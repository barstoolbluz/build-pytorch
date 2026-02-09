# PyTorch optimized for NVIDIA Ampere Datacenter (SM80: A100, A30) + ARMv9
# Package name: pytorch-python313-cuda12_8-sm80-armv9

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
    pname = "pytorch-python313-cuda12_8-sm80-armv9";

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
      echo "CPU Features: ARMv9 + SVE/SVE2"
      echo "CUDA: Enabled (cudaSupport=true, gpuTargets=[${gpuArchSM}])"
      echo "CXXFLAGS: $CXXFLAGS"
      echo "========================================="
    '';

    postInstall = (oldAttrs.postInstall or "") + ''
      echo 1 > $out/.metadata-rev
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch for NVIDIA A100/A30 (SM80, Ampere) + ARMv9 (SVE2)";
      longDescription = ''
        Custom PyTorch build with targeted optimizations:
        - GPU: NVIDIA Ampere datacenter architecture (SM80) - A100, A30
        - CPU: ARMv9-A with SVE/SVE2 (Scalable Vector Extensions)
        - CUDA: 12.8 with compute capability 8.0
        - BLAS: cuBLAS for GPU operations
        - Python: 3.13

        Hardware requirements:
        - GPU: A100 (40GB/80GB), A30, or other SM80 GPUs
        - CPU: NVIDIA Grace, ARM Neoverse V1/V2, Cortex-X2+, AWS Graviton3+
        - Driver: NVIDIA 450+ required

        Choose this if: You have A100 or A30 datacenter GPU on modern ARM server with
        ARMv9/SVE2 support (Grace, Graviton3+). For older ARM servers
        (Graviton2), use armv8_2 variant instead.
      '';
      platforms = [ "aarch64-linux" ];
    };
  })
