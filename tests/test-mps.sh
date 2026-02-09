#!/usr/bin/env bash
# Quick MPS validation for a PyTorch nix store path
#
# Usage: ./test-mps.sh [store-path]
#   If no store-path given, uses ./result-pytorch-python313-darwin-mps
#
# Works on any branch — checks out, builds, then run this script.
# The expected PyTorch version is extracted from the nix store path.

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"

pkg="${1:-$repo_root/result-pytorch-python313-darwin-mps}"

if [[ ! -d "$pkg" ]]; then
  echo "ERROR: $pkg not found" >&2
  echo "  Run:  flox build pytorch-python313-darwin-mps" >&2
  exit 1
fi

# Resolve symlink to get the real store path
store_path="$(readlink -f "$pkg")"

# Extract expected version from store path name (e.g. ...-2.8.0 → 2.8.0)
expected_version="${store_path##*-}"

# The dev output holds propagated-build-inputs with all Python deps
dev_pkg="${pkg}-dev"
if [[ ! -d "$dev_pkg" ]]; then
  echo "ERROR: $dev_pkg not found (needed for dependency closure)" >&2
  exit 1
fi

# Detect python version from the store path
py_ver=$(basename "$store_path" | grep -oE 'python3\.[0-9]+' | head -1 | sed 's/python//')
py_ver="${py_ver:-3.13}"

# Find the Python interpreter from the dev closure
python_bin=""
PYTHONPATH=""
while IFS= read -r dep; do
  sp="$dep/lib/python${py_ver}/site-packages"
  if [[ -d "$sp" ]]; then
    PYTHONPATH="${PYTHONPATH:+$PYTHONPATH:}$sp"
  fi
  if [[ -z "$python_bin" && -x "$dep/bin/python${py_ver}" ]]; then
    python_bin="$dep/bin/python${py_ver}"
  fi
done < <(nix-store --query --requisites "$dev_pkg")

if [[ -z "$python_bin" ]]; then
  echo "ERROR: python${py_ver} not found in dependency closure" >&2
  exit 1
fi

export PYTHONPATH

branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
echo "Branch:           $branch"
echo "Store path:       $store_path"
echo "Expected version: $expected_version"
echo "Python:           $python_bin"
echo "---"

"$python_bin" -c "
import sys
import torch

version = torch.__version__
expected = '${expected_version}'

print(f'PyTorch version:  {version}', '  ✓' if version == expected else f'  ✗ (expected {expected})')

mps_built = getattr(torch.backends.mps, 'is_built', lambda: False)()
mps_avail = getattr(torch.backends.mps, 'is_available', lambda: False)()

print(f'MPS built:        {mps_built}', '  ✓' if mps_built else '  ✗')
print(f'MPS available:    {mps_avail}', '  ✓' if mps_avail else '  ✗')
print(f'CUDA available:   {torch.cuda.is_available()}')

# Exit nonzero if validation fails
if version != expected or not mps_built or not mps_avail:
    sys.exit(1)
"
