# PyTorch optimized for NVIDIA Pascal (SM61: GTX 1070, 1080, 1080 Ti) + AVX
# Package name: pytorch-python313-cuda12_8-sm61-avx

{ python3Packages
, lib
, config
, cudaPackages
, addDriverRunpath
}:

let
  # GPU target: SM61 (Pascal consumer architecture - GTX 1070, 1080, 1080 Ti)
  gpuArchNum = "61";  # For CMAKE_CUDA_ARCHITECTURES (just the integer)
  gpuArchSM = "6.1";  # For TORCH_CUDA_ARCH_LIST (dot notation required for older archs)

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
    gpuTargets = [ gpuArchSM ];
  # 2. Customize build (CPU flags, metadata, etc.)
  }).overrideAttrs (oldAttrs: {
    pname = "pytorch-python313-cuda12_8-sm61-avx";

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

      # cuDNN 9.11+ dropped SM < 7.5 support — disable for SM61
      export USE_CUDNN=0
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
      echo "GPU Target: ${gpuArchSM} (Pascal: GTX 1070, 1080, 1080 Ti)"
      echo "CPU Features: AVX (maximum compatibility)"
      echo "CUDA: Enabled (cudaSupport=true, gpuTargets=[${gpuArchSM}])"
      echo "CXXFLAGS: $CXXFLAGS"
      echo "========================================="
    '';

    postInstall = (oldAttrs.postInstall or "") + ''
      echo 1 > $out/.metadata-rev
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch for NVIDIA GTX 1070/1080 Ti (SM61, Pascal) with AVX";
      longDescription = ''
        Custom PyTorch build with targeted optimizations:
        - GPU: NVIDIA Pascal consumer architecture (SM61) - GTX 1070, 1080, 1080 Ti
        - CPU: x86-64 with AVX instruction set (maximum compatibility)
        - CUDA: 12.8 with compute capability 6.1
        - BLAS: cuBLAS for GPU operations
        - Python: 3.13

        Hardware requirements:
        - GPU: GTX 1070, 1080, 1080 Ti, or other SM61 GPUs
        - CPU: Intel Sandy Bridge+ (2011+), AMD Bulldozer+ (2011+)
        - Driver: NVIDIA 390+ required

        Note: cuDNN 9.11+ dropped support for SM < 7.5. If cuDNN operations
        fail at runtime, this is a known upstream limitation for Pascal GPUs.

        Choose this if: You have a GTX 1070, 1080, or 1080 Ti and want CUDA
        acceleration with broad CPU compatibility using AVX.
      '';
      platforms = [ "x86_64-linux" ];
    };
  })
