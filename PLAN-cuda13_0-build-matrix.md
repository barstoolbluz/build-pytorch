# Plan: Create Full Build Matrix for build-pytorch (cuda-13_0 Branch)

## Summary

Create the full 44-variant build matrix for build-pytorch cuda-13_0 branch to match build-torchaudio and build-torchvision.

## Current State (VALIDATED 2026-02-06)

**Existing recipe files (6):**
```
pytorch-python313-cuda13_0-sm110-armv8_2.nix      # ⚠️ BROKEN: wrong nixpkgs, no overlays
pytorch-python313-cuda13_0-sm110-armv9.nix        # ⚠️ BROKEN: wrong nixpkgs, no overlays
pytorch-python313-cuda13_0-sm120-avx512-magma.nix # Redundant (has -magma suffix)
pytorch-python313-cuda13_0-sm120-avx512.nix       # ✓ Canonical x86 reference - CORRECT
pytorch-python313-cuda13_0-sm120-avx.nix          # ⚠️ BROKEN: wrong nixpkgs, no overlays
pytorch-python313-cuda13_0-sm121-armv9-nightly.nix # ⚠️ BROKEN: completely different pattern
```

**Critical Issues Discovered During Validation:**

1. **sm110-armv8_2.nix and sm110-armv9.nix are BROKEN:**
   - Wrong nixpkgs pin: `fe5e41d7ffc0421f0913e8472ce6238ed0daf8e3` (should be `6a030d535719c5190187c4cec156f335e95e3211`)
   - Missing 3-overlay structure (no CUDA 13.0 overlay, no MAGMA patch, no PyTorch 2.10.0 upgrade)
   - Use `python3Packages.pytorch` instead of `python3Packages.torch`
   - Missing CCCL symlinks and FindCUDAToolkit stub
   - **ACTION: REWRITE from canonical template**

2. **sm120-avx.nix is BROKEN:**
   - Same issues as ARM variants above
   - **ACTION: DELETE and create new sm120-avx2.nix from template**

3. **sm121-armv9-nightly.nix is BROKEN:**
   - Uses completely different approach (`buildPythonPackage` from scratch instead of overlay)
   - PyTorch 2.9.0 instead of 2.10.0
   - Cannot be simply renamed - must be replaced entirely
   - **ACTION: DELETE and create proper sm121-armv9.nix from ARM template**

4. **sm120-avx512-magma.nix is redundant:**
   - Correct pattern but `-magma` suffix is non-standard
   - All variants include MAGMA by default
   - **ACTION: DELETE (sm120-avx512.nix already exists)**

**Only 1 file is correct:** `pytorch-python313-cuda13_0-sm120-avx512.nix`

**Target (44 total):**
- 36 GPU x86 variants (9 architectures × 4 ISAs)
- 4 GPU ARM variants (SM110/SM121 × ARMv8.2/ARMv9)
- 4 CPU-only x86 variants

---

## Canonical Recipe Pattern (PyTorch)

The canonical recipe is `pytorch-python313-cuda13_0-sm120-avx512.nix`:

```nix
# 3-overlay structure:
overlays = [
  # Overlay 1: Use CUDA 13.0
  (final: prev: { cudaPackages = final.cudaPackages_13; })

  # Overlay 2: Patch MAGMA for CUDA 13.0 compatibility
  (final: prev: {
    magma = prev.magma.overrideAttrs (oldAttrs: {
      patches = (oldAttrs.patches or []) ++ [
        (final.fetchpatch {
          name = "cuda-13.0-clockrate-fix.patch";
          url = "https://github.com/icl-utk-edu/magma/commit/235aefb7b064954fce09d035c69907ba8a87cbcd.patch";
          hash = "sha256-i9InbxD5HtfonB/GyF9nQhFmok3jZ73RxGcIciGBGvU=";
        })
      ];
    });
  })

  # Overlay 3: Upgrade PyTorch to 2.10.0
  (final: prev: {
    python3Packages = prev.python3Packages.override {
      overrides = pfinal: pprev: {
        torch = pprev.torch.overrideAttrs (oldAttrs: rec {
          version = "2.10.0";
          src = prev.fetchFromGitHub { ... };
          patches = [];
        });
      };
    };
  })
];
```

**Key differences from TorchVision/TorchAudio:**
- PyTorch is the base package, not an override of another package
- Uses `torch.override { cudaSupport = true; gpuTargets = [...]; }`
- pname uses `pytorch210-` prefix (e.g., `pytorch210-python313-cuda13_0-sm120-avx512`)

---

## Files to Create/Rewrite (43 total)

### GPU x86 Variants (36 files - 35 new, 1 exists)

| Architecture | avx2 | avx512 | avx512bf16 | avx512vnni |
|--------------|------|--------|------------|------------|
| **SM121** | NEW | NEW | NEW | NEW |
| **SM120** | NEW | EXISTS ✓ | NEW | NEW |
| **SM110** | NEW | NEW | NEW | NEW |
| **SM103** | NEW | NEW | NEW | NEW |
| **SM100** | NEW | NEW | NEW | NEW |
| **SM90** | NEW | NEW | NEW | NEW |
| **SM89** | NEW | NEW | NEW | NEW |
| **SM86** | NEW | NEW | NEW | NEW |
| **SM80** | NEW | NEW | NEW | NEW |

### GPU ARM Variants (4 files - all need creation/rewrite)

| Architecture | ARMv8.2 | ARMv9 |
|--------------|---------|-------|
| **SM121** | NEW | REPLACE* |
| **SM110** | REWRITE** | REWRITE** |

*REPLACE: Delete `sm121-armv9-nightly.nix` and create proper `sm121-armv9.nix`
**REWRITE: Files exist but are broken - must be rewritten with correct 3-overlay pattern

### CPU-Only Variants (4 new files)

| CPU ISA | File |
|---------|------|
| avx2 | `pytorch-python313-cpu-avx2.nix` |
| avx512 | `pytorch-python313-cpu-avx512.nix` |
| avx512bf16 | `pytorch-python313-cpu-avx512bf16.nix` |
| avx512vnni | `pytorch-python313-cpu-avx512vnni.nix` |

---

## Files to Delete (4)

These must be removed - they are either broken or redundant:

1. `pytorch-python313-cuda13_0-sm120-avx512-magma.nix` - Redundant (sm120-avx512.nix exists)
2. `pytorch-python313-cuda13_0-sm120-avx.nix` - Broken (wrong nixpkgs, no overlays)
3. `pytorch-python313-cuda13_0-sm121-armv9-nightly.nix` - Broken (completely wrong pattern)
4. `pytorch-python313-cuda13_0-sm110-armv8_2.nix` - Broken (will be rewritten in-place)
5. `pytorch-python313-cuda13_0-sm110-armv9.nix` - Broken (will be rewritten in-place)

**Note:** Files #4 and #5 can be overwritten in-place rather than deleted.

---

## Template Variables

### GPU Architectures

| Architecture | gpuArchSM | gpuArchNum | Description |
|--------------|-----------|------------|-------------|
| SM121 | "12.1" | "121" | DGX Spark |
| SM120 | "12.0" | "120" | Blackwell (RTX 5090) |
| SM110 | "11.0" | "110" | DRIVE Thor |
| SM103 | "10.3" | "103" | B300 |
| SM100 | "10.0" | "100" | B100/B200 |
| SM90 | "9.0" | "90" | Hopper (H100) |
| SM89 | "8.9" | "89" | Ada (RTX 40 series) |
| SM86 | "8.6" | "86" | Ampere (RTX 30 series) |
| SM80 | "8.0" | "80" | Ampere DC (A100) |

### CPU ISA Flags

| ISA | cpuFlags |
|-----|----------|
| avx2 | `["-mavx2", "-mfma", "-mf16c"]` |
| avx512 | `["-mavx512f", "-mavx512dq", "-mavx512vl", "-mavx512bw", "-mfma"]` |
| avx512bf16 | `["-mavx512f", "-mavx512dq", "-mavx512vl", "-mavx512bw", "-mavx512bf16", "-mfma"]` |
| avx512vnni | `["-mavx512f", "-mavx512dq", "-mavx512vl", "-mavx512bw", "-mavx512vnni", "-mfma"]` |

---

## Implementation Order

### Phase 1: Clean up broken/redundant files
1. Delete `sm120-avx512-magma.nix` (redundant)
2. Delete `sm120-avx.nix` (broken)
3. Delete `sm121-armv9-nightly.nix` (broken)

### Phase 2: Create GPU x86 Recipes (35 new files)
Group by architecture, using `sm120-avx512.nix` as template:
1. **SM120** (3 new): avx2, avx512bf16, avx512vnni
2. **SM121** (4 new): avx2, avx512, avx512bf16, avx512vnni
3. **SM110** (4 new): avx2, avx512, avx512bf16, avx512vnni
4. **SM103** (4 new): all 4 ISAs
5. **SM100** (4 new): all 4 ISAs
6. **SM90** (4 new): all 4 ISAs
7. **SM89** (4 new): all 4 ISAs
8. **SM86** (4 new): all 4 ISAs
9. **SM80** (4 new): all 4 ISAs

### Phase 3: Create/Rewrite GPU ARM Recipes (4 files)
Create ARM template from `sm120-avx512.nix`, then:
1. **SM110-armv8_2** (REWRITE existing broken file)
2. **SM110-armv9** (REWRITE existing broken file)
3. **SM121-armv8_2** (NEW)
4. **SM121-armv9** (NEW - replaces deleted nightly file)

### Phase 4: Create CPU-Only Recipes (4 files)
Based on torchvision CPU recipes (simpler 1-overlay pattern):
1. pytorch-python313-cpu-avx2.nix
2. pytorch-python313-cpu-avx512.nix
3. pytorch-python313-cpu-avx512bf16.nix
4. pytorch-python313-cpu-avx512vnni.nix

### Phase 5: Update Documentation
1. Update README.md variant counts
2. Update variant matrix table

---

## Reference Files

- **Canonical x86 GPU recipe:** `pytorch-python313-cuda13_0-sm120-avx512.nix` ✓ (use as template)
- **TorchAudio x86 reference:** `/home/daedalus/dev/builds/build-torchaudio/.flox/pkgs/torchaudio-python313-cuda13_0-sm120-avx512.nix`
- **TorchVision ARM reference:** `/home/daedalus/dev/builds/build-torchvision/.flox/pkgs/torchvision-python313-cuda13_0-sm110-armv8_2.nix`
- **TorchVision CPU reference:** `/home/daedalus/dev/builds/build-torchvision/.flox/pkgs/torchvision-python313-cpu-avx512.nix`

**Note:** The existing ARM recipes in build-pytorch are broken. Use the torchvision ARM recipes as reference.

---

## Verification

After creating all recipes:

```bash
# Count files (total 44)
ls .flox/pkgs/pytorch-python313-cuda13_0-*.nix | wc -l  # Should be 40 (36 x86 + 4 ARM)
ls .flox/pkgs/pytorch-python313-cpu-*.nix | wc -l       # Should be 4

# Verify no broken files remain
ls .flox/pkgs/pytorch-python313-cuda13_0-*-magma.nix 2>/dev/null  # Should be empty
ls .flox/pkgs/pytorch-python313-cuda13_0-*-nightly.nix 2>/dev/null  # Should be empty
ls .flox/pkgs/pytorch-python313-cuda13_0-*-avx.nix 2>/dev/null  # Should be empty (avx2 not avx)

# Verify all GPU files have correct 3-overlay pattern
for f in .flox/pkgs/pytorch-python313-cuda13_0-*.nix; do
  count=$(grep -c 'cudaPackages_13\|cuda-13.0-clockrate-fix.patch\|version = "2.10.0"' "$f")
  if [ "$count" -ne 3 ]; then
    echo "BROKEN: $f (expected 3 patterns, found $count)"
  fi
done

# Verify CPU files have 1-overlay pattern (no CUDA)
for f in .flox/pkgs/pytorch-python313-cpu-*.nix; do
  count=$(grep -c 'version = "2.10.0"' "$f")
  cuda=$(grep -c 'cudaPackages_13' "$f")
  if [ "$count" -ne 1 ] || [ "$cuda" -ne 0 ]; then
    echo "BROKEN: $f"
  fi
done

# Verify consistent nixpkgs pin across all files
grep -l 'fe5e41d7ffc0421f0913e8472ce6238ed0daf8e3' .flox/pkgs/pytorch-python313-*.nix
# Should be empty (old pin should not exist)

# Spot check gpuArchSM values
grep 'gpuArchSM = "9.0"' .flox/pkgs/pytorch-python313-cuda13_0-sm90-*.nix
grep 'gpuArchSM = "8.6"' .flox/pkgs/pytorch-python313-cuda13_0-sm86-*.nix
grep 'gpuArchSM = "12.1"' .flox/pkgs/pytorch-python313-cuda13_0-sm121-*.nix
```

---

## Key Considerations

1. **pname prefix:** PyTorch recipes use `pytorch210-` prefix in pname
2. **No TorchVision dependency:** PyTorch is standalone, no `.override { torch = ... }`
3. **MAGMA in all variants:** All GPU variants include the MAGMA clockRate patch
4. **CPU-only simpler:** CPU variants don't need CUDA overlays or MAGMA patch
5. **Consistent nixpkgs pin:** All use `6a030d535719c5190187c4cec156f335e95e3211`
6. **Use `torch` not `pytorch`:** The attribute is `python3Packages.torch`, not `python3Packages.pytorch`

---

## Validation History

**2026-02-06:** Plan validated against actual files. Critical issues found:
- Existing ARM variants (sm110-*) use wrong nixpkgs and missing overlays → need rewrite
- sm120-avx.nix uses wrong nixpkgs and missing overlays → delete
- sm121-armv9-nightly.nix uses completely different pattern → delete
- Only sm120-avx512.nix is correct and can be used as template

**Corrected file counts:**
- Files to delete: 4 (3 broken + 1 redundant)
- Files to create new: 43 (35 x86 + 4 ARM + 4 CPU)
- Files that already exist and are correct: 1 (sm120-avx512.nix)
- **Total after completion: 44 variants**
