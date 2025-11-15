# PyTorch optimized for NVIDIA Blackwell (RTX 5090) + AVX-512 BF16
# Package name: pytorch-python313-cuda12_8-sm120-avx512bf16
#
# Optimized for BF16 training workloads (modern mixed-precision)
# Hardware: Intel Cooper Lake+ (2020), AMD Zen 4+ (2022)

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

  # CPU optimization: AVX-512 + BF16 (Brain Float 16)
  cpuFlags = [
    "-mavx512f"    # AVX-512 Foundation
    "-mavx512dq"   # Doubleword and Quadword instructions
    "-mavx512vl"   # Vector Length extensions
    "-mavx512bw"   # Byte and Word instructions
    "-mavx512bf16" # Brain Float 16 instructions (ML training acceleration)
    "-mfma"        # Fused multiply-add
  ];

in python3Packages.pytorch.overrideAttrs (oldAttrs: {
  pname = "pytorch-python313-cuda12_8-sm120-avx512bf16";

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
    echo "CPU Features: AVX-512 + BF16 (mixed-precision training optimized)"
    echo "CUDA: Enabled with cuBLAS (12.8)"
    echo "TORCH_CUDA_ARCH_LIST: $TORCH_CUDA_ARCH_LIST"
    echo "CXXFLAGS: $CXXFLAGS"
    echo ""
    echo "⚠️  WARNING: SM120 support requires PyTorch 2.7+"
    echo "    Current PyTorch version: ${oldAttrs.version or "unknown"}"
    echo "========================================="
  '';

  meta = oldAttrs.meta // {
    description = "PyTorch optimized for NVIDIA RTX 5090 (SM120) with AVX-512 BF16 (mixed-precision training)";
    longDescription = ''
      Custom PyTorch build with targeted optimizations:
      - GPU: NVIDIA Blackwell architecture (SM120) - RTX 5090
      - CPU: x86-64 with AVX-512 + BF16 (Brain Float 16 instructions)
      - CUDA: 12.8 (PyTorch 2.7 default)
      - BLAS: cuBLAS for GPU operations, dynamic OpenBLAS for host-side
      - Python: 3.13
      - Optimization: BF16 mixed-precision training acceleration

      Hardware support:
      - GPU: RTX 5090, Blackwell architecture GPUs
      - CPU: Intel Cooper Lake+ (2020+), AMD Zen 4+ (2022+)
      - Driver: NVIDIA 570+ required

      Use case: Optimized for modern mixed-precision training (BF16 operations)
    '';
    platforms = [ "x86_64-linux" ];
  };
})
