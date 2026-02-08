# PyTorch with MPS (Metal Performance Shaders) for Apple Silicon
# Package name: pytorch-python313-darwin-mps
#
# macOS build for Apple Silicon (M1/M2/M3/M4) with Metal GPU acceleration
# Hardware: Apple M1, M2, M3, M4 and variants (Pro, Max, Ultra)
# Requires: macOS 12.3+

{ pkgs ? import <nixpkgs> {} }:

let
  # Import nixpkgs at a specific revision (pinned for version consistency)
  nixpkgs_pinned = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/6a030d535719c5190187c4cec156f335e95e3211.tar.gz";
  }) {
    config = {
      allowUnfree = true;
    };
  };

in nixpkgs_pinned.python3Packages.torch.overrideAttrs (oldAttrs: {
  pname = "pytorch-python313-darwin-mps";

  # Limit build parallelism to prevent memory saturation
  ninjaFlags = [ "-j32" ];
  requiredSystemFeatures = [ "big-parallel" ];

  passthru = oldAttrs.passthru // {
    gpuArch = "mps";
    blasProvider = "veclib";
  };

  # Filter out CUDA deps (base pytorch may include them)
  buildInputs = nixpkgs_pinned.lib.filter (p: !(nixpkgs_pinned.lib.hasPrefix "cuda" (p.pname or "")))
    (oldAttrs.buildInputs or []);

  nativeBuildInputs = nixpkgs_pinned.lib.filter (p: p.pname or "" != "addDriverRunpath")
    (oldAttrs.nativeBuildInputs or []);

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

    echo "========================================="
    echo "PyTorch Build Configuration"
    echo "========================================="
    echo "GPU Target: MPS (Metal Performance Shaders)"
    echo "Platform: Apple Silicon (aarch64-darwin)"
    echo "BLAS Backend: vecLib (Apple Accelerate)"
    echo "========================================="
  '';

  meta = oldAttrs.meta // {
    description = "PyTorch with MPS GPU acceleration for Apple Silicon";
    longDescription = ''
      Custom PyTorch build with targeted optimizations:
      - GPU: Metal Performance Shaders (MPS) for Apple Silicon
      - Platform: macOS 12.3+ on M1/M2/M3/M4
      - BLAS: vecLib (Apple Accelerate framework)
      - Python: 3.13
    '';
    platforms = [ "aarch64-darwin" ];
  };
})
