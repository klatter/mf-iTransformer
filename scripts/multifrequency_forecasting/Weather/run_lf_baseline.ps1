#!/usr/bin/env pwsh
$ErrorActionPreference = 'Stop'

<#
.SYNOPSIS
Weather low-frequency baseline launcher (PowerShell)

.DESCRIPTION
Runs `iTransformer` low-frequency baseline experiments for the Weather dataset.

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

foreach ($predLen in $predLens) {
    & $python run.py `
        --is_training 1 `
        --model iTransformer `
        --exp_name MTSF `
        --data custom `
        --root_path ./dataset/weather/ `
        --data_path weather_low.csv `
        --model_id "weather_lf_${predLen}" `
        --features M `
        --seq_len 96 `
        --label_len 48 `
        --pred_len $predLen `
        --e_layers 3 `
        --enc_in 21 `
        --dec_in 21 `
        --c_out 21 `
        --d_model 512 `
        --d_ff 512 `
        --des Exp_LF_Baseline `
        --itr 5
}
