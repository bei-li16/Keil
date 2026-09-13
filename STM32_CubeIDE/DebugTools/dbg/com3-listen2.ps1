param([int]$sec = 15)
$p = New-Object System.IO.Ports.SerialPort('COM3',115200,'None',8,'One')
$p.ReadTimeout = 800
$p.Open()
$sw = [Diagnostics.Stopwatch]::StartNew()
$buf = ''
while ($sw.Elapsed.TotalSeconds -lt $sec) {
  try { $buf += $p.ReadExisting() } catch {}
  Start-Sleep -Milliseconds 200
}
$p.Close()
Write-Output ("received bytes: " + $buf.Length)
Write-Output '--- first 200 chars ---'
Write-Output $buf.Substring(0, [Math]::Min(200, $buf.Length))
Write-Output '--- message counts ---'
Write-Output ("Task100ms   : " + ([regex]::Matches($buf, 'Task100ms')).Count)
Write-Output ("Task1000ms d: " + ([regex]::Matches($buf, 'Task1000ms in default')).Count)
Write-Output ("Task1000ms N: " + ([regex]::Matches($buf, 'Task1000ms in Normal')).Count)
Write-Output '--- other/garbage lines ---'
($buf -split "`n" | Where-Object { $_ -notmatch '^\d{10}\|\[RELEASE\]\|Task100(0ms)?' } | Select-Object -First 5)
