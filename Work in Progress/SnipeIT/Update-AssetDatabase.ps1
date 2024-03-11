<#
.SYNOPSIS
	This script utilizes the SnipeITPS Module to automatically and regularly update assets in a SnipeIT Database.
.DESCRIPTION
    This script retrieves information about the local device and checks if the corresponding asset exists in a database. 
    If an asset is found, it compares the current values stored in the database with the locally cached values. 
    If any differences are detected, the online asset is updated to match the locally cached values. If no asset is found, a new one is created.

    Before creating a new asset, the script ensures that all required values exist in the database. This includes checking for:
    - Duplicate Serial Number
    - Manufacturer
    - Category
    - Model
    - Company
    - Location

    Once all the necessary checks have been completed, a new asset is created in the database.
.PARAMETER <Parameter_Name>
    N/A
.INPUTS
	!IMPORTANT! - This package requires a 'client_config.xml' file to exist in the same directory.
    If you have not yet created this, please run the accompanying New-ClientConfig.ps1 to generate this file.
.OUTPUTS
	None at present. Looking to add logging in future.
.NOTES
	Version:        1.1
	Author:         Chris Robb
	Creation Date:  14-Feb-2024
	Purpose/Change: Initial script development
  
.EXAMPLE
	.\Update-AssetDatabase.ps1
#>

<# Import Client XML
If you dont want to store these files locally you can update the values below to be stored at runtime and removed after.
$APIKey = "Supersecretapikey"
$URL = "https://assets.contoso.com"
$clientName = "contoso"
$address = "10 Downing Street, London"
#>

<# These fields are optional should you want to deploy the config on the local client
$xml = Import-Clixml "$PSScriptRoot\client_config.xml"
$APIKey = $xml.APIKey
$URL = $xml.URL
$clientName = $xml.clientName
$clientAddress = $xml.address
#>

#Set TLS for older devices
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

## Install & Import required modules
If(Get-Module -ListAvailable SnipeITPS)
    {
        Import-Module SnipeitPS
    }
Else
    {
        Install-PackageProvider NuGet -Force -Confirm:$False
        Install-Module SnipeitPS -Force -Confirm:$False 
        Import-Module SnipeitPS
    }


Try {

## Connect to Asset Database
Connect-SnipeitPS -URL $URL -apiKey $APIKey

## Chassis Type to Category Map
$enclosureType = Get-WmiObject Win32_SystemEnclosure | Select-Object ChassisTypes

If ($enclosureType.ChassisTypes[0] -eq 12 -or $enclosureType.ChassisTypes[0]-eq 21) {} #Ignore Docking Stations
 
else {
     switch ($enclosureType.ChassisTypes[0]) {
     {$_ -in "8", "9", "10", "11", "12", "14", "18", "21","31"} {$ChassisType = "Laptop"}
     {$_ -in "32"} {$ChassisType = "Tablet"}
     {$_ -in "3", "4", "5", "6", "7", "15", "16"} {$ChassisType = "Desktop"}
     {$_ -in "23"}{$ChassisType = "Server"}
     Default {$ChassisType = "Unknown" }
     }
 }


## Gather Local client details
$deviceDetails = [psobject]@{
    'name'            = $env:COMPUTERNAME
    'serial'          = (Get-WmiObject -Class Win32_Bios).SerialNumber
    'model_id'        = (Get-WmiObject -Class Win32_ComputerSystem).Model
    'warranty_months' = 36
    'category'        = $ChassisType
    'manufacturer'    = (Get-WmiObject -Class Win32_ComputerSystem).Manufacturer
    'company_id'      = $clientName
        }

<# If you have SnipeIT Custom Fields they can be added here. #>
$custom_fieldset = [psobject] @{
    _snipeit_cpu_4              = ((Get-WmiObject -Class Win32_Processor).Name | Select-Object -First 1)
    _snipeit_ram_5              = "$((Get-WMIObject -Class Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).sum /1gb)GB"
    _snipeit_storage_7          = "$(ForEach($Disk in Get-Disk){$Disk.Model + " | " + [Int]$($Disk.Size /1GB) + 'GB'})"
    _snipeit_firmware_8         = (Get-WmiObject -Class Win32_Bios).SMBIOSBIOSVersion
    _snipeit_operating_system_9 = (Get-Item "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").GetValue('ProductName')
    _snipeit_build_version_10   = (Get-WmiObject -Class Win32_OperatingSystem).Version
}

## Check Database for IDs
$pattern = "[^A-Za-z0-9-\s]"
$cleanModel = [regex]::Replace($deviceDetails.model_id,$pattern,"")

$onlineModel = (Get-SnipeItModel -Search $cleanModel)
$onlineCompany = (Get-SnipeitCompany -name $clientName).Id
$onlineLocation = (Get-SnipeitLocation -search $clientName)
$onlineCategory  = (Get-SnipeitCategory -search $deviceDetails.category).Id


## Check if Asset Exists already
    If($onlineAsset = Get-SnipeitAsset -serial $deviceDetails.serial -ErrorAction Stop)
        {
            #Asset Found
            #Compare online asset to local and check for changes

            $objRef1 = @{
                Name           = $onlineAsset.Name;
                Serial         = $onlineAsset.serial;
                Notes          = $onlineAsset.notes;
                modelID        = $onlineasset.Model.id;
                categoryID     = $onlineasset.category.id;
                companyID      = $onlineAsset.company.id;
                locationID     = $onlineAsset.rta_location.id;
                CPU            = $onlineAsset.custom_fields.CPU.value;
                RAM            = $onlineAsset.custom_fields.RAM.Value;
                Storage        = $onlineAsset.custom_fields.Storage.value;
                Firmware       = $onlineAsset.custom_fields.Firmware.value;
                OS             = $onlineAsset.custom_fields.'Operating System'.value;
                buildVersion   = $onlineAsset.custom_fields.'Build Version'.value;
                }

            $objRef2 = @{
                Name           = $deviceDetails.name;
                Serial         = $deviceDetails.serial;
                Notes          = $deviceDetails.notes;
                modelID        = $onlineModel.id;
                categoryID     = $onlineCategory;
                companyID      = $onlineCompany;
                locationID     = $onlineLocation;          
                RAM            = $custom_fieldset._snipeit_ram_5;
                CPU            = $custom_fieldset._snipeit_cpu_4;
                Storage        = $custom_fieldset._snipeit_storage_7;
                Firmware       = $custom_fieldset._snipeit_firmware_8;
                OS             = $custom_fieldset._snipeit_operating_system_9;
                buildVersion   = $custom_fieldset._snipeit_build_version_10;
                }            

                $compare = Compare-Object $objRef1.Values $objRef2.Values

            #If record doesn't match, update online record.
                If($compare -ne $null)
                    {
                        Write-Host "Changes in asset detected. Updating $URL"
                        Set-SnipeitAsset -id $onlineAsset.id -warranty_months $deviceDetails.warranty_months -name $deviceDetails.name -model_id $onlineModel.id -serial $deviceDetails.serial -notes $deviceDetails.notes -company_id $onlineCompany -customfields $custom_fieldset -rtd_location_id $onlineLocation.id
                    }
                ElseIf($compare -eq $null)
                    { 
                        #Objects match, do nothing.
                        Return "No changes needed"
                    }
        }
    Else 
    #Asset doesn't exist. Check fields in database for existing values.
        {
            Write-Host "Asset $($deviceDetails.serial) not found in Database. Running additional checks..."

            # Check Name for duplicates - COMPLETE
            Write-Host "Looking for $($env:COMPUTERNAME) in Database..."
            If($onlineAsset = Get-SnipeitAsset -search $env:COMPUTERNAME -ErrorAction Stop)
            {Write-Host "Device found with the same name found. Serial Number: $($deviceByName.serial)"}
            Else{}

            # Check Manufacturer - COMPLETE
            Write-Host "Looking for MANUFACTURER $($deviceDetails.manufacturer) in Database..."
            If($onlineManufacturer = Get-SnipeitManufacturer -search $deviceDetails.manufacturer)
                {
                    Write-Host "$($deviceDetails.manufacturer) found in Database. No action needed."
                }
            Else
                {
                    Write-Host "$($deviceDetails.manufacturer) not found. Creating a new entry."
                    $onlineManufacturer = New-SnipeitManufacturer -Name $deviceDetails.manufacturer -ErrorAction Stop
                    Write-Host "MANUFACTURER $($deviceDetails.manufacturer) created in Database. "
                }

            # Check Category - COMPLETE
            Write-Host "Looking for CATEGORY $($deviceDetails.category) in Database..."
            If($onlineCategory)
                {
                    Write-Host "$($deviceDetails.category) found in Database. No action needed."
                }
            Else
                {
                    Write-Host "$($deviceDetails.category) not found. Creating a new entry."
                    $onlineModel = New-SnipeitCategory -name $deviceDetails.category -category_type asset -ErrorAction Stop
                    Write-Host "CATEGORY $($deviceDetails.category) created in Database. "
                }

            # Check Model - COMPLETE
            Write-Host "Looking for MODEL $cleanModel in Database..."
            If($onlineModel)
                {
                    Write-Host "$cleanModel found in Database. No action needed."
                }
            Else
                {
                    Write-Host "$cleanModel not found. Creating a new entry."
                    $fieldset = Get-SnipeitFieldset | Where-Object {$_.Name -eq $ChassisType} | Select-Object -ExpandProperty id
                    $onlineModel = New-SnipeitModel -Name $cleanModel -category_id $onlineCategory -manufacturer_id $onlineManufacturer.id -fieldset_id $fieldset -ErrorAction Stop
                    Write-Host "MODEL $cleanModel created in Database."
                }  
            
            # Check Company - Complete
            Write-Host "Looking for COMPANY $($deviceDetails.company_id) in Database..."
            If($onlineCompany)
                {
                    Write-Host "$($deviceDetails.company_id) found in Database. No action needed."
                }
            Else
                {
                    Write-Host "$($deviceDetails.company_id) not found. Creating a new entry."
                    New-SnipeitCompany -name $deviceDetails.company_id -ErrorAction Stop
                    $onlineCompany = (Get-SnipeitCompany -name $clientName).Id
                    Write-Host "COMPANY $($deviceDetails.company_id) created in Database. "
                }

            # Check Location
            Write-Host "Looking for LOCATION $($deviceDetails.location_id) in Database..."
            If($onlineLocation)
                {
                    Write-Host "$($deviceDetails.location_id) found in Database. No action needed."
                }
            Else
                {
                    Write-Host "$($deviceDetails.location_id) not found. Creating a new entry."
                    $onlineLocation = New-SnipeitLocation -name $clientName -address $addressLine1 -address2 $addressLine2 -city $city -state $state -country $country -zip $postcode -ErrorAction Stop
                    Write-Host "LOCATION $($deviceDetails.location_id) created in Database. "
                }
            
            Write-Host "Creating new asset $($deviceDetails.Name)"
            New-SnipeitAsset -status_id 6 -warranty_months $deviceDetails.warranty_months -name $deviceDetails.name -model_id $onlineModel.id -serial $deviceDetails.serial -notes $deviceDetails.notes -company_id $onlineCompany -customfields $custom_fieldset -rtd_location_id $onlineLocation -ErrorAction Stop
        }
}

Catch
{ $_
}