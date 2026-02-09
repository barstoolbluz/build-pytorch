# PyTorch CPU-only optimized for AVX (Sandy Bridge+ maximum compatibility)
# Package name: pytorch-python313-cpu-avx

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
  # CPU optimization: AVX only (Sandy Bridge+, 2011+)
  # Explicitly disable newer instructions for maximum compatibility
  cpuFlags = [
    "-mavx"        # Enable AVX
    "-mno-fma"     # Disable FMA3 (Haswell+)
    "-mno-bmi"     # Disable BMI1 (Haswell+)
    "-mno-bmi2"    # Disable BMI2 (Haswell+)
    "-mno-avx2"    # Disable AVX2 (Haswell+)
  ];

  # Use OpenBLAS for CPU linear algebra (or could use MKL)
  # Note: Official PyTorch binaries bundle MKL, but OpenBLAS is open-source
  blasBackend = nixpkgs_pinned.openblas;

in nixpkgs_pinned.python3Packages.torch.overrideAttrs (oldAttrs: {
  pname = "pytorch-python313-cpu-avx";

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

  # Add CMAKE flags to disable AVX2/AVX512 detection
  cmakeFlags = (oldAttrs.cmakeFlags or []) ++ [
    "-DCXX_AVX2_FOUND=FALSE"
    "-DC_AVX2_FOUND=FALSE"
    "-DCXX_AVX512_FOUND=FALSE"
    "-DC_AVX512_FOUND=FALSE"
    "-DUSE_NNPACK=OFF"
  ];

  # Set CPU optimization flags and disable CUDA
  preConfigure = (oldAttrs.preConfigure or "") + ''
    # Disable CUDA
    export USE_CUDA=0
    export USE_CUDNN=0
    export USE_CUBLAS=0

    # Disable features that require AVX2+
    export USE_FBGEMM=0
    export USE_MKLDNN=0
    export USE_NNPACK=0

    # Use OpenBLAS for CPU operations
    export BLAS=OpenBLAS

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
    echo "CPU Features: AVX (Sandy Bridge+ compatibility)"
    echo "BLAS Backend: OpenBLAS"
    echo "CUDA: Disabled"
    echo "FBGEMM/MKLDNN/NNPACK: Disabled (require AVX2+)"
    echo "CXXFLAGS: $CXXFLAGS"
    echo "========================================="
  '';

    postInstall = (oldAttrs.postInstall or "") + ''
      echo 1 > $out/.metadata-rev
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch CPU-only optimized for AVX (Sandy Bridge+ maximum compatibility)";
      longDescription = ''
        Custom PyTorch build for CPU-only workloads with maximum compatibility:
        - GPU: None (CPU-only)
        - CPU: x86-64 with AVX instruction set (Sandy Bridge+, 2011+)
        - BLAS: OpenBLAS for CPU linear algebra operations
        - Python: 3.13
        - Disabled: FBGEMM, MKLDNN, NNPACK (require AVX2+)

        Hardware support:
        - CPU: Intel Sandy Bridge+ (2011+), AMD Bulldozer+ (2011+)

        Choose this if: You need CPU-only PyTorch on very old hardware without
        AVX2 support, or want maximum compatibility across legacy x86-64 systems.
        Note: Some optimizations are disabled due to AVX2+ requirements.
        For better performance on modern CPUs, use avx2 or avx512 variants.
      '';
      platforms = [ "x86_64-linux" ];
    };
})
