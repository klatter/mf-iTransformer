#!/usr/bin/env pwsh
$ErrorActionPreference = 'Stop'

<#
.SYNOPSIS
High-frequency baseline launcher (PowerShell)

.DESCRIPTION
Runs high-frequency baseline experiments for ETT datasets using the
`iTransformer` model. Iterates over prediction horizons and datasets and
invokes `run.py` with appropriate model configuration.

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

$predLens = @(96, 192, 336, 720)
$datasets = @('ETTh1', 'ETTh2', 'ETTm1', 'ETTm2')

# Optional override: set the environment variable `MF_DATASETS` to a comma-separated
# list of dataset identifiers to run a restricted subset. Example:
#   $env:MF_DATASETS = 'ETTh1,ETTm1'; .\scripts\multifrequency_forecasting\ETT\run_hf_baseline.ps1
if ($env:MF_DATASETS) {
    $datasets = $env:MF_DATASETS -split ',' | ForEach-Object { $_.Trim() }
    Write-Host "Overriding datasets list from MF_DATASETS: $($datasets -join ',')"
}

function Get-Dims {
    param([string]$Dataset, [int]$PredLen)
    if ($Dataset -eq 'ETTh1' -and ($PredLen -eq 96 -or $PredLen -eq 192)) {
        return @(256, 256)
    }
    return @(128, 128)
}

foreach ($dataset in $datasets) {
    foreach ($predLen in $predLens) {
        $dims = Get-Dims -Dataset $dataset -PredLen $predLen
        $dModel = $dims[0]
        $dFf = $dims[1]

        & $python run.py `
            --is_training 1 `
            --model iTransformer `
            --exp_name MTSF `
            --data $dataset `
            --root_path ./dataset/ETT-small/ `
            --data_path "$dataset.csv" `
            --model_id "${dataset}_hf_${predLen}" `
            --features M `
            --seq_len 96 `
            --label_len 48 `
            --pred_len $predLen `
            --e_layers 2 `
            --enc_in 7 `
            --dec_in 7 `
            --c_out 7 `
            --d_model $dModel `
            --d_ff $dFf `
            --des Exp_HF_Baseline `
            --itr 5
    }
}
