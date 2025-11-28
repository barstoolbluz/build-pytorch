# Wrapper that imports CUDA 13.0 packages from build-cudatoolkit repo
# and passes them to the PyTorch nightly build

{ pkgs ? import <nixpkgs> {} }:

let
  # Path to the build-cudatoolkit repo (adjust if needed)
  cudaToolkitRepo = ../../build-cudatoolkit;

  # Import CUDA 13.0 packages from the sibling repo
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
