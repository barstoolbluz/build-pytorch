# CUDA Fix Summary

## What Was Wrong

The initial build of `pytorch-python313-cuda12_8-sm90-avx512` completed successfully but produced a **CPU-only** PyTorch package despite:
- Setting `USE_CUDA=1` in build environment
- Adding CUDA packages to buildInputs
- Configuring CUDA architectures

### Build Log Evidence
```
-- Could NOT find CUDA (missing: CUDA_TOOLKIT_ROOT_DIR CUDA_NVCC_EXECUTABLE)
  PyTorch: CUDA cannot be found.
  Not compiling with CUDA.
--   USE_CUDA              : OFF
```

### Runtime Evidence
```bash
$ python -c "import torch; print(torch.cuda.is_available())"
False
```

## Root Cause

**nixpkgs PyTorch defaults to `cudaSupport = false`**

Using `.overrideAttrs` only modifies the build attributes but doesn't change the fundamental derivation configuration. The CUDA support must be enabled at the derivation level using `.override { cudaSupport = true; }` first.

## The Fix

### File Changed
`.flox/pkgs/pytorch-python313-cuda12_8-sm90-avx512.nix`

### Key Changes

1. **Two-stage override pattern:**
```nix
(python3Packages.pytorch.override {
  cudaSupport = true;
}).overrideAttrs (oldAttrs: {
  # custom build configuration
})
```

2. **Simplified GPU architecture:**
```nix
gpuArch = "9.0"  # Changed from "sm_90"
```

3. **Removed manual CUDA dependencies:**
   - Removed manual `buildInputs` with CUDA packages
   - Removed manual `addDriverRunpath` from `nativeBuildInputs`
   - These are now handled automatically by `cudaSupport = true`

4. **Cleaner environment variable setup:**
```nix
export TORCH_CUDA_ARCH_LIST="${gpuArch}"
export CMAKE_CUDA_ARCHITECTURES="${gpuArch}"
```

## Next Steps

1. **Test the fix:**
   ```bash
   flox build pytorch-python313-cuda12_8-sm90-avx512
   ```

2. **Verify CUDA is enabled:**
   ```bash
   ./test-cuda.sh
   ```

   Should show:
   - `CUDA available: True`
   - `CUDA version: 12.x`
   - `Arch list: ['sm_90']`

3. **Apply pattern to all GPU variants:**
   - `pytorch-python313-cuda12_8-sm120-*-cu128.nix` (6 files)
   - `pytorch-python313-cuda12_8-sm86-avx2.nix` (1 file)
   - Total: 7 GPU variant files to update

## GPU Variants to Update

### SM120 variants (RTX 5090):
1. `pytorch-python313-cuda12_8-sm120-avx512-cu128.nix` - gpuArch = "12.0"
2. `pytorch-python313-cuda12_8-sm120-avx2-cu128.nix` - gpuArch = "12.0"
3. `pytorch-python313-cuda12_8-sm120-avx512vnni-cu128.nix` - gpuArch = "12.0"
4. `pytorch-python313-cuda12_8-sm120-avx512bf16-cu128.nix` - gpuArch = "12.0"
5. `pytorch-python313-cuda12_8-sm120-armv9-cu128.nix` - gpuArch = "12.0"
6. `pytorch-python313-cuda12_8-sm120-armv8.2-cu128.nix` - gpuArch = "12.0"

### SM86 variant (RTX 3090):
7. `pytorch-python313-cuda12_8-sm86-avx2.nix` - gpuArch = "8.6"

### SM90 variant (H100) - DONE ✅:
8. `pytorch-python313-cuda12_8-sm90-avx512.nix` - gpuArch = "9.0"

## Testing Strategy

**You have RTX 5090 (SM120), so:**
1. Test SM90 build (won't run on your GPU but tests the build process)
2. Update and test SM120 variant (will actually work on your RTX 5090!)
3. Apply pattern to remaining variants

## Documentation Created

- `CUDA_FIX_PATTERN.md` - Reference pattern for applying the fix
- `CUDA_FIX_SUMMARY.md` - This file, overview of the issue and solution
