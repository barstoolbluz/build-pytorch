# GPU Architecture Format Fix

## The Problem

PyTorch's build system requires **two different architecture formats**:

1. **TORCH_CUDA_ARCH_LIST**: Needs `sm_XX` format (e.g., `sm_90`)
   - Used by PyTorch's internal CMake script `select_compute_arch.cmake`
   - This script validates against known architectures

2. **CMAKE_CUDA_ARCHITECTURES**: Needs integer format (e.g., `90`)
   - Used by CMake's CUDA language support
   - Validates the format (must be integers or special values)

## Build Errors Encountered

### Error 1: CMAKE_CUDA_ARCHITECTURES format
```
CMake Error: CMAKE_CUDA_ARCHITECTURES: 9.0
is not one of the following:
  * a semicolon-separated list of integers
```
**Cause:** Used "9.0" instead of "90"

### Error 2: Unknown CUDA Architecture
```
CMake Error: Found Unknown CUDA Architecture Name in CUDA_SELECT_NVCC_ARCH_FLAGS: 90
```
**Cause:** Used "90" for TORCH_CUDA_ARCH_LIST instead of "sm_90"

## The Solution

Define **both formats** in the Nix expression:

```nix
let
  gpuArchNum = "90";     # For CMAKE_CUDA_ARCHITECTURES (integer)
  gpuArchSM = "sm_90";   # For TORCH_CUDA_ARCH_LIST (with sm_ prefix)

  cpuFlags = [ ... ];
in
  (python3Packages.pytorch.override {
    cudaSupport = true;
  }).overrideAttrs (oldAttrs: {
    pname = "pytorch-python313-cuda12_8-sm90-avx512";

    preConfigure = (oldAttrs.preConfigure or "") + ''
      # Use the correct format for each variable
      export TORCH_CUDA_ARCH_LIST="${gpuArchSM}"      # sm_90
      export CMAKE_CUDA_ARCHITECTURES="${gpuArchNum}"  # 90

      # ... rest of configuration
    '';
  })
```

## Architecture Mappings

| GPU | Compute Cap | gpuArchNum | gpuArchSM |
|-----|-------------|------------|-----------|
| RTX 5090 | SM120 | "120" | "sm_120" |
| H100, L40S | SM90 | "90" | "sm_90" |
| RTX 4090, L4 | SM89 | "89" | "sm_89" |
| RTX 3090, A40 | SM86 | "86" | "sm_86" |
| A100 | SM80 | "80" | "sm_80" |
| T4, RTX 20xx | SM75 | "75" | "sm_75" |

## Why This Happens

PyTorch wraps CMake's CUDA support with its own validation layer:

1. **CMake level** (`CMAKE_CUDA_ARCHITECTURES`):
   - Native CMake CUDA support
   - Expects integer compute capability (60, 70, 75, 80, 86, 89, 90, etc.)
   - Validates format only (integers, semicolons, or special values)

2. **PyTorch level** (`TORCH_CUDA_ARCH_LIST`):
   - PyTorch's `select_compute_arch.cmake` script
   - Maintains a list of known architectures in `sm_XX` format
   - Validates against this known list
   - Converts to gencode flags for nvcc

## Testing the Fix

After applying the fix, rebuild:
```bash
flox build pytorch-python313-cuda12_8-sm90-avx512
```

Check the build output for:
```
-- Found CUDA: ... (found version "12.8")
USE_CUDA              : ON
TORCH_CUDA_ARCH_LIST  : sm_90
CMAKE_CUDA_ARCHITECTURES: 90
```

Both should now be accepted without errors.
