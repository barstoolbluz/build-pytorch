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

# Import and rebuild torch from source with CUDA 13.0
import ./pytorch-python313-cuda13_0-sm121-armv9-nightly.nix {
  inherit (pkgs) python3 lib fetchFromGitHub config addDriverRunpath callPackage;
  # Pass CUDA 13.0 package set to rebuild torch from source
  cudaPackages_13 = cudaPackages_13;
}
