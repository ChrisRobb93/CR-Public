$clientName = Read-Host "Enter Client Name"
$clientAPIkey = Read-Host "Enter Client API Key"
$URL = Read-Host "Enter your DB URL for example https://assets.contoso.com"
$Address = Read-Host "Location Address"

$xml = [psobject]@{
    'ClientName' = $clientName
    'APIKey'     = $clientAPIkey
    'URL'        = $URL
    'Address'    = $Address

    }

$xml | Export-Clixml .\Assets_$($ClientName)_Config.xml