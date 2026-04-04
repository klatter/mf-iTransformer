# Multifrequency Forecasting Scripts

This folder contains dataset preparation and experiment launch scripts for:

- High-frequency baseline (`iTransformer`)
- Low-frequency baseline (`iTransformer`)
- Mixed-frequency experiment (`MfITransformer`)
- Mixed-frequency grid search (`MfITransformer`)

Both Bash (`.sh`) and PowerShell (`.ps1`) variants are available.

## Folder Layout

- `prepare_datasets.sh` / `prepare_datasets.ps1`: generate `_low.csv` and `_mixed.csv` datasets
- `ETT/`: ETTh1, ETTh2, ETTm1, ETTm2 experiments
- `Weather/`: weather experiments

## PowerShell Scripts

### ETT

- `ETT/run_hf_baseline.ps1`
- `ETT/run_lf_baseline.ps1`
- `ETT/run_mf_experiment.ps1`
- `ETT/run_mf_gridsearch.ps1`

### Weather

- `Weather/run_hf_baseline.ps1`
- `Weather/run_lf_baseline.ps1`
- `Weather/run_mf_experiment.ps1`
- `Weather/run_mf_gridsearch.ps1`

## Typical Workflow (Windows / PowerShell)

1. Generate prepared datasets:

```powershell
.\scripts\multifrequency_forecasting\prepare_datasets.ps1
```

2. Run one of the experiment launchers, for example:

```powershell
.\scripts\multifrequency_forecasting\ETT\run_mf_experiment.ps1
```

### Overriding which datasets run

You can override the default dataset list used by the launcher scripts using the
`MF_DATASETS` environment variable. Provide a comma-separated list of dataset
identifiers (e.g. `ETTh1`, `ETTm1`). This works for both Bash and PowerShell
launchers.

PowerShell example (run only ETTh1 and ETTm1):

```powershell
$env:MF_DATASETS = 'ETTh1,ETTm1'
.\scripts\multifrequency_forecasting\ETT\run_mf_experiment.ps1
```

Bash example (run only ETTh1 and ETTm1):

```bash
MF_DATASETS="ETTh1,ETTm1" ./scripts/multifrequency_forecasting/ETT/run_mf_experiment.sh
```

or:

```powershell
.\scripts\multifrequency_forecasting\Weather\run_hf_baseline.ps1
```

## Notes

- Scripts auto-source `scripts/setup_env.ps1` when present.
- If `PYTHON_EXECUTABLE` is set, it is used; otherwise scripts fall back to `python`.
- MF scripts pass `--downsampling_rates` and `--freq_groups` explicitly.

## MF Arguments and Examples

- `--downsampling_rates`: one or more integers. Provide a single value to apply the same
	rate to all groups, or one value per group. Example: `--downsampling_rates 1 24`.
- `--freq_groups`: semicolon-separated groups of feature indices. Example:
	- `"0,1;2,3,4"` → two groups: indices [0,1] and [2,3,4]
	- `"0,1,2,3,4,5;6"` → two groups, where the last index is grouped separately.

### Example CLI (Bash)

```bash
python run.py --is_training 1 --model MfITransformer --exp_name multi_train \
	--data ETTh1_mixed --root_path ./dataset/ETT-small/ --data_path ETTh1_mixed.csv \
	--seq_len 96 --label_len 48 --pred_len 96 --downsampling_rates 1 24 \
	--freq_groups "0,1,2,3,4,5;6"
```

### Example CLI (PowerShell)

```powershell
.
un.py --is_training 1 --model MfITransformer --exp_name multi_train \
	--data custom_mixed --root_path ./dataset/weather/ --data_path weather_mixed.csv \
	--seq_len 96 --label_len 48 --pred_len 192 --downsampling_rates 1 24 \
	--freq_groups "0,1,2;3,4"
```
