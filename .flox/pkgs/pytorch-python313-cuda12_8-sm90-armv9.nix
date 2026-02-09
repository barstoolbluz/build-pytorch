# PyTorch optimized for NVIDIA Hopper (SM90: H100, L40S) + ARMv9
# Package name: pytorch-python313-cuda12_8-sm90-armv9

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
    pname = "pytorch-python313-cuda12_8-sm90-armv9";

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
      echo "CPU Features: ARMv9 + SVE/SVE2"
      echo "CUDA: Enabled (cudaSupport=true, gpuTargets=[${gpuArchSM}])"
      echo "CXXFLAGS: $CXXFLAGS"
      echo "========================================="
    '';

    postInstall = (oldAttrs.postInstall or "") + ''
      echo 1 > $out/.metadata-rev
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch for NVIDIA H100/L40S (SM90) + ARMv9 (SVE2)";
      longDescription = ''
        Custom PyTorch build with targeted optimizations:
        - GPU: NVIDIA Hopper architecture (SM90) - H100, L40S
        - CPU: ARMv9-A with SVE/SVE2 (Scalable Vector Extensions)
        - CUDA: 12.8 with compute capability 9.0
        - BLAS: cuBLAS for GPU operations
        - Python: 3.13

        Hardware requirements:
        - GPU: H100, H200, L40S, or other SM90 GPUs
        - CPU: NVIDIA Grace, ARM Neoverse V1/V2, Cortex-X2+, AWS Graviton3+
        - Driver: NVIDIA 525+ required

        Choose this if: You have H100/L40S GPU on modern ARM server with
        ARMv9/SVE2 support (Grace, Graviton3+). For older ARM servers
        (Graviton2), use armv8_2 variant instead.
      '';
      platforms = [ "aarch64-linux" ];
    };
  })
