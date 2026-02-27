# PyTorch optimized for NVIDIA Volta (SM70: V100, Titan V) + AVX-512
# Package name: pytorch-python311-cuda12_9-sm70-avx512

{ pkgs ? import <nixpkgs> {} }:

let
  # Import nixpkgs at a specific revision with CUDA 12.9
  nixpkgs_pinned = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/46336d4d6980ae6f136b45c8507b17787eb186a0.tar.gz";
  }) {
    config = {
      allowUnfree = true;
      cudaSupport = true;
    };
    overlays = [
      (final: prev: { cudaPackages = final.cudaPackages_12_9; })
    ];
  };
  # GPU target: SM70 (Volta architecture - V100, Titan V)
  gpuArchNum = "70";  # For CMAKE_CUDA_ARCHITECTURES (just the integer)
  gpuArchSM = "7.0";  # For TORCH_CUDA_ARCH_LIST (with sm_ prefix)

  # CPU optimization: AVX-512
  cpuFlags = [
    "-mavx512f"    # AVX-512 Foundation
    "-mavx512dq"   # Doubleword and Quadword instructions
    "-mavx512vl"   # Vector Length extensions
    "-mavx512bw"   # Byte and Word instructions
    "-mfma"        # Fused multiply-add
  ];

in
  # First, enable CUDA support via override
  (nixpkgs_pinned.python311Packages.torch.override {
    cudaSupport = true;
    # Specify GPU targets using nixpkgs parameter
    gpuTargets = [ gpuArchSM ];
    # cudaPackages is automatically passed and uses the one from inputs
  }).overrideAttrs (oldAttrs: {
    pname = "pytorch-python311-cuda12_9-sm70-avx512";
    passthru = oldAttrs.passthru // {
      gpuArch = gpuArchSM;
      blasProvider = "cublas";
      cpuISA = "avx512";
    };

    # Limit build parallelism to prevent memory saturation
    ninjaFlags = [ "-j32" ];
    requiredSystemFeatures = [ "big-parallel" ];

    # Set CPU optimization flags
    # GPU architecture is handled by nixpkgs via gpuTargets parameter
    preConfigure = (oldAttrs.preConfigure or "") + ''
      export CXXFLAGS="${nixpkgs_pinned.lib.concatStringsSep " " cpuFlags} $CXXFLAGS"
      export CFLAGS="${nixpkgs_pinned.lib.concatStringsSep " " cpuFlags} $CFLAGS"
      export MAX_JOBS=32

      # cuDNN 9.11+ dropped SM < 7.5 support — disable for SM70
      export USE_CUDNN=0

      echo "========================================="
      echo "PyTorch Build Configuration"
      echo "========================================="
      echo "GPU Target: ${gpuArchSM} (Volta: V100, Titan V)"
      echo "CPU Features: AVX-512"
      echo "CUDA: 12.9 (cudaSupport=true, gpuTargets=[${gpuArchSM}])"
      echo "CXXFLAGS: $CXXFLAGS"
      echo "========================================="
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch for NVIDIA V100/Titan V (SM70, Volta) with AVX-512";
      longDescription = ''
        Custom PyTorch build with targeted optimizations:
        - GPU: NVIDIA Volta architecture (SM70) - V100, Titan V
        - CPU: x86-64 with AVX-512 instruction set
        - CUDA: 12.9 with compute capability 7.0
        - BLAS: cuBLAS for GPU operations
        - Python: 3.11

        Hardware requirements:
        - GPU: V100, Titan V, or other SM70 GPUs
        - CPU: Intel Skylake-X+ (2017+), AMD Zen 4+ (2022+) with AVX-512
        - Driver: NVIDIA 396+ required

        Note: cuDNN is disabled because cuDNN 9.11+ dropped SM < 7.5 support.

        Choose this if: You have V100/Titan V GPU with AVX-512 CPUs
        and need optimized kernels for Volta architecture.
      '';
      platforms = [ "x86_64-linux" ];
    };
  })
