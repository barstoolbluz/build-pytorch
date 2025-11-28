# Wrapper that imports CUDA 13.0 packages from build-cudatoolkit repo
# and passes them to the PyTorch nightly build
#
# USAGE:
# Option 1 (Default): Auto-fetch from GitHub
#   flox build pytorch-python313-cuda13_0-sm121-armv9-nightly-wrapper
#   (Uses pinned commit from https://github.com/barstoolbluz/build-cudatoolkit)
#
# Option 2 (Override for local development): Use local repo
#   export CUDA_TOOLKIT_REPO=$(pwd)/../build-cudatoolkit
#   flox build pytorch-python313-cuda13_0-sm121-armv9-nightly-wrapper

{ pkgs ? import <nixpkgs> {} }:

let
  # Get optional override path from environment variable
  cudaToolkitRepoOverride = builtins.getEnv "CUDA_TOOLKIT_REPO";

  # Default: Fetch from GitHub with pinned commit (reproducible, works in pure mode)
  # Override: Use local path if CUDA_TOOLKIT_REPO is set
  cudaToolkitRepo =
    if cudaToolkitRepoOverride != "" then
      # Local development mode - use override path
      if builtins.substring 0 1 cudaToolkitRepoOverride == "/" then
        cudaToolkitRepoOverride
      else
        throw ''
          ERROR: CUDA_TOOLKIT_REPO must be an ABSOLUTE path!
          Got: ${cudaToolkitRepoOverride}
          Use: export CUDA_TOOLKIT_REPO=$(pwd)/../build-cudatoolkit
        ''
    else
      # Production mode - fetch from GitHub with pinned commit
      pkgs.fetchFromGitHub {
        owner = "barstoolbluz";
        repo = "build-cudatoolkit";
        rev = "main";  # TODO: Replace with specific commit hash for reproducibility
        hash = "";  # TODO: Fill in after first build - Nix will provide the correct hash
        # Example: hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
      };

  # Import CUDA 13.0 packages from the repo
  cudatoolkit-13_0 = pkgs.callPackage "${cudaToolkitRepo}/.flox/pkgs/cudatoolkit-13_0.nix" {};
  cudnn-13_0 = pkgs.callPackage "${cudaToolkitRepo}/.flox/pkgs/cudnn-13_0.nix" {};
  nccl-13_0 = pkgs.callPackage "${cudaToolkitRepo}/.flox/pkgs/nccl-13_0.nix" {};
  libcusparse_lt-13_0 = pkgs.callPackage "${cudaToolkitRepo}/.flox/pkgs/libcusparse_lt-13_0.nix" {};

  # Now call the PyTorch build with CUDA 13.0 packages
  pytorch = pkgs.callPackage ./pytorch-python313-cuda13_0-sm121-armv9-nightly.nix {
    inherit cudatoolkit-13_0 cudnn-13_0 nccl-13_0 libcusparse_lt-13_0;
  };

in
  pytorch
