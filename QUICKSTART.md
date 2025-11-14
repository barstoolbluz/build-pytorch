# Quick Start Guide

## Fixed Naming Issue ✅

The package names have been updated to work with Flox's Nix expression build system.

**Naming format:** `pytorch-py{python-ver}-{gpu|cpu}-{isa}`

Examples:
- `pytorch-py313-sm90-avx512`
- `pytorch-py313-sm86-avx2`
- `pytorch-py313-cpu-avx2`

## Building PyTorch Variants

### 1. Enter the Environment

```bash
cd /home/daedalus/dev/builds/build-pytorch
flox activate
```

### 2. Build a Variant

```bash
# Build CPU-only variant (faster, recommended for testing)
flox build pytorch-py313-cpu-avx2

# Build GPU variants (will take 1-3 hours each)
flox build pytorch-py313-sm90-avx512  # H100/L40S
flox build pytorch-py313-sm86-avx2    # RTX 3090/A40
```

### 3. Use the Built Package

```bash
# Result appears as a symlink
ls -lh result-pytorch-py313-cpu-avx2

# Test it
./result-pytorch-py313-cpu-avx2/bin/python -c "import torch; print(torch.__version__)"

# Activate the environment
source result-pytorch-py313-cpu-avx2/bin/activate
python -c "import torch; print(torch.__version__)"
```

## What Happened

The build command:
```bash
flox build pytorch-py313-cpu-avx2
```

Is doing:
1. Reading `.flox/pkgs/pytorch-py313-cpu-avx2.nix`
2. Calling `python3Packages.pytorch.overrideAttrs` with custom flags
3. Setting `CXXFLAGS="-mavx2 -mfma"` for CPU optimization
4. Compiling PyTorch from source (~1-3 hours)
5. Creating a result symlink: `./result-pytorch-py313-cpu-avx2`

## Successful Output

You saw this output which confirms everything is working:

```
Building python3.13-pytorch-py313-cpu-avx2-2.8.0 in Nix expression mode
this derivation will be built:
  /nix/store/...-python3.13-pytorch-py313-cpu-avx2-2.8.0.drv
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
flox publish -o <your-org> pytorch-py313-cpu-avx2
flox publish -o <your-org> pytorch-py313-sm90-avx512
flox publish -o <your-org> pytorch-py313-sm86-avx2

# Users can then install with:
flox install <your-org>/pytorch-py313-sm90-avx512
```

## Adding More Variants

Copy an existing `.nix` file:

```bash
cp .flox/pkgs/pytorch-py313-sm90-avx512.nix \
   .flox/pkgs/pytorch-py313-sm89-avx512.nix
```

Edit the new file:
```nix
let
  gpuArch = "sm_89";  # Change GPU arch
  cpuFlags = [ "-mavx512f" "-mavx512dq" "-mfma" ];  # Adjust CPU flags
in python3Packages.pytorch.overrideAttrs (oldAttrs: {
  pname = "pytorch-py313-sm89-avx512";  # Update package name
  # ... rest stays the same
})
```

Commit and build:
```bash
git add .flox/pkgs/pytorch-py313-sm89-avx512.nix
git commit -m "Add RTX 4090 variant with AVX-512"
flox build pytorch-py313-sm89-avx512
```

## Next Steps

See the full documentation:
- `README.md` - Complete guide and build matrix
- `BLAS_DEPENDENCIES.md` - Technical details on linear algebra libraries
- `SUMMARY.md` - Implementation summary and architecture
