# PyTorch optimized for NVIDIA Ampere (SM86: RTX 3090, A5000, A40) + ARMv8.2
# Package name: pytorch-python313-cuda12_8-sm86-armv8.2

{ python3Packages
, lib
, config
, cudaPackages
, addDriverRunpath
}:

let
  # GPU target: SM86 (Ampere architecture - RTX 3090, A5000, A40)
  # PyTorch's CMake accepts numeric format (8.6) not sm_86
  gpuArchNum = "8.6";

  # CPU optimization: ARMv8.2-A with FP16 and dot product
  cpuFlags = [
    "-march=armv8.2-a+fp16+dotprod"  # ARMv8.2 with half-precision and dot product
  ];

in
  # Two-stage override:
  # 1. Enable CUDA and specify GPU targets
  (python3Packages.pytorch.override {
    cudaSupport = true;
    gpuTargets = [ gpuArchNum ];
  # 2. Customize build (CPU flags, metadata, etc.)
  }).overrideAttrs (oldAttrs: {
    pname = "pytorch-python313-cuda12_8-sm86-armv8.2";

    # Set CPU optimization flags
    # GPU architecture is handled by nixpkgs via gpuTargets parameter
    preConfigure = (oldAttrs.preConfigure or "") + ''
      # CPU optimizations via compiler flags
      export CXXFLAGS="$CXXFLAGS ${lib.concatStringsSep " " cpuFlags}"
      export CFLAGS="$CFLAGS ${lib.concatStringsSep " " cpuFlags}"

      echo "========================================="
      echo "PyTorch Build Configuration"
      echo "========================================="
      echo "GPU Target: ${gpuArchNum} (Ampere: RTX 3090, A5000, A40)"
      echo "CPU Features: ARMv8.2 + FP16 + DotProd"
      echo "CUDA: Enabled (cudaSupport=true, gpuTargets=[${gpuArchNum}])"
      echo "CXXFLAGS: $CXXFLAGS"
      echo "========================================="
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch for NVIDIA RTX 3090/A40 (SM86) + ARMv8.2";
      longDescription = ''
        Custom PyTorch build with targeted optimizations:
        - GPU: NVIDIA Ampere architecture (SM86) - RTX 3090, A5000, A40
        - CPU: ARMv8.2-A with FP16 and dot product instructions
        - CUDA: 12.8 with compute capability 8.6
        - BLAS: cuBLAS for GPU operations
        - Python: 3.13

        Hardware requirements:
        - GPU: RTX 3090, RTX 3080 Ti, A5000, A40, or other SM86 GPUs
        - CPU: ARM Neoverse N1, Cortex-A75+, AWS Graviton2
        - Driver: NVIDIA 470+ required

        Choose this if: You have RTX 3090/A40 GPU on ARM server (Graviton2)
        and need GPU acceleration on ARM platform. For newer ARM servers
        (Graviton3+, Grace), use armv9 variant instead.
      '';
      platforms = [ "aarch64-linux" ];
    };
  })
