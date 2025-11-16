#!/usr/bin/env bash

export PYTHONPATH="/home/daedalus/dev/builds/build-pytorch/result-pytorch-python313-cuda12_8-sm90-avx512/lib/python3.13/site-packages:$PYTHONPATH"

echo "========================================"
echo "Detailed PyTorch Build Verification"
echo "========================================"
echo ""

# Check CPU features
echo "=== System CPU Features ==="
lscpu | grep -E "Model name|Architecture|Flags" | head -3
echo ""
echo "AVX-512 support:"
lscpu | grep -o 'avx512[^ ]*' | sort -u
echo ""

# Check NVIDIA GPU
echo "=== NVIDIA GPU Check ==="
if command -v nvidia-smi &> /dev/null; then
    nvidia-smi --query-gpu=name,driver_version,compute_cap --format=csv
else
    echo "nvidia-smi not found - no NVIDIA driver installed"
fi
echo ""

# Check PyTorch build configuration
echo "=== PyTorch Configuration ==="
python3.13 << 'EOF'
import torch
print(f"PyTorch version: {torch.__version__}")
print(f"Python version: {torch.__config__.python_version}")
print(f"Build type: {torch.__config__.build_type}")

# Show build configuration (truncated for readability)
config = torch.__config__.show()
print("\nBuild flags (searching for AVX/CUDA):")
for line in config.split('\n'):
    if 'avx' in line.lower() or 'cuda' in line.lower() or 'sm_' in line.lower():
        print(f"  {line}")
EOF
echo ""

# Run performance test
echo "=== Performance Test ==="
python3.13 << 'EOF'
import torch
import time

# CPU Performance Test
print("CPU Matrix Multiplication Benchmark (1000x1000):")
x = torch.randn(1000, 1000)
y = torch.randn(1000, 1000)

# Warmup
for _ in range(10):
    _ = torch.mm(x, y)

# Benchmark
start = time.time()
iterations = 100
for _ in range(iterations):
    z = torch.mm(x, y)
elapsed = time.time() - start

print(f"  {iterations} iterations in {elapsed:.3f}s")
print(f"  Average: {elapsed/iterations*1000:.2f}ms per iteration")
print(f"  Throughput: {iterations/elapsed:.1f} ops/sec")
EOF
echo ""

# Test model inference
echo "=== Model Inference Test ==="
python3.13 << 'EOF'
import torch
import torch.nn as nn

model = nn.Sequential(
    nn.Linear(512, 2048),
    nn.ReLU(),
    nn.Linear(2048, 2048),
    nn.ReLU(),
    nn.Linear(2048, 512),
    nn.ReLU(),
    nn.Linear(512, 10)
)

x = torch.randn(64, 512)

# Test inference
with torch.no_grad():
    output = model(x)

print(f"Input shape: {x.shape}")
print(f"Output shape: {output.shape}")
print(f"Model parameters: {sum(p.numel() for p in model.parameters()):,}")
print("✅ Inference successful")
EOF
echo ""

echo "========================================"
echo "Verification Complete!"
echo "========================================"
