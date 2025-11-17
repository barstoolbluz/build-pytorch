# PyTorch optimized for NVIDIA Blackwell Thor/DRIVE (SM110) + ARMv8.2
# Package name: pytorch-python313-cuda12_8-sm110-armv8.2

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

  # CPU optimization: ARMv8.2-A
  cpuFlags = [
    "-march=armv8.2-a+fp16+dotprod"  # ARMv8.2 with FP16 and dot product
  ];

in
  # Two-stage override:
  # 1. Enable CUDA and specify GPU targets
  (python3Packages.pytorch.override {
    cudaSupport = true;
    gpuTargets = [ gpuArchSM ];
  # 2. Customize build (CPU flags, metadata, etc.)
  }).overrideAttrs (oldAttrs: {
    pname = "pytorch-python313-cuda12_8-sm110-armv8.2";

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
      echo "CPU Features: ARMv8.2-A + FP16 + DotProd"
      echo "CUDA: Enabled (cudaSupport=true, gpuTargets=[${gpuArchSM}])"
      echo "CXXFLAGS: $CXXFLAGS"
      echo "========================================="
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch for NVIDIA DRIVE (SM110, Blackwell Thor) + ARMv8.2";
      longDescription = ''
        Custom PyTorch build with targeted optimizations:
        - GPU: NVIDIA Blackwell Thor/DRIVE architecture (SM110)
        - CPU: ARMv8.2-A with FP16 and dot product instructions
        - CUDA: 12.8 with compute capability 11.0
        - BLAS: cuBLAS for GPU operations
        - Python: 3.13

        Hardware requirements:
        - GPU: NVIDIA DRIVE platforms (Thor, Orin+), automotive/edge computing GPUs
        - CPU: ARM Neoverse N1, Cortex-A75+, automotive ARM SoCs
        - Driver: NVIDIA 550+ required

        Choose this if: You have NVIDIA DRIVE or Blackwell Thor GPU on older ARM platform
        without SVE2 support (Orin, older automotive SoCs). For newer ARM platforms with
        SVE2, use armv9 variant instead.
      '';
      platforms = [ "aarch64-linux" ];
    };
  })
