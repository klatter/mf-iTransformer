#!/bin/bash
set -euo pipefail

#=============================================================================
# Weather mixed-frequency grid search launcher (Bash)
#
# Usage:
#   ./run_mf_gridsearch.sh
#
# Description:
#   Grid-search over learning rates and model sizes for `MfITransformer` on the
#   Weather mixed dataset. Passes `--downsampling_rates` and `--freq_groups`.
#=============================================================================
#!/bin/bash

set -euo pipefail
PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../../.." >/dev/null 2>&1 && pwd )"
source "$PROJECT_ROOT/scripts/setup_env.sh"
cd "$PROJECT_ROOT"

PYTHON_BIN="${PYTHON_EXECUTABLE:-python}"
LRS=(0.0001 0.0005 0.001)
DMODELS=(128 256 512)

for lr in "${LRS[@]}"; do
  for d_model in "${DMODELS[@]}"; do
    "$PYTHON_BIN" run.py \
      --is_training 1 \
      --model MfITransformer \
      --exp_name multi_train \
      --data custom_mixed \
      --root_path ./dataset/weather/ \
      --data_path weather_mixed.csv \
      --model_id "weather_mf_grid_pl96_lr${lr}_dm${d_model}" \
      --features M \
      --seq_len 96 \
      --label_len 48 \
      --pred_len 96 \
      --e_layers 3 \
      --enc_in 21 \
      --dec_in 21 \
      --c_out 21 \
      --d_model "$d_model" \
      --d_ff "$d_model" \
      --learning_rate "$lr" \
      --downsampling_rates 1 24 \
      --freq_groups "0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19;20" \
      --des Exp_MF_Grid \
      --itr 1
  done
done
