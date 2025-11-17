# PyTorch optimized for NVIDIA Blackwell B300 Datacenter (SM103: B300) + ARMv8.2
# Package name: pytorch-python313-cuda12_8-sm103-armv8.2

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
    pname = "pytorch-python313-cuda12_8-sm103-armv8.2";

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
      echo "CPU Features: ARMv8.2-A + FP16 + DotProd"
      echo "CUDA: Enabled (cudaSupport=true, gpuTargets=[${gpuArchSM}])"
      echo "CXXFLAGS: $CXXFLAGS"
      echo "========================================="
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch for NVIDIA B300 (SM103, Blackwell DC) + ARMv8.2";
      longDescription = ''
        Custom PyTorch build with targeted optimizations:
        - GPU: NVIDIA Blackwell B300 datacenter architecture (SM103)
        - CPU: ARMv8.2-A with FP16 and dot product instructions
        - CUDA: 12.8 with compute capability 10.3
        - BLAS: cuBLAS for GPU operations
        - Python: 3.13

        Hardware requirements:
        - GPU: B300 or other SM103 GPUs
        - CPU: ARM Neoverse N1, Cortex-A75+, AWS Graviton2
        - Driver: NVIDIA 550+ required

        Choose this if: You have B300 datacenter GPU on older ARM server without SVE2
        support (Graviton2, Neoverse N1). For newer ARM servers with SVE2 (Grace,
        Graviton3+), use armv9 variant instead.
      '';
      platforms = [ "aarch64-linux" ];
    };
  })
