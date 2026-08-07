function Get-PodResource {
    <#
    .SYNOPSIS
        Pulls the resources attribute of all pods in a namespace

    .EXAMPLE
        Get-PodImage namespace

        podname1 {"limits":{"cpu":"250m","memory":"768M"},"requests":{"cpu":"20m","memory":"350M"}}
        podname2 {"limits":{"cpu":"250m","memory":"768M"},"requests":{"cpu":"30m","memory":"400M"}}
    #>
    [Alias('kpr')]
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Namespace
    )
    if (Get-Command kubectl -ErrorAction SilentlyContinue) {
        # kubectl get pods <pod name> -n jointventure -o jsonpath='{range .spec.containers[*]}{"Container Name: "}{.name}{"\n"}{"Requests:"}{.resources.requests}{"\n"}{"Limits:"}{.resources.limits}{"\n"}{end}'
        k get pods -n $Namespace -o jsonpath='{range .spec.containers[*]}{"Container: "}{.name}{@.metadata.namespace}{"/"}{@.metadata.name}{" "}{@.spec.containers[*].resources}{"\n"}{end}'
    }
    else {
        Write-Warning "kubectl not found"
    }
}