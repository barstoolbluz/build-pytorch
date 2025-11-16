# CUDA Configuration Fix Pattern

## Problem
The original `.nix` expressions used `overrideAttrs` directly, which doesn't enable CUDA support in nixpkgs PyTorch. The build would complete but produce CPU-only PyTorch packages.

## Root Cause
- nixpkgs PyTorch has `cudaSupport = false` by default
- Must use `.override { cudaSupport = true; }` first
- Then use `.overrideAttrs` to customize build flags

## Solution Pattern

### Before (CPU-only, broken):
```nix
python3Packages.pytorch.overrideAttrs (oldAttrs: {
  pname = "pytorch-python313-cuda12_8-sm90-avx512";
  # ... build customization
})
```

### After (CUDA-enabled, working):
```nix
(python3Packages.pytorch.override {
  cudaSupport = true;
}).overrideAttrs (oldAttrs: {
  pname = "pytorch-python313-cuda12_8-sm90-avx512";
  # ... build customization
})
```

## Key Changes

1. **Two-stage override:**
   - Stage 1: `.override { cudaSupport = true; }` - Enables CUDA in the derivation
   - Stage 2: `.overrideAttrs (...)` - Customizes build configuration

2. **GPU architecture format (CRITICAL):**
   - **Two different formats needed:**
     - `TORCH_CUDA_ARCH_LIST` needs `sm_XX` format (e.g., "sm_90")
     - `CMAKE_CUDA_ARCHITECTURES` needs integer format (e.g., "90")

   ```nix
   let
     gpuArchNum = "90";     # For CMAKE_CUDA_ARCHITECTURES
     gpuArchSM = "sm_90";   # For TORCH_CUDA_ARCH_LIST
   in
     # ...
     export TORCH_CUDA_ARCH_LIST="${gpuArchSM}"
     export CMAKE_CUDA_ARCHITECTURES="${gpuArchNum}"
   ```

   - Architecture mappings:
     - SM90 → gpuArchNum="90", gpuArchSM="sm_90"
     - SM120 → gpuArchNum="120", gpuArchSM="sm_120"
     - SM86 → gpuArchNum="86", gpuArchSM="sm_86"
     - SM89 → gpuArchNum="89", gpuArchSM="sm_89"

3. **Remove manual CUDA packages:**
   - Don't manually add CUDA packages to `buildInputs`
   - nixpkgs handles this automatically when `cudaSupport = true`

4. **Remove manual `addDriverRunpath`:**
   - Also handled automatically with `cudaSupport = true`

## GPU Architecture Mapping

| GPU Model | Compute Capability | gpuArch Value |
|-----------|-------------------|---------------|
| RTX 5090 | SM120 | "120" |
| H100, L40S | SM90 | "90" |
| RTX 4090 | SM89 | "89" |
| RTX 3090 | SM86 | "86" |
| A100 | SM80 | "80" |

## Testing the Fix

After rebuilding:
```bash
python3.13 -c "
import sys
sys.path.insert(0, './result-pytorch-python313-cuda12_8-sm90-avx512/lib/python3.13/site-packages')
import torch
print(f'CUDA available: {torch.cuda.is_available()}')
print(f'CUDA version: {torch.version.cuda}')
print(f'Arch list: {torch.cuda.get_arch_list()}')
"
```

Should show:
- CUDA available: True
- CUDA version: 12.x
- Arch list: ['sm_90'] (or appropriate architecture)
