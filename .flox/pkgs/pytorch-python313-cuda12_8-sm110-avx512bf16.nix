# PyTorch optimized for NVIDIA Blackwell Thor/DRIVE (SM110) + AVX-512 BF16
# Package name: pytorch-python313-cuda12_8-sm110-avx512bf16

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

  # CPU optimization: AVX-512 with BF16
  cpuFlags = [
    "-mavx512f"      # AVX-512 Foundation
    "-mavx512dq"     # Doubleword and Quadword instructions
    "-mavx512vl"     # Vector Length extensions
    "-mavx512bw"     # Byte and Word instructions
    "-mavx512bf16"   # Brain Float 16
    "-mfma"          # Fused multiply-add
  ];

in
  # Two-stage override:
  # 1. Enable CUDA and specify GPU targets
  (python3Packages.pytorch.override {
    cudaSupport = true;
    gpuTargets = [ gpuArchSM ];
  # 2. Customize build (CPU flags, metadata, etc.)
  }).overrideAttrs (oldAttrs: {
    pname = "pytorch-python313-cuda12_8-sm110-avx512bf16";

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
      echo "CPU Features: AVX-512 BF16 (mixed-precision training)"
      echo "CUDA: Enabled (cudaSupport=true, gpuTargets=[${gpuArchSM}])"
      echo "CXXFLAGS: $CXXFLAGS"
      echo "========================================="
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch for NVIDIA DRIVE (SM110, Blackwell Thor) + AVX-512 BF16";
      longDescription = ''
        Custom PyTorch build with targeted optimizations:
        - GPU: NVIDIA Blackwell Thor/DRIVE architecture (SM110)
        - CPU: x86-64 with AVX-512 BF16 instruction set
        - CUDA: 12.8 with compute capability 11.0
        - BLAS: cuBLAS for GPU operations
        - Python: 3.13

        Hardware requirements:
        - GPU: NVIDIA DRIVE platforms (Thor, Orin+), automotive/edge computing GPUs
        - CPU: Intel Cooper Lake+ (2020+), AMD Zen 4+ (2022+) with avx512_bf16
        - Driver: NVIDIA 550+ required

        Choose this if: You have NVIDIA DRIVE or Blackwell Thor GPU and CPU with AVX-512
        BF16 support for BF16 (Brain Float 16) mixed-precision training on CPU. For general
        workloads use avx512, for INT8 inference use avx512vnni.
      '';
      platforms = [ "x86_64-linux" ];
    };
  })
