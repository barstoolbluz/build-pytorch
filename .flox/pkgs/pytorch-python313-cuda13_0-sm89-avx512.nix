# PyTorch 2.10.0 optimized for NVIDIA RTX 40 Ada (SM89) + AVX512
# Package name: pytorch210-python313-cuda13_0-sm89-avx512

{ pkgs ? import <nixpkgs> {} }:

let
  nixpkgs_pinned = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/6a030d535719c5190187c4cec156f335e95e3211.tar.gz";
  }) {
    config = {
      allowUnfree = true;
      allowBroken = true;
      cudaSupport = true;
    };
    overlays = [
      (final: prev: { cudaPackages = final.cudaPackages_13; })

      (final: prev: {
        magma = prev.magma.overrideAttrs (oldAttrs: {
          patches = (oldAttrs.patches or []) ++ [
            (final.fetchpatch {
              name = "cuda-13.0-clockrate-fix.patch";
              url = "https://github.com/icl-utk-edu/magma/commit/235aefb7b064954fce09d035c69907ba8a87cbcd.patch";
              hash = "sha256-i9InbxD5HtfonB/GyF9nQhFmok3jZ73RxGcIciGBGvU=";
            })
          ];
        });
      })

      (final: prev: {
        python3Packages = prev.python3Packages.override {
          overrides = pfinal: pprev: {
            torch = pprev.torch.overrideAttrs (oldAttrs: rec {
              version = "2.10.0";
              src = prev.fetchFromGitHub {
                owner = "pytorch";
                repo = "pytorch";
                rev = "v${version}";
                hash = "sha256-RKiZLHBCneMtZKRgTEuW1K7+Jpi+tx11BMXuS1jC1xQ=";
                fetchSubmodules = true;
              };
              patches = [];
            });
          };
        };
      })
    ];
  };

  gpuArchSM = "8.9";
  cpuFlags = [ "-mavx512f" "-mavx512dq" "-mavx512vl" "-mavx512bw" "-mfma" ];

in
  (nixpkgs_pinned.python3Packages.torch.override {
    cudaSupport = true;
    gpuTargets = [ gpuArchSM ];
  }).overrideAttrs (oldAttrs: {
    pname = "pytorch210-python313-cuda13_0-sm89-avx512";
    patches = [];
    ninjaFlags = [ "-j32" ];
    requiredSystemFeatures = [ "big-parallel" ];

    cmakeFlags = (oldAttrs.cmakeFlags or []) ++ [
      "-DTORCH_BUILD_VERSION=2.10.0"
      "-DCMAKE_CUDA_FLAGS=-I/build/cccl-compat"
      "-DCUDA_VERSION=13.0"
    ];

    preConfigure = (oldAttrs.preConfigure or "") + ''
      export CXXFLAGS="${nixpkgs_pinned.lib.concatStringsSep " " cpuFlags} $CXXFLAGS"
      export CFLAGS="${nixpkgs_pinned.lib.concatStringsSep " " cpuFlags} $CFLAGS"
      export MAX_JOBS=32
      export PYTORCH_BUILD_VERSION=2.10.0
      echo "2.10.0" > version.txt

      mkdir -p /build/cccl-compat/cccl
      ln -sf ${nixpkgs_pinned.cudaPackages.cuda_cccl}/include/cuda /build/cccl-compat/cccl/cuda
      ln -sf ${nixpkgs_pinned.cudaPackages.cuda_cccl}/include/cub /build/cccl-compat/cccl/cub
      ln -sf ${nixpkgs_pinned.cudaPackages.cuda_cccl}/include/thrust /build/cccl-compat/cccl/thrust
      ln -sf ${nixpkgs_pinned.cudaPackages.cuda_cccl}/include/nv /build/cccl-compat/cccl/nv
      export CXXFLAGS="-I/build/cccl-compat $CXXFLAGS"
      export CFLAGS="-I/build/cccl-compat $CFLAGS"
      export CUDAFLAGS="-I/build/cccl-compat $CUDAFLAGS"

      echo "GPU: SM89 (RTX 40 Ada) | CPU: AVX512 | PyTorch 2.10.0 | CUDA 13.0"
    '';

    postPatch = (oldAttrs.postPatch or "") + ''
      mkdir -p cmake/Modules
      cat > cmake/Modules/FindCUDAToolkit.cmake << 'EOF'
if(NOT CUDAToolkit_FOUND)
  set(_orig_module_path "''${CMAKE_MODULE_PATH}")
  list(FILTER CMAKE_MODULE_PATH EXCLUDE REGEX "cmake/Modules")
  include(FindCUDAToolkit)
  set(CMAKE_MODULE_PATH "''${_orig_module_path}")
endif()
EOF
    '';

    postInstall = (oldAttrs.postInstall or "") + ''
      echo 1 > $out/.metadata-rev
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch 2.10.0 for NVIDIA RTX 40 Ada (SM89) + AVX512";
      platforms = [ "x86_64-linux" ];
    };
  })
