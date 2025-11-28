# Building PyTorch Nightly for DGX Spark (SM121) with CUDA 13.0

This guide explains how to build PyTorch nightly with CUDA 13.0 support for NVIDIA DGX Spark (SM121).

## Prerequisites

1. **CUDA 13.0 Packages** - Built from `https://github.com/barstoolbluz/build-cudatoolkit/`
   - `cudatoolkit-13_0` (v13.0.88)
   - `cudnn-13_0` (v9.13.0.50)
   - `nccl-13_0` (v2.28.7-1)
   - `libcusparse_lt-13_0` (v0.8.1.1)

2. **Hardware**
   - NVIDIA DGX Spark (GB10 GPU) or other SM121 hardware
   - ARM64 system with ARMv9 + SVE2 support (NVIDIA Grace, Graviton3+, etc.)
   - NVIDIA Driver 570+

## Step 1: Clone or Access CUDA 13.0 Build Repository

```bash
# On your build system
cd ~/dev/builds
git clone https://github.com/barstoolbluz/build-cudatoolkit.git
cd build-cudatoolkit
```

## Step 2: Build CUDA 13.0 Packages (if not already built)

```bash
cd build-cudatoolkit
flox activate

# Build all CUDA 13.0 components
flox build cudatoolkit-13_0
flox build cudnn-13_0
flox build nccl-13_0
flox build libcusparse_lt-13_0
```

After building, you'll have results in:
- `./result-cudatoolkit-13_0/`
- `./result-cudnn-13_0/`
- `./result-nccl-13_0/`
- `./result-libcusparse_lt-13_0/`

## Step 3: Update PyTorch Source Hash

The PyTorch nightly build needs a valid source hash. On first build it will fail and tell you the correct hash.

```bash
cd ~/dev/builds/build-pytorch
flox activate

# Try to build - it will fail with the correct hash
flox build pytorch-python313-cuda13_0-sm121-armv9-nightly 2>&1 | grep "got:"

# Example output:
#   got:    sha256-abc123def456...

# Copy that hash and update line 72 in the .nix file:
# .flox/pkgs/pytorch-python313-cuda13_0-sm121-armv9-nightly.nix
```

Edit line 72:
```nix
hash = "sha256-abc123def456...";  # Replace with actual hash from error
```

## Step 4: Build PyTorch with CUDA 13.0 Dependencies

### Recommended: Use the Wrapper (Proper Nix Pattern)

A wrapper expression is provided that automatically imports the CUDA packages from your build-cudatoolkit repo:

**File:** `.flox/pkgs/pytorch-python313-cuda13_0-sm121-armv9-nightly-wrapper.nix`

This wrapper:
- Imports CUDA 13.0 .nix expressions from the sibling repo
- Passes them as inputs to the PyTorch build
- Builds everything from source (reproducible)
- Works for development and production

Build with:
```bash
cd ~/dev/builds/build-pytorch
flox activate

# Build using the wrapper
flox build pytorch-python313-cuda13_0-sm121-armv9-nightly-wrapper
```

**Adjust paths if needed:**
If your repos aren't in the standard layout (`~/dev/builds/build-cudatoolkit` and `~/dev/builds/build-pytorch`), edit line 8 of the wrapper:

```nix
cudaToolkitRepo = ../../build-cudatoolkit;  # Adjust to match your directory structure
```

### Alternative: Copy CUDA Packages Locally

If you want everything self-contained in one repository:

```bash
cd ~/dev/builds/build-pytorch

# Copy CUDA 13.0 package definitions
cp ../build-cudatoolkit/.flox/pkgs/cudatoolkit-13_0.nix .flox/pkgs/
cp ../build-cudatoolkit/.flox/pkgs/cudnn-13_0.nix .flox/pkgs/
cp ../build-cudatoolkit/.flox/pkgs/nccl-13_0.nix .flox/pkgs/
cp ../build-cudatoolkit/.flox/pkgs/libcusparse_lt-13_0.nix .flox/pkgs/

# Add to manifest
flox edit
```

In `.flox/env/manifest.toml`, add:
```toml
[build.packages]
cudatoolkit-13_0.pkg-path = ".flox/pkgs/cudatoolkit-13_0.nix"
cudnn-13_0.pkg-path = ".flox/pkgs/cudnn-13_0.nix"
nccl-13_0.pkg-path = ".flox/pkgs/nccl-13_0.nix"
libcusparse_lt-13_0.pkg-path = ".flox/pkgs/libcusparse_lt-13_0.nix"
pytorch-python313-cuda13_0-sm121-armv9-nightly.pkg-path = ".flox/pkgs/pytorch-python313-cuda13_0-sm121-armv9-nightly.nix"
```

Then:
```bash
flox build pytorch-python313-cuda13_0-sm121-armv9-nightly
```

**⚠️ Anti-Pattern to Avoid:**
Do NOT use result symlinks (e.g., `result-cudatoolkit-13_0`) as package inputs. They are:
- Not reproducible (mutable, can change)
- Subject to garbage collection
- Not suitable for sharing/publishing
- Against Nix best practices

## Step 5: Start the Build

```bash
cd ~/dev/builds/build-pytorch
flox activate

# This will take 1-3 hours on a multi-core ARM system
flox build pytorch-python313-cuda13_0-sm121-armv9-nightly

# Or with explicit parallelism:
NIX_BUILD_CORES=16 flox build pytorch-python313-cuda13_0-sm121-armv9-nightly
```

## Step 6: Verify the Build

```bash
# Check the result
ls -lh result-pytorch-python313-cuda13_0-sm121-armv9-nightly/

# Test the build
./result-pytorch-python313-cuda13_0-sm121-armv9-nightly/bin/python -c "
import torch
print(f'PyTorch version: {torch.__version__}')
print(f'CUDA available: {torch.cuda.is_available()}')
print(f'CUDA version: {torch.version.cuda}')
if torch.cuda.is_available():
    print(f'GPU: {torch.cuda.get_device_name(0)}')
    print(f'Compute capability: {torch.cuda.get_device_capability(0)}')
"
```

Expected output:
```
PyTorch version: 2.9.0+...
CUDA available: True
CUDA version: 13.0
GPU: NVIDIA DGX Spark
Compute capability: (12, 1)
```

## Troubleshooting

### Issue: "cudatoolkit-13_0 not found"
**Solution**: Ensure you've built the CUDA packages or update paths in the .nix file

### Issue: "Unknown CUDA Architecture Name: sm_121"
**Solution**: The CMake patch didn't apply. Check `postPatch` output in build logs

### Issue: Build fails with Triton errors
**Solution**: This is a known issue with CUDA 13.0 + sm_121a. The build should continue past Triton errors for core PyTorch functionality.

### Issue: Flash Attention compilation fails
**Solution**: Expected with CUDA 13.0. Flash Attention support is not yet stable.

## Known Limitations

- **Flash Attention**: May not work with CUDA 13.0 / SM121
- **Triton**: Compilation errors with sm_121a (GPU name incompatibility)
- **FP8 Kernels**: May fall back to slower legacy implementations
- **Ecosystem**: Many PyTorch extensions expect CUDA 12.x

## Build Time Estimates

- CUDA 13.0 packages: ~30 minutes (if rebuilding)
- PyTorch nightly: ~2-3 hours on 16-core ARM system
- Total: ~3-4 hours for complete stack

## Next Steps

After successful build:

1. **Test thoroughly** with your workloads
2. **Report issues** to PyTorch GitHub if you find SM121-specific bugs
3. **Publish to Flox** once validated:
   ```bash
   flox publish pytorch-python313-cuda13_0-sm121-armv9-nightly
   ```

## References

- PyTorch GitHub: https://github.com/pytorch/pytorch
- CUDA 13.0 Packages: https://github.com/barstoolbluz/build-cudatoolkit/
- DGX Spark Forums: https://forums.developer.nvidia.com/c/accelerated-computing/dgx-spark/
- PyTorch SM121 Tracking: https://discuss.pytorch.org/t/dgx-spark-gb10-cuda-13-0-python-3-12-sm-121/223744
