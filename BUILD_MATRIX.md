# PyTorch Build Matrix Documentation

## Overview

This document defines the complete build matrix for custom PyTorch builds, explaining all dimensions and their interactions.

## Matrix Dimensions

Our build matrix has **4 independent dimensions**:

```
Build Variant = f(Python_Version, GPU_Architecture, CPU_ISA, CUDA_Toolkit)
```

### 1. Python Version

**Supported Versions:**
- Python 3.13 (current)
- Python 3.12 (planned)
- Python 3.11 (planned)

**Naming:** `py313`, `py312`, `py311`

**Example:** `pytorch-py313-...`

### 2. GPU Architecture (Compute Capability)

**Supported GPU Architectures:**

| SM Version | Architecture | GPUs | CUDA Requirement | Status |
|------------|--------------|------|------------------|--------|
| **SM120** | Blackwell | RTX 5090 | CUDA 12.8+ | Cutting edge |
| **SM90** | Hopper | H100, H200, L40S | CUDA 12.0+ | Datacenter |
| **SM89** | Ada Lovelace | RTX 4090, L4, L40 | CUDA 11.8+ | High-end gaming/workstation |
| **SM86** | Ampere | RTX 3090, A5000, A40 | CUDA 11.1+ | Mainstream gaming/workstation |
| **SM80** | Ampere | A100 | CUDA 11.0+ | Datacenter |
| **SM75** | Turing | T4, RTX 20xx | CUDA 10.0+ | Legacy datacenter/gaming |
| **CPU** | None | N/A | N/A | CPU-only builds |

**Naming:** `sm120`, `sm90`, `sm89`, `sm86`, `sm80`, `sm75`, `cpu`

**Example:** `pytorch-py313-sm120-...`

**Important Notes:**
- SM120 requires PyTorch 2.7+ with CUDA 12.8+ (stable release available as of April 2025)
- Older architectures (SM35-SM70) are deprecated in CUDA 13.0+
- GPU architecture determines MINIMUM CUDA toolkit version
- PyTorch 2.7 ships with pre-built wheels for CUDA 12.8

### 3. CPU Instruction Set Architecture (ISA)

**x86-64 Optimizations:**

| ISA | Compiler Flags | Hardware | Performance Gain | Compatibility |
|-----|----------------|----------|------------------|---------------|
| **AVX-512 BF16** | `-mavx512f -mavx512dq -mavx512vl -mavx512bw -mavx512bf16 -mfma` | Intel Cooper Lake+ (2020), AMD Zen 4+ (2022) | ~2.5x over baseline (BF16) | Limited |
| **AVX-512 VNNI** | `-mavx512f -mavx512dq -mavx512vl -mavx512bw -mavx512vnni -mfma` | Intel Skylake-SP+ (2017), AMD Zen 4+ (2022) | ~2.2x over baseline (INT8) | Limited |
| **AVX-512** | `-mavx512f -mavx512dq -mavx512vl -mavx512bw -mfma` | Intel Skylake-X+ (2017), AMD Zen 4+ (2022) | ~2x over baseline | Limited |
| **AVX2** | `-mavx2 -mfma -mf16c` | Intel Haswell+ (2013+), AMD Zen 1+ (2017) | ~1.5x over baseline | Broad |

**AMD Zen ISA Support:**
- Zen 1-3 (EPYC Naples/Rome/Milan): **AVX2** only
- Zen 4 (EPYC Genoa, 2022): **AVX2** + **AVX-512** + **VNNI** + **BF16**
- Zen 5 (EPYC Turin, 2024): Same as Zen 4, but native 512-bit datapath (vs 2×256 in Zen 4)

**ARM Optimizations:**

| ISA | Compiler Flags | Hardware | Status |
|-----|----------------|----------|--------|
| **ARMv9** | `-march=armv9-a+sve+sve2` | Neoverse V1/V2, Cortex-X2+, Graviton3+ | Supported |
| **ARMv8.2** | `-march=armv8.2-a+fp16+dotprod` | Neoverse N1, Cortex-A75+, Graviton2 | Supported |

**Naming:** `avx512bf16`, `avx512vnni`, `avx512`, `avx2`, `armv9`, `armv8.2`

**Example:** `pytorch-python313-cuda12_8-sm120-avx512-cu128`

**Note:** ISA-based naming is vendor-agnostic. An `avx512` build works on both Intel Skylake-X and AMD Zen 4.

### 4. CUDA Toolkit Version

**Why CUDA Toolkit Matters:**

The CUDA toolkit version determines:
1. Which GPU architectures can be compiled
2. Which NVIDIA driver versions are compatible
3. Which CUDA features are available

**CUDA Toolkit Compatibility Table:**

| CUDA Version | Min Driver (Linux) | Min Driver (Windows) | SM120 | SM90 | SM89 | SM86 | Notes |
|--------------|-------------------|----------------------|-------|------|------|------|-------|
| **13.0** | 580+ | Not bundled* | ✅ | ✅ | ✅ | ✅ | Latest, removes SM 5.x-7.0 |
| **12.9** | 575+ | 576+ | ✅ | ✅ | ✅ | ✅ | Latest 12.x |
| **12.8** | 570+ | 571+ | ✅ | ✅ | ✅ | ✅ | PyTorch 2.7 default |
| **12.6** | 560+ | 561+ | ✅** | ✅ | ✅ | ✅ | Stable |
| **12.5** | 555+ | 556+ | ✅** | ✅ | ✅ | ✅ | Stable |
| **12.4** | 550+ | 551+ | ❌ | ✅ | ✅ | ✅ | Stable |
| **12.2** | 535+ | 536+ | ❌ | ✅ | ✅ | ✅ | Baseline 12.x |
| **12.0** | 525+ | 526+ | ❌ | ✅ | ✅ | ✅ | First 12.x release |

*Starting CUDA 13.0, Windows driver must be installed separately
**SM120 may work but not officially tested/documented

**Naming:** `cuda130`, `cuda129`, `cuda128`, `cuda126`, `cuda125`, `cuda124`, `cuda122`

**Example:** `pytorch-python313-cuda12_8-sm120-avx512-cu129`

**Default Strategy:** Use CUDA 12.8 for all builds (matches PyTorch 2.7 default). Consider CUDA 12.9 or 13.0 for future releases.

## CUDA Forward Compatibility

### What is Forward Compatibility?

Forward compatibility allows applications compiled with a **newer CUDA toolkit** to run on systems with an **older driver** by installing a compatibility package.

### Forward Compatibility Matrix

| Compat Package | Driver 535+ | Driver 550+ | Driver 570+ | Driver 575+ | Driver 580+ |
|----------------|-------------|-------------|-------------|-------------|-------------|
| cuda-compat-13-0 | ✅ | ✅ | ✅ | ✅ | N/A (native) |
| cuda-compat-12-9 | ✅ | ✅ | ✅ | N/A (native) | ✅ |
| cuda-compat-12-8 | ✅ | ✅ | N/A (native) | ✅ | ✅ |
| cuda-compat-12-6 | ✅ | ✅ | ✅ | ✅ | ✅ |
| cuda-compat-12-5 | ✅ | ✅ | ✅ | ✅ | ✅ |
| cuda-compat-12-4 | ✅ | N/A (native) | ✅ | ✅ | ✅ |
| cuda-compat-12-3 | ✅ | ✅ | ✅ | ✅ | ✅ |
| cuda-compat-12-2 | N/A (native) | ✅ | ✅ | ✅ | ✅ |

### What Forward Compatibility Does NOT Do

**❌ Forward compatibility DOES NOT:**
- Add support for new GPU architectures (SM versions)
- Provide CUDA features not in the original driver
- Support OpenGL/Vulkan interoperability
- Work on all consumer GPUs (see limitations below)

**✅ Forward compatibility DOES:**
- Allow newer CUDA runtime to work with older driver
- Enable running apps compiled with newer toolkit
- Support PTX JIT compilation with compatibility packages
- Provide backward compatibility for most operations

**⚠️ Hardware Limitations:**
Forward compatibility officially supports:
- NVIDIA Data Center GPUs (Tesla, A100, H100, etc.)
- Select NGC-Ready RTX cards
- Jetson boards

**Not officially supported:**
- Consumer GeForce GTX/RTX cards (may work but not guaranteed)

### Example Usage

**Scenario:** User has driver 535 (CUDA 12.2) but needs to run PyTorch compiled with CUDA 12.9

**Solution:**
```bash
# Install forward compatibility package
sudo apt-get install cuda-compat-12-9

# Now can run CUDA 12.9 applications
flox install yourorg/pytorch-python313-cuda12_8-sm86-avx2-cu129
```

**Important:** This works for SM86 because SM86 was supported in the driver 535 era. It would NOT work for SM120 because SM120 requires driver 575+.

## Build Matrix Strategies

### Strategy 1: Minimal Matrix (Recommended)

Build **one CUDA version** (latest stable) for each GPU architecture.

**Total variants per Python version: 5**

```
pytorch-python313-cuda12_8-sm120-avx512-cu128   # RTX 5090, driver 570+
pytorch-python313-cuda12_8-sm90-avx512-cu128    # H100/L40S, driver 570+ (or 535+ with cuda-compat)
pytorch-python313-cuda12_8-sm89-avx512-cu128    # RTX 4090, driver 570+ (or 535+ with cuda-compat)
pytorch-python313-cuda12_8-sm86-avx2-cu128      # RTX 3090, driver 570+ (or 535+ with cuda-compat)
pytorch-python313-cuda12_8-cpu-avx2             # CPU-only
```

**Pros:**
- Simple to maintain
- Users with older drivers install cuda-compat package
- Covers all hardware with minimal builds

**Cons:**
- Users on older drivers need to install additional packages
- May have issues with corporate/restricted environments

### Strategy 2: Driver Compatibility Matrix

Build **multiple CUDA versions** to avoid requiring forward compat packages.

**Total variants per Python version: 12-15**

```
# SM120 builds (RTX 5090)
pytorch-python313-cuda12_8-sm120-avx512-cu129   # Driver 575+
pytorch-python313-cuda12_8-sm120-avx512-cu130   # Driver 580+

# SM90 builds (H100, L40S)
pytorch-python313-cuda12_8-sm90-avx512-cu122    # Driver 535+
pytorch-python313-cuda12_8-sm90-avx512-cu124    # Driver 550+
pytorch-python313-cuda12_8-sm90-avx512-cu128    # Driver 570+
pytorch-python313-cuda12_8-sm90-avx512-cu129    # Driver 575+

# SM89 builds (RTX 4090)
pytorch-python313-cuda12_8-sm89-avx512-cu122    # Driver 535+
pytorch-python313-cuda12_8-sm89-avx512-cu124    # Driver 550+
pytorch-python313-cuda12_8-sm89-avx512-cu128    # Driver 570+
pytorch-python313-cuda12_8-sm89-avx512-cu129    # Driver 575+

# SM86 builds (RTX 3090)
pytorch-python313-cuda12_8-sm86-avx2-cu122      # Driver 535+
pytorch-python313-cuda12_8-sm86-avx2-cu124      # Driver 550+
pytorch-python313-cuda12_8-sm86-avx2-cu128      # Driver 570+
pytorch-python313-cuda12_8-sm86-avx2-cu129      # Driver 575+

# CPU
pytorch-python313-cuda12_8-cpu-avx2             # No CUDA
```

**Pros:**
- No forward compat packages needed
- Works in restricted environments
- Clear driver requirements

**Cons:**
- 3x more variants to build and maintain
- More disk space for published packages
- More complex for users to choose

### Strategy 3: Hybrid Approach (Pragmatic)

Build **latest CUDA** for all + **one legacy CUDA** for SM86/SM89.

**Total variants per Python version: 7**

```
# Latest CUDA for all
pytorch-python313-cuda12_8-sm120-avx512-cu129   # RTX 5090
pytorch-python313-cuda12_8-sm90-avx512-cu129    # H100/L40S
pytorch-python313-cuda12_8-sm89-avx512-cu129    # RTX 4090
pytorch-python313-cuda12_8-sm86-avx2-cu129      # RTX 3090

# Legacy CUDA for older drivers
pytorch-python313-cuda12_8-sm89-avx512-cu122    # RTX 4090, driver 535+
pytorch-python313-cuda12_8-sm86-avx2-cu122      # RTX 3090, driver 535+

# CPU
pytorch-python313-cuda12_8-cpu-avx2             # CPU-only
```

**Rationale:**
- RTX 5090 users have new drivers anyway (575+)
- H100 users are in datacenters with new drivers (570+)
- RTX 4090/3090 users may have older gaming drivers (535+)

## Current Implementation Status

### Implemented Variants (Proof-of-Concept)

✅ `pytorch-python313-cuda12_8-sm120-avx512` - RTX 5090 (no CUDA version suffix yet)
✅ `pytorch-python313-cuda12_8-sm90-avx512` - H100/L40S (no CUDA version suffix yet)
✅ `pytorch-python313-cuda12_8-sm86-avx2` - RTX 3090/A40 (no CUDA version suffix yet)
✅ `pytorch-python313-cuda12_8-cpu-avx2` - CPU-only

**Current CUDA Version:** Uses whatever is in nixpkgs (likely 12.4-12.6)

### Recommended Next Steps

1. **Determine CUDA version in current nixpkgs:**
   ```bash
   nix eval nixpkgs#cudaPackages.cudatoolkit.version
   ```

2. **Update naming to include CUDA version:**
   - Rename files to include `-cu{version}` suffix
   - Update `pname` in each .nix file
   - Document CUDA version in README

3. **Choose build strategy:** Minimal (Strategy 1) or Hybrid (Strategy 3)

4. **Add CUDA version detection to builds:**
   - Print CUDA version during build
   - Verify compatibility with target SM arch
   - Warn if mismatch detected

## Naming Convention

### Full Package Name Format

```
pytorch-py{python_ver}-{gpu_arch}-{cpu_isa}-cu{cuda_ver}
```

### Examples

```
pytorch-python313-cuda12_8-sm120-avx512-cu129   # Python 3.13, RTX 5090, AVX-512, CUDA 12.9
pytorch-python312-cuda12_8-sm90-avx512-cu128    # Python 3.12, H100, AVX-512, CUDA 12.8
pytorch-python311-cuda12_8-sm86-avx2-cu122      # Python 3.11, RTX 3090, AVX2, CUDA 12.2
pytorch-python313-cuda12_8-cpu-avx2             # Python 3.13, CPU-only, AVX2
```

### Special Cases

**CPU-only builds:** No CUDA version suffix
```
pytorch-python313-cuda12_8-cpu-avx2
pytorch-python312-cuda12_8-cpu-armv9
```

**ARM builds:** Use arm prefix for CPU ISA
```
pytorch-python313-cuda12_8-sm90-armv9-cu129     # H100 + ARMv9 (future)
pytorch-python313-cuda12_8-cpu-armv8            # CPU-only ARMv8 (future)
```

## User Selection Guide

### For Users: How to Choose Your Build

1. **Check your GPU:**
   ```bash
   nvidia-smi --query-gpu=name,compute_cap --format=csv
   ```

2. **Check your driver:**
   ```bash
   nvidia-smi | grep "Driver Version"
   ```

3. **Match to build variant:**

   | Your GPU | Your Driver | Install This |
   |----------|-------------|--------------|
   | RTX 5090 | 575+ | `pytorch-python313-cuda12_8-sm120-avx512-cu129` |
   | RTX 5090 | < 575 | Upgrade driver first! |
   | H100/L40S | 575+ | `pytorch-python313-cuda12_8-sm90-avx512-cu129` |
   | H100/L40S | 535-574 | `pytorch-python313-cuda12_8-sm90-avx512-cu129` + `cuda-compat-12-9` |
   | RTX 4090 | 575+ | `pytorch-python313-cuda12_8-sm89-avx512-cu129` |
   | RTX 4090 | 535-574 | `pytorch-python313-cuda12_8-sm89-avx512-cu122` (if available) |
   | RTX 3090 | 575+ | `pytorch-python313-cuda12_8-sm86-avx2-cu129` |
   | RTX 3090 | 535-574 | `pytorch-python313-cuda12_8-sm86-avx2-cu122` (if available) |
   | No GPU | Any | `pytorch-python313-cuda12_8-cpu-avx2` |

4. **Check CPU capabilities (for AVX-512 builds):**
   ```bash
   lscpu | grep -E 'avx512|avx2'
   ```

   If no AVX-512: Use AVX2 variant instead.

## Build Time Considerations

### Build Duration by Variant Type

| Variant Type | Estimated Time | Reason |
|--------------|----------------|--------|
| CPU-only | 1-2 hours | Fewer compilation targets |
| GPU (single SM) | 2-3 hours | CUDA compilation overhead |
| GPU (multi SM) | 4-6 hours | Multiple architecture targets |

### Disk Space Requirements

| Component | Size per Build |
|-----------|----------------|
| Source code | ~2 GB |
| Build artifacts | ~15 GB |
| Final package | ~1-2 GB |
| **Total per variant** | ~18-20 GB |

**Recommendation:** Build on CI/CD with at least 100GB free space to accommodate multiple variants.

## CI/CD Considerations

### Parallel Build Strategy

Build variants in parallel by matrix dimension:

```yaml
matrix:
  python: [py313, py312, py311]
  gpu_arch: [sm120, sm90, sm89, sm86, cpu]
  cpu_isa: [avx512, avx2]
  cuda: [cu129]
```

**Estimated CI time:** 2-3 hours per variant × parallelism factor

### Publishing Strategy

After successful builds:
```bash
flox publish -o <your-org> pytorch-python313-cuda12_8-sm120-avx512-cu129
flox publish -o <your-org> pytorch-python313-cuda12_8-sm90-avx512-cu129
# ... etc
```

Users install with:
```bash
flox install <your-org>/pytorch-python313-cuda12_8-sm120-avx512-cu129
```

## Python 3.13 SM120 Build Matrix (Current Focus)

This section documents the complete build matrix for **RTX 5090 (SM120)** with **Python 3.13** and **CUDA 12.8**.

### Complete SM120 Matrix

**GPU Architecture:** SM120 (NVIDIA Blackwell - RTX 5090)
**CUDA Toolkit:** 12.8 (PyTorch 2.7 default)
**Python Version:** 3.13
**Driver Requirement:** 570+

#### x86-64 Variants (4 total)

| Package Name | CPU ISA | Hardware Support | Compiler Flags | Status |
|-------------|---------|------------------|----------------|---------|
| `pytorch-python313-cuda12_8-sm120-avx512` | AVX-512 (x86-64-v4) | Intel Skylake-X+ (2017), AMD Zen 4+ (2022) | `-mavx512f -mavx512dq -mavx512vl -mavx512bw -mfma` | ✅ Exists |
| `pytorch-python313-cuda12_8-sm120-avx2` | AVX2 (x86-64-v3) | Intel Haswell+ (2013), AMD Zen 1+ (2017) | `-mavx2 -mfma -mf16c` | ⏳ To create |
| `pytorch-python313-cuda12_8-sm120-avx512vnni` | AVX-512 + VNNI | Intel Skylake-SP+ (2017), AMD Zen 4+ (2022) | `-mavx512f -mavx512dq -mavx512vl -mavx512bw -mavx512vnni -mfma` | ⏳ To create |
| `pytorch-python313-cuda12_8-sm120-avx512bf16` | AVX-512 + BF16 | Intel Cooper Lake+ (2020), AMD Zen 4+ (2022) | `-mavx512f -mavx512dq -mavx512vl -mavx512bw -mavx512bf16 -mfma` | ⏳ To create |

**Use cases:**
- **avx512**: General datacenter use (most common)
- **avx2**: Broad compatibility for older CPUs
- **avx512vnni**: Optimized INT8 inference (quantized models)
- **avx512bf16**: Optimized BF16 training (modern mixed-precision)

#### ARM Variants (2 total)

| Package Name | CPU ISA | Hardware Support | Compiler Flags | Status |
|-------------|---------|------------------|----------------|---------|
| `pytorch-python313-cuda12_8-sm120-armv9` | ARMv9-A | AWS Graviton3+, Neoverse V1/V2, Grace Hopper | `-march=armv9-a+sve+sve2` | ⏳ To create |
| `pytorch-python313-cuda12_8-sm120-armv8.2` | ARMv8.2-A | AWS Graviton2, ARM servers | `-march=armv8.2-a+fp16+dotprod` | ⏳ To create |

**Use cases:**
- **armv9**: Modern ARM datacenter (Grace Hopper superchips, Graviton3)
- **armv8.2**: General ARM server deployments

**Total SM120 variants: 6** (4 x86-64 + 2 ARM)

### BLAS Backend Strategy

#### GPU Builds (All SM120 variants)

**BLAS Configuration:**
```nix
buildInputs = oldAttrs.buildInputs ++ [
  cudaPackages.libcublas      # Primary: GPU operations
  cudaPackages.libcufft
  cudaPackages.libcurand
  cudaPackages.libcusolver
  cudaPackages.libcusparse
  cudaPackages.cudnn
  # Explicitly add dynamic OpenBLAS for host-side operations
  (openblas.override {
    blas64 = false;
    singleThreaded = false;
  })
];

# Note: We rely on nixpkgs default OpenBLAS which uses DYNAMIC_ARCH=1
# This provides runtime CPU detection for optimal host-side performance
```

**Rationale:**
1. **Primary BLAS:** cuBLAS handles 90%+ of operations on GPU
2. **Host-side BLAS:** nixpkgs OpenBLAS (default uses DYNAMIC_ARCH=1) for CPU preprocessing/fallback
3. **Runtime dispatch:** Single OpenBLAS binary works on both Intel and AMD CPUs
4. **Minimal overhead:** Dynamic dispatch adds ~5% overhead but provides maximum compatibility
5. **Vendor-agnostic:** Users care about ISA (AVX2 vs AVX-512), not vendor (Intel vs AMD)
6. **Explicit control:** We add OpenBLAS to buildInputs to ensure it's included (not just inherited)

**Performance breakdown:**
- GPU operations (cuBLAS): 100% optimized ✅
- Host-side operations (dynamic OpenBLAS): 95% optimized ⚠️ (5% dispatch overhead)
- Overall performance: ~99% optimal (GPU workloads are 90%+ cuBLAS)

#### Alternative: Static OpenBLAS (Not Recommended)

Could use vendor-specific targets:
```nix
# Intel-specific
openblas.override {
  DYNAMIC_ARCH = 0;
  TARGET = "SKYLAKEX";  # AVX-512 Intel
}

# AMD-specific
openblas.override {
  DYNAMIC_ARCH = 0;
  TARGET = "ZEN4";  # AVX-512 AMD
}
```

**Why not:**
- Requires separate builds for Intel vs AMD
- Doubles the build matrix (6 variants → 12)
- Minimal performance gain (~5%) for GPU workloads
- Users would need to know CPU vendor

#### CPU-Only Builds Strategy

For CPU-only builds (no GPU), BLAS performance matters more:

```nix
# CPU builds should use dynamic OpenBLAS or MKL
blasBackend = openblas.override {
  DYNAMIC_ARCH = 1;  # OR use mkl for Intel CPUs
};
```

**Future consideration:** Offer both OpenBLAS and MKL variants for CPU-only builds.

### Build Command Examples

```bash
# Build all SM120 variants
flox build pytorch-python313-cuda12_8-sm120-avx512       # Already exists
flox build pytorch-python313-cuda12_8-sm120-avx2         # To create
flox build pytorch-python313-cuda12_8-sm120-avx512vnni   # To create
flox build pytorch-python313-cuda12_8-sm120-avx512bf16   # To create
flox build pytorch-python313-cuda12_8-sm120-armv9        # To create
flox build pytorch-python313-cuda12_8-sm120-armv8.2      # To create
```

### Requirements

All SM120 variants require:
- NVIDIA driver 570+ (for CUDA 12.8 + SM120 support)
- PyTorch 2.7+ (SM120 support added in stable release, April 2025)
- Linux only (aarch64-linux or x86_64-linux)
- RTX 5090 or other Blackwell GPU

## Future Expansions

### Planned Additions

1. **More GPU architectures:** SM90 (H100), SM89 (RTX 4090), SM86 (RTX 3090), SM80 (A100)
2. **More Python versions:** 3.12, 3.11
3. **More CUDA versions:** 12.9, 13.0 for cutting-edge
4. **CPU builds with MKL:** Intel-optimized CPU-only variants

### Not Planned

- SM versions < SM75 (deprecated by NVIDIA)
- CUDA versions < 12.0 (legacy)
- ROCm/AMD GPU support (different build system)
- Apple Silicon GPU builds (no NVIDIA driver support)
- Vendor-specific GPU builds (ISA-based naming is vendor-agnostic)

## Summary

**4D Build Matrix:**
1. Python Version (3.11, 3.12, 3.13)
2. GPU Architecture (SM120, SM90, SM89, SM86, SM80, SM75, CPU)
3. CPU ISA (AVX-512, AVX2, ARMv9, ARMv8)
4. CUDA Toolkit (13.0, 12.9, 12.8, 12.6, 12.4, 12.2)

**Current Implementation:** Minimal matrix with 4 variants (Python 3.13 only)

**Recommended Strategy:** Hybrid approach (7 variants per Python version)

**Total Potential Matrix:** 3 × 8 × 4 × 6 = **576 possible combinations**

**Practical Matrix:** 7 variants × 3 Python versions = **21 total builds**
