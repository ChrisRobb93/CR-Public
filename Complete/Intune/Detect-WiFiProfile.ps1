#Put your SSID in here
$SSID = "SSID"

if ((netsh.exe wlan show profiles) -match $SSID) {  
    Write-Host Managed Wi-Fi Corporate network found
    exit 0
}
else {
    Write-Host Managed Wi-Fi Corporate network not found
    exit 1
}