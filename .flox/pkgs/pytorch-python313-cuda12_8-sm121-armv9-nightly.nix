# PyTorch NIGHTLY optimized for NVIDIA DGX Spark (SM121) + ARMv9
# Package name: pytorch-python313-cuda12_8-sm121-armv9-nightly
#
# WARNING: This is an experimental build using PyTorch nightly
# SM121 support is not yet stable in PyTorch. Known issues:
# - Flash Attention may not work
# - Triton compilation errors possible
# - FP8 kernels may fall back to slower legacy versions
#
# NOTE: Uses CUDA 12.8 until CUDA 13.0 is available in nixpkgs

{ python3Packages
, lib
, fetchFromGitHub
, config
, cudaPackages
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
  # Two-stage override (same pattern as working builds):
  # 1. Enable CUDA and specify GPU targets
  (python3Packages.pytorch.override {
    cudaSupport = true;
    gpuTargets = [ gpuArchSM ];
  # 2. Customize build (source, CPU flags, metadata, patches)
  }).overrideAttrs (oldAttrs: let
    pytorchNightlySrc = fetchFromGitHub {
      owner = "pytorch";
      repo = "pytorch";
      # Specific commit from main branch - REPLACE THIS with a recent commit
      # Find recent commits at: https://github.com/pytorch/pytorch/commits/main
      # Using v2.9.0 tag as starting point - update to latest nightly commit as needed
      rev = "v2.9.0";  # Use a tagged release or specific commit hash
      hash = "";  # Leave empty - Nix will tell you the correct hash on first build
      fetchSubmodules = true;
    };
  in {
    pname = "pytorch-python313-cuda12_8-sm121-armv9-nightly";
    version = "2.9.0-nightly";

    # Override source to use PyTorch nightly
    src = pytorchNightlySrc;

    # Patch CMake to recognize SM121 architecture via postPatch
    postPatch = (oldAttrs.postPatch or "") + ''
      echo "Patching CMake files to add SM121 support..."

      # Find the select_compute_arch.cmake file
      CMAKE_FILE="cmake/Modules_CUDA_fix/upstream/FindCUDA/select_compute_arch.cmake"

      if [ -f "$CMAKE_FILE" ]; then
        # Add SM121 support after SM120
        # Find the line with SM120 and add SM121 handling after the corresponding endif
        sed -i '/elseif(arch_name STREQUAL "SM120" OR arch_name STREQUAL "sm_120")/,/set(arch_ptx "120")/{
          /set(arch_ptx "120")/a\
  # DGX Spark (compute capability 12.1)\
  elseif(arch_name STREQUAL "SM121" OR arch_name STREQUAL "sm_121")\
    set(arch_bin "121")\
    set(arch_ptx "121")
        }' "$CMAKE_FILE"

        echo "✓ SM121 support added to $CMAKE_FILE"
      else
        echo "⚠ WARNING: Could not find $CMAKE_FILE"
        echo "  Available cmake files:"
        find cmake -name "*.cmake" | head -10
      fi
    '';

    # Set CPU optimization flags and add SM121 debugging
    preConfigure = (oldAttrs.preConfigure or "") + ''
      # CPU optimizations via compiler flags
      export CXXFLAGS="$CXXFLAGS ${lib.concatStringsSep " " cpuFlags}"
      export CFLAGS="$CFLAGS ${lib.concatStringsSep " " cpuFlags}"

      # Verify SM121 architecture is being used
      echo "========================================="
      echo "PyTorch NIGHTLY Build Configuration"
      echo "========================================="
      echo "Version: Nightly (based on ${oldAttrs.version or "unknown"})"
      echo "GPU Target: ${gpuArchSM} (DGX Spark - Compute Capability 12.1)"
      echo "CPU Features: ARMv9 + SVE/SVE2"
      echo "CUDA: 12.8 (cudaSupport=true, gpuTargets=[${gpuArchSM}])"
      echo "CXXFLAGS: $CXXFLAGS"
      echo "========================================="
      echo "WARNING: This is an experimental nightly build"
      echo "Known issues with SM121:"
      echo "  - Flash Attention may not work"
      echo "  - Triton compilation errors possible"
      echo "  - FP8 kernels may fall back to slower legacy versions"
      echo "  - CUDA 13.0 features not available (using CUDA 12.8)"
      echo "========================================="

      # Check if the patch was applied correctly
      if grep -q "SM121" cmake/Modules_CUDA_fix/upstream/FindCUDA/select_compute_arch.cmake 2>/dev/null; then
        echo "✓ SM121 patch successfully applied to CMake files"
      else
        echo "⚠ WARNING: SM121 patch may not have been applied correctly"
      fi
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch NIGHTLY for NVIDIA DGX Spark (SM121) + ARMv9 (SVE2)";
      longDescription = ''
        EXPERIMENTAL PyTorch nightly build with targeted optimizations:
        - GPU: NVIDIA DGX Spark architecture (SM121, Compute Capability 12.1)
        - CPU: ARMv9-A with SVE/SVE2 (Scalable Vector Extensions)
        - CUDA: 12.8 (13.0 not yet available in nixpkgs)
        - BLAS: cuBLAS for GPU operations
        - Python: 3.13
        - Version: Nightly build from main branch

        Hardware requirements:
        - GPU: NVIDIA DGX Spark (GB10) or other SM121 GPUs
        - CPU: NVIDIA Grace, ARM Neoverse V1/V2, Cortex-X2+, AWS Graviton3+
        - Driver: NVIDIA 570+ required

        WARNING: This is an experimental build. Known issues:
        - Flash Attention compatibility issues
        - Triton may have compilation errors with sm_121a
        - FP8 CUTLASS kernels may fall back to slower legacy kernels
        - Using CUDA 12.8 instead of required CUDA 13.0

        Choose this if: You have DGX Spark hardware and need cutting-edge
        PyTorch support for SM121. For production workloads, wait for
        official stable release with SM121 support.
      '';
      platforms = [ "aarch64-linux" ];
      broken = false;  # Experimental but attempt to build
    };
  })
