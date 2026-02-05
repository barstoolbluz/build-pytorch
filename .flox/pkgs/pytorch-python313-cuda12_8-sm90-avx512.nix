# PyTorch optimized for NVIDIA Hopper (SM90: H100, L40S) + AVX-512
# Package name: pytorch-python313-cuda12_8-sm90-avx512

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

  # CPU optimization: AVX-512
  cpuFlags = [
    "-mavx512f"    # AVX-512 Foundation
    "-mavx512dq"   # Doubleword and Quadword instructions
    "-mavx512vl"   # Vector Length extensions
    "-mavx512bw"   # Byte and Word instructions
    "-mfma"        # Fused multiply-add
  ];

in
  # First, enable CUDA support via override
  (python3Packages.pytorch.override {
    cudaSupport = true;
    # Specify GPU targets using nixpkgs parameter
    gpuTargets = [ gpuArchSM ];
    # cudaPackages is automatically passed and uses the one from inputs
  }).overrideAttrs (oldAttrs: {
    pname = "pytorch-python313-cuda12_8-sm90-avx512";

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
      echo "CPU Features: AVX-512"
      echo "CUDA: Enabled (cudaSupport=true, gpuTargets=[${gpuArchSM}])"
      echo "CXXFLAGS: $CXXFLAGS"
      echo "========================================="
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch for NVIDIA H100/L40S (SM90, Hopper) with CUDA";
      longDescription = ''
        Custom PyTorch build with targeted optimizations:
        - GPU: NVIDIA Hopper architecture (SM90) - H100, L40S
        - CPU: x86-64 with AVX-512 instruction set
        - CUDA: 12.8 with compute capability 9.0
        - BLAS: cuBLAS for GPU operations
        - Python: 3.13

        Hardware requirements:
        - GPU: H100, H200, L40S, or other SM90 GPUs
        - CPU: Intel Skylake-X+ (2017+), AMD Zen 4+ (2022+) with AVX-512
        - Driver: NVIDIA 525+ required

        Choose this if: You have H100/L40S datacenter GPUs with AVX-512 CPUs
        and need optimized kernels for Hopper architecture. For RTX 5090, use
        sm120 builds instead.
      '';
      platforms = [ "x86_64-linux" ];
    };
  })
