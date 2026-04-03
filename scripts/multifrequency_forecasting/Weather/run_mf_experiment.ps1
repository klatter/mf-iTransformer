#!/usr/bin/env pwsh
$ErrorActionPreference = 'Stop'

<#
.SYNOPSIS
Weather mixed-frequency experiment launcher (PowerShell)

.DESCRIPTION
Runs mixed-frequency `MfITransformer` experiments for the Weather dataset
across multiple prediction horizons. Passes `--downsampling_rates` and
`--freq_groups` to `run.py`.

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
$freqGroups = '0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19;20'

foreach ($predLen in $predLens) {
    & $python run.py `
        --is_training 1 `
        --model MfITransformer `
        --exp_name multi_train `
        --data custom_mixed `
        --root_path ./dataset/weather/ `
        --data_path weather_mixed.csv `
        --model_id "weather_mf_${predLen}" `
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
        --downsampling_rates 1 24 `
        --freq_groups $freqGroups `
        --des Exp_MF `
        --itr 5
}
