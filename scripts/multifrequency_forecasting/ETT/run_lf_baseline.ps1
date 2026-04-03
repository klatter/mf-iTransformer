#!/usr/bin/env pwsh
$ErrorActionPreference = 'Stop'

<#
.SYNOPSIS
Low-frequency baseline launcher (PowerShell)

.DESCRIPTION
Runs low-frequency baseline experiments for ETT datasets using the
`iTransformer` model with downsampled input CSVs ("*_low.csv").

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
            --data custom `
            --root_path ./dataset/ETT-small/ `
            --data_path "${dataset}_low.csv" `
            --model_id "${dataset}_lf_${predLen}" `
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
            --des Exp_LF_Baseline `
            --itr 5
    }
}
