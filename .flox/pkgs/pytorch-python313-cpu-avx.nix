# PyTorch 2.10.0 for CPU-only + AVX (maximum compatibility)
# Package name: pytorch210-python313-cpu-avx
#
# CPU-only build with maximum CPU compatibility.
# Targets Intel Sandy Bridge (2011+), AMD Bulldozer (2011+).
# No GPU/CUDA support - pure CPU inference and training.
#
# This variant explicitly disables AVX2, FMA, BMI, and related libraries
# that require newer instruction sets.

{ pkgs ? import <nixpkgs> {} }:

let
  nixpkgs_pinned = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/6a030d535719c5190187c4cec156f335e95e3211.tar.gz";
  }) {
    config = { allowUnfree = true; allowBroken = true; };
    overlays = [
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

  # AVX-only flags (explicitly disable AVX2, FMA, BMI)
  cpuFlags = [
    "-mavx"      # Enable AVX
    "-mno-fma"   # Disable FMA3 (requires Haswell+)
    "-mno-bmi"   # Disable BMI1 (requires Haswell+)
    "-mno-bmi2"  # Disable BMI2 (requires Haswell+)
    "-mno-avx2"  # Disable AVX2 (requires Haswell+)
  ];

in
  (nixpkgs_pinned.python3Packages.torch.override {
    cudaSupport = false;
  }).overrideAttrs (oldAttrs: {
    pname = "pytorch210-python313-cpu-avx";
    patches = [];
    ninjaFlags = [ "-j32" ];
    requiredSystemFeatures = [ "big-parallel" ];

    cmakeFlags = (oldAttrs.cmakeFlags or []) ++ [
      "-DTORCH_BUILD_VERSION=2.10.0"
      "-DUSE_CUDA=OFF"
      # Prevent ATen AVX2/AVX512 dispatch kernel compilation
      "-DCXX_AVX2_FOUND=FALSE"
      "-DC_AVX2_FOUND=FALSE"
      "-DCXX_AVX512_FOUND=FALSE"
      "-DC_AVX512_FOUND=FALSE"
      "-DCAFFE2_COMPILER_SUPPORTS_AVX512_EXTENSIONS=OFF"
      # NNPACK requires AVX2+FMA3
      "-DUSE_NNPACK=OFF"
    ];

    preConfigure = (oldAttrs.preConfigure or "") + ''
      export CXXFLAGS="${nixpkgs_pinned.lib.concatStringsSep " " cpuFlags} $CXXFLAGS"
      export CFLAGS="${nixpkgs_pinned.lib.concatStringsSep " " cpuFlags} $CFLAGS"
      export MAX_JOBS=32
      export PYTORCH_BUILD_VERSION=2.10.0
      echo "2.10.0" > version.txt

      # Disable libraries requiring AVX2+
      export USE_FBGEMM=0      # FBGEMM hard-requires AVX2 with no fallback
      export USE_MKLDNN=0      # oneDNN/MKLDNN compiles AVX2/AVX512 dispatch variants
      export USE_MKLDNN_CBLAS=0
      export USE_NNPACK=0      # NNPACK requires AVX2+FMA3

      echo "CPU-only build | CPU: AVX (max compat) | PyTorch: 2.10.0"
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch 2.10.0 CPU-only + AVX (maximum compatibility)";
      longDescription = ''
        CPU-only PyTorch build with maximum CPU compatibility:
        - CPU: x86-64 with AVX instruction set only
        - PyTorch: 2.10.0
        - Python: 3.13
        - No CUDA/GPU support

        Disabled components (require AVX2+):
        - FBGEMM (requires AVX2)
        - MKLDNN/oneDNN (AVX2/AVX512 dispatch)
        - NNPACK (requires AVX2+FMA3)
        - ATen AVX2/AVX512 dispatch kernels

        Hardware requirements:
        - CPU: Intel Sandy Bridge+ (2011+), AMD Bulldozer+ (2011+)
      '';
      platforms = [ "x86_64-linux" ];
    };
  })
