# PyTorch optimized for NVIDIA Turing (SM75: T4, RTX 2080 Ti) + AVX-512 + BF16
# Package name: pytorch-python312-cuda12_8-sm75-avx512bf16

{ pkgs ? import <nixpkgs> {} }:

let
  # Import nixpkgs at a specific revision with CUDA 12.8
  nixpkgs_pinned = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/46336d4d6980ae6f136b45c8507b17787eb186a0.tar.gz";
  }) {
    config = {
      allowUnfree = true;
      cudaSupport = true;
    };
    overlays = [
      (final: prev: { cudaPackages = final.cudaPackages_12_8; })
    ];
  };
  # GPU target: SM75 (Turing architecture - T4, RTX 2080 Ti)
  gpuArchNum = "75";  # For CMAKE_CUDA_ARCHITECTURES (just the integer)
  gpuArchSM = "7.5";  # For TORCH_CUDA_ARCH_LIST (with sm_ prefix)

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
    gpuTargets = [ gpuArchSM ];
  # 2. Customize build (CPU flags, metadata, etc.)
  }).overrideAttrs (oldAttrs: {
    pname = "pytorch-python312-cuda12_8-sm75-avx512bf16";
    passthru = oldAttrs.passthru // {
      gpuArch = gpuArchSM;
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
      echo "GPU Target: ${gpuArchSM} (Turing: T4, RTX 2080 Ti)"
      echo "CPU Features: AVX-512 + BF16"
      echo "CUDA: 12.8 (cudaSupport=true, gpuTargets=[${gpuArchSM}])"
      echo "CXXFLAGS: $CXXFLAGS"
      echo "========================================="
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch for NVIDIA T4/RTX 2080 Ti (SM75) + AVX-512 BF16";
      longDescription = ''
        Custom PyTorch build with targeted optimizations:
        - GPU: NVIDIA Turing architecture (SM75) - T4, RTX 2080 Ti, Quadro RTX 8000
        - CPU: x86-64 with AVX-512 + BF16 instruction set
        - CUDA: 12.8 with compute capability 7.5
        - BLAS: cuBLAS for GPU operations
        - Python: 3.12
        - Workload: BF16 mixed-precision training acceleration

        Hardware requirements:
        - GPU: T4, RTX 2080 Ti, RTX 2080, Quadro RTX 8000, or other SM75 GPUs
        - CPU: Intel Cooper Lake+ (2020+), AMD Zen 4+ (2022+)
        - Driver: NVIDIA 418+ required

        Choose this if: You have T4/RTX 2080 Ti GPU + CPU with AVX-512 BF16 support,
        and need accelerated BF16 mixed-precision training. NOT for INT8 inference
        (use avx512vnni) or general FP32 (use avx512).

        vLLM compatibility: Pin-compatible with build-vllm/vllm-0.14.0 (vLLM 0.14.0,
        CUDA 12.8, nixpkgs 46336d4) for SM-specific torch substitution.
      '';
      platforms = [ "x86_64-linux" ];
    };
  })
