# PyTorch CPU-only optimized for AVX-512 + BF16
# Package name: pytorch-python313-cpu-avx512bf16
#
# Optimized for BF16 training workloads (modern mixed-precision)
# Hardware: Intel Cooper Lake+ (2020), AMD Zen 4+ (2022)

{ python3Packages
, lib
, openblas
, mkl
}:

let
  # CPU optimization: AVX-512 + BF16 (Brain Float 16)
  cpuFlags = [
    "-mavx512f"    # AVX-512 Foundation
    "-mavx512dq"   # Doubleword and Quadword instructions
    "-mavx512vl"   # Vector Length extensions
    "-mavx512bw"   # Byte and Word instructions
    "-mavx512bf16" # Brain Float 16 instructions (ML training acceleration)
    "-mfma"        # Fused multiply-add
  ];

  # Use OpenBLAS for CPU linear algebra (or could use MKL)
  # Note: Official PyTorch binaries bundle MKL, but OpenBLAS is open-source
  blasBackend = openblas;

in python3Packages.pytorch.overrideAttrs (oldAttrs: {
  pname = "pytorch-python313-cpu-avx512bf16";

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
    echo "CPU Features: AVX-512 + BF16 (mixed-precision optimized)"
    echo "BLAS Backend: OpenBLAS"
    echo "CUDA: Disabled"
    echo "CXXFLAGS: $CXXFLAGS"
    echo ""
    echo "Hardware support: Intel Cooper Lake+ (2020), AMD Zen 4+ (2022)"
    echo "Optimized for: BF16 training (modern mixed-precision)"
    echo "========================================="
  '';

  meta = oldAttrs.meta // {
    description = "PyTorch CPU-only optimized for AVX-512 BF16 (mixed-precision training)";
    longDescription = ''
      Custom PyTorch build for CPU-only workloads:
      - GPU: None (CPU-only)
      - CPU: x86-64 with AVX-512 + BF16 instruction set
      - BLAS: OpenBLAS for CPU linear algebra operations
      - Python: 3.13
      - Workload: BF16 mixed-precision training acceleration

      Hardware support:
      - CPU: Intel Cooper Lake+ (2020+), AMD Zen 4+ (2022+)

      Choose this if: You need CPU-only mixed-precision training with BF16
      on modern CPUs supporting AVX-512 BF16 instructions. Provides hardware
      acceleration for BF16 operations compared to standard AVX-512 build.
      NOT for INT8 inference (use avx512vnni) or general FP32 (use avx512).
    '';
    platforms = [ "x86_64-linux" ];
  };
})
