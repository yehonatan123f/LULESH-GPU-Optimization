# DEVLOG

## Starting Point
- Copied `lulesh.cc`, `lulesh-comm.cc`, `lulesh-util.cc`, `lulesh-init.cc`, `lulesh.h`, and `Makefile` from `../LULESH-openacc` into `LULESH-openmp-senarioA`.
- Baseline (OpenACC) build: `make clean && make` inside `LULESH-openacc` – success with PGI OpenACC flags.
- Baseline run: `./lulesh -s 30 -i 100` in `LULESH-openacc` validated (`MaxAbsDiff = 0`, `MaxRelDiff = 0`) and timed at `Elapsed time = 1.08 s`, `FOM = 2492.5498 z/s`.

## Translation Steps
- **Data regions**: `#pragma acc enter/exit data` blocks → `#pragma omp target enter/exit data map(alloc|to|delete: ...)` so the same persistent device mirrors exist during the time stepping loop.
- **Compute loops**: Every `#pragma acc parallel loop`/`kernels loop` replaced by `#pragma omp target teams distribute parallel for` and the previous `present(...)` lists became `map(present: ...)`. Hourglass kernels now also include `map(to: gamma)` to move the constant coefficient matrix.
- **MPI-facing updates**: `#pragma acc update host/device` became `#pragma omp target update from/to`, and all `acc wait`/`async` constructs were rewritten as synchronous transfers guarded by `#pragma omp taskwait`.
- **Special cases**: The `acc parallel` region used for acceleration boundary conditions was flattened into three explicit target loops; OpenACC `copyin` clauses for per-region element lists now use `map(to: regElemList...)`.
- **Runtime hooks**: Removed `openacc.h` include, replaced device selection (`acc_get_num_devices/acc_set_device_num`) with `_OPENMP`-guarded `omp_get_num_devices` and `omp_set_default_device`, and left `ReleaseDeviceMem` as a no-op for OpenMP.

## Pitfalls & Fixes
- The automated text replacement initially left invalid pragmas such as `map(alloc:(...)` and lingering `copyin(...)` clauses, causing compile errors. Manually corrected those clauses and converted `target data create` to `map(alloc:...)`.
- OpenACC async updates had no direct OpenMP equivalent; switched to synchronous updates plus `taskwait` to keep correctness, noting that this may sacrifice overlap but preserves validation.
- The `gamma[4][8]` constant used in hourglass control was explicitly mapped with `map(to: gamma)` to avoid device copy-in errors.

## Iteration Log
1. **Baseline reference**
   - Build: `make clean && make` (OpenACC).
   - Run: `./lulesh -s 30 -i 100`.
   - Output: `Run completed ... MaxAbsDiff = 0`, `Elapsed time = 1.08 (s)`, `FOM = 2492.5498 (z/s)`.
   - Outcome: establishes canonical configuration per requirements.
2. **First OpenMP build attempt after scripted replacements**
   - Build: `make clean && make` in `LULESH-openmp-senarioA`.
   - Failure snippet: `lulesh.cc:2613: error: expected a "]"` and `invalid text in pragma` on the new `target enter data map(alloc:(...)`.
   - Outcome: confirmed need to fix map syntax and remaining `copyin` clauses.
3. **Adjusted pragmas and rebuilt**
   - Changes: fixed `map(alloc|to|delete:)` clauses, converted `copyin` → `map(to:)`, replaced `target data create` with `map(alloc:)`, and reworked the boundary-condition parallel region into explicit target loops.
   - Build: `make clean && make` – success (warnings only).
4. **Scenario A validation run**
   - Run: `./lulesh -s 30 -i 100`.
   - Output: `Run completed ... MaxAbsDiff = 0`, `Elapsed time = 0.92 (s)`, `FOM = 2942.9077 (z/s)`.
   - Outcome: correct physics with improved time over baseline.

## Final Summary
- Device data stays resident via `target enter/exit data` blocks, while per-kernel work relies on `target teams distribute parallel for` with explicit `map(present: ...)` clauses. Reductions/atomics remain unchanged because OpenMP handles them implicitly in these loops, and MPI synchronization now depends on synchronous `target update` plus `taskwait`.
- Known limitations: removed asynchronous overlap, so further tuning might reintroduce OpenMP tasks/nowait regions; no attempt yet to refactor region-loop privatization for better load balance.

## Makefile Justification
- Swapped the compiler driver to `nvc++` and replaced the OpenACC-only `-acc` flag set with the minimal OpenMP offload stack (`-mp=gpu -gpu=cc80,fastmath -Minfo=accel`). No additional optimizations were added beyond what is required to enable OpenMP target execution on the A100.
