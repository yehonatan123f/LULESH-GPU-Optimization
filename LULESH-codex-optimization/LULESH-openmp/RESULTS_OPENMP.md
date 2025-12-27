RESULTS (OpenMP GPU)
=====================

Baseline (HeCBench-lulesh-omp)
------------------------------
- Build: `module load pgi/24.7 nvhpc/24.7 && cd HeCBench-lulesh-omp && make clean && make`
- Run: `module load pgi/24.7 nvhpc/24.7 && cd HeCBench-lulesh-omp && ./lulesh -i 100 -s 128 -r 11 -b 1 -c 1`
- Validation:  
  `Testing Plane 0 of Energy Array on rank 0:`  
  `     MaxAbsDiff   = 0.000000e+00`  
  `     TotalAbsDiff = 0.000000e+00`  
  `     MaxRelDiff   = 0.000000e+00`
- Timing:  
  `Elapsed time         =       5.35 (s)`  
  `Grind time (us/z/c)  = 0.025505166 (per dom)  (0.025505166 overall)`  
  `FOM                  =  39207.743 (z/s)`

Optimized (LULESH-openmp)
-------------------------
- Build: `module load pgi/24.7 nvhpc/24.7 && cd LULESH-openmp && make clean && make`
- Run: `module load pgi/24.7 nvhpc/24.7 && cd LULESH-openmp && ./lulesh -i 100 -s 128 -r 11 -b 1 -c 1`
- Validation:  
  `Testing Plane 0 of Energy Array on rank 0:`  
  `     MaxAbsDiff   = 0.000000e+00`  
  `     TotalAbsDiff = 0.000000e+00`  
  `     MaxRelDiff   = 0.000000e+00`
- Timing:  
  `Elapsed time         =       4.22 (s)`  
  `Grind time (us/z/c)  = 0.020100923 (per dom)  (0.020100923 overall)`  
  `FOM                  =   49748.96 (z/s)`

Comparison
----------
| Metric                 | Baseline | Optimized | Delta |
|------------------------|---------:|----------:|------:|
| Elapsed time (s)       | 5.35     | 4.22      | −21.1% |
| Grind time (µs/z/c)    | 0.025505 | 0.020101  | −21.2% |
| FOM (z/s)              | 39,207.7 | 49,748.9  | +26.9% |

Key Changes
-----------
- Added a GPU-side `CalcTimeConstraintsForElemsDevice` reduction that keeps `ss`, `arealg`, and `vdov` resident on the device and updates only the scalar timestep limits on the host.
- Removed the large per-iteration `target update from` transfers for `ss`, `arealg`, and `vdov`, cutting the dominant host↔device traffic in the inner loop.
- Issued a single `target update from (e[:])` after the timestep loop so CPU-side final validation (`VerifyAndWriteFinalOutput`) still sees the correct energy field.

Validation Note
---------------
Final energy verification and the negative element volume check are still executed on the host CPU exactly as in the baseline.
