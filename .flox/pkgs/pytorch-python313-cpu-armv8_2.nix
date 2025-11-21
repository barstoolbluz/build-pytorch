# PyTorch CPU-only optimized for ARMv8.2
# Package name: pytorch-python313-cpu-armv8.2
#
# ARM server build for AWS Graviton2, general ARM servers
# Hardware: ARM Neoverse N1, Cortex-A75+, Graviton2

{ python3Packages
, lib
, openblas
}:

let
  # CPU optimization: ARMv8.2-A with FP16 and dot product
  cpuFlags = [
    "-march=armv8.2-a+fp16+dotprod"  # ARMv8.2 with half-precision and dot product
  ];

  # Use OpenBLAS for CPU linear algebra
  blasBackend = openblas;

in python3Packages.pytorch.overrideAttrs (oldAttrs: {
  pname = "pytorch-python313-cpu-armv8.2";

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
    echo "CPU Architecture: ARMv8.2-A with FP16 and dot product"
    echo "BLAS Backend: OpenBLAS"
    echo "CUDA: Disabled"
    echo "CXXFLAGS: $CXXFLAGS"
    echo ""
    echo "Hardware support: ARM Neoverse N1, Cortex-A75+, AWS Graviton2"
    echo "Use case: General ARM server deployments (CPU-only)"
    echo "========================================="
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
