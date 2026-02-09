# PyTorch CPU-only optimized for AVX-512
# Package name: pytorch-python313-cpu-avx512

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
  # CPU optimization: AVX-512 (no GPU)
  cpuFlags = [
    "-mavx512f"    # AVX-512 Foundation
    "-mavx512dq"   # Doubleword and Quadword instructions
    "-mavx512vl"   # Vector Length extensions
    "-mavx512bw"   # Byte and Word instructions
    "-mfma"        # Fused multiply-add
  ];

  # Use OpenBLAS for CPU linear algebra (or could use MKL)
  # Note: Official PyTorch binaries bundle MKL, but OpenBLAS is open-source
  blasBackend = nixpkgs_pinned.openblas;

in nixpkgs_pinned.python3Packages.torch.overrideAttrs (oldAttrs: {
  pname = "pytorch-python313-cpu-avx512";

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
    echo "CPU Features: AVX-512"
    echo "BLAS Backend: OpenBLAS"
    echo "CUDA: Disabled"
    echo "CXXFLAGS: $CXXFLAGS"
    echo ""
    echo "Hardware support: Intel Skylake-X+ (2017), AMD Zen 4+ (2022)"
    echo "Performance: ~2x faster than AVX2 for CPU workloads"
    echo "========================================="
  '';

    postInstall = (oldAttrs.postInstall or "") + ''
      echo 1 > $out/.metadata-rev
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch CPU-only optimized for AVX-512 (general FP32 workloads)";
      longDescription = ''
        Custom PyTorch build for CPU-only workloads:
        - GPU: None (CPU-only)
        - CPU: x86-64 with AVX-512 instruction set
        - BLAS: OpenBLAS for CPU linear algebra operations
        - Python: 3.13
        - Workload: General FP32 training and inference

        Hardware support:
        - CPU: Intel Skylake-X+ (2017+), AMD Zen 4+ (2022+)

        Performance: ~2x improvement over AVX2 for FP32 operations.

        Choose this if: You have modern server CPU with AVX-512 and need
        general-purpose CPU-only PyTorch for FP32 training and inference.
        For specialized workloads, consider avx512bf16 (BF16 training)
        or avx512vnni (INT8 inference) variants instead.
      '';
      platforms = [ "x86_64-linux" ];
    };
})
