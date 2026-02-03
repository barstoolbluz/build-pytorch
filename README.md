# PyTorch Custom Build Environment

> **You are on the `cuda-12_9` branch** — PyTorch 2.9.1 + CUDA 12.9.1 (50 variants)

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
| `main` | 2.8.0 | 12.8 | 43 | Stable baseline |
| **`cuda-12_9`** ⬅️ | **2.9.1** | **12.9.1** | **50** | **This branch** — Full coverage + SM103 (B300) |
| `cuda-13_0` | 2.10 | 13.0 | 3 | SM110 (DRIVE Thor), SM121 (DGX Spark) |

Different GPU architectures require different minimum CUDA versions — SM103 needs CUDA 12.9+, SM110/SM121 need CUDA 13.0+.

## Build Matrix (this branch: cuda-12_9)

**This branch builds PyTorch 2.9.1 with CUDA 12.9.1** — 50 variants covering all GPU architectures plus SM103 (B300).

### Complete Variant Matrix

| GPU Architecture | CPU ISA | Package Name | Primary Use Case |
|-----------------|---------|--------------|------------------|
| **CPU-only** | AVX2 | `pytorch-python313-cpu-avx2` | Development, broad x86-64 compatibility |
| | AVX-512 | `pytorch-python313-cpu-avx512` | General FP32 CPU training/inference |
| | AVX-512 BF16 | `pytorch-python313-cpu-avx512bf16` | BF16 mixed-precision training |
| | AVX-512 VNNI | `pytorch-python313-cpu-avx512vnni` | INT8 quantized inference |
| | ARMv8.2 | `pytorch-python313-cpu-armv8_2` | ARM Graviton2, older ARM servers |
| | ARMv9 | `pytorch-python313-cpu-armv9` | ARM Grace, Graviton3+, modern ARM |
| **SM80 (Ampere DC)** | AVX2 | `pytorch-python313-cuda12_9-sm80-avx2` | A100/A30 + broad CPU compatibility |
| | AVX-512 | `pytorch-python313-cuda12_9-sm80-avx512` | A100/A30 + general workloads |
| | AVX-512 BF16 | `pytorch-python313-cuda12_9-sm80-avx512bf16` | A100/A30 + BF16 training |
| | AVX-512 VNNI | `pytorch-python313-cuda12_9-sm80-avx512vnni` | A100/A30 + INT8 inference |
| | ARMv8.2 | `pytorch-python313-cuda12_9-sm80-armv8_2` | A100/A30 + ARM Graviton2 |
| | ARMv9 | `pytorch-python313-cuda12_9-sm80-armv9` | A100/A30 + ARM Grace |
| **SM86 (Ampere)** | AVX2 | `pytorch-python313-cuda12_9-sm86-avx2` | RTX 3090/A40 + broad CPU compatibility |
| | AVX-512 | `pytorch-python313-cuda12_9-sm86-avx512` | RTX 3090/A40 + general workloads |
| | AVX-512 BF16 | `pytorch-python313-cuda12_9-sm86-avx512bf16` | RTX 3090/A40 + BF16 training |
| | AVX-512 VNNI | `pytorch-python313-cuda12_9-sm86-avx512vnni` | RTX 3090/A40 + INT8 inference |
| | ARMv8.2 | `pytorch-python313-cuda12_9-sm86-armv8_2` | RTX 3090/A40 + ARM Graviton2 |
| | ARMv9 | `pytorch-python313-cuda12_9-sm86-armv9` | RTX 3090/A40 + ARM Grace |
| **SM89 (Ada)** | AVX2 | `pytorch-python313-cuda12_9-sm89-avx2` | RTX 4090/L40 + broad CPU compatibility |
| | AVX-512 | `pytorch-python313-cuda12_9-sm89-avx512` | RTX 4090/L40 + general workloads |
| | AVX-512 BF16 | `pytorch-python313-cuda12_9-sm89-avx512bf16` | RTX 4090/L40 + BF16 training |
| | AVX-512 VNNI | `pytorch-python313-cuda12_9-sm89-avx512vnni` | RTX 4090/L40 + INT8 inference |
| | ARMv8.2 | `pytorch-python313-cuda12_9-sm89-armv8_2` | RTX 4090/L40 + ARM Graviton2 |
| | ARMv9 | `pytorch-python313-cuda12_9-sm89-armv9` | RTX 4090/L40 + ARM Grace |
| **SM90 (Hopper)** | AVX2 | `pytorch-python313-cuda12_9-sm90-avx2` | H100/L40S + broad CPU compatibility |
| | AVX-512 | `pytorch-python313-cuda12_9-sm90-avx512` | H100/L40S + general workloads |
| | AVX-512 BF16 | `pytorch-python313-cuda12_9-sm90-avx512bf16` | H100/L40S + BF16 training |
| | AVX-512 VNNI | `pytorch-python313-cuda12_9-sm90-avx512vnni` | H100/L40S + INT8 inference |
| | ARMv8.2 | `pytorch-python313-cuda12_9-sm90-armv8_2` | H100/L40S + ARM Graviton2 |
| | ARMv9 | `pytorch-python313-cuda12_9-sm90-armv9` | H100/L40S + ARM Grace |
| **SM100 (Blackwell DC)** | AVX2 | `pytorch-python313-cuda12_9-sm100-avx2` | B100/B200 + broad CPU compatibility |
| | AVX-512 | `pytorch-python313-cuda12_9-sm100-avx512` | B100/B200 + general workloads |
| | AVX-512 BF16 | `pytorch-python313-cuda12_9-sm100-avx512bf16` | B100/B200 + BF16 training |
| | AVX-512 VNNI | `pytorch-python313-cuda12_9-sm100-avx512vnni` | B100/B200 + INT8 inference |
| | ARMv8.2 | `pytorch-python313-cuda12_9-sm100-armv8_2` | B100/B200 + ARM Graviton2 |
| | ARMv9 | `pytorch-python313-cuda12_9-sm100-armv9` | B100/B200 + ARM Grace |
| **SM103 (Blackwell DC)** | AVX2 | `pytorch-python313-cuda12_9-sm103-avx2` | B300 + broad CPU compatibility |
| | AVX-512 | `pytorch-python313-cuda12_9-sm103-avx512` | B300 + general workloads |
| | AVX-512 BF16 | `pytorch-python313-cuda12_9-sm103-avx512bf16` | B300 + BF16 training |
| | AVX-512 VNNI | `pytorch-python313-cuda12_9-sm103-avx512vnni` | B300 + INT8 inference |
| | ARMv8.2 | `pytorch-python313-cuda12_9-sm103-armv8_2` | B300 + ARM Graviton2 |
| | ARMv9 | `pytorch-python313-cuda12_9-sm103-armv9` | B300 + ARM Grace |
| **SM61 (Pascal)** | AVX | `pytorch-python313-cuda12_9-sm61-avx` | GTX 1070/1080 Ti + legacy AVX CPUs |
| | AVX2 | `pytorch-python313-cuda12_9-sm61-avx2` | GTX 1070/1080 Ti + modern CPUs |
| **SM120 (Blackwell)** | AVX2 | `pytorch-python313-cuda12_9-sm120-avx2` | RTX 5090 + broad CPU compatibility |
| | AVX-512 | `pytorch-python313-cuda12_9-sm120-avx512` | RTX 5090 + general workloads |
| | AVX-512 BF16 | `pytorch-python313-cuda12_9-sm120-avx512bf16` | RTX 5090 + BF16 training |
| | AVX-512 VNNI | `pytorch-python313-cuda12_9-sm120-avx512vnni` | RTX 5090 + INT8 inference |
| | ARMv8.2 | `pytorch-python313-cuda12_9-sm120-armv8_2` | RTX 5090 + ARM Graviton2 |
| | ARMv9 | `pytorch-python313-cuda12_9-sm120-armv9` | RTX 5090 + ARM Grace |
### Variants on Other Branches

| Branch | PyTorch | CUDA | Architectures | Variants |
|--------|---------|------|---------------|----------|
| `main` | 2.8.0 | 12.8 | SM61–SM120, CPU | 43 (stable baseline) |
| `cuda-13_0` | 2.10 | 13.0 | SM110 (DRIVE Thor), SM121 (DGX Spark) | 3 |

```bash
# PyTorch 2.8.0 + CUDA 12.8 (stable baseline)
git checkout main && flox build pytorch-python313-cuda12_8-sm90-avx512

# PyTorch 2.10 + CUDA 13.0 (DGX Spark, DRIVE Thor)
git checkout cuda-13_0 && flox build pytorch-python313-cuda13_0-sm121-avx512
```

### GPU Architecture Reference

**SM121 (DGX Spark) - Compute Capability 12.1** *(cuda-13_0 branch)*
- Specialized Datacenter: DGX Spark
- Driver: NVIDIA 570+
- CUDA: Requires 12.9+ (nvcc 12.8 does not recognize sm_121)

**SM120 (Blackwell) - Compute Capability 12.0**
- Consumer: RTX 5090
- Driver: NVIDIA 570+
- Note: Requires PyTorch 2.7+ or nightly builds

**SM110 (Blackwell Thor/NVIDIA DRIVE) - Compute Capability 11.0** *(cuda-13_0 branch)*
- Automotive/Edge: NVIDIA DRIVE platforms (Thor, Orin+)
- Driver: NVIDIA 550+
- CUDA: Requires 13.0+ (nvcc 12.8 does not recognize sm_110)

**SM103 (Blackwell B300 Datacenter) - Compute Capability 10.3** *(this branch)*
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

**SM61 (Pascal) - Compute Capability 6.1**
- Consumer: GTX 1070, GTX 1080, GTX 1080 Ti
- Driver: NVIDIA 390+
- Note: cuDNN 9.11+ dropped SM < 7.5 support. FBGEMM, MKLDNN, NNPACK disabled (require AVX2+). Only AVX CPU variant available.

**Other Supported Architectures** (no variants yet, add as needed):
- SM75 (Turing): T4, RTX 2080 Ti, Quadro RTX 8000

### CPU Variant Guide

Choose the right CPU variant based on your hardware and workload:

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
flox build pytorch-python313-cuda12_9-sm86-avx512
```

**Scenario 2: H100 Datacenter + AMD EPYC Zen 4**
```bash
# Check CPU
lscpu | grep avx512_vnni  # ✓ Found for INT8 inference

# For training
flox build pytorch-python313-cuda12_9-sm90-avx512

# For INT8 inference
flox build pytorch-python313-cuda12_9-sm90-avx512vnni
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
flox build pytorch-python313-cuda12_9-sm90-armv9
```

## Quick Start

```bash
# Enter the build environment
flox activate

# Build a specific variant
flox build pytorch-python313-cuda12_9-sm90-avx512

# The result will be in ./result-pytorch-python313-cuda12_9-sm90-avx512/
ls -lh result-pytorch-python313-cuda12_9-sm90-avx512/lib/python3.13/site-packages/torch/
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
│   └── pkgs/                      # Nix expression builds (50 variants on this branch)
│       ├── pytorch-python313-cpu-*.nix            # 6 CPU-only variants
│       ├── pytorch-python313-cuda12_9-sm61-*.nix  # 2 SM61 variants (Pascal)
│       ├── pytorch-python313-cuda12_9-sm80-*.nix  # 6 SM80 variants
│       ├── pytorch-python313-cuda12_9-sm86-*.nix  # 6 SM86 variants
│       ├── pytorch-python313-cuda12_9-sm89-*.nix  # 6 SM89 variants
│       ├── pytorch-python313-cuda12_9-sm90-*.nix  # 6 SM90 variants
│       ├── pytorch-python313-cuda12_9-sm100-*.nix # 6 SM100 variants
│       ├── pytorch-python313-cuda12_9-sm103-*.nix # 6 SM103 variants (B300)
│       └── pytorch-python313-cuda12_9-sm120-*.nix # 6 SM120 variants
├── README.md
├── QUICKSTART.md
├── BLAS_DEPENDENCIES.md
└── SUMMARY.md
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
flox publish -o <your-org> pytorch-python313-cuda12_9-sm90-avx512
flox publish -o <your-org> pytorch-python313-cuda12_9-sm86-avx2
flox publish -o <your-org> pytorch-python313-cuda12_9-cpu-avx2

# Users install with:
flox install <your-org>/pytorch-python313-cuda12_9-sm90-avx512
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
# .flox/pkgs/pytorch-python313-cuda12_9-sm89-avx512.nix
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
    pname = "pytorch-python313-cuda12_9-sm89-avx512";

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
