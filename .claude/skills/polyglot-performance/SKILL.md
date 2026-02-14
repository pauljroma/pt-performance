# polyglot-performance Skill

**Type**: Language Selection & Performance Optimization
**Languages**: Python → Cython → Rust (escalation path)
**Purpose**: Claude automatically selects optimal language for performance-critical code

---

## When to Use Each Language

### Decision Matrix

| Requirement | Python | Cython | Rust |
|-------------|--------|--------|------|
| Rapid prototyping | ✅ | ❌ | ❌ |
| Easy maintenance | ✅ | ⚠️ | ❌ |
| 10-100x speedup needed | ❌ | ✅ | ✅ |
| 100-1000x speedup needed | ❌ | ⚠️ | ✅ |
| Memory safety critical | ❌ | ❌ | ✅ |
| Parallel processing | ⚠️ | ⚠️ | ✅ |
| GIL is bottleneck | ❌ | ⚠️ | ✅ |
| Numerical computation | ⚠️ | ✅ | ✅ |
| Systems programming | ❌ | ❌ | ✅ |
| Python interop | ✅ | ✅ | ⚠️ |

### Performance Ladder

```
Python (baseline)
    ↓ (10-100x speedup needed, Python interop required)
Cython (Python + C speed)
    ↓ (100-1000x speedup needed, memory safety, no GIL)
Rust (maximum performance + safety)
```

---

## Use Cases

### ✅ Use Cython When:

1. **Numerical computation bottlenecks**
   - Loops over arrays
   - Mathematical operations
   - Example: Processing 1M+ data points

2. **Python extension with C speed**
   - Need Python API compatibility
   - Want gradual optimization (type annotations)
   - Example: Hot loop in data pipeline

3. **NumPy operations too slow**
   - Custom array operations
   - Statistical computations
   - Example: Custom aggregations

4. **Moderate speedup needed (10-100x)**
   - Not worth Rust complexity
   - Still need Python ecosystem
   - Example: ETL transformations

### ✅ Use Rust When:

1. **Systems-level programming**
   - Low-level operations
   - Memory management critical
   - Example: Parser, serializer

2. **Concurrency/parallelism required**
   - No GIL limitations
   - Thread-safe by default
   - Example: Multi-threaded web server

3. **Maximum performance needed (100-1000x)**
   - Cython not fast enough
   - Zero-cost abstractions
   - Example: High-frequency trading

4. **Memory safety critical**
   - No segfaults
   - No data races
   - Example: Security-critical code

5. **CLI tools and utilities**
   - Single binary
   - Fast startup
   - Example: Code generator, formatter

### ❌ Stay with Python When:

1. Performance is acceptable
2. Code clarity > speed
3. Rapid iteration needed
4. Not a bottleneck

---

## Automatic Detection

### Triggers for Cython

Claude will proactively suggest/use Cython when:

1. **Keywords detected**:
   - "optimize", "speed up", "performance bottleneck"
   - "process millions of rows"
   - "loop is too slow"

2. **Code patterns detected**:
   ```python
   # Hot loops
   for i in range(1000000):
       result += expensive_operation(i)

   # NumPy operations on large arrays
   arr = np.array([...])  # 1M+ elements
   result = custom_operation(arr)

   # Nested loops
   for i in range(n):
       for j in range(m):
           # expensive computation
   ```

3. **Performance requirements**:
   - Processing >1M items
   - Operations taking >10 seconds
   - Need 10-100x speedup

### Triggers for Rust

Claude will proactively suggest/use Rust when:

1. **Keywords detected**:
   - "concurrency", "parallel", "multi-threaded"
   - "GIL", "release GIL", "no GIL"
   - "systems programming", "low-level"
   - "CLI tool", "command-line utility"
   - "memory safe", "no segfaults"

2. **Code patterns detected**:
   ```python
   # Parallelism needed
   with ThreadPoolExecutor() as executor:
       # Python GIL limits this

   # Systems-level operations
   # File I/O, network, parsing

   # CLI tool
   if __name__ == "__main__":
       import argparse
   ```

3. **Performance requirements**:
   - Need 100-1000x speedup
   - Cython attempted but not fast enough
   - Concurrency is bottleneck

---

## Templates and Patterns

### Cython Template

**File structure**:
```
your_module/
├── fast_ops.pyx          # Cython source
├── fast_ops.pxd          # Cython header (optional)
├── setup.py              # Build configuration
└── __init__.py           # Python wrapper
```

**Example: Optimizing Hot Loop**

**Before (Python)**:
```python
def process_data(data: list[float]) -> float:
    """Process 1M data points - takes 5 seconds."""
    result = 0.0
    for value in data:
        result += value * value + 2 * value + 1
    return result
```

**After (Cython)**:
```cython
# fast_ops.pyx
import cython

@cython.boundscheck(False)  # Disable bounds checking
@cython.wraparound(False)   # Disable negative indexing
def process_data_fast(double[::1] data):
    """Process 1M data points - takes 0.05 seconds (100x faster)."""
    cdef:
        double result = 0.0
        Py_ssize_t i, n = data.shape[0]
        double value

    for i in range(n):
        value = data[i]
        result += value * value + 2.0 * value + 1.0

    return result
```

**Build (setup.py)**:
```python
from setuptools import setup, Extension
from Cython.Build import cythonize
import numpy as np

extensions = [
    Extension(
        "fast_ops",
        ["fast_ops.pyx"],
        include_dirs=[np.get_include()],
        extra_compile_args=["-O3", "-march=native"],
    )
]

setup(
    ext_modules=cythonize(extensions, language_level="3"),
)
```

**Build command**:
```bash
python setup.py build_ext --inplace
```

### Rust Template (PyO3)

**File structure**:
```
your_module/
├── src/
│   └── lib.rs            # Rust source
├── Cargo.toml            # Rust configuration
└── __init__.py           # Python wrapper
```

**Example: Parallel Processing**

**Cargo.toml**:
```toml
[package]
name = "fast_ops_rust"
version = "0.1.0"
edition = "2021"

[lib]
name = "fast_ops_rust"
crate-type = ["cdylib"]

[dependencies]
pyo3 = { version = "0.20", features = ["extension-module"] }
rayon = "1.8"  # For parallelism
```

**Rust (src/lib.rs)**:
```rust
use pyo3::prelude::*;
use rayon::prelude::*;

/// Process data in parallel (no GIL!)
#[pyfunction]
fn process_data_parallel(data: Vec<f64>) -> PyResult<f64> {
    let result: f64 = data
        .par_iter()
        .map(|&value| value * value + 2.0 * value + 1.0)
        .sum();

    Ok(result)
}

/// Parse large JSON file (10-100x faster than Python)
#[pyfunction]
fn parse_json_fast(json_str: &str) -> PyResult<Vec<(String, f64)>> {
    let parsed: Vec<(String, f64)> = serde_json::from_str(json_str)?;
    Ok(parsed)
}

#[pymodule]
fn fast_ops_rust(_py: Python, m: &PyModule) -> PyResult<()> {
    m.add_function(wrap_pyfunction!(process_data_parallel, m)?)?;
    m.add_function(wrap_pyfunction!(parse_json_fast, m)?)?;
    Ok(())
}
```

**Build**:
```bash
pip install maturin
maturin develop --release
```

**Python usage**:
```python
import fast_ops_rust

# Parallel processing (no GIL!)
result = fast_ops_rust.process_data_parallel(data)

# Fast JSON parsing
parsed = fast_ops_rust.parse_json_fast(json_string)
```

---

## Real-World Examples

### Example 1: Data Pipeline Optimization

**Scenario**: ETL pipeline processing 10M rows takes 2 hours

**Analysis**:
- Python: 2 hours (baseline)
- **Cython**: 7 minutes (17x speedup) ← **RECOMMENDED**
- Rust: 3 minutes (40x speedup, but higher complexity)

**Decision**: Use Cython
- Reason: 17x speedup sufficient, easier to maintain
- Implementation: Cythonize hot loops with type annotations

**Code**:
```cython
# etl_fast.pyx
@cython.boundscheck(False)
def transform_rows(data: list[dict]) -> list[dict]:
    cdef:
        list result = []
        dict row
        double value

    for row in data:
        value = row['amount'] * 1.1  # 10% markup
        row['final_amount'] = value
        result.append(row)

    return result
```

### Example 2: High-Performance Parser

**Scenario**: Parse 100MB JSON file, Python takes 30 seconds

**Analysis**:
- Python: 30 seconds (baseline)
- Cython: 10 seconds (3x speedup)
- **Rust**: 0.5 seconds (60x speedup) ← **RECOMMENDED**

**Decision**: Use Rust
- Reason: 60x speedup, no GIL, memory safe
- Implementation: Rust parser with serde_json

**Code**:
```rust
// parser.rs
use serde_json::Value;
use pyo3::prelude::*;

#[pyfunction]
fn parse_large_json(json_str: &str) -> PyResult<Value> {
    let parsed: Value = serde_json::from_str(json_str)
        .map_err(|e| PyErr::new::<pyo3::exceptions::PyValueError, _>(
            format!("JSON parse error: {}", e)
        ))?;
    Ok(parsed)
}
```

### Example 3: Numerical Simulation

**Scenario**: Monte Carlo simulation with 1M iterations

**Analysis**:
- Python: 10 minutes (baseline)
- **Cython**: 30 seconds (20x speedup) ← **RECOMMENDED**
- Rust: 15 seconds (40x speedup, but overkill)

**Decision**: Use Cython
- Reason: 20x speedup sufficient, NumPy integration
- Implementation: Cythonize simulation loop

**Code**:
```cython
# simulation.pyx
import numpy as np
cimport numpy as cnp
from libc.math cimport sqrt, exp

@cython.boundscheck(False)
def monte_carlo_simulate(int n_iterations, double initial_value):
    cdef:
        cnp.ndarray[cnp.float64_t, ndim=1] results = np.zeros(n_iterations)
        int i
        double value = initial_value
        double random_factor

    for i in range(n_iterations):
        random_factor = np.random.randn()
        value = value * exp(random_factor * 0.1)
        results[i] = value

    return results
```

### Example 4: CLI Tool

**Scenario**: Build code formatter (like Black or Ruff)

**Analysis**:
- Python: 5 seconds to format 1000 files
- Cython: 2 seconds (2.5x speedup, still slow startup)
- **Rust**: 0.2 seconds (25x speedup, instant startup) ← **RECOMMENDED**

**Decision**: Use Rust
- Reason: CLI tools benefit from compiled binary, fast startup
- Implementation: Rust CLI with clap

**Code**:
```rust
// main.rs
use clap::Parser;
use std::fs;

#[derive(Parser)]
struct Args {
    #[arg(short, long)]
    file: String,
}

fn main() {
    let args = Args::parse();
    let content = fs::read_to_string(&args.file).unwrap();
    let formatted = format_code(&content);
    fs::write(&args.file, formatted).unwrap();
}
```

---

## Workflow

### Step 1: Claude Detects Performance Need

```
User: "This function processes 5M rows and takes 10 minutes. Can you optimize it?"

Claude analyzes:
- Large dataset (5M rows) → Performance critical
- Hot loop detected
- Numeric operations
→ Triggers polyglot-performance skill
```

### Step 2: Claude Selects Language

```
Claude decision matrix:
- Need: 10-100x speedup
- Context: Python data pipeline, NumPy arrays
- Complexity tolerance: Medium
→ Recommends: Cython
```

### Step 3: Claude Implements

```
Claude:
"I'll optimize this with Cython for 10-100x speedup.

Creating:
1. fast_ops.pyx (Cythonized hot loop)
2. setup.py (build configuration)
3. Benchmark script to verify speedup

[Creates files]

To build:
python setup.py build_ext --inplace

Expected speedup: 20-50x"
```

### Step 4: Benchmark and Verify

```python
# benchmark.py
import time
import numpy as np

# Original Python
start = time.time()
result_py = process_data_python(data)
time_py = time.time() - start

# Cython
start = time.time()
result_cy = process_data_fast(data)
time_cy = time.time() - start

print(f"Python: {time_py:.2f}s")
print(f"Cython: {time_cy:.2f}s")
print(f"Speedup: {time_py/time_cy:.1f}x")
```

---

## Integration with insight-collab

### Multi-Axis Optimization

Sometimes you need BOTH o1 reasoning AND performance languages:

**Example**: Design + implement high-performance recommendation engine

```
Phase 1: Architecture (o1)
- o1 analyzes: Algorithm choice, data structures, tradeoffs
- o1 recommends: Approximate nearest neighbors with LSH

Phase 2: Language Selection (polyglot-performance)
- Claude analyzes: 10M users, need <100ms latency
- Claude selects: Rust (parallelism + performance)

Phase 3: Implementation (Claude)
- Claude implements: Rust LSH with rayon parallelism
- Claude creates: Python bindings with PyO3
- Claude writes: Benchmarks and tests
```

**Result**: Optimal algorithm (from o1) + optimal implementation (Rust)

---

## Cost Analysis

### Cython

**Setup Cost**:
- Initial: 30-60 minutes (learn syntax, setup build)
- Per module: 15-30 minutes (write .pyx, setup.py)

**Maintenance Cost**:
- Medium (less readable than Python)
- Type annotations can be verbose
- Build step adds complexity

**Performance Gain**:
- 10-100x typical speedup
- Diminishing returns vs Rust for some tasks

**When Worth It**:
- ✅ Critical hot loop (used millions of times)
- ✅ NumPy-heavy code
- ✅ Need Python interop
- ❌ Not worth it for rarely-used code

### Rust

**Setup Cost**:
- Initial: 2-4 hours (learn Rust, PyO3, tooling)
- Per module: 1-2 hours (write Rust, bindings, build)

**Maintenance Cost**:
- Higher than Cython (separate language)
- Borrow checker learning curve
- Separate build system (Cargo)

**Performance Gain**:
- 100-1000x typical speedup
- Memory safety guaranteed
- True parallelism (no GIL)

**When Worth It**:
- ✅ Maximum performance needed
- ✅ Concurrency critical
- ✅ CLI tool (single binary benefit)
- ✅ Systems programming
- ❌ Not worth it for simple speedups (use Cython)

---

## Benchmarking Framework

Claude will automatically create benchmarks when using Cython/Rust:

```python
# benchmark.py
import time
import numpy as np
from typing import Callable

def benchmark(func: Callable, *args, n_runs: int = 10):
    """Benchmark function with multiple runs."""
    times = []
    for _ in range(n_runs):
        start = time.perf_counter()
        result = func(*args)
        elapsed = time.perf_counter() - start
        times.append(elapsed)

    return {
        'mean': np.mean(times),
        'std': np.std(times),
        'min': np.min(times),
        'max': np.max(times)
    }

# Compare implementations
data = np.random.randn(1_000_000)

py_stats = benchmark(process_data_python, data)
cy_stats = benchmark(process_data_cython, data)
rs_stats = benchmark(process_data_rust, data)

print(f"Python:  {py_stats['mean']:.3f}s ± {py_stats['std']:.3f}s")
print(f"Cython:  {cy_stats['mean']:.3f}s ± {cy_stats['std']:.3f}s")
print(f"Rust:    {rs_stats['mean']:.3f}s ± {rs_stats['std']:.3f}s")
print(f"\nSpeedup (Cython): {py_stats['mean']/cy_stats['mean']:.1f}x")
print(f"Speedup (Rust):   {py_stats['mean']/rs_stats['mean']:.1f}x")
```

---

## Status

**Status**: 🔄 READY TO IMPLEMENT
**Next**: Create polyglot-performance config and MCP integration →
