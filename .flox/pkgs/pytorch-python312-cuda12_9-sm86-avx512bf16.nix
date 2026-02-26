# PyTorch optimized for NVIDIA Ampere (SM86: RTX 3090, A5000, A40) + AVX-512 + BF16
# Package name: pytorch-python312-cuda12_9-sm86-avx512bf16

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
  # GPU target: SM86 (Ampere architecture - RTX 3090, A5000, A40)
  # PyTorch's CMake accepts numeric format (8.6) not sm_86
  gpuArchNum = "8.6";

  # CPU optimization: AVX-512 + BF16 (Brain Float 16)
  cpuFlags = [
    "-mavx512f"    # AVX-512 Foundation
    "-mavx512dq"   # Doubleword and Quadword instructions
    "-mavx512vl"   # Vector Length extensions
    "-mavx512bw"   # Byte and Word instructions
    "-mavx512bf16" # Brain Float 16 instructions (ML training acceleration)
    "-mfma"        # Fused multiply-add
  ];

in
  # Two-stage override:
  # 1. Enable CUDA and specify GPU targets
  (nixpkgs_pinned.python312Packages.torch.override {
    cudaSupport = true;
    gpuTargets = [ gpuArchNum ];
  # 2. Customize build (CPU flags, metadata, etc.)
  }).overrideAttrs (oldAttrs: {
    pname = "pytorch-python312-cuda12_9-sm86-avx512bf16";
    passthru = oldAttrs.passthru // {
      gpuArch = gpuArchNum;
      blasProvider = "cublas";
      cpuISA = "avx512bf16";
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

      echo "========================================="
      echo "PyTorch Build Configuration"
      echo "========================================="
      echo "GPU Target: ${gpuArchNum} (Ampere: RTX 3090, A5000, A40)"
      echo "CPU Features: AVX-512 + BF16"
      echo "CUDA: 12.9 (cudaSupport=true, gpuTargets=[${gpuArchNum}])"
      echo "CXXFLAGS: $CXXFLAGS"
      echo "========================================="
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch for NVIDIA RTX 3090/A40 (SM86) + AVX-512 BF16";
      longDescription = ''
        Custom PyTorch build with targeted optimizations:
        - GPU: NVIDIA Ampere architecture (SM86) - RTX 3090, A5000, A40
        - CPU: x86-64 with AVX-512 + BF16 instruction set
        - CUDA: 12.9 with compute capability 8.6
        - BLAS: cuBLAS for GPU operations
        - Python: 3.12
        - Workload: BF16 mixed-precision training acceleration

        Hardware requirements:
        - GPU: RTX 3090, RTX 3080 Ti, A5000, A40, or other SM86 GPUs
        - CPU: Intel Cooper Lake+ (2020+), AMD Zen 4+ (2022+)
        - Driver: NVIDIA 470+ required

        Choose this if: You have RTX 3090/A40 GPU + CPU with AVX-512 BF16 support,
        and need accelerated BF16 mixed-precision training. NOT for INT8 inference
        (use avx512vnni) or general FP32 (use avx512).

        vLLM compatibility: Pin-compatible with build-vllm/vllm-0.14.0 (vLLM 0.14.0,
        CUDA 12.9, nixpkgs 46336d4) for SM-specific torch substitution.
      '';
      platforms = [ "x86_64-linux" ];
    };
  })
