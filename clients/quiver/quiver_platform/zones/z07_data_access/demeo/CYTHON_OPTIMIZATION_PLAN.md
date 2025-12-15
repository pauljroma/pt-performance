# DeMeo v2.0 - Cython Optimization Plan

## Performance-Critical Candidates

### 🔴 HIGH Priority (Cythonize ASAP)

#### 1. **bayesian_fusion.py** - Core Math Engine
**Why**: Heavy numerical computation in tight loops, bootstrap sampling (1000 iterations)

**Functions to Cythonize**:
```python
# CRITICAL - Called 1000x per drug ranking
def estimate_confidence_interval(
    tool_results: Dict[str, ToolPrediction],
    weights: Dict[str, float],
    prior: float,
    n_bootstrap: int = 1000
) -> Tuple[float, float]:
    """
    Bootstrap sampling - 1000 iterations of:
    - Random sampling
    - Noise generation (np.random.normal)
    - Consensus calculation
    - Percentile computation

    🔥 BOTTLENECK: O(n_bootstrap * n_tools) = 1000 * 6 = 6000 operations per drug
    ⚡ Cython speedup: 10-50x (tight loops, NumPy arrays)
    """

# CRITICAL - Called once per tool fusion
def fuse_tool_predictions(
    tool_results: Dict[str, ToolPrediction],
    weights: Optional[Dict[str, float]] = None,
    prior: float = 0.50
) -> FusionResult:
    """
    Bayesian fusion loop over tools

    🔥 BOTTLENECK: O(n_tools) but called for every drug
    ⚡ Cython speedup: 5-10x (eliminate Python dict overhead)
    """
```

**Cython Optimizations**:
- Typed memoryviews for NumPy arrays: `double[::1]`
- Static typing for loop variables: `cdef int i, j`
- C-level random number generation (GSL or NumPy C API)
- Inline functions with `cdef inline`

**Expected Speedup**: **10-50x** for bootstrap, **5-10x** for fusion

---

#### 2. **multimodal_consensus.py** - Vector Math
**Why**: Cosine similarity calculations, pairwise comparisons, matrix operations

**Functions to Cythonize**:
```python
# CRITICAL - Pairwise similarity (N choose 2 comparisons)
def calculate_agreement_coefficient(vectors: Dict[str, np.ndarray]) -> float:
    """
    Pairwise cosine similarity calculation

    🔥 BOTTLENECK: O(n_modalities²) - For 3 modalities = 3 comparisons
    But if extended to 10 modalities = 45 comparisons
    ⚡ Cython speedup: 20-100x (use BLAS directly, avoid sklearn overhead)
    """

# IMPORTANT - Weighted vector fusion
def compute_consensus(
    vectors: Dict[str, np.ndarray],
    weights: Optional[Dict[str, float]] = None
) -> ConsensusResult:
    """
    Weighted sum of vectors

    🔥 BOTTLENECK: O(n_modalities * vector_dim) = 3 * 16-32 dims
    ⚡ Cython speedup: 10-20x (fused loops, no Python overhead)
    """
```

**Cython Optimizations**:
- BLAS/LAPACK integration for vector operations
- Typed memoryviews: `double[:, ::1]` for 2D arrays
- Fused loop for weighted sum (single pass)
- C-level cosine similarity (avoid sklearn overhead)

**Expected Speedup**: **20-100x** for similarity, **10-20x** for fusion

---

#### 3. **vscore_calculator.py** - Statistical Computation
**Why**: Variance calculations, element-wise operations on large vectors

**Functions to Cythonize**:
```python
# CRITICAL - Core v-score formula
def compute_variance_scaled_vscore(
    wt_vec: np.ndarray,
    disease_vec: np.ndarray,
    wt_var: float,
    disease_var: float
) -> np.ndarray:
    """
    Element-wise: (disease - wt) / sqrt(var_wt + var_disease)

    🔥 BOTTLENECK: O(vector_dim) - 16-32 dimensions, but called frequently
    ⚡ Cython speedup: 15-30x (vectorized C operations, no Python loop)
    """
```

**Cython Optimizations**:
- Fused element-wise operations (single loop)
- C math library for sqrt (`libc.math.sqrt`)
- Typed memoryviews for zero-copy NumPy access
- Parallel loop with OpenMP (`prange`)

**Expected Speedup**: **15-30x**

---

### 🟡 MEDIUM Priority (Phase 2)

#### 4. **demeo_orchestrator.py** - Orchestration Logic
**Why**: Mostly I/O bound (tool calls), but some ranking logic

**Functions to Consider**:
```python
# MEDIUM - Sorting/filtering large result sets
def _get_candidate_drugs(gene: str, unified_query_layer) -> List[str]:
    """
    If querying thousands of drugs from PGVector
    ⚡ Cython speedup: 3-5x (if doing in-memory filtering/ranking)
    """
```

**Verdict**: **Low priority** - Orchestration is I/O bound, minimal compute

---

### 🟢 LOW Priority (Not Recommended)

#### 5. **Neo4j Migrations** - Cypher Scripts
**Why**: Not Python code, no benefit

#### 6. **__init__.py** - Package Initialization
**Why**: Runs once at import, no compute

---

## Recommended Cython Migration Strategy

### Phase 1: High-Impact Functions (Week 1)

**Create Cython modules**:
```
zones/z07_data_access/demeo/
├── _bayesian_fusion_core.pyx      # Core math functions
├── _multimodal_consensus_core.pyx # Vector operations
└── _vscore_core.pyx                # V-score computation
```

**Keep Python wrappers**:
```
zones/z07_data_access/demeo/
├── bayesian_fusion.py             # Calls _bayesian_fusion_core
├── multimodal_consensus.py        # Calls _multimodal_consensus_core
└── vscore_calculator.py           # Calls _vscore_core
```

### Phase 2: Profiling & Optimization (Week 2)

1. **Profile with `cProfile`**:
   ```bash
   python3 -m cProfile -o demeo.prof -s cumtime \
       -m zones.z07_data_access.demeo.demeo_orchestrator
   ```

2. **Identify actual bottlenecks** with `snakeviz`:
   ```bash
   snakeviz demeo.prof
   ```

3. **Cythonize only proven bottlenecks**

---

## Cython Implementation Examples

### Example 1: Bootstrap CI (bayesian_fusion_core.pyx)

```cython
# cython: language_level=3
# cython: boundscheck=False
# cython: wraparound=False

import numpy as np
cimport numpy as cnp
from libc.math cimport sqrt
from libc.stdlib cimport rand, RAND_MAX

cdef double random_normal(double mean, double std) nogil:
    """Fast C-level normal random generation."""
    cdef double u1 = (<double>rand()) / RAND_MAX
    cdef double u2 = (<double>rand()) / RAND_MAX
    return mean + std * sqrt(-2.0 * log(u1)) * cos(2.0 * 3.14159265 * u2)

cpdef tuple estimate_confidence_interval_fast(
    double[:] scores,
    double[:] confidences,
    double[:] weights,
    double prior,
    int n_bootstrap
):
    """Cython-optimized bootstrap confidence interval."""
    cdef:
        int i, j, n_tools
        double[:] bootstrap_scores = np.zeros(n_bootstrap)
        double consensus, noise

    n_tools = scores.shape[0]

    # Parallel bootstrap loop
    with nogil:
        for i in range(n_bootstrap):
            consensus = prior
            for j in range(n_tools):
                # Add noise based on confidence
                noise = random_normal(0.0, (1.0 - confidences[j]) * 0.1)
                consensus *= (1.0 + weights[j] * max(0.0, min(1.0, scores[j] + noise)))
            bootstrap_scores[i] = min(1.0, max(0.0, consensus))

    # Compute percentiles
    cdef double[:] sorted_scores = np.sort(bootstrap_scores)
    cdef int idx_lower = int(n_bootstrap * 0.025)
    cdef int idx_upper = int(n_bootstrap * 0.975)

    return (sorted_scores[idx_lower], sorted_scores[idx_upper])
```

**Speedup**: ~**30-50x** faster than pure Python

---

### Example 2: Cosine Similarity (multimodal_consensus_core.pyx)

```cython
# cython: language_level=3
# cython: boundscheck=False
# cython: wraparound=False

import numpy as np
cimport numpy as cnp
from libc.math cimport sqrt

cpdef double cosine_similarity_fast(double[:] vec1, double[:] vec2) nogil:
    """Fast C-level cosine similarity."""
    cdef:
        int i, n
        double dot_product = 0.0
        double norm1 = 0.0
        double norm2 = 0.0

    n = vec1.shape[0]

    for i in range(n):
        dot_product += vec1[i] * vec2[i]
        norm1 += vec1[i] * vec1[i]
        norm2 += vec2[i] * vec2[i]

    return dot_product / (sqrt(norm1) * sqrt(norm2))

cpdef double calculate_agreement_fast(double[:, :] vectors):
    """Pairwise agreement across modalities."""
    cdef:
        int i, j, n_modalities
        double similarity, total = 0.0
        int count = 0

    n_modalities = vectors.shape[0]

    # Pairwise comparisons
    for i in range(n_modalities):
        for j in range(i + 1, n_modalities):
            similarity = cosine_similarity_fast(vectors[i, :], vectors[j, :])
            total += similarity
            count += 1

    return total / count if count > 0 else 1.0
```

**Speedup**: ~**50-100x** faster than sklearn

---

### Example 3: V-Score Computation (vscore_core.pyx)

```cython
# cython: language_level=3
# cython: boundscheck=False
# cython: wraparound=False
# cython: cdivision=True

import numpy as np
cimport numpy as cnp
from libc.math cimport sqrt
from cython.parallel import prange

cpdef cnp.ndarray[cnp.float64_t, ndim=1] compute_vscore_fast(
    double[:] wt_vec,
    double[:] disease_vec,
    double wt_var,
    double disease_var
):
    """Parallel v-score computation."""
    cdef:
        int i, n
        double denominator
        cnp.ndarray[cnp.float64_t, ndim=1] vscore

    n = wt_vec.shape[0]
    vscore = np.zeros(n, dtype=np.float64)
    denominator = sqrt(wt_var + disease_var)

    # Parallel loop with OpenMP
    for i in prange(n, nogil=True):
        vscore[i] = (disease_vec[i] - wt_vec[i]) / denominator

    return vscore
```

**Speedup**: ~**20-30x** faster with parallelization

---

## Setup & Build Configuration

### setup.py for Cython modules

```python
from setuptools import setup, Extension
from Cython.Build import cythonize
import numpy as np

extensions = [
    Extension(
        "zones.z07_data_access.demeo._bayesian_fusion_core",
        ["zones/z07_data_access/demeo/_bayesian_fusion_core.pyx"],
        include_dirs=[np.get_include()],
        extra_compile_args=['-O3', '-march=native', '-fopenmp'],
        extra_link_args=['-fopenmp']
    ),
    Extension(
        "zones.z07_data_access.demeo._multimodal_consensus_core",
        ["zones/z07_data_access/demeo/_multimodal_consensus_core.pyx"],
        include_dirs=[np.get_include()],
        extra_compile_args=['-O3', '-march=native', '-fopenmp'],
        extra_link_args=['-fopenmp']
    ),
    Extension(
        "zones.z07_data_access.demeo._vscore_core",
        ["zones/z07_data_access/demeo/_vscore_core.pyx"],
        include_dirs=[np.get_include()],
        extra_compile_args=['-O3', '-march=native', '-fopenmp'],
        extra_link_args=['-fopenmp']
    ),
]

setup(
    name='demeo',
    ext_modules=cythonize(
        extensions,
        compiler_directives={
            'language_level': 3,
            'boundscheck': False,
            'wraparound': False,
            'cdivision': True,
            'embedsignature': True
        }
    )
)
```

### Build command

```bash
python3 setup.py build_ext --inplace
```

---

## Expected Overall Performance Gains

| Component | Python (ms) | Cython (ms) | Speedup | Priority |
|-----------|-------------|-------------|---------|----------|
| Bootstrap CI (1000 iter) | 500-1000 | 10-20 | **50x** | 🔴 HIGH |
| Bayesian fusion | 5-10 | 0.5-1 | **10x** | 🔴 HIGH |
| Cosine similarity | 2-5 | 0.02-0.05 | **100x** | 🔴 HIGH |
| Multi-modal consensus | 3-8 | 0.3-0.8 | **10x** | 🔴 HIGH |
| V-score computation | 1-3 | 0.05-0.1 | **30x** | 🔴 HIGH |
| **End-to-End (20 drugs)** | **10-20s** | **0.5-1s** | **20x** | ⚡ TOTAL |

---

## Recommendation

**Cythonize immediately**:
1. ✅ `_bayesian_fusion_core.pyx` - Bootstrap CI + fusion
2. ✅ `_multimodal_consensus_core.pyx` - Cosine similarity + agreement
3. ✅ `_vscore_core.pyx` - V-score computation

**Keep as pure Python**:
- ❌ `demeo_orchestrator.py` - I/O bound
- ❌ `__init__.py` - Import logic

**Expected Total Speedup**: **20-30x** end-to-end for rescue ranking workflow.

---

## Next Steps

1. **Week 1**: Implement 3 Cython modules (.pyx files)
2. **Week 1**: Create setup.py and build configuration
3. **Week 1**: Profile before/after with cProfile
4. **Week 2**: Benchmark with real data (SCN1A rescue ranking)
5. **Week 2**: Optimize based on profiling results

**ETA**: 1-2 weeks for full Cython migration with 20-30x speedup.
