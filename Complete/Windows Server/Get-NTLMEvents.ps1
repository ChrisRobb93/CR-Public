# Get the events
$events = Get-WinEvent -ea SilentlyContinue -FilterHashtable @{
    ProviderName = "Microsoft-Windows-Security-Netlogon"
    Id = 8004
    StartTime = [datetime]::Today
}

# Initialize an array to hold the results
$eventList = @()

# Process each event
$events | ForEach-Object {
    $xmldoc = [xml]($_.ToXml())
    $eventDetails = [PSCustomObject]@{
        SChannelName    = $xmldoc.Event.EventData.Data.'#text'[0]
        Username        = $xmldoc.Event.EventData.Data.'#text'[1]
        Domain          = $xmldoc.Event.EventData.Data.'#text'[2]
        WorkstationName = $xmldoc.Event.EventData.Data.'#text'[3]
        SChannelType    = $xmldoc.Event.EventData.Data.'#text'[4]
    }

    # Add to the list
    $eventList += $eventDetails
}

# Export to CSV
$eventList | Export-Csv -Path "C:\Logs\NetlogonEvents.csv" -NoTypeInformation