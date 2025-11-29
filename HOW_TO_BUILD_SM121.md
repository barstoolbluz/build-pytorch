# How to Build PyTorch Nightly for SM121 with CUDA 13.0

## Quick Start

### Step 1: Build PyTorch with CUDA 13.0

Use the `--stability=unstable` flag to get nixpkgs with CUDA 13.0 support:

```bash
cd ~/dev/builds/build-pytorch
flox activate

# Build PyTorch with CUDA 13.0 (requires unstable nixpkgs)
flox build --stability=unstable pytorch-python313-cuda13_0-sm121-armv9-nightly
```

**What happens:**
- `--stability=unstable` uses newer nixpkgs with `cudaPackages_13`
- PyTorch is built completely from scratch using `buildPythonPackage`
- Only CUDA 13.0 libraries are used (no CUDA 12.8 mixing)

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
flox build --stability=unstable pytorch-python313-cuda13_0-sm121-armv9-nightly

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
- Make sure you're using `--stability=unstable` flag
- Older/stable nixpkgs only has up to cudaPackages_12
- Only unstable nixpkgs has cudaPackages_13

### Build uses CUDA 12.8 instead of 13.0
- Verify you're using `--stability=unstable`
- Check build logs - should see "cuda13.0" in package names, not "cuda12.8"

## After Successful Build

Publish to your Flox organization:
```bash
flox publish pytorch-python313-cuda13_0-sm121-armv9-nightly
```

Then teammates can install with:
```bash
flox install yourorg/pytorch-python313-cuda13_0-sm121-armv9-nightly
```
