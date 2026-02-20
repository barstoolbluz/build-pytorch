# PyTorch optimized for NVIDIA Turing (SM75: T4, RTX 2080 Ti) + AVX2
# Package name: pytorch-python313-cuda12_8-sm75-avx2

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

  # CPU optimization: AVX2 (broader compatibility)
  cpuFlags = [
    "-mavx2"       # AVX2 instructions
    "-mfma"        # Fused multiply-add
    "-mf16c"       # Half-precision conversions
  ];

in
  # Two-stage override:
  # 1. Enable CUDA and specify GPU targets
  (python3Packages.pytorch.override {
    cudaSupport = true;
    gpuTargets = [ gpuArchNum ];
  # 2. Customize build (CPU flags, metadata, etc.)
  }).overrideAttrs (oldAttrs: {
    pname = "pytorch-python313-cuda12_8-sm75-avx2";
    passthru = oldAttrs.passthru // {
      gpuArch = gpuArchNum;
      blasProvider = "cublas";
      cpuISA = "avx2";
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
      echo "CPU Features: AVX2 (broad compatibility)"
      echo "CUDA: Enabled (cudaSupport=true, gpuTargets=[${gpuArchNum}])"
      echo "CXXFLAGS: $CXXFLAGS"
      echo "========================================="
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch for NVIDIA T4/RTX 2080 Ti (SM75, Turing) + AVX2";
      longDescription = ''
        Custom PyTorch build with targeted optimizations:
        - GPU: NVIDIA Turing architecture (SM75) - T4, RTX 2080 Ti, Quadro RTX 8000
        - CPU: x86-64 with AVX2 instruction set (broad compatibility)
        - CUDA: 12.8 with compute capability 7.5
        - BLAS: cuBLAS for GPU operations
        - Python: 3.13

        Hardware requirements:
        - GPU: T4, RTX 2080 Ti, RTX 2080 Super, Quadro RTX 8000, or other SM75 GPUs
        - CPU: Intel Haswell+ (2013+), AMD Zen 1+ (2017+) with AVX2
        - Driver: NVIDIA 418+ required

        Choose this if: You have T4/RTX 2080 Ti-class GPU and want maximum CPU
        compatibility with AVX2. Newer GPUs (RTX 3090, RTX 4090) will work
        via backward compatibility but won't get architecture-specific kernels.
        For those, use sm86, sm90, or sm120 builds instead.
      '';
      platforms = [ "x86_64-linux" ];
    };
  })
