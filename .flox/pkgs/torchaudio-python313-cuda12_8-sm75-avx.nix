# Torchaudio for NVIDIA Turing (SM75: T4, RTX 2080 Ti, Quadro RTX 8000) + AVX
# Package name: torchaudio-python313-cuda12_8-sm75-avx

{ python3Packages
, lib
, config
, cudaPackages
, addDriverRunpath
}:

let
  gpuArchSM = "7.5";

  # Import the matching PyTorch AVX-only build
  customPytorch = import ./pytorch-python313-cuda12_8-sm75-avx.nix {
    inherit python3Packages lib config cudaPackages addDriverRunpath;
  };

  cpuFlags = [
    "-mavx"
    "-mno-fma"
    "-mno-bmi"
    "-mno-bmi2"
    "-mno-avx2"
  ];

in
  (python3Packages.torchaudio.override {
    torch = customPytorch;
  }).overrideAttrs (oldAttrs: {
    pname = "torchaudio-python313-cuda12_8-sm75-avx";
    passthru = (oldAttrs.passthru or {}) // {
      gpuArch = gpuArchSM;
      cpuISA = "avx";
    };

    preConfigure = (oldAttrs.preConfigure or "") + ''
      export CXXFLAGS="${lib.concatStringsSep " " cpuFlags} $CXXFLAGS"
      export CFLAGS="${lib.concatStringsSep " " cpuFlags} $CFLAGS"

      # Override toolkit-wide arch list to target only our SM
      export TORCH_CUDA_ARCH_LIST="${gpuArchSM}"

      echo "========================================="
      echo "Torchaudio Build Configuration"
      echo "========================================="
      echo "GPU Target: ${gpuArchSM} (Turing: T4, RTX 2080 Ti, Quadro RTX 8000)"
      echo "CPU Features: AVX (maximum compatibility)"
      echo "PyTorch: custom AVX-only build (sm75-avx)"
      echo "CXXFLAGS: $CXXFLAGS"
      echo "========================================="
    '';

    meta = oldAttrs.meta // {
      description = "Torchaudio for NVIDIA T4/RTX 2080 Ti (SM75, Turing) with AVX";
      longDescription = ''
        Custom torchaudio build matching the pytorch-python313-cuda12_8-sm75-avx variant:
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
