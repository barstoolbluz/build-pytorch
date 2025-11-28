# Wrapper that uses CUDA 13.0 packages from the included build-cudatoolkit environment
# and passes them to the PyTorch nightly build
#
# USAGE:
#   flox build pytorch-python313-cuda13_0-sm121-armv9-nightly-wrapper
#
# This expects the build-cudatoolkit environment to be included in manifest.toml,
# which provides access to cudatoolkit-13_0, cudnn-13_0, nccl-13_0, and libcusparse_lt-13_0

{ pkgs ? import <nixpkgs> {}
, cudatoolkit-13_0 ? null
, cudnn-13_0 ? null
, nccl-13_0 ? null
, libcusparse_lt-13_0 ? null
}:

let
  # Check if CUDA packages were provided from included environment
  hasCuda = cudatoolkit-13_0 != null && cudnn-13_0 != null &&
            nccl-13_0 != null && libcusparse_lt-13_0 != null;
in

if !hasCuda then
  throw ''
    CUDA 13.0 packages not found!

    Make sure the build-cudatoolkit environment is included in manifest.toml:

    [include]
    environments = [
      { dir = "../build-cudatoolkit" }
    ]
  ''
else
  pkgs.callPackage ./pytorch-python313-cuda13_0-sm121-armv9-nightly.nix {
    inherit cudatoolkit-13_0 cudnn-13_0 nccl-13_0 libcusparse_lt-13_0;
  }
