# PyTorch CPU-only optimized for AVX2
# Package name: pytorch-python313-cpu-avx2

{ python3Packages
, lib
, openblas
, mkl
}:

let
  # CPU optimization: AVX2 (no GPU)
  cpuFlags = [
    "-mavx2"       # AVX2 instructions
    "-mfma"        # Fused multiply-add
    "-mf16c"       # Half-precision conversions
  ];

  # Use OpenBLAS for CPU linear algebra (or could use MKL)
  # Note: Official PyTorch binaries bundle MKL, but OpenBLAS is open-source
  blasBackend = openblas;

in python3Packages.pytorch.overrideAttrs (oldAttrs: {
  pname = "pytorch-python313-cpu-avx2";

  # Disable CUDA support for CPU-only build
  passthru = oldAttrs.passthru // {
    gpuArch = null;
    blasProvider = "openblas";
  };

  # Override build configuration - remove CUDA deps, ensure BLAS
  buildInputs = lib.filter (p: !(lib.hasPrefix "cuda" (p.pname or ""))) oldAttrs.buildInputs ++ [
    blasBackend
  ];

  nativeBuildInputs = lib.filter (p: p.pname or "" != "addDriverRunpath") oldAttrs.nativeBuildInputs;

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
    export CXXFLAGS="$CXXFLAGS ${lib.concatStringsSep " " cpuFlags}"
    export CFLAGS="$CFLAGS ${lib.concatStringsSep " " cpuFlags}"

    # Optimize for host CPU
    export CMAKE_BUILD_TYPE=Release

    echo "========================================="
    echo "PyTorch Build Configuration"
    echo "========================================="
    echo "GPU Target: None (CPU-only build)"
    echo "CPU Features: AVX2"
    echo "BLAS Backend: OpenBLAS"
    echo "CUDA: Disabled"
    echo "CXXFLAGS: $CXXFLAGS"
    echo "========================================="
  '';

  postInstall = (oldAttrs.postInstall or "") + ''
    echo 1 > $out/.metadata-rev
  '';

  meta = oldAttrs.meta // {
    description = "PyTorch CPU-only optimized for AVX2";
    longDescription = ''
      Custom PyTorch build for CPU-only workloads:
      - GPU: None (CPU-only)
      - CPU: x86-64 with AVX2 instruction set
      - BLAS: OpenBLAS for CPU linear algebra operations
      - Python: 3.13

      Hardware support:
      - CPU: Intel Haswell+ (2013+), AMD Zen 1+ (2017+)

      Choose this if: You need CPU-only PyTorch on older hardware without
      AVX-512 support, or want maximum compatibility across x86-64 systems.
      Good for development, testing, and inference on commodity hardware.
    '';
    platforms = [ "x86_64-linux" "aarch64-linux" ];
  };
})
