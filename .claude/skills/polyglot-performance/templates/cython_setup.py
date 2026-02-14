"""
Cython Setup Template

Build command:
    python setup.py build_ext --inplace

For development (rebuilds on change):
    pip install -e .

For production build:
    python setup.py build_ext --inplace --force
"""

from setuptools import setup, Extension
from Cython.Build import cythonize
import numpy as np
import sys

# Compiler optimization flags
extra_compile_args = []
extra_link_args = []

if sys.platform == 'darwin':  # macOS
    extra_compile_args = [
        '-O3',              # Maximum optimization
        '-march=native',    # Use CPU-specific instructions
        '-ffast-math',      # Fast floating-point math
    ]
elif sys.platform == 'linux':
    extra_compile_args = [
        '-O3',
        '-march=native',
        '-ffast-math',
    ]
elif sys.platform == 'win32':  # Windows
    extra_compile_args = [
        '/O2',              # Maximum optimization
        '/fp:fast',         # Fast floating-point
    ]

# Define extensions
extensions = [
    Extension(
        name="fast_ops",  # Change this to your module name
        sources=["fast_ops.pyx"],  # Change this to your .pyx file
        include_dirs=[np.get_include()],
        extra_compile_args=extra_compile_args,
        extra_link_args=extra_link_args,
        define_macros=[('NPY_NO_DEPRECATED_API', 'NPY_1_7_API_VERSION')],
    ),
    # Add more extensions here if needed
    # Extension(
    #     name="another_module",
    #     sources=["another_module.pyx"],
    #     ...
    # ),
]

# Cythonize with optimizations
setup(
    name="fast_ops",  # Package name
    version="0.1.0",
    ext_modules=cythonize(
        extensions,
        compiler_directives={
            'language_level': '3',      # Python 3
            'boundscheck': False,       # Disable bounds checking (faster, unsafe)
            'wraparound': False,        # Disable negative indexing (faster, unsafe)
            'cdivision': True,          # Use C division (faster, unsafe)
            'initializedcheck': False,  # Disable initialized check (faster, unsafe)
            'nonecheck': False,         # Disable None check (faster, unsafe)
            'embedsignature': True,     # Embed function signatures in docstrings
            'annotation_typing': True,  # Use annotations for type inference
        },
        annotate=True,  # Generate HTML annotation file (.html)
    ),
    install_requires=[
        'numpy>=1.20.0',
        'cython>=3.0.0',
    ],
)

"""
Notes:

1. Annotation file:
   After build, open fast_ops.html in browser to see performance insights.
   Yellow lines = Python interaction (slow)
   White lines = Pure C (fast)

2. Safety vs Speed:
   Current settings prioritize speed (boundscheck=False, etc.)
   For debugging, set these to True in compiler_directives

3. Testing optimizations:
   - Check .html file for yellow lines
   - Profile with cProfile
   - Benchmark against pure Python

4. Advanced options:
   - language="c++" : Use C++ instead of C
   - parallel=True : Enable parallel compilation
   - nthreads=4 : Number of parallel compilation threads

Example advanced setup:

    setup(
        ext_modules=cythonize(
            extensions,
            compiler_directives={...},
            annotate=True,
            nthreads=4,           # Parallel compilation
            language_level=3,
        ),
    )
"""
