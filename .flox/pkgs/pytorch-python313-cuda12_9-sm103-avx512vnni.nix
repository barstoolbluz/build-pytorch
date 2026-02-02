# PyTorch optimized for NVIDIA Blackwell B300 Datacenter (SM103: B300) + AVX-512 with VNNI
# Package name: pytorch-python313-cuda12_9-sm103-avx512vnni

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

  # CPU optimization: AVX-512 with VNNI
  cpuFlags = [
    "-mavx512f" "-mavx512dq" "-mavx512vl" "-mavx512bw" "-mavx512vnni" "-mfma"
  ];

in
  (nixpkgs_pinned.python3Packages.pytorch.override {
    cudaSupport = true;
    gpuTargets = [ gpuArchSM ];
  }).overrideAttrs (oldAttrs: {
    pname = "pytorch-python313-cuda12_9-sm103-avx512vnni";

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
      echo "CPU Features: AVX-512 VNNI (INT8 inference)"
      echo "CUDA: 12.9 (pinned nixpkgs)"
      echo "========================================="
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch for NVIDIA B300 (SM103, Blackwell DC) + AVX-512 VNNI";
      longDescription = ''
        Custom PyTorch build with targeted optimizations:
        - GPU: NVIDIA Blackwell B300 datacenter architecture (SM103)
        - CPU: x86-64 with AVX-512 VNNI instruction set
        - CUDA: 12.9 with compute capability 10.3
        - BLAS: cuBLAS for GPU operations
        - Python: 3.13

        Hardware requirements:
        - GPU: B300 or other SM103 GPUs
        - CPU: Intel Skylake-SP+ (2017+), AMD Zen 4+ (2022+) with avx512_vnni
        - Driver: NVIDIA 550+ required
      '';
      platforms = [ "x86_64-linux" ];
    };
  })
