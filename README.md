# PyTorch Custom Build Environment

> **You are on the `cuda-13_0` branch** — PyTorch 2.10 + CUDA 13.0 (SM110, SM121 for DGX Spark / DRIVE Thor)

This Flox environment builds custom PyTorch variants with targeted optimizations for specific GPU architectures and CPU instruction sets.

## Overview

Modern PyTorch containers are often bloated with support for every possible GPU architecture and CPU configuration. This project creates **targeted builds** that are optimized for specific hardware, resulting in:

- **Smaller binaries** - Only include code for your target GPU architecture
- **Better performance** - CPU code optimized for specific instruction sets (AVX2, AVX-512, ARMv8/9)
- **Faster startup** - Less code to load means faster initialization
- **Easier deployment** - Install only the variant you need

## Multi-Branch Strategy

This repository provides PyTorch builds across multiple branches, each targeting a specific PyTorch + CUDA combination:

| Branch | PyTorch | CUDA | Variants | Key Additions |
|--------|---------|------|----------|---------------|
| `main` | 2.8.0 | 12.8 | 44 | Stable baseline |
| `cuda-12_9` | 2.9.1 | 12.9.1 | 50 | Full coverage + SM103 (B300) |
| **`cuda-13_0`** ⬅️ | **2.10** | **13.0** | **59** | **This branch** — Full matrix with CUDA 13.0 + ARM |

Different GPU architectures require different minimum CUDA versions — SM103 needs CUDA 12.9+, SM110/SM121 need CUDA 13.0+.

## Version Matrix

| Branch | PyTorch | CUDA | cuDNN | Python | Min Driver | Nixpkgs Pin |
|--------|---------|------|-------|--------|------------|-------------|
| `main` | 2.8.0 | 12.8 | 9.x | 3.13 | 550+ | [`fe5e41d`](https://github.com/NixOS/nixpkgs/tree/fe5e41d7ffc0421f0913e8472ce6238ed0daf8e3) |
| `cuda-12_9` | 2.9.1 | 12.9.1 | 9.13.0 | 3.13 | 550+ | [`6a030d5`](https://github.com/NixOS/nixpkgs/tree/6a030d535719c5190187c4cec156f335e95e3211) |
| **`cuda-13_0`** ⬅️ | **2.10** | **13.0** | **9.x** | **3.13** | **570+** | [`6a030d5`](https://github.com/NixOS/nixpkgs/tree/6a030d535719c5190187c4cec156f335e95e3211) |

## Build Matrix (this branch: cuda-13_0)

**This branch builds PyTorch 2.10 with CUDA 13.0** — the complete 59-variant matrix including new architectures requiring CUDA 13.0+ and ARM CPU support.

### Complete Variant Matrix — 59 Variants

*Package pattern: `pytorch-python313-cuda13_0-{gpu}-{cpu}` | CPU-only: `pytorch-python313-cpu-{cpu}`*
*Click package names to view build recipes.*

| GPU | CPU ISA | Package | Use Case |
|-----|---------|---------|----------|
| **CPU-only** | AVX | [`cpu-avx`](.flox/pkgs/pytorch-python313-cpu-avx.nix) | Maximum compatibility (Sandy Bridge+) |
| | AVX2 | [`cpu-avx2`](.flox/pkgs/pytorch-python313-cpu-avx2.nix) | Development, broad compatibility |
| | AVX-512 | [`cpu-avx512`](.flox/pkgs/pytorch-python313-cpu-avx512.nix) | General FP32 workloads |
| | AVX-512 BF16 | [`cpu-avx512bf16`](.flox/pkgs/pytorch-python313-cpu-avx512bf16.nix) | BF16 mixed-precision training |
| | AVX-512 VNNI | [`cpu-avx512vnni`](.flox/pkgs/pytorch-python313-cpu-avx512vnni.nix) | INT8 quantized inference |
| | ARMv8.2 | [`cpu-armv8_2`](.flox/pkgs/pytorch-python313-cpu-armv8_2.nix) | ARM servers (Graviton2) |
| | ARMv9 | [`cpu-armv9`](.flox/pkgs/pytorch-python313-cpu-armv9.nix) | Modern ARM (Grace, Graviton3+) |
| **SM75 (Turing)** | AVX2 | [`sm75-avx2`](.flox/pkgs/pytorch-python313-cuda13_0-sm75-avx2.nix) | T4/RTX 2080 Ti + broad compatibility |
| | AVX-512 | [`sm75-avx512`](.flox/pkgs/pytorch-python313-cuda13_0-sm75-avx512.nix) | T4/RTX 2080 Ti + general workloads |
| | AVX-512 BF16 | [`sm75-avx512bf16`](.flox/pkgs/pytorch-python313-cuda13_0-sm75-avx512bf16.nix) | T4/RTX 2080 Ti + BF16 training |
| | AVX-512 VNNI | [`sm75-avx512vnni`](.flox/pkgs/pytorch-python313-cuda13_0-sm75-avx512vnni.nix) | T4/RTX 2080 Ti + INT8 inference |
| | ARMv8.2 | [`sm75-armv8_2`](.flox/pkgs/pytorch-python313-cuda13_0-sm75-armv8_2.nix) | T4/RTX 2080 Ti + Graviton2 |
| | ARMv9 | [`sm75-armv9`](.flox/pkgs/pytorch-python313-cuda13_0-sm75-armv9.nix) | T4/RTX 2080 Ti + Grace/Graviton3+ |
| **SM80 (Ampere DC)** | AVX2 | [`sm80-avx2`](.flox/pkgs/pytorch-python313-cuda13_0-sm80-avx2.nix) | A100/A30 + broad compatibility |
| | AVX-512 | [`sm80-avx512`](.flox/pkgs/pytorch-python313-cuda13_0-sm80-avx512.nix) | A100/A30 + general workloads |
| | AVX-512 BF16 | [`sm80-avx512bf16`](.flox/pkgs/pytorch-python313-cuda13_0-sm80-avx512bf16.nix) | A100/A30 + BF16 training |
| | AVX-512 VNNI | [`sm80-avx512vnni`](.flox/pkgs/pytorch-python313-cuda13_0-sm80-avx512vnni.nix) | A100/A30 + INT8 inference |
| | ARMv8.2 | [`sm80-armv8_2`](.flox/pkgs/pytorch-python313-cuda13_0-sm80-armv8_2.nix) | A100/A30 + Graviton2 |
| | ARMv9 | [`sm80-armv9`](.flox/pkgs/pytorch-python313-cuda13_0-sm80-armv9.nix) | A100/A30 + Grace/Graviton3+ |
| **SM86 (Ampere)** | AVX2 | [`sm86-avx2`](.flox/pkgs/pytorch-python313-cuda13_0-sm86-avx2.nix) | RTX 3090/A40 + broad compatibility |
| | AVX-512 | [`sm86-avx512`](.flox/pkgs/pytorch-python313-cuda13_0-sm86-avx512.nix) | RTX 3090/A40 + general workloads |
| | AVX-512 BF16 | [`sm86-avx512bf16`](.flox/pkgs/pytorch-python313-cuda13_0-sm86-avx512bf16.nix) | RTX 3090/A40 + BF16 training |
| | AVX-512 VNNI | [`sm86-avx512vnni`](.flox/pkgs/pytorch-python313-cuda13_0-sm86-avx512vnni.nix) | RTX 3090/A40 + INT8 inference |
| | ARMv8.2 | [`sm86-armv8_2`](.flox/pkgs/pytorch-python313-cuda13_0-sm86-armv8_2.nix) | RTX 3090/A40 + Graviton2 |
| | ARMv9 | [`sm86-armv9`](.flox/pkgs/pytorch-python313-cuda13_0-sm86-armv9.nix) | RTX 3090/A40 + Grace/Graviton3+ |
| **SM89 (Ada)** | AVX2 | [`sm89-avx2`](.flox/pkgs/pytorch-python313-cuda13_0-sm89-avx2.nix) | RTX 4090/L40 + broad compatibility |
| | AVX-512 | [`sm89-avx512`](.flox/pkgs/pytorch-python313-cuda13_0-sm89-avx512.nix) | RTX 4090/L40 + general workloads |
| | AVX-512 BF16 | [`sm89-avx512bf16`](.flox/pkgs/pytorch-python313-cuda13_0-sm89-avx512bf16.nix) | RTX 4090/L40 + BF16 training |
| | AVX-512 VNNI | [`sm89-avx512vnni`](.flox/pkgs/pytorch-python313-cuda13_0-sm89-avx512vnni.nix) | RTX 4090/L40 + INT8 inference |
| | ARMv8.2 | [`sm89-armv8_2`](.flox/pkgs/pytorch-python313-cuda13_0-sm89-armv8_2.nix) | RTX 4090/L40 + Graviton2 |
| | ARMv9 | [`sm89-armv9`](.flox/pkgs/pytorch-python313-cuda13_0-sm89-armv9.nix) | RTX 4090/L40 + Grace/Graviton3+ |
| **SM90 (Hopper)** | AVX2 | [`sm90-avx2`](.flox/pkgs/pytorch-python313-cuda13_0-sm90-avx2.nix) | H100/H200 + broad compatibility |
| | AVX-512 | [`sm90-avx512`](.flox/pkgs/pytorch-python313-cuda13_0-sm90-avx512.nix) | H100/H200 + general workloads |
| | AVX-512 BF16 | [`sm90-avx512bf16`](.flox/pkgs/pytorch-python313-cuda13_0-sm90-avx512bf16.nix) | H100/H200 + BF16 training |
| | AVX-512 VNNI | [`sm90-avx512vnni`](.flox/pkgs/pytorch-python313-cuda13_0-sm90-avx512vnni.nix) | H100/H200 + INT8 inference |
| | ARMv8.2 | [`sm90-armv8_2`](.flox/pkgs/pytorch-python313-cuda13_0-sm90-armv8_2.nix) | H100/H200 + Graviton2 |
| | ARMv9 | [`sm90-armv9`](.flox/pkgs/pytorch-python313-cuda13_0-sm90-armv9.nix) | H100/H200 + Grace/Graviton3+ |
| **SM100 (Blackwell DC)** | AVX2 | [`sm100-avx2`](.flox/pkgs/pytorch-python313-cuda13_0-sm100-avx2.nix) | B100/B200 + broad compatibility |
| | AVX-512 | [`sm100-avx512`](.flox/pkgs/pytorch-python313-cuda13_0-sm100-avx512.nix) | B100/B200 + general workloads |
| | AVX-512 BF16 | [`sm100-avx512bf16`](.flox/pkgs/pytorch-python313-cuda13_0-sm100-avx512bf16.nix) | B100/B200 + BF16 training |
| | AVX-512 VNNI | [`sm100-avx512vnni`](.flox/pkgs/pytorch-python313-cuda13_0-sm100-avx512vnni.nix) | B100/B200 + INT8 inference |
| | ARMv8.2 | [`sm100-armv8_2`](.flox/pkgs/pytorch-python313-cuda13_0-sm100-armv8_2.nix) | B100/B200 + Graviton2 |
| | ARMv9 | [`sm100-armv9`](.flox/pkgs/pytorch-python313-cuda13_0-sm100-armv9.nix) | B100/B200 + Grace/Graviton3+ |
| **SM103 (B300)** | AVX2 | [`sm103-avx2`](.flox/pkgs/pytorch-python313-cuda13_0-sm103-avx2.nix) | B300 + broad compatibility |
| | AVX-512 | [`sm103-avx512`](.flox/pkgs/pytorch-python313-cuda13_0-sm103-avx512.nix) | B300 + general workloads |
| | AVX-512 BF16 | [`sm103-avx512bf16`](.flox/pkgs/pytorch-python313-cuda13_0-sm103-avx512bf16.nix) | B300 + BF16 training |
| | AVX-512 VNNI | [`sm103-avx512vnni`](.flox/pkgs/pytorch-python313-cuda13_0-sm103-avx512vnni.nix) | B300 + INT8 inference |
| | ARMv8.2 | [`sm103-armv8_2`](.flox/pkgs/pytorch-python313-cuda13_0-sm103-armv8_2.nix) | B300 + Graviton2 |
| | ARMv9 | [`sm103-armv9`](.flox/pkgs/pytorch-python313-cuda13_0-sm103-armv9.nix) | B300 + Grace/Graviton3+ |
| **SM110 (DRIVE Thor)** | ARMv8.2 | [`sm110-armv8_2`](.flox/pkgs/pytorch-python313-cuda13_0-sm110-armv8_2.nix) | DRIVE Thor + Graviton2/older ARM |
| | ARMv9 | [`sm110-armv9`](.flox/pkgs/pytorch-python313-cuda13_0-sm110-armv9.nix) | DRIVE Thor + Grace/Graviton3+ |
| **SM120 (Blackwell)** | AVX2 | [`sm120-avx2`](.flox/pkgs/pytorch-python313-cuda13_0-sm120-avx2.nix) | RTX 5090 + broad compatibility |
| | AVX-512 | [`sm120-avx512`](.flox/pkgs/pytorch-python313-cuda13_0-sm120-avx512.nix) | RTX 5090 + general workloads |
| | AVX-512 BF16 | [`sm120-avx512bf16`](.flox/pkgs/pytorch-python313-cuda13_0-sm120-avx512bf16.nix) | RTX 5090 + BF16 training |
| | AVX-512 VNNI | [`sm120-avx512vnni`](.flox/pkgs/pytorch-python313-cuda13_0-sm120-avx512vnni.nix) | RTX 5090 + INT8 inference |
| | ARMv8.2 | [`sm120-armv8_2`](.flox/pkgs/pytorch-python313-cuda13_0-sm120-armv8_2.nix) | RTX 5090 + Graviton2 |
| | ARMv9 | [`sm120-armv9`](.flox/pkgs/pytorch-python313-cuda13_0-sm120-armv9.nix) | RTX 5090 + Grace/Graviton3+ |
| **SM121 (DGX Spark)** | ARMv8.2 | [`sm121-armv8_2`](.flox/pkgs/pytorch-python313-cuda13_0-sm121-armv8_2.nix) | DGX Spark + Graviton2/older ARM |
| | ARMv9 | [`sm121-armv9`](.flox/pkgs/pytorch-python313-cuda13_0-sm121-armv9.nix) | DGX Spark + Grace/Graviton3+ |

### Variants on Other Branches

For most GPU architectures (SM61–SM120, CPU-only), use these branches:

| Branch | PyTorch | CUDA | Architectures | Variants |
|--------|---------|------|---------------|----------|
| `main` | 2.8.0 | 12.8 | SM61–SM120, CPU | 44 (stable baseline) |
| `cuda-12_9` | **2.9.1** | **12.9.1** | SM61–SM120 + SM103 (B300) | **50** (recommended) |

```bash
# PyTorch 2.9.1 + CUDA 12.9.1 (recommended for most use cases)
git checkout cuda-12_9 && flox build pytorch-python313-cuda12_9-sm90-avx512

# PyTorch 2.8.0 + CUDA 12.8 (stable baseline)
git checkout main && flox build pytorch-python313-cuda12_8-sm90-avx512
```

### GPU Architecture Reference

**SM121 (DGX Spark) - Compute Capability 12.1** *(this branch)*
- Specialized Datacenter: DGX Spark
- Driver: NVIDIA 570+
- CUDA: Requires 12.9+ (nvcc 12.8 does not recognize sm_121)

**SM120 (Blackwell) - Compute Capability 12.0**
- Consumer: RTX 5090
- Driver: NVIDIA 570+
- Note: Requires PyTorch 2.7+ or nightly builds

**SM110 (Blackwell Thor/NVIDIA DRIVE) - Compute Capability 11.0** *(this branch)*
- Automotive/Edge: NVIDIA DRIVE platforms (Thor, Orin+)
- Driver: NVIDIA 550+
- CUDA: Requires 13.0+ (nvcc 12.8 does not recognize sm_110)

**SM103 (Blackwell B300 Datacenter) - Compute Capability 10.3** *(cuda-12_9 branch)*
- Datacenter: B300
- Driver: NVIDIA 550+
- CUDA: Requires 12.9+ (nvcc 12.8 does not recognize sm_103)

**SM100 (Blackwell Datacenter) - Compute Capability 10.0**
- Datacenter: B100, B200
- Driver: NVIDIA 550+
- Features: FP4 GEMV kernels, blockscaled datatypes, mixed input GEMM

**SM90 (Hopper) - Compute Capability 9.0**
- Datacenter: H100, H200, L40S
- Driver: NVIDIA 525+
- Features: Native FP8, Transformer Engine

**SM89 (Ada Lovelace) - Compute Capability 8.9**
- Consumer: RTX 4090, RTX 4080, RTX 4070 Ti, RTX 4070, RTX 4060 Ti
- Datacenter: L4, L40
- Driver: NVIDIA 520+
- Features: RT cores (3rd gen), Tensor cores (4th gen), DLSS 3

**SM86 (Ampere) - Compute Capability 8.6**
- Consumer: RTX 3090, RTX 3090 Ti, RTX 3080 Ti
- Datacenter: A5000, A40
- Driver: NVIDIA 470+
- Features: RT cores, Tensor cores (2nd gen)

**SM80 (Ampere Datacenter) - Compute Capability 8.0**
- Datacenter: A100 (40GB/80GB), A30
- Driver: NVIDIA 450+
- Features: Multi-Instance GPU (MIG), Tensor cores (3rd gen), FP64 Tensor cores

**SM75 (Turing) - Compute Capability 7.5**
- Consumer: RTX 2080 Ti, RTX 2080, RTX 2070, RTX 2060
- Datacenter: T4, Quadro RTX 8000, Quadro RTX 6000
- Driver: NVIDIA 418+
- Features: RT cores (1st gen), Tensor cores (2nd gen)

**SM61 (Pascal) - Compute Capability 6.1**
- Consumer: GTX 1070, GTX 1080, GTX 1080 Ti
- Driver: NVIDIA 390+
- Note: cuDNN 9.11+ dropped SM < 7.5 support. FBGEMM, MKLDNN, NNPACK disabled (require AVX2+) for AVX variant. AVX2 variant disables cuDNN only.

### CPU Variant Guide

Choose the right CPU variant based on your hardware and workload:

**AVX (Maximum Compatibility)**
- Hardware: Intel Sandy Bridge+ (2011+), AMD Bulldozer+ (2011+)
- Use for: Maximum CPU compatibility, legacy systems
- Choose when: Running on older CPUs without AVX2 support
- Note: Disables FBGEMM, MKLDNN, NNPACK (require AVX2+)

**AVX2 (Broad Compatibility)**
- Hardware: Intel Haswell+ (2013+), AMD Zen 1+ (2017+)
- Use for: Maximum compatibility, development, general workloads
- Choose when: Uncertain about CPU features or need portability

**AVX-512 (General Performance)**
- Hardware: Intel Skylake-X+ (2017+), AMD Zen 4+ (2022+)
- Use for: General FP32 training and inference on modern CPUs
- Choose when: You have AVX-512 CPU and need general-purpose performance
- NOT for: Specialized BF16 training or INT8 inference (see below)

**AVX-512 BF16 (Mixed-Precision Training)**
- Hardware: Intel Cooper Lake+ (2020+), AMD Zen 4+ (2022+)
- Use for: BF16 (Brain Float 16) mixed-precision training only
- Choose when: Training with BF16 on CPU (rare - usually done on GPU)
- NOT for: INT8 inference or general FP32 workloads
- Detection: `lscpu | grep bf16` or `/proc/cpuinfo` shows `avx512_bf16`

**AVX-512 VNNI (INT8 Inference)**
- Hardware: Intel Skylake-SP+ (2017+), AMD Zen 4+ (2022+)
- Use for: Quantized INT8 model inference acceleration
- Choose when: Running INT8 quantized models for fast inference
- NOT for: Training or general FP32 workloads
- Detection: `lscpu | grep vnni` or `/proc/cpuinfo` shows `avx512_vnni`

**ARMv8.2 (ARM Servers - Older)**
- Hardware: ARM Neoverse N1, Cortex-A75+, AWS Graviton2
- Use for: ARM servers without SVE2 support
- Choose when: You have Graviton2 or older ARM server hardware

**ARMv9 (ARM Servers - Modern)**
- Hardware: NVIDIA Grace, ARM Neoverse V1/V2, Cortex-X2+, AWS Graviton3+
- Use for: Modern ARM servers with SVE2 (Scalable Vector Extensions)
- Choose when: You have Grace, Graviton3+, or other modern ARM processors
- Detection: `lscpu | grep sve` or `/proc/cpuinfo` shows `sve` and `sve2`

## Variant Selection Guide

### Quick Decision Tree

**1. Do you have an NVIDIA GPU?**
- NO → Use CPU-only variant (choose CPU ISA below)
- YES → Continue to step 2

**2. Which GPU do you have?**
```bash
# Check GPU model
nvidia-smi --query-gpu=name --format=csv,noheader

# Check compute capability
nvidia-smi --query-gpu=compute_cap --format=csv,noheader
```

| Your GPU | Compute Cap | Use Architecture |
|----------|-------------|------------------|
| DGX Spark | 12.1 | **SM121** |
| RTX 5090 | 12.0 | **SM120** |
| NVIDIA DRIVE Thor, Orin+ | 11.0 | **SM110** |
| B300 | 10.3 | **SM103** |
| B100, B200 | 10.0 | **SM100** |
| H100, H200, L40S | 9.0 | **SM90** |
| RTX 4090, RTX 4080, RTX 4070 series, L4, L40 | 8.9 | **SM89** |
| RTX 3090, RTX 3090 Ti, RTX 3080 Ti, A5000, A40 | 8.6 | **SM86** |
| A100, A30 | 8.0 | **SM80** |
| T4, RTX 2080 Ti, Quadro RTX 8000 | 7.5 | **SM75** |
| GTX 1070, 1080, 1080 Ti | 6.1 | **SM61** |

**3. Which CPU ISA should you use?**
```bash
# Check CPU features
lscpu | grep -E 'avx|sve'
# or
grep -E 'avx|sve' /proc/cpuinfo
```

| If you see... | Platform | Workload Type | Choose |
|--------------|----------|---------------|--------|
| `avx512_bf16` | x86-64 | BF16 training on CPU | `avx512bf16` |
| `avx512_vnni` | x86-64 | INT8 inference | `avx512vnni` |
| `avx512f` | x86-64 | General workloads | `avx512` |
| `avx2` (no avx512) | x86-64 | General workloads | `avx2` |
| `sve` and `sve2` | ARM | Modern ARM (Grace, Graviton3+) | `armv9` |
| Neither | ARM | Older ARM (Graviton2) | `armv8_2` |

**Default Recommendations:**
- **Development/Testing**: `cpu-avx2` (fastest build, broad compatibility)
- **RTX 3090 Workstation (Intel i9/Xeon)**: `sm86-avx512`
- **H100 Datacenter (x86-64)**: `sm90-avx512`
- **RTX 5090 Gaming PC**: `sm120-avx512` or `sm120-avx2`
- **AWS with H100 + Graviton3**: `sm90-armv9`
- **Inference Server (INT8 models)**: `sm86-avx512vnni` (or sm90/sm120)

### Example Use Cases

**Scenario 1: RTX 3090 + Intel i9-12900K**
```bash
# Check CPU
lscpu | grep avx512f  # ✓ Found AVX-512

# Build variant
flox build pytorch-python313-cuda12_8-sm86-avx512
```

**Scenario 2: H100 Datacenter + AMD EPYC Zen 4**
```bash
# Check CPU
lscpu | grep avx512_vnni  # ✓ Found for INT8 inference

# For training
flox build pytorch-python313-cuda12_8-sm90-avx512

# For INT8 inference
flox build pytorch-python313-cuda12_8-sm90-avx512vnni
```

**Scenario 3: Development Laptop (no GPU)**
```bash
# Maximum compatibility
flox build pytorch-python313-cpu-avx2
```

**Scenario 4: AWS Graviton3 + H100**
```bash
# Check ARM features
lscpu | grep sve2  # ✓ Found (Graviton3 has SVE2)

# Build variant
flox build pytorch-python313-cuda12_8-sm90-armv9
```

## Quick Start

```bash
# Enter the build environment
flox activate

# Build a specific variant
flox build pytorch-python313-cuda12_8-sm90-avx512

# The result will be in ./result-pytorch-python313-cuda12_8-sm90-avx512/
ls -lh result-pytorch-python313-cuda12_8-sm90-avx512/lib/python3.13/site-packages/torch/
```

## Build Configuration Details

### GPU Builds

GPU-optimized builds use:
- **CUDA Toolkit** from nixpkgs (via Flox catalog)
- **cuBLAS** for GPU linear algebra operations
- **cuDNN** for deep learning primitives
- **Targeted compilation** via `TORCH_CUDA_ARCH_LIST`

Each GPU variant only compiles kernels for its specific SM architecture, reducing binary size by 50-70% compared to universal builds.

### CPU Builds

CPU-only builds use:
- **OpenBLAS** for linear algebra (open-source alternative to MKL)
- **oneDNN** (MKLDNN) for optimized deep learning operations
- **Compiler flags** for specific instruction sets

### BLAS Library Strategy

| Build Type | BLAS Backend | Notes |
|------------|--------------|-------|
| GPU (CUDA) | cuBLAS | NVIDIA's optimized GPU library |
| CPU (x86-64) | OpenBLAS | Open-source, good performance |
| CPU (alternative) | Intel MKL | Proprietary, slightly faster, available in Flox catalog as `mkl` |

## Architecture

```
build-pytorch/
├── .flox/
│   ├── env/
│   │   └── manifest.toml          # Build environment definition
│   └── pkgs/                      # Nix expression builds (59 variants on this branch)
│       ├── pytorch-python313-cuda13_0-sm75-*.nix    # T4/RTX 20 Turing (4 x86 + 2 ARM)
│       ├── pytorch-python313-cuda13_0-sm80-*.nix    # A100 Ampere DC (4 x86 + 2 ARM)
│       ├── pytorch-python313-cuda13_0-sm86-*.nix    # RTX 30 Ampere (4 x86 + 2 ARM)
│       ├── pytorch-python313-cuda13_0-sm89-*.nix    # RTX 40 Ada (4 x86 + 2 ARM)
│       ├── pytorch-python313-cuda13_0-sm90-*.nix    # H100 Hopper (4 x86 + 2 ARM)
│       ├── pytorch-python313-cuda13_0-sm100-*.nix   # B100/B200 (4 x86 + 2 ARM)
│       ├── pytorch-python313-cuda13_0-sm103-*.nix   # B300 (4 x86 + 2 ARM)
│       ├── pytorch-python313-cuda13_0-sm110-*.nix   # DRIVE Thor (2 ARM only)
│       ├── pytorch-python313-cuda13_0-sm120-*.nix   # RTX 5090 (4 x86 + 2 ARM)
│       ├── pytorch-python313-cuda13_0-sm121-*.nix   # DGX Spark (2 ARM only)
│       └── pytorch-python313-cpu-*.nix              # CPU-only (5 x86 + 2 ARM)
├── README.md
└── FLOX.md
```

### How It Works

1. **Base Package**: Each variant starts with `python313Packages.pytorch` from nixpkgs
2. **Override Mechanism**: Uses Nix's `overrideAttrs` to customize the build
3. **Build Flags**: Sets environment variables to control:
   - `TORCH_CUDA_ARCH_LIST` - GPU architecture targets
   - `CXXFLAGS` / `CFLAGS` - CPU instruction sets
   - `USE_CUBLAS`, `USE_CUDA` - Feature toggles
4. **Dependencies**: Injects specific CUDA libraries or BLAS backends

### Key Build Variables

```bash
# GPU Architecture (CUDA builds)
export TORCH_CUDA_ARCH_LIST="sm_90"
export CMAKE_CUDA_ARCHITECTURES="90"

# CPU Optimizations
export CXXFLAGS="$CXXFLAGS -mavx512f -mavx512dq -mfma"

# BLAS Backend Selection
export BLAS=OpenBLAS  # or MKL
export USE_CUBLAS=1   # For GPU builds
```

## Publishing to Flox Catalog

Once builds are validated, publish them for team use:

```bash
# Ensure git remote is configured
git remote add origin <your-repo-url>
git push origin master

# Publish to your Flox organization
flox publish -o <your-org> pytorch-python313-cuda12_8-sm90-avx512
flox publish -o <your-org> pytorch-python313-cuda12_8-sm86-avx2
flox publish -o <your-org> pytorch-python313-cuda12_8-cpu-avx2

# Users install with:
flox install <your-org>/pytorch-python313-cuda12_8-sm90-avx512
```

## Build Times & Requirements

⚠️ **Warning**: Building PyTorch from source is resource-intensive:

- **Time**: 1-3 hours per variant (depends on CPU cores)
- **Disk**: ~20GB per build (source + build artifacts)
- **Memory**: 8GB+ RAM recommended
- **CPU**: Multi-core system strongly recommended

**Recommendation**: Build on CI/CD runners and publish to your Flox catalog. Users then install pre-built packages instantly.

## Extending the Matrix

To add more variants (e.g., SM89 for RTX 4090):

1. Copy an existing `.nix` file from `.flox/pkgs/`
2. Modify the `gpuArchNum`, `gpuArchSM` (for GPU builds), and `cpuFlags` variables
3. Update the `pname` and descriptions
4. Commit: `git add .flox/pkgs/your-new-variant.nix && git commit`
5. Build: `flox build your-new-variant`

### Example: Adding SM89 (RTX 4090) with AVX-512

```nix
# .flox/pkgs/pytorch-python313-cuda12_8-sm89-avx512.nix
{ python3Packages, lib, config, cudaPackages, addDriverRunpath }:

let
  # GPU target: SM89 (Ada Lovelace - RTX 4090, L4, L40)
  gpuArchNum = "89";        # For CMAKE_CUDA_ARCHITECTURES
  gpuArchSM = "sm_89";      # For TORCH_CUDA_ARCH_LIST

  # CPU optimization: AVX-512
  cpuFlags = [
    "-mavx512f"    # AVX-512 Foundation
    "-mavx512dq"   # Doubleword and Quadword instructions
    "-mavx512vl"   # Vector Length extensions
    "-mavx512bw"   # Byte and Word instructions
    "-mfma"        # Fused multiply-add
  ];

in
  # Two-stage override:
  # 1. Enable CUDA and specify GPU targets
  (python3Packages.pytorch.override {
    cudaSupport = true;
    gpuTargets = [ gpuArchSM ];
  # 2. Customize build (CPU flags, metadata, etc.)
  }).overrideAttrs (oldAttrs: {
    pname = "pytorch-python313-cuda12_8-sm89-avx512";

    # Set CPU optimization flags
    preConfigure = (oldAttrs.preConfigure or "") + ''
      # CPU optimizations via compiler flags
      export CXXFLAGS="$CXXFLAGS ${lib.concatStringsSep " " cpuFlags}"
      export CFLAGS="$CFLAGS ${lib.concatStringsSep " " cpuFlags}"

      echo "========================================="
      echo "PyTorch Build Configuration"
      echo "========================================="
      echo "GPU Target: ${gpuArchSM} (Ada: RTX 4090, L4, L40)"
      echo "CPU Features: AVX-512"
      echo "CUDA: Enabled (cudaSupport=true, gpuTargets=[${gpuArchSM}])"
      echo "CXXFLAGS: $CXXFLAGS"
      echo "========================================="
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch for NVIDIA RTX 4090 (SM89, Ada) + AVX-512";
      longDescription = ''
        Custom PyTorch build with targeted optimizations:
        - GPU: NVIDIA Ada Lovelace architecture (SM89) - RTX 4090, L4, L40
        - CPU: x86-64 with AVX-512 instruction set
        - CUDA: 12.8 with compute capability 8.9
        - BLAS: cuBLAS for GPU operations
        - Python: 3.13
      '';
      platforms = [ "x86_64-linux" ];
    };
  })
```

**Key points:**
- Use **two-stage override**: First `.override { cudaSupport = true; gpuTargets = [...] }`, then `.overrideAttrs`
- Set `gpuTargets` in the first override stage (nixpkgs handles CUDA compilation)
- CPU flags go in `preConfigure` via `CXXFLAGS`/`CFLAGS`
- GPU architecture is automatic (from `gpuTargets`), don't set `TORCH_CUDA_ARCH_LIST` manually

## Python Version Support

Current variants use Python 3.13. To add Python 3.12 or 3.11 variants:

1. Change package name: `python312Packages.pytorch-sm90-avx512`
2. Ensure file name matches: `python312Packages.pytorch-sm90-avx512.nix`
3. The build will automatically use the correct Python version

## Troubleshooting

### Build fails with "CUDA not found"

Ensure you're building on a Linux system. GPU builds are Linux-only.

### Build fails with "unknown architecture"

Verify the SM architecture is supported by your PyTorch version:
- SM120 (Blackwell) requires PyTorch 2.7+ or nightly builds
- Older architectures like SM35 may be deprecated

### CPU build performance is poor

Consider using Intel MKL instead of OpenBLAS:
```nix
blasBackend = mkl;  # Instead of openblas
```

### Build takes too long

Use parallel compilation:
```bash
NIX_BUILD_CORES=8 flox build <variant>
```

## Related Documentation

- [PyTorch CUDA Architecture List](https://arnon.dk/matching-sm-architectures-arch-and-gencode-for-various-nvidia-cards/)
- [Flox Build Documentation](https://flox.dev/docs/reference/command-reference/flox-build/)
- [FLOX.md](./FLOX.md) - Complete Flox environment guide

## Contributing

To add new variants or improve builds:

1. Test locally with `flox build <variant>`
2. Verify the built package works: `./result-<variant>/bin/python -c "import torch; print(torch.__version__)"`
3. Commit changes and create a pull request
4. Document the new variant in this README

## License

This build environment configuration is MIT licensed. PyTorch itself is BSD-3-Clause licensed.
