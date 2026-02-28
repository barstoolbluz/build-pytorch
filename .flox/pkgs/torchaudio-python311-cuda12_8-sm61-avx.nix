# Torchaudio for NVIDIA Pascal (SM61: GTX 1070, 1080, 1080 Ti) + AVX
# Package name: torchaudio-python311-cuda12_8-sm61-avx

{ pkgs ? import <nixpkgs> {} }:
let
  nixpkgs_pinned = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/fe5e41d7ffc0421f0913e8472ce6238ed0daf8e3.tar.gz";
  }) {
    config = { allowUnfree = true; cudaSupport = true; };
    overlays = [ (final: prev: { cudaPackages = final.cudaPackages_12_8; }) ];
  };

  gpuArchSM = "6.1";

  # Import the matching PyTorch AVX-only build
  customPytorch = import ./pytorch-python311-cuda12_8-sm61-avx.nix {};

  cpuFlags = [
    "-mavx"
    "-mno-fma"
    "-mno-bmi"
    "-mno-bmi2"
    "-mno-avx2"
  ];

in
  (nixpkgs_pinned.python311Packages.torchaudio.override {
    torch = customPytorch;
  }).overrideAttrs (oldAttrs: {
    pname = "torchaudio-python311-cuda12_8-sm61-avx";
    passthru = (oldAttrs.passthru or {}) // {
      gpuArch = gpuArchSM;
      cpuISA = "avx";
    };

    preConfigure = (oldAttrs.preConfigure or "") + ''
      export CXXFLAGS="${nixpkgs_pinned.lib.concatStringsSep " " cpuFlags} $CXXFLAGS"
      export CFLAGS="${nixpkgs_pinned.lib.concatStringsSep " " cpuFlags} $CFLAGS"

      # Override toolkit-wide arch list to target only our SM
      export TORCH_CUDA_ARCH_LIST="${gpuArchSM}"

      echo "========================================="
      echo "Torchaudio Build Configuration"
      echo "========================================="
      echo "GPU Target: ${gpuArchSM} (Pascal: GTX 1070, 1080, 1080 Ti)"
      echo "CPU Features: AVX (maximum compatibility)"
      echo "PyTorch: custom AVX-only build (sm61-avx)"
      echo "CXXFLAGS: $CXXFLAGS"
      echo "========================================="
    '';

    meta = oldAttrs.meta // {
      description = "Torchaudio for NVIDIA GTX 1070/1080 Ti (SM61, Pascal) with AVX";
      longDescription = ''
        Custom torchaudio build matching the pytorch-python311-cuda12_8-sm61-avx variant:
        - GPU: NVIDIA Pascal consumer architecture (SM61) - GTX 1070, 1080, 1080 Ti
        - CPU: x86-64 with AVX instruction set (maximum compatibility)
        - CUDA: 12.8 with compute capability 6.1
        - Python: 3.11

        This build imports and links against the corresponding PyTorch SM61-AVX recipe,
        ensuring ABI compatibility. C++ extensions are compiled with AVX-only flags to
        avoid illegal instructions on Sandy Bridge/Ivy Bridge CPUs.
      '';
      platforms = [ "x86_64-linux" ];
    };
  })
