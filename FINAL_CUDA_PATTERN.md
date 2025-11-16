# Final CUDA Configuration Pattern

## The Working Solution

After several iterations, the correct approach is to use **nixpkgs' native `gpuTargets` parameter** instead of manually overriding CMAKE variables.

### Complete Working Pattern

```nix
{ python3Packages
, lib
, config
, cudaPackages
, addDriverRunpath
}:

let
  # GPU target
  gpuArchNum = "90";     # For reference (not directly used)
  gpuArchSM = "sm_90";   # For gpuTargets parameter

  # CPU optimization flags
  cpuFlags = [
    "-mavx512f"
    "-mavx512dq"
    "-mavx512vl"
    "-mavx512bw"
    "-mfma"
  ];

in
  # Two-stage override:
  # 1. Enable CUDA and specify GPU targets
  (python3Packages.pytorch.override {
    cudaSupport = true;
    gpuTargets = [ gpuArchSM ];  # This is the key!
  # 2. Customize build (CPU flags, metadata, etc.)
  }).overrideAttrs (oldAttrs: {
    pname = "pytorch-python313-cuda12_8-sm90-avx512";

    preConfigure = (oldAttrs.preConfigure or "") + ''
      # Only set CPU optimizations
      # GPU architecture is handled by gpuTargets parameter
      export CXXFLAGS="$CXXFLAGS ${lib.concatStringsSep " " cpuFlags}"
      export CFLAGS="$CFLAGS ${lib.concatStringsSep " " cpuFlags}"

      echo "========================================="
      echo "PyTorch Build Configuration"
      echo "========================================="
      echo "GPU Target: ${gpuArchSM}"
      echo "CPU Features: AVX-512"
      echo "CUDA: Enabled via nixpkgs"
      echo "========================================="
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch optimized for SM90 with AVX-512";
      platforms = [ "x86_64-linux" ];
    };
  })
```

## Why This Works

1. **nixpkgs handles CUDA configuration:**
   - `cudaSupport = true` → Enables CUDA in the derivation
   - `gpuTargets = [ "sm_90" ]` → Sets the correct GPU architecture
   - nixpkgs internally manages all CMAKE variables correctly

2. **No manual CMAKE variable overrides needed:**
   - ❌ Don't set `TORCH_CUDA_ARCH_LIST`
   - ❌ Don't set `CMAKE_CUDA_ARCHITECTURES`
   - ✅ Use `gpuTargets` parameter instead

3. **CPU optimizations are independent:**
   - We only override `CXXFLAGS` and `CFLAGS` for CPU
   - These don't interfere with CUDA configuration

## GPU Architecture Values for `gpuTargets`

| GPU Model | Compute Cap | gpuTargets Value |
|-----------|-------------|------------------|
| RTX 5090 | SM120 | `["sm_120"]` |
| H100, L40S | SM90 | `["sm_90"]` |
| RTX 4090, L4 | SM89 | `["sm_89"]` |
| RTX 3090, A40 | SM86 | `["sm_86"]` |
| A100 | SM80 | `["sm_80"]` |

**Note:** `gpuTargets` is a list, so you can build for multiple architectures:
```nix
gpuTargets = [ "sm_80" "sm_86" "sm_90" ];  # Multi-GPU support
```

But for our use case, we want **single-architecture builds** for maximum optimization.

## What Changed from Previous Attempts

### Attempt 1 (Failed): Using only `.overrideAttrs`
- ❌ Didn't enable CUDA at derivation level
- Result: CPU-only build

### Attempt 2 (Failed): Manual CMAKE variables
- ❌ Tried to override `TORCH_CUDA_ARCH_LIST` and `CMAKE_CUDA_ARCHITECTURES`
- ❌ PyTorch's CMake scripts didn't recognize the architecture
- Result: "Unknown CUDA Architecture" errors

### Attempt 3 (Success): Using `gpuTargets`
- ✅ Let nixpkgs handle CUDA configuration
- ✅ Use `gpuTargets` parameter in `.override`
- ✅ Only customize CPU flags in `.overrideAttrs`
- Result: Clean build with CUDA support

## Testing

After building:
```bash
flox build pytorch-python313-cuda12_8-sm90-avx512
```

Verify CUDA support:
```python
import torch
print(f"CUDA available: {torch.cuda.is_available()}")
print(f"CUDA version: {torch.version.cuda}")
print(f"Arch list: {torch.cuda.get_arch_list()}")
```

Expected output:
```
CUDA available: True
CUDA version: 12.8
Arch list: ['sm_90']
```

## Applying to Other Variants

For each GPU variant, simply change:
```nix
gpuArchSM = "sm_XX";  # sm_120, sm_90, sm_86, etc.
```

And ensure:
```nix
gpuTargets = [ gpuArchSM ];
```

That's it! No other changes needed.
