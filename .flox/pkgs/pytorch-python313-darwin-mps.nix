# PyTorch with MPS (Metal Performance Shaders) for Apple Silicon
# Package name: pytorch-python313-darwin-mps
#
# macOS build for Apple Silicon (M1/M2/M3/M4) with Metal GPU acceleration
# Hardware: Apple M1, M2, M3, M4 and variants (Pro, Max, Ultra)
# Requires: macOS 12.3+
#
# Note: Frameworks (Metal, Accelerate, etc.) are provided automatically by
# apple-sdk_13 via $SDKROOT — no individual framework packages needed.

{ python3Packages
, lib
}:

python3Packages.pytorch.overrideAttrs (oldAttrs: {
  pname = "pytorch-python313-darwin-mps";

  passthru = oldAttrs.passthru // {
    gpuArch = "mps";
    blasProvider = "veclib";
  };

  # Filter out CUDA deps (base pytorch may include them)
  buildInputs = lib.filter (p: !(lib.hasPrefix "cuda" (p.pname or "")))
    (oldAttrs.buildInputs or []);

  nativeBuildInputs = lib.filter (p: p.pname or "" != "addDriverRunpath")
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

  postInstall = (oldAttrs.postInstall or "") + ''
    echo 1 > $out/.metadata-rev
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
