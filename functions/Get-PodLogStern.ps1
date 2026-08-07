function Get-PodLogStern {
    <#
        .SYNOPSIS
        Get logs of all pods in a namespace using stern utility. https://github.com/stern/stern

        .EXAMPLE
        kstern mynamespace -Since 10m -State 'running,waiting'

        Return logs for namespace "mynamespace", last 10 minutes, containers in state of running or waiting
    #>
    [Alias('kstern')]
    [CmdletBinding()]
    param(
        # pod name
        [Parameter(Position = 0)]
        [string]$PodName = ".*",

        # Pull logs since (use 2h, 5m, etc.). Default: 2h (2 hours)
        [Parameter(Position = 1)]
        [string]$Since = '2h',

        # Include only lines container provided regular expression (e.g., "The file uploaded*")
        [Parameter(Position = 2)]
        [string]$Include,

        # Container state to return (running, waiting, terminated, or all)
        # Pass in multiple vai single-stringed, comma-separated (e.g. 'running, waiting')
        # Pass in 'all' to get everything
        [Parameter(Position = 3)]
        [ValidateSet('running', 'waiting', 'terminated', 'all')]
        [string]$State = 'all',

        # Output log data to JSON format
        [switch]$Output,

        # Namespace is optional, defaults to context's namespace if not provided
        [string]$Namespace
    )
    if (k krew) {
        if ($Output) {
            if ($Include) {
                k stern $PodName --namespace $Namespace --since $Since --include $Include --no-follow=true --container-state $State --color=always --timestamps=short --output=json
            }
            else {
                k stern $PodName --namespace $Namespace --since $Since --no-follow=true --container-state $State --color=always --timestamps=short --output=json
            }
        }
        else {
            if ($Include) {
                k stern $PodName --namespace $Namespace --since $Since --include $Include --no-follow=true --container-state $State --color=always --timestamps=short
            }
            else {
                k stern $PodName --namespace $Namespace --since $Since --no-follow=true --container-state $State --color=always --timestamps=short
            }
        }
    }
    else {
        Write-Warning "Stern utility was not found installed via krew"
    }
}