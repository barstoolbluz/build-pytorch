# PyTorch NIGHTLY built from scratch for SM121 + CUDA 13.0 + ARMv9
# This builds PyTorch completely from source without using nixpkgs' torch package
#
# USAGE:
#   flox build --stability=unstable pytorch-python313-cuda13_0-sm121-armv9-nightly
#
# Note: Requires --stability=unstable to get nixpkgs with cudaPackages_13 support

{ pkgs ? import <nixpkgs> {}
, cudaPackages_13
}:

let
  inherit (pkgs) python3 lib fetchFromGitHub cmake ninja git which pkg-config;
  inherit (pkgs.python3.pkgs) pybind11;

  python = python3;

  # Build MAGMA with CUDA 13.0 support only (disable ROCm for ARM compatibility)
  magma = pkgs.magma.override {
    cudaPackages = cudaPackages_13;
    cudaSupport = true;
    rocmSupport = false;  # ROCm not available on aarch64-linux
  };

  cudaPackages = cudaPackages_13 // {
    # Add alias for naming difference
    cusparselt = cudaPackages_13.libcusparse_lt;
  };

  # GPU target: SM121 only
  gpuArchSM = "sm_121";
  gpuArchNum = "121";

  # CPU optimizations
  cpuFlags = "-march=armv9-a+sve+sve2";

in python.pkgs.buildPythonPackage rec {
  pname = "pytorch-cuda13_0-sm121-armv9-nightly";
  version = "2.9.0-nightly";
  format = "setuptools";

  src = fetchFromGitHub {
    owner = "pytorch";
    repo = "pytorch";
    rev = "v2.9.0";
    hash = "";  # Will fail first time - update with correct hash
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    cmake
    ninja
    which
    pybind11
    pkg-config
    git
  ] ++ (with cudaPackages; [
    cuda_nvcc
  ]);

  buildInputs = [
    magma
  ] ++ (with cudaPackages; [
    cuda_cccl
    cuda_cudart
    cuda_cupti
    cuda_nvml_dev
    cuda_nvrtc
    cuda_nvtx
    cuda_profiler_api
    libcublas
    libcufft
    libcufile
    libcurand
    libcusolver
    libcusparse
    cusparselt
    cudnn
    nccl
  ]);

  propagatedBuildInputs = with python.pkgs; [
    astunparse
    filelock
    fsspec
    jinja2
    networkx
    packaging
    pyyaml
    requests
    sympy
    typing-extensions
    pillow
  ];

  dontUseCmakeConfigure = true;

  # Patch CMake to add SM121 support
  postPatch = ''
    echo "========================================="
    echo "Patching CMake for SM121 support"
    echo "========================================="

    CMAKE_FILE="cmake/Modules_CUDA_fix/upstream/FindCUDA/select_compute_arch.cmake"

    if [ -f "$CMAKE_FILE" ]; then
      sed -i '/elseif(arch_name STREQUAL "SM120" OR arch_name STREQUAL "sm_120")/,/set(arch_ptx "120")/{
        /set(arch_ptx "120")/a\
  # DGX Spark (compute capability 12.1)\
  elseif(arch_name STREQUAL "SM121" OR arch_name STREQUAL "sm_121")\
    set(arch_bin "121")\
    set(arch_ptx "121")
      }' "$CMAKE_FILE"

      if grep -q "SM121" "$CMAKE_FILE"; then
        echo "✓ SM121 support added"
      else
        echo "⚠ WARNING: SM121 patch may not have applied"
      fi
    else
      echo "⚠ WARNING: CMake file not found at expected location"
    fi
  '';

  preConfigure = ''
    export MAX_JOBS=$NIX_BUILD_CORES
    export USE_CUDA=1
    export USE_CUDNN=1
    export USE_NCCL=1
    export TORCH_CUDA_ARCH_LIST="${gpuArchSM}"
    export CUDA_HOME="${cudaPackages.cudatoolkit}"
    export CUDNN_INCLUDE_DIR="${lib.getDev cudaPackages.cudnn}/include"
    export CUDNN_LIB_DIR="${lib.getLib cudaPackages.cudnn}/lib"
    export NCCL_ROOT="${cudaPackages.nccl}"
    export CUPTI_INCLUDE_DIR="${lib.getDev cudaPackages.cuda_cupti}/include"
    export CUPTI_LIBRARY_DIR="${lib.getLib cudaPackages.cuda_cupti}/lib"

    # CPU optimizations
    export CXXFLAGS="$CXXFLAGS ${cpuFlags}"
    export CFLAGS="$CFLAGS ${cpuFlags}"

    echo "========================================="
    echo "PyTorch Build Configuration (from scratch)"
    echo "========================================="
    echo "Version: ${version}"
    echo "GPU: SM121 (DGX Spark)"
    echo "CPU: ARMv9 + SVE/SVE2"
    echo "CUDA: 13.0 (${cudaPackages.cudatoolkit})"
    echo "cuDNN: ${cudaPackages.cudnn}"
    echo "NCCL: ${cudaPackages.nccl}"
    echo "TORCH_CUDA_ARCH_LIST: $TORCH_CUDA_ARCH_LIST"
    echo "========================================="
  '';

  # Disable some tests that require GPU
  doCheck = false;

  meta = with lib; {
    description = "PyTorch NIGHTLY for DGX Spark (SM121) + CUDA 13.0 + ARMv9";
    homepage = "https://pytorch.org/";
    license = licenses.bsd3;
    platforms = [ "aarch64-linux" ];
  };
}
