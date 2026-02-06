# Future Session: Refactor and Expand PyTorch Build Recipes

## Objective

1. **Refactor** the remaining PyTorch build recipes to use the working three-overlay pattern established in `pytorch-python313-cuda13_0-sm120-avx512.nix`
2. **Create** new variants to align with TorchVision (sm121-armv8_2, sm121-armv9)

## Background

The `sm120-avx512` variant was fully developed with PyTorch 2.10.0 + CUDA 13.0 support, including:
- Three-overlay pattern (CUDA 13.0 → MAGMA patch → PyTorch 2.10.0)
- All CUDA 13.0 compatibility fixes (CCCL symlinks, version fixes, FindCUDAToolkit stub)
- MAGMA enabled via upstream patch (commit 235aefb7)

The other variants are still using an older nixpkgs pin (`fe5e41d7...`) without these fixes.

## Files to Refactor

### Standard Variants (use overlay pattern)

These use the old nixpkgs pin (`fe5e41d7...`) and need the three-overlay pattern:

| File | GPU Target | CPU ISA | Platform |
|------|------------|---------|----------|
| `.flox/pkgs/pytorch-python313-cuda13_0-sm120-avx.nix` | SM120 (RTX 5090) | AVX | x86_64-linux |
| `.flox/pkgs/pytorch-python313-cuda13_0-sm110-armv8_2.nix` | SM110 (DRIVE Thor) | ARMv8.2 | aarch64-linux |
| `.flox/pkgs/pytorch-python313-cuda13_0-sm110-armv9.nix` | SM110 (DRIVE Thor) | ARMv9 | aarch64-linux |

### Nightly Variant (different architecture)

| File | GPU Target | CPU ISA | Platform |
|------|------------|---------|----------|
| `.flox/pkgs/pytorch-python313-cuda13_0-sm121-armv9-nightly.nix` | SM121 (DGX Spark) | ARMv9 | aarch64-linux |

**Note:** The nightly variant has a completely different architecture:
- Builds PyTorch from scratch using `stdenv.mkDerivation` (not nixpkgs' torch)
- Takes `cudaPackages_13` as an input parameter (requires `--stability=unstable`)
- Uses `pkgs.magma.override` but **does not have the CUDA 13.0 clockRate patch**
- Needs the MAGMA patch added via: `magma = pkgs.magma.override { ... }.overrideAttrs (oldAttrs: { patches = ... })`

## Reference Implementation

Use `.flox/pkgs/pytorch-python313-cuda13_0-sm120-avx512.nix` as the canonical reference.

Key elements to copy:
1. **Nixpkgs pin**: `6a030d535719c5190187c4cec156f335e95e3211`
2. **Three overlays**:
   - Overlay 1: `cudaPackages = final.cudaPackages_13`
   - Overlay 2: MAGMA patch for CUDA 13.0 (`cuda-13.0-clockrate-fix.patch`)
   - Overlay 3: PyTorch 2.10.0 source upgrade
3. **CMake flags**: `-DTORCH_BUILD_VERSION=2.10.0`, `-DCMAKE_CUDA_FLAGS=-I/build/cccl-compat`, `-DCUDA_VERSION=13.0`
4. **preConfigure**: Version fixes, CCCL symlink structure
5. **postPatch**: FindCUDAToolkit.cmake delegating stub

## What to Preserve Per-Variant

Each variant should keep its unique:
- `gpuArchSM` value (e.g., "11.0" for SM110, "12.1" for SM121)
- `cpuFlags` array (e.g., `-march=armv8.2-a+fp16+dotprod` vs `-mavx`)
- `pname`
- `meta.description` and `meta.longDescription`
- `meta.platforms` (`x86_64-linux` vs `aarch64-linux`)

## Post-Refactor Documentation Updates

After refactoring is complete, update:

1. **`/home/daedalus/dev/builds/build-pytorch/docs/pytorch-2.10-cuda13-build-notes.md`**
   - Add section listing all available variants
   - Update any variant-specific notes

2. **`/home/daedalus/dev/builds/build-pytorch/README.md`** (if applicable)
   - Document all available build variants
   - Add build instructions for each target

## New Variants to Create

TorchVision has variants that don't have standalone PyTorch counterparts. Create these for consistency:

| Variant | GPU Target | CPU ISA | Platform | Notes |
|---------|------------|---------|----------|-------|
| `sm121-armv8_2` | SM121 (DGX Spark) | ARMv8.2 | aarch64-linux | Copy from sm120-avx512, adjust gpuArchSM and cpuFlags |
| `sm121-armv9` | SM121 (DGX Spark) | ARMv9 | aarch64-linux | Copy from sm120-avx512, adjust gpuArchSM and cpuFlags |

**Reference for ARM cpuFlags:**
- ARMv8.2: `["-march=armv8.2-a+fp16+dotprod"]`
- ARMv9: `["-march=armv9-a+sve2"]`

## Test Recipe

The file `.flox/pkgs/pytorch-python313-cuda13_0-sm120-avx512-magma.nix` is a test recipe that validated the MAGMA patch approach. It can be deleted once all variants are refactored and tested, or kept as a reference.

## Verification

After refactoring each variant:
1. Check for MAGMA patch overlay: `grep 'cuda-13.0-clockrate-fix.patch' <file>`
2. Check for old MAGMA-disable code: `grep -E 'filterMagma|USE_MAGMA=OFF|USE_MAGMA=0' <file>` (should return nothing)
3. Verify nixpkgs pin: `grep '6a030d535719c5190187c4cec156f335e95e3211' <file>`
4. Build test (if hardware available): `flox build <package-name>`
