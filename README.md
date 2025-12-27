# LULESH GPU Optimization

This repository contains multiple LULESH variants and experiments focused on GPU acceleration, including CUDA, OpenACC, and OpenMP versions, along with benchmarking scripts and results summaries.

## Contents
- `lulesh-cuda/`: CUDA implementation and build files
- `LULESH-openacc/`: OpenACC implementation
- `LULESH-codex-optimization/`, `LULESH-codex-translation/`, `LULESH-codex-translation-again/`: Codex-assisted variants and logs
- `LULESH-intel-translation/`: Intel migration tool and translated variants
- `HeCBench-lulesh-omp/`: HeCBench OpenMP variant

## Quick Start
Build in a specific subdirectory (example):
```
cd lulesh-cuda
make
```

## Notes
- Profiling artifacts (Nsight Systems reports) are ignored to keep the repository size manageable.
