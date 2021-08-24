Try 
    {
        $PrimaryBootOrder = Get-WmiObject -class Lenovo_BiosSetting -namespace root\wmi | Where-Object {($_.CurrentSetting -Like "Primary Boot Sequence*")} -ErrorAction Stop
        $PrimaryBootString = ($PrimaryBootOrder.CurrentSetting).Split(",;")
        $PrimaryBootDevice = ($PrimaryBootString[1]).Split(":")

        #Write-Host "Primary Boot Device: $($PrimaryBootDevice[0])"
        $BootOrders = Get-WmiObject -class Lenovo_BiosSetting -namespace root\wmi | Where-Object {($_.CurrentSetting -Like "*Boot Sequence*")} -ErrorAction Stop
        
        ForEach($BootOrder in $BootOrders)
        {
            If($PrimaryBootOrder.InstanceName -ine $BootOrder.InstanceName)
                {
                    $BootString = ($BootOrder.CurrentSetting).Split(",;")
                    $BootDevice = ($BootString[1]).Split(",;:")

                    If($PrimaryBootDevice[0] -ine $BootDevice[0])
                        {
                            #Write-Warning "$($PrimaryBootString[0]) does not match $($BootString[0])"
                            #Write-Warning "Boot Device: $($BootDevice[0])"
                            #Return $False
                            $Results += @("False")
                        }
                    ElseIf(($PrimaryBootDevice[0] -eq $BootDevice[0]))
                        {
                            #Write-Host "$($PrimaryBootString[0]) matches $($BootString[0])"
                            $Results += @("True")
                            #Return $True
                        }
                }
        }

    If ($Results -notcontains "False")
    {
        Return $True
    }
    ElseIf ($Results -contains "False")
    {
        Return $False
    }

    }

Catch [Exception] 
    {
    $_.Exception.Message
    }