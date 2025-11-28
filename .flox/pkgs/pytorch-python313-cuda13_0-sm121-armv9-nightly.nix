# PyTorch NIGHTLY optimized for NVIDIA DGX Spark (SM121) + ARMv9 with CUDA 13.0
# Package name: pytorch-python313-cuda13_0-sm121-armv9-nightly
#
# WARNING: This is an experimental build using PyTorch nightly with CUDA 13.0
# SM121 support is not yet stable in PyTorch. Known issues:
# - Flash Attention may not work
# - Triton compilation errors possible
# - FP8 kernels may fall back to slower legacy versions
#
# REQUIRES: nixpkgs with cudaPackages_13 (use --stability=unstable)

{ python3
, lib
, fetchFromGitHub
, config
, cudaPackages  # CUDA 13.0 packages passed from wrapper
, addDriverRunpath
}:

let
  # GPU target: SM121 (DGX Spark - specialized datacenter)
  gpuArchNum = "121";  # For CMAKE_CUDA_ARCHITECTURES (just the integer)
  gpuArchSM = "sm_121";  # For TORCH_CUDA_ARCH_LIST (with sm_ prefix)

  # CPU optimization: ARMv9-A with SVE/SVE2
  cpuFlags = [
    "-march=armv9-a+sve+sve2"  # ARMv9 with Scalable Vector Extensions
  ];

in
  # Build torch from python3.pkgs scope with CUDA 13.0
  ((python3.pkgs.torch.override {
    cudaSupport = true;
    cudaPackages = cudaPackages;
    gpuTargets = [ gpuArchSM ];
  }).overrideAttrs (oldAttrs: let
    pytorchNightlySrc = fetchFromGitHub {
      owner = "pytorch";
      repo = "pytorch";
      # Use a specific nightly commit - UPDATE THIS to latest commit from:
      # https://github.com/pytorch/pytorch/commits/main
      # For now, using v2.9.0 tag as starting point
      rev = "v2.9.0";
      hash = "";  # Leave empty - Nix will tell you the correct hash on first build
      fetchSubmodules = true;
    };
  in {
    pname = "pytorch-python313-cuda13_0-sm121-armv9-nightly";
    version = "2.9.0-nightly";

    # Override source to use PyTorch nightly
    src = pytorchNightlySrc;

    # Patch CMake to recognize SM121 architecture
    postPatch = (oldAttrs.postPatch or "") + ''
      echo "========================================="
      echo "Patching CMake files to add SM121 support..."
      echo "========================================="

      # Find the select_compute_arch.cmake file
      CMAKE_FILE="cmake/Modules_CUDA_fix/upstream/FindCUDA/select_compute_arch.cmake"

      if [ -f "$CMAKE_FILE" ]; then
        # Add SM121 support after SM120
        # This adds the conditional block to handle SM121/sm_121
        sed -i '/elseif(arch_name STREQUAL "SM120" OR arch_name STREQUAL "sm_120")/,/set(arch_ptx "120")/{
          /set(arch_ptx "120")/a\
  # DGX Spark (compute capability 12.1)\
  elseif(arch_name STREQUAL "SM121" OR arch_name STREQUAL "sm_121")\
    set(arch_bin "121")\
    set(arch_ptx "121")
        }' "$CMAKE_FILE"

        # Verify the patch was applied
        if grep -q "SM121" "$CMAKE_FILE"; then
          echo "✓ SM121 support added to $CMAKE_FILE"
        else
          echo "⚠ WARNING: SM121 patch may not have been applied correctly"
          echo "  Manual verification needed"
        fi
      else
        echo "⚠ WARNING: Could not find $CMAKE_FILE"
        echo "  Available cmake files:"
        find cmake -name "*.cmake" -path "*/CUDA/*" | head -10
      fi

      echo "========================================="
    '';

    # Set CPU optimization flags
    # GPU architecture and CUDA paths are handled by nixpkgs via cudaPackages parameter
    preConfigure = (oldAttrs.preConfigure or "") + ''
      # CPU optimizations via compiler flags
      export CXXFLAGS="$CXXFLAGS ${lib.concatStringsSep " " cpuFlags}"
      export CFLAGS="$CFLAGS ${lib.concatStringsSep " " cpuFlags}"

      echo "========================================="
      echo "PyTorch NIGHTLY Build Configuration"
      echo "========================================="
      echo "Version: 2.9.0-nightly"
      echo "GPU Target: ${gpuArchSM} (DGX Spark - Compute Capability 12.1)"
      echo "CPU Features: ARMv9 + SVE/SVE2"
      echo "CUDA: 13.0 (via cudaPackages, managed by nixpkgs)"
      echo "CXXFLAGS: $CXXFLAGS"
      echo "========================================="
      echo "⚠ WARNING: This is an experimental nightly build"
      echo "Known issues with SM121/CUDA 13.0:"
      echo "  - Flash Attention may not work"
      echo "  - Triton compilation errors possible (sm_121a)"
      echo "  - FP8 kernels may fall back to slower legacy versions"
      echo "========================================="
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch NIGHTLY for NVIDIA DGX Spark (SM121) + ARMv9 (SVE2) with CUDA 13.0";
      longDescription = ''
        EXPERIMENTAL PyTorch nightly build with targeted optimizations:
        - GPU: NVIDIA DGX Spark architecture (SM121, Compute Capability 12.1)
        - CPU: ARMv9-A with SVE/SVE2 (Scalable Vector Extensions)
        - CUDA: 13.0.88 (from custom build-cudatoolkit packages)
        - cuDNN: 9.13.0.50
        - NCCL: 2.28.7-1
        - cuBLAS: 13.1.0.3
        - BLAS: cuBLAS for GPU operations
        - Python: 3.13
        - Version: Nightly build from PyTorch main branch

        Hardware requirements:
        - GPU: NVIDIA DGX Spark (GB10) or other SM121 GPUs
        - CPU: NVIDIA Grace, ARM Neoverse V1/V2, Cortex-X2+, AWS Graviton3+
        - Driver: NVIDIA 570+ required
        - CUDA: 13.0.88+ required

        WARNING: This is an experimental build. Known issues:
        - Flash Attention compatibility issues with CUDA 13.0
        - Triton may have compilation errors with sm_121a GPU name
        - FP8 CUTLASS kernels may fall back to slower legacy kernels
        - General ecosystem is still in early development for CUDA 13.0

        CUDA 13.0 packages from: https://github.com/barstoolbluz/build-cudatoolkit/

        Choose this if: You have DGX Spark hardware and need cutting-edge
        PyTorch support for SM121. For production workloads, wait for
        official stable release with SM121 support.
      '';
      platforms = [ "aarch64-linux" ];
      broken = false;  # Experimental but attempt to build
    };
  }))
