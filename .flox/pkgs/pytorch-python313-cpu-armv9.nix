# PyTorch CPU-only optimized for ARMv9
# Package name: pytorch-python313-cpu-armv9
#
# ARM datacenter build for Grace CPUs, AWS Graviton3+
# Hardware: ARM Neoverse V1/V2, Cortex-X2+, Graviton3+

{ python3Packages
, lib
, openblas
}:

let
  # CPU optimization: ARMv9-A with SVE/SVE2
  cpuFlags = [
    "-march=armv9-a+sve+sve2"  # ARMv9 with Scalable Vector Extensions
  ];

  # Use OpenBLAS for CPU linear algebra
  blasBackend = openblas;

in python3Packages.pytorch.overrideAttrs (oldAttrs: {
  pname = "pytorch-python313-cpu-armv9";

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
    echo "CPU Architecture: ARMv9-A with SVE2"
    echo "BLAS Backend: OpenBLAS"
    echo "CUDA: Disabled"
    echo "CXXFLAGS: $CXXFLAGS"
    echo ""
    echo "Hardware support: NVIDIA Grace, ARM Neoverse V1/V2, Cortex-X2+, AWS Graviton3+"
    echo "Use case: Modern ARM datacenter deployments (CPU-only)"
    echo "========================================='';

  meta = oldAttrs.meta // {
    description = "PyTorch CPU-only build optimized for ARMv9-A (Grace, Graviton3+) with OpenBLAS";
    longDescription = ''
      Custom PyTorch build for CPU-only workloads:
      - GPU: None (CPU-only)
      - CPU: ARMv9-A with SVE/SVE2 (Scalable Vector Extensions)
      - BLAS: OpenBLAS for CPU linear algebra operations
      - Python: 3.13

      Hardware support:
      - NVIDIA Grace CPUs, ARM Neoverse V1/V2, Cortex-X2+, AWS Graviton3+

      Use case: Modern ARM datacenter deployments without GPU acceleration.
      Optimized for latest ARM server hardware with SVE2 support.
    '';
    platforms = [ "aarch64-linux" ];
  };
})
