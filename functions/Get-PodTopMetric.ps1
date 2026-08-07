function Get-PodTopMetric {
    <#
        .SYNOPSIS
        Return TOP metrics for a pod in a given namespace
    #>
    [Alias('kpt')]
    [CmdletBinding()]
    param(
        # Namespace to pull
        [Parameter(Position = 0)]
        [string]$Namespace,

        # Output details on all containers in the pod
        [switch]$Containers
    )
    if ($Containers) {
        k top pod -n $Namespace --containers
    }
    else {
        k top pod -n $Namespace
    }
}