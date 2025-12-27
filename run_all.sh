#!/usr/bin/env bash
set -euo pipefail

# Run from the directory that contains these folders:
#   LULESH-intel-translation/LULESH-openmp
#   HeCBench-lulesh-omp
#   LULESH-codex-translation/LULESH-openmp
#   LULESH-codex-optimization/LULESH-openmp
#   LULESH-openacc
#   lulesh-cuda
#
# Output:
#   lulesh_bench_summary.md
#   lulesh_bench_results.csv
#   lulesh_bench_runs.log

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

REPS=5
SIZES=(100 150 200 250 300)

# label -> relative dir
declare -A DIRS=(
  ["intel_translation"]="LULESH-intel-translation/LULESH-openmp"
  ["hecbench_openmp"]="HeCBench-lulesh-omp"
  ["codex_translation"]="LULESH-codex-translation/LULESH-openmp"
  ["codex_optimization"]="LULESH-codex-optimization/LULESH-openmp"
  ["openacc"]="LULESH-openacc"
  ["cuda"]="lulesh-cuda"
)

# Keep a fixed order for reporting
IMPLS=("openacc" "intel_translation" "codex_translation" "codex_optimization" "hecbench_openmp" "cuda")

OUT_CSV="${ROOT}/lulesh_bench_results.csv"
OUT_MD="${ROOT}/lulesh_bench_summary.md"
OUT_LOG="${ROOT}/lulesh_bench_runs.log"

: > "$OUT_CSV"
: > "$OUT_MD"
: > "$OUT_LOG"

echo "impl,s,avg_time,rep_times" >> "$OUT_CSV"

# avg_times["impl,s"]=value
declare -A AVG

die() { echo "ERROR: $*" >&2; exit 1; }

pick_exe() {
  if [[ -x "./lulesh" ]]; then
    echo "./lulesh"
  elif [[ -x "./lulesh2.0" ]]; then
    echo "./lulesh2.0"
  elif [[ -x "./lulesh-cuda" ]]; then
    echo "./lulesh-cuda"
  else
    return 1
  fi
}

extract_time() {
  # Tries to parse a numeric time from common LULESH timing lines.
  # Prints a single number on success, empty on failure.
  awk '
    function trim(s){gsub(/^[ \t]+|[ \t]+$/, "", s); return s}
    BEGIN{t=""}
    /Elapsed[[:space:]]+time|Elapsed[[:space:]]+Time|Total[[:space:]]+time|Total[[:space:]]+Time/{
      # Try "something = number ..."
      n=split($0, parts, "=")
      if (n>=2) {
        rhs=trim(parts[2])
        split(rhs, tok, /[ \t]/)
        if (tok[1] ~ /^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$/) {print tok[1]; exit}
      }
      # Fallback: last token that looks like a number
      for (i=NF; i>=1; --i) {
        if ($i ~ /^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$/) {print $i; exit}
      }
    }
  '
}

build_dir() {
  local d="$1"
  echo "==> Building in: $d" | tee -a "$OUT_LOG"
  ( cd "$d" && make clean && make ) >> "$OUT_LOG" 2>&1
}

run_bench() {
  local impl="$1"
  local d="$2"

  ( cd "$d" && {
      local exe
      exe="$(pick_exe)" || die "No executable ./lulesh (or ./lulesh2.0 or ./lulesh-cuda) in $d after build"

      for s in "${SIZES[@]}"; do
        local sum="0"
        local rep_times=()
        for rep in $(seq 1 "$REPS"); do
          echo "==> [$impl] s=$s rep=$rep : $exe -i 100 -s $s" | tee -a "$OUT_LOG"
          out="$($exe -i 100 -s "$s" 2>&1 | tee -a "$OUT_LOG")"

          t="$(printf "%s\n" "$out" | extract_time | head -n1 || true)"
          [[ -n "$t" ]] || die "Failed to parse timing for [$impl] s=$s rep=$rep in $d. Check $OUT_LOG."

          rep_times+=("$t")
          sum="$(awk -v a="$sum" -v b="$t" 'BEGIN{printf "%.12f", a+b}')"
        done

        avg="$(awk -v a="$sum" -v n="$REPS" 'BEGIN{printf "%.6f", a/n}')"
        AVG["$impl,$s"]="$avg"

        # Join rep times with ';'
        joined="$(IFS=';'; echo "${rep_times[*]}")"
        echo "${impl},${s},${avg},\"${joined}\"" >> "$OUT_CSV"
      done
    }
  )
}

# Build + run all
for impl in "${IMPLS[@]}"; do
  d_rel="${DIRS[$impl]}"
  [[ -d "${ROOT}/${d_rel}" ]] || die "Missing directory: ${ROOT}/${d_rel}"
  build_dir "${ROOT}/${d_rel}"
  run_bench "$impl" "${ROOT}/${d_rel}"
done

# Write a compact markdown table
{
  echo "# LULESH Benchmark Summary"
  echo
  echo "Command: \`./lulesh -i 100 -s {100,150,200,250,300}\`"
  echo "Repetitions per size: ${REPS}"
  echo
  echo "| Implementation | s=100 | s=150 | s=200 | s=250 | s=300 |"
  echo "|---|---:|---:|---:|---:|---:|"
  for impl in "${IMPLS[@]}"; do
    printf "| %s " "$impl"
    for s in "${SIZES[@]}"; do
      v="${AVG[$impl,$s]:-NA}"
      printf "| %s " "$v"
    done
    echo "|"
  done
  echo
  echo "Raw per-run data: \`$(basename "$OUT_CSV")\`"
  echo "Full logs: \`$(basename "$OUT_LOG")\`"
} > "$OUT_MD"

echo "Done."
echo "Wrote: $OUT_MD"
echo "Wrote: $OUT_CSV"
echo "Wrote: $OUT_LOG"
