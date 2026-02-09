# PyTorch optimized for NVIDIA Blackwell (SM120: RTX 5090) + ARMv8.2
# Package name: pytorch-python313-cuda12_8-sm120-armv8_2

{ python3Packages
, lib
, config
, cudaPackages
, addDriverRunpath
}:

let
  # GPU target: SM120 (Blackwell architecture - RTX 5090)
  # PyTorch's CMake accepts numeric format (12.0) not sm_120
  gpuArchNum = "12.0";

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
    pname = "pytorch-python313-cuda12_8-sm120-armv8_2";

    # Set CPU optimization flags
    # GPU architecture is handled by nixpkgs via gpuTargets parameter
    preConfigure = (oldAttrs.preConfigure or "") + ''
      # CPU optimizations via compiler flags
      export CXXFLAGS="$CXXFLAGS ${lib.concatStringsSep " " cpuFlags}"
      export CFLAGS="$CFLAGS ${lib.concatStringsSep " " cpuFlags}"

      echo "========================================="
      echo "PyTorch Build Configuration"
      echo "========================================="
      echo "GPU Target: ${gpuArchNum} (Blackwell: RTX 5090)"
      echo "CPU Features: ARMv8.2 + FP16 + DotProd"
      echo "CUDA: Enabled (cudaSupport=true, gpuTargets=[${gpuArchNum}])"
      echo "CXXFLAGS: $CXXFLAGS"
      echo "========================================="
    '';

    postInstall = (oldAttrs.postInstall or "") + ''
      echo 1 > $out/.metadata-rev
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch for NVIDIA RTX 5090 (SM120) + ARMv8.2";
      longDescription = ''
        Custom PyTorch build with targeted optimizations:
        - GPU: NVIDIA Blackwell architecture (SM120) - RTX 5090
        - CPU: ARMv8.2-A with FP16 and dot product instructions
        - CUDA: 12.8 with compute capability 12.0
        - BLAS: cuBLAS for GPU operations
        - Python: 3.13

        Hardware requirements:
        - GPU: RTX 5090, Blackwell architecture GPUs
        - CPU: ARM Neoverse N1, Cortex-A75+, AWS Graviton2
        - Driver: NVIDIA 570+ required

        ⚠️  IMPORTANT: SM120 (Blackwell) support was added in PyTorch 2.7

        Choose this if: You have RTX 5090 GPU on ARM server (Graviton2)
        and need GPU acceleration on ARM platform. For newer ARM servers
        (Graviton3+, Grace), use armv9 variant instead.
      '';
      platforms = [ "aarch64-linux" ];
    };
  })
