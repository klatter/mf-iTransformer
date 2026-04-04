#!/usr/bin/env pwsh
$ErrorActionPreference = 'Stop'

<#
.SYNOPSIS
Mixed-frequency grid search launcher (PowerShell)

.DESCRIPTION
Performs a grid search over learning rates and model sizes for mixed-frequency
experiments using `MfITransformer` on ETT datasets. Passes `--downsampling_rates`
and `--freq_groups` to `run.py`.

.NOTES
Set `PYTHON_EXECUTABLE` to override the Python interpreter used.
#>

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ProjectRoot = (Resolve-Path (Join-Path $ScriptDir '..\..\..')).Path

if (Test-Path (Join-Path $ProjectRoot 'scripts/setup_env.ps1')) {
    . (Join-Path $ProjectRoot 'scripts/setup_env.ps1')
}

Set-Location $ProjectRoot
$python = if ($env:PYTHON_EXECUTABLE) { $env:PYTHON_EXECUTABLE } else { 'python' }

$datasets = @('ETTh1', 'ETTh2', 'ETTm1', 'ETTm2')

# Optional override: set the environment variable `MF_DATASETS` to a comma-separated
# list of dataset identifiers to run a restricted subset. Example:
#   $env:MF_DATASETS = 'ETTh1,ETTm1'; .\scripts\multifrequency_forecasting\ETT\run_mf_gridsearch.ps1
if ($env:MF_DATASETS) {
    $datasets = $env:MF_DATASETS -split ',' | ForEach-Object { $_.Trim() }
    Write-Host "Overriding datasets list from MF_DATASETS: $($datasets -join ',')"
}
$learningRates = @(0.0001, 0.0005, 0.001)
$dModels = @(128, 256, 512)
$freqGroups = '0,1,2,3,4,5;6'

function Get-Rates {
    param([string]$Dataset)
    if ($Dataset.StartsWith('ETTm')) {
        return @(1, 96)
    }
    return @(1, 24)
}

foreach ($dataset in $datasets) {
    $rates = Get-Rates -Dataset $dataset
    foreach ($learningRate in $learningRates) {
        foreach ($dModel in $dModels) {
            & $python run.py `
                --is_training 1 `
                --model MfITransformer `
                --exp_name multi_train `
                --data "${dataset}_mixed" `
                --root_path ./dataset/ETT-small/ `
                --data_path "${dataset}_mixed.csv" `
                --model_id "${dataset}_mf_grid_pl96_lr${learningRate}_dm${dModel}" `
                --features M `
                --seq_len 96 `
                --label_len 48 `
                --pred_len 96 `
                --e_layers 2 `
                --enc_in 7 `
                --dec_in 7 `
                --c_out 7 `
                --d_model $dModel `
                --d_ff $dModel `
                --learning_rate $learningRate `
                --downsampling_rates $rates[0] $rates[1] `
                --freq_groups $freqGroups `
                --des Exp_MF_Grid `
                --itr 1
        }
    }
}
