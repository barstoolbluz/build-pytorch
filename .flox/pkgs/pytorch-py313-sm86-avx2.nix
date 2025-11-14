# PyTorch optimized for NVIDIA Ampere (SM86: RTX 3090, A40) + AVX2
# Package name: pytorch-py313-sm86-avx2

{ python3Packages
, lib
, config
, cudaPackages
, addDriverRunpath
}:

let
  # GPU target: SM86 (Ampere architecture - RTX 3090, A5000, A40)
  gpuArch = "sm_86";

  # CPU optimization: AVX2 (broader compatibility)
  cpuFlags = [
    "-mavx2"       # AVX2 instructions
    "-mfma"        # Fused multiply-add
    "-mf16c"       # Half-precision conversions
  ];

in python3Packages.pytorch.overrideAttrs (oldAttrs: {
  pname = "pytorch-py313-sm86-avx2";

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

    # Optimize for target architecture
    export CMAKE_CUDA_ARCHITECTURES="${lib.removePrefix "sm_" gpuArch}"

    echo "========================================="
    echo "PyTorch Build Configuration"
    echo "========================================="
    echo "GPU Target: ${gpuArch} (Ampere: RTX 3090, A5000, A40)"
    echo "CPU Features: AVX2"
    echo "CUDA: Enabled with cuBLAS"
    echo "TORCH_CUDA_ARCH_LIST: $TORCH_CUDA_ARCH_LIST"
    echo "CXXFLAGS: $CXXFLAGS"
    echo "========================================="
  '';

  meta = oldAttrs.meta // {
    description = "PyTorch optimized for NVIDIA RTX 3090/A40 (SM86) with AVX2 CPU instructions";
    longDescription = ''
      Custom PyTorch build with targeted optimizations:
      - GPU: NVIDIA Ampere architecture (SM86) - RTX 3090, A5000, A40
      - CPU: x86-64 with AVX2 instruction set (broad compatibility)
      - BLAS: NVIDIA cuBLAS for GPU operations

      This build balances performance with broader CPU compatibility,
      making it suitable for a wide range of workstations and servers.
    '';
    platforms = [ "x86_64-linux" ];
  };
})
