# PyTorch 2.10.0 CPU-only for Intel Mac
# Package name: pytorch-python313-darwin-x86
#
# macOS build for Intel-based Macs (x86_64)
# Hardware: Intel Core i5/i7/i9, Xeon Mac Pro

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

  darwinFrameworks = with nixpkgs_pinned.darwin.apple_sdk.frameworks; [
    Accelerate
  ];

  cpuFlags = [ "-mavx2" "-mfma" "-mf16c" ];

in
  (nixpkgs_pinned.python3Packages.torch.override {
    cudaSupport = false;
  }).overrideAttrs (oldAttrs: {
    pname = "pytorch-python313-darwin-x86";
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
      export USE_MPS=0
      export BLAS=Accelerate
      export USE_MKLDNN=1
      export PYTORCH_BUILD_VERSION=2.10.0
      echo "2.10.0" > version.txt

      export CXXFLAGS="${nixpkgs_pinned.lib.concatStringsSep " " cpuFlags} $CXXFLAGS"
      export CFLAGS="${nixpkgs_pinned.lib.concatStringsSep " " cpuFlags} $CFLAGS"

      echo "CPU-only build | Platform: Intel Mac | CPU: AVX2 | PyTorch: 2.10.0"
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch 2.10.0 CPU-only for Intel Mac";
      longDescription = ''
        Custom PyTorch build for Intel Mac:
        - GPU: None (CPU-only)
        - Platform: Intel Mac (x86_64-darwin)
        - CPU: AVX2 instruction set
        - BLAS: Apple Accelerate framework
        - Python: 3.13
        - PyTorch: 2.10.0

        Note: Intel Macs do not support MPS. Use this CPU-only variant.
      '';
      platforms = [ "x86_64-darwin" ];
    };
  })
