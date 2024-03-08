#Add SSID and PSK here

$SSID = 'SSID'
$PSK  = 'sup3rs3cr3tPSK'

#Check that the Wireless AutoConfig Service (wlansvc) is running
$serviceStatus = Get-Service -Name wlansvc | Select-Object -ExpandProperty Status
if ($serviceStatus -ne "Running") {
    Write-Host -ForegroundColor Red "The Wireless AutoConfig Service (wlansvc) is not running.  Perhaps this device doesn't have a wireless adapter.  Exiting without creating the profile."
    Exit 1
}

$list=(netsh.exe wlan show profiles) -match '\s{2,}:\s'
#Check if SSID exists
If($list -like "*$($SSID)*"){Write-Host "$SSID already exists."
    exit 0}
Else{
#Create a wifi profile file to be imported 
$guid = New-Guid
$wirelessProfilePath = "$($ENV:TEMP)\$guid.SSID"
$HexArray = $ssid.ToCharArray() | foreach-object { [System.String]::Format("{0:X}", [System.Convert]::ToUInt32($_)) }
$HexSSID = $HexArray -join ""
@"
<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
    <name>$($SSID)</name>
    <SSIDConfig>
        <SSID>
            <hex>$($HexSSID)</hex>
            <name>$($SSID)</name>
        </SSID>
    </SSIDConfig>
    <connectionType>ESS</connectionType>
    <connectionMode>auto</connectionMode>
    <MSM>
        <security>
            <authEncryption>
                <authentication>WPA2PSK</authentication>
                <encryption>AES</encryption>
                <useOneX>false</useOneX>
            </authEncryption>
            <sharedKey>
                <keyType>passPhrase</keyType>
                <protected>false</protected>
                <keyMaterial>$($PSK)</keyMaterial>
            </sharedKey>
        </security>
    </MSM>
    <MacRandomization xmlns="http://www.microsoft.com/networking/WLAN/profile/v3">
        <enableRandomization>false</enableRandomization>
        <randomizationSeed>1451755948</randomizationSeed>
    </MacRandomization>
</WLANProfile>
"@ | out-file "$wirelessProfilePath"

#Import the file containing the wireless profile
netsh wlan add profile filename="$wirelessProfilePath" user=all

#Delete the file containing the wireless profile
Start-sleep -Seconds 5
remove-item "$wirelessProfilePath" -Force

#Check if the file was successfully deleted.
if (Get-Item "$wirelessProfilePath" -ErrorAction SilentlyContinue) {
    Write-Host -ForegroundColor Red "The file containing the wireless profile was unable to be deleted.  Investigate and remove this file as it contains a password!"
    exit 1
}
}
