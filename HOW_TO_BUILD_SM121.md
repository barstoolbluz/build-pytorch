# How to Build PyTorch Nightly for SM121 with CUDA 13.0

## Quick Start

### Step 1: Make sure CUDA 13.0 packages are built

```bash
cd ~/dev/builds/build-cudatoolkit
flox activate

# Build all CUDA 13.0 packages (if not already done)
flox build cudatoolkit-13_0
flox build cudnn-13_0
flox build nccl-13_0
flox build libcusparse_lt-13_0

# Verify results exist
ls -la result-cudatoolkit-13_0
ls -la result-cudnn-13_0
ls -la result-nccl-13_0
ls -la result-libcusparse_lt-13_0
```

### Step 2: Choose your build method

You have **2 options** - pick the one that works best for you:

---

## Option A: Use the Wrapper (Auto-fetches CUDA packages) - RECOMMENDED

**Best if:** You want a simple, automatic build

This is the proper Nix pattern - it fetches the CUDA packages from GitHub and builds everything.

### A1: Default Mode (Auto-fetch from GitHub)
```bash
cd ~/dev/builds/build-pytorch
flox activate

# Just build - wrapper fetches CUDA packages automatically
flox build pytorch-python313-cuda13_0-sm121-armv9-nightly-wrapper
```

**First build steps:**
1. Build will fail with hash mismatch - this is expected!
2. Copy the correct hash from the error message
3. Update line 34 in the wrapper .nix file with the hash
4. Rebuild

### A2: Override Mode (Use local build-cudatoolkit for development)
```bash
cd ~/dev/builds/build-pytorch
flox activate

# Point to your local build-cudatoolkit directory
export CUDA_TOOLKIT_REPO=$(pwd)/../build-cudatoolkit

# Build using local CUDA packages (skips GitHub fetch)
flox build pytorch-python313-cuda13_0-sm121-armv9-nightly-wrapper
```

**Why this is recommended:**
- Proper Nix pattern - reproducible builds
- Auto-fetches from GitHub (no local repo needed)
- Can override with local repo for development
- Suitable for publishing/sharing
- Single command builds everything

---

## Option B: Copy CUDA Packages Locally

**Best if:** You want everything self-contained in one repo

```bash
cd ~/dev/builds/build-pytorch

# Copy CUDA 13.0 package definitions from build-cudatoolkit
cp ../build-cudatoolkit/.flox/pkgs/cudatoolkit-13_0.nix .flox/pkgs/
cp ../build-cudatoolkit/.flox/pkgs/cudnn-13_0.nix .flox/pkgs/
cp ../build-cudatoolkit/.flox/pkgs/nccl-13_0.nix .flox/pkgs/
cp ../build-cudatoolkit/.flox/pkgs/libcusparse_lt-13_0.nix .flox/pkgs/

# Now add them to your manifest
flox edit
```

Add to `.flox/env/manifest.toml` under `[build.packages]`:
```toml
[build.packages]
cudatoolkit-13_0.pkg-path = ".flox/pkgs/cudatoolkit-13_0.nix"
cudnn-13_0.pkg-path = ".flox/pkgs/cudnn-13_0.nix"
nccl-13_0.pkg-path = ".flox/pkgs/nccl-13_0.nix"
libcusparse_lt-13_0.pkg-path = ".flox/pkgs/libcusparse_lt-13_0.nix"
pytorch-python313-cuda13_0-sm121-armv9-nightly.pkg-path = ".flox/pkgs/pytorch-python313-cuda13_0-sm121-armv9-nightly.nix"
```

Then build:
```bash
flox build pytorch-python313-cuda13_0-sm121-armv9-nightly
```

---

## Step 3: Fix the PyTorch Source Hash

The first build will fail with an error like:
```
error: hash mismatch in fixed-output derivation
  got:    sha256-abc123def456...
```

Copy that hash and update `.flox/pkgs/pytorch-python313-cuda13_0-sm121-armv9-nightly.nix` line 72:
```nix
hash = "sha256-abc123def456...";  # Replace with actual hash
```

## Step 4: Rebuild

```bash
# Use whichever method you chose (A or B)
flox build pytorch-python313-cuda13_0-sm121-armv9-nightly-wrapper  # Option A (RECOMMENDED)
# OR
flox build pytorch-python313-cuda13_0-sm121-armv9-nightly  # Option B

# This will take 2-3 hours...
```

## Step 5: Test the Build

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

### "cudatoolkit-13_0 not found"
- Make sure you built the CUDA packages in step 1
- Check paths in the wrapper/prebuilt .nix files
- Try Option C (copy files locally)

### "hash mismatch"
- Expected on first build - copy the correct hash from error message
- Update line 72 in the main .nix file

### Build fails with "Unknown architecture sm_121"
- Check the build logs for "Patching CMake files to add SM121 support"
- Should see "✓ SM121 support added to cmake/..."
- If not, the patch didn't apply correctly

### Repos aren't siblings
Edit the wrapper's path on line 8:
```nix
cudaToolkitRepo = /absolute/path/to/build-cudatoolkit;
```

## My Recommendation

**Use Option A** (wrapper) - it's the proper Nix pattern and works great for both development and production.

Only use **Option B** (local copy) if you need the build to be completely self-contained in a single repository.

**❌ Don't use result symlinks** - they're not reproducible, can be garbage collected, and aren't suitable for sharing.

## After Successful Build

Publish to your Flox organization:
```bash
flox publish pytorch-python313-cuda13_0-sm121-armv9-nightly
```

Then teammates can install with:
```bash
flox install yourorg/pytorch-python313-cuda13_0-sm121-armv9-nightly
```
