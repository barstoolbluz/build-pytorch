# PyTorch CPU-only for Intel Mac
# Package name: pytorch-python313-cpu-darwin
#
# macOS build for Intel-based Macs (x86_64)
# Hardware: Intel Core i5/i7/i9, Xeon Mac Pro

{ python3Packages
, lib
, darwin
}:

let
  # Darwin frameworks for Accelerate BLAS
  darwinFrameworks = with darwin.apple_sdk.frameworks; [
    Accelerate
  ];

  # CPU optimization: AVX2 (standard for Intel Macs)
  cpuFlags = [
    "-mavx2"
    "-mfma"
    "-mf16c"
  ];

in python3Packages.pytorch.overrideAttrs (oldAttrs: {
  pname = "pytorch-python313-cpu-darwin";

  passthru = oldAttrs.passthru // {
    gpuArch = null;
    blasProvider = "accelerate";
  };

  buildInputs = lib.filter (p: !(lib.hasPrefix "cuda" (p.pname or "")))
    (oldAttrs.buildInputs or []) ++ darwinFrameworks;

  nativeBuildInputs = lib.filter (p: p.pname or "" != "addDriverRunpath")
    (oldAttrs.nativeBuildInputs or []);

  preConfigure = (oldAttrs.preConfigure or "") + ''
    export USE_CUDA=0
    export USE_CUDNN=0
    export USE_CUBLAS=0
    export USE_MPS=0
    export BLAS=Accelerate
    export USE_MKLDNN=1

    export CXXFLAGS="$CXXFLAGS ${lib.concatStringsSep " " cpuFlags}"
    export CFLAGS="$CFLAGS ${lib.concatStringsSep " " cpuFlags}"

    echo "========================================="
    echo "PyTorch Build Configuration"
    echo "========================================="
    echo "GPU Target: None (CPU-only build)"
    echo "Platform: Intel Mac (x86_64-darwin)"
    echo "CPU Features: AVX2"
    echo "BLAS Backend: Apple Accelerate"
    echo "========================================="
  '';

  meta = oldAttrs.meta // {
    description = "PyTorch CPU-only for Intel Mac";
    longDescription = ''
      Custom PyTorch build for Intel Mac:
      - GPU: None (CPU-only)
      - Platform: Intel Mac (x86_64-darwin)
      - CPU: AVX2 instruction set
      - BLAS: Apple Accelerate framework
      - Python: 3.13

      Note: Intel Macs do not support MPS. Use this CPU-only variant.
    '';
    platforms = [ "x86_64-darwin" ];
  };
})
