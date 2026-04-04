#!/bin/bash
set -euo pipefail

#=============================================================================
# High-frequency baseline launcher (Bash)
#
# Usage:
#   ./run_hf_baseline.sh
#
# Description:
#   Runs high-frequency baseline experiments for ETT datasets using the
#   `iTransformer` model. Iterates over a list of prediction horizons and
#   datasets, and invokes `run.py` with appropriate per-dataset model sizes.
#
# Environment variables:
#   PYTHON_EXECUTABLE - if set, this Python binary is used instead of `python`.
#=============================================================================

PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../../.." >/dev/null 2>&1 && pwd )"
source "$PROJECT_ROOT/scripts/setup_env.sh"
cd "$PROJECT_ROOT"

PYTHON_BIN="${PYTHON_EXECUTABLE:-python}"
PRED_LENS=(96 192 336 720)
DATASETS=(ETTh1 ETTh2 ETTm1 ETTm2)

# Optional override via environment variable `MF_DATASETS` (comma-separated).
# Example:
#   MF_DATASETS="ETTh1,ETTm1" ./run_hf_baseline.sh
if [ -n "${MF_DATASETS:-}" ]; then
  IFS=',' read -r -a DATASETS <<< "$MF_DATASETS"
  echo "Overriding datasets list from MF_DATASETS: ${DATASETS[*]}"
fi

get_dims() {
  local dataset="$1"
  local pred_len="$2"
  if [[ "$dataset" == "ETTh1" && ( "$pred_len" == "96" || "$pred_len" == "192" ) ]]; then
    echo "256 256"
  else
    echo "128 128"
  fi
}

for dataset in "${DATASETS[@]}"; do
  for pred_len in "${PRED_LENS[@]}"; do
    read -r d_model d_ff <<< "$(get_dims "$dataset" "$pred_len")"

    "$PYTHON_BIN" run.py \
      --is_training 1 \
      --model iTransformer \
      --exp_name MTSF \
      --data "$dataset" \
      --root_path ./dataset/ETT-small/ \
      --data_path "${dataset}.csv" \
      --model_id "${dataset}_hf_${pred_len}" \
      --features M \
      --seq_len 96 \
      --label_len 48 \
      --pred_len "$pred_len" \
      --e_layers 2 \
      --enc_in 7 \
      --dec_in 7 \
      --c_out 7 \
      --d_model "$d_model" \
      --d_ff "$d_ff" \
      --des Exp_HF_Baseline \
      --itr 5
  done
done
