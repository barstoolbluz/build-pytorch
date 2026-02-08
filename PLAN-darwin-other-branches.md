# Plan: Add Darwin Variants to cuda-12_9 and cuda-13_0 Branches

## Summary

Add macOS (Darwin) support to the `cuda-12_9` and `cuda-13_0` branches with:
- **`pytorch-python313-darwin-mps`** for Apple Silicon (M1/M2/M3/M4) with Metal GPU acceleration
- **`pytorch-python313-darwin-x86`** for Intel Macs (CPU-only)

## Naming Convention

| Variant | pname | File | Platform |
|---------|-------|------|----------|
| MPS (Apple Silicon) | `pytorch-python313-darwin-mps` | `pytorch-python313-darwin-mps.nix` | aarch64-darwin |
| CPU (Intel Mac) | `pytorch-python313-darwin-x86` | `pytorch-python313-darwin-x86.nix` | x86_64-darwin |

Nix appends version automatically (e.g., `pytorch-python313-darwin-mps-2.10.0`).

## Current State

| Branch | PyTorch | Current Variants | After Darwin |
|--------|---------|------------------|--------------|
| `main` | 2.8.0 | 46 | ✅ Done |
| `cuda-12_9` | 2.9.1 | 57 | → 59 |
| `cuda-13_0` | 2.10.0 | 59 | → 61 |

## ⚠️ CRITICAL: Branch Pattern Differences

| Branch | Pattern | PyTorch Source |
|--------|---------|----------------|
| `main` | Direct Flox `python3Packages.pytorch` | nixpkgs version |
| `cuda-12_9` | Pinned nixpkgs `nixpkgs_pinned.python3Packages.torch` | nixpkgs version |
| `cuda-13_0` | Pinned nixpkgs + **overlay** to build 2.10.0 from source | GitHub fetch |

---

## Branch: cuda-12_9 (Simple Pinned Pattern)

### Nixpkgs Pin
```
https://github.com/NixOS/nixpkgs/archive/6a030d535719c5190187c4cec156f335e95e3211.tar.gz
```

### Files to Create/Modify

| File | Action |
|------|--------|
| `.flox/env/manifest.toml` | Edit - add darwin systems |
| `.flox/pkgs/pytorch-python313-darwin-mps.nix` | Create |
| `.flox/pkgs/pytorch-python313-darwin-x86.nix` | Create |
| `README.md` | Edit - update counts (57→59), add Darwin section |

### pytorch-python313-darwin-mps.nix (cuda-12_9)

```nix
# PyTorch with MPS (Metal Performance Shaders) for Apple Silicon
# Package name: pytorch-python313-darwin-mps
#
# macOS build for Apple Silicon (M1/M2/M3/M4) with Metal GPU acceleration
# Hardware: Apple M1, M2, M3, M4 and variants (Pro, Max, Ultra)
# Requires: macOS 12.3+

{ pkgs ? import <nixpkgs> {} }:

let
  nixpkgs_pinned = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/6a030d535719c5190187c4cec156f335e95e3211.tar.gz";
  }) {
    config = { allowUnfree = true; };
  };

  darwinFrameworks = with nixpkgs_pinned.darwin.apple_sdk.frameworks; [
    Accelerate
    Metal
    MetalPerformanceShaders
    MetalPerformanceShadersGraph
    CoreML
  ];

in nixpkgs_pinned.python3Packages.torch.overrideAttrs (oldAttrs: {
  pname = "pytorch-python313-darwin-mps";

  passthru = oldAttrs.passthru // {
    gpuArch = "mps";
    blasProvider = "accelerate";
  };

  buildInputs = nixpkgs_pinned.lib.filter (p: !(nixpkgs_pinned.lib.hasPrefix "cuda" (p.pname or "")))
    (oldAttrs.buildInputs or []) ++ darwinFrameworks;

  nativeBuildInputs = nixpkgs_pinned.lib.filter (p: p.pname or "" != "addDriverRunpath")
    (oldAttrs.nativeBuildInputs or []);

  preConfigure = (oldAttrs.preConfigure or "") + ''
    export USE_CUDA=0
    export USE_CUDNN=0
    export USE_CUBLAS=0
    export USE_MPS=1
    export USE_METAL=1
    export BLAS=Accelerate

    echo "========================================="
    echo "PyTorch Build Configuration"
    echo "========================================="
    echo "GPU Target: MPS (Metal Performance Shaders)"
    echo "Platform: Apple Silicon (aarch64-darwin)"
    echo "BLAS Backend: Apple Accelerate"
    echo "========================================="
  '';

  meta = oldAttrs.meta // {
    description = "PyTorch with MPS GPU acceleration for Apple Silicon";
    platforms = [ "aarch64-darwin" ];
  };
})
```

### pytorch-python313-darwin-x86.nix (cuda-12_9)

```nix
# PyTorch CPU-only for Intel Mac
# Package name: pytorch-python313-darwin-x86
#
# macOS build for Intel-based Macs (x86_64)
# Hardware: Intel Core i5/i7/i9, Xeon Mac Pro

{ pkgs ? import <nixpkgs> {} }:

let
  nixpkgs_pinned = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/6a030d535719c5190187c4cec156f335e95e3211.tar.gz";
  }) {
    config = { allowUnfree = true; };
  };

  darwinFrameworks = with nixpkgs_pinned.darwin.apple_sdk.frameworks; [
    Accelerate
  ];

  cpuFlags = [ "-mavx2" "-mfma" "-mf16c" ];

in nixpkgs_pinned.python3Packages.torch.overrideAttrs (oldAttrs: {
  pname = "pytorch-python313-darwin-x86";

  passthru = oldAttrs.passthru // {
    gpuArch = null;
    blasProvider = "accelerate";
  };

  buildInputs = nixpkgs_pinned.lib.filter (p: !(nixpkgs_pinned.lib.hasPrefix "cuda" (p.pname or "")))
    (oldAttrs.buildInputs or []) ++ darwinFrameworks;

  nativeBuildInputs = nixpkgs_pinned.lib.filter (p: p.pname or "" != "addDriverRunpath")
    (oldAttrs.nativeBuildInputs or []);

  preConfigure = (oldAttrs.preConfigure or "") + ''
    export USE_CUDA=0
    export USE_CUDNN=0
    export USE_CUBLAS=0
    export USE_MPS=0
    export BLAS=Accelerate
    export USE_MKLDNN=1

    export CXXFLAGS="${nixpkgs_pinned.lib.concatStringsSep " " cpuFlags} $CXXFLAGS"
    export CFLAGS="${nixpkgs_pinned.lib.concatStringsSep " " cpuFlags} $CFLAGS"

    echo "========================================="
    echo "PyTorch Build Configuration"
    echo "========================================="
    echo "GPU Target: None (CPU-only build)"
    echo "Platform: Intel Mac (x86_64-darwin)"
    echo "CPU Features: AVX2"
    echo "BLAS Backend: Apple Accelerate"
    echo "========================================="
  '';

  meta = oldAttrs.meta // {
    description = "PyTorch CPU-only for Intel Mac";
    platforms = [ "x86_64-darwin" ];
  };
})
```

---

## Branch: cuda-13_0 (Overlay Pattern - PyTorch 2.10.0 from source)

### Nixpkgs Pin
```
https://github.com/NixOS/nixpkgs/archive/6a030d535719c5190187c4cec156f335e95e3211.tar.gz
```

### Key Differences from cuda-12_9
- Uses `allowBroken = true`
- Uses overlay to build PyTorch 2.10.0 from GitHub source
- Uses two-stage: `.override { cudaSupport = false; }` then `.overrideAttrs`
- Has `cmakeFlags` for version and `patches = []`

### Files to Create/Modify

| File | Action |
|------|--------|
| `.flox/env/manifest.toml` | Edit - add darwin systems |
| `.flox/pkgs/pytorch-python313-darwin-mps.nix` | Create |
| `.flox/pkgs/pytorch-python313-darwin-x86.nix` | Create |
| `README.md` | Edit - update counts (59→61), add Darwin section |

### pytorch-python313-darwin-mps.nix (cuda-13_0)

```nix
# PyTorch 2.10.0 with MPS (Metal Performance Shaders) for Apple Silicon
# Package name: pytorch-python313-darwin-mps
#
# macOS build for Apple Silicon (M1/M2/M3/M4) with Metal GPU acceleration
# Hardware: Apple M1, M2, M3, M4 and variants (Pro, Max, Ultra)
# Requires: macOS 12.3+

{ pkgs ? import <nixpkgs> {} }:

let
  nixpkgs_pinned = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/6a030d535719c5190187c4cec156f335e95e3211.tar.gz";
  }) {
    config = { allowUnfree = true; allowBroken = true; };
    overlays = [
      (final: prev: {
        python3Packages = prev.python3Packages.override {
          overrides = pfinal: pprev: {
            torch = pprev.torch.overrideAttrs (oldAttrs: rec {
              version = "2.10.0";
              src = prev.fetchFromGitHub {
                owner = "pytorch";
                repo = "pytorch";
                rev = "v${version}";
                hash = "sha256-RKiZLHBCneMtZKRgTEuW1K7+Jpi+tx11BMXuS1jC1xQ=";
                fetchSubmodules = true;
              };
              patches = [];
            });
          };
        };
      })
    ];
  };

  darwinFrameworks = with nixpkgs_pinned.darwin.apple_sdk.frameworks; [
    Accelerate
    Metal
    MetalPerformanceShaders
    MetalPerformanceShadersGraph
    CoreML
  ];

in
  (nixpkgs_pinned.python3Packages.torch.override {
    cudaSupport = false;
  }).overrideAttrs (oldAttrs: {
    pname = "pytorch-python313-darwin-mps";
    patches = [];

    buildInputs = nixpkgs_pinned.lib.filter (p: !(nixpkgs_pinned.lib.hasPrefix "cuda" (p.pname or "")))
      (oldAttrs.buildInputs or []) ++ darwinFrameworks;

    nativeBuildInputs = nixpkgs_pinned.lib.filter (p: p.pname or "" != "addDriverRunpath")
      (oldAttrs.nativeBuildInputs or []);

    cmakeFlags = (oldAttrs.cmakeFlags or []) ++ [
      "-DTORCH_BUILD_VERSION=2.10.0"
      "-DUSE_CUDA=OFF"
    ];

    preConfigure = (oldAttrs.preConfigure or "") + ''
      export USE_CUDA=0
      export USE_CUDNN=0
      export USE_CUBLAS=0
      export USE_MPS=1
      export USE_METAL=1
      export BLAS=Accelerate
      export PYTORCH_BUILD_VERSION=2.10.0
      echo "2.10.0" > version.txt

      echo "MPS build | Platform: Apple Silicon | PyTorch: 2.10.0"
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch 2.10.0 with MPS GPU acceleration for Apple Silicon";
      platforms = [ "aarch64-darwin" ];
    };
  })
```

### pytorch-python313-darwin-x86.nix (cuda-13_0)

```nix
# PyTorch 2.10.0 CPU-only for Intel Mac
# Package name: pytorch-python313-darwin-x86
#
# macOS build for Intel-based Macs (x86_64)
# Hardware: Intel Core i5/i7/i9, Xeon Mac Pro

{ pkgs ? import <nixpkgs> {} }:

let
  nixpkgs_pinned = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/6a030d535719c5190187c4cec156f335e95e3211.tar.gz";
  }) {
    config = { allowUnfree = true; allowBroken = true; };
    overlays = [
      (final: prev: {
        python3Packages = prev.python3Packages.override {
          overrides = pfinal: pprev: {
            torch = pprev.torch.overrideAttrs (oldAttrs: rec {
              version = "2.10.0";
              src = prev.fetchFromGitHub {
                owner = "pytorch";
                repo = "pytorch";
                rev = "v${version}";
                hash = "sha256-RKiZLHBCneMtZKRgTEuW1K7+Jpi+tx11BMXuS1jC1xQ=";
                fetchSubmodules = true;
              };
              patches = [];
            });
          };
        };
      })
    ];
  };

  darwinFrameworks = with nixpkgs_pinned.darwin.apple_sdk.frameworks; [
    Accelerate
  ];

  cpuFlags = [ "-mavx2" "-mfma" "-mf16c" ];

in
  (nixpkgs_pinned.python3Packages.torch.override {
    cudaSupport = false;
  }).overrideAttrs (oldAttrs: {
    pname = "pytorch-python313-darwin-x86";
    patches = [];

    buildInputs = nixpkgs_pinned.lib.filter (p: !(nixpkgs_pinned.lib.hasPrefix "cuda" (p.pname or "")))
      (oldAttrs.buildInputs or []) ++ darwinFrameworks;

    nativeBuildInputs = nixpkgs_pinned.lib.filter (p: p.pname or "" != "addDriverRunpath")
      (oldAttrs.nativeBuildInputs or []);

    cmakeFlags = (oldAttrs.cmakeFlags or []) ++ [
      "-DTORCH_BUILD_VERSION=2.10.0"
      "-DUSE_CUDA=OFF"
    ];

    preConfigure = (oldAttrs.preConfigure or "") + ''
      export USE_CUDA=0
      export USE_CUDNN=0
      export USE_CUBLAS=0
      export USE_MPS=0
      export BLAS=Accelerate
      export USE_MKLDNN=1
      export PYTORCH_BUILD_VERSION=2.10.0
      echo "2.10.0" > version.txt

      export CXXFLAGS="${nixpkgs_pinned.lib.concatStringsSep " " cpuFlags} $CXXFLAGS"
      export CFLAGS="${nixpkgs_pinned.lib.concatStringsSep " " cpuFlags} $CFLAGS"

      echo "CPU-only build | Platform: Intel Mac | CPU: AVX2 | PyTorch: 2.10.0"
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch 2.10.0 CPU-only for Intel Mac";
      platforms = [ "x86_64-darwin" ];
    };
  })
```

---

## Implementation Steps

### Step 1: cuda-12_9 Branch
```bash
git checkout cuda-12_9
git pull origin cuda-12_9
```

1. Edit `manifest.toml` - add darwin systems
2. Create `pytorch-python313-darwin-mps.nix`
3. Create `pytorch-python313-darwin-x86.nix`
4. Update `README.md`
5. Verify syntax: `nix-instantiate --parse .flox/pkgs/pytorch-python313-darwin-mps.nix`
6. Commit and push

### Step 2: cuda-13_0 Branch
```bash
git checkout cuda-13_0
git pull origin cuda-13_0
```

1. Edit `manifest.toml` - add darwin systems
2. Create `pytorch-python313-darwin-mps.nix` (with overlay pattern!)
3. Create `pytorch-python313-darwin-x86.nix` (with overlay pattern!)
4. Update `README.md`
5. Verify syntax
6. Commit and push

### Step 3: Update Cross-References
- Update Multi-Branch Strategy tables on all branches to show correct variant counts

---

## Commit Messages

```
feat(darwin): add MPS and CPU-only macOS variants

- Add aarch64-darwin and x86_64-darwin to manifest systems
- Add pytorch-python313-darwin-mps for Apple Silicon with Metal GPU
- Add pytorch-python313-darwin-x86 for Intel Mac
- Use Apple Accelerate framework for BLAS
- Update README with Darwin documentation
```

---

## Summary

| Branch | Before | After | Pattern |
|--------|--------|-------|---------|
| cuda-12_9 | 57 | 59 | Simple pinned nixpkgs |
| cuda-13_0 | 59 | 61 | Overlay (2.10.0 from source) |

New files per branch: 2 (.nix files)
Total new files: 4
