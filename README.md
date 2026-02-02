# PyTorch Builds — CUDA 12.9 Branch (SM103)

This branch contains PyTorch build recipes that require **CUDA 12.9+**, which is needed for SM103 (Blackwell B300) GPU architecture.

## Why a Separate Branch?

SM103 (`sm_103`) is not recognized by `nvcc` in CUDA 12.8 (the default in nixpkgs on `main`). CUDA 12.9 adds SM103 support. Since the PyTorch override pattern binds `cudaPackages` from the nixpkgs scope, the only way to use CUDA 12.9 is to pin nixpkgs to a revision that defaults to CUDA 12.9.

## Recipes (6 variants)

| Package Name | CPU ISA | Platform |
|---|---|---|
| `pytorch-python313-cuda12_9-sm103-avx2` | AVX2 | x86_64-linux |
| `pytorch-python313-cuda12_9-sm103-avx512` | AVX-512 | x86_64-linux |
| `pytorch-python313-cuda12_9-sm103-avx512bf16` | AVX-512 BF16 | x86_64-linux |
| `pytorch-python313-cuda12_9-sm103-avx512vnni` | AVX-512 VNNI | x86_64-linux |
| `pytorch-python313-cuda12_9-sm103-armv8_2` | ARMv8.2-A | aarch64-linux |
| `pytorch-python313-cuda12_9-sm103-armv9` | ARMv9-A | aarch64-linux |

## Setup

The nixpkgs pin in each `.nix` file must point to a nixpkgs commit where `cudaPackages` defaults to CUDA 12.9. Update the `url` in `builtins.fetchTarball` accordingly.

## Building

```bash
git checkout cuda-12_9
flox build pytorch-python313-cuda12_9-sm103-avx2
```

## Related Branches

- **`main`** — CUDA 12.8 recipes (SM61, SM80–SM100, SM120, CPU)
- **`cuda-13_0`** — CUDA 13.0 recipes (SM110, SM121)
