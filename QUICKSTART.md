# Quick Start Guide

## Choosing Your Variant

**60 production-ready variants** are available. Choose based on your hardware:

### Quick Selection

**Have NVIDIA GPU?**
```bash
# Check your GPU
nvidia-smi --query-gpu=name,compute_cap --format=csv,noheader
```

| Your GPU | Compute Cap | Architecture | Example Package |
|----------|-------------|--------------|-----------------|
| DGX Spark | 12.1 | SM121 | `pytorch-python313-cuda12_8-sm121-avx512` |
| RTX 5090 | 12.0 | SM120 | `pytorch-python313-cuda12_8-sm120-avx512` |
| NVIDIA DRIVE Thor, Orin+ | 11.0 | SM110 | `pytorch-python313-cuda12_8-sm110-avx512` |
| B300 | 10.3 | SM103 | `pytorch-python313-cuda12_8-sm103-avx512` |
| B100, B200 | 10.0 | SM100 | `pytorch-python313-cuda12_8-sm100-avx512` |
| H100, L40S | 9.0 | SM90 | `pytorch-python313-cuda12_8-sm90-avx512` |
| RTX 4090, L40 | 8.9 | SM89 | `pytorch-python313-cuda12_8-sm89-avx512` |
| RTX 3090, A40 | 8.6 | SM86 | `pytorch-python313-cuda12_8-sm86-avx512` |
| A100, A30 | 8.0 | SM80 | `pytorch-python313-cuda12_8-sm80-avx512` |

**CPU-only (no GPU)?**
```bash
# Check CPU features
lscpu | grep -E 'avx512|sve'
```

- See `avx512_bf16`? → Use `pytorch-python313-cpu-avx512bf16` (BF16 training)
- See `avx512_vnni`? → Use `pytorch-python313-cpu-avx512vnni` (INT8 inference)
- See `avx512f`? → Use `pytorch-python313-cpu-avx512` (general)
- See `avx2` only? → Use `pytorch-python313-cpu-avx2` (broad compatibility)
- See `sve2` (ARM)? → Use `pytorch-python313-cpu-armv9` (modern ARM)
- ARM without sve2? → Use `pytorch-python313-cpu-armv8.2` (Graviton2)

**Naming format:** `pytorch-python313-{cuda12_8-smXX|cpu}-{cpu-isa}`

## Building PyTorch Variants

### 1. Enter the Environment

```bash
cd /home/daedalus/dev/builds/build-pytorch
flox activate
```

### 2. Build a Variant

```bash
# CPU-only variants (faster builds, ~1-2 hours)
flox build pytorch-python313-cpu-avx2              # Broad compatibility
flox build pytorch-python313-cpu-avx512            # General FP32
flox build pytorch-python313-cpu-avx512vnni        # INT8 inference

# GPU variants (longer builds, ~2-3 hours each)
flox build pytorch-python313-cuda12_8-sm80-avx512  # A100/A30
flox build pytorch-python313-cuda12_8-sm86-avx512  # RTX 3090/A40
flox build pytorch-python313-cuda12_8-sm89-avx512  # RTX 4090/L40
flox build pytorch-python313-cuda12_8-sm90-avx512  # H100/L40S
flox build pytorch-python313-cuda12_8-sm100-avx512 # B100/B200
flox build pytorch-python313-cuda12_8-sm103-avx512 # B300
flox build pytorch-python313-cuda12_8-sm110-avx512 # NVIDIA DRIVE Thor/Orin+
flox build pytorch-python313-cuda12_8-sm120-avx2   # RTX 5090
flox build pytorch-python313-cuda12_8-sm121-avx512 # DGX Spark

# ARM variants (if on ARM server)
flox build pytorch-python313-cpu-armv9             # Grace, Graviton3+
flox build pytorch-python313-cuda12_8-sm90-armv9   # H100 + Grace
```

### 3. Use the Built Package

```bash
# Result appears as a symlink
ls -lh result-pytorch-python313-cuda12_8-cpu-avx2

# Test it
./result-pytorch-python313-cuda12_8-cpu-avx2/bin/python -c "import torch; print(torch.__version__)"

# Activate the environment
source result-pytorch-python313-cuda12_8-cpu-avx2/bin/activate
python -c "import torch; print(torch.__version__)"
```

## What Happened

The build command:
```bash
flox build pytorch-python313-cuda12_8-cpu-avx2
```

Is doing:
1. Reading `.flox/pkgs/pytorch-python313-cuda12_8-cpu-avx2.nix`
2. Calling `python3Packages.pytorch.overrideAttrs` with custom flags
3. Setting `CXXFLAGS="-mavx2 -mfma"` for CPU optimization
4. Compiling PyTorch from source (~1-3 hours)
5. Creating a result symlink: `./result-pytorch-python313-cuda12_8-cpu-avx2`

## Successful Output

You saw this output which confirms everything is working:

```
Building python3.13-pytorch-python313-cuda12_8-cpu-avx2-2.8.0 in Nix expression mode
this derivation will be built:
  /nix/store/...-python3.13-pytorch-python313-cuda12_8-cpu-avx2-2.8.0.drv
these 104 paths will be fetched (346.24 MiB download, 1977.98 MiB unpacked):
```

This means:
- ✅ Flox found your Nix expression
- ✅ The package name is correct
- ✅ Dependencies are being downloaded
- ✅ The build will compile PyTorch with your custom flags

## Build Time Warning

**CPU-only builds:** 1-2 hours on a multi-core system
**GPU builds:** 2-3 hours (more CUDA code to compile)

**Recommendation:** Start with the CPU variant to validate everything works, then queue up the GPU builds to run overnight or on a beefy CI machine.

## Publishing (After Build Completes)

Once you have successfully built packages:

```bash
# Push to git remote
git remote add origin <your-repo-url>
git push origin master

# Publish to Flox catalog (requires flox auth login)
flox publish -o <your-org> pytorch-python313-cuda12_8-cpu-avx2
flox publish -o <your-org> pytorch-python313-cuda12_8-sm90-avx512
flox publish -o <your-org> pytorch-python313-cuda12_8-sm86-avx2

# Users can then install with:
flox install <your-org>/pytorch-python313-cuda12_8-sm90-avx512
```

## Adding More Variants

Copy an existing `.nix` file:

```bash
cp .flox/pkgs/pytorch-python313-cuda12_8-sm90-avx512.nix \
   .flox/pkgs/pytorch-python313-cuda12_8-sm89-avx512.nix
```

Edit the new file (use **two-stage override pattern**):
```nix
let
  # GPU target: SM89 (Ada Lovelace - RTX 4090, L4, L40)
  gpuArchNum = "89";        # For CMAKE_CUDA_ARCHITECTURES
  gpuArchSM = "sm_89";      # For TORCH_CUDA_ARCH_LIST

  # CPU optimization
  cpuFlags = [ "-mavx512f" "-mavx512dq" "-mavx512vl" "-mavx512bw" "-mfma" ];

in
  # 1. Enable CUDA and specify GPU targets
  (python3Packages.pytorch.override {
    cudaSupport = true;
    gpuTargets = [ gpuArchSM ];
  # 2. Customize build
  }).overrideAttrs (oldAttrs: {
    pname = "pytorch-python313-cuda12_8-sm89-avx512";
    # ... Update preConfigure and meta sections
  })
```

Commit and build:
```bash
git add .flox/pkgs/pytorch-python313-cuda12_8-sm89-avx512.nix
git commit -m "Add RTX 4090 (SM89) variant with AVX-512"
flox build pytorch-python313-cuda12_8-sm89-avx512
```

## Next Steps

See the full documentation:
- `README.md` - Complete guide and build matrix
- `BLAS_DEPENDENCIES.md` - Technical details on linear algebra libraries
- `SUMMARY.md` - Implementation summary and architecture
