using namespace System.Management.Automation
using namespace System.Management.Automation.Language

$PSDefaultParameterValues = @{
    "Install-Module:Scope"      = "AllUsers"
    "Install-Module:Repository" = "PSGallery"
}

if (Get-Module oh-my-posh -ListAvailable) {
    Import-Module oh-my-posh
    $ohMyPoshConfig = 'https://raw.githubusercontent.com/wsmelton/prompt/main/oh-my-config.json'
    oh-my-posh --init --shell pwsh --config $ohMyPoshConfig | Invoke-Expression
}

if (Get-Module Terminal-Icons -ListAvailable) {
    Import-Module Terminal-Icons
}

#region PSReadLine
Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView
#endregion PSReadLine

if ($psedition -ne 'Core') {
    [System.Net.ServicePointManager]::SecurityProtocol = @("Tls12", "Tls11", "Tls", "Ssl3")
}

# non-PSReadLine version of the same prompt
<#
function Prompt {
    $major = $PSVersionTable.PSVersion.Major
    $minor = $PSVersionTable.PSVersion.Minor
    $patch = $PSVersionTable.PSVersion.Patch
    if ($major -lt 6) {
        Write-Host "[PS $($major).$($minor)] [" -NoNewline
    } else {
        $patch = $PSVersionTable.PSVersion.Patch
        Write-Host "[PS $($major).$($minor).$($patch)] [" -NoNewline
    }
    Write-Host (Get-Date -Format "HH:mm:ss") -ForegroundColor Gray -NoNewline

    try {
        $history = Get-History -ErrorAction Ignore -Count 1
        if ($history) {
            Write-Host "] " -NoNewline
            $ts = New-TimeSpan $history.StartExecutionTime $history.EndExecutionTime
            switch ($ts) {
                { $_.TotalMinutes -ge 1 } {
                    '[{0,5:f1} m ]' -f $_.TotalMinutes | Write-Host -ForegroundColor DarkRed -NoNewline
                }
                { $_.TotalMinutes -lt 1 -and $_.TotalSeconds -ge 1 } {
                    '[{0,5:f1} s ]' -f $_.TotalSeconds | Write-Host -ForegroundColor DarkYellow -NoNewline
                }
                default {
                    '[{0,5:f1}ms ]' -f $_.Milliseconds | Write-Host -ForegroundColor Cyan -NoNewline
                }
            }
        } else {
            Write-Host "] >" -ForegroundColor Gray -NoNewline
        }
    } catch { }
    if (Test-Path .git) {
        $branchName = git branch | ForEach-Object { if ( $_ -match "^\*(.*)" ) { $_ -replace "\* ", "" } }
        Write-Host "[ git:$branchName ]" -ForegroundColor Yellow -NoNewline
    }
    Write-Host " $($executionContext.SessionState.Path.CurrentLocation.ProviderPath)"
    "[$($MyInvocation.HistoryId)] > "
}
#>

#region functions
function rdp {
    [cmdletbinding()]
    param (
        $server,
        [switch]$fullScreen
    )
    if ($fullScreen) {
        mstsc.exe -v $server -f
    } else {
        mstsc.exe -v $server /w 2150 /h 1250
    }
}
function findshit ($str,$path) {
    $str = [regex]::escape($str)
    Select-String -Pattern $str -Path (Get-ChildItem $path -Recurse -Exclude 'allcommands.ps1', '*.dll', "*psproj")
}
function Get-ClusterFailoverEvent {
    param([string]$Server)
    Get-WinEvent -ComputerName $Server -FilterHashtable @{LogName = 'Microsoft-Windows-FailoverClustering/Operational'; Id = 1641 }
}
function Find-MissingCommands {
    <#
    .SYNOPSIS
    Find missing commands between the dbatools.io/commands and dbatools Module public functions

    .PARAMETER ModulePath
    Path to dbatools local repository

    .PARAMETER CommandPagePath
    Full path to the index.html commands page (e.g. c:\git\web\commands\index.html)

    .PARAMETER Reverse
    Compare commands found in the CommandPagePath to those in the module

    .EXAMPLE
    Find-MissingCommands

    Returns string list of the commands not found in the Commands page.
    #>
    [cmdletbinding()]
    param(
        [string]
        $ModulePath = 'C:\git\dbatools',

        [string]
        $CommandPagePath = 'C:\git\web\commands\index.html',

        [switch]
        $Reverse
    )
    $commandPage = Get-Content $CommandPagePath

    if (-not (Get-Module dbatools)) {
        Import-Module $ModulePath
    }
    $commands = Get-Command -Module dbatools -CommandType Cmdlet, Function | Where-Object Name -NotIn 'Where-DbaObject','New-DbaTeppCompletionResult' | Select-Object -Expand Name

    if ($Reverse) {
        $commandRefs = $commandPage | Select-String '<a href="http://docs.dbatools.io/' | ForEach-Object { $_.ToString().Trim() }
        $commandRefList = foreach ($ref in $commandRefs) {
            $ref.ToString().SubString(0,$ref.ToString().IndexOf('">')).TrimStart('<a href="http://docs.dbatools.io/')
        }
        $commandRefList | Where-Object { $_ -notin $commands }
    } else {
        #find missing
        $notFound = $commands | ForEach-Object -ThrottleLimit 10 -Parallel { $foundIt = $using:commandPage | Select-String -Pattern $_; if (-not $foundIt) { $_ } }

        # found
        $found = $commands | ForEach-Object -ThrottleLimit 10 -Parallel { $foundIt = $using:commandPage | Select-String -Pattern $_; if ($foundIt) { $_ } }

        Write-Host "Tally: Total Commands ($($commands.Count)) | Found ($($found.Count)) | Missing ($($notFound.Count))"
        $notFound
    }
}
#endregion functions

#Import-Module Az.Tools.Predictor
#Set-PSReadLineOption -PredictionSource HistoryAndPlugin
