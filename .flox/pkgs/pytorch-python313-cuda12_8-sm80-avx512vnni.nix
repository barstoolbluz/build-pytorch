# PyTorch optimized for NVIDIA Ampere Datacenter (SM80: A100, A30) + AVX-512 + VNNI
# Package name: pytorch-python313-cuda12_8-sm80-avx512vnni

{ python3Packages
, lib
, config
, cudaPackages
, addDriverRunpath
}:

let
  # GPU target: SM80 (Ampere datacenter architecture - A100, A30)
  gpuArchNum = "80";  # For CMAKE_CUDA_ARCHITECTURES (just the integer)
  gpuArchSM = "8.0";  # For TORCH_CUDA_ARCH_LIST (dot notation)

  # CPU optimization: AVX-512 + VNNI (Vector Neural Network Instructions)
  cpuFlags = [
    "-mavx512f"    # AVX-512 Foundation
    "-mavx512dq"   # Doubleword and Quadword instructions
    "-mavx512vl"   # Vector Length extensions
    "-mavx512bw"   # Byte and Word instructions
    "-mavx512vnni" # Vector Neural Network Instructions (INT8 acceleration)
    "-mfma"        # Fused multiply-add
  ];

in
  # Two-stage override:
  # 1. Enable CUDA and specify GPU targets
  (python3Packages.pytorch.override {
    cudaSupport = true;
    gpuTargets = [ gpuArchSM ];
  # 2. Customize build (CPU flags, metadata, etc.)
  }).overrideAttrs (oldAttrs: {
    pname = "pytorch-python313-cuda12_8-sm80-avx512vnni";

    # Set CPU optimization flags
    # GPU architecture is handled by nixpkgs via gpuTargets parameter
    preConfigure = (oldAttrs.preConfigure or "") + ''
      # CPU optimizations via compiler flags
      export CXXFLAGS="$CXXFLAGS ${lib.concatStringsSep " " cpuFlags}"
      export CFLAGS="$CFLAGS ${lib.concatStringsSep " " cpuFlags}"

      echo "========================================="
      echo "PyTorch Build Configuration"
      echo "========================================="
      echo "GPU Target: ${gpuArchSM} (Ampere Datacenter: A100, A30)"
      echo "CPU Features: AVX-512 + VNNI"
      echo "CUDA: Enabled (cudaSupport=true, gpuTargets=[${gpuArchSM}])"
      echo "CXXFLAGS: $CXXFLAGS"
      echo "========================================="
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch for NVIDIA A100/A30 (SM80, Ampere) + AVX-512 VNNI";
      longDescription = ''
        Custom PyTorch build with targeted optimizations:
        - GPU: NVIDIA Ampere datacenter architecture (SM80) - A100, A30
        - CPU: x86-64 with AVX-512 + VNNI instruction set
        - CUDA: 12.8 with compute capability 8.0
        - BLAS: cuBLAS for GPU operations
        - Python: 3.13
        - Workload: INT8 quantized model inference acceleration

        Hardware requirements:
        - GPU: A100 (40GB/80GB), A30, or other SM80 GPUs
        - CPU: Intel Skylake-SP+ (2017+), AMD Zen 4+ (2022+)
        - Driver: NVIDIA 450+ required

        Choose this if: You have A100 or A30 datacenter GPU + CPU with AVX-512 VNNI support,
        and need accelerated INT8 quantized inference. NOT for training
        (use avx512bf16) or general FP32 (use avx512).
      '';
      platforms = [ "x86_64-linux" ];
    };
  })
