# PyTorch optimized for NVIDIA Blackwell (SM120: RTX 5090) + AVX2
# Package name: pytorch-python313-cuda12_8-sm120-avx2

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
    pname = "pytorch-python313-cuda12_8-sm120-avx2";

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
      echo "CPU Features: AVX2 (broad compatibility)"
      echo "CUDA: Enabled (cudaSupport=true, gpuTargets=[${gpuArchNum}])"
      echo "CXXFLAGS: $CXXFLAGS"
      echo "========================================="
    '';

  meta = oldAttrs.meta // {
    description = "PyTorch optimized for NVIDIA RTX 5090 (SM120) with AVX2 CPU instructions";
    longDescription = ''
      Custom PyTorch build with targeted optimizations:
      - GPU: NVIDIA Blackwell architecture (SM120) - RTX 5090
      - CPU: x86-64 with AVX2 instruction set (broad compatibility)
      - CUDA: 12.8 (PyTorch 2.7 default)
      - BLAS: cuBLAS for GPU operations, dynamic OpenBLAS for host-side
      - Python: 3.13

      Hardware support:
      - GPU: RTX 5090, Blackwell architecture GPUs
      - CPU: Intel Haswell+ (2013+), AMD Zen 1+ (2017+)
      - Driver: NVIDIA 570+ required

      ⚠️  IMPORTANT: SM120 (Blackwell) support was added in PyTorch 2.7
    '';
    platforms = [ "x86_64-linux" ];
  };
})
