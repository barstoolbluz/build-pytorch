# PyTorch optimized for NVIDIA Pascal (SM61: GTX 1070, 1080, 1080 Ti) + AVX2
# Package name: pytorch-python313-cuda12_9-sm61-avx2

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
  };

  # GPU target: SM61 (Pascal consumer architecture - GTX 1070, 1080, 1080 Ti)
  gpuArchNum = "61";  # For CMAKE_CUDA_ARCHITECTURES (just the integer)
  gpuArchSM = "6.1";  # For TORCH_CUDA_ARCH_LIST (dot notation required for older archs)

  # CPU optimization: AVX2 (modern CPU with Pascal GPU)
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
    gpuTargets = [ gpuArchSM ];
  # 2. Customize build (CPU flags, metadata, etc.)
  }).overrideAttrs (oldAttrs: {
    pname = "pytorch-python313-cuda12_9-sm61-avx2";

    # Limit build parallelism to prevent memory saturation
    ninjaFlags = [ "-j32" ];
    requiredSystemFeatures = [ "big-parallel" ];

    preConfigure = (oldAttrs.preConfigure or "") + ''
      export CXXFLAGS="${nixpkgs_pinned.lib.concatStringsSep " " cpuFlags} $CXXFLAGS"
      export CFLAGS="${nixpkgs_pinned.lib.concatStringsSep " " cpuFlags} $CFLAGS"
      export MAX_JOBS=32

      # cuDNN 9.11+ dropped SM < 7.5 support — disable for SM61
      export USE_CUDNN=0

      echo "========================================="
      echo "PyTorch Build Configuration"
      echo "========================================="
      echo "GPU Target: ${gpuArchSM} (Pascal: GTX 1070, 1080, 1080 Ti)"
      echo "CPU Features: AVX2 (broad compatibility)"
      echo "CUDA: 12.9 (pinned nixpkgs)"
      echo "========================================="
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch for NVIDIA GTX 1070/1080 Ti (SM61, Pascal) with AVX2";
      longDescription = ''
        Custom PyTorch build with targeted optimizations:
        - GPU: NVIDIA Pascal consumer architecture (SM61) - GTX 1070, 1080, 1080 Ti
        - CPU: x86-64 with AVX2 instruction set (broad compatibility)
        - CUDA: 12.9 with compute capability 6.1
        - BLAS: cuBLAS for GPU operations
        - Python: 3.13

        Hardware requirements:
        - GPU: GTX 1070, 1080, 1080 Ti, or other SM61 GPUs
        - CPU: Intel Haswell+ (2013+), AMD Zen 1+ (2017+)
        - Driver: NVIDIA 390+ required

        Note: cuDNN is disabled because cuDNN 9.11+ dropped SM < 7.5 support.
        FBGEMM, MKLDNN, and NNPACK are enabled (AVX2+FMA3 available).

        Choose this if: You have a GTX 1070, 1080, or 1080 Ti with a modern
        CPU that supports AVX2 and want CUDA acceleration.
      '';
      platforms = [ "x86_64-linux" ];
    };
  })
