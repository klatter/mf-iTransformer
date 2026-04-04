#!/bin/bash
set -euo pipefail

#=============================================================================
# Mixed-frequency grid search launcher (Bash)
#
# Usage:
#   ./run_mf_gridsearch.sh
#
# Description:
#   Performs a grid search over learning rates and model sizes for mixed-
#   frequency experiments using `MfITransformer` on ETT datasets. Passes
#   `--downsampling_rates` and `--freq_groups` to `run.py`.
#
# Environment variables:
#   PYTHON_EXECUTABLE - use this Python binary instead of `python`.
#=============================================================================

PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../../.." >/dev/null 2>&1 && pwd )"
source "$PROJECT_ROOT/scripts/setup_env.sh"
cd "$PROJECT_ROOT"

PYTHON_BIN="${PYTHON_EXECUTABLE:-python}"
DATASETS=(ETTh1 ETTh2 ETTm1 ETTm2)

# Optional override via environment variable `MF_DATASETS` (comma-separated).
# Example:
#   MF_DATASETS="ETTh1,ETTm1" ./run_mf_gridsearch.sh
if [ -n "${MF_DATASETS:-}" ]; then
  IFS=',' read -r -a DATASETS <<< "$MF_DATASETS"
  echo "Overriding datasets list from MF_DATASETS: ${DATASETS[*]}"
fi
LRS=(0.0001 0.0005 0.001)
DMODELS=(128 256 512)
FREQ_GROUPS="0,1,2,3,4,5;6"

get_rates() {
  local dataset="$1"
  if [[ "$dataset" == ETTm* ]]; then
    echo "1 96"
  else
    echo "1 24"
  fi
}

for dataset in "${DATASETS[@]}"; do
  read -r r1 r2 <<< "$(get_rates "$dataset")"
  for lr in "${LRS[@]}"; do
    for d_model in "${DMODELS[@]}"; do
      "$PYTHON_BIN" run.py \
        --is_training 1 \
        --model MfITransformer \
        --exp_name multi_train \
        --data "${dataset}_mixed" \
        --root_path ./dataset/ETT-small/ \
        --data_path "${dataset}_mixed.csv" \
        --model_id "${dataset}_mf_grid_pl96_lr${lr}_dm${d_model}" \
        --features M \
        --seq_len 96 \
        --label_len 48 \
        --pred_len 96 \
        --e_layers 2 \
        --enc_in 7 \
        --dec_in 7 \
        --c_out 7 \
        --d_model "$d_model" \
        --d_ff "$d_model" \
        --learning_rate "$lr" \
        --downsampling_rates "$r1" "$r2" \
        --freq_groups "$FREQ_GROUPS" \
        --des Exp_MF_Grid \
        --itr 1
    done
  done
done
