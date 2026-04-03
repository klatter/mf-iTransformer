#!/bin/bash
set -euo pipefail

#=============================================================================
# Weather high-frequency baseline launcher (Bash)
#
# Usage:
#   ./run_hf_baseline.sh
#
# Description:
#   Runs `iTransformer` high-frequency baseline experiments for the Weather dataset.
#=============================================================================

PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../../.." >/dev/null 2>&1 && pwd )"
source "$PROJECT_ROOT/scripts/setup_env.sh"
cd "$PROJECT_ROOT"

PYTHON_BIN="${PYTHON_EXECUTABLE:-python}"
PRED_LENS=(96 192 336 720)

for pred_len in "${PRED_LENS[@]}"; do
  "$PYTHON_BIN" run.py \
    --is_training 1 \
    --model iTransformer \
    --exp_name MTSF \
    --data custom \
    --root_path ./dataset/weather/ \
    --data_path weather.csv \
    --model_id "weather_hf_${pred_len}" \
    --features M \
    --seq_len 96 \
    --label_len 48 \
    --pred_len "$pred_len" \
    --e_layers 3 \
    --enc_in 21 \
    --dec_in 21 \
    --c_out 21 \
    --d_model 512 \
    --d_ff 512 \
    --des Exp_HF_Baseline \
    --itr 5
done
