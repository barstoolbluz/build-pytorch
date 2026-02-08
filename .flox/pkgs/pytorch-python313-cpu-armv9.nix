# PyTorch 2.10.0 for CPU-only + ARMv9
# Package name: pytorch210-python313-cpu-armv9
#
# CPU-only build optimized for ARM systems with ARMv9 instruction set.
# No GPU/CUDA support - pure CPU inference and training.

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

  cpuFlags = [ "-march=armv9-a+sve+sve2" ];

in
  (nixpkgs_pinned.python3Packages.torch.override {
    cudaSupport = false;
  }).overrideAttrs (oldAttrs: {
    pname = "pytorch210-python313-cpu-armv9";
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

      echo "CPU-only build | CPU: ARMv9 | PyTorch: 2.10.0"
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch 2.10.0 CPU-only + ARMv9";
      longDescription = ''
        CPU-only PyTorch build with targeted optimizations:
        - CPU: ARM with ARMv9 instruction set (SVE, SVE2)
        - PyTorch: 2.10.0
        - Python: 3.13
        - No CUDA/GPU support

        Hardware requirements:
        - CPU: NVIDIA Grace, ARM Neoverse V1/V2, Cortex-X2+, AWS Graviton3+
      '';
      platforms = [ "aarch64-linux" ];
    };
  })
