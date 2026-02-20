# PyTorch optimized for NVIDIA Turing (SM75: T4, RTX 2080 Ti) + AVX-512 + VNNI
# Package name: pytorch-python313-cuda12_8-sm75-avx512vnni

{ python3Packages
, lib
, config
, cudaPackages
, addDriverRunpath
}:

let
  # GPU target: SM75 (Turing architecture - T4, RTX 2080 Ti, Quadro RTX 8000)
  # PyTorch's CMake accepts numeric format (7.5) not sm_75
  gpuArchNum = "7.5";

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
    pname = "pytorch-python313-cuda12_8-sm75-avx512vnni";
    passthru = oldAttrs.passthru // {
      gpuArch = gpuArchNum;
      blasProvider = "cublas";
      cpuISA = "avx512vnni";
    };

    # Set CPU optimization flags
    # GPU architecture is handled by nixpkgs via gpuTargets parameter
    preConfigure = (oldAttrs.preConfigure or "") + ''
      # CPU optimizations via compiler flags
      export CXXFLAGS="$CXXFLAGS ${lib.concatStringsSep " " cpuFlags}"
      export CFLAGS="$CFLAGS ${lib.concatStringsSep " " cpuFlags}"

      echo "========================================="
      echo "PyTorch Build Configuration"
      echo "========================================="
      echo "GPU Target: ${gpuArchNum} (Turing: T4, RTX 2080 Ti, Quadro RTX 8000)"
      echo "CPU Features: AVX-512 + VNNI"
      echo "CUDA: Enabled (cudaSupport=true, gpuTargets=[${gpuArchNum}])"
      echo "CXXFLAGS: $CXXFLAGS"
      echo "========================================="
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch for NVIDIA T4/RTX 2080 Ti (SM75, Turing) + AVX-512 VNNI (INT8 inference)";
      longDescription = ''
        Custom PyTorch build with targeted optimizations:
        - GPU: NVIDIA Turing architecture (SM75) - T4, RTX 2080 Ti, Quadro RTX 8000
        - CPU: x86-64 with AVX-512 + VNNI instruction set
        - CUDA: 12.8 with compute capability 7.5
        - BLAS: cuBLAS for GPU operations
        - Python: 3.13
        - Workload: INT8 quantized model inference acceleration

        Hardware requirements:
        - GPU: T4, RTX 2080 Ti, RTX 2080 Super, Quadro RTX 8000, or other SM75 GPUs
        - CPU: Intel Skylake-SP+ (2017+), AMD Zen 4+ (2022+)
        - Driver: NVIDIA 418+ required

        Choose this if: You have T4/RTX 2080 Ti GPU + CPU with AVX-512 VNNI support,
        and need accelerated INT8 quantized inference. NOT for training
        (use avx512bf16) or general FP32 (use avx512).
      '';
      platforms = [ "x86_64-linux" ];
    };
  })
