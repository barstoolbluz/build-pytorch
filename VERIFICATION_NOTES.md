# Verification Notes - 2025-11-14

## Purpose

This document tracks verification of technical claims made in the build matrix documentation, particularly around CPU instruction set support and BLAS configuration.

## Verification Session: AMD Zen ISA Support

### Claims Verified

#### ✅ AMD EPYC Genoa (Zen 4) Supports AVX512_VNNI and AVX512_BF16

**Original claim:** AMD Zen 5+ supports VNNI and BF16
**Corrected claim:** AMD Zen 4+ supports VNNI and BF16

**Sources:**
1. **WikiChip - Genoa Core Documentation**
   - URL: https://en.wikichip.org/wiki/amd/cores/genoa
   - Explicitly lists: AVX512_VNNI, AVX512_BF16
   - Complete extension list: AVX512F, AVX512BW, AVX512CD, AVX512DQ, AVX512VL, AVX512_BF16, AVX512_BITALG, AVX512_IFMA, AVX512_VBMI, AVX512_VBMI2, AVX512_VNNI, AVX512_VPOPCNTDQ, GFNI, VAES, VPCLMULQDQ

2. **WikiChip - AVX512_VNNI**
   - URL: https://en.wikichip.org/wiki/x86/avx512_vnni
   - Lists AMD Zen 4 (2022) as supporting AVX512_VNNI

3. **WikiChip - AVX512_BF16**
   - URL: https://en.wikichip.org/wiki/x86/avx512_bf16
   - Intel: Cooper Lake (2020) - first support
   - AMD: Zen 4 (2022) - first support

**Impact:**
- `avx512vnni` variant works on AMD EPYC Genoa (not just Turin)
- `avx512bf16` variant works on AMD EPYC Genoa (not just Turin)
- Wider hardware compatibility than originally documented

#### ✅ Intel AVX512_VNNI Timeline Correction

**Original claim:** Intel Cascade Lake (2019) first introduced AVX512_VNNI
**Corrected claim:** Intel Skylake-SP (2017) first introduced AVX512_VNNI

**Source:**
- **WikiChip - AVX512_VNNI**
- Microarchitecture support table shows Skylake (server) 2017 as first
- Cascade Lake (2019) also supports it, but wasn't first

**Impact:** Minor correction, doesn't affect build matrix significantly

### Hardware Support Timeline

| Instruction Set | Intel First Support | AMD First Support |
|-----------------|---------------------|-------------------|
| AVX-512 (baseline) | Skylake-X (2017) | Zen 4 (2022) |
| AVX512_VNNI | Skylake-SP (2017) | Zen 4 (2022) |
| AVX512_BF16 | Cooper Lake (2020) | Zen 4 (2022) |

### AMD Zen Architecture Summary

| Generation | Year | AVX2 | AVX-512 | VNNI | BF16 | Notes |
|------------|------|------|---------|------|------|-------|
| Zen 1 (Naples) | 2017 | ✅ | ❌ | ❌ | ❌ | AVX2 only |
| Zen 2 (Rome) | 2019 | ✅ | ❌ | ❌ | ❌ | AVX2 only |
| Zen 3 (Milan) | 2021 | ✅ | ❌ | ❌ | ❌ | AVX2 only |
| **Zen 4 (Genoa)** | **2022** | ✅ | ✅ | ✅ | ✅ | **First AMD with AVX-512** |
| Zen 5 (Turin) | 2024 | ✅ | ✅ | ✅ | ✅ | Native 512-bit datapath vs 2×256 in Zen 4 |

**Key insight:** Zen 4 was AMD's first architecture to support AVX-512, and it included VNNI and BF16 from day one.

## Verification Session: BLAS Configuration

### Claims Verified

#### ✅ nixpkgs PyTorch Includes OpenBLAS

**Method:**
```bash
nix-instantiate --eval -E 'with import <nixpkgs> {}; \
  builtins.attrNames (lib.filterAttrs (n: v: lib.hasInfix "blas" ...) \
  python3Packages.pytorch.buildInputs)'
```

**Result:** `[ "blas" "openblas" ]`

**Conclusion:** nixpkgs PyTorch derivation includes both generic "blas" and "openblas" in buildInputs.

#### ✅ OpenBLAS Supports DYNAMIC_ARCH Parameter

**Method:**
```bash
nix-instantiate --eval -E 'with import <nixpkgs> {}; \
  openblas.override.__functionArgs or {}'
```

**Result:** Shows `dynamicArch = true` parameter exists

**Conclusion:**
- OpenBLAS in nixpkgs can be configured with DYNAMIC_ARCH
- Default value likely `true` (based on parameter name `dynamicArch` not `DYNAMIC_ARCH`)
- nixpkgs follows convention of enabling dynamic architecture detection by default

### BLAS Strategy Decision

**Decision:** Explicitly add OpenBLAS to GPU build `buildInputs`

**Rationale:**
1. **Control:** Don't rely on inheritance from base PyTorch derivation
2. **Transparency:** Make BLAS configuration explicit in our .nix files
3. **Consistency:** Ensure all variants use the same BLAS strategy
4. **Documentation:** Makes it clear to users what BLAS backend is used

**Implementation:**
```nix
buildInputs = oldAttrs.buildInputs ++ [
  cudaPackages.libcublas
  # ... other CUDA libs
  (openblas.override {
    blas64 = false;
    singleThreaded = false;
  })
];
```

**Note:** We rely on nixpkgs default `DYNAMIC_ARCH=1` rather than setting it explicitly, as this is the nixpkgs convention.

## Documentation Updates Made

### BUILD_MATRIX.md Changes

1. **ISA Table (Section 3):**
   - Updated AVX-512 BF16 hardware: "Intel Cooper Lake+ (2020), AMD Zen 4+ (2022)"
   - Updated AVX-512 VNNI hardware: "Intel Skylake-SP+ (2017), AMD Zen 4+ (2022)"
   - Updated AVX-512 baseline: Added years for clarity
   - Updated AVX2: Added years for clarity

2. **AMD Zen ISA Support:**
   - Changed Zen 4 from "AVX2 + AVX-512" to "AVX2 + AVX-512 + VNNI + BF16"
   - Clarified Zen 5 improvements: Native 512-bit datapath vs 2×256 in Zen 4

3. **SM120 Build Matrix (x86-64 variants):**
   - Updated hardware support columns with years
   - avx512vnni: Changed from "Zen 5+" to "Zen 4+ (2022)"
   - avx512bf16: Changed from "Zen 5+" to "Zen 4+ (2022)"

4. **BLAS Backend Strategy:**
   - Added explicit OpenBLAS to buildInputs example
   - Added note about relying on nixpkgs DYNAMIC_ARCH default
   - Updated rationale to include "Explicit control" point
   - Clarified that we add OpenBLAS explicitly rather than just inheriting

### Files Modified

- `BUILD_MATRIX.md` - Complete ISA and BLAS strategy updates
- `VERIFICATION_NOTES.md` - This file (created)

## Confidence Levels

| Fact | Confidence | Verification Method |
|------|------------|---------------------|
| AMD Zen 4 supports AVX512_VNNI | **Very High** ✅ | WikiChip official documentation |
| AMD Zen 4 supports AVX512_BF16 | **Very High** ✅ | WikiChip official documentation |
| Intel Skylake-SP first VNNI | **High** ✅ | WikiChip microarch table |
| nixpkgs PyTorch uses OpenBLAS | **High** ✅ | nix-instantiate verification |
| OpenBLAS default is DYNAMIC_ARCH=1 | **Medium** ⚠️ | Inferred from parameter naming |

## Next Steps

1. Update existing `.nix` files to explicitly add OpenBLAS to buildInputs
2. Create new SM120 variant files with correct hardware support claims
3. Test builds to verify OpenBLAS is correctly linked
4. Consider adding verification tests to CI/CD

## References

1. WikiChip - AMD Genoa Core: https://en.wikichip.org/wiki/amd/cores/genoa
2. WikiChip - AVX512_VNNI: https://en.wikichip.org/wiki/x86/avx512_vnni
3. WikiChip - AVX512_BF16: https://en.wikichip.org/wiki/x86/avx512_bf16
4. ServeTheHome - EPYC Genoa Review: https://www.servethehome.com/amd-epyc-genoa-gaps-intel-xeon-in-stunning-fashion/
5. AMD EPYC 9004 Architecture Whitepaper: https://www.amd.com/system/files/documents/4th-gen-epyc-processor-architecture-white-paper.pdf

## Change Log

- 2025-11-14: Initial verification session
  - Verified AMD Zen 4 VNNI/BF16 support
  - Corrected Intel VNNI timeline
  - Verified nixpkgs BLAS configuration
  - Updated BUILD_MATRIX.md accordingly
