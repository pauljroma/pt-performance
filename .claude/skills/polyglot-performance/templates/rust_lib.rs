/*!
Rust + PyO3 Template for Maximum Performance

Usage:
1. Replace function implementations with your logic
2. Build with: maturin develop --release
3. Import in Python: import fast_ops_rust
4. Benchmark to verify speedup

Typical speedup: 100-1000x for concurrent/systems-level code

Features:
- No GIL (true parallelism)
- Memory safety (no segfaults)
- Zero-cost abstractions
- Excellent performance
*/

use pyo3::prelude::*;
use pyo3::exceptions::PyValueError;
use rayon::prelude::*;  // For parallelism
use std::collections::HashMap;

/// Process data in parallel (no GIL!)
///
/// Example:
///     data = [1.0, 2.0, 3.0, ...]
///     result = fast_ops_rust.process_parallel(data)
///
/// Speedup: 10-100x vs Python (depending on CPU cores)
#[pyfunction]
fn process_parallel(data: Vec<f64>) -> PyResult<f64> {
    // Parallel processing using rayon
    // No GIL means true parallelism across all cores
    let result: f64 = data
        .par_iter()  // Parallel iterator
        .map(|&value| {
            // Your computation here
            value * value + 2.0 * value + 1.0
        })
        .sum();

    Ok(result)
}

/// Process data sequentially (single-threaded)
///
/// Use this for smaller datasets where parallelism overhead isn't worth it
#[pyfunction]
fn process_sequential(data: Vec<f64>) -> PyResult<f64> {
    let result: f64 = data
        .iter()
        .map(|&value| value * value + 2.0 * value + 1.0)
        .sum();

    Ok(result)
}

/// Parse JSON fast (10-100x faster than Python json module)
///
/// Example:
///     json_str = '{"key": "value", ...}'
///     parsed = fast_ops_rust.parse_json_fast(json_str)
#[pyfunction]
fn parse_json_fast(json_str: &str) -> PyResult<HashMap<String, serde_json::Value>> {
    serde_json::from_str(json_str)
        .map_err(|e| PyValueError::new_err(format!("JSON parse error: {}", e)))
}

/// Filter and transform data (example of complex operation)
///
/// Example:
///     data = [1.0, 2.0, 3.0, ...]
///     threshold = 2.0
///     result = fast_ops_rust.filter_transform(data, threshold)
#[pyfunction]
fn filter_transform(data: Vec<f64>, threshold: f64) -> PyResult<Vec<f64>> {
    let result: Vec<f64> = data
        .into_par_iter()  // Parallel + consume vector
        .filter(|&x| x > threshold)
        .map(|x| x * 2.0)
        .collect();

    Ok(result)
}

/// Count occurrences in parallel
///
/// Example:
///     items = ["apple", "banana", "apple", ...]
///     counts = fast_ops_rust.count_occurrences(items)
///     # Returns: {"apple": 2, "banana": 1, ...}
#[pyfunction]
fn count_occurrences(items: Vec<String>) -> PyResult<HashMap<String, usize>> {
    use std::sync::Mutex;

    let counts = Mutex::new(HashMap::new());

    items.par_iter().for_each(|item| {
        let mut map = counts.lock().unwrap();
        *map.entry(item.clone()).or_insert(0) += 1;
    });

    Ok(counts.into_inner().unwrap())
}

/// Matrix multiplication (example of numerical computation)
///
/// Example:
///     a = [[1.0, 2.0], [3.0, 4.0]]
///     b = [[5.0, 6.0], [7.0, 8.0]]
///     result = fast_ops_rust.matmul(a, b)
#[pyfunction]
fn matmul(a: Vec<Vec<f64>>, b: Vec<Vec<f64>>) -> PyResult<Vec<Vec<f64>>> {
    let n = a.len();
    let m = b[0].len();
    let p = b.len();

    if a[0].len() != p {
        return Err(PyValueError::new_err("Matrix dimensions don't match"));
    }

    let result: Vec<Vec<f64>> = (0..n)
        .into_par_iter()
        .map(|i| {
            (0..m)
                .map(|j| {
                    (0..p).map(|k| a[i][k] * b[k][j]).sum()
                })
                .collect()
        })
        .collect();

    Ok(result)
}

/// Read and process large file (systems programming example)
///
/// Example:
///     lines = fast_ops_rust.read_and_process("data.txt")
#[pyfunction]
fn read_and_process(filepath: &str) -> PyResult<Vec<String>> {
    use std::fs::File;
    use std::io::{BufRead, BufReader};

    let file = File::open(filepath)
        .map_err(|e| PyValueError::new_err(format!("File error: {}", e)))?;

    let reader = BufReader::new(file);

    let lines: Vec<String> = reader
        .lines()
        .filter_map(|line| line.ok())
        .filter(|line| !line.is_empty())
        .map(|line| line.to_uppercase())
        .collect();

    Ok(lines)
}

/// Compute statistics in parallel
///
/// Example:
///     data = [1.0, 2.0, 3.0, ...]
///     stats = fast_ops_rust.compute_stats(data)
///     # Returns: {"mean": 2.0, "std": 0.816, ...}
#[pyfunction]
fn compute_stats(data: Vec<f64>) -> PyResult<HashMap<String, f64>> {
    if data.is_empty() {
        return Err(PyValueError::new_err("Empty data"));
    }

    let n = data.len() as f64;
    let sum: f64 = data.par_iter().sum();
    let mean = sum / n;

    let variance: f64 = data
        .par_iter()
        .map(|&x| (x - mean).powi(2))
        .sum::<f64>() / n;

    let std = variance.sqrt();

    let min = data.par_iter().cloned().fold(|| f64::INFINITY, f64::min).min().unwrap();
    let max = data.par_iter().cloned().fold(|| f64::NEG_INFINITY, f64::max).max().unwrap();

    let mut stats = HashMap::new();
    stats.insert("mean".to_string(), mean);
    stats.insert("std".to_string(), std);
    stats.insert("min".to_string(), min);
    stats.insert("max".to_string(), max);
    stats.insert("count".to_string(), n);

    Ok(stats)
}

/// Custom class example
#[pyclass]
struct DataProcessor {
    #[pyo3(get, set)]
    threshold: f64,
    data: Vec<f64>,
}

#[pymethods]
impl DataProcessor {
    #[new]
    fn new(threshold: f64) -> Self {
        DataProcessor {
            threshold,
            data: Vec::new(),
        }
    }

    fn add_data(&mut self, values: Vec<f64>) {
        self.data.extend(values);
    }

    fn process(&self) -> Vec<f64> {
        self.data
            .par_iter()
            .filter(|&&x| x > self.threshold)
            .map(|&x| x * 2.0)
            .collect()
    }

    fn clear(&mut self) {
        self.data.clear();
    }

    fn len(&self) -> usize {
        self.data.len()
    }
}

/// Python module definition
#[pymodule]
fn fast_ops_rust(_py: Python, m: &PyModule) -> PyResult<()> {
    // Register functions
    m.add_function(wrap_pyfunction!(process_parallel, m)?)?;
    m.add_function(wrap_pyfunction!(process_sequential, m)?)?;
    m.add_function(wrap_pyfunction!(parse_json_fast, m)?)?;
    m.add_function(wrap_pyfunction!(filter_transform, m)?)?;
    m.add_function(wrap_pyfunction!(count_occurrences, m)?)?;
    m.add_function(wrap_pyfunction!(matmul, m)?)?;
    m.add_function(wrap_pyfunction!(read_and_process, m)?)?;
    m.add_function(wrap_pyfunction!(compute_stats, m)?)?;

    // Register classes
    m.add_class::<DataProcessor>()?;

    Ok(())
}

/*
Advanced features:

1. Error handling:
   - Use PyResult<T> for all functions
   - Convert Rust errors to Python exceptions
   - Use custom error types if needed

2. Type conversions:
   - Vec<T> ↔ list
   - HashMap<K,V> ↔ dict
   - String/&str ↔ str
   - Use numpy crate for NumPy arrays

3. NumPy integration:
   Add to Cargo.toml:
   ```
   numpy = "0.20"
   ```

   Then:
   ```rust
   use numpy::{PyArray1, PyReadonlyArray1};

   #[pyfunction]
   fn process_numpy(array: PyReadonlyArray1<f64>) -> Py<PyArray1<f64>> {
       let array = array.as_array();
       // Process array...
   }
   ```

4. Async support:
   Add to Cargo.toml:
   ```
   tokio = { version = "1", features = ["full"] }
   pyo3-asyncio = "0.20"
   ```

5. Custom exceptions:
   ```rust
   use pyo3::create_exception;

   create_exception!(mymodule, CustomError, pyo3::exceptions::PyException);
   ```
*/
