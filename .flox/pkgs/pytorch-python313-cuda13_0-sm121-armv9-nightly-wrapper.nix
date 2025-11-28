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

# Import and pass the full CUDA 13.0 package set for manual configuration
import ./pytorch-python313-cuda13_0-sm121-armv9-nightly.nix {
  inherit (pkgs) python3Packages lib fetchFromGitHub config cudaPackages addDriverRunpath;
  # Pass entire cudaPackages_13 set for complete CUDA 13.0 libraries
  cudaPackages_13 = cudaPackages_13;
}
