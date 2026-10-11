# Default verifies TEAM RTL. -Fixture explicitly selects harness demonstration.
param([switch]$Fixture,[switch]$Mutations)
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) { $python = Get-Command python3 -ErrorAction SilentlyContinue }
if (-not $python) { throw 'Install Python 3 and add it to PATH.' }
$argsList = @('run_tests.py')
if ($Fixture) { $argsList += '--fixture' }
if ($Mutations) { $argsList += '--mutations' }
& $python.Source @argsList
if ($LASTEXITCODE -ne 0) { throw "Verification failed or blocked; exit code=$LASTEXITCODE. See simulation/results." }
