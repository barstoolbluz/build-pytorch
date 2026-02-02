# PyTorch optimized for NVIDIA Blackwell B300 Datacenter (SM103: B300) + ARMv8.2-A
# Package name: pytorch-python313-cuda12_9-sm103-armv8_2

{ pkgs ? import <nixpkgs> {} }:

let
  # Import nixpkgs at a specific revision with CUDA 12.9 (required for SM103)
  # TODO: Pin to nixpkgs commit where cudaPackages defaults to CUDA 12.9
  nixpkgs_pinned = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/fe5e41d7ffc0421f0913e8472ce6238ed0daf8e3.tar.gz";
    # You can add the sha256 here once known for reproducibility
  }) {
    config = {
      allowUnfree = true;  # Required for CUDA packages
      cudaSupport = true;
    };
  };

  # GPU target: SM103 (Blackwell B300 datacenter architecture)
  gpuArchNum = "103";
  gpuArchSM = "sm_103";

  # CPU optimization: ARMv8.2-A
  cpuFlags = [
    "-march=armv8.2-a+fp16+dotprod"
  ];

in
  (nixpkgs_pinned.python3Packages.pytorch.override {
    cudaSupport = true;
    gpuTargets = [ gpuArchSM ];
  }).overrideAttrs (oldAttrs: {
    pname = "pytorch-python313-cuda12_9-sm103-armv8_2";

    # Limit build parallelism to prevent memory saturation
    ninjaFlags = [ "-j32" ];
    requiredSystemFeatures = [ "big-parallel" ];

    preConfigure = (oldAttrs.preConfigure or "") + ''
      export CXXFLAGS="${nixpkgs_pinned.lib.concatStringsSep " " cpuFlags} $CXXFLAGS"
      export CFLAGS="${nixpkgs_pinned.lib.concatStringsSep " " cpuFlags} $CFLAGS"
      export MAX_JOBS=32

      echo "========================================="
      echo "PyTorch Build Configuration"
      echo "========================================="
      echo "GPU Target: sm_103 (Blackwell B300 Datacenter)"
      echo "CPU Features: ARMv8.2-A + FP16 + DotProd"
      echo "CUDA: 12.9 (pinned nixpkgs)"
      echo "========================================="
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch for NVIDIA B300 (SM103, Blackwell DC) + ARMv8.2";
      longDescription = ''
        Custom PyTorch build with targeted optimizations:
        - GPU: NVIDIA Blackwell B300 datacenter architecture (SM103)
        - CPU: ARMv8.2-A with FP16 and dot product instructions
        - CUDA: 12.9 with compute capability 10.3
        - BLAS: cuBLAS for GPU operations
        - Python: 3.13

        Hardware requirements:
        - GPU: B300 or other SM103 GPUs
        - CPU: ARM Neoverse N1, Cortex-A75+, AWS Graviton2
        - Driver: NVIDIA 550+ required
      '';
      platforms = [ "aarch64-linux" ];
    };
  })
