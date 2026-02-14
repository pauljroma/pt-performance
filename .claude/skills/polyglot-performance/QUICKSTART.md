# polyglot-performance Quick Start

**Purpose**: Claude automatically selects optimal language (Python/Cython/Rust) for performance-critical code

**Status**: ✅ READY TO USE

---

## Quick Decision Guide

```
Is this a performance bottleneck?
    ↓
   NO → Use Python (done)
    ↓
  YES → How much speedup needed?
    ↓
10-100x? → Use Cython (Python + C speed, easy Python interop)
    ↓
100-1000x? → Use Rust (maximum performance, true parallelism)
    ↓
Systems programming / CLI tool? → Use Rust
```

---

## Installation

### Cython Setup

```bash
# Install Cython
pip install cython numpy

# That's it! Ready to use.
```

### Rust Setup

```bash
# Install Rust (one-time)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env

# Install maturin (Rust ↔ Python bridge)
pip install maturin

# Done! Ready to build Rust extensions.
```

---

## Usage Examples

### Example 1: Optimize Slow Loop (Use Cython)

**Scenario**: Processing 5M rows takes 10 minutes

```python
# Original Python (slow.py)
def process_data(data):
    """Takes 10 minutes for 5M rows."""
    result = 0.0
    for value in data:
        result += value * value + 2 * value + 1
    return result
```

**Ask Claude**:
```
"This process_data function takes 10 minutes on 5M rows. Can you optimize it?"
```

**Claude Response**:
```
I'll optimize this with Cython for 20-50x speedup.

Creating:
1. fast_ops.pyx (Cythonized version)
2. setup.py (build configuration)
3. benchmark.py (verify speedup)

[Creates files]

To build:
python setup.py build_ext --inplace

Expected speedup: 20-50x (10 min → 12-30 seconds)
```

**Result**: 30x speedup, 10 min → 20 seconds

---

### Example 2: Parallel Processing (Use Rust)

**Scenario**: Need to process data in parallel (Python GIL is bottleneck)

```python
# Python with ThreadPoolExecutor (doesn't help due to GIL)
from concurrent.futures import ThreadPoolExecutor

def process_parallel(data):
    """GIL limits this to single-core performance."""
    with ThreadPoolExecutor(max_workers=8) as executor:
        results = list(executor.map(expensive_function, data))
    return results
```

**Ask Claude**:
```
"I need true parallelism for this function. Python's GIL is limiting me to single-core performance."
```

**Claude Response**:
```
I'll implement this in Rust for true parallelism (no GIL).

Creating:
1. src/lib.rs (Rust implementation with rayon)
2. Cargo.toml (Rust configuration)
3. benchmark.py (verify speedup)

[Creates files]

To build:
maturin develop --release

Expected speedup: 8x on 8-core CPU (true parallelism)
```

**Result**: 8x speedup on 8-core CPU, no GIL limitations

---

### Example 3: JSON Parsing (Use Rust)

**Scenario**: Parsing 100MB JSON file takes 30 seconds

**Ask Claude**:
```
"This JSON parsing is too slow. Can you speed it up?"
```

**Claude Response**:
```
I'll use Rust with serde_json for 50-100x speedup.

Creating:
1. src/lib.rs (Rust JSON parser)
2. Cargo.toml
3. benchmark.py

Expected speedup: 50-100x (30s → 0.3-0.6s)
```

**Result**: 60x speedup, 30s → 0.5s

---

## How Claude Decides

### Triggers for Cython

Claude automatically suggests Cython when detecting:

**Keywords**:
- "optimize", "speed up", "too slow", "bottleneck"
- "process millions", "large dataset"

**Code Patterns**:
```python
# Hot loop (1M+ iterations)
for i in range(1_000_000):
    result += expensive_operation(i)

# NumPy arrays with custom operations
arr = np.array([...])  # Large array
custom_operation(arr)

# Nested loops
for i in range(n):
    for j in range(m):
        # computation
```

**Performance Requirements**:
- Processing >1M items
- Operation taking >10 seconds
- Need 10-100x speedup

### Triggers for Rust

Claude automatically suggests Rust when detecting:

**Keywords**:
- "parallel", "concurrent", "multi-threaded"
- "GIL", "no GIL", "release GIL"
- "systems programming", "low-level"
- "CLI tool", "command-line"

**Code Patterns**:
```python
# Parallelism (GIL limited)
with ThreadPoolExecutor():
    ...

# CLI tool
if __name__ == "__main__":
    import argparse

# File I/O heavy operations
```

**Performance Requirements**:
- Need 100-1000x speedup
- Concurrency is critical
- Cython tried but not fast enough

---

## Templates Available

### Cython Templates

1. **cython_template.pyx** - Optimized functions with type annotations
2. **cython_setup.py** - Build configuration with optimization flags

**Features**:
- NumPy integration
- Memory views for faster array access
- C math functions (sqrt, exp, log, etc.)
- Disable bounds checking for maximum speed

### Rust Templates

1. **rust_lib.rs** - PyO3 bindings with parallel processing
2. **rust_Cargo.toml** - Rust configuration with dependencies

**Features**:
- Rayon for data parallelism
- Serde for JSON parsing
- Memory-safe by design
- No GIL limitations

### Benchmark Template

**benchmark_template.py** - Automatic performance comparison

**Features**:
- Compare Python vs Cython vs Rust
- Calculate speedup automatically
- Verify correctness
- Generate detailed reports

---

## Build Commands

### Cython

```bash
# Development build
python setup.py build_ext --inplace

# Clean and rebuild
python setup.py clean --all
python setup.py build_ext --inplace --force

# Install as package
pip install -e .
```

### Rust

```bash
# Development build (fast compile, unoptimized)
maturin develop

# Release build (optimized)
maturin develop --release

# Maximum optimization (CPU-specific)
RUSTFLAGS="-C target-cpu=native" maturin develop --release

# Build wheel for distribution
maturin build --release
pip install target/wheels/your_module-*.whl
```

---

## Performance Expectations

| Language | Typical Speedup | Setup Time | Use When |
|----------|----------------|------------|----------|
| **Python** | 1x (baseline) | 0 min | Default choice |
| **Cython** | 10-100x | 15-30 min | Hot loops, NumPy ops |
| **Rust** | 100-1000x | 60-120 min | Max performance, parallelism |

### Cost-Benefit Analysis

**Cython**:
- ✅ Worth it if: Code runs >1000 times/day
- ✅ Easy Python interop
- ⚠️  Medium maintenance complexity

**Rust**:
- ✅ Worth it if: Need maximum performance OR parallelism OR CLI tool
- ✅ Memory safe, no segfaults
- ⚠️  Higher learning curve

---

## Verification

### After Building, Verify Speedup

```bash
# Run benchmark
python benchmark.py

# Expected output:
Python:  10.234s
Cython:  0.512s (20x speedup)
Rust:    0.102s (100x speedup)

✅ All implementations produce identical results
```

### Check Optimization (Cython Only)

```bash
# Generate annotation file
python setup.py build_ext --inplace

# Open fast_ops.html in browser
# Yellow lines = Python interaction (slow)
# White lines = Pure C (fast)
```

---

## Troubleshooting

### Cython: "No module named 'fast_ops'"

**Cause**: Build failed or module not in Python path

**Fix**:
```bash
python setup.py build_ext --inplace
# Check for errors in output
```

### Rust: "maturin: command not found"

**Cause**: maturin not installed

**Fix**:
```bash
pip install maturin
```

### Rust: Build errors

**Cause**: Usually missing dependencies

**Fix**:
```bash
# Check Cargo.toml has correct dependencies
# Most common: Add rayon, serde, pyo3

# Update dependencies
cargo update
```

### Speedup Less Than Expected

**Causes**:
1. Not using release build (Rust)
2. Bounds checking enabled (Cython)
3. Small dataset (overhead dominates)
4. GIL not released (Cython/Rust)

**Fix**:
```bash
# Rust: Use --release
maturin develop --release

# Cython: Check setup.py has boundscheck=False

# Verify benchmark uses large enough dataset
```

---

## Integration with insight-collab

### Combined Optimization

Sometimes you need BOTH o1 reasoning AND performance languages:

**Example**: "Design and implement high-performance recommendation engine"

```
Phase 1: Algorithm Design (o1)
- User: "What's the best algorithm for 10M user recommendations?"
- Claude: [Consults o1]
- o1: "Use approximate nearest neighbors with LSH for O(log n) lookups"

Phase 2: Language Selection (polyglot-performance)
- Claude: "10M users, need <100ms latency → Use Rust"

Phase 3: Implementation
- Claude: [Creates Rust LSH implementation with rayon parallelism]
- Claude: [Creates Python bindings with PyO3]
- Claude: [Creates benchmarks]

Result: Optimal algorithm (from o1) + optimal implementation (Rust)
```

---

## Real-World Checklist

### Before Optimizing

- [ ] Profile to find actual bottleneck (don't guess!)
- [ ] Confirm performance is actually a problem
- [ ] Benchmark baseline Python performance
- [ ] Set target speedup (10x? 100x?)

### Choosing Language

- [ ] Need 10-100x? → Try Cython first
- [ ] Need 100-1000x or parallelism? → Use Rust
- [ ] CLI tool or systems programming? → Use Rust
- [ ] Unsure? → Ask Claude (I'll analyze and recommend)

### After Implementation

- [ ] Run benchmarks to verify speedup
- [ ] Verify correctness (results match Python)
- [ ] Check if speedup justifies complexity
- [ ] Document build process for team
- [ ] Add to CI/CD if needed

---

## Examples by Use Case

| Use Case | Recommended Language | Expected Speedup |
|----------|---------------------|------------------|
| ETL pipeline (10M rows) | Cython | 10-50x |
| Numerical simulation | Cython | 20-100x |
| JSON parsing (large files) | Rust | 50-100x |
| Parallel data processing | Rust | 10-100x (scales with cores) |
| CLI tool / formatter | Rust | 10-50x + instant startup |
| Hot loop in API endpoint | Cython | 10-50x |
| Systems programming | Rust | 100-1000x |
| Machine learning inference | Rust | 50-200x |

---

## Next Steps

1. ✅ Install Cython: `pip install cython`
2. ✅ Install Rust (optional): `curl https://sh.rustup.rs | sh`
3. ✅ Install maturin (optional): `pip install maturin`
4. ✅ Ask Claude to optimize your slow code
5. ✅ Claude will automatically select the right language
6. ✅ Build and benchmark to verify speedup

---

**Questions?**

- See full documentation: `.claude/skills/polyglot-performance/SKILL.md`
- See templates: `.claude/skills/polyglot-performance/templates/`
- Ask Claude: "Show me an example of Cython optimization"

**Status**: ✅ PRODUCTION READY
