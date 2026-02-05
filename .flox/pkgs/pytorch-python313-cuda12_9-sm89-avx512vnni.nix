# PyTorch optimized for NVIDIA Ada Lovelace (SM89: RTX 4090, L40) + AVX-512 + VNNI
# Package name: pytorch-python313-cuda12_9-sm89-avx512vnni

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
  # GPU target: SM89 (Ada Lovelace architecture - RTX 4090, L40)
  gpuArchNum = "89";  # For CMAKE_CUDA_ARCHITECTURES (just the integer)
  gpuArchSM = "8.9";  # For TORCH_CUDA_ARCH_LIST (with sm_ prefix)

  # CPU optimization: AVX-512 + VNNI (Vector Neural Network Instructions)
  cpuFlags = [
    "-mavx512f"    # AVX-512 Foundation
    "-mavx512dq"   # Doubleword and Quadword instructions
    "-mavx512vl"   # Vector Length extensions
    "-mavx512bw"   # Byte and Word instructions
    "-mavx512vnni" # Vector Neural Network Instructions (INT8 acceleration)
    "-mfma"        # Fused multiply-add
  ];

in
  # Two-stage override:
  # 1. Enable CUDA and specify GPU targets
  (nixpkgs_pinned.python3Packages.torch.override {
    cudaSupport = true;
    gpuTargets = [ gpuArchSM ];
  # 2. Customize build (CPU flags, metadata, etc.)
  }).overrideAttrs (oldAttrs: {
    pname = "pytorch-python313-cuda12_9-sm89-avx512vnni";

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
      echo "GPU Target: ${gpuArchSM} (Ada: RTX 4090, L40)"
      echo "CPU Features: AVX-512 + VNNI"
      echo "CUDA: 12.9 (cudaSupport=true, gpuTargets=[${gpuArchSM}])"
      echo "CXXFLAGS: $CXXFLAGS"
      echo "========================================="
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch for NVIDIA RTX 4090/L40 (SM89) + AVX-512 VNNI";
      longDescription = ''
        Custom PyTorch build with targeted optimizations:
        - GPU: NVIDIA Ada Lovelace architecture (SM89) - RTX 4090, RTX 4080, L40, L40S
        - CPU: x86-64 with AVX-512 + VNNI instruction set
        - CUDA: 12.9 with compute capability 8.9
        - BLAS: cuBLAS for GPU operations
        - Python: 3.13
        - Workload: INT8 quantized model inference acceleration

        Hardware requirements:
        - GPU: RTX 4090, RTX 4080, RTX 4070 Ti, RTX 4070, RTX 4060 Ti, L40, or other SM89 GPUs
        - CPU: Intel Skylake-SP+ (2017+), AMD Zen 4+ (2022+)
        - Driver: NVIDIA 520+ required

        Choose this if: You have RTX 4090/40x0 GPU + CPU with AVX-512 VNNI support,
        and need accelerated INT8 quantized inference. NOT for training
        (use avx512bf16) or general FP32 (use avx512).
      '';
      platforms = [ "x86_64-linux" ];
    };
  })
