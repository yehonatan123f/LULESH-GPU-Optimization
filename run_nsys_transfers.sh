#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SIZES=(200 250 300)
ITERATIONS=100

# label -> relative dir
declare -A DIRS=(
  ["HeCBench-lulesh-omp"]="HeCBench-lulesh-omp"
  ["LULESH-codex-translation"]="LULESH-codex-translation"
  ["LULESH-codex-optimization"]="LULESH-codex-optimization"
  ["lulesh-cuda"]="lulesh-cuda"
  ["LULESH-intel-translation"]="LULESH-intel-translation"
  ["LULESH-openacc"]="LULESH-openacc"
)

# Keep a fixed order for reporting
IMPLS=("HeCBench-lulesh-omp" "LULESH-codex-translation" "LULESH-codex-optimization" "lulesh-cuda" "LULESH-intel-translation" "LULESH-openacc")

OUT_DIR="${ROOT}/nsys_transfer_results"
OUT_LOG="${OUT_DIR}/nsys_transfer_runs.log"
OUT_CSV="${OUT_DIR}/nsys_transfer_summary.csv"
OUT_SUMMARY_LIVE="${OUT_DIR}/nsys_transfer_live_summary.log"

mkdir -p "$OUT_DIR"
: > "$OUT_LOG"
: > "$OUT_CSV"
: > "$OUT_SUMMARY_LIVE"
echo "impl,s,h2d_mb,d2h_mb,report_base" >> "$OUT_CSV"

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

parse_transfer_mb() {
  # Reads nsys output from stdin and prints: "H2D_MB D2H_MB"
  awk '
    BEGIN{section=0; h2d=""; d2h=""}
    /cuda_gpu_mem_size_sum/ {section=1; next}
    section && /\[CUDA memcpy Host-to-Device\]/ {h2d=$1}
    section && /\[CUDA memcpy Device-to-Host\]/ {d2h=$1}
    section && /^Generated:/ {section=0}
    END{
      if (h2d=="") h2d="0";
      if (d2h=="") d2h="0";
      gsub(",", "", h2d);
      gsub(",", "", d2h);
      print h2d, d2h;
    }
  '
}

pick_trace() {
  case "$1" in
    LULESH-openacc)
      echo "cuda,openacc"
      ;;
    lulesh-cuda)
      echo "cuda"
      ;;
    HeCBench-lulesh-omp|LULESH-codex-translation|LULESH-codex-optimization|LULESH-intel-translation)
      echo "cuda,openmp"
      ;;
    *)
      echo "cuda"
      ;;
  esac
}

resolve_impl_dir() {
  local impl="$1"
  local base_dir="$2"

  if [[ -x "${base_dir}/lulesh" || -x "${base_dir}/lulesh2.0" || -x "${base_dir}/lulesh-cuda" ]]; then
    echo "$base_dir"
    return 0
  fi

  # Common nested locations for translated projects
  if [[ -d "${base_dir}/LULESH-openmp" ]]; then
    echo "${base_dir}/LULESH-openmp"
    return 0
  fi

  if [[ -d "${base_dir}/LULESH-openacc" ]]; then
    echo "${base_dir}/LULESH-openacc"
    return 0
  fi

  return 1
}

run_one() {
  local impl="$1"
  local d="$2"

  d="$(resolve_impl_dir "$impl" "$d")" || die "No executable or known subdir in $d"

  ( cd "$d" && {
      local exe
      exe="$(pick_exe)" || die "No executable in $d (expected ./lulesh, ./lulesh2.0, or ./lulesh-cuda). Build first."

      for s in "${SIZES[@]}"; do
        local out_base="${OUT_DIR}/${impl}/s${s}"
        mkdir -p "$(dirname "$out_base")"

        local trace
        trace="$(pick_trace "$impl")"
        echo "==> [$impl] s=$s : nsys profile --trace=${trace} $exe -i ${ITERATIONS} -s $s" | tee -a "$OUT_LOG"

        # Run nsys and capture output for parsing and logging.
        local out
        out="$({ nsys profile --trace="${trace}" --stats=true --cuda-memory-usage=true --force-overwrite=true -o "$out_base" "$exe" -i "$ITERATIONS" -s "$s"; } 2>&1 | tee -a "$OUT_LOG")"

        local h2d d2h
        read -r h2d d2h < <(printf "%s\n" "$out" | parse_transfer_mb)

        echo "==> [$impl] s=$s : H2D_MB=$h2d D2H_MB=$d2h" | tee -a "$OUT_LOG" | tee -a "$OUT_SUMMARY_LIVE"
        echo "${impl},${s},${h2d},${d2h},${out_base}" >> "$OUT_CSV"
      done
    }
  )
}

for impl in "${IMPLS[@]}"; do
  d_rel="${DIRS[$impl]}"
  [[ -d "${ROOT}/${d_rel}" ]] || die "Missing directory: ${ROOT}/${d_rel}"
  run_one "$impl" "${ROOT}/${d_rel}"
done

echo "Done."
echo "Log: $OUT_LOG"
echo "Summary: $OUT_CSV"
echo "Live summary: $OUT_SUMMARY_LIVE"
