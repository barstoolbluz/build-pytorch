# PyTorch optimized for NVIDIA Ada Lovelace (SM89: RTX 4090, L4, L40) + AVX
# Package name: pytorch-python313-cuda12_9-sm89-avx

{ pkgs ? import <nixpkgs> {} }:

let
  # Import nixpkgs at a specific revision with CUDA 12.9
  nixpkgs_pinned = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/0182a361324364ae3f436a63005877674cf45efb.tar.gz";
  }) {
    config = {
      allowUnfree = true;
      cudaSupport = true;
    };
    overlays = [
      (final: prev: { cudaPackages = final.cudaPackages_12_9; })
    ];
  };

  # GPU target: SM89 (Ada Lovelace architecture - RTX 4090, L4, L40)
  gpuArchNum = "89";  # For CMAKE_CUDA_ARCHITECTURES (just the integer)
  gpuArchSM = "8.9";  # For TORCH_CUDA_ARCH_LIST (dot notation)

  # CPU optimization: AVX only (Ivy Bridge lacks FMA3, BMI1, BMI2, AVX2)
  cpuFlags = [
    "-mavx"
    "-mno-fma"
    "-mno-bmi"
    "-mno-bmi2"
    "-mno-avx2"
  ];

in
  # Two-stage override:
  # 1. Enable CUDA and specify GPU targets
  (nixpkgs_pinned.python313Packages.torch.override {
    cudaSupport = true;
    gpuTargets = [ gpuArchSM ];
  # 2. Customize build (CPU flags, metadata, etc.)
  }).overrideAttrs (oldAttrs: {
    pname = "pytorch-python313-cuda12_9-sm89-avx";
    passthru = oldAttrs.passthru // {
      gpuArch = gpuArchSM;
      blasProvider = "cublas";
      cpuISA = "avx";
    };

    # Limit build parallelism to prevent memory saturation
    ninjaFlags = [ "-j32" ];
    requiredSystemFeatures = [ "big-parallel" ];

    # Prevent ATen from compiling AVX2/AVX512 dispatch kernels.
    cmakeFlags = (oldAttrs.cmakeFlags or []) ++ [
      "-DCXX_AVX2_FOUND=FALSE"
      "-DC_AVX2_FOUND=FALSE"
      "-DCXX_AVX512_FOUND=FALSE"
      "-DC_AVX512_FOUND=FALSE"
      "-DCAFFE2_COMPILER_SUPPORTS_AVX512_EXTENSIONS=OFF"
      "-DUSE_NNPACK=OFF"
    ];

    preConfigure = (oldAttrs.preConfigure or "") + ''
      export CXXFLAGS="${nixpkgs_pinned.lib.concatStringsSep " " cpuFlags} $CXXFLAGS"
      export CFLAGS="${nixpkgs_pinned.lib.concatStringsSep " " cpuFlags} $CFLAGS"
      export MAX_JOBS=32

      # FBGEMM hard-requires AVX2 with no fallback — disable entirely
      export USE_FBGEMM=0
      # oneDNN/MKLDNN compiles AVX2/AVX512 dispatch variants internally
      export USE_MKLDNN=0
      export USE_MKLDNN_CBLAS=0
      # NNPACK requires AVX2+FMA3 — disable entirely for AVX-only builds
      export USE_NNPACK=0

      echo "========================================="
      echo "PyTorch Build Configuration"
      echo "========================================="
      echo "GPU Target: ${gpuArchSM} (Ada Lovelace: RTX 4090, L4, L40)"
      echo "CPU Features: AVX (maximum compatibility)"
      echo "CUDA: 12.9 (pinned nixpkgs)"
      echo "========================================="
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch for NVIDIA RTX 4090/L4/L40 (SM89, Ada) with AVX";
      longDescription = ''
        Custom PyTorch build with targeted optimizations:
        - GPU: NVIDIA Ada Lovelace architecture (SM89) - RTX 4090, L4, L40
        - CPU: x86-64 with AVX instruction set (maximum compatibility)
        - CUDA: 12.9 with compute capability 8.9
        - BLAS: cuBLAS for GPU operations
        - Python: 3.13

        Hardware requirements:
        - GPU: RTX 4090, L4, L40, or other SM89 GPUs
        - CPU: Intel Sandy Bridge+ (2011+), AMD Bulldozer+ (2011+)
        - Driver: NVIDIA 520+ required

        Choose this if: You have an Ada Lovelace GPU and want CUDA
        acceleration with broad CPU compatibility using AVX.

        vLLM compatibility: Pin-compatible with build-vllm/main (vLLM 0.15.1,
        CUDA 12.9, nixpkgs 0182a36) for SM-specific torch substitution.
      '';
      platforms = [ "x86_64-linux" ];
    };
  })
