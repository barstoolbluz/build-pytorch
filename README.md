# PyTorch Builds — CUDA 13.0 Branch (SM110 + SM121)

This branch contains PyTorch build recipes that require **CUDA 13.0+**, which is needed for SM110 (Blackwell Thor/DRIVE) and SM121 (DGX Spark) GPU architectures.

## Why a Separate Branch?

SM110 (`sm_110`) and SM121 (`sm_121`) are not recognized by `nvcc` in CUDA 12.8 (the default in nixpkgs on `main`). CUDA 13.0 adds support for these architectures. Since the PyTorch override pattern binds `cudaPackages` from the nixpkgs scope, the only way to use CUDA 13.0 is to pin nixpkgs to a revision that defaults to CUDA 13.0.

## Recipes

### SM110 — Blackwell Thor/DRIVE (2 variants, ARM-only)

| Package Name | CPU ISA | Platform |
|---|---|---|
| `pytorch-python313-cuda13_0-sm110-armv8_2` | ARMv8.2-A | aarch64-linux |
| `pytorch-python313-cuda13_0-sm110-armv9` | ARMv9-A | aarch64-linux |

### SM121 — DGX Spark (1 nightly variant)

| Package Name | CPU ISA | Platform |
|---|---|---|
| `pytorch-python313-cuda13_0-sm121-armv9-nightly` | ARMv9-A | aarch64-linux |

SM121 uses a from-scratch build pattern (Pattern C) since it requires CMake patches for SM121 support.

## Setup

The nixpkgs pin in each SM110 `.nix` file must point to a nixpkgs commit where `cudaPackages` defaults to CUDA 13.0. Update the `url` in `builtins.fetchTarball` accordingly.

The SM121 nightly file references `cudaPackages_13` directly.

## Building

```bash
git checkout cuda-13_0
flox build pytorch-python313-cuda13_0-sm110-armv9
flox build pytorch-python313-cuda13_0-sm121-armv9-nightly
```

## Related Branches

- **`main`** — CUDA 12.8 recipes (SM61, SM80–SM100, SM120, CPU)
- **`cuda-12_9`** — CUDA 12.9 recipes (SM103)
