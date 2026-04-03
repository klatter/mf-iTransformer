#!/usr/bin/env pwsh

# Resolve project root from script location to support running from any cwd.
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ProjectRoot = $ScriptDir
for ($i = 0; $i -lt 8; $i++) {
    if (Test-Path (Join-Path $ProjectRoot 'run.py')) { break }
    $ProjectRoot = Split-Path $ProjectRoot -Parent
}
if (-not (Test-Path (Join-Path $ProjectRoot 'run.py'))) { throw 'Could not locate project root (run.py).' }

Set-Location $ProjectRoot
if (Test-Path (Join-Path $ProjectRoot 'scripts/setup_env.ps1')) {
    . (Join-Path $ProjectRoot 'scripts/setup_env.ps1')
}

$python = if ($env:PYTHON_EXECUTABLE) { $env:PYTHON_EXECUTABLE } elseif ($env:CONDA_PREFIX -and (Test-Path (Join-Path $env:CONDA_PREFIX 'python.exe'))) { Join-Path $env:CONDA_PREFIX 'python.exe' } else { 'python' }

$dataDir = Join-Path $ProjectRoot 'dataset'
$scriptPath = Join-Path $ProjectRoot 'scripts/multifrequency_forecasting/generate_mf_datasets.py'

Write-Host "========================================================="
Write-Host "Generating MIXED and HIGH Datasets for Experiments"
Write-Host "========================================================="

<#
.SYNOPSIS
Prepare Mixed / Low / High frequency datasets

.DESCRIPTION
This script wraps the Python utility that generates `_mixed.csv` and
`_low.csv` variants from raw CSV inputs. It is intended to be run from
PowerShell on Windows; a Bash variant `prepare_datasets.sh` exists for Unix.

.NOTES
The script looks for `scripts/generate_mf_datasets.py` and will call the
Python executable specified by `PYTHON_EXECUTABLE` environment variable
when available.
#>

function Invoke-MFDatasetGeneration {
    param(
        [Parameter(Mandatory = $true)][string]$DatasetPath,
        [Parameter(Mandatory = $true)][string]$OutputPrefix,
        [Parameter(Mandatory = $true)][string]$LowFreqCols,
        [Parameter(Mandatory = $true)][int]$Ratio
    )

    if (-not (Test-Path $DatasetPath)) {
        Write-Warning "Missing input file $DatasetPath - skipping generation."
        return
    }

    & $python $scriptPath `
      --dataset $DatasetPath `
      --output_prefix $OutputPrefix `
      --low_freq_cols $LowFreqCols `
      --ratio $Ratio
}

function Invoke-MFGroupGeneration {
    param(
        [Parameter(Mandatory = $true)][string[]]$DatasetNames,
        [Parameter(Mandatory = $true)][string]$Label,
        [Parameter(Mandatory = $true)][int]$Ratio
    )

    foreach ($name in $DatasetNames) {
        Write-Host "`nProcessing $name ($Label)..."
        Invoke-MFDatasetGeneration `
          -DatasetPath (Join-Path $dataDir "ETT-small\$name.csv") `
          -OutputPrefix (Join-Path $dataDir "ETT-small\$name") `
          -LowFreqCols 'OT' `
          -Ratio $Ratio
    }
}

# ---------------------------------------------------------
# 1. Hourly ETT Datasets (ETTh1, ETTh2) -> Target: Daily
# Ratio: 24 (1 hour * 24 = 1 day)
# ---------------------------------------------------------
Invoke-MFGroupGeneration -DatasetNames @('ETTh1', 'ETTh2') -Label 'Hourly -> Daily' -Ratio 24

# ---------------------------------------------------------
# 2. Minute ETT Datasets (ETTm1, ETTm2) -> Target: Daily
# Ratio: 96 (15 mins * 4/hr * 24 hrs = 1 day)
# ---------------------------------------------------------
Invoke-MFGroupGeneration -DatasetNames @('ETTm1', 'ETTm2') -Label '15-Min -> Daily' -Ratio 96

# ---------------------------------------------------------
# 3. Weather Dataset (10m) -> Target: 4 Hours
# Ratio: 24 (10 mins * 6/hr * 4 hrs = 4 hours)
# ---------------------------------------------------------
Write-Host "`nProcessing Weather (10m -> 4h)..."
Invoke-MFDatasetGeneration `
  -DatasetPath (Join-Path $dataDir 'weather\weather.csv') `
  -OutputPrefix (Join-Path $dataDir 'weather\weather') `
  -LowFreqCols 'OT' `
  -Ratio 24

Write-Host "`n========================================================="
Write-Host "Dataset generation complete!"
Write-Host "========================================================="