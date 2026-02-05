# PyTorch optimized for NVIDIA Blackwell Datacenter (SM100: B100, B200) + ARMv8.2
# Package name: pytorch-python313-cuda12_9-sm100-armv8_2

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
  # GPU target: SM100 (Blackwell datacenter architecture - B100, B200)
  gpuArchNum = "100";  # For CMAKE_CUDA_ARCHITECTURES (just the integer)
  gpuArchSM = "sm_100";  # For TORCH_CUDA_ARCH_LIST (with sm_ prefix)

  # CPU optimization: ARMv8.2-A with FP16 and dot product
  cpuFlags = [
    "-march=armv8.2-a+fp16+dotprod"  # ARMv8.2 with half-precision and dot product
  ];

in
  # Two-stage override:
  # 1. Enable CUDA and specify GPU targets
  (nixpkgs_pinned.python3Packages.torch.override {
    cudaSupport = true;
    gpuTargets = [ gpuArchSM ];
  # 2. Customize build (CPU flags, metadata, etc.)
  }).overrideAttrs (oldAttrs: {
    pname = "pytorch-python313-cuda12_9-sm100-armv8_2";

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
      echo "GPU Target: ${gpuArchSM} (Blackwell Datacenter: B100, B200)"
      echo "CPU Features: ARMv8.2 + FP16 + DotProd"
      echo "CUDA: 12.9 (cudaSupport=true, gpuTargets=[${gpuArchSM}])"
      echo "CXXFLAGS: $CXXFLAGS"
      echo "========================================="
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch for NVIDIA B100/B200 (SM100, Blackwell DC) + ARMv8.2";
      longDescription = ''
        Custom PyTorch build with targeted optimizations:
        - GPU: NVIDIA Blackwell datacenter architecture (SM100) - B100, B200
        - CPU: ARMv8.2-A with FP16 and dot product instructions
        - CUDA: 12.9 with compute capability 10.0
        - BLAS: cuBLAS for GPU operations
        - Python: 3.13

        Hardware requirements:
        - GPU: B100, B200, or other SM100 GPUs
        - CPU: ARM Neoverse N1, Cortex-A75+, AWS Graviton2
        - Driver: NVIDIA 550+ required

        Choose this if: You have B100 or B200 datacenter GPU on ARM server (Graviton2)
        and need GPU acceleration on ARM platform. For newer ARM servers
        (Graviton3+, Grace), use armv9 variant instead.
      '';
      platforms = [ "aarch64-linux" ];
    };
  })
