# PyTorch 2.10.0 + CUDA 13.0 Build Notes

This document captures the fixes and workarounds required to build PyTorch 2.10.0 with CUDA 13.0 for SM120 (Blackwell RTX 5090) using Nix overlays.

## Overview

- **Purpose**: Upgrade from nixpkgs' PyTorch 2.9.1 to 2.10.0 via overlay
- **Target GPU**: SM120 (Blackwell consumer architecture - RTX 5090)
- **Target CPU**: x86-64 with AVX-512
- **CUDA Version**: 13.0
- **Key Challenge**: Multiple compatibility issues between PyTorch 2.10.0 and CUDA 13.0

---

## The Overlay Pattern

Building PyTorch 2.10.0 with CUDA 13.0 requires a two-overlay approach in Nix:

### Overlay Structure

```nix
overlays = [
  # Overlay 1: Use CUDA 13.0
  (final: prev: { cudaPackages = final.cudaPackages_13; })

  # Overlay 2: Upgrade PyTorch to 2.10.0
  (final: prev: {
    python3Packages = prev.python3Packages.override {
      overrides = pfinal: pprev: {
        torch = pprev.torch.overrideAttrs (oldAttrs: rec {
          version = "2.10.0";

          src = prev.fetchFromGitHub {
            owner = "pytorch";
            repo = "pytorch";
            rev = "v${version}";
            hash = "sha256-RKiZLHBCneMtZKRgTEuW1K7+Jpi+tx11BMXuS1jC1xQ=";
            fetchSubmodules = true;
          };

          # Clear patches - nixpkgs patches are for 2.9.1 and won't apply to 2.10.0
          patches = [];
        });
      };
    };
  })
];
```

### Why `patches = []` is Required

The nixpkgs PyTorch 2.9.1 derivation includes patches that target specific files and line numbers. These patches fail to apply to PyTorch 2.10.0 because:

- File paths may have changed
- Line numbers have shifted
- Some patched code may have been refactored

**Error signature** (without fix):
```
can't find file to patch
```

---

## Fix 1: MAGMA Incompatibility

### Problem

MAGMA 2.9.0 uses the `clockRate` field from `cudaDeviceProp`, which was removed in CUDA 13.0.

### Error Message

```
error: 'struct cudaDeviceProp' has no member named 'clockRate'
```

This error occurs during MAGMA compilation, not PyTorch itself, but MAGMA is a PyTorch build dependency.

### Solution

Disable MAGMA entirely using a three-pronged approach:

1. **Filter MAGMA from dependency lists**:
```nix
# Helper to filter out magma from dependency lists
filterMagma = deps: builtins.filter (d: !(nixpkgs_pinned.lib.hasPrefix "magma" (d.pname or d.name or ""))) deps;

# In overrideAttrs:
buildInputs = filterMagma (oldAttrs.buildInputs or []);
nativeBuildInputs = filterMagma (oldAttrs.nativeBuildInputs or []);
propagatedBuildInputs = filterMagma (oldAttrs.propagatedBuildInputs or []);
```

2. **CMake flag**:
```nix
cmakeFlags = (oldAttrs.cmakeFlags or []) ++ [
  "-DUSE_MAGMA=OFF"
];
```

3. **Environment variable**:
```bash
export USE_MAGMA=0
```

### Impact

Disabling MAGMA affects some linear algebra operations that would otherwise use GPU-accelerated MAGMA routines. PyTorch falls back to cuBLAS/cuSOLVER for these operations.

---

## Fix 2: Version Mismatch

### Problem

When using the overlay to upgrade PyTorch source from 2.9.1 to 2.10.0, the cmake build system may still report the old version, causing a static assertion failure.

### Error Message

```
static assertion failed: std::string requires TORCH_FEATURE_VERSION >= TORCH_VERSION_2_10_0
```

This occurs because PyTorch 2.10.0 code expects to be built as version 2.10.0, but cmake was detecting version 2.9.1 from the overlay base.

### Solution

Override the version in multiple places:

1. **Environment variable** (for setup.py):
```bash
export PYTORCH_BUILD_VERSION=2.10.0
```

2. **Override version.txt** (for cmake):
```bash
echo "2.10.0" > version.txt
```

3. **CMake flag**:
```nix
cmakeFlags = (oldAttrs.cmakeFlags or []) ++ [
  "-DTORCH_BUILD_VERSION=2.10.0"
];
```

---

## Fix 3: CCCL Header Path Compatibility

### Problem

PyTorch 2.10.0's bundled CUTLASS expects CCCL headers at `<cccl/cuda/std/...>` but CUDA 13.0's CCCL provides them at `<cuda/std/...>`.

### Error Message

```
fatal error: cccl/cuda/std/utility: No such file or directory
```

### Solution

Create a compatibility symlink structure in preConfigure:

```bash
# Create compatibility directory
mkdir -p /build/cccl-compat/cccl

# Create symlinks to actual CCCL locations
ln -sf ${nixpkgs_pinned.cudaPackages.cuda_cccl}/include/cuda /build/cccl-compat/cccl/cuda
ln -sf ${nixpkgs_pinned.cudaPackages.cuda_cccl}/include/cub /build/cccl-compat/cccl/cub
ln -sf ${nixpkgs_pinned.cudaPackages.cuda_cccl}/include/thrust /build/cccl-compat/cccl/thrust
ln -sf ${nixpkgs_pinned.cudaPackages.cuda_cccl}/include/nv /build/cccl-compat/cccl/nv

# Add to include paths
export CXXFLAGS="-I/build/cccl-compat $CXXFLAGS"
export CFLAGS="-I/build/cccl-compat $CFLAGS"
export CUDAFLAGS="-I/build/cccl-compat $CUDAFLAGS"
```

Also add to cmake flags:
```nix
cmakeFlags = (oldAttrs.cmakeFlags or []) ++ [
  "-DCMAKE_CUDA_FLAGS=-I/build/cccl-compat"
];
```

---

## Fix 4: FindCUDAToolkit.cmake Install Error

### Problem

The PyTorch install phase tries to copy `cmake/Modules/FindCUDAToolkit.cmake`, but this file doesn't exist in PyTorch 2.10.0 (CMake 3.17+ has native CUDAToolkit support).

### Error Message

```
CMake Error at cmake_install.cmake:148 (file):
  file INSTALL cannot find
  "/build/source/cmake/Modules/FindCUDAToolkit.cmake": No such file or
  directory.
```

### Challenge

A simple empty stub breaks cmake's native CUDA detection during the build phase, causing gloo cmake errors.

### Solution

Create a delegating stub in postPatch that:
1. Checks if CUDAToolkit is already found
2. Temporarily removes our path from CMAKE_MODULE_PATH
3. Includes the real FindCUDAToolkit module
4. Restores module path

```nix
postPatch = (oldAttrs.postPatch or "") + ''
  mkdir -p cmake/Modules
  cat > cmake/Modules/FindCUDAToolkit.cmake << 'EOF'
# Delegating stub for FindCUDAToolkit
# This file exists for the install phase but delegates to cmake's native module
if(NOT CUDAToolkit_FOUND)
  # Save current module path
  set(_orig_module_path "''${CMAKE_MODULE_PATH}")
  # Remove our path so cmake finds the native module
  list(FILTER CMAKE_MODULE_PATH EXCLUDE REGEX "cmake/Modules")
  # Include the real module
  include(FindCUDAToolkit)
  # Restore module path
  set(CMAKE_MODULE_PATH "''${_orig_module_path}")
endif()
EOF
'';
```

---

## Fix 5: Gloo Legacy CUDA Detection

> **Note**: This is a preventative fix. Unlike Fixes 1-4, this addresses a potential issue rather than a specific observed build error.

### Problem

Gloo (PyTorch's collective communication library) uses legacy CUDA detection in its cmake configuration. Without an explicit CUDA version hint, it may fail to properly detect CUDA 13.0.

### Solution

Pass the CUDA version explicitly to cmake:

```nix
cmakeFlags = (oldAttrs.cmakeFlags or []) ++ [
  "-DCUDA_VERSION=13.0"
];
```

This ensures gloo's cmake finds the correct CUDA version even when using its legacy detection path.

---

## Summary Table

| Issue | Error Signature | Fix |
|-------|-----------------|-----|
| MAGMA | `no member named 'clockRate'` | filterMagma + USE_MAGMA=OFF |
| Version | `TORCH_FEATURE_VERSION >= TORCH_VERSION_2_10_0` | version.txt + env var + cmake flag |
| CCCL | `cccl/cuda/std/utility: No such file` | Symlink structure in /build/cccl-compat |
| FindCUDA | `file INSTALL cannot find` | Delegating cmake stub |
| Patches | `can't find file to patch` | `patches = []` |
| Gloo CUDA | *(preventative)* | `-DCUDA_VERSION=13.0` |

---

## Full Working Nix Expression

> **Canonical Reference**: The authoritative implementation is maintained at:
> `.flox/pkgs/pytorch-python313-cuda13_0-sm120-avx512.nix`
>
> The expression below is a snapshot for documentation purposes. Always refer to the canonical file for the latest working version.

```nix
# PyTorch 2.10.0 optimized for NVIDIA Blackwell (SM120: RTX 5090) + AVX-512
# Package name: pytorch210-python313-cuda13_0-sm120-avx512
#
# NOTE: This attempts to upgrade PyTorch from 2.9.1 to 2.10.0 via overlay.
# Submodule compatibility is not guaranteed - build may fail if submodules changed.

{ pkgs ? import <nixpkgs> {} }:

let
  # Import nixpkgs at a specific revision with CUDA 13.0
  nixpkgs_pinned = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/6a030d535719c5190187c4cec156f335e95e3211.tar.gz";
  }) {
    config = {
      allowUnfree = true;
      allowBroken = true;
      cudaSupport = true;
    };
    overlays = [
      # Overlay 1: Use CUDA 13.0
      (final: prev: { cudaPackages = final.cudaPackages_13; })

      # Overlay 2: Upgrade PyTorch to 2.10.0
      (final: prev: {
        python3Packages = prev.python3Packages.override {
          overrides = pfinal: pprev: {
            torch = pprev.torch.overrideAttrs (oldAttrs: rec {
              version = "2.10.0";

              # Override the source - this replaces the vendored src.nix approach
              # with a direct fetchFromGitHub. Submodules are fetched separately
              # by nixpkgs' src.nix, so this may cause issues if submodule
              # revisions changed between 2.9.1 and 2.10.0.
              src = prev.fetchFromGitHub {
                owner = "pytorch";
                repo = "pytorch";
                rev = "v${version}";
                hash = "sha256-RKiZLHBCneMtZKRgTEuW1K7+Jpi+tx11BMXuS1jC1xQ=";
                fetchSubmodules = true;
              };

              # Clear patches in the overlay - nixpkgs patches are for 2.9.1 and won't apply to 2.10.0
              patches = [];
            });
          };
        };
      })
    ];
  };

  # GPU target: SM120 (Blackwell consumer - RTX 5090)
  gpuArchNum = "120";
  gpuArchSM = "12.0";

  # CPU optimization: AVX-512
  cpuFlags = [
    "-mavx512f"    # AVX-512 Foundation
    "-mavx512dq"   # Doubleword and Quadword instructions
    "-mavx512vl"   # Vector Length extensions
    "-mavx512bw"   # Byte and Word instructions
    "-mfma"        # Fused multiply-add
  ];

  # Helper to filter out magma from dependency lists
  filterMagma = deps: builtins.filter (d: !(nixpkgs_pinned.lib.hasPrefix "magma" (d.pname or d.name or ""))) deps;

in
  (nixpkgs_pinned.python3Packages.torch.override {
    cudaSupport = true;
    gpuTargets = [ gpuArchSM ];
  }).overrideAttrs (oldAttrs: {
    pname = "pytorch210-python313-cuda13_0-sm120-avx512";

    # Clear patches - they reference submodule paths that don't exist in tarball
    patches = [];

    # Remove MAGMA from all dependency lists - incompatible with CUDA 13.0
    buildInputs = filterMagma (oldAttrs.buildInputs or []);
    nativeBuildInputs = filterMagma (oldAttrs.nativeBuildInputs or []);
    propagatedBuildInputs = filterMagma (oldAttrs.propagatedBuildInputs or []);

    # Limit build parallelism to prevent memory saturation
    ninjaFlags = [ "-j32" ];
    requiredSystemFeatures = [ "big-parallel" ];

    # CMake flags to disable MAGMA, fix version, and add CCCL compatibility include path
    cmakeFlags = (oldAttrs.cmakeFlags or []) ++ [
      "-DUSE_MAGMA=OFF"
      "-DTORCH_BUILD_VERSION=2.10.0"
      "-DCMAKE_CUDA_FLAGS=-I/build/cccl-compat"
      # Set CUDA version explicitly for gloo's cmake (it uses legacy CUDA detection)
      "-DCUDA_VERSION=13.0"
    ];

    preConfigure = (oldAttrs.preConfigure or "") + ''
      export CXXFLAGS="${nixpkgs_pinned.lib.concatStringsSep " " cpuFlags} $CXXFLAGS"
      export CFLAGS="${nixpkgs_pinned.lib.concatStringsSep " " cpuFlags} $CFLAGS"
      export MAX_JOBS=32

      # Override version for PyTorch 2.10.0 (setup.py uses this env var)
      export PYTORCH_BUILD_VERSION=2.10.0
      # Also set in version.txt for cmake
      echo "2.10.0" > version.txt

      # Disable MAGMA - incompatible with CUDA 13.0 (clockRate removed from cudaDeviceProp)
      export USE_MAGMA=0

      # Fix CCCL include path compatibility for CUTLASS
      # PyTorch 2.10.0's CUTLASS expects <cccl/cuda/std/...> but CUDA 13.0 has <cuda/std/...>
      # Create a compatibility symlink structure
      mkdir -p /build/cccl-compat/cccl
      ln -sf ${nixpkgs_pinned.cudaPackages.cuda_cccl}/include/cuda /build/cccl-compat/cccl/cuda
      ln -sf ${nixpkgs_pinned.cudaPackages.cuda_cccl}/include/cub /build/cccl-compat/cccl/cub
      ln -sf ${nixpkgs_pinned.cudaPackages.cuda_cccl}/include/thrust /build/cccl-compat/cccl/thrust
      ln -sf ${nixpkgs_pinned.cudaPackages.cuda_cccl}/include/nv /build/cccl-compat/cccl/nv
      export CXXFLAGS="-I/build/cccl-compat $CXXFLAGS"
      export CFLAGS="-I/build/cccl-compat $CFLAGS"
      export CUDAFLAGS="-I/build/cccl-compat $CUDAFLAGS"

      echo "========================================="
      echo "PyTorch Build Configuration"
      echo "========================================="
      echo "GPU Target: ${gpuArchSM} (Blackwell: RTX 5090)"
      echo "CPU Features: AVX-512"
      echo "CUDA: 13.0 (pinned nixpkgs)"
      echo "PyTorch: 2.10.0 (overlay upgrade)"
      echo "MAGMA: Disabled (CUDA 13.0 incompatibility)"
      echo "CCCL: Compatibility symlinks created"
      echo "========================================="
    '';

    # Fix: Create a stub FindCUDAToolkit.cmake file that the install phase expects
    # The stub must delegate to cmake's native module to avoid breaking CUDA detection
    postPatch = (oldAttrs.postPatch or "") + ''
      # Create a delegating cmake module - this finds the real module and includes it
      mkdir -p cmake/Modules
      cat > cmake/Modules/FindCUDAToolkit.cmake << 'EOF'
# Delegating stub for FindCUDAToolkit
# This file exists for the install phase but delegates to cmake's native module
if(NOT CUDAToolkit_FOUND)
  # Save current module path
  set(_orig_module_path "''${CMAKE_MODULE_PATH}")
  # Remove our path so cmake finds the native module
  list(FILTER CMAKE_MODULE_PATH EXCLUDE REGEX "cmake/Modules")
  # Include the real module
  include(FindCUDAToolkit)
  # Restore module path
  set(CMAKE_MODULE_PATH "''${_orig_module_path}")
endif()
EOF
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch 2.10.0 for NVIDIA RTX 5090 (SM120, Blackwell) + AVX-512";
      longDescription = ''
        Custom PyTorch build with targeted optimizations:
        - GPU: NVIDIA Blackwell consumer architecture (SM120) - RTX 5090
        - CPU: x86-64 with AVX-512 instruction set
        - CUDA: 13.0 with compute capability 12.0
        - PyTorch: 2.10.0 (upgraded via overlay)
        - BLAS: cuBLAS for GPU operations
        - Python: 3.13

        Hardware requirements:
        - GPU: RTX 5090, RTX 5080, or other SM120 GPUs
        - CPU: Intel Skylake-X+ (2017+), AMD Zen 4+ (2022+)
        - Driver: NVIDIA 580+ required
      '';
      platforms = [ "x86_64-linux" ];
    };
  })
```

---

## Verification Steps

### Build Verification

After a successful build, verify the output exists:

```bash
# Check build artifacts
ls -la result-pytorch210-python313-cuda13_0-sm120-avx512/

# Verify library files
ls result-pytorch210-python313-cuda13_0-sm120-avx512/lib/python3.13/site-packages/torch/
```

### Runtime Verification

Test that PyTorch loads correctly and detects CUDA:

```python
import torch

# Check PyTorch version
print(f"PyTorch version: {torch.__version__}")

# Check CUDA availability
print(f"CUDA available: {torch.cuda.is_available()}")
print(f"CUDA version: {torch.version.cuda}")

# Check GPU detection
if torch.cuda.is_available():
    print(f"GPU count: {torch.cuda.device_count()}")
    print(f"GPU name: {torch.cuda.get_device_name(0)}")
    print(f"GPU capability: {torch.cuda.get_device_capability(0)}")

# Quick computation test
if torch.cuda.is_available():
    x = torch.randn(1000, 1000, device='cuda')
    y = torch.randn(1000, 1000, device='cuda')
    z = torch.matmul(x, y)
    print(f"Matrix multiplication test: {z.shape}")
```

---

## Known Limitations

1. **MAGMA disabled**: Some sparse matrix operations may be slower without MAGMA GPU acceleration
2. **Overlay fragility**: This approach overrides nixpkgs' torch package and may break if upstream packaging changes significantly
3. **Submodule compatibility**: PyTorch 2.10.0 source is fetched independently; submodule versions may not match what upstream expects
4. **Build time**: Full build takes several hours on a 32-core system

---

## References

- [PyTorch GitHub](https://github.com/pytorch/pytorch)
- [NVIDIA CUDA 13.0 Release Notes](https://docs.nvidia.com/cuda/cuda-toolkit-release-notes/)
- [Nixpkgs CUDA Support](https://nixos.wiki/wiki/CUDA)
- [MAGMA Library](https://icl.utk.edu/magma/)
