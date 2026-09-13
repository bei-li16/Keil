$p = New-Object System.IO.Ports.SerialPort('COM3',115200,'None',8,'One')
$p.ReadTimeout = 800
$p.Open()
$sw = [Diagnostics.Stopwatch]::StartNew()
$buf = ''
while ($sw.Elapsed.TotalSeconds -lt 8) {
  try { $buf += $p.ReadExisting() } catch {}
  Start-Sleep -Milliseconds 200
}
$p.Close()
Write-Output ("received bytes: " + $buf.Length)
Write-Output '--- content ---'
Write-Output $buf
