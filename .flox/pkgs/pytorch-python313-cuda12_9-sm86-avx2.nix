# PyTorch optimized for NVIDIA Ampere (SM86: RTX 3090, A40) + AVX2
# Package name: pytorch-python313-cuda12_9-sm86-avx2

{ pkgs ? import <nixpkgs> {} }:

let
  # Import nixpkgs at a specific revision with CUDA 12.9
  nixpkgs_pinned = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/6a030d535719c5190187c4cec156f335e95e3211.tar.gz";
  }) {
    config = {
      allowUnfree = true;
      cudaSupport = true;
    };
    overlays = [
      (final: prev: { cudaPackages = final.cudaPackages_12_9; })
    ];
  };
  # GPU target: SM86 (Ampere architecture - RTX 3090, A5000, A40)
  # PyTorch's CMake accepts numeric format (8.6) not sm_86
  gpuArchNum = "8.6";

  # CPU optimization: AVX2 (broader compatibility)
  cpuFlags = [
    "-mavx2"       # AVX2 instructions
    "-mfma"        # Fused multiply-add
    "-mf16c"       # Half-precision conversions
  ];

in
  # Two-stage override:
  # 1. Enable CUDA and specify GPU targets
  (nixpkgs_pinned.python3Packages.torch.override {
    cudaSupport = true;
    gpuTargets = [ gpuArchNum ];
  # 2. Customize build (CPU flags, metadata, etc.)
  }).overrideAttrs (oldAttrs: {
    pname = "pytorch-python313-cuda12_9-sm86-avx2";

    # Limit build parallelism to prevent memory saturation
    ninjaFlags = [ "-j32" ];
    requiredSystemFeatures = [ "big-parallel" ];

    # Set CPU optimization flags
    # GPU architecture is handled by nixpkgs via gpuTargets parameter
    preConfigure = (oldAttrs.preConfigure or "") + ''
      export CXXFLAGS="${nixpkgs_pinned.lib.concatStringsSep " " cpuFlags} $CXXFLAGS"
      export CFLAGS="${nixpkgs_pinned.lib.concatStringsSep " " cpuFlags} $CFLAGS"
      export MAX_JOBS=32

      echo "========================================="
      echo "PyTorch Build Configuration"
      echo "========================================="
      echo "GPU Target: ${gpuArchNum} (Ampere: RTX 3090, A5000, A40)"
      echo "CPU Features: AVX2 (broad compatibility)"
      echo "CUDA: 12.9 (cudaSupport=true, gpuTargets=[${gpuArchNum}])"
      echo "CXXFLAGS: $CXXFLAGS"
      echo "========================================="
    '';

    postInstall = (oldAttrs.postInstall or "") + ''
      echo 1 > $out/.metadata-rev
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch for NVIDIA RTX 3090/A40 (SM86, Ampere) with CUDA";
      longDescription = ''
        Custom PyTorch build with targeted optimizations:
        - GPU: NVIDIA Ampere architecture (SM86) - RTX 3090, A5000, A40
        - CPU: x86-64 with AVX2 instruction set (broad compatibility)
        - CUDA: 12.9 with compute capability 8.6
        - BLAS: cuBLAS for GPU operations
        - Python: 3.13

        Hardware requirements:
        - GPU: RTX 3090, RTX 3080 Ti, A5000, A40, or other SM86 GPUs
        - CPU: Intel Haswell+ (2013+), AMD Zen 1+ (2017+) with AVX2
        - Driver: NVIDIA 470+ required

        Choose this if: You have RTX 3090/A40-class GPU and want maximum CPU
        compatibility with AVX2. Newer GPUs (RTX 4090, RTX 5090) will work
        via backward compatibility but won't get architecture-specific kernels.
        For those, use sm90 or sm120 builds instead.
      '';
      platforms = [ "x86_64-linux" ];
    };
  })
