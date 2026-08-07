function Get-NodeTopMetric {
    <#
        .SYNOPSIS
        Return TOP metrics for a pod in a given namespace
    #>
    [Alias('knt')]
    [CmdletBinding()]
    param()
    k top node --show-capacity
}