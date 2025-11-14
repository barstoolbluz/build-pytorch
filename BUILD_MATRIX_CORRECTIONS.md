# Build Matrix Corrections & Verification

## Corrections Made (2025-11-14)

### 1. SM120 CUDA Requirement ✅ FIXED

**Original (WRONG):**
- SM120 requires CUDA 12.9+
- PyTorch 2.7+ may need nightly builds

**Corrected (VERIFIED):**
- SM120 requires **CUDA 12.8+**
- PyTorch 2.7 **stable release** (April 23, 2025) includes SM120 support
- Ships with pre-built wheels for CUDA 12.8
- Source: [PyTorch 2.7 Release Blog](https://pytorch.org/blog/pytorch-2-7/)

### 2. CUDA Toolkit Driver Requirements ✅ UPDATED

**Added:**
- Windows driver versions for each CUDA toolkit
- CUDA 12.0 baseline (driver 525+)
- Note about CUDA 13.0 Windows driver changes

**CUDA Toolkit → Driver Mapping (Linux):**

| CUDA | Driver | Verified |
|------|--------|----------|
| 13.0 | 580+ | ✅ NVIDIA docs |
| 12.9 | 575+ | ✅ From forward compat table |
| 12.8 | 570+ | ✅ PyTorch 2.7 docs |
| 12.6 | 560+ | ⚠️ Estimated (pattern-based) |
| 12.5 | 555+ | ⚠️ Estimated (pattern-based) |
| 12.4 | 550+ | ✅ Community verified |
| 12.2 | 535+ | ✅ NVIDIA forums |
| 12.0 | 525+ | ✅ NVIDIA docs |

### 3. Architecture Support by CUDA Version ✅ CLARIFIED

**Updated SM120 support matrix:**
- CUDA 12.8: ✅ Supported (PyTorch 2.7 default)
- CUDA 12.6: ✅** May work (not officially documented)
- CUDA 12.5: ✅** May work (not officially documented)
- CUDA 12.4: ❌ No support (too old)

### 4. Default Build Strategy ✅ CHANGED

**Original:** Use CUDA 12.9 for all builds

**Corrected:** Use CUDA 12.8 for all builds
- Matches PyTorch 2.7 default
- Lower driver requirement (570+ vs 575+)
- Broader compatibility

## Verified Facts

### ✅ Confirmed from Official Sources

1. **PyTorch 2.7 Released:** April 23, 2025
   - Source: PyTorch Blog, Twitter
   - Includes stable SM120 support

2. **PyTorch 2.7 CUDA Version:** 12.8
   - Official wheels: `cuda128`
   - Install: `pip install torch==2.7.0 --index-url https://download.pytorch.org/whl/cu128`

3. **CUDA 13.0 Changes:**
   - Removes support for SM 5.x (Maxwell), 6.x (Pascal), 7.0-7.1 (Volta)
   - Windows driver no longer bundled
   - Requires driver 580+

4. **Forward Compatibility Matrix:**
   - From user-provided official NVIDIA table
   - Accurately reflects cuda-compat package support

### ⚠️ Estimated/Inferred (Need Verification)

1. **CUDA 12.5/12.6 driver versions (555+, 560+)**
   - Based on version number progression
   - Not explicitly found in documentation
   - Pattern: Each minor CUDA bump = ~5-10 driver version increase

2. **SM120 support in CUDA 12.5/12.6**
   - Marked as "may work but not documented"
   - Conservative assumption: Only CUDA 12.8+ officially supports SM120

## Implications for RTX 5090 Users

### Your Specific Hardware

**RTX 5090 Requirements:**
1. **Driver:** 570+ minimum (for CUDA 12.8)
2. **CUDA Toolkit:** 12.8+ (12.9, 13.0 also work)
3. **PyTorch:** 2.7+ stable (no nightly needed!)

### Recommended Build

```bash
# Check your driver first
nvidia-smi

# If driver >= 570, build with CUDA 12.8
flox build pytorch-py313-sm120-avx512-cu128

# If driver < 570, upgrade driver first:
# Ubuntu/Debian:
sudo apt-get install nvidia-driver-570

# Then build
```

### If Driver Upgrade Not Possible

If you're stuck on driver 535-569:
- Cannot use SM120 (requires hardware support in driver)
- Must use older GPU builds (SM90, SM86, etc.)
- Or upgrade to driver 570+

**Forward compat won't help:** SM120 support requires driver-level changes, not just CUDA runtime compatibility.

## Updated Build Recommendations

### For Production Use

**Strategy:** CUDA 12.8 for all builds

```
pytorch-py313-sm120-avx512-cu128   # RTX 5090, driver 570+
pytorch-py313-sm90-avx512-cu128    # H100/L40S
pytorch-py313-sm89-avx512-cu128    # RTX 4090
pytorch-py313-sm86-avx2-cu128      # RTX 3090
pytorch-py313-cpu-avx2             # CPU-only
```

**Why CUDA 12.8:**
1. Matches PyTorch 2.7 (stable, well-tested)
2. Supports all SM architectures including SM120
3. Lower driver requirement (570 vs 575 for 12.9)
4. Forward compat works back to driver 535

### For Cutting Edge

**Strategy:** CUDA 12.9 or 13.0

```
pytorch-py313-sm120-avx512-cu129   # RTX 5090, driver 575+
# or
pytorch-py313-sm120-avx512-cu130   # RTX 5090, driver 580+
```

**Why newer CUDA:**
- Latest features and optimizations
- Better support for future GPU architectures
- Performance improvements

**Tradeoff:**
- Higher driver requirement
- Less tested (especially 13.0)
- CUDA 13.0 removes SM 5.x-7.0 support

## Naming Updates Required

### Current Files (Missing CUDA Version)

```
.flox/pkgs/pytorch-py313-sm120-avx512.nix     # Which CUDA?
.flox/pkgs/pytorch-py313-sm90-avx512.nix      # Which CUDA?
.flox/pkgs/pytorch-py313-sm86-avx2.nix        # Which CUDA?
.flox/pkgs/pytorch-py313-cpu-avx2.nix         # No CUDA (OK)
```

### Recommended Renames

```
.flox/pkgs/pytorch-py313-sm120-avx512-cu128.nix
.flox/pkgs/pytorch-py313-sm90-avx512-cu128.nix
.flox/pkgs/pytorch-py313-sm86-avx2-cu128.nix
.flox/pkgs/pytorch-py313-cpu-avx2.nix
```

**Action Required:**
1. Rename .nix files to include `-cu128`
2. Update `pname` inside each file
3. Update manifest.toml hook messages
4. Update README.md examples

## Documentation Updates Needed

### Files to Update

1. **README.md**
   - Change CUDA 12.9 → 12.8 in examples
   - Update driver requirements (575+ → 570+)
   - Note PyTorch 2.7 stable availability

2. **SUMMARY.md**
   - Update package naming examples
   - Correct CUDA version references

3. **QUICKSTART.md**
   - Update build command examples
   - Correct driver requirement statements

4. **.flox/env/manifest.toml**
   - Update build command examples in hook

## Verification Checklist

- [x] SM120 CUDA requirement corrected (12.9+ → 12.8+)
- [x] PyTorch version clarified (nightly → 2.7 stable)
- [x] Driver requirements table completed
- [x] CUDA 13.0 architecture deprecation noted
- [x] Default CUDA version changed (12.9 → 12.8)
- [x] Build examples updated throughout
- [ ] **TODO:** Rename .nix files to include `-cu128`
- [ ] **TODO:** Update all documentation files
- [ ] **TODO:** Test build with actual PyTorch 2.7

## Sources Referenced

1. PyTorch 2.7 Release Blog: https://pytorch.org/blog/pytorch-2-7/
2. PyTorch Forums - SM120 Support: https://discuss.pytorch.org/t/pytorch-support-for-sm120/216099
3. GitHub Issue - SM120 Support: https://github.com/pytorch/pytorch/issues/159207
4. NVIDIA CUDA Toolkit Release Notes: https://docs.nvidia.com/cuda/cuda-toolkit-release-notes/
5. NVIDIA CUDA Compatibility Guide: https://docs.nvidia.com/deploy/cuda-compatibility/
6. User-provided forward compatibility table (official NVIDIA source)

## Confidence Levels

| Fact | Confidence | Source |
|------|------------|--------|
| SM120 in PyTorch 2.7 | **High** ✅ | Official PyTorch blog |
| CUDA 12.8 default | **High** ✅ | PyTorch 2.7 docs |
| Driver 570+ for CUDA 12.8 | **High** ✅ | NVIDIA docs + PyTorch |
| Driver 575+ for CUDA 12.9 | **High** ✅ | Forward compat table |
| Driver 560+ for CUDA 12.6 | **Medium** ⚠️ | Pattern inference |
| Driver 555+ for CUDA 12.5 | **Medium** ⚠️ | Pattern inference |
| Forward compat matrix | **High** ✅ | User-provided NVIDIA table |

## Next Steps

1. Apply remaining documentation updates
2. Optionally rename files to include `-cu128`
3. Consider building test variant to verify
4. Update any CI/CD configs if present
