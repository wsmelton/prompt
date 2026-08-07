if (-not $IsMacOS) {
    function Get-ClusterFailoverEvent {
            param([string]$Server)
            Get-WinEvent -ComputerName $Server -FilterHashtable @{LogName = 'Microsoft-Windows-FailoverClustering/Operational'; Id = 1641 }
        }
}