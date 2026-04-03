#!/usr/bin/env pwsh
$ErrorActionPreference = 'Stop'

<#
.SYNOPSIS
Weather mixed-frequency grid search launcher (PowerShell)

.DESCRIPTION
Performs a grid search over learning rates and model sizes for mixed-frequency
experiments using `MfITransformer` on the Weather dataset.

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

$learningRates = @(0.0001, 0.0005, 0.001)
$dModels = @(128, 256, 512)
$freqGroups = '0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19;20'

foreach ($learningRate in $learningRates) {
    foreach ($dModel in $dModels) {
        & $python run.py `
            --is_training 1 `
            --model MfITransformer `
            --exp_name multi_train `
            --data custom_mixed `
            --root_path ./dataset/weather/ `
            --data_path weather_mixed.csv `
            --model_id "weather_mf_grid_pl96_lr${learningRate}_dm${dModel}" `
            --features M `
            --seq_len 96 `
            --label_len 48 `
            --pred_len 96 `
            --e_layers 3 `
            --enc_in 21 `
            --dec_in 21 `
            --c_out 21 `
            --d_model $dModel `
            --d_ff $dModel `
            --learning_rate $learningRate `
            --downsampling_rates 1 24 `
            --freq_groups $freqGroups `
            --des Exp_MF_Grid `
            --itr 1
    }
}
