# PyTorch 2.9.1 optimized for NVIDIA Blackwell (SM120: RTX 5090) + AVX-512
# Package name: pytorch-python313-cuda13_0-sm120-avx512

{ pkgs ? import <nixpkgs> {} }:

let
  # Import nixpkgs at a specific revision with CUDA 13.0 and PyTorch 2.9.1
  nixpkgs_pinned = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/6a030d535719c5190187c4cec156f335e95e3211.tar.gz";
  }) {
    config = {
      allowUnfree = true;
      allowBroken = true;
      cudaSupport = true;
    };
    overlays = [
      (final: prev: { cudaPackages = final.cudaPackages_13; })
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
    pname = "pytorch-python313-cuda13_0-sm120-avx512";

    # Remove MAGMA from all dependency lists - incompatible with CUDA 13.0
    buildInputs = filterMagma (oldAttrs.buildInputs or []);
    nativeBuildInputs = filterMagma (oldAttrs.nativeBuildInputs or []);
    propagatedBuildInputs = filterMagma (oldAttrs.propagatedBuildInputs or []);

    # Limit build parallelism to prevent memory saturation
    ninjaFlags = [ "-j32" ];
    requiredSystemFeatures = [ "big-parallel" ];

    # CMake flags to disable MAGMA at build configuration time
    cmakeFlags = (oldAttrs.cmakeFlags or []) ++ [
      "-DUSE_MAGMA=OFF"
    ];

    preConfigure = (oldAttrs.preConfigure or "") + ''
      export CXXFLAGS="${nixpkgs_pinned.lib.concatStringsSep " " cpuFlags} $CXXFLAGS"
      export CFLAGS="${nixpkgs_pinned.lib.concatStringsSep " " cpuFlags} $CFLAGS"
      export MAX_JOBS=32

      # Disable MAGMA - incompatible with CUDA 13.0 (clockRate removed from cudaDeviceProp)
      export USE_MAGMA=0

      echo "========================================="
      echo "PyTorch Build Configuration"
      echo "========================================="
      echo "GPU Target: ${gpuArchSM} (Blackwell: RTX 5090)"
      echo "CPU Features: AVX-512"
      echo "CUDA: 13.0 (pinned nixpkgs)"
      echo "MAGMA: Disabled (CUDA 13.0 incompatibility)"
      echo "========================================="
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch 2.9.1 for NVIDIA RTX 5090 (SM120, Blackwell) + AVX-512";
      longDescription = ''
        Custom PyTorch build with targeted optimizations:
        - GPU: NVIDIA Blackwell consumer architecture (SM120) - RTX 5090
        - CPU: x86-64 with AVX-512 instruction set
        - CUDA: 13.0 with compute capability 12.0
        - PyTorch: 2.9.1
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
