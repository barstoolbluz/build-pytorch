# PyTorch 2.10.0 with MPS (Metal Performance Shaders) for Apple Silicon
# Package name: pytorch-python313-darwin-mps
#
# macOS build for Apple Silicon (M1/M2/M3/M4) with Metal GPU acceleration
# Hardware: Apple M1, M2, M3, M4 and variants (Pro, Max, Ultra)
# Requires: macOS 12.3+

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

  darwinFrameworks = with nixpkgs_pinned.darwin.apple_sdk_14_0.frameworks; [
    Accelerate
    Metal
    MetalPerformanceShaders
    MetalPerformanceShadersGraph
    CoreML
  ];

in
  (nixpkgs_pinned.python3Packages.torch.override {
    cudaSupport = false;
  }).overrideAttrs (oldAttrs: {
    pname = "pytorch-python313-darwin-mps";
    patches = [];

    buildInputs = nixpkgs_pinned.lib.filter (p: !(nixpkgs_pinned.lib.hasPrefix "cuda" (p.pname or "")))
      (oldAttrs.buildInputs or []) ++ darwinFrameworks;

    nativeBuildInputs = nixpkgs_pinned.lib.filter (p: p.pname or "" != "addDriverRunpath")
      (oldAttrs.nativeBuildInputs or []);

    cmakeFlags = (oldAttrs.cmakeFlags or []) ++ [
      "-DTORCH_BUILD_VERSION=2.10.0"
      "-DUSE_CUDA=OFF"
    ];

    preConfigure = (oldAttrs.preConfigure or "") + ''
      export USE_CUDA=0
      export USE_CUDNN=0
      export USE_CUBLAS=0
      export USE_MPS=1
      export USE_METAL=1
      export BLAS=Accelerate
      export PYTORCH_BUILD_VERSION=2.10.0
      echo "2.10.0" > version.txt

      echo "MPS build | Platform: Apple Silicon | PyTorch: 2.10.0"
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch 2.10.0 with MPS GPU acceleration for Apple Silicon";
      longDescription = ''
        Custom PyTorch build with targeted optimizations:
        - GPU: Metal Performance Shaders (MPS) for Apple Silicon
        - Platform: macOS 12.3+ on M1/M2/M3/M4
        - BLAS: Apple Accelerate framework
        - Python: 3.13
        - PyTorch: 2.10.0
      '';
      platforms = [ "aarch64-darwin" ];
    };
  })
