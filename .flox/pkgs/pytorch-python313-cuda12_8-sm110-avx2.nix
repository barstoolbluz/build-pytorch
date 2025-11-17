# PyTorch optimized for NVIDIA Blackwell Thor/DRIVE (SM110) + AVX2
# Package name: pytorch-python313-cuda12_8-sm110-avx2

{ python3Packages
, lib
, config
, cudaPackages
, addDriverRunpath
}:

let
  # GPU target: SM110 (Blackwell Thor/NVIDIA DRIVE - automotive/edge computing)
  gpuArchNum = "110";  # For CMAKE_CUDA_ARCHITECTURES (just the integer)
  gpuArchSM = "sm_110";  # For TORCH_CUDA_ARCH_LIST (with sm_ prefix)

  # CPU optimization: AVX2 (broader compatibility)
  cpuFlags = [
    "-mavx2"       # AVX2 instructions
    "-mfma"        # Fused multiply-add
    "-mf16c"       # Half-precision conversions
  ];

in
  # Two-stage override:
  # 1. Enable CUDA and specify GPU targets
  (python3Packages.pytorch.override {
    cudaSupport = true;
    gpuTargets = [ gpuArchSM ];
  # 2. Customize build (CPU flags, metadata, etc.)
  }).overrideAttrs (oldAttrs: {
    pname = "pytorch-python313-cuda12_8-sm110-avx2";

    # Set CPU optimization flags
    # GPU architecture is handled by nixpkgs via gpuTargets parameter
    preConfigure = (oldAttrs.preConfigure or "") + ''
      # CPU optimizations via compiler flags
      export CXXFLAGS="$CXXFLAGS ${lib.concatStringsSep " " cpuFlags}"
      export CFLAGS="$CFLAGS ${lib.concatStringsSep " " cpuFlags}"

      echo "========================================="
      echo "PyTorch Build Configuration"
      echo "========================================="
      echo "GPU Target: ${gpuArchSM} (Blackwell Thor/DRIVE - Automotive/Edge)"
      echo "CPU Features: AVX2 (broad compatibility)"
      echo "CUDA: Enabled (cudaSupport=true, gpuTargets=[${gpuArchSM}])"
      echo "CXXFLAGS: $CXXFLAGS"
      echo "========================================="
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch for NVIDIA DRIVE (SM110, Blackwell Thor) with AVX2";
      longDescription = ''
        Custom PyTorch build with targeted optimizations:
        - GPU: NVIDIA Blackwell Thor/DRIVE architecture (SM110)
        - CPU: x86-64 with AVX2 instruction set (broad compatibility)
        - CUDA: 12.8 with compute capability 11.0
        - BLAS: cuBLAS for GPU operations
        - Python: 3.13

        Hardware requirements:
        - GPU: NVIDIA DRIVE platforms (Thor, Orin+), automotive/edge computing GPUs
        - CPU: Intel Haswell+ (2013+), AMD Zen 1+ (2017+)
        - Driver: NVIDIA 550+ required

        Choose this if: You have NVIDIA DRIVE or Blackwell Thor GPU for automotive AI
        or edge computing and want maximum CPU compatibility with AVX2. For specialized
        CPU workloads, consider avx512 (general), avx512bf16 (BF16), or avx512vnni (INT8).
      '';
      platforms = [ "x86_64-linux" ];
    };
  })
