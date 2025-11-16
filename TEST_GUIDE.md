# PyTorch Build Testing Guide

## Quick Start

### Test a Specific Build

```bash
# Test the build you just created
./test-build.sh pytorch-python313-cuda12_8-sm120-avx512

# Test SM86 build
./test-build.sh pytorch-python313-cuda12_8-sm86-avx2

# Test CPU-only build
./test-build.sh pytorch-python313-cpu-avx2
```

### Auto-Detection

```bash
# If you have only one build, it will auto-detect
./test-build.sh

# If multiple builds exist, it will list them
./test-build.sh
# Output:
#   Multiple builds found:
#     - pytorch-python313-cuda12_8-sm120-avx512
#     - pytorch-python313-cuda12_8-sm86-avx2
#   Please specify which build to test: ./test-build.sh <build-name>
```

## What the Test Does

The test script (`test-build.sh`) performs 5 comprehensive tests:

### Test 1: PyTorch Import & Version
- Verifies PyTorch can be imported
- Shows version and installation path
- **Exit on failure**: Yes - if PyTorch cannot be imported

### Test 2: CUDA Support (GPU builds only)
- Checks if CUDA is built into PyTorch
- Shows CUDA version, cuDNN version
- Lists compiled GPU architectures
- Detects available GPUs
- **Exit on failure**: Yes - if CUDA support is missing from CUDA build

### Test 3: CPU Inference
- Creates a simple neural network
- Runs inference on CPU
- Validates output shapes
- **Exit on failure**: Yes - basic functionality must work

### Test 4: GPU Inference (GPU builds only)
- **Architecture compatibility check**: Compares GPU hardware vs. compiled architectures
- If mismatch detected: Skips test gracefully (not a failure)
- If compatible: Runs GPU inference and matrix multiplication
- **Exit on failure**: Only if unexpected errors occur

### Test 5: Build Configuration
- Verifies build name matches package
- Shows MKL/MKL-DNN availability
- Confirms expected architecture is compiled
- **Exit on failure**: No - informational only

## Understanding Test Output

### Successful Test (Compatible GPU)

```bash
$ ./test-build.sh pytorch-python313-cuda12_8-sm120-avx512

========================================
PyTorch Build Test
========================================
Build: pytorch-python313-cuda12_8-sm120-avx512
Path: /nix/store/xxx-pytorch-python313-cuda12_8-sm120-avx512-2.8.0
CUDA build: true

========================================
Test 1: PyTorch Import & Version
========================================
✓ PyTorch version: 2.8.0
  Python: 3.13.5
  Install path: ...

========================================
Test 2: CUDA Support
========================================
CUDA built: True
CUDA available: True
CUDA version: 12.8
cuDNN version: 91100
Compiled arch list: ['sm_120']
GPU count: 1
GPU 0: NVIDIA GeForce RTX 5090
  Compute capability: 12.0
  Memory: 31.4 GB

========================================
Test 3: CPU Inference
========================================
✓ Input shape: torch.Size([32, 512])
✓ Output shape: torch.Size([32, 10])
✓ Model parameters: 1,055,242
✓ CPU inference successful!

========================================
Test 4: GPU Inference
========================================
GPU compute capability: 12.0
Compiled architectures: ['sm_120']
✓ Input device: cuda:0
✓ Output device: cuda:0
✓ Output shape: torch.Size([32, 10])
✓ Matrix multiplication: torch.Size([1000, 1000])
✓ GPU inference successful!

========================================
Test 5: Build Configuration
========================================
Package name: pytorch-python313-cuda12_8-sm120-avx512
PyTorch version: 2.8.0
MKL available: False
MKL-DNN available: True
CUDA architectures: ['sm_120']
✓ Expected architecture found in build

========================================
Test Summary
========================================
✓ Build: pytorch-python313-cuda12_8-sm120-avx512
✓ PyTorch imported successfully
✓ CPU inference working
✓ CUDA support verified
✓ GPU inference working (or skipped due to arch mismatch)

✓ All tests passed!
========================================
```

### Architecture Mismatch (Expected Behavior)

When testing an SM86 build on an RTX 5090 (SM120) GPU:

```bash
$ ./test-build.sh pytorch-python313-cuda12_8-sm86-avx2

========================================
Test 4: GPU Inference
========================================
GPU compute capability: 12.0
Compiled architectures: ['sm_86']
⚠ WARNING: GPU architecture 12.0 not in compiled list ['sm_86']
  This build is targeted for a different GPU architecture
  GPU operations will fail - this is expected behavior

========================================
Test Summary
========================================
✓ Build: pytorch-python313-cuda12_8-sm86-avx2
✓ PyTorch imported successfully
✓ CPU inference working
✓ CUDA support verified
✓ GPU inference working (or skipped due to arch mismatch)

✓ All tests passed!
========================================
```

**This is NOT a failure** - it confirms the build is correctly targeted for a specific GPU architecture.

## GPU Architecture Compatibility

| Build Variant | Compiled For | Works On | Notes |
|---------------|--------------|----------|-------|
| `sm120-*` | RTX 5090 (Blackwell) | RTX 5090+ | Native support |
| `sm90-*` | H100, L40S (Hopper) | H100, L40S, and newer | Native support |
| `sm86-*` | RTX 3090, A40 (Ampere) | RTX 3090, A40, A5000 | Native support |
| `sm120-*` | RTX 5090 | RTX 3090 | ❌ Won't work (backward incompatible) |
| `sm86-*` | RTX 3090 | RTX 5090 | ❌ Won't work (forward incompatible) |

**Key Point**: PyTorch CUDA builds are architecture-specific. An SM86 build will only work on SM86 GPUs.

## Comparison with Old Test Scripts

### Old Scripts (test.sh, test-cuda.sh, test-detailed.sh)

❌ **Problems:**
- Hardcoded to `result-pytorch-python313-cuda12_8-sm90-avx512`
- Won't work for SM86 or SM120 builds
- No architecture mismatch handling
- No auto-detection

### New Script (test-build.sh)

✅ **Improvements:**
- Accepts any build name as parameter
- Auto-detects builds when only one exists
- Gracefully handles architecture mismatches
- Better error messages
- Colored output for readability
- Comprehensive test coverage
- Works for CUDA and CPU-only builds

## When to Use This Script

### After Building

```bash
# Build
flox build pytorch-python313-cuda12_8-sm120-avx512

# Test immediately
./test-build.sh pytorch-python313-cuda12_8-sm120-avx512
```

### Before Publishing

Always test before publishing to FloxHub:

```bash
# Test
./test-build.sh pytorch-python313-cuda12_8-sm120-avx512

# If all tests pass, publish
flox publish -o <your-org> pytorch-python313-cuda12_8-sm120-avx512
```

### Verifying Published Packages

After installing from FloxHub:

```bash
# Install
flox install <org>/pytorch-python313-cuda12_8-sm120-avx512

# Test (adjust path to installed location)
# This script works on local builds only
```

## Troubleshooting

### "Result directory not found"

**Problem**: The result symlink doesn't exist.

**Solution**: Build first with `flox build <package-name>`

### "CUDA built but no GPU available"

**Problem**: PyTorch is built with CUDA support, but no GPU is detected.

**Possible causes:**
- No NVIDIA GPU in system
- NVIDIA driver not installed
- Testing on a headless system without GPU

**Note**: This is a warning, not an error. CPU inference will still work.

### "GPU architecture mismatch"

**Problem**: Testing an SM86 build on an RTX 5090, or vice versa.

**Solution**: This is expected behavior! Build the correct variant for your GPU:
- RTX 5090 → use SM120 builds
- RTX 3090/A40 → use SM86 builds
- H100/L40S → use SM90 builds

## Exit Codes

- **0**: All tests passed (or skipped gracefully)
- **1**: Test failure (import failed, CPU inference failed, or unexpected error)

## Integration with CI/CD

```bash
#!/bin/bash
# Example CI/CD script

set -e

# Build all variants
for variant in sm120-avx512 sm86-avx2 cpu-avx2; do
    echo "Building pytorch-python313-cuda12_8-${variant}..."
    flox build pytorch-python313-cuda12_8-${variant}

    echo "Testing pytorch-python313-cuda12_8-${variant}..."
    ./test-build.sh pytorch-python313-cuda12_8-${variant}

    echo "Publishing pytorch-python313-cuda12_8-${variant}..."
    flox publish -o myorg pytorch-python313-cuda12_8-${variant}
done
```

## Summary

Use `test-build.sh` for:
- ✅ Testing any PyTorch build variant
- ✅ Verifying CUDA support
- ✅ Validating architecture compatibility
- ✅ Pre-publication verification
- ✅ Debugging build issues

The script is intelligent enough to handle architecture mismatches gracefully, making it safe to test any build on any hardware.
