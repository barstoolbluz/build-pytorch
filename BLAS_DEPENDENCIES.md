# BLAS Dependencies in PyTorch Builds

## Overview

PyTorch relies on BLAS (Basic Linear Algebra Subprograms) libraries for efficient matrix operations. The choice of BLAS backend significantly impacts performance for both CPU and GPU workloads.

## BLAS Backends by Build Type

### GPU Builds (CUDA-enabled)

**Primary Backend: NVIDIA cuBLAS**

GPU builds use NVIDIA's cuBLAS library for GPU-accelerated linear algebra operations.

**Flox Catalog Packages:**
```bash
flox search cublas --all | grep flox-cuda

# Available packages:
flox-cuda/cudaPackages.libcublas         # Latest stable
flox-cuda/cudaPackages_12_8.libcublas    # CUDA 12.8 specific
flox-cuda/cudaPackages_12.libcublas      # CUDA 12.x stable
```

**Related CUDA Math Libraries:**
- `libcublas` - Basic linear algebra (matrix multiply, etc.)
- `libcublasmp` - Multi-process GPU-accelerated BLAS
- `libcusolver` - Linear solvers and decompositions
- `libcusparse` - Sparse matrix operations
- `libcufft` - Fast Fourier Transforms

**Integration in Nix Expression:**
```nix
buildInputs = oldAttrs.buildInputs ++ [
  cudaPackages.cuda_cudart    # CUDA runtime
  cudaPackages.libcublas      # cuBLAS library
  cudaPackages.libcufft       # FFT operations
  cudaPackages.libcurand      # Random number generation
  cudaPackages.libcusolver    # Linear solvers
  cudaPackages.libcusparse    # Sparse operations
  cudaPackages.cudnn          # Deep neural network primitives
];
```

**Build Environment Variables:**
```bash
export USE_CUBLAS=1
export USE_CUDA=1
export TORCH_CUDA_ARCH_LIST="sm_90"
export CMAKE_CUDA_ARCHITECTURES="90"
```

### CPU Builds

**Primary Backend Options: OpenBLAS or Intel MKL**

#### Option 1: OpenBLAS (Default)

**Advantages:**
- Open-source (BSD license)
- Good performance across architectures
- Active development
- No licensing restrictions

**Flox Catalog:**
```bash
flox search openblas

# Available:
openblas                # Latest stable
openblasCompat          # Compatibility version
blas                    # OpenBLAS with BLAS C/FORTRAN ABI
lapack                  # OpenBLAS with LAPACK interface
```

**Integration:**
```nix
let
  blasBackend = openblas;
in python3Packages.pytorch.overrideAttrs (oldAttrs: {
  buildInputs = oldAttrs.buildInputs ++ [ blasBackend ];

  preConfigure = ''
    export BLAS=OpenBLAS
    export USE_MKLDNN=1
  '';
})
```

#### Option 2: Intel MKL (Alternative)

**Advantages:**
- Highly optimized for Intel CPUs
- Excellent performance on x86-64
- Industry standard for HPC

**Disadvantages:**
- Proprietary license
- Larger package size
- Intel CPU bias (may perform worse on AMD)

**Flox Catalog:**
```bash
flox search mkl

# Available:
mkl                              # Intel OneAPI Math Kernel Library
python313Packages.mkl-service    # Python MKL runtime control
```

**Integration:**
```nix
let
  blasBackend = mkl;
in python3Packages.pytorch.overrideAttrs (oldAttrs: {
  buildInputs = oldAttrs.buildInputs ++ [ blasBackend ];

  preConfigure = ''
    export BLAS=MKL
    export USE_MKL=1
  '';
})
```

## Performance Comparison

### Matrix Multiplication Benchmarks (Approximate)

**CPU Operations (2048x2048 GEMM on Intel Xeon):**
- Intel MKL: ~650 GFLOPS (baseline)
- OpenBLAS: ~580 GFLOPS (-10%)
- Reference BLAS: ~80 GFLOPS (-87%)

**GPU Operations (2048x2048 GEMM on H100):**
- cuBLAS: ~60,000 GFLOPS
- CPU (best): ~650 GFLOPS (-98%)

**Takeaway:** GPU acceleration is 100x faster for large matrix operations. BLAS choice matters more for CPU workloads.

## oneDNN (MKLDNN) Integration

PyTorch also uses Intel's oneDNN (formerly MKL-DNN) for optimized deep learning operations on CPU.

**What it provides:**
- Optimized convolution operations
- Batch normalization
- ReLU, pooling, and other primitives
- Vectorized operations using AVX2/AVX-512

**Configuration:**
```bash
export USE_MKLDNN=1
export USE_MKLDNN_CBLAS=1
```

**Note:** oneDNN is separate from BLAS and can work with either OpenBLAS or MKL.

## Build Configuration Matrix

| Build Type | GPU BLAS | CPU BLAS | oneDNN | Use Case |
|------------|----------|----------|--------|----------|
| GPU + AVX-512 | cuBLAS | MKL (fallback) | Yes | Datacenter, mixed workloads |
| GPU + AVX2 | cuBLAS | OpenBLAS (fallback) | Yes | Workstations, broad compatibility |
| CPU-only + AVX-512 | None | MKL | Yes | Intel servers, inference |
| CPU-only + AVX2 | None | OpenBLAS | Yes | Development, CI/CD |
| CPU-only + ARM | None | OpenBLAS | Limited | ARM servers (Graviton, etc.) |

## Memory Layout Considerations

### cuBLAS vs CPU BLAS

- **cuBLAS**: Column-major layout (Fortran convention)
- **PyTorch**: Row-major layout (C convention)

PyTorch automatically handles layout conversion, but there's a performance cost. This is why GPU builds are significantly faster - the data stays on the GPU, avoiding CPU↔GPU transfers.

### Impact on Build Choices

- **GPU builds**: Use cuBLAS exclusively for GPU tensors
- **CPU builds**: Use OpenBLAS/MKL for CPU tensors
- **Mixed mode**: PyTorch handles routing automatically based on tensor device

## Advanced: Custom BLAS Configuration

### Override BLAS for Specific Platforms

```nix
let
  # Select BLAS based on platform
  blasBackend = if stdenv.isLinux && stdenv.isx86_64
    then mkl          # Intel MKL on x86-64 Linux
    else openblas;    # OpenBLAS elsewhere

in python3Packages.pytorch.overrideAttrs (oldAttrs: {
  # ... configuration
})
```

### Multi-threaded BLAS

Control BLAS threading for CPU builds:

```bash
export OPENBLAS_NUM_THREADS=8
export MKL_NUM_THREADS=8
export OMP_NUM_THREADS=8
```

**Note:** Set these at runtime, not during build.

## Verifying BLAS Configuration

After building, verify which BLAS backend is used:

```python
import torch
print(torch.__config__.show())

# Look for lines like:
# BLAS_INFO=openblas
# or
# BLAS_INFO=mkl
```

For GPU builds:
```python
import torch
print(torch.cuda.is_available())      # Should be True
print(torch.version.cuda)             # CUDA version
print(torch.backends.cudnn.version()) # cuDNN version
```

## Troubleshooting

### "Symbol not found: cblas_dgemm"

BLAS library not linked correctly. Ensure:
```nix
buildInputs = oldAttrs.buildInputs ++ [ openblas ];  # or mkl
```

### Poor CPU performance

1. Check BLAS backend: `torch.__config__.show()`
2. Try switching to MKL if on Intel CPU
3. Verify CPU flags are set: `echo $CXXFLAGS`
4. Ensure oneDNN is enabled: `USE_MKLDNN=1`

### GPU operations failing

1. Verify CUDA libraries are linked: `ldd result-*/lib/python3.13/site-packages/torch/lib/libtorch.so`
2. Check for `libcublas` in output
3. Ensure CUDA runtime is available: `nvidia-smi`

## References

- [OpenBLAS Documentation](https://github.com/xianyi/OpenBLAS/wiki)
- [Intel MKL Documentation](https://www.intel.com/content/www/us/en/developer/tools/oneapi/onemkl.html)
- [cuBLAS Documentation](https://docs.nvidia.com/cuda/cublas/)
- [oneDNN Documentation](https://oneapi-src.github.io/oneDNN/)
- [PyTorch BLAS Configuration](https://github.com/pytorch/pytorch/blob/master/cmake/Dependencies.cmake)

## Summary

**For GPU builds:**
- Use cuBLAS (from Flox CUDA catalog)
- CPU BLAS is secondary (fallback only)
- Focus on CUDA architecture targeting

**For CPU builds:**
- Use OpenBLAS (open-source, good compatibility)
- Or use MKL (better performance on Intel, proprietary)
- Enable oneDNN for optimized DL ops
- Set appropriate CPU instruction flags (AVX2, AVX-512)

**Publishing:**
- Document which BLAS backend each variant uses
- Users can't change BLAS after build - it's compiled in
- Create separate variants for OpenBLAS vs MKL if needed
