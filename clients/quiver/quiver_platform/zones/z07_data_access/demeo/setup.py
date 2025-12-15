"""
DeMeo v2.0 - Cython Build Configuration

Builds high-performance Cython modules for DeMeo framework.

Usage:
    # Build in-place
    python3 setup.py build_ext --inplace

    # Clean build artifacts
    python3 setup.py clean --all

    # Install
    python3 setup.py install

Author: Quiver Platform - DeMeo Team
Created: 2025-12-03
Version: 2.0.0-alpha1
"""

from setuptools import setup, Extension
from Cython.Build import cythonize
import numpy as np
import sys
import os

# Compiler flags for optimization
extra_compile_args = [
    '-O3',              # Maximum optimization
    '-ffast-math',      # Fast math operations
]

# Add CPU-specific optimizations (skip -march=native on Apple Silicon)
if sys.platform != 'darwin':
    extra_compile_args.append('-march=native')

extra_link_args = []

# Add OpenMP support if available
if sys.platform == 'darwin':  # macOS
    # Use libomp from Homebrew
    libomp_include = '/opt/homebrew/opt/libomp/include'
    libomp_lib = '/opt/homebrew/opt/libomp/lib'
    extra_compile_args.extend(['-Xpreprocessor', '-fopenmp', f'-I{libomp_include}'])
    extra_link_args.extend(['-lomp', f'-L{libomp_lib}'])
elif sys.platform == 'linux':  # Linux
    extra_compile_args.append('-fopenmp')
    extra_link_args.append('-fopenmp')
elif sys.platform == 'win32':  # Windows
    extra_compile_args.append('/openmp')

# Define Cython extensions
extensions = [
    Extension(
        name='_bayesian_fusion_core',
        sources=['_bayesian_fusion_core.pyx'],
        include_dirs=[np.get_include()],
        extra_compile_args=extra_compile_args,
        extra_link_args=extra_link_args,
        language='c'
    ),
    Extension(
        name='_multimodal_consensus_core',
        sources=['_multimodal_consensus_core.pyx'],
        include_dirs=[np.get_include()],
        extra_compile_args=extra_compile_args,
        extra_link_args=extra_link_args,
        language='c'
    ),
    Extension(
        name='_vscore_core',
        sources=['_vscore_core.pyx'],
        include_dirs=[np.get_include()],
        extra_compile_args=extra_compile_args,
        extra_link_args=extra_link_args,
        language='c'
    ),
]

# Compiler directives for Cython
compiler_directives = {
    'language_level': 3,          # Python 3
    'boundscheck': False,         # Disable bounds checking (unsafe but fast)
    'wraparound': False,          # Disable negative indexing (unsafe but fast)
    'cdivision': True,            # C-style division (no Python overhead)
    'embedsignature': True,       # Embed function signatures in docstrings
    'initializedcheck': False,    # Disable memoryview initialization check
    'nonecheck': False,           # Disable None checks
    'overflowcheck': False,       # Disable overflow checking
}

if __name__ == '__main__':
    print("=" * 80)
    print("DeMeo v2.0 - Cython Build Configuration")
    print("=" * 80)
    print("\nBuilding 3 high-performance Cython modules:")
    print("  1. _bayesian_fusion_core.pyx     (Bootstrap CI + fusion)")
    print("  2. _multimodal_consensus_core.pyx (Cosine similarity + agreement)")
    print("  3. _vscore_core.pyx               (V-score computation)")
    print("\nOptimizations enabled:")
    print(f"  - Compiler flags: {' '.join(extra_compile_args)}")
    print(f"  - OpenMP parallelization: {'Yes' if '-fopenmp' in str(extra_compile_args) else 'No'}")
    print(f"  - NumPy integration: Yes")
    print("\nExpected speedup: 20-50x")
    print("=" * 80)

    setup(
        name='demeo',
        version='2.0.0-alpha1',
        description='DeMeo v2.0 - High-Performance Drug Rescue Framework',
        author='Quiver Platform - Sapphire Team',
        ext_modules=cythonize(
            extensions,
            compiler_directives=compiler_directives,
            annotate=True,  # Generate HTML annotation files
            nthreads=4      # Parallel Cython compilation
        ),
        zip_safe=False,
        python_requires='>=3.8',
        install_requires=[
            'numpy>=1.20.0',
            'cython>=0.29.0',
        ]
    )
