# PowerShell entry: avoid CMD interpreting &, >, | in GDB expressions.
$pythonExe = Join-Path $PSScriptRoot 'bin/python/python.exe'
if (-not (Test-Path -LiteralPath $pythonExe -PathType Leaf)) {
    Write-Error 'Missing bundled Python: copy the complete tools directory.'
    exit 2
}
& $pythonExe -B (Join-Path $PSScriptRoot 'dt.py') @args
exit $LASTEXITCODE
