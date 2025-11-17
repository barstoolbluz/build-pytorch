# PyTorch optimized for NVIDIA Blackwell (SM120: RTX 5090) + AVX-512
# Package name: pytorch-python313-cuda12_8-sm120-avx512

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

  # CPU optimization: AVX-512
  cpuFlags = [
    "-mavx512f"    # AVX-512 Foundation
    "-mavx512dq"   # Doubleword and Quadword instructions
    "-mavx512vl"   # Vector Length extensions
    "-mavx512bw"   # Byte and Word instructions
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
    pname = "pytorch-python313-cuda12_8-sm120-avx512";

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
      echo "CPU Features: AVX-512"
      echo "CUDA: Enabled (cudaSupport=true, gpuTargets=[${gpuArchNum}])"
      echo "CXXFLAGS: $CXXFLAGS"
      echo "========================================="
    '';

  meta = oldAttrs.meta // {
    description = "PyTorch for NVIDIA RTX 5090 (SM120, Blackwell) + AVX-512";
    longDescription = ''
      Custom PyTorch build with targeted optimizations:
      - GPU: NVIDIA Blackwell architecture (SM120) - RTX 5090
      - CPU: x86-64 with AVX-512 instruction set
      - CUDA: 12.8 with compute capability 12.0
      - BLAS: cuBLAS for GPU operations
      - Python: 3.13

      Hardware requirements:
      - GPU: RTX 5090, Blackwell architecture GPUs
      - CPU: Intel Skylake-X+ (2017+), AMD Zen 4+ (2022+)
      - Driver: NVIDIA 570+ required

      ⚠️  IMPORTANT: SM120 (Blackwell) support was added in PyTorch 2.7

      Choose this if: You have RTX 5090 GPU + AVX-512 CPU for general
      workloads. For specialized CPU workloads, consider avx512bf16
      (BF16 training) or avx512vnni (INT8 inference) variants instead.
    '';
    platforms = [ "x86_64-linux" ];
  };
})
