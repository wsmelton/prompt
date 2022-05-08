using namespace System.Management.Automation
using namespace System.Management.Automation.Language
using namespace System.Collections.Generic
using namespace Microsoft.Azure.Commands.ContainerRegistry.Models

# improve speed of downloads by turning off progress bar
$ProgressPreference = 'SilentlyContinue'

$PSDefaultParameterValues = @{
    "Install-Module:Scope"      = "AllUsers"
    "Install-Module:Repository" = "PSGallery"
}

$ohMyPoshModule = Get-Module -Name oh-my-posh -ListAvailable | Select-Object -First 1
if ($ohMyPoshModule.Version.Major -ge 7 -and $ohMyPoshModule.Version.Minor -ge 30) {
    Import-Module oh-my-posh
    $ohMyPoshConfig = "$PSScriptRoot\oh-my-config.json"
    oh-my-posh --init --shell pwsh --config $ohMyPoshConfig | Invoke-Expression
} else {
    Write-Warning "oh-my-posh version should be 7.30.2 or higher"
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

if (Get-Module Az.Accounts -ListAvailable) {
    $azContextImport = "$env:USERPROFILE\azure-context.json"
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
function Reset-Az {
    param(
        [string]
        $TenantId
    )
    Clear-AzContext -Force
    Connect-AzAccount -Tenant $TenantId -WarningPreference SilentlyContinue >$null
    Get-AzContext -ListAvailable | ForEach-Object { $n = $_.Name; Rename-AzContext -SourceName $n -TargetName $n.Split(' ')[0] }
    Save-AzContext -Path $azContextImport -Force

    Import-AzContext -Path $azContextImport >$null
}
function Revoke-DomainToken {
    <#
    .SYNOPSIS
    Revoking user access in Active Directory and Azure AD Tenant
    Ref: https://docs.microsoft.com/en-us/azure/active-directory/enterprise-users/users-revoke-access
    #>
    [cmdletbinding(SupportsShouldProcess)]
    param(
        # Provide user identity (username@domain.com)
        [string]
        $Identity,

        # Credential to login to Active Directory
        [PSCredential]
        $ADCredential
    )
    begin {
        $justUsername = $Identity.Split('@')[0]
        function New-RandomPassword {
            $uppercase = "ABCDEFGHKLMNOPRSTUVWXYZ".ToCharArray()
            $lowercase = "abcdefghiklmnoprstuvwxyz".ToCharArray()
            $number = "0123456789".ToCharArray()
            $special = "$%&/()=?}{@#*+!".ToCharArray()

            $password = ($uppercase | Get-Random -Count 3) -join ''
            $password += ($lowercase | Get-Random -Count 5) -join ''
            $password += ($number | Get-Random -Count 2) -join ''
            $password += ($special | Get-Random -Count 3) -join ''
            $password
        }
    }
    process {
        try {
            if ($psedition -eq 'Core') {
                Import-Module ActiveDirectory -UseWindowsPowerShell -ErrorAction Stop
            } else {
                Import-Module ActiveDirectory -ErrorAction Stop
            }
        } catch {
            throw "Issue loading ActiveDirectory Module: $($_)"
        }

        try {
            if ($psedition -eq 'Core') {
                Import-Module AzureAD -UseWindowsPowerShell -ErrorAction Stop
            } else {
                Import-Module AzureAD -ErrorAction Stop
            }
        } catch {
            throw "Issue loading AzureAD Module: $($_)"
        }

        if ($PSCmdlet.ShouldProcess($justUsername,'Disabling Active Directory Identity')) {
            try {
                if (Get-ADUser -Identity $justUsername -Credential $ADCredential -ErrorAction SilentlyContinue) {
                    Disable-ADAccount -Identity $justUsername -Credential $ADCredential -ErrorAction Stop
                } else {
                    Write-Warning "No user found matching $justUsername"
                    return
                }
            } catch {
                throw "Issue disabling User [$justUsername]: $($_)"
            }
        }
        if ($PSCmdlet.ShouldProcess($justUsername,'Reseting password to random value x2')) {
            try {
                1..2 | ForEach-Object {
                    Set-ADAccountPassword -Identity $justUsername -Credential $ADCredential -Reset -NewPassword (ConvertTo-SecureString -String (New-RandomPassword) -AsPlainText -Force) -ErrorAction Stop
                }
            } catch {
                throw "Issue reseting password for User [$justUsername]: $($_)"
            }
        }
        try {
            Get-AzureADTenantDetail -ErrorAction Stop >$null
            Write-Host 'Connected to Azure AD'
        } catch {
            Write-Warning "No active connection found to Azure AD"
            Connect-AzureAD >$null
        }

        if ($PSCmdlet.ShouldProcess($Identity,'Disabling Azure AD Identity')) {
            try {
                Set-AzureADUser -ObjectId $Identity -AccountEnabled $false -ErrorAction Stop
            } catch {
                throw "Issue disabling Azure AD Account [$Identity]: $($_)"
            }
        }
        if ($PSCmdlet.ShouldProcess($Identity,'Revoking Azure AD Token')) {
            try {
                Revoke-AzureADUserAllRefreshToken -ObjectId $Identity -ErrorAction Stop
            } catch {
                throw "Issue revoking Azure AD Account [$Identity]: $($_)"
            }
        }
    }
}
filter Get-AcrTag {
    <#
    .SYNOPSIS
        Search ACR for repositories and get latest tags
    .LINK
        https://gist.github.com/Jaykul/88900be0cf36ab6d340d65a4ffd056b3
    .EXAMPLE
        Test-MyTestFunction -Verbose
        Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
    #>
    [Alias("Get-BicepTag","gat","gbt")]
    [CmdletBinding()]
    param(
        # The (partial) name of the repository.
        [Parameter(Mandatory, ValueFromRemainingArguments, Position = 0)]
        [Alias("RepositoryName")]
        [string[]]$Name,

        # The name of the registry to search.
        # Recommend you set this in your $PSDefaultParameters
        [Parameter(Mandatory)]
        [string]$RegistryName,

        # Force fetching the list of repositories from the registry
        [switch]$Force
    )
    $global:AzContainerRegistryRepositoryCache += @{}
    if (!$Force -and $AzContainerRegistryRepositoryCache.ContainsKey($RegistryName)) {
        Write-Verbose "Using cached repository list (specify -Force to re-fetch)"
    } else {
        Write-Verbose "Looking for new repositories"
        $global:AzContainerRegistryRepositoryCache[$RegistryName] = Get-AzContainerRegistryRepository -RegistryName $RegistryName
    }

    $Repositories = $global:AzContainerRegistryRepositoryCache[$RegistryName] -match "($($name -join '|'))$"
    foreach ($repo in $Repositories) {
        Write-Verbose "Fetching version tags for $repo"
        foreach($registry in Get-AzContainerRegistryTag -RegistryName crbicepazusw2dvorprd -RepositoryName $repo -ea 0) {
            # Sort the tags the opposite direction
            $registry.Tags.Sort( { -1 * $args[0].LastUpdateTime.CompareTo($args[1].LastUpdateTime) } )
            $registry
        }
    }
}
function Set-Subscription {
    [Alias("ss")]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromRemainingArguments, Position = 0)]
        [string]
        $SubName,

        [string]
        $TenantId = $tenantIdProd
    )
    process {
        $cContext = Get-AzContext
        if ($cContext.Name -ne $SubName) {
            $result = Select-AzSubscription $SubName -Tenant $TenantId
        }
        if ($result.Name -eq $SubName) {
            Write-Host "Context switched to subscription: [$SubName]" -ForegroundColor DarkCyan
        }
    }
}
#endregion functions

#Import-Module Az.Tools.Predictor
#Set-PSReadLineOption -PredictionSource HistoryAndPlugin

if ((Test-Path $azContextImport) -and (Get-Module Az.Accounts -ListAvailable)) {
    $data = Get-Content $azContextImport | ConvertFrom-Json
    if ($data.Contexts.Count -gt 1) {
        Import-AzContext -Path $azContextImport
    }
}