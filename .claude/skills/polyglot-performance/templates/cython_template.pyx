# cython: language_level=3
# cython: boundscheck=False
# cython: wraparound=False
# cython: cdivision=True
"""
Cython Template for Performance-Critical Code

Usage:
1. Replace function_name with your function
2. Add type annotations (cdef) for variables
3. Build with: python setup.py build_ext --inplace
4. Benchmark to verify speedup

Typical speedup: 10-100x for numerical/loop-heavy code
"""

import numpy as np
cimport numpy as cnp
from libc.math cimport sqrt, exp, log, sin, cos
cimport cython

# Type definitions for NumPy arrays
ctypedef cnp.float64_t DTYPE_t
ctypedef cnp.int64_t ITYPE_t


@cython.boundscheck(False)  # Disable bounds checking (unsafe but fast)
@cython.wraparound(False)   # Disable negative indexing (unsafe but fast)
@cython.cdivision(True)     # Use C division (no zero check, faster)
def optimized_function(cnp.ndarray[DTYPE_t, ndim=1] data):
    """
    Replace this with your optimized function.

    Args:
        data: NumPy array of floats (1D)

    Returns:
        Computed result

    Example:
        data = np.random.randn(1_000_000)
        result = optimized_function(data)
    """
    cdef:
        Py_ssize_t i, n = data.shape[0]
        DTYPE_t result = 0.0
        DTYPE_t value, temp

    # Hot loop - will be compiled to C
    for i in range(n):
        value = data[i]
        temp = value * value + 2.0 * value + 1.0
        result += temp

    return result


@cython.boundscheck(False)
@cython.wraparound(False)
def process_2d_array(cnp.ndarray[DTYPE_t, ndim=2] matrix):
    """
    Example: Process 2D array.

    Args:
        matrix: 2D NumPy array

    Returns:
        Processed result
    """
    cdef:
        Py_ssize_t i, j
        Py_ssize_t rows = matrix.shape[0]
        Py_ssize_t cols = matrix.shape[1]
        DTYPE_t result = 0.0
        DTYPE_t value

    # Nested loop - much faster in Cython
    for i in range(rows):
        for j in range(cols):
            value = matrix[i, j]
            result += value * value

    return result


@cython.boundscheck(False)
@cython.wraparound(False)
def accumulate_with_condition(cnp.ndarray[DTYPE_t, ndim=1] data, DTYPE_t threshold):
    """
    Example: Conditional accumulation.

    Args:
        data: Input array
        threshold: Threshold value

    Returns:
        Sum of values > threshold
    """
    cdef:
        Py_ssize_t i, n = data.shape[0]
        DTYPE_t result = 0.0
        DTYPE_t value

    for i in range(n):
        value = data[i]
        if value > threshold:
            result += value

    return result


# Advanced: Using C++ STL (requires language="c++" in setup.py)
# from libcpp.vector cimport vector
# from libcpp.unordered_map cimport unordered_map


def process_list_of_dicts(list data):
    """
    Example: Process Python list of dicts (slower, but sometimes needed).

    Args:
        data: List of dictionaries

    Returns:
        Processed results
    """
    cdef:
        list result = []
        dict item
        double value

    for item in data:
        value = item.get('amount', 0.0) * 1.1
        item['processed_amount'] = value
        result.append(item)

    return result


# Memory views (faster than NumPy arrays for some operations)
@cython.boundscheck(False)
@cython.wraparound(False)
def process_memoryview(double[::1] data):
    """
    Example: Using memory views (typed views of arrays).

    Memory views are faster than np.ndarray for some operations.

    Args:
        data: Memory view of doubles

    Returns:
        Result
    """
    cdef:
        Py_ssize_t i, n = data.shape[0]
        double result = 0.0

    for i in range(n):
        result += data[i] * data[i]

    return result
