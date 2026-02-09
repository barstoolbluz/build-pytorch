# PyTorch optimized for NVIDIA Ampere Datacenter (SM80: A100, A30) + ARMv8.2
# Package name: pytorch-python313-cuda12_8-sm80-armv8_2

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

  # CPU optimization: ARMv8.2-A with FP16 and dot product
  cpuFlags = [
    "-march=armv8.2-a+fp16+dotprod"  # ARMv8.2 with half-precision and dot product
  ];

in
  # Two-stage override:
  # 1. Enable CUDA and specify GPU targets
  (python3Packages.pytorch.override {
    cudaSupport = true;
    gpuTargets = [ gpuArchSM ];
  # 2. Customize build (CPU flags, metadata, etc.)
  }).overrideAttrs (oldAttrs: {
    pname = "pytorch-python313-cuda12_8-sm80-armv8_2";

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
      echo "CPU Features: ARMv8.2 + FP16 + DotProd"
      echo "CUDA: Enabled (cudaSupport=true, gpuTargets=[${gpuArchSM}])"
      echo "CXXFLAGS: $CXXFLAGS"
      echo "========================================="
    '';

    postInstall = (oldAttrs.postInstall or "") + ''
      echo 1 > $out/.metadata-rev
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch for NVIDIA A100/A30 (SM80, Ampere) + ARMv8.2";
      longDescription = ''
        Custom PyTorch build with targeted optimizations:
        - GPU: NVIDIA Ampere datacenter architecture (SM80) - A100, A30
        - CPU: ARMv8.2-A with FP16 and dot product instructions
        - CUDA: 12.8 with compute capability 8.0
        - BLAS: cuBLAS for GPU operations
        - Python: 3.13

        Hardware requirements:
        - GPU: A100 (40GB/80GB), A30, or other SM80 GPUs
        - CPU: ARM Neoverse N1, Cortex-A75+, AWS Graviton2
        - Driver: NVIDIA 450+ required

        Choose this if: You have A100 or A30 datacenter GPU on ARM server (Graviton2)
        and need GPU acceleration on ARM platform. For newer ARM servers
        (Graviton3+, Grace), use armv9 variant instead.
      '';
      platforms = [ "aarch64-linux" ];
    };
  })
