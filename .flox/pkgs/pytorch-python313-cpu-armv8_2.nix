# PyTorch CPU-only optimized for ARMv8.2
# Package name: pytorch-python313-cpu-armv8_2
#
# ARM server build for AWS Graviton2, general ARM servers
# Hardware: ARM Neoverse N1, Cortex-A75+, Graviton2

{ pkgs ? import <nixpkgs> {} }:

let
  # Import nixpkgs at a specific revision (pinned for version consistency)
  nixpkgs_pinned = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/6a030d535719c5190187c4cec156f335e95e3211.tar.gz";
  }) {
    config = {
      allowUnfree = true;
    };
  };
  # CPU optimization: ARMv8.2-A with FP16 and dot product
  cpuFlags = [
    "-march=armv8.2-a+fp16+dotprod"  # ARMv8.2 with half-precision and dot product
  ];

  # Use OpenBLAS for CPU linear algebra
  blasBackend = nixpkgs_pinned.openblas;

in nixpkgs_pinned.python3Packages.torch.overrideAttrs (oldAttrs: {
  pname = "pytorch-python313-cpu-armv8_2";

    # Limit build parallelism to prevent memory saturation
    ninjaFlags = [ "-j32" ];
    requiredSystemFeatures = [ "big-parallel" ];

  # Disable CUDA support for CPU-only build
  passthru = oldAttrs.passthru // {
    gpuArch = null;
    blasProvider = "openblas";
  };

  # Override build configuration - remove CUDA deps, ensure BLAS
  buildInputs = nixpkgs_pinned.lib.filter (p: !(nixpkgs_pinned.lib.hasPrefix "cuda" (p.pname or ""))) oldAttrs.buildInputs ++ [
    blasBackend
  ];

  nativeBuildInputs = nixpkgs_pinned.lib.filter (p: p.pname or "" != "addDriverRunpath") oldAttrs.nativeBuildInputs;

  # Set CPU optimization flags and disable CUDA
  preConfigure = (oldAttrs.preConfigure or "") + ''
    # Disable CUDA
    export USE_CUDA=0
    export USE_CUDNN=0
    export USE_CUBLAS=0

    # Use OpenBLAS for CPU operations
    export BLAS=OpenBLAS
    export USE_MKLDNN=1
    export USE_MKLDNN_CBLAS=1

    # CPU optimizations via compiler flags
    export CXXFLAGS="${nixpkgs_pinned.lib.concatStringsSep " " cpuFlags} $CXXFLAGS"
    export CFLAGS="${nixpkgs_pinned.lib.concatStringsSep " " cpuFlags} $CFLAGS"
      export MAX_JOBS=32

    # Optimize for host CPU
    export CMAKE_BUILD_TYPE=Release

    echo "========================================="
    echo "PyTorch Build Configuration"
    echo "========================================="
    echo "GPU Target: None (CPU-only build)"
    echo "CPU Architecture: ARMv8.2-A with FP16 and dot product"
    echo "BLAS Backend: OpenBLAS"
    echo "CUDA: Disabled"
    echo "CXXFLAGS: $CXXFLAGS"
    echo ""
    echo "Hardware support: ARM Neoverse N1, Cortex-A75+, AWS Graviton2"
    echo "Use case: General ARM server deployments (CPU-only)"
    echo "========================================="
  '';

    postInstall = (oldAttrs.postInstall or "") + ''
      echo 1 > $out/.metadata-rev
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch CPU-only optimized for ARMv8.2 (Graviton2, ARM servers)";
      longDescription = ''
        Custom PyTorch build for CPU-only workloads:
        - GPU: None (CPU-only)
        - CPU: ARMv8.2-A with FP16 and dot product instructions
        - BLAS: OpenBLAS for CPU linear algebra operations
        - Python: 3.13

        Hardware support:
        - CPU: ARM Neoverse N1, Cortex-A75+, AWS Graviton2

        Choose this if: You need CPU-only PyTorch on ARM servers like
        AWS Graviton2, or general ARMv8.2 hardware. For newer ARM servers
        with ARMv9/SVE2 support (Graviton3+, Grace), use armv9 variant instead.
      '';
      platforms = [ "aarch64-linux" ];
    };
})
