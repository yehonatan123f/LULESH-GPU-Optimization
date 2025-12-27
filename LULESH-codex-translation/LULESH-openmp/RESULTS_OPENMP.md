# RESULTS_OPENMP

## Baseline: LULESH-openacc
- Build: `make clean && make`
- Run: `./lulesh -s 30 -i 100`
- Validation:
  - `Run completed:  Problem size = 30 ... MaxAbsDiff = 0.000000e+00 ... MaxRelDiff = 0.000000e+00`
- Timing:
  - `Elapsed time         =       1.08 (s)`
  - `Grind time (us/z/c)  =  0.4011956 ...`
  - `FOM                  =  2492.5498 (z/s)`

## Scenario A: LULESH-openmp-senarioA
- Build: `make clean && make`
- Run: `./lulesh -s 30 -i 100`
- Validation:
  - `Run completed:  Problem size = 30 ... MaxAbsDiff = 0.000000e+00 ... MaxRelDiff = 0.000000e+00`
- Timing:
  - `Elapsed time         =       0.92 (s)`
  - `Grind time (us/z/c)  = 0.33979999 ...`
  - `FOM                  =  2942.9077 (z/s)`

## Comparison
- Absolute time change: 1.08 s → 0.92 s (−0.16 s, 14.8% faster).
- Speedup: 1.08 / 0.92 ≈ 1.17× improvement in FOM (2492.5 → 2942.9 z/s).

## Key Changes
- Code: translated all `#pragma acc*` constructs to `#pragma omp target*`, introduced persistent `target enter/exit data map(...)` regions, replaced `acc update/wait` with synchronous `target update` + `taskwait`, reworked OpenACC kernels (e.g., hourglass/force assembly) into `target teams distribute parallel for` loops, and made MPI boundary updates rely on host/device transfers managed by OpenMP.
- Makefile: switched compiler to `nvc++` and replaced `-acc -gpu=...` with `-mp=gpu -gpu=cc80,fastmath -Minfo=accel`; no extra tuning flags beyond what is required for OpenMP offload.
