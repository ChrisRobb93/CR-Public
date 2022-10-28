Function Write-Log {
    [CmdletBinding()]
    Param(
    [Parameter(Mandatory=$False)]
    [ValidateSet("INFO","WARN","ERROR","FATAL","DEBUG")]
    [String]
    $Level = "INFO",

    [Parameter(Mandatory=$True)]
    [string]
    $Message,

    [Parameter(Mandatory=$False)]
    [string]
    $Writelogfile
    )

    $Stamp = (Get-Date).toString("dd/MM/yy HH:mm:ss")
    $Line = "$Stamp $Level $Message"

    If($WriteLogFile)
        {
            Add-Content $LogFile -Value $Line
        }
}
