# Path to your CSV file
$csvPath = "C:\Path\Access Points_1.csv"

# Shared secret template name
$sharedSecretTemplate = "TemplateName"

# Import the CSV
$apList = Import-Csv -Path $csvPath

# Loop through each access point
foreach ($ap in $apList) {
    $clientName = $ap.serial_number
    $ipAddress = $ap.local_ip

    Write-Host "Creating RADIUS client: $clientName ($ipAddress)"

    # Use netsh to add the RADIUS client
    netsh nps add client name="$clientName" address="$ipAddress" vendor=standard sharedsecret="$sharedSecretTemplate"
}

Write-Host "✅ All clients have been added."
