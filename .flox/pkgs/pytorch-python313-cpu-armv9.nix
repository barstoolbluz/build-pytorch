# PyTorch CPU-only optimized for ARMv9
# Package name: pytorch-python313-cpu-armv9
#
# ARM datacenter build for Grace CPUs, AWS Graviton3+
# Hardware: ARM Neoverse V1/V2, Cortex-X2+, Graviton3+

{ pkgs ? import <nixpkgs> {} }:

let
  # Import nixpkgs at a specific revision (pinned for consistency with CUDA builds)
  nixpkgs_pinned = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/fe5e41d7ffc0421f0913e8472ce6238ed0daf8e3.tar.gz";
  }) {
    config = {
      allowUnfree = true;
      cudaSupport = true;
    };
    overlays = [
      (final: prev: { cudaPackages = final.cudaPackages_12_9; })
    ];
  };
  # CPU optimization: ARMv9-A with SVE/SVE2
  cpuFlags = [
    "-march=armv9-a+sve+sve2"  # ARMv9 with Scalable Vector Extensions
  ];

  # Use OpenBLAS for CPU linear algebra
  blasBackend = nixpkgs_pinned.openblas;

in nixpkgs_pinned.python3Packages.pytorch.overrideAttrs (oldAttrs: {
  pname = "pytorch-python313-cpu-armv9";

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
    echo "CPU Architecture: ARMv9-A with SVE2"
    echo "BLAS Backend: OpenBLAS"
    echo "CUDA: Disabled"
    echo "CXXFLAGS: $CXXFLAGS"
    echo ""
    echo "Hardware support: NVIDIA Grace, ARM Neoverse V1/V2, Cortex-X2+, AWS Graviton3+"
    echo "Use case: Modern ARM datacenter deployments (CPU-only)"
    echo "========================================="
  '';

  meta = oldAttrs.meta // {
    description = "PyTorch CPU-only optimized for ARMv9 (Grace, Graviton3+, SVE2)";
    longDescription = ''
      Custom PyTorch build for CPU-only workloads:
      - GPU: None (CPU-only)
      - CPU: ARMv9-A with SVE/SVE2 (Scalable Vector Extensions)
      - BLAS: OpenBLAS for CPU linear algebra operations
      - Python: 3.13

      Hardware support:
      - CPU: NVIDIA Grace, ARM Neoverse V1/V2, Cortex-X2+, AWS Graviton3+

      Choose this if: You need CPU-only PyTorch on modern ARM servers with
      ARMv9/SVE2 support (Grace, Graviton3+). Provides better performance than
      armv8_2 variant on supported hardware. For older ARM servers (Graviton2),
      use armv8_2 variant instead.
    '';
    platforms = [ "aarch64-linux" ];
  };
})
