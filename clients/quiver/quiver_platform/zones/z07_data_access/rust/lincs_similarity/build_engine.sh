#!/bin/bash
#
# Build script for LINCS Similarity Engine
# Sets up Python environment and builds Rust library with PyO3
#

set -e

echo "=================================================================================="
echo "Building LINCS Similarity Engine (Rust + PyO3)"
echo "=================================================================================="
echo ""

# Find Python 3.11
PYTHON_PATH=$(which python3.11)
if [ -z "$PYTHON_PATH" ]; then
    echo "Error: python3.11 not found in PATH"
    exit 1
fi

echo "✓ Found Python: $PYTHON_PATH"

# Set PyO3 environment
export PYO3_PYTHON="$PYTHON_PATH"

# Get Python config
PYTHON_VERSION=$(python3.11 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
echo "✓ Python version: $PYTHON_VERSION"

# Build with cargo
echo ""
echo "Building Rust library with release optimizations..."
echo "  - LTO: enabled"
echo "  - Optimization level: 3"
echo "  - Codegen units: 1"
echo ""

cd "$(dirname "$0")"
cargo build --release

if [ $? -eq 0 ]; then
    echo ""
    echo "=================================================================================="
    echo "Build complete!"
    echo "=================================================================================="
    echo ""
    echo "Shared library:"
    ls -lh target/release/*.dylib 2>/dev/null || ls -lh target/release/*.so 2>/dev/null || echo "  (library not found)"
    echo ""
    echo "To use in Python:"
    echo "  import lincs_similarity_engine"
    echo "  result = lincs_similarity_engine.batch_pearson_correlation(queries, refs)"
    echo ""
else
    echo ""
    echo "Build failed. Check error messages above."
    exit 1
fi
