try {
  $p = New-Object System.IO.Ports.SerialPort('COM3',115200)
  $p.Open()
  Write-Output "RESULT: COM3 opened OK - NOT occupied"
  $p.Close()
} catch {
  Write-Output ("RESULT: COM3 open FAILED - " + $_.Exception.Message)
}
