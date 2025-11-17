# PyTorch optimized for NVIDIA Blackwell B300 Datacenter (SM103: B300) + AVX2
# Package name: pytorch-python313-cuda12_8-sm103-avx2

{ python3Packages
, lib
, config
, cudaPackages
, addDriverRunpath
}:

let
  # GPU target: SM103 (Blackwell B300 datacenter architecture)
  gpuArchNum = "103";  # For CMAKE_CUDA_ARCHITECTURES (just the integer)
  gpuArchSM = "sm_103";  # For TORCH_CUDA_ARCH_LIST (with sm_ prefix)

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
    pname = "pytorch-python313-cuda12_8-sm103-avx2";

    # Set CPU optimization flags
    # GPU architecture is handled by nixpkgs via gpuTargets parameter
    preConfigure = (oldAttrs.preConfigure or "") + ''
      # CPU optimizations via compiler flags
      export CXXFLAGS="$CXXFLAGS ${lib.concatStringsSep " " cpuFlags}"
      export CFLAGS="$CFLAGS ${lib.concatStringsSep " " cpuFlags}"

      echo "========================================="
      echo "PyTorch Build Configuration"
      echo "========================================="
      echo "GPU Target: ${gpuArchSM} (Blackwell B300 Datacenter)"
      echo "CPU Features: AVX2 (broad compatibility)"
      echo "CUDA: Enabled (cudaSupport=true, gpuTargets=[${gpuArchSM}])"
      echo "CXXFLAGS: $CXXFLAGS"
      echo "========================================="
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch for NVIDIA B300 (SM103, Blackwell DC) with AVX2";
      longDescription = ''
        Custom PyTorch build with targeted optimizations:
        - GPU: NVIDIA Blackwell B300 datacenter architecture (SM103)
        - CPU: x86-64 with AVX2 instruction set (broad compatibility)
        - CUDA: 12.8 with compute capability 10.3
        - BLAS: cuBLAS for GPU operations
        - Python: 3.13

        Hardware requirements:
        - GPU: B300 or other SM103 GPUs
        - CPU: Intel Haswell+ (2013+), AMD Zen 1+ (2017+)
        - Driver: NVIDIA 550+ required

        Choose this if: You have B300 datacenter GPU and want maximum CPU
        compatibility with AVX2. For specialized CPU workloads, consider avx512
        (general), avx512bf16 (BF16 training), or avx512vnni (INT8 inference).
      '';
      platforms = [ "x86_64-linux" ];
    };
  })
