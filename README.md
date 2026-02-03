# PyTorch Build Recipes

This repository contains Nix/Flox build recipes for PyTorch across multiple CUDA versions and GPU architectures. Each branch targets a specific PyTorch + CUDA combination.

## Repository Overview

| Branch | PyTorch | CUDA | Key Architectures | Use Case |
|--------|---------|------|-------------------|----------|
| **`main`** | 2.8.0 | 12.8 | SM61–SM100, SM120, CPU | Stable baseline |
| **`cuda-12_9`** | **2.9.1** | **12.9.1** | SM61–SM120, SM103, CPU | Blackwell B300 support |
| **`cuda-13_0`** | 2.10 | 13.0 | SM110, SM121 | DGX Spark, DRIVE Thor |

Different GPU architectures require different minimum CUDA versions:
- **SM103** (B300) requires CUDA 12.9+
- **SM110** (DRIVE Thor) and **SM121** (DGX Spark) require CUDA 13.0+

---

# This Branch: PyTorch 2.9.1 + CUDA 12.9.1

This branch contains **PyTorch 2.9.1** build recipes using **CUDA 12.9.1** via a pinned nixpkgs with the `cudaPackages_12_9` overlay. It covers all GPU architectures from `main` plus SM103 (Blackwell B300).

## Version Info

| Component | Version |
|-----------|---------|
| PyTorch | 2.9.1 |
| CUDA Toolkit | 12.9.1 |
| cuDNN | 9.13.0 |
| Python | 3.13 |
| nixpkgs | `6a030d535719c5190187c4cec156f335e95e3211` |

## Why This Branch?

SM103 (`sm_103`) is not recognized by `nvcc` in CUDA 12.8 (the default in nixpkgs on `main`). CUDA 12.9 adds SM103 support. This branch pins nixpkgs and applies an overlay to select `cudaPackages_12_9` for all builds.

## Recipes (50 variants)

### GPU Architectures

| Architecture | GPU Examples | Variants |
|---|---|---|
| SM61 (Pascal) | GTX 1070, 1080 Ti | avx, avx2 |
| SM80 (Ampere DC) | A100, A30 | avx2, avx512, avx512bf16, avx512vnni, armv8_2, armv9 |
| SM86 (Ampere) | RTX 3090, A40 | avx2, avx512, avx512bf16, avx512vnni, armv8_2, armv9 |
| SM89 (Ada) | RTX 4090, L40 | avx2, avx512, avx512bf16, avx512vnni, armv8_2, armv9 |
| SM90 (Hopper) | H100, L40S | avx2, avx512, avx512bf16, avx512vnni, armv8_2, armv9 |
| SM100 (Blackwell DC) | B100, B200 | avx2, avx512, avx512bf16, avx512vnni, armv8_2, armv9 |
| SM103 (Blackwell DC) | B300 | avx2, avx512, avx512bf16, avx512vnni, armv8_2, armv9 |
| SM120 (Blackwell) | RTX 5090 | avx2, avx512, avx512bf16, avx512vnni, armv8_2, armv9 |

### CPU-Only

| Variants |
|---|
| avx2, avx512, avx512bf16, avx512vnni, armv8_2, armv9 |

### SM61 Notes

- **sm61-avx**: AVX-only build for older CPUs. Disables cuDNN, FBGEMM, MKLDNN, NNPACK (require AVX2+).
- **sm61-avx2**: Modern CPU with Pascal GPU. Only cuDNN disabled (SM61 < SM75 GPU limitation).

## Building

```bash
git checkout cuda-12_9
flox build pytorch-python313-cuda12_9-sm90-avx2
flox build pytorch-python313-cpu-avx512
```

## Switching Branches

```bash
# For PyTorch 2.8.0 + CUDA 12.8 (stable)
git checkout main

# For PyTorch 2.9.1 + CUDA 12.9.1 (this branch)
git checkout cuda-12_9

# For PyTorch 2.10 + CUDA 13.0 (DGX Spark, DRIVE Thor)
git checkout cuda-13_0
```
