# PyTorch optimized for NVIDIA Blackwell (RTX 5090) + AVX2
# Package name: pytorch-python313-cuda12_8-sm120-avx2
#
# NOTE: SM120 support requires PyTorch 2.7+ with CUDA 12.8+
# Broader CPU compatibility (Intel Haswell+ 2013, AMD Zen 1+ 2017)

{ python3Packages
, lib
, config
, cudaPackages
, addDriverRunpath
, openblas
}:

let
  # GPU target: SM120 (Blackwell architecture - RTX 5090)
  gpuArch = "sm_120";

  # CPU optimization: AVX2 (broad compatibility)
  cpuFlags = [
    "-mavx2"       # AVX2 instructions
    "-mfma"        # Fused multiply-add
    "-mf16c"       # Half-precision conversions
  ];

in python3Packages.pytorch.overrideAttrs (oldAttrs: {
  pname = "pytorch-python313-cuda12_8-sm120-avx2";

  # Enable CUDA support with specific GPU target
  passthru = oldAttrs.passthru // {
    inherit gpuArch;
  };

  # Override build configuration
  buildInputs = oldAttrs.buildInputs ++ [
    cudaPackages.cuda_cudart
    cudaPackages.libcublas
    cudaPackages.libcufft
    cudaPackages.libcurand
    cudaPackages.libcusolver
    cudaPackages.libcusparse
    cudaPackages.cudnn
    # Explicitly add dynamic OpenBLAS for host-side operations
    (openblas.override {
      blas64 = false;
      singleThreaded = false;
    })
  ];

  nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
    addDriverRunpath
  ];

  # Set CUDA architecture and CPU optimization flags
  preConfigure = (oldAttrs.preConfigure or "") + ''
    export TORCH_CUDA_ARCH_LIST="${gpuArch}"
    export TORCH_NVCC_FLAGS="-Xfatbin -compress-all"

    # CPU optimizations via compiler flags
    export CXXFLAGS="$CXXFLAGS ${lib.concatStringsSep " " cpuFlags}"
    export CFLAGS="$CFLAGS ${lib.concatStringsSep " " cpuFlags}"

    # Enable cuBLAS
    export USE_CUBLAS=1
    export USE_CUDA=1

    # Optimize for target architecture (SM120 = compute capability 12.0)
    export CMAKE_CUDA_ARCHITECTURES="${lib.removePrefix "sm_" gpuArch}"

    echo "========================================="
    echo "PyTorch Build Configuration"
    echo "========================================="
    echo "GPU Target: ${gpuArch} (Blackwell: RTX 5090)"
    echo "CPU Features: AVX2 (broad compatibility)"
    echo "CUDA: Enabled with cuBLAS (12.8)"
    echo "TORCH_CUDA_ARCH_LIST: $TORCH_CUDA_ARCH_LIST"
    echo "CXXFLAGS: $CXXFLAGS"
    echo ""
    echo "⚠️  WARNING: SM120 support requires PyTorch 2.7+"
    echo "    Current PyTorch version: ${oldAttrs.version or "unknown"}"
    echo "========================================="
  '';

  meta = oldAttrs.meta // {
    description = "PyTorch optimized for NVIDIA RTX 5090 (SM120) with AVX2 CPU instructions";
    longDescription = ''
      Custom PyTorch build with targeted optimizations:
      - GPU: NVIDIA Blackwell architecture (SM120) - RTX 5090
      - CPU: x86-64 with AVX2 instruction set (broad compatibility)
      - CUDA: 12.8 (PyTorch 2.7 default)
      - BLAS: cuBLAS for GPU operations, dynamic OpenBLAS for host-side
      - Python: 3.13

      Hardware support:
      - GPU: RTX 5090, Blackwell architecture GPUs
      - CPU: Intel Haswell+ (2013+), AMD Zen 1+ (2017+)
      - Driver: NVIDIA 570+ required

      ⚠️  IMPORTANT: SM120 (Blackwell) support was added in PyTorch 2.7
    '';
    platforms = [ "x86_64-linux" ];
  };
})
