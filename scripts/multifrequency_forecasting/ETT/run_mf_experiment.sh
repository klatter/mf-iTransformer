#!/bin/bash
set -euo pipefail

#=============================================================================
# Mixed-frequency experiment launcher (Bash)
#
# Usage:
#   ./run_mf_experiment.sh
#
# Description:
#   Launches mixed-frequency experiments using `MfITransformer` for ETT
#   datasets. Passes `--downsampling_rates` and `--freq_groups` to `run.py`.
#
# Notes:
#   - The script auto-detects appropriate downsampling rates for minute vs
#     hourly datasets via `get_rates`.
#   - Set `PYTHON_EXECUTABLE` to point to a specific Python interpreter.
#=============================================================================

PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../../.." >/dev/null 2>&1 && pwd )"
source "$PROJECT_ROOT/scripts/setup_env.sh"
cd "$PROJECT_ROOT"

PYTHON_BIN="${PYTHON_EXECUTABLE:-python}"
PRED_LENS=(96 192 336 720)
DATASETS=(ETTh1 ETTh2 ETTm1 ETTm2)
FREQ_GROUPS="0,1,2,3,4,5;6"

get_dims() {
  local dataset="$1"
  local pred_len="$2"
  if [[ "$dataset" == "ETTh1" && ( "$pred_len" == "96" || "$pred_len" == "192" ) ]]; then
    echo "256 256"
  else
    echo "128 128"
  fi
}

get_rates() {
  local dataset="$1"
  if [[ "$dataset" == ETTm* ]]; then
    echo "1 96"
  else
    echo "1 24"
  fi
}

for dataset in "${DATASETS[@]}"; do
  for pred_len in "${PRED_LENS[@]}"; do
    read -r d_model d_ff <<< "$(get_dims "$dataset" "$pred_len")"
    read -r r1 r2 <<< "$(get_rates "$dataset")"

    "$PYTHON_BIN" run.py \
      --is_training 1 \
      --model MfITransformer \
      --exp_name multi_train \
      --data "${dataset}_mixed" \
      --root_path ./dataset/ETT-small/ \
      --data_path "${dataset}_mixed.csv" \
      --model_id "${dataset}_mf_${pred_len}" \
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
      --downsampling_rates "$r1" "$r2" \
      --freq_groups "$FREQ_GROUPS" \
      --des Exp_MF \
      --itr 5
  done
done
