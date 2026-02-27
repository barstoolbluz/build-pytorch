# PyTorch optimized for NVIDIA DGX Spark (SM121) + ARMv8.2
# Package name: pytorch-python313-cuda13_0-sm121-armv8_2

{ pkgs ? import <nixpkgs> {} }:

let
  # Import nixpkgs at a specific revision with CUDA 13.0 (required for SM121)
  nixpkgs_pinned = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/0182a361324364ae3f436a63005877674cf45efb.tar.gz";
  }) {
    config = {
      allowUnfree = true;
      cudaSupport = true;
    };
    overlays = [
      (final: prev: { cudaPackages = final.cudaPackages_13_0; })
    ];
  };

  # GPU target: SM121 (DGX Spark architecture)
  gpuArchNum = "121";
  gpuArchSM = "12.1";

  # CPU optimization: ARMv8.2
  cpuFlags = [
    "-march=armv8.2-a+fp16+dotprod"
  ];

in
  (nixpkgs_pinned.python3Packages.torch.override {
    cudaSupport = true;
    gpuTargets = [ gpuArchSM ];
  }).overrideAttrs (oldAttrs: {
    pname = "pytorch-python313-cuda13_0-sm121-armv8_2";
    passthru = oldAttrs.passthru // {
      gpuArch = gpuArchSM;
      blasProvider = "cublas";
      cpuISA = "armv8_2";
    };

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
      echo "GPU Target: sm_121 (DGX Spark)"
      echo "CPU Features: ARMv8.2"
      echo "CUDA: 13.0 (pinned nixpkgs)"
      echo "========================================="
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch for NVIDIA DGX Spark (SM121) + ARMv8.2";
      longDescription = ''
        Custom PyTorch build with targeted optimizations:
        - GPU: NVIDIA DGX Spark architecture (SM121)
        - CPU: ARMv8.2-A with FP16 and DotProd
        - CUDA: 13.0 with compute capability 12.1
        - BLAS: cuBLAS for GPU operations
        - Python: 3.13

        Hardware requirements:
        - GPU: NVIDIA DGX Spark or other SM121 GPUs
        - CPU: ARMv8.2+ (Cortex-A76+, Graviton2+)
        - Driver: NVIDIA 570+ required
      '';
      platforms = [ "aarch64-linux" ];
    };
  })
