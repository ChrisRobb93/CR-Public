<#
Set this as a daily scheduled task to cleanup log files older than $DaysToKeep
#>

$DaysToKeep=14
$LogDirectories="ENTERFULLPATHHERE"


Foreach ( $LogDirectory in $LogDirectories ) {

	Get-ChildItem -path $LogDirectory -recurse |
	Where-Object {$_.LastWriteTime -lt (get-date).AddDays(-$DaysToKeep) -and $_.Attributes -notlike "Directory" }|
	Foreach-Object { Remove-Item $_.FullName }

}