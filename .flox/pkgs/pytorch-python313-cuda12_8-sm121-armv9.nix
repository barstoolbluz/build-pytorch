# PyTorch optimized for NVIDIA DGX Spark (SM121) + ARMv9
# Package name: pytorch-python313-cuda12_8-sm121-armv9

{ python3Packages
, lib
, config
, cudaPackages
, addDriverRunpath
}:

let
  # GPU target: SM121 (DGX Spark - specialized datacenter)
  gpuArchNum = "121";  # For CMAKE_CUDA_ARCHITECTURES (just the integer)
  gpuArchSM = "sm_121";  # For TORCH_CUDA_ARCH_LIST (with sm_ prefix)

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
    pname = "pytorch-python313-cuda12_8-sm121-armv9";

    # Set CPU optimization flags
    # GPU architecture is handled by nixpkgs via gpuTargets parameter
    preConfigure = (oldAttrs.preConfigure or "") + ''
      # CPU optimizations via compiler flags
      export CXXFLAGS="$CXXFLAGS ${lib.concatStringsSep " " cpuFlags}"
      export CFLAGS="$CFLAGS ${lib.concatStringsSep " " cpuFlags}"

      echo "========================================="
      echo "PyTorch Build Configuration"
      echo "========================================="
      echo "GPU Target: ${gpuArchSM} (DGX Spark - Specialized Datacenter)"
      echo "CPU Features: ARMv9 + SVE/SVE2"
      echo "CUDA: Enabled (cudaSupport=true, gpuTargets=[${gpuArchSM}])"
      echo "CXXFLAGS: $CXXFLAGS"
      echo "========================================="
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch for NVIDIA DGX Spark (SM121) + ARMv9 (SVE2)";
      longDescription = ''
        Custom PyTorch build with targeted optimizations:
        - GPU: NVIDIA DGX Spark architecture (SM121)
        - CPU: ARMv9-A with SVE/SVE2 (Scalable Vector Extensions)
        - CUDA: 12.8 with compute capability 12.1
        - BLAS: cuBLAS for GPU operations
        - Python: 3.13

        Hardware requirements:
        - GPU: NVIDIA DGX Spark or other SM121 GPUs
        - CPU: NVIDIA Grace, ARM Neoverse V1/V2, Cortex-X2+, AWS Graviton3+
        - Driver: NVIDIA 570+ required

        Choose this if: You have DGX Spark specialized datacenter GPU on modern ARM
        platform with ARMv9/SVE2 support (Grace, Graviton3+). For older ARM platforms,
        use armv8.2 variant instead.
      '';
      platforms = [ "aarch64-linux" ];
    };
  })
