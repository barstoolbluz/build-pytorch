# PyTorch 2.10.0 with MPS (Metal Performance Shaders) for Apple Silicon
# Package name: pytorch-python313-darwin-mps
#
# macOS build for Apple Silicon (M1/M2/M3/M4) with Metal GPU acceleration
# Hardware: Apple M1, M2, M3, M4 and variants (Pro, Max, Ultra)
# Requires: macOS 12.3+

{ pkgs ? import <nixpkgs> {} }:

let
  # Import nixpkgs at a specific revision (pinned for version consistency)
  # Overlay swaps torch source to 2.10.0 since nixpkgs only has 2.9.1
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

in
  (nixpkgs_pinned.python3Packages.torch.override {
    cudaSupport = false;
  }).overrideAttrs (oldAttrs: {
    pname = "pytorch-python313-darwin-mps";
    patches = [];

    ninjaFlags = [ "-j32" ];
    requiredSystemFeatures = [ "big-parallel" ];

    passthru = oldAttrs.passthru // {
      gpuArch = "mps";
      blasProvider = "veclib";
    };

    # Filter out CUDA deps
    buildInputs = nixpkgs_pinned.lib.filter (p: !(nixpkgs_pinned.lib.hasPrefix "cuda" (p.pname or "")))
      (oldAttrs.buildInputs or []);

    nativeBuildInputs = nixpkgs_pinned.lib.filter (p: p.pname or "" != "addDriverRunpath")
      (oldAttrs.nativeBuildInputs or []);

    cmakeFlags = (oldAttrs.cmakeFlags or []) ++ [
      "-DTORCH_BUILD_VERSION=2.10.0"
      "-DUSE_CUDA=OFF"
    ];

    preConfigure = (oldAttrs.preConfigure or "") + ''
      # Disable CUDA
      export USE_CUDA=0
      export USE_CUDNN=0
      export USE_CUBLAS=0

      # Enable MPS (Metal Performance Shaders)
      export USE_MPS=1
      export USE_METAL=1

      # Use vecLib (Apple Accelerate) for BLAS
      export BLAS=vecLib
      export MAX_JOBS=32

      # Version pinning
      export PYTORCH_BUILD_VERSION=2.10.0
      echo "2.10.0" > version.txt

      echo "========================================="
      echo "PyTorch Build Configuration"
      echo "========================================="
      echo "GPU Target: MPS (Metal Performance Shaders)"
      echo "Platform: Apple Silicon (aarch64-darwin)"
      echo "BLAS Backend: vecLib (Apple Accelerate)"
      echo "PyTorch: 2.10.0"
      echo "========================================="
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch 2.10.0 with MPS GPU acceleration for Apple Silicon";
      longDescription = ''
        Custom PyTorch build with targeted optimizations:
        - GPU: Metal Performance Shaders (MPS) for Apple Silicon
        - Platform: macOS 12.3+ on M1/M2/M3/M4
        - BLAS: vecLib (Apple Accelerate framework)
        - Python: 3.13
        - PyTorch: 2.10.0
      '';
      platforms = [ "aarch64-darwin" ];
    };
  })
