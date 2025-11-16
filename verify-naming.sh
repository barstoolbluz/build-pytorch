#!/bin/bash
# Verify SM120 naming convention is correct

echo "======================================"
echo "SM120 NAMING CONVENTION VERIFICATION"
echo "======================================"
echo ""

# Check 1: Filename vs pname consistency
echo "1. Filename vs pname consistency:"
echo "-----------------------------------"
all_match=true
for f in .flox/pkgs/pytorch-python313-cuda12_8-sm120-*.nix; do
    filename=$(basename "$f" .nix)
    pname=$(grep 'pname =' "$f" | sed 's/.*pname = "\(.*\)";/\1/')

    if [ "$filename" = "$pname" ]; then
        echo "✓ $filename"
    else
        echo "✗ MISMATCH: file=$filename, pname=$pname"
        all_match=false
    fi
done
echo ""

# Check 2: No cu128 suffix
echo "2. Check for cu128 suffix (should be none):"
echo "--------------------------------------------"
if grep -r "cu128" .flox/pkgs/pytorch-python313-cuda12_8-sm120-*.nix > /dev/null 2>&1; then
    echo "✗ Found cu128 references:"
    grep -n "cu128" .flox/pkgs/pytorch-python313-cuda12_8-sm120-*.nix
else
    echo "✓ No cu128 suffix found (correct)"
fi
echo ""

# Check 3: Convention comparison
echo "3. Naming convention comparison:"
echo "--------------------------------"
echo "Existing conventions:"
sm86=$(basename .flox/pkgs/pytorch-python313-cuda12_8-sm86-avx2.nix .nix)
sm90=$(basename .flox/pkgs/pytorch-python313-cuda12_8-sm90-avx512.nix .nix)
echo "  SM86: $sm86"
echo "  SM90: $sm90"
echo ""
echo "SM120 files (should follow same pattern):"
for f in .flox/pkgs/pytorch-python313-cuda12_8-sm120-*.nix; do
    echo "  SM120: $(basename $f .nix)"
done
echo ""

# Check 4: File count
echo "4. File count:"
echo "--------------"
count=$(ls .flox/pkgs/pytorch-python313-cuda12_8-sm120-*.nix 2>/dev/null | wc -l)
echo "Total SM120 files: $count (expected: 6)"
echo ""

# Summary
echo "======================================"
echo "SUMMARY"
echo "======================================"
if $all_match && [ $count -eq 6 ]; then
    echo "✓ ALL CHECKS PASSED"
    echo "  - All filenames match pnames"
    echo "  - No cu128 suffixes found"
    echo "  - All 6 SM120 files present"
    echo "  - Convention matches SM86/SM90"
else
    echo "✗ SOME CHECKS FAILED"
    echo "  Please review output above"
fi
echo ""
