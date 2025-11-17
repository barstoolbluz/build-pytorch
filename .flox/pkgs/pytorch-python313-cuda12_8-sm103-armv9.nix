# PyTorch optimized for NVIDIA Blackwell B300 Datacenter (SM103: B300) + ARMv9
# Package name: pytorch-python313-cuda12_8-sm103-armv9

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
    pname = "pytorch-python313-cuda12_8-sm103-armv9";

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
      echo "CPU Features: ARMv9 + SVE/SVE2"
      echo "CUDA: Enabled (cudaSupport=true, gpuTargets=[${gpuArchSM}])"
      echo "CXXFLAGS: $CXXFLAGS"
      echo "========================================="
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch for NVIDIA B300 (SM103, Blackwell DC) + ARMv9 (SVE2)";
      longDescription = ''
        Custom PyTorch build with targeted optimizations:
        - GPU: NVIDIA Blackwell B300 datacenter architecture (SM103)
        - CPU: ARMv9-A with SVE/SVE2 (Scalable Vector Extensions)
        - CUDA: 12.8 with compute capability 10.3
        - BLAS: cuBLAS for GPU operations
        - Python: 3.13

        Hardware requirements:
        - GPU: B300 or other SM103 GPUs
        - CPU: NVIDIA Grace, ARM Neoverse V1/V2, Cortex-X2+, AWS Graviton3+
        - Driver: NVIDIA 550+ required

        Choose this if: You have B300 datacenter GPU on modern ARM server with
        ARMv9/SVE2 support (Grace, Graviton3+). For older ARM servers
        (Graviton2), use armv8.2 variant instead.
      '';
      platforms = [ "aarch64-linux" ];
    };
  })
