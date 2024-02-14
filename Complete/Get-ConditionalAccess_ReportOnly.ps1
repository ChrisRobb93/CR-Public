Import-Module Microsoft.Graph.Reports
Connect-MGGraph -Scope AuditLog.Read.All
$SignIns = Get-MGAuditLogSignIn
    ForEach ($SignIn in $SignIns){
        $Policies = $SignIn.AppliedConditionalAccessPolicies
            ForEach ($Policy in $Policies)
                {
                    
                    If (($Policy.Result -eq "reportOnlyFailure") -or ($Policy.Result -eq "reportOnlyInterrupted")){
                    $Report = [ordered]@{'Login Time'=$SignIn.CreatedDateTime;'Policy Name'=$Policy.DisplayName;'Username'=$SignIn.UserDisplayName;'Result'=$Policy.Result;'Device Name'=$signin.DeviceDetail.DisplayName;'OS Version'=$signin.DeviceDetail.OperatingSystem;'Browser'=$signin.DeviceDetail.Browser;'IP Address'=$SignIn.IPAddress}
                    $Reports += @(New-Object -TypeName psObject -Property $Report)
                    }
                    Else{}

                }        
    }

$Reports | FT
$Reports = $NULL