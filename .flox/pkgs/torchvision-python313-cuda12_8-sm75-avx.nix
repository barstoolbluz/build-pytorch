# Torchvision for NVIDIA Turing (SM75: T4, RTX 2080 Ti, Quadro RTX 8000) + AVX
# Package name: torchvision-python313-cuda12_8-sm75-avx

{ pkgs ? import <nixpkgs> {} }:
let
  nixpkgs_pinned = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/fe5e41d7ffc0421f0913e8472ce6238ed0daf8e3.tar.gz";
  }) {
    config = { allowUnfree = true; cudaSupport = true; };
    overlays = [ (final: prev: { cudaPackages = final.cudaPackages_12_8; }) ];
  };

  gpuArchSM = "7.5";

  # Import the matching PyTorch AVX-only build
  customPytorch = import ./pytorch-python313-cuda12_8-sm75-avx.nix {};

  cpuFlags = [
    "-mavx"
    "-mno-fma"
    "-mno-bmi"
    "-mno-bmi2"
    "-mno-avx2"
  ];

in
  (nixpkgs_pinned.python313Packages.torchvision.override {
    torch = customPytorch;
  }).overrideAttrs (oldAttrs: {
    pname = "torchvision-python313-cuda12_8-sm75-avx";
    passthru = (oldAttrs.passthru or {}) // {
      gpuArch = gpuArchSM;
      cpuISA = "avx";
    };

    preConfigure = (oldAttrs.preConfigure or "") + ''
      export CXXFLAGS="${nixpkgs_pinned.lib.concatStringsSep " " cpuFlags} $CXXFLAGS"
      export CFLAGS="${nixpkgs_pinned.lib.concatStringsSep " " cpuFlags} $CFLAGS"

      # Override toolkit-wide arch list to target only our SM
      export TORCH_CUDA_ARCH_LIST="${gpuArchSM}"
      export FORCE_CUDA=1

      echo "========================================="
      echo "Torchvision Build Configuration"
      echo "========================================="
      echo "GPU Target: ${gpuArchSM} (Turing: T4, RTX 2080 Ti, Quadro RTX 8000)"
      echo "CPU Features: AVX (maximum compatibility)"
      echo "PyTorch: custom AVX-only build (sm75-avx)"
      echo "CXXFLAGS: $CXXFLAGS"
      echo "========================================="
    '';

    meta = oldAttrs.meta // {
      description = "Torchvision for NVIDIA T4/RTX 2080 Ti (SM75, Turing) with AVX";
      longDescription = ''
        Custom torchvision build matching the pytorch-python313-cuda12_8-sm75-avx variant:
        - GPU: NVIDIA Turing architecture (SM75) - T4, RTX 2080 Ti, Quadro RTX 8000
        - CPU: x86-64 with AVX instruction set (maximum compatibility)
        - CUDA: 12.8 with compute capability 7.5
        - Python: 3.13

        This build imports and links against the corresponding PyTorch SM75-AVX recipe,
        ensuring ABI compatibility. C++ extensions are compiled with AVX-only flags to
        avoid illegal instructions on Sandy Bridge/Ivy Bridge CPUs.
      '';
      platforms = [ "x86_64-linux" ];
    };
  })
