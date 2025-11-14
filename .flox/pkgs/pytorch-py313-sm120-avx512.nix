# PyTorch optimized for NVIDIA Blackwell (SM120: RTX 5090) + AVX-512
# Package name: pytorch-py313-sm120-avx512
#
# NOTE: SM120 support requires PyTorch 2.7+ or nightly builds
# The stable PyTorch in nixpkgs may not support SM120 yet.
# You may need to override the PyTorch version or use a nightly build.

{ python3Packages
, lib
, config
, cudaPackages
, addDriverRunpath
}:

let
  # GPU target: SM120 (Blackwell architecture - RTX 5090)
  gpuArch = "sm_120";

  # CPU optimization: AVX-512
  cpuFlags = [
    "-mavx512f"    # AVX-512 Foundation
    "-mavx512dq"   # Doubleword and Quadword instructions
    "-mavx512vl"   # Vector Length extensions
    "-mavx512bw"   # Byte and Word instructions
    "-mfma"        # Fused multiply-add
  ];

in python3Packages.pytorch.overrideAttrs (oldAttrs: {
  pname = "pytorch-py313-sm120-avx512";

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

    # Optimize for target architecture (SM120 = compute capability 12.0)
    export CMAKE_CUDA_ARCHITECTURES="${lib.removePrefix "sm_" gpuArch}"

    echo "========================================="
    echo "PyTorch Build Configuration"
    echo "========================================="
    echo "GPU Target: ${gpuArch} (Blackwell: RTX 5090)"
    echo "CPU Features: AVX-512"
    echo "CUDA: Enabled with cuBLAS"
    echo "TORCH_CUDA_ARCH_LIST: $TORCH_CUDA_ARCH_LIST"
    echo "CXXFLAGS: $CXXFLAGS"
    echo ""
    echo "⚠️  WARNING: SM120 support requires PyTorch 2.7+"
    echo "    Current PyTorch version: ${oldAttrs.version or "unknown"}"
    echo "    If build fails, you may need PyTorch nightly"
    echo "========================================="
  '';

  meta = oldAttrs.meta // {
    description = "PyTorch optimized for NVIDIA RTX 5090 (SM120) with AVX-512 CPU instructions";
    longDescription = ''
      Custom PyTorch build with targeted optimizations:
      - GPU: NVIDIA Blackwell architecture (SM120) - RTX 5090
      - CPU: x86-64 with AVX-512 instruction set
      - BLAS: NVIDIA cuBLAS for GPU operations

      ⚠️  IMPORTANT: SM120 (Blackwell) support was added in PyTorch 2.7
      The stable PyTorch version in nixpkgs may not support SM120 yet.
      If compilation fails with "unknown compute capability" errors,
      you'll need to use PyTorch nightly builds or wait for PyTorch 2.7+
      to land in nixpkgs.

      See: https://github.com/pytorch/pytorch/issues/159207

      This build is optimized for cutting-edge gaming and workstation
      hardware with NVIDIA's latest Blackwell architecture.
    '';
    platforms = [ "x86_64-linux" ];
  };
})
