# PyTorch optimized for NVIDIA Hopper (SM90: H100, L40S) + AVX-512
# Package name: python313Packages.pytorch-sm90-avx512

{ python3Packages
, lib
, config
, cudaPackages
, addDriverRunpath
}:

let
  # GPU target: SM90 (Hopper architecture - H100, L40S)
  gpuArch = "sm_90";

  # CPU optimization: AVX-512
  cpuFlags = [
    "-mavx512f"    # AVX-512 Foundation
    "-mavx512dq"   # Doubleword and Quadword instructions
    "-mavx512vl"   # Vector Length extensions
    "-mavx512bw"   # Byte and Word instructions
    "-mfma"        # Fused multiply-add
  ];

in python3Packages.pytorch.overrideAttrs (oldAttrs: {
  pname = "python313Packages.pytorch-sm90-avx512";

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
    echo "GPU Target: ${gpuArch} (Hopper: H100, L40S)"
    echo "CPU Features: AVX-512"
    echo "CUDA: Enabled with cuBLAS"
    echo "TORCH_CUDA_ARCH_LIST: $TORCH_CUDA_ARCH_LIST"
    echo "CXXFLAGS: $CXXFLAGS"
    echo "========================================="
  '';

  meta = oldAttrs.meta // {
    description = "PyTorch optimized for NVIDIA H100/L40S (SM90) with AVX-512 CPU instructions";
    longDescription = ''
      Custom PyTorch build with targeted optimizations:
      - GPU: NVIDIA Hopper architecture (SM90) - H100, L40S
      - CPU: x86-64 with AVX-512 instruction set
      - BLAS: NVIDIA cuBLAS for GPU operations

      This build is optimized for high-performance computing workloads
      on modern datacenter hardware.
    '';
    platforms = [ "x86_64-linux" ];
  };
})
