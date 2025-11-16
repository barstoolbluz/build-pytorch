# SM90 and SM120 Support Issue

## Problem

PyTorch 2.8.0 in nixpkgs doesn't recognize SM90 or SM120 as valid CUDA architectures.

### Error
```
CMake Error: Found Unknown CUDA Architecture Name in CUDA_SELECT_NVCC_ARCH_FLAGS: sm_90
```

### Root Cause

PyTorch's `cmake/Modules_CUDA_fix/upstream/FindCUDA/select_compute_arch.cmake` maintains a hardcoded list of known architectures. SM90 (Hopper) and SM120 (Blackwell) are newer architectures that may not be in PyTorch 2.8.0's validation list.

## Timeline

- **SM90 (Hopper/H100)**: Added in PyTorch 2.0+ (March 2023)
- **SM120 (Blackwell/RTX 5090)**: Added in PyTorch 2.7+ (January 2025)

## Current Status

**nixpkgs PyTorch version**: 2.8.0 (should have SM90, but validation fails)

This suggests the nixpkgs version may be:
1. Using an older CMake validation script
2. Missing a patch for SM90/SM120 support
3. The `gpuTargets` parameter may not work as expected for newer architectures

## Possible Solutions

### Option 1: Use Supported Architectures (Immediate)
Build for SM86 (RTX 3090/A40) which is well-supported:
```nix
gpuTargets = [ "sm_86" ];
```

**Pros:**
- Will build successfully
- Verifies our CUDA configuration pattern works
- Can test on compatible hardware

**Cons:**
- Won't utilize SM90/SM120 features
- Suboptimal for H100/RTX 5090

### Option 2: Patch PyTorch's CMake Script
Add SM90 and SM120 to the known architectures list.

**File to patch**: `cmake/Modules_CUDA_fix/upstream/FindCUDA/select_compute_arch.cmake`

```nix
postPatch = ''
  # Add SM90 and SM120 to known architectures
  substituteInPlace cmake/Modules_CUDA_fix/upstream/FindCUDA/select_compute_arch.cmake \
    --replace '"8.0" "8.0(8.0)" "80"' '"8.0" "8.0(8.0)" "80" "9.0" "9.0(9.0)" "90" "12.0" "12.0(12.0)" "120"'
'';
```

**Pros:**
- Enables SM90/SM120 support
- Uses proper architecture features

**Cons:**
- Requires understanding PyTorch's CMake internals
- May need multiple patches
- Could break with PyTorch updates

### Option 3: Wait for nixpkgs Update
Wait for nixpkgs to update PyTorch to a version with proper SM90/SM120 support.

**Pros:**
- No patches needed
- Official support

**Cons:**
- Unknown timeline
- May take months

### Option 4: Use PyTorch Nightly/Unstable
Switch to PyTorch nightly builds which definitely have SM90/SM120 support.

**Pros:**
- Latest features and architecture support

**Cons:**
- Less stable
- Harder to integrate with nixpkgs
- More complex build process

## Recommended Approach

1. **Short term**: Build SM86 variant to verify CUDA configuration works
2. **Medium term**: Apply CMake patch for SM90/SM120 support
3. **Long term**: Monitor nixpkgs for PyTorch updates with native support

## Testing Strategy

### Phase 1: Verify Pattern with SM86
```bash
# Build SM86 variant (known to work)
flox build pytorch-python313-cuda12_8-sm86-avx2

# Test CUDA support
python -c "import torch; print(torch.cuda.get_arch_list())"
# Should show: ['sm_86']
```

### Phase 2: Add SM90/SM120 with Patch
Once SM86 works, apply patches to enable SM90/SM120.

## Hardware Compatibility Note

**Your RTX 5090 (SM120) can run binaries built for older architectures:**
- SM86 binary will work on RTX 5090 (backward compatible)
- Won't utilize SM120-specific features
- Performance will be good but not optimal

**For testing purposes:**
- SM86 build is sufficient to verify CUDA works
- Can upgrade to SM120 once we solve the CMake validation issue

## Next Steps

1. Update SM86 variant with corrected CUDA pattern
2. Build and test SM86 variant
3. If successful, document working pattern
4. Investigate CMake patches for SM90/SM120
