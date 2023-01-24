<#
Set this as a daily scheduled task to cleanup log files older than $DaysToKeep
#>

Param 
(
	    [Parameter(Mandatory=$True)]
		[string] $DaysToKeep,

		[Parameter(Mandatory=$True)]
		[string] $LogDirectories,
)


Foreach ( $LogDirectory in $LogDirectories ) {

	Get-ChildItem -path $LogDirectory -recurse | Where-Object {$_.LastWriteTime -lt (get-date).AddDays(-$DaysToKeep) -and $_.Attributes -notlike "Directory" } | Remove-Item

}