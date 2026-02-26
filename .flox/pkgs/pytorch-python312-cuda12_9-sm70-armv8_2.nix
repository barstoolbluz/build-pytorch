# PyTorch optimized for NVIDIA Volta (SM70: V100, Titan V) + ARMv8.2
# Package name: pytorch-python312-cuda12_9-sm70-armv8_2

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

  # CPU optimization: ARMv8.2-A with FP16 and dot product
  cpuFlags = [
    "-march=armv8.2-a+fp16+dotprod"  # ARMv8.2 with half-precision and dot product
  ];

in
  # Two-stage override:
  # 1. Enable CUDA and specify GPU targets
  (nixpkgs_pinned.python312Packages.torch.override {
    cudaSupport = true;
    gpuTargets = [ gpuArchSM ];
  # 2. Customize build (CPU flags, metadata, etc.)
  }).overrideAttrs (oldAttrs: {
    pname = "pytorch-python312-cuda12_9-sm70-armv8_2";
    passthru = oldAttrs.passthru // {
      gpuArch = gpuArchSM;
      blasProvider = "cublas";
      cpuISA = "armv8_2";
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
      echo "CPU Features: ARMv8.2 + FP16 + DotProd"
      echo "CUDA: 12.9 (cudaSupport=true, gpuTargets=[${gpuArchSM}])"
      echo "CXXFLAGS: $CXXFLAGS"
      echo "========================================="
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch for NVIDIA V100/Titan V (SM70) + ARMv8.2";
      longDescription = ''
        Custom PyTorch build with targeted optimizations:
        - GPU: NVIDIA Volta architecture (SM70) - V100, Titan V
        - CPU: ARMv8.2-A with FP16 and dot product instructions
        - CUDA: 12.9 with compute capability 7.0
        - BLAS: cuBLAS for GPU operations
        - Python: 3.12

        Hardware requirements:
        - GPU: V100, Titan V, or other SM70 GPUs
        - CPU: ARM Neoverse N1, Cortex-A75+, AWS Graviton2
        - Driver: NVIDIA 396+ required

        Note: cuDNN is disabled because cuDNN 9.11+ dropped SM < 7.5 support.

        Choose this if: You have V100/Titan V GPU on ARM server (Graviton2)
        and need GPU acceleration on ARM platform. For newer ARM servers
        (Graviton3+, Grace), use armv9 variant instead.

        vLLM compatibility: Pin-compatible with build-vllm/vllm-0.14.0 (vLLM 0.14.0,
        CUDA 12.9, nixpkgs 46336d4) for SM-specific torch substitution.
      '';
      platforms = [ "aarch64-linux" ];
    };
  })
