#!/usr/bin/env bash

export PYTHONPATH="/home/daedalus/dev/builds/build-pytorch/result-pytorch-python313-cuda12_8-sm90-avx512/lib/python3.13/site-packages:$PYTHONPATH"

echo "========================================"
echo "CUDA Diagnostics"
echo "========================================"
echo ""

# Check NVIDIA driver and CUDA
echo "=== NVIDIA Driver ==="
nvidia-smi
echo ""

# Check for CUDA libraries
echo "=== CUDA Libraries Check ==="
ldconfig -p | grep -i cuda | head -10
echo ""

# Check PyTorch's view of CUDA
echo "=== PyTorch CUDA Detection ==="
python3.13 << 'EOF'
import torch
import os

print(f"CUDA available: {torch.cuda.is_available()}")
print(f"CUDA built: {torch.cuda.is_built()}")

if torch.cuda.is_built():
    print(f"CUDA version (compiled): {torch.version.cuda}")
    print(f"cuDNN version: {torch.backends.cudnn.version()}")
    print(f"Compiled with CUDA arch list: {torch.cuda.get_arch_list()}")

# Check for CUDA libraries
print("\nEnvironment variables:")
print(f"  CUDA_HOME: {os.environ.get('CUDA_HOME', 'Not set')}")
print(f"  LD_LIBRARY_PATH: {os.environ.get('LD_LIBRARY_PATH', 'Not set')[:200]}...")

# Try to get more debug info
print("\nTrying to load CUDA:")
try:
    torch.cuda.init()
    print("  ✅ CUDA initialized")
except Exception as e:
    print(f"  ❌ CUDA init failed: {e}")

if torch.cuda.is_available():
    print(f"\nGPU Device:")
    print(f"  Count: {torch.cuda.device_count()}")
    print(f"  Name: {torch.cuda.get_device_name(0)}")
    print(f"  Capability: {torch.cuda.get_device_capability(0)}")
    print(f"  Memory: {torch.cuda.get_device_properties(0).total_memory / 1024**3:.1f} GB")
EOF
echo ""

# Check result libraries
echo "=== Result Package CUDA Libraries ==="
find ./result-pytorch-python313-cuda12_8-sm90-avx512/lib -name "*cuda*" 2>/dev/null | head -10
echo ""

echo "========================================"
