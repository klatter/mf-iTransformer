#!/bin/bash

set -euo pipefail

# Resolve project root relative to this script to support running from any cwd.
PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../.." >/dev/null 2>&1 && pwd )"
cd "$PROJECT_ROOT"

# Load environment bootstrap when available.
if [ -f "$PROJECT_ROOT/scripts/setup_env.sh" ]; then
  # shellcheck disable=SC1091
  source "$PROJECT_ROOT/scripts/setup_env.sh"
fi

PYTHON_BIN="${PYTHON_EXECUTABLE:-python}"

# Ensure the dataset directory exists
DATA_DIR="./dataset"
SCRIPT_PATH="scripts/multifrequency_forecasting/generate_mf_datasets.py"

if [ ! -d "$DATA_DIR" ]; then
  echo "Error: Directory $DATA_DIR does not exist. Please place your raw CSVs there."
  exit 1
fi

echo "========================================================="
echo "Generating Mixed, Low, and High Datasets from Source"
echo "========================================================="

generate_dataset() {
  local dataset_path="$1"
  local output_prefix="$2"
  local ratio="$3"

  if [ ! -f "$dataset_path" ]; then
    echo "Warning: $dataset_path not found."
    return
  fi

  "$PYTHON_BIN" "$SCRIPT_PATH" \
    --dataset "$dataset_path" \
    --output_prefix "$output_prefix" \
    --low_freq_cols "OT" \
    --ratio "$ratio"
}

# ---------------------------------------------------------
# 1. Hourly ETT Datasets (ETTh1, ETTh2)
# Hourly -> Daily (Ratio: 24)
# ---------------------------------------------------------
for DATASET in "ETTh1" "ETTh2"; do
  echo "Processing $DATASET (Hourly -> Daily)..."
  generate_dataset "$DATA_DIR/ETT-small/$DATASET.csv" "$DATA_DIR/ETT-small/$DATASET" 24
done

# ---------------------------------------------------------
# 2. Minute ETT Datasets (ETTm1, ETTm2)
# 15 Minutes -> Daily (Ratio: 96)
# ---------------------------------------------------------
for DATASET in "ETTm1" "ETTm2"; do
  echo "Processing $DATASET (15 Min -> Daily)..."
  generate_dataset "$DATA_DIR/ETT-small/$DATASET.csv" "$DATA_DIR/ETT-small/$DATASET" 96
done

# ---------------------------------------------------------
# 3. Weather Dataset
# 10 Minutes -> 4 Hours (Ratio: 24)
# ---------------------------------------------------------
echo "Processing Weather (10m -> 4h)..."
generate_dataset "$DATA_DIR/weather/weather.csv" "$DATA_DIR/weather/weather" 24

echo "========================================================="
echo "Dataset preparation complete."
echo "========================================================="