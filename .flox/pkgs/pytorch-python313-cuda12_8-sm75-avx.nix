# PyTorch optimized for NVIDIA Turing (SM75: T4, RTX 2080 Ti) + AVX
# Package name: pytorch-python313-cuda12_8-sm75-avx

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
  (python3Packages.pytorch.override {
    cudaSupport = true;
    gpuTargets = [ gpuArchNum ];
  # 2. Customize build (CPU flags, metadata, etc.)
  }).overrideAttrs (oldAttrs: {
    pname = "pytorch-python313-cuda12_8-sm75-avx";
    passthru = oldAttrs.passthru // {
      gpuArch = gpuArchNum;
      blasProvider = "cublas";
      cpuISA = "avx";
    };

    # Prevent ATen from compiling AVX2/AVX512 dispatch kernels.
    # FindAVX.cmake probe-compiles with -mavx2 and succeeds (the compiler
    # supports it), then Codegen.cmake force-compiles kernel TUs with -mavx2
    # regardless of project CXXFLAGS.  Lying to cmake here restricts the
    # dispatch codegen to AVX + baseline only.
    cmakeFlags = (oldAttrs.cmakeFlags or []) ++ [
      "-DCXX_AVX2_FOUND=FALSE"
      "-DC_AVX2_FOUND=FALSE"
      "-DCXX_AVX512_FOUND=FALSE"
      "-DC_AVX512_FOUND=FALSE"
      "-DCAFFE2_COMPILER_SUPPORTS_AVX512_EXTENSIONS=OFF"
      # NNPACK requires AVX2+FMA3 — disable for AVX-only builds
      "-DUSE_NNPACK=OFF"
    ];

    preConfigure = (oldAttrs.preConfigure or "") + ''
      export CXXFLAGS="${lib.concatStringsSep " " cpuFlags} $CXXFLAGS"
      export CFLAGS="${lib.concatStringsSep " " cpuFlags} $CFLAGS"

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
      echo "GPU Target: ${gpuArchNum} (Turing: T4, RTX 2080 Ti, Quadro RTX 8000)"
      echo "CPU Features: AVX (maximum compatibility)"
      echo "CUDA: Enabled (cudaSupport=true, gpuTargets=[${gpuArchNum}])"
      echo "CXXFLAGS: $CXXFLAGS"
      echo "========================================="
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch for NVIDIA T4/RTX 2080 Ti (SM75, Turing) with AVX";
      longDescription = ''
        Custom PyTorch build with targeted optimizations:
        - GPU: NVIDIA Turing architecture (SM75) - T4, RTX 2080 Ti, Quadro RTX 8000
        - CPU: x86-64 with AVX instruction set (maximum compatibility)
        - CUDA: 12.8 with compute capability 7.5
        - BLAS: cuBLAS for GPU operations
        - Python: 3.13

        Hardware requirements:
        - GPU: T4, RTX 2080 Ti, RTX 2080 Super, Quadro RTX 8000, or other SM75 GPUs
        - CPU: Intel Sandy Bridge+ (2011+), AMD Bulldozer+ (2011+)
        - Driver: NVIDIA 418+ required

        Note: FBGEMM, MKLDNN, and NNPACK are disabled as they require AVX2+.

        Choose this if: You have a T4/RTX 2080 Ti-class GPU paired with an older
        CPU that lacks AVX2 (e.g., Sandy Bridge/Ivy Bridge Xeons in older servers).
      '';
      platforms = [ "x86_64-linux" ];
    };
  })
