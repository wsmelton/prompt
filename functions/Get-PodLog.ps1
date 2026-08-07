function Get-PodLog {
    <#
        .SYNOPSIS
        Watch the logs for a given Namespace and particular pod (by index number of the "kubectl get pod" output
    #>
    [Alias('kpl')]
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Namespace,
        [Parameter(Position = 1)]
        [string]$Index = 1
    )
    k logs -f (kubectl get pod -n $Namespace -o name | Select-Object -Index $Index) -n $Namespace
}