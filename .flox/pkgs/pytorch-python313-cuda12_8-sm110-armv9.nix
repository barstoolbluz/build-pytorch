# PyTorch optimized for NVIDIA Blackwell Thor/DRIVE (SM110) + ARMv9
# Package name: pytorch-python313-cuda12_8-sm110-armv9

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

  # CPU optimization: ARMv9-A with SVE/SVE2
  cpuFlags = [
    "-march=armv9-a+sve+sve2"  # ARMv9 with Scalable Vector Extensions
  ];

in
  # Two-stage override:
  # 1. Enable CUDA and specify GPU targets
  (python3Packages.pytorch.override {
    cudaSupport = true;
    gpuTargets = [ gpuArchSM ];
  # 2. Customize build (CPU flags, metadata, etc.)
  }).overrideAttrs (oldAttrs: {
    pname = "pytorch-python313-cuda12_8-sm110-armv9";

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
      echo "CPU Features: ARMv9 + SVE/SVE2"
      echo "CUDA: Enabled (cudaSupport=true, gpuTargets=[${gpuArchSM}])"
      echo "CXXFLAGS: $CXXFLAGS"
      echo "========================================="
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch for NVIDIA DRIVE (SM110, Blackwell Thor) + ARMv9 (SVE2)";
      longDescription = ''
        Custom PyTorch build with targeted optimizations:
        - GPU: NVIDIA Blackwell Thor/DRIVE architecture (SM110)
        - CPU: ARMv9-A with SVE/SVE2 (Scalable Vector Extensions)
        - CUDA: 12.8 with compute capability 11.0
        - BLAS: cuBLAS for GPU operations
        - Python: 3.13

        Hardware requirements:
        - GPU: NVIDIA DRIVE platforms (Thor, Orin+), automotive/edge computing GPUs
        - CPU: Modern ARM automotive SoCs with ARMv9/SVE2 support
        - Driver: NVIDIA 550+ required

        Choose this if: You have NVIDIA DRIVE or Blackwell Thor GPU on modern ARM platform
        with ARMv9/SVE2 support (next-gen automotive SoCs). For older ARM platforms,
        use armv8.2 variant instead.
      '';
      platforms = [ "aarch64-linux" ];
    };
  })
