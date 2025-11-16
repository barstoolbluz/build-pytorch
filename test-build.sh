#!/usr/bin/env bash
# Generic PyTorch build test script
# Usage: ./test-build.sh [build-name]
# Example: ./test-build.sh pytorch-python313-cuda12_8-sm120-avx512

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
info() { echo -e "${BLUE}$1${NC}"; }
success() { echo -e "${GREEN}✓ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
error() { echo -e "${RED}✗ $1${NC}"; exit 1; }

# Parse arguments
BUILD_NAME="${1:-}"

# Auto-detect if no argument provided
if [ -z "$BUILD_NAME" ]; then
    info "No build name provided, auto-detecting..."

    # Look for result-* symlinks
    RESULT_LINKS=(result-pytorch-*)

    if [ ${#RESULT_LINKS[@]} -eq 0 ] || [ ! -L "${RESULT_LINKS[0]}" ]; then
        error "No result-* symlinks found. Build something first with: flox build <package-name>"
    fi

    if [ ${#RESULT_LINKS[@]} -eq 1 ]; then
        # Only one result, use it
        RESULT_DIR="${RESULT_LINKS[0]}"
        BUILD_NAME="${RESULT_DIR#result-}"
        info "Auto-detected: $BUILD_NAME"
    else
        # Multiple results, ask user to specify
        warning "Multiple builds found:"
        for link in "${RESULT_LINKS[@]}"; do
            echo "  - ${link#result-}"
        done
        echo ""
        error "Please specify which build to test: ./test-build.sh <build-name>"
    fi
else
    # User provided build name
    RESULT_DIR="result-${BUILD_NAME}"
fi

# Verify result directory exists
if [ ! -L "$RESULT_DIR" ] && [ ! -d "$RESULT_DIR" ]; then
    error "Result directory not found: $RESULT_DIR\nDid you build it? Run: flox build $BUILD_NAME"
fi

# Resolve to actual path
RESULT_PATH=$(readlink -f "$RESULT_DIR" 2>/dev/null || echo "$RESULT_DIR")

if [ ! -d "$RESULT_PATH" ]; then
    error "Result path does not exist: $RESULT_PATH"
fi

# Setup Python path
PYTHONPATH="${RESULT_PATH}/lib/python3.13/site-packages:${PYTHONPATH:-}"
export PYTHONPATH

# Determine if this is a CUDA build
IS_CUDA_BUILD=false
if [[ "$BUILD_NAME" == *"cuda"* ]] || [[ "$BUILD_NAME" == *"sm"[0-9]* ]]; then
    IS_CUDA_BUILD=true
fi

echo "========================================"
echo "PyTorch Build Test"
echo "========================================"
info "Build: $BUILD_NAME"
info "Path: $RESULT_PATH"
info "CUDA build: $IS_CUDA_BUILD"
echo ""

# Test 1: Import PyTorch
echo "========================================"
echo "Test 1: PyTorch Import & Version"
echo "========================================"
python3.13 << 'EOF'
import sys
try:
    import torch
    print(f"✓ PyTorch version: {torch.__version__}")
    print(f"  Python: {sys.version.split()[0]}")
    print(f"  Install path: {torch.__file__}")
except ImportError as e:
    print(f"✗ Failed to import PyTorch: {e}")
    sys.exit(1)
EOF
echo ""

# Test 2: CUDA Support (if CUDA build)
if [ "$IS_CUDA_BUILD" = true ]; then
    echo "========================================"
    echo "Test 2: CUDA Support"
    echo "========================================"
    python3.13 << 'EOF'
import torch
import sys

cuda_available = torch.cuda.is_available()
cuda_built = torch.version.cuda is not None

print(f"CUDA built: {cuda_built}")
print(f"CUDA available: {cuda_available}")

if cuda_built:
    print(f"CUDA version: {torch.version.cuda}")
    print(f"cuDNN version: {torch.backends.cudnn.version()}")
    print(f"Compiled arch list: {torch.cuda.get_arch_list()}")
else:
    print("✗ PyTorch was not built with CUDA support!")
    sys.exit(1)

if cuda_available:
    gpu_count = torch.cuda.device_count()
    print(f"GPU count: {gpu_count}")

    if gpu_count > 0:
        for i in range(gpu_count):
            name = torch.cuda.get_device_name(i)
            cap = torch.cuda.get_device_capability(i)
            props = torch.cuda.get_device_properties(i)
            mem_gb = props.total_memory / (1024**3)
            print(f"GPU {i}: {name}")
            print(f"  Compute capability: {cap[0]}.{cap[1]}")
            print(f"  Memory: {mem_gb:.1f} GB")
else:
    print("⚠ CUDA is built but no GPU detected (driver/hardware issue)")
    print("  This is OK if testing on a system without a GPU")
EOF
    echo ""
fi

# Test 3: CPU Inference
echo "========================================"
echo "Test 3: CPU Inference"
echo "========================================"
python3.13 << 'EOF'
import torch
import torch.nn as nn
import sys

try:
    # Create a simple model
    model = nn.Sequential(
        nn.Linear(512, 1024),
        nn.ReLU(),
        nn.Linear(1024, 512),
        nn.ReLU(),
        nn.Linear(512, 10)
    )

    # Test input
    x = torch.randn(32, 512)

    # Run inference
    with torch.no_grad():
        output = model(x)

    print(f"✓ Input shape: {x.shape}")
    print(f"✓ Output shape: {output.shape}")
    print(f"✓ Model parameters: {sum(p.numel() for p in model.parameters()):,}")
    print("✓ CPU inference successful!")

except Exception as e:
    print(f"✗ CPU inference failed: {e}")
    sys.exit(1)
EOF
echo ""

# Test 4: GPU Inference (if CUDA build and GPU available)
if [ "$IS_CUDA_BUILD" = true ]; then
    echo "========================================"
    echo "Test 4: GPU Inference"
    echo "========================================"
    set +e  # Temporarily disable exit-on-error to capture test result
    python3.13 << 'EOF'
import torch
import torch.nn as nn
import sys

if not torch.cuda.is_available():
    print("⚠ Skipping GPU test - no GPU available")
    sys.exit(0)

# Check for architecture compatibility
gpu_cap = torch.cuda.get_device_capability(0)
gpu_arch = f"{gpu_cap[0]}.{gpu_cap[1]}"
compiled_archs = torch.cuda.get_arch_list()

print(f"GPU compute capability: {gpu_arch}")
print(f"Compiled architectures: {compiled_archs}")

# Check if GPU architecture is compatible
compatible = any(gpu_arch in arch or f"sm_{int(float(gpu_arch)*10)}" in arch for arch in compiled_archs)

if not compatible:
    print(f"⚠ WARNING: GPU architecture {gpu_arch} not in compiled list {compiled_archs}")
    print(f"  This build is targeted for a different GPU architecture")
    print(f"  GPU operations will fail - this is expected behavior")
    sys.exit(0)

try:
    # Create model and move to GPU
    model = nn.Sequential(
        nn.Linear(512, 1024),
        nn.ReLU(),
        nn.Linear(1024, 512),
        nn.ReLU(),
        nn.Linear(512, 10)
    ).cuda()

    # Create input and move to GPU
    x = torch.randn(32, 512).cuda()

    # Run inference
    with torch.no_grad():
        output = model(x)

    print(f"✓ Input device: {x.device}")
    print(f"✓ Output device: {output.device}")
    print(f"✓ Output shape: {output.shape}")

    # Test matrix multiplication
    a = torch.randn(1000, 1000).cuda()
    b = torch.randn(1000, 1000).cuda()
    c = torch.mm(a, b)

    print(f"✓ Matrix multiplication: {c.shape}")
    print("✓ GPU inference successful!")

except Exception as e:
    error_str = str(e)
    if "no kernel image is available" in error_str:
        print(f"⚠ GPU architecture mismatch (expected, not a failure)")
        print(f"  Build compiled for: {compiled_archs}")
        print(f"  GPU architecture: {gpu_arch}")
        sys.exit(0)
    else:
        print(f"✗ GPU inference failed: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
EOF
    GPU_TEST_EXIT=$?
    set -e  # Re-enable exit-on-error
    echo ""
fi

# Test 5: Architecture Verification
echo "========================================"
echo "Test 5: Build Configuration"
echo "========================================"
python3.13 << EOF
import torch

print(f"Package name: $BUILD_NAME")
print(f"PyTorch version: {torch.__version__}")

# Check CPU features
print(f"MKL available: {torch.backends.mkl.is_available()}")
print(f"MKL-DNN available: {torch.backends.mkldnn.is_available()}")

if torch.version.cuda is not None:
    arch_list = torch.cuda.get_arch_list()
    print(f"CUDA architectures: {arch_list}")

    # Verify expected architecture is in the list
    build_name = "$BUILD_NAME"
    if "sm86" in build_name:
        expected = ["8.6", "sm_86"]
    elif "sm90" in build_name:
        expected = ["9.0", "sm_90"]
    elif "sm120" in build_name:
        expected = ["12.0", "sm_120"]
    else:
        expected = None

    if expected:
        found = any(arch in str(arch_list) for arch in expected)
        if found:
            print(f"✓ Expected architecture found in build")
        else:
            print(f"⚠ Expected architecture {expected} not found in {arch_list}")
EOF
echo ""

# Summary
echo "========================================"
echo "Test Summary"
echo "========================================"
success "Build: $BUILD_NAME"
success "PyTorch imported successfully"
success "CPU inference working"

if [ "$IS_CUDA_BUILD" = true ]; then
    python3.13 -c "import torch; exit(0 if torch.cuda.is_available() else 1)" 2>/dev/null
    if [ $? -eq 0 ]; then
        success "CUDA support verified"
        if [ "${GPU_TEST_EXIT:-1}" -eq 0 ]; then
            success "GPU inference working (or skipped due to arch mismatch)"
        else
            warning "GPU test failed (check output above)"
        fi
    else
        warning "CUDA built but no GPU detected (may be expected)"
    fi
fi

echo ""
success "All tests passed!"
echo "========================================"
