# PyTorch Custom Build Environment

This Flox environment builds custom PyTorch variants with targeted optimizations for specific GPU architectures and CPU instruction sets.

## Overview

Modern PyTorch containers are often bloated with support for every possible GPU architecture and CPU configuration. This project creates **targeted builds** that are optimized for specific hardware, resulting in:

- **Smaller binaries** - Only include code for your target GPU architecture
- **Better performance** - CPU code optimized for specific instruction sets (AVX2, AVX-512, ARMv8/9)
- **Faster startup** - Less code to load means faster initialization
- **Easier deployment** - Install only the variant you need

## Build Matrix

### Proof-of-Concept Variants

| Package Name | GPU Target | CPU Target | Use Case |
|-------------|------------|------------|----------|
| `python313Packages.pytorch-sm90-avx512` | NVIDIA H100, L40S (SM90) | x86-64 AVX-512 | Modern datacenter (Hopper GPUs) |
| `python313Packages.pytorch-sm86-avx2` | NVIDIA RTX 3090, A40 (SM86) | x86-64 AVX2 | Workstations & servers (Ampere GPUs) |
| `python313Packages.pytorch-cpu-avx2` | None (CPU-only) | x86-64 AVX2 | Development, inference, CPU workloads |

### Supported GPU Architectures

- **SM120** - Blackwell (RTX 5090) - _Requires PyTorch nightly_
- **SM90** - Hopper (H100, H200, L40S)
- **SM89** - Ada Lovelace (RTX 4090, L4, L40)
- **SM86** - Ampere (RTX 3090, A5000, A40)
- **SM80** - Ampere (A100)
- **SM75** - Turing (T4, RTX 20xx series)

### Supported CPU Features

- **AVX-512** - Intel Skylake-X and newer, AMD Zen 4+
- **AVX2** - Intel Haswell+ (2013+), AMD Excavator+ (broad compatibility)
- **ARMv9** - ARM Neoverse V1/V2, Cortex-X2+
- **ARMv8** - ARM Cortex-A53+, Apple Silicon (baseline)

## Quick Start

```bash
# Enter the build environment
flox activate

# Build a specific variant
flox build python313Packages.pytorch-sm90-avx512

# The result will be in ./result-python313Packages.pytorch-sm90-avx512/
ls -lh result-python313Packages.pytorch-sm90-avx512/lib/python3.13/site-packages/torch/
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
│   └── pkgs/                      # Nix expression builds
│       ├── python313Packages.pytorch-sm90-avx512.nix
│       ├── python313Packages.pytorch-sm86-avx2.nix
│       └── python313Packages.pytorch-cpu-avx2.nix
└── README.md
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
flox publish -o <your-org> python313Packages.pytorch-sm90-avx512
flox publish -o <your-org> python313Packages.pytorch-sm86-avx2
flox publish -o <your-org> python313Packages.pytorch-cpu-avx2

# Users install with:
flox install <your-org>/python313Packages.pytorch-sm90-avx512
```

## Build Times & Requirements

⚠️ **Warning**: Building PyTorch from source is resource-intensive:

- **Time**: 1-3 hours per variant (depends on CPU cores)
- **Disk**: ~20GB per build (source + build artifacts)
- **Memory**: 8GB+ RAM recommended
- **CPU**: Multi-core system strongly recommended

**Recommendation**: Build on CI/CD runners and publish to your Flox catalog. Users then install pre-built packages instantly.

## Extending the Matrix

To add more variants:

1. Copy an existing `.nix` file from `.flox/pkgs/`
2. Modify the `gpuArch` and `cpuFlags` variables
3. Update the `pname` to match the new configuration
4. Commit the new file: `git add .flox/pkgs/your-new-variant.nix && git commit`
5. Build: `flox build your-new-variant`

### Example: Adding SM89 (RTX 4090) with AVX-512

```nix
# .flox/pkgs/python313Packages.pytorch-sm89-avx512.nix
{ python3Packages, lib, cudaPackages, addDriverRunpath }:

let
  gpuArch = "sm_89";
  cpuFlags = [ "-mavx512f" "-mavx512dq" "-mfma" ];
in python3Packages.pytorch.overrideAttrs (oldAttrs: {
  pname = "python313Packages.pytorch-sm89-avx512";
  # ... (rest of configuration)
})
```

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
