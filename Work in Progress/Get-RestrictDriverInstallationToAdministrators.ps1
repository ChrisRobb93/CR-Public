$DomainName = "ENTERDOMAINNAMEHERE"
function Test-RegistryValue 
    {

        Param (
            [parameter(Mandatory=$True)]
            [ValidateNotNullOrEmpty()]$Path,
            
            [parameter(Mandatory=$True)]
            [ValidateNotNullOrEmpty()]$Value
            )

        Try
            {
                Get-ItemProperty -Path $Path -ErrorAction Stop | Select-Object -ExpandProperty $Value -ErrorAction Stop | Out-Null
                return $True
            }
        Catch
            {
                return $False
            }
    }

If ( (Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint' -Value RestrictDriverInstallationToAdministrators) -eq $True)
    {
        $RDITAValue = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint' -Name RestrictDriverInstallationToAdministrators).RestrictDriverInstallationToAdministrators
        If ( $RDITAValue -eq "1" )
            {
               #Write-Host "Machine is restricted"
               Return $True
            }

        If ( $RDITAValue -eq "0" )
            {
                #Write-Host "Machine is unrestricted. Veryify mitigations are inplace"
                $TrustedServers = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint' -Name TrustedServers).TrustedServers
                $ServerList = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint' -Name ServerList).ServerList                
                $PPaPServerList = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PackagePointAndPrint' -Name PackagePointAndPrintServerList).PackagePointAndPrintServerList

                If (( $TrustedServers -eq "1" ) -and ( $ServerList -like "*$($DomainName)*" ) -and ( $PPaPServerList -like "*")) 
                    {
                        #Write-Host "Appropriate mitigations are in place, allow Administrative override."
                        Return $True
                    }
                Else
                    {
                        #Write-Host "Appropriate mitigations are not in place, restrict Administrative override."
                        Return $False
                    }
            }
    }

ElseIf ( (Test-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint' -Value RestrictDriverInstallationToAdministrators) -eq $False)
    {
        #Write-Host "No override configured, device is safe."
        Return $true
    }