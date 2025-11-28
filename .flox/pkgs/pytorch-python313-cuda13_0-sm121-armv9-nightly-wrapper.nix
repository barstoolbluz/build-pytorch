# Wrapper that uses CUDA 13.0 from nixpkgs (available via --stability=unstable)
# and passes it to the PyTorch nightly build
#
# USAGE:
#   flox build --stability=unstable pytorch-python313-cuda13_0-sm121-armv9-nightly-wrapper
#
# Note: Requires --stability=unstable to get nixpkgs with cudaPackages_13 support

{ pkgs ? import <nixpkgs> {}
, cudaPackages_13
}:

# Import directly instead of using callPackage to avoid auto-injection of cudaPackages from pkgs
import ./pytorch-python313-cuda13_0-sm121-armv9-nightly.nix {
  inherit (pkgs) python3 lib fetchFromGitHub config addDriverRunpath;
  cudaPackages = cudaPackages_13;  # Explicitly use CUDA 13.0
}
