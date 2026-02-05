# PyTorch optimized for NVIDIA Hopper (SM90: H100, L40S) + AVX-512 + BF16
# Package name: pytorch-python313-cuda12_8-sm90-avx512bf16

{ python3Packages
, lib
, config
, cudaPackages
, addDriverRunpath
}:

let
  # GPU target: SM90 (Hopper architecture - H100, L40S)
  gpuArchNum = "90";  # For CMAKE_CUDA_ARCHITECTURES (just the integer)
  gpuArchSM = "9.0";  # For TORCH_CUDA_ARCH_LIST (dot notation)

  # CPU optimization: AVX-512 + BF16 (Brain Float 16)
  cpuFlags = [
    "-mavx512f"    # AVX-512 Foundation
    "-mavx512dq"   # Doubleword and Quadword instructions
    "-mavx512vl"   # Vector Length extensions
    "-mavx512bw"   # Byte and Word instructions
    "-mavx512bf16" # Brain Float 16 instructions (ML training acceleration)
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
    pname = "pytorch-python313-cuda12_8-sm90-avx512bf16";

    # Set CPU optimization flags
    # GPU architecture is handled by nixpkgs via gpuTargets parameter
    preConfigure = (oldAttrs.preConfigure or "") + ''
      # CPU optimizations via compiler flags
      export CXXFLAGS="$CXXFLAGS ${lib.concatStringsSep " " cpuFlags}"
      export CFLAGS="$CFLAGS ${lib.concatStringsSep " " cpuFlags}"

      echo "========================================="
      echo "PyTorch Build Configuration"
      echo "========================================="
      echo "GPU Target: ${gpuArchSM} (Hopper: H100, L40S)"
      echo "CPU Features: AVX-512 + BF16"
      echo "CUDA: Enabled (cudaSupport=true, gpuTargets=[${gpuArchSM}])"
      echo "CXXFLAGS: $CXXFLAGS"
      echo "========================================="
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch for NVIDIA H100/L40S (SM90) + AVX-512 BF16";
      longDescription = ''
        Custom PyTorch build with targeted optimizations:
        - GPU: NVIDIA Hopper architecture (SM90) - H100, L40S
        - CPU: x86-64 with AVX-512 + BF16 instruction set
        - CUDA: 12.8 with compute capability 9.0
        - BLAS: cuBLAS for GPU operations
        - Python: 3.13
        - Workload: BF16 mixed-precision training acceleration

        Hardware requirements:
        - GPU: H100, H200, L40S, or other SM90 GPUs
        - CPU: Intel Cooper Lake+ (2020+), AMD Zen 4+ (2022+)
        - Driver: NVIDIA 525+ required

        Choose this if: You have H100/L40S GPU + CPU with AVX-512 BF16 support,
        and need accelerated BF16 mixed-precision training. NOT for INT8 inference
        (use avx512vnni) or general FP32 (use avx512).
      '';
      platforms = [ "x86_64-linux" ];
    };
  })
