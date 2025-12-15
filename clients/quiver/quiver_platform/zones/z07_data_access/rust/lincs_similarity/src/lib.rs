use pyo3::prelude::*;
use numpy::{PyArray2, PyReadonlyArray1, PyReadonlyArray2};
use ndarray::{Array1, Array2, ArrayView1};
use rayon::prelude::*;

/// High-performance similarity engine for LINCS L1000 data
/// Implements MODEX protocol metrics with Rayon parallelization
///
/// Target: 1M x 1M comparisons in <1 hour (10-100x speedup vs Python)

// =============================================================================
// Core Similarity Metrics
// =============================================================================

/// Pearson correlation coefficient
/// Returns: (correlation, n_samples)
fn pearson_correlation(x: &ArrayView1<f64>, y: &ArrayView1<f64>) -> (f64, usize) {
    let n = x.len();
    if n == 0 {
        return (0.0, 0);
    }

    let mean_x = x.mean().unwrap_or(0.0);
    let mean_y = y.mean().unwrap_or(0.0);

    let mut sum_xy = 0.0;
    let mut sum_xx = 0.0;
    let mut sum_yy = 0.0;

    for i in 0..n {
        let dx = x[i] - mean_x;
        let dy = y[i] - mean_y;
        sum_xy += dx * dy;
        sum_xx += dx * dx;
        sum_yy += dy * dy;
    }

    let corr = if sum_xx > 0.0 && sum_yy > 0.0 {
        sum_xy / (sum_xx * sum_yy).sqrt()
    } else {
        0.0
    };

    (corr, n)
}

/// Cosine similarity
fn cosine_similarity(x: &ArrayView1<f64>, y: &ArrayView1<f64>) -> f64 {
    let dot = x.iter().zip(y.iter()).map(|(a, b)| a * b).sum::<f64>();
    let norm_x = x.iter().map(|a| a * a).sum::<f64>().sqrt();
    let norm_y = y.iter().map(|b| b * b).sum::<f64>().sqrt();

    if norm_x > 0.0 && norm_y > 0.0 {
        dot / (norm_x * norm_y)
    } else {
        0.0
    }
}

/// KS enrichment score (used in connectivity score)
fn ks_enrichment_score(positions: &[usize], total: usize) -> f64 {
    if positions.is_empty() {
        return 0.0;
    }

    let n = positions.len() as f64;
    let mut sorted_pos: Vec<usize> = positions.to_vec();
    sorted_pos.sort_unstable();

    // Running sum enrichment
    let mut max_deviation = 0.0;
    for (i, &pos) in sorted_pos.iter().enumerate() {
        let hit_rate = (i + 1) as f64 / n;
        let background_rate = pos as f64 / total as f64;
        let deviation = (hit_rate - background_rate).abs();
        if deviation > max_deviation {
            max_deviation = deviation;
        }
    }

    max_deviation
}

/// Connectivity score (Lamb et al. 2006)
/// Returns: tau score in [-100, 100]
fn connectivity_score(query: &ArrayView1<f64>, reference: &ArrayView1<f64>, n_top: usize) -> f64 {
    let n_genes = query.len();
    let n_top = n_top.min(n_genes / 2);

    // Get top/bottom genes from query
    let mut query_indices: Vec<(usize, f64)> = query.iter()
        .enumerate()
        .map(|(i, &v)| (i, v))
        .collect();

    query_indices.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap());

    let up_genes: Vec<usize> = query_indices.iter().take(n_top).map(|(i, _)| *i).collect();
    let down_genes: Vec<usize> = query_indices.iter().rev().take(n_top).map(|(i, _)| *i).collect();

    // Rank genes in reference (high to low)
    let mut ref_indices: Vec<(usize, f64)> = reference.iter()
        .enumerate()
        .map(|(i, &v)| (i, v))
        .collect();

    ref_indices.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap());

    let ref_ranks: Vec<usize> = ref_indices.iter().map(|(i, _)| *i).collect();

    // Find positions of up/down genes in reference ranking
    let up_positions: Vec<usize> = ref_ranks.iter()
        .enumerate()
        .filter(|(_, &gene_id)| up_genes.contains(&gene_id))
        .map(|(pos, _)| pos)
        .collect();

    let down_positions: Vec<usize> = ref_ranks.iter()
        .enumerate()
        .filter(|(_, &gene_id)| down_genes.contains(&gene_id))
        .map(|(pos, _)| pos)
        .collect();

    // KS enrichment
    let up_ks = ks_enrichment_score(&up_positions, n_genes);
    let down_ks = -ks_enrichment_score(&down_positions, n_genes);

    // Connectivity score: scale to tau [-100, +100]
    (up_ks + down_ks) * 100.0
}

/// Rescue score (antipodal scoring with baseline)
/// Returns: score in [-1, 1] where 1.0 = perfect rescue
fn rescue_score(
    disease: &ArrayView1<f64>,
    drug: &ArrayView1<f64>,
    wt_baseline: Option<&ArrayView1<f64>>
) -> f64 {
    // Calculate deviations from WT baseline
    let (disease_dev, drug_dev) = if let Some(wt) = wt_baseline {
        let d_dev: Array1<f64> = disease.iter().zip(wt.iter()).map(|(d, w)| d - w).collect();
        let dr_dev: Array1<f64> = drug.iter().zip(wt.iter()).map(|(d, w)| d - w).collect();
        (d_dev, dr_dev)
    } else {
        (disease.to_owned(), drug.to_owned())
    };

    // Cosine similarity between deviations
    let cosine = cosine_similarity(&disease_dev.view(), &drug_dev.view());

    // Rescue score: negative of cosine
    // If cosine = -1 (opposite), rescue = +1 (perfect rescue)
    -cosine
}

// =============================================================================
// Batch Processing with Rayon Parallelization
// =============================================================================

/// Compute pairwise Pearson correlations between all rows of two matrices
/// Returns: (n_queries, n_references) matrix of correlations
#[pyfunction]
fn batch_pearson_correlation<'py>(
    py: Python<'py>,
    queries: PyReadonlyArray2<f64>,
    references: PyReadonlyArray2<f64>
) -> PyResult<&'py PyArray2<f64>> {
    let queries_array = queries.as_array();
    let references_array = references.as_array();

    let n_queries = queries_array.nrows();
    let n_refs = references_array.nrows();

    // Parallel computation
    let results: Vec<f64> = (0..n_queries).into_par_iter()
        .flat_map(|i| {
            let query = queries_array.row(i);
            (0..n_refs).map(move |j| {
                let reference = references_array.row(j);
                let (corr, _) = pearson_correlation(&query, &reference);
                corr
            }).collect::<Vec<f64>>()
        })
        .collect();

    // Convert to 2D array
    let result_array = Array2::from_shape_vec((n_queries, n_refs), results)
        .map_err(|e| PyErr::new::<pyo3::exceptions::PyValueError, _>(e.to_string()))?;

    Ok(PyArray2::from_owned_array(py, result_array))
}

/// Compute pairwise cosine similarities
#[pyfunction]
fn batch_cosine_similarity<'py>(
    py: Python<'py>,
    queries: PyReadonlyArray2<f64>,
    references: PyReadonlyArray2<f64>
) -> PyResult<&'py PyArray2<f64>> {
    let queries_array = queries.as_array();
    let references_array = references.as_array();

    let n_queries = queries_array.nrows();
    let n_refs = references_array.nrows();

    let results: Vec<f64> = (0..n_queries).into_par_iter()
        .flat_map(|i| {
            let query = queries_array.row(i);
            (0..n_refs).map(move |j| {
                let reference = references_array.row(j);
                cosine_similarity(&query, &reference)
            }).collect::<Vec<f64>>()
        })
        .collect();

    let result_array = Array2::from_shape_vec((n_queries, n_refs), results)
        .map_err(|e| PyErr::new::<pyo3::exceptions::PyValueError, _>(e.to_string()))?;

    Ok(PyArray2::from_owned_array(py, result_array))
}

/// Compute pairwise connectivity scores
#[pyfunction]
fn batch_connectivity_score<'py>(
    py: Python<'py>,
    queries: PyReadonlyArray2<f64>,
    references: PyReadonlyArray2<f64>,
    n_top: usize
) -> PyResult<&'py PyArray2<f64>> {
    let queries_array = queries.as_array();
    let references_array = references.as_array();

    let n_queries = queries_array.nrows();
    let n_refs = references_array.nrows();

    let results: Vec<f64> = (0..n_queries).into_par_iter()
        .flat_map(|i| {
            let query = queries_array.row(i);
            (0..n_refs).map(move |j| {
                let reference = references_array.row(j);
                connectivity_score(&query, &reference, n_top)
            }).collect::<Vec<f64>>()
        })
        .collect();

    let result_array = Array2::from_shape_vec((n_queries, n_refs), results)
        .map_err(|e| PyErr::new::<pyo3::exceptions::PyValueError, _>(e.to_string()))?;

    Ok(PyArray2::from_owned_array(py, result_array))
}

/// Compute rescue scores for disease-drug pairs
#[pyfunction]
fn batch_rescue_score<'py>(
    py: Python<'py>,
    diseases: PyReadonlyArray2<f64>,
    drugs: PyReadonlyArray2<f64>,
    wt_baseline: Option<PyReadonlyArray1<f64>>
) -> PyResult<&'py PyArray2<f64>> {
    let diseases_array = diseases.as_array();
    let drugs_array = drugs.as_array();

    let n_diseases = diseases_array.nrows();
    let n_drugs = drugs_array.nrows();

    // Convert baseline to owned array if present
    let wt_owned: Option<Array1<f64>> = wt_baseline.map(|arr| arr.as_array().to_owned());

    let results: Vec<f64> = (0..n_diseases).into_par_iter()
        .flat_map(|i| {
            let disease = diseases_array.row(i);
            let wt_ref = wt_owned.as_ref();
            (0..n_drugs).map(move |j| {
                let drug = drugs_array.row(j);
                let wt_view = wt_ref.map(|arr| arr.view());
                rescue_score(&disease, &drug, wt_view.as_ref())
            }).collect::<Vec<f64>>()
        })
        .collect();

    let result_array = Array2::from_shape_vec((n_diseases, n_drugs), results)
        .map_err(|e| PyErr::new::<pyo3::exceptions::PyValueError, _>(e.to_string()))?;

    Ok(PyArray2::from_owned_array(py, result_array))
}

/// Find top-k most similar items for each query
#[pyfunction]
fn find_top_k_similar<'py>(
    py: Python<'py>,
    queries: PyReadonlyArray2<f64>,
    references: PyReadonlyArray2<f64>,
    k: usize,
    metric: &str
) -> PyResult<(&'py PyArray2<usize>, &'py PyArray2<f64>)> {
    let queries_array = queries.as_array();
    let references_array = references.as_array();

    let n_queries = queries_array.nrows();
    let n_refs = references_array.nrows();
    let k = k.min(n_refs);

    let results: Vec<(Vec<usize>, Vec<f64>)> = (0..n_queries).into_par_iter()
        .map(|i| {
            let query = queries_array.row(i);

            // Compute similarities
            let mut similarities: Vec<(usize, f64)> = (0..n_refs).map(|j| {
                let reference = references_array.row(j);
                let score = match metric {
                    "pearson" => pearson_correlation(&query, &reference).0,
                    "cosine" => cosine_similarity(&query, &reference),
                    _ => 0.0
                };
                (j, score)
            }).collect();

            // Sort by score (descending)
            similarities.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap());

            // Take top-k
            let top_indices: Vec<usize> = similarities.iter().take(k).map(|(idx, _)| *idx).collect();
            let top_scores: Vec<f64> = similarities.iter().take(k).map(|(_, score)| *score).collect();

            (top_indices, top_scores)
        })
        .collect();

    // Flatten results
    let indices: Vec<usize> = results.iter().flat_map(|(idx, _)| idx.clone()).collect();
    let scores: Vec<f64> = results.iter().flat_map(|(_, sc)| sc.clone()).collect();

    let indices_array = Array2::from_shape_vec((n_queries, k), indices)
        .map_err(|e| PyErr::new::<pyo3::exceptions::PyValueError, _>(e.to_string()))?;
    let scores_array = Array2::from_shape_vec((n_queries, k), scores)
        .map_err(|e| PyErr::new::<pyo3::exceptions::PyValueError, _>(e.to_string()))?;

    Ok((
        PyArray2::from_owned_array(py, indices_array),
        PyArray2::from_owned_array(py, scores_array)
    ))
}

// =============================================================================
// Python Module Export
// =============================================================================

#[pymodule]
fn lincs_similarity_engine(_py: Python, m: &PyModule) -> PyResult<()> {
    m.add_function(wrap_pyfunction!(batch_pearson_correlation, m)?)?;
    m.add_function(wrap_pyfunction!(batch_cosine_similarity, m)?)?;
    m.add_function(wrap_pyfunction!(batch_connectivity_score, m)?)?;
    m.add_function(wrap_pyfunction!(batch_rescue_score, m)?)?;
    m.add_function(wrap_pyfunction!(find_top_k_similar, m)?)?;
    Ok(())
}
