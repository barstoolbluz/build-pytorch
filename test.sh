#!/usr/bin/env bash

# The result is a Python package, not a full Python environment
# We need to add it to PYTHONPATH and use system Python

export PYTHONPATH="/home/daedalus/dev/builds/build-pytorch/result-pytorch-python313-cuda12_8-sm90-avx512/lib/python3.13/site-packages:$PYTHONPATH"

python3.13 << 'EOF'
import torch
import torch.nn as nn

print("========================================")
print("PyTorch Build Test")
print("========================================")
print(f"PyTorch version: {torch.__version__}")
print(f"CUDA available: {torch.cuda.is_available()}")
if torch.cuda.is_available():
    print(f"CUDA version: {torch.version.cuda}")
    print(f"GPU count: {torch.cuda.device_count()}")
    if torch.cuda.device_count() > 0:
        print(f"GPU 0: {torch.cuda.get_device_name(0)}")

# Check compiled architectures
print(f"\nCompiled CUDA architectures: {torch.cuda.get_arch_list() if torch.cuda.is_available() else 'N/A'}")

# Create a simple model
model = nn.Sequential(
    nn.Linear(512, 1024),
    nn.ReLU(),
    nn.Linear(1024, 512),
    nn.ReLU(),
    nn.Linear(512, 10)
)

# Test on CPU
print("\n=== CPU Inference Test ===")
x = torch.randn(32, 512)
with torch.no_grad():
    output = model(x)
print(f"Output shape: {output.shape}")
print(f"Output sample: {output[0][:5]}")
print("✅ CPU inference working!")

# Test on GPU if available
if torch.cuda.is_available():
    print("\n=== GPU Inference Test ===")
    model_gpu = model.cuda()
    x_gpu = x.cuda()
    with torch.no_grad():
        output_gpu = model_gpu(x_gpu)
    print(f"Output shape: {output_gpu.shape}")
    print(f"Output sample: {output_gpu[0][:5]}")
    print("✅ GPU inference working!")
else:
    print("\n⚠️  No GPU available for testing")

print("\n========================================")
print("All tests passed!")
print("========================================")
EOF
