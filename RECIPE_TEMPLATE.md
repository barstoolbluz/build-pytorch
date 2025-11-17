# PyTorch Build Recipe Templates

This document provides **mechanical, copy-paste templates** for creating any PyTorch variant in the build matrix. Use these templates to generate `.nix` files for any combination of Python version, CUDA version, GPU architecture, and CPU ISA.

## Table of Contents

1. [Quick Reference](#quick-reference)
2. [GPU Build Template](#gpu-build-template)
3. [CPU Build Template](#cpu-build-template)
4. [Variable Lookup Tables](#variable-lookup-tables)
5. [Examples](#examples)

---

## Quick Reference

### File Naming Convention

**GPU builds:**
```
.flox/pkgs/pytorch-{PYTHON}-cuda{CUDA_MAJOR}_{CUDA_MINOR}-{GPU_ARCH}-{CPU_ISA}.nix
```

**CPU builds:**
```
.flox/pkgs/pytorch-{PYTHON}-cpu-{CPU_ISA}.nix
```

### Package Naming Convention

**GPU:** `pytorch-{PYTHON}-cuda{CUDA_MAJOR}_{CUDA_MINOR}-{GPU_ARCH}-{CPU_ISA}`
**CPU:** `pytorch-{PYTHON}-cpu-{CPU_ISA}`

---

## GPU Build Template

**File:** `.flox/pkgs/pytorch-{PYTHON}-cuda{CUDA_MAJOR}_{CUDA_MINOR}-{GPU_ARCH}-{CPU_ISA}.nix`

```nix
# PyTorch optimized for {GPU_DESC} + {CPU_ISA_DESC}
# Package name: pytorch-{PYTHON}-cuda{CUDA_MAJOR}_{CUDA_MINOR}-{GPU_ARCH}-{CPU_ISA}

{ {PYTHON_PACKAGES}
, lib
, config
, {CUDA_PACKAGES}
, addDriverRunpath
, openblas
}:

let
  # GPU target: {GPU_ARCH_UPPER} ({GPU_DESC})
  gpuArch = "{GPU_ARCH_UNDERSCORE}";

  # CPU optimization: {CPU_ISA_DESC}
  cpuFlags = [
    {CPU_FLAGS}
  ];

in {PYTHON_PACKAGES}.pytorch.overrideAttrs (oldAttrs: {
  pname = "pytorch-{PYTHON}-cuda{CUDA_MAJOR}_{CUDA_MINOR}-{GPU_ARCH}-{CPU_ISA}";

  # Enable CUDA support with specific GPU target
  passthru = oldAttrs.passthru // {
    inherit gpuArch;
  };

  # Override build configuration
  buildInputs = oldAttrs.buildInputs ++ [
    {CUDA_PACKAGES}.cuda_cudart
    {CUDA_PACKAGES}.libcublas
    {CUDA_PACKAGES}.libcufft
    {CUDA_PACKAGES}.libcurand
    {CUDA_PACKAGES}.libcusolver
    {CUDA_PACKAGES}.libcusparse
    {CUDA_PACKAGES}.cudnn
    # Explicitly add dynamic OpenBLAS for host-side operations
    (openblas.override {
      blas64 = false;
      singleThreaded = false;
    })
  ];

  nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
    addDriverRunpath
  ];

  # Set CUDA architecture and CPU optimization flags
  preConfigure = (oldAttrs.preConfigure or "") + ''
    export TORCH_CUDA_ARCH_LIST="${gpuArch}"
    export TORCH_NVCC_FLAGS="-Xfatbin -compress-all"

    # CPU optimizations via compiler flags
    export CXXFLAGS="$CXXFLAGS ${lib.concatStringsSep " " cpuFlags}"
    export CFLAGS="$CFLAGS ${lib.concatStringsSep " " cpuFlags}"

    # Enable cuBLAS
    export USE_CUBLAS=1
    export USE_CUDA=1

    # Optimize for target architecture
    export CMAKE_CUDA_ARCHITECTURES="${lib.removePrefix "sm_" gpuArch}"

    echo "========================================="
    echo "PyTorch Build Configuration"
    echo "========================================="
    echo "GPU Target: ${gpuArch} ({GPU_DESC})"
    echo "CPU Features: {CPU_ISA_DESC}"
    echo "CUDA: Enabled with cuBLAS"
    echo "TORCH_CUDA_ARCH_LIST: $TORCH_CUDA_ARCH_LIST"
    echo "CXXFLAGS: $CXXFLAGS"
    echo "========================================="
  '';

  meta = oldAttrs.meta // {
    description = "PyTorch optimized for {GPU_DESC} with {CPU_ISA_DESC}";
    longDescription = ''
      Custom PyTorch build with targeted optimizations:
      - GPU: {GPU_DESC}
      - CPU: {CPU_ISA_DESC}
      - CUDA: {CUDA_VERSION}
      - BLAS: cuBLAS for GPU operations, OpenBLAS for host-side
      - Python: {PYTHON_VERSION}
    '';
    platforms = [ "{PLATFORM}" ];
  };
})
```

---

## CPU Build Template

**File:** `.flox/pkgs/pytorch-{PYTHON}-cpu-{CPU_ISA}.nix`

```nix
# PyTorch CPU-only optimized for {CPU_ISA_DESC}
# Package name: pytorch-{PYTHON}-cpu-{CPU_ISA}

{ {PYTHON_PACKAGES}
, lib
, openblas
, mkl
}:

let
  # CPU optimization: {CPU_ISA_DESC} (no GPU)
  cpuFlags = [
    {CPU_FLAGS}
  ];

  # Use OpenBLAS for CPU linear algebra
  blasBackend = openblas;

in {PYTHON_PACKAGES}.pytorch.overrideAttrs (oldAttrs: {
  pname = "pytorch-{PYTHON}-cpu-{CPU_ISA}";

  # Disable CUDA support for CPU-only build
  passthru = oldAttrs.passthru // {
    gpuArch = null;
    blasProvider = "openblas";
  };

  # Override build configuration - remove CUDA deps, ensure BLAS
  buildInputs = lib.filter (p: !(lib.hasPrefix "cuda" (p.pname or ""))) oldAttrs.buildInputs ++ [
    blasBackend
  ];

  nativeBuildInputs = lib.filter (p: p.pname or "" != "addDriverRunpath") oldAttrs.nativeBuildInputs;

  # Set CPU optimization flags and disable CUDA
  preConfigure = (oldAttrs.preConfigure or "") + ''
    # Disable CUDA
    export USE_CUDA=0
    export USE_CUDNN=0
    export USE_CUBLAS=0

    # Use OpenBLAS for CPU operations
    export BLAS=OpenBLAS
    export USE_MKLDNN=1
    export USE_MKLDNN_CBLAS=1

    # CPU optimizations via compiler flags
    export CXXFLAGS="$CXXFLAGS ${lib.concatStringsSep " " cpuFlags}"
    export CFLAGS="$CFLAGS ${lib.concatStringsSep " " cpuFlags}"

    # Optimize for host CPU
    export CMAKE_BUILD_TYPE=Release

    echo "========================================="
    echo "PyTorch Build Configuration"
    echo "========================================="
    echo "GPU Target: None (CPU-only build)"
    echo "CPU Features: {CPU_ISA_DESC}"
    echo "BLAS Backend: OpenBLAS"
    echo "CUDA: Disabled"
    echo "CXXFLAGS: $CXXFLAGS"
    echo "========================================="
  '';

  meta = oldAttrs.meta // {
    description = "PyTorch CPU-only build optimized for {CPU_ISA_DESC}";
    longDescription = ''
      Custom PyTorch build for CPU-only workloads:
      - GPU: None (CPU-only)
      - CPU: {CPU_ISA_DESC}
      - BLAS: OpenBLAS for CPU linear algebra operations
      - Python: {PYTHON_VERSION}

      This build is suitable for inference, development, and workloads
      that don't require GPU acceleration.
    '';
    platforms = [ "{PLATFORMS}" ];
  };
})
```

---

## Variable Lookup Tables

### Python Versions

| Variable | {PYTHON} | {PYTHON_PACKAGES} | {PYTHON_VERSION} |
|----------|----------|-------------------|------------------|
| Python 3.13 | `python313` | `python313Packages` or `python3Packages` | `3.13` |
| Python 3.12 | `python312` | `python312Packages` | `3.12` |
| Python 3.11 | `python311` | `python311Packages` | `3.11` |

### CUDA Versions

| Variable | {CUDA_MAJOR}_{CUDA_MINOR} | {CUDA_PACKAGES} | {CUDA_VERSION} | Available? |
|----------|---------------------------|-----------------|----------------|------------|
| CUDA 12.8 | `12_8` | `cudaPackages_12_8` or `cudaPackages` | `12.8` | ✅ Yes (default) |
| CUDA 12.9 | `12_9` | `cudaPackages_12_9` | `12.9` | ✅ Yes |
| CUDA 12.6 | `12_6` | `cudaPackages_12_6` | `12.6` | ✅ Yes |
| CUDA 12.4 | `12_4` | `cudaPackages_12_4` | `12.4` | ✅ Yes |
| CUDA 13.0 | `13_0` | `cudaPackages_13_0` | `13.0` | ❌ Not in nixpkgs yet |

**Note:** `cudaPackages` (no version) is an alias for `cudaPackages_12_8` (current default).

### GPU Architectures

| Variable | {GPU_ARCH} | {GPU_ARCH_UNDERSCORE} | {GPU_ARCH_UPPER} | {GPU_DESC} | {PLATFORM} |
|----------|------------|----------------------|------------------|------------|------------|
| SM121 | `sm121` | `sm_121` | `SM121` | `NVIDIA DGX Spark (Specialized Datacenter)` | `x86_64-linux` |
| SM120 | `sm120` | `sm_120` | `SM120` | `NVIDIA Blackwell (RTX 5090)` | `x86_64-linux` |
| SM110 | `sm110` | `sm_110` | `SM110` | `NVIDIA DRIVE Thor, Orin+ (Automotive)` | `x86_64-linux` |
| SM103 | `sm103` | `sm_103` | `SM103` | `NVIDIA Blackwell B300 (Datacenter)` | `x86_64-linux` |
| SM100 | `sm100` | `sm_100` | `SM100` | `NVIDIA Blackwell B100/B200 (Datacenter)` | `x86_64-linux` |
| SM90 | `sm90` | `sm_90` | `SM90` | `NVIDIA Hopper (H100, L40S)` | `x86_64-linux` |
| SM89 | `sm89` | `sm_89` | `SM89` | `NVIDIA Ada Lovelace (RTX 4090, L40)` | `x86_64-linux` |
| SM86 | `sm86` | `sm_86` | `SM86` | `NVIDIA Ampere (RTX 3090, A40, A5000)` | `x86_64-linux` |
| SM80 | `sm80` | `sm_80` | `SM80` | `NVIDIA Ampere Datacenter (A100, A30)` | `x86_64-linux` |
| SM75 | `sm75` | `sm_75` | `SM75` | `NVIDIA Turing (T4, RTX 20xx)` | `x86_64-linux` |

### CPU ISA (x86-64)

| Variable | {CPU_ISA} | {CPU_ISA_DESC} | {CPU_FLAGS} | {PLATFORM} |
|----------|-----------|----------------|-------------|------------|
| AVX-512 BF16 | `avx512bf16` | `AVX-512 with BF16` | `"-mavx512f"    "-mavx512dq"   "-mavx512vl"   "-mavx512bw"   "-mavx512bf16" "-mfma"` | `x86_64-linux` |
| AVX-512 VNNI | `avx512vnni` | `AVX-512 with VNNI` | `"-mavx512f"    "-mavx512dq"   "-mavx512vl"   "-mavx512bw"   "-mavx512vnni" "-mfma"` | `x86_64-linux` |
| AVX-512 | `avx512` | `AVX-512` | `"-mavx512f"    "-mavx512dq"   "-mavx512vl"   "-mavx512bw"   "-mfma"` | `x86_64-linux` |
| AVX2 | `avx2` | `AVX2` | `"-mavx2"       "-mfma"        "-mf16c"` | `x86_64-linux` |

### CPU ISA (ARM)

| Variable | {CPU_ISA} | {CPU_ISA_DESC} | {CPU_FLAGS} | {PLATFORM} |
|----------|-----------|----------------|-------------|------------|
| ARMv9 | `armv9` | `ARMv9-A with SVE2` | `"-march=armv9-a+sve+sve2"` | `aarch64-linux` |
| ARMv8.2 | `armv8.2` | `ARMv8.2-A` | `"-march=armv8.2-a+fp16+dotprod"` | `aarch64-linux` |

### Platform Combinations

| Build Type | CPU ISA | {PLATFORM} | {PLATFORMS} (CPU builds) |
|------------|---------|------------|--------------------------|
| GPU x86-64 | avx*, any x86 | `x86_64-linux` | N/A |
| GPU ARM | armv9, armv8.2 | `aarch64-linux` | N/A |
| CPU x86-64 | avx*, any x86 | N/A | `x86_64-linux` or both |
| CPU ARM | armv9, armv8.2 | N/A | `aarch64-linux` or both |

**Recommendation for CPU builds:** Use `[ "x86_64-linux" "aarch64-linux" ]` for maximum compatibility unless ISA is architecture-specific.

---

## Examples

### Example 1: RTX 5090 with AVX-512, Python 3.13, CUDA 12.8

**File:** `.flox/pkgs/pytorch-python313-cuda12_8-sm120-avx512.nix`

**Substitutions:**
- `{PYTHON}` → `python313`
- `{PYTHON_PACKAGES}` → `python3Packages` (or `python313Packages`)
- `{PYTHON_VERSION}` → `3.13`
- `{CUDA_MAJOR}_{CUDA_MINOR}` → `12_8`
- `{CUDA_PACKAGES}` → `cudaPackages` (or `cudaPackages_12_8`)
- `{CUDA_VERSION}` → `12.8`
- `{GPU_ARCH}` → `sm120`
- `{GPU_ARCH_UNDERSCORE}` → `sm_120`
- `{GPU_ARCH_UPPER}` → `SM120`
- `{GPU_DESC}` → `NVIDIA Blackwell (RTX 5090)`
- `{CPU_ISA}` → `avx512`
- `{CPU_ISA_DESC}` → `AVX-512`
- `{CPU_FLAGS}` → `"-mavx512f"    "-mavx512dq"   "-mavx512vl"   "-mavx512bw"   "-mfma"`
- `{PLATFORM}` → `x86_64-linux`

**Result:** Already exists! (See `.flox/pkgs/pytorch-python313-cuda12_8-sm120-avx512.nix`)

---

### Example 2: RTX 3090 with AVX2, Python 3.12, CUDA 12.8

**File:** `.flox/pkgs/pytorch-python312-cuda12_8-sm86-avx2.nix`

**Substitutions:**
- `{PYTHON}` → `python312`
- `{PYTHON_PACKAGES}` → `python312Packages`
- `{PYTHON_VERSION}` → `3.12`
- `{CUDA_MAJOR}_{CUDA_MINOR}` → `12_8`
- `{CUDA_PACKAGES}` → `cudaPackages_12_8`
- `{CUDA_VERSION}` → `12.8`
- `{GPU_ARCH}` → `sm86`
- `{GPU_ARCH_UNDERSCORE}` → `sm_86`
- `{GPU_ARCH_UPPER}` → `SM86`
- `{GPU_DESC}` → `NVIDIA Ampere (RTX 3090, A40)`
- `{CPU_ISA}` → `avx2`
- `{CPU_ISA_DESC}` → `AVX2`
- `{CPU_FLAGS}` → `"-mavx2"       "-mfma"        "-mf16c"`
- `{PLATFORM}` → `x86_64-linux`

---

### Example 3: CPU-only AVX2, Python 3.11

**File:** `.flox/pkgs/pytorch-python311-cpu-avx2.nix`

**Substitutions:**
- `{PYTHON}` → `python311`
- `{PYTHON_PACKAGES}` → `python311Packages`
- `{PYTHON_VERSION}` → `3.11`
- `{CPU_ISA}` → `avx2`
- `{CPU_ISA_DESC}` → `AVX2`
- `{CPU_FLAGS}` → `"-mavx2"       "-mfma"        "-mf16c"`
- `{PLATFORMS}` → `"x86_64-linux" "aarch64-linux"` (both for compatibility)

---

## Generation Workflow

To create a new variant:

1. **Determine dimensions:**
   - Python version: 311, 312, or 313?
   - GPU architecture: sm120, sm90, sm86, etc., or CPU?
   - CPU ISA: avx512, avx2, armv9, etc.?
   - CUDA version (GPU only): 12_8, 12_9, etc.?

2. **Look up variables** from the tables above

3. **Copy the appropriate template** (GPU or CPU)

4. **Find-and-replace** all `{VARIABLE}` placeholders

5. **Save** with the correct filename

6. **Commit** to git:
   ```bash
   git add .flox/pkgs/pytorch-{name}.nix
   git commit -m "Add {description}"
   ```

7. **Build** (optional, takes 1-3 hours):
   ```bash
   flox build {package-name}
   ```

8. **Publish** (after successful build):
   ```bash
   flox publish -o <your-org> {package-name}
   ```

---

## Notes

- All GPU builds include OpenBLAS for host-side operations (nixpkgs default uses DYNAMIC_ARCH=1)
- CUDA 13.0 is not available in nixpkgs yet (as of 2025-11-14)
- Default `cudaPackages` points to CUDA 12.8
- Default `python3Packages` points to Python 3.13
- ARM GPU builds should use `platforms = [ "aarch64-linux" ]`
- x86-64 GPU builds should use `platforms = [ "x86_64-linux" ]`
- CPU-only builds can use both platforms for maximum compatibility
