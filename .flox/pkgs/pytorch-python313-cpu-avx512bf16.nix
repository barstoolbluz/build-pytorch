# PyTorch 2.10.0 for CPU-only + AVX-512 BF16
# Package name: pytorch210-python313-cpu-avx512bf16
#
# CPU-only build optimized for x86-64 systems with AVX-512 BF16 instruction set.
# No GPU/CUDA support - pure CPU inference and training with BF16 acceleration.

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

  cpuFlags = [ "-mavx512f" "-mavx512dq" "-mavx512vl" "-mavx512bw" "-mavx512bf16" "-mfma" ];

in
  (nixpkgs_pinned.python3Packages.torch.override {
    cudaSupport = false;
  }).overrideAttrs (oldAttrs: {
    pname = "pytorch210-python313-cpu-avx512bf16";
    patches = [];
    ninjaFlags = [ "-j32" ];
    requiredSystemFeatures = [ "big-parallel" ];

    cmakeFlags = (oldAttrs.cmakeFlags or []) ++ [
      "-DTORCH_BUILD_VERSION=2.10.0"
      "-DUSE_CUDA=OFF"
    ];

    preConfigure = (oldAttrs.preConfigure or "") + ''
      export CXXFLAGS="${nixpkgs_pinned.lib.concatStringsSep " " cpuFlags} $CXXFLAGS"
      export CFLAGS="${nixpkgs_pinned.lib.concatStringsSep " " cpuFlags} $CFLAGS"
      export MAX_JOBS=32
      export PYTORCH_BUILD_VERSION=2.10.0
      echo "2.10.0" > version.txt

      echo "CPU-only build | CPU: AVX-512 BF16 | PyTorch: 2.10.0"
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch 2.10.0 CPU-only + AVX-512 BF16";
      longDescription = ''
        CPU-only PyTorch build with targeted optimizations:
        - CPU: x86-64 with AVX-512 BF16 instruction set
        - PyTorch: 2.10.0
        - Python: 3.13
        - No CUDA/GPU support

        Hardware requirements:
        - CPU: Intel Cooper Lake+ (2020+), AMD Zen 4+ (2022+)
      '';
      platforms = [ "x86_64-linux" ];
    };
  })
