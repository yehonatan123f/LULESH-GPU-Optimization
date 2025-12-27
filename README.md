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

Run the binary with an example problem size:
```
./lulesh -i 100 -s 200
```

## Scripts
Run every implementation in this repo (each subdirectory's build/run flow) via:
```
./run_all.sh
```

Profile data transfers and runtime behavior with Nsight Systems:
```
./run_nsys_transfers.sh
```

## Notes
- Profiling artifacts (Nsight Systems reports) are ignored to keep the repository size manageable.
