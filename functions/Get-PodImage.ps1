function Get-PodImage {
    <#
    .SYNOPSIS
        Pulls the image value from each pod in a namespace

    .EXAMPLE
        Get-PodImage namespace
    #>
    [Alias('kpi')]
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Namespace
    )
    if (Get-Command kubectl -ErrorAction SilentlyContinue) {
        k get pods -n $Namespace -o jsonpath='{range .items[*]}{@.metadata.name}{" "}{@.spec.containers[*].image}{"\n"}{end}'
    }
    else {
        Write-Warning "kubectl not found"
    }
}