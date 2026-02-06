# PyTorch 2.10.0 optimized for NVIDIA Blackwell (SM120: RTX 5090) + AVX-512
# Package name: pytorch210-python313-cuda13_0-sm120-avx512
#
# NOTE: This attempts to upgrade PyTorch from 2.9.1 to 2.10.0 via overlay.
# Submodule compatibility is not guaranteed - build may fail if submodules changed.
#
# MAGMA is enabled via a CUDA 13.0 compatibility patch.
# Patch reference: https://github.com/icl-utk-edu/magma/issues/61

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

      # Overlay 2: Patch MAGMA for CUDA 13.0 compatibility
      # This fixes: 'struct cudaDeviceProp' has no member named 'clockRate'
      # The patch uses cudaDeviceGetAttribute(cudaDevAttrClockRate) instead
      (final: prev: {
        magma = prev.magma.overrideAttrs (oldAttrs: {
          patches = (oldAttrs.patches or []) ++ [
            (final.fetchpatch {
              name = "cuda-13.0-clockrate-fix.patch";
              url = "https://github.com/icl-utk-edu/magma/commit/235aefb7b064954fce09d035c69907ba8a87cbcd.patch";
              hash = "sha256-i9InbxD5HtfonB/GyF9nQhFmok3jZ73RxGcIciGBGvU=";
            })
          ];
        });
      })

      # Overlay 3: Upgrade PyTorch to 2.10.0
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

in
  (nixpkgs_pinned.python3Packages.torch.override {
    cudaSupport = true;
    gpuTargets = [ gpuArchSM ];
  }).overrideAttrs (oldAttrs: {
    pname = "pytorch210-python313-cuda13_0-sm120-avx512";

    # Clear patches - they reference submodule paths that don't exist in tarball
    patches = [];

    # Limit build parallelism to prevent memory saturation
    ninjaFlags = [ "-j32" ];
    requiredSystemFeatures = [ "big-parallel" ];

    # CMake flags for CUDA 13.0 compatibility
    cmakeFlags = (oldAttrs.cmakeFlags or []) ++ [
      "-DTORCH_BUILD_VERSION=2.10.0"
      "-DCMAKE_CUDA_FLAGS=-I/build/cccl-compat"
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

      # Fix CCCL include path compatibility for CUTLASS
      # PyTorch 2.10.0's CUTLASS expects <cccl/cuda/std/...> but CUDA 13.0 has <cuda/std/...>
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
      echo "MAGMA: Enabled (with CUDA 13.0 patch)"
      echo "CCCL: Compatibility symlinks created"
      echo "========================================="
    '';

    # Fix: Create a stub FindCUDAToolkit.cmake file that the install phase expects
    postPatch = (oldAttrs.postPatch or "") + ''
      mkdir -p cmake/Modules
      cat > cmake/Modules/FindCUDAToolkit.cmake << 'EOF'
# Delegating stub for FindCUDAToolkit
if(NOT CUDAToolkit_FOUND)
  set(_orig_module_path "''${CMAKE_MODULE_PATH}")
  list(FILTER CMAKE_MODULE_PATH EXCLUDE REGEX "cmake/Modules")
  include(FindCUDAToolkit)
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
        - MAGMA: Enabled (patched for CUDA 13.0)
        - Python: 3.13

        Hardware requirements:
        - GPU: RTX 5090, RTX 5080, or other SM120 GPUs
        - CPU: Intel Skylake-X+ (2017+), AMD Zen 4+ (2022+)
        - Driver: NVIDIA 580+ required
      '';
      platforms = [ "x86_64-linux" ];
    };
  })
