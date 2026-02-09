# PyTorch optimized for NVIDIA Ampere (SM86: RTX 3090, A5000, A40) + AVX-512 + VNNI
# Package name: pytorch-python313-cuda12_8-sm86-avx512vnni

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

  # CPU optimization: AVX-512 + VNNI (Vector Neural Network Instructions)
  cpuFlags = [
    "-mavx512f"    # AVX-512 Foundation
    "-mavx512dq"   # Doubleword and Quadword instructions
    "-mavx512vl"   # Vector Length extensions
    "-mavx512bw"   # Byte and Word instructions
    "-mavx512vnni" # Vector Neural Network Instructions (INT8 acceleration)
    "-mfma"        # Fused multiply-add
  ];

in
  # Two-stage override:
  # 1. Enable CUDA and specify GPU targets
  (python3Packages.pytorch.override {
    cudaSupport = true;
    gpuTargets = [ gpuArchNum ];
  # 2. Customize build (CPU flags, metadata, etc.)
  }).overrideAttrs (oldAttrs: {
    pname = "pytorch-python313-cuda12_8-sm86-avx512vnni";

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
      echo "CPU Features: AVX-512 + VNNI"
      echo "CUDA: Enabled (cudaSupport=true, gpuTargets=[${gpuArchNum}])"
      echo "CXXFLAGS: $CXXFLAGS"
      echo "========================================="
    '';

    postInstall = (oldAttrs.postInstall or "") + ''
      echo 1 > $out/.metadata-rev
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch for NVIDIA RTX 3090/A40 (SM86) + AVX-512 VNNI";
      longDescription = ''
        Custom PyTorch build with targeted optimizations:
        - GPU: NVIDIA Ampere architecture (SM86) - RTX 3090, A5000, A40
        - CPU: x86-64 with AVX-512 + VNNI instruction set
        - CUDA: 12.8 with compute capability 8.6
        - BLAS: cuBLAS for GPU operations
        - Python: 3.13
        - Workload: INT8 quantized model inference acceleration

        Hardware requirements:
        - GPU: RTX 3090, RTX 3080 Ti, A5000, A40, or other SM86 GPUs
        - CPU: Intel Skylake-SP+ (2017+), AMD Zen 4+ (2022+)
        - Driver: NVIDIA 470+ required

        Choose this if: You have RTX 3090/A40 GPU + CPU with AVX-512 VNNI support,
        and need accelerated INT8 quantized inference. NOT for training
        (use avx512bf16) or general FP32 (use avx512).
      '';
      platforms = [ "x86_64-linux" ];
    };
  })
