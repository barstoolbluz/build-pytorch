# PyTorch optimized for NVIDIA Ampere (SM86: RTX 3090, A40) + AVX2
# Package name: pytorch-python313-cuda12_8-sm86-avx2

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
    pname = "pytorch-python313-cuda12_8-sm86-avx2";

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
      echo "CPU Features: AVX2 (broad compatibility)"
      echo "CUDA: Enabled (cudaSupport=true, gpuTargets=[${gpuArchNum}])"
      echo "CXXFLAGS: $CXXFLAGS"
      echo "========================================="
    '';

    postInstall = (oldAttrs.postInstall or "") + ''
      echo 1 > $out/.metadata-rev
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch for NVIDIA RTX 3090/A40 (SM86, Ampere) with CUDA";
      longDescription = ''
        Custom PyTorch build with targeted optimizations:
        - GPU: NVIDIA Ampere architecture (SM86) - RTX 3090, A5000, A40
        - CPU: x86-64 with AVX2 instruction set (broad compatibility)
        - CUDA: 12.8 with compute capability 8.6
        - BLAS: cuBLAS for GPU operations
        - Python: 3.13

        Hardware requirements:
        - GPU: RTX 3090, RTX 3080 Ti, A5000, A40, or other SM86 GPUs
        - CPU: Intel Haswell+ (2013+), AMD Zen 1+ (2017+) with AVX2
        - Driver: NVIDIA 470+ required

        Choose this if: You have RTX 3090/A40-class GPU and want maximum CPU
        compatibility with AVX2. Newer GPUs (RTX 4090, RTX 5090) will work
        via backward compatibility but won't get architecture-specific kernels.
        For those, use sm90 or sm120 builds instead.
      '';
      platforms = [ "x86_64-linux" ];
    };
  })
