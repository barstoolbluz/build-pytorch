# How to Build PyTorch Nightly for SM121 with CUDA 13.0

## Quick Start

### Step 1: Build PyTorch with CUDA 13.0

The wrapper automatically uses CUDA 13.0 packages from flox's `flox-cuda` catalog:

```bash
cd ~/dev/builds/build-pytorch
flox activate

# Build PyTorch with CUDA 13.0 (uses flox-cuda catalog)
flox build pytorch-python313-cuda13_0-sm121-armv9-nightly-wrapper
```

**What happens:**
- Flox provides `cudaPackages_13` from its `flox-cuda` catalog
- The wrapper extracts cudatoolkit, cuDNN, NCCL, cuSPARSELt from cudaPackages_13
- PyTorch builds with these CUDA 13.0 packages

---

## Step 2: Fix the PyTorch Source Hash

The first build will fail with an error like:
```
error: hash mismatch in fixed-output derivation
  got:    sha256-abc123def456...
```

Copy that hash and update `.flox/pkgs/pytorch-python313-cuda13_0-sm121-armv9-nightly.nix` line 54:
```nix
hash = "sha256-abc123def456...";  # Replace with actual hash
```

## Step 3: Rebuild

```bash
flox build pytorch-python313-cuda13_0-sm121-armv9-nightly-wrapper

# This will take 2-3 hours...
```

## Step 4: Test the Build

```bash
cd ~/dev/builds/build-pytorch

# Find your result symlink
ls -la result-pytorch-python313-cuda13_0-sm121-armv9-nightly*

# Test PyTorch
./result-*/bin/python << 'EOF'
import torch
print(f"PyTorch version: {torch.__version__}")
print(f"CUDA available: {torch.cuda.is_available()}")
print(f"CUDA version: {torch.version.cuda}")

if torch.cuda.is_available():
    print(f"GPU: {torch.cuda.get_device_name(0)}")
    cap = torch.cuda.get_device_capability(0)
    print(f"Compute capability: {cap[0]}.{cap[1]}")

    # Test SM121 specifically
    if cap == (12, 1):
        print("✅ SM121 (DGX Spark) detected correctly!")
    else:
        print(f"⚠️  Expected SM121, got SM{cap[0]}{cap[1]}")
EOF
```

Expected output:
```
PyTorch version: 2.9.0+git...
CUDA available: True
CUDA version: 13.0
GPU: NVIDIA DGX Spark
Compute capability: 12.1
✅ SM121 (DGX Spark) detected correctly!
```

## Troubleshooting

### "hash mismatch"
- Expected on first build - copy the correct hash from error message
- Update line 54 in pytorch-python313-cuda13_0-sm121-armv9-nightly.nix

### Build fails with "Unknown architecture sm_121"
- Check the build logs for "Patching CMake files to add SM121 support"
- Should see "✓ SM121 support added to cmake/..."
- If not, the patch didn't apply correctly

### "cudaPackages_13 not found"
- Make sure you're running `flox build` (not plain `nix-build`)
- Flox provides cudaPackages_13 from its flox-cuda catalog
- Plain nix-build won't work because nixpkgs doesn't have cudaPackages_13

## After Successful Build

Publish to your Flox organization:
```bash
flox publish pytorch-python313-cuda13_0-sm121-armv9-nightly
```

Then teammates can install with:
```bash
flox install yourorg/pytorch-python313-cuda13_0-sm121-armv9-nightly
```
