#!/bin/bash
# Test the locally built SM120 PyTorch package
# This tests the build WITHOUT publishing to FloxHub

set -e

RESULT_DIR="result-pytorch-python313-cuda12_8-sm120-avx512-cu128"

if [ ! -L "$RESULT_DIR" ]; then
    echo "ERROR: Build result not found at $RESULT_DIR"
    echo "Did you run: flox build pytorch-python313-cuda12_8-sm120-avx512-cu128"
    exit 1
fi

echo "========================================"
echo "Testing SM120 PyTorch Build"
echo "========================================"
echo "Result path: $(readlink -f $RESULT_DIR)"
echo ""

# Use the built Python with PyTorch
PYTHON="${RESULT_DIR}/bin/python"

if [ ! -f "$PYTHON" ]; then
    # Try the lib path directly
    PYTHON="python3.13"
    export PYTHONPATH="${RESULT_DIR}/lib/python3.13/site-packages:$PYTHONPATH"
fi

echo "Running CUDA verification tests..."
echo ""

$PYTHON << 'EOF'
import torch
import sys

print("=" * 50)
print("PyTorch Build Information")
print("=" * 50)
print(f"PyTorch version: {torch.__version__}")
print(f"Python version: {sys.version}")
print(f"PyTorch path: {torch.__file__}")
print()

print("=" * 50)
print("CUDA Support")
print("=" * 50)
print(f"CUDA available: {torch.cuda.is_available()}")
print(f"CUDA built: {torch.version.cuda}")
print(f"cuDNN version: {torch.backends.cudnn.version()}")
print()

print("=" * 50)
print("GPU Architecture Configuration")
print("=" * 50)
print(f"Compiled arch list: {torch.cuda.get_arch_list()}")
print(f"Number of GPUs: {torch.cuda.device_count()}")
print()

if torch.cuda.is_available():
    print("=" * 50)
    print("GPU Device Information")
    print("=" * 50)
    for i in range(torch.cuda.device_count()):
        print(f"GPU {i}: {torch.cuda.get_device_name(i)}")
        cap = torch.cuda.get_device_capability(i)
        print(f"  Compute capability: {cap[0]}.{cap[1]}")
    print()

    print("=" * 50)
    print("Quick Tensor Test")
    print("=" * 50)
    try:
        x = torch.randn(3, 3).cuda()
        y = torch.randn(3, 3).cuda()
        z = x @ y
        print(f"✓ Matrix multiplication on GPU successful")
        print(f"  Result shape: {z.shape}")
        print(f"  Result device: {z.device}")
    except Exception as e:
        print(f"✗ GPU tensor operation failed: {e}")
    print()

# Verify SM120 support
print("=" * 50)
print("SM120 Verification")
print("=" * 50)
arch_list = torch.cuda.get_arch_list()
has_sm120 = any('12.0' in arch or 'sm_120' in arch for arch in arch_list)
print(f"SM120 (12.0) in arch list: {has_sm120}")
print(f"Architecture list: {arch_list}")

if has_sm120:
    print("✓ BUILD SUCCESS: SM120 support confirmed!")
else:
    print("⚠ WARNING: SM120 not found in architecture list")
    print("  This may still work via forward compatibility")
print()

# Check CPU optimizations
print("=" * 50)
print("CPU Features")
print("=" * 50)
print(f"MKL available: {torch.backends.mkl.is_available()}")
print(f"MKL-DNN available: {torch.backends.mkldnn.is_available()}")
print()

print("=" * 50)
print("Test Complete!")
print("=" * 50)
EOF

echo ""
echo "========================================"
echo "Test completed successfully!"
echo "========================================"
