# PyTorch optimized for NVIDIA Ada Lovelace (SM89: RTX 4090, L40) + ARMv9
# Package name: pytorch-python313-cuda12_9-sm89-armv9

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
  gpuArchSM = "sm_89";  # For TORCH_CUDA_ARCH_LIST (with sm_ prefix)

  # CPU optimization: ARMv9-A with SVE/SVE2
  cpuFlags = [
    "-march=armv9-a+sve+sve2"  # ARMv9 with Scalable Vector Extensions
  ];

in
  # Two-stage override:
  # 1. Enable CUDA and specify GPU targets
  (nixpkgs_pinned.python3Packages.pytorch.override {
    cudaSupport = true;
    gpuTargets = [ gpuArchSM ];
  # 2. Customize build (CPU flags, metadata, etc.)
  }).overrideAttrs (oldAttrs: {
    pname = "pytorch-python313-cuda12_9-sm89-armv9";

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
      echo "CPU Features: ARMv9 + SVE/SVE2"
      echo "CUDA: 12.9 (cudaSupport=true, gpuTargets=[${gpuArchSM}])"
      echo "CXXFLAGS: $CXXFLAGS"
      echo "========================================="
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch for NVIDIA RTX 4090/L40 (SM89) + ARMv9 (SVE2)";
      longDescription = ''
        Custom PyTorch build with targeted optimizations:
        - GPU: NVIDIA Ada Lovelace architecture (SM89) - RTX 4090, RTX 4080, L40, L40S
        - CPU: ARMv9-A with SVE/SVE2 (Scalable Vector Extensions)
        - CUDA: 12.9 with compute capability 8.9
        - BLAS: cuBLAS for GPU operations
        - Python: 3.13

        Hardware requirements:
        - GPU: RTX 4090, RTX 4080, RTX 4070 Ti, RTX 4070, RTX 4060 Ti, L40, or other SM89 GPUs
        - CPU: NVIDIA Grace, ARM Neoverse V1/V2, Cortex-X2+, AWS Graviton3+
        - Driver: NVIDIA 520+ required

        Choose this if: You have RTX 4090/40x0 GPU on modern ARM server with
        ARMv9/SVE2 support (Grace, Graviton3+). For older ARM servers
        (Graviton2), use armv8_2 variant instead.
      '';
      platforms = [ "aarch64-linux" ];
    };
  })
