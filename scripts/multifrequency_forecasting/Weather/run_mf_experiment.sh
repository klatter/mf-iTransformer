#!/bin/bash
set -euo pipefail

#=============================================================================
# Weather mixed-frequency experiment launcher (Bash)
#
# Usage:
#   ./run_mf_experiment.sh
#
# Description:
#   Runs mixed-frequency `MfITransformer` experiments over a set of
#   prediction horizons. Passes `--downsampling_rates` and `--freq_groups`.
#=============================================================================

PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../../.." >/dev/null 2>&1 && pwd )"
source "$PROJECT_ROOT/scripts/setup_env.sh"
cd "$PROJECT_ROOT"

PYTHON_BIN="${PYTHON_EXECUTABLE:-python}"
PRED_LENS=(96 192 336 720)

for pred_len in "${PRED_LENS[@]}"; do
  "$PYTHON_BIN" run.py \
    --is_training 1 \
    --model MfITransformer \
    --exp_name multi_train \
    --data custom_mixed \
    --root_path ./dataset/weather/ \
    --data_path weather_mixed.csv \
    --model_id "weather_mf_${pred_len}" \
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
    --downsampling_rates 1 24 \
    --freq_groups "0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19;20" \
    --des Exp_MF \
    --itr 5
done
