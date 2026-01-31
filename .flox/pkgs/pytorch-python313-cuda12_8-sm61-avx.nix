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

  # CPU optimization: AVX (maximum compatibility)
  cpuFlags = [
    "-mavx"        # AVX instructions
    "-mfma"        # Fused multiply-add
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

    # Set CPU optimization flags
    # GPU architecture is handled by nixpkgs via gpuTargets parameter
    preConfigure = (oldAttrs.preConfigure or "") + ''
      # CPU optimizations via compiler flags
      export CXXFLAGS="$CXXFLAGS ${lib.concatStringsSep " " cpuFlags}"
      export CFLAGS="$CFLAGS ${lib.concatStringsSep " " cpuFlags}"

      echo "========================================="
      echo "PyTorch Build Configuration"
      echo "========================================="
      echo "GPU Target: ${gpuArchSM} (Pascal: GTX 1070, 1080, 1080 Ti)"
      echo "CPU Features: AVX (maximum compatibility)"
      echo "CUDA: Enabled (cudaSupport=true, gpuTargets=[${gpuArchSM}])"
      echo "CXXFLAGS: $CXXFLAGS"
      echo "========================================="
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
