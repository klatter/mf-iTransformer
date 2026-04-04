#!/usr/bin/env pwsh
$ErrorActionPreference = 'Stop'

<#
.SYNOPSIS
Mixed-frequency experiment launcher (PowerShell)

.DESCRIPTION
Launches mixed-frequency experiments using `MfITransformer` for ETT datasets.
Automatically chooses downsampling rates for minute vs hourly datasets and
passes `--downsampling_rates` and `--freq_groups` to `run.py`.

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
#   $env:MF_DATASETS = 'ETTh1,ETTm1'; .\scripts\multifrequency_forecasting\ETT\run_mf_experiment.ps1
if ($env:MF_DATASETS) {
    $datasets = $env:MF_DATASETS -split ',' | ForEach-Object { $_.Trim() }
    Write-Host "Overriding datasets list from MF_DATASETS: $($datasets -join ',')"
}
$freqGroups = '0,1,2,3,4,5;6'

function Get-Dims {
    param([string]$Dataset, [int]$PredLen)
    if ($Dataset -eq 'ETTh1' -and ($PredLen -eq 96 -or $PredLen -eq 192)) {
        return @(256, 256)
    }
    return @(128, 128)
}

function Get-Rates {
    param([string]$Dataset)
    if ($Dataset.StartsWith('ETTm')) {
        return @(1, 96)
    }
    return @(1, 24)
}

foreach ($dataset in $datasets) {
    foreach ($predLen in $predLens) {
        $dims = Get-Dims -Dataset $dataset -PredLen $predLen
        $dModel = $dims[0]
        $dFf = $dims[1]
        $rates = Get-Rates -Dataset $dataset

        & $python run.py `
            --is_training 1 `
            --model MfITransformer `
            --exp_name multi_train `
            --data "${dataset}_mixed" `
            --root_path ./dataset/ETT-small/ `
            --data_path "${dataset}_mixed.csv" `
            --model_id "${dataset}_mf_${predLen}" `
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
            --downsampling_rates $rates[0] $rates[1] `
            --freq_groups $freqGroups `
            --des Exp_MF `
            --itr 5
    }
}
