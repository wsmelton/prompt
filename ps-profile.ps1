using namespace System.Management.Automation
using namespace System.Management.Automation.Language
using namespace System.Collections.Generic
using namespace Microsoft.Azure.Commands.ContainerRegistry.Models

# improve speed of downloads by turning off progress bar
$ProgressPreference = 'SilentlyContinue'

$PSDefaultParameterValues = @{
    "Install-Module:Scope"            = "AllUsers"
    "Install-Module:Repository"       = "PSGallery"
    "Invoke-Command:HideComputerName" = $true
}

if (Get-Module ImportExcel -List)
{
    $PSDefaultParameterValues.Add('Export-Excel:FreezeTopRow',$true)
    $PSDefaultParameterValues.Add('Export-Excel:BoldTopRow',$true)
    $PSDefaultParameterValues.Add('Export-Excel:TableStyle','Light14')
}

# $ohMyPoshConfig = "$PSScriptRoot\oh-my-config.json"
# oh-my-posh init pwsh --config $ohMyPoshConfig | Invoke-Expression
<# the great and might PowerLine by Jaykul #>
try
{
    Import-Module TerminalBlocks -ErrorAction Stop
    Import-Module posh-git -ErrorAction Stop
    $global:GitPromptSettings = New-GitPromptSettings
    $global:GitPromptSettings.BeforeStatus = ''
    $global:GitPromptSettings.AfterStatus = ''
    $global:GitPromptSettings.PathStatusSeparator = ''
    $global:GitPromptSettings.BeforeStash.Text = "$(Text '&ReverseSeparator;')"
    $global:GitPromptSettings.AfterStash.Text = "$(Text '&Separator;')"

    $global:Prompt = @(
        Show-LastExitCode -ForegroundColor 'VioletRed1' -Caps "","`n"
        Show-HistoryId -Prefix "&parrot;" -ForegroundColor Black -BackgroundColor MediumAquamarine
        Show-Path -DriveName -ForegroundColor SteelBlue1 -BackGroundColor RoyalBlue
        if (Get-Command kubectl -CommandType Application) {
            Show-KubeContext -ForegroundColor Black -BackgroundColor RosyBrown -Caps " "
        }

        if (Get-Module posh-git)
        {
            Show-PoshGitStatus -AfterStatus "" -PathStatusSeparator "" -Caps ""
        }
        Show-Date -Format "T" -Prefix "&fiveoclock;" -ForegroundColor Black -BackgroundColor GoldenRod -Alignment Right
        Show-ElapsedTime -Prefix "&timerclock;" -ForegroundColor Black -BackgroundColor PaleGreen4 -Alignment Right
        New-TerminalBlock '❯' -ForegroundColor 'Gray80' -Caps ""," "
        Set-PSReadLineOption -PromptText (New-Text "❯ " -Foreground AntiqueWhite4), (New-Text "❯ " -Foreground 'VioletRed1') -ContinuationPrompt (New-Text "❯ " -Foreground 'SteelBlue1')
    )
    function global:Prompt { -join $Prompt }
}
catch
{
    Write-Warning "Issue importing and configuring TerminalBlocks: $($_)"
}

if (Get-Module Terminal-Icons -ListAvailable)
{
    Import-Module Terminal-Icons
}

if ((Get-Module AzureAD -ListAvailable) -and ($psedition -eq 'Core'))
{
    Import-Module AzureAD -UseWindowsPowerShell -WarningAction SilentlyContinue
}

#region PSReadLine
Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView
#endregion PSReadLine

if ($psedition -ne 'Core')
{
    [System.Net.ServicePointManager]::SecurityProtocol = @("Tls12", "Tls11", "Tls", "Ssl3")
}

if (Get-Module Az.Accounts -ListAvailable)
{
    $azContextImport = "$env:USERPROFILE\azure-context.json"
}

#region functions
function rdp
{
    [cmdletbinding()]
    param (
        $server,
        [switch]$fullScreen
    )
    if ($fullScreen)
    {
        mstsc.exe -v $server -f
    }
    else
    {
        mstsc.exe -v $server /w 2150 /h 1250
    }
}
function findshit ($str,$path)
{
    $str = [regex]::escape($str)
    Select-String -Pattern $str -Path (Get-ChildItem $path -Recurse -Exclude 'allcommands.ps1', '*.dll', "*psproj")
}
function findAd
{
    [cmdletbinding()]
    param(
        [Parameter(Position = 0,Mandatory)]
        [string]
        $str,

        [Parameter(Position = 1)]
        [string[]]
        $Props,

        [Parameter(Position = 2)]
        [Alias('emo')]
        [switch]
        $ExpandMemberOf
    )
    begin
    {
        $hasSpace = $false
    }
    process
    {
        if ($IsCoreCLR -and -not (Get-Module ActiveDirectory))
        {
            Import-Module ActiveDirectory -UseWindowsPowerShell -ErrorAction Stop
        }
        elseif (-not (Get-Module ActiveDirectory))
        {
            Import-Module ActiveDirectory -ErrorAction Stop
        }
        $hasSpace = $str.Split(' ').Count -gt 1

        $adObject = Get-ADObject -Filter "Name -eq '$str'"

        if ($adObject)
        {
            switch ($adObject.ObjectClass)
            {
                'user'
                {
                    $defautlProps = 'Description', 'MemberOf', 'whenCreated', 'whenChanged', 'LastLogonDate', 'PasswordLastSet', 'UserPrincipalName', 'CannotChangePassword', 'PasswordNeverExpires'
                }
                default
                {
                    $defaultProps = 'Description', 'MemberOf', 'whenCreated', 'whenChanged', 'UserPrincipalName'
                }
            }
            if ($PSBoundParameters.ContainsKey(''))
            {
                $defaultProps += $Props
            }
            $finalAdObject = Get-ADObject -Filter "Name -eq '$str'" -Properties $defaultProps

            if ($finalAdObject)
            {
                if ($PSBoundParameters.ContainsKey('ExpandMemberOf'))
                {
                    $finalAdObject.MemberOf | Sort-Object
                }
                else
                {
                    $finalAdObject
                }
            }
        }
    }
}
function findAdSrv
{
    [cmdletbinding()]
    param(
        [Parameter(Position = 0,Mandatory)]
        [string]
        $str,

        [Parameter(Position = 1)]
        [string[]]
        $Props,

        [Parameter(Position = 2)]
        [Alias('emo')]
        [switch]
        $ExpandMemberOf
    )
    process
    {
        if ($IsCoreCLR -and -not (Get-Module ActiveDirectory))
        {
            Import-Module ActiveDirectory -UseWindowsPowerShell -ErrorAction Stop
        }
        elseif (-not (Get-Module ActiveDirectory))
        {
            Import-Module ActiveDirectory -ErrorAction Stop
        }

        $defaultProps = 'Description', 'MemberOf', 'whenCreated', 'LastLogonDate'
        if ($PSBoundParameters.ContainsKey('Props'))
        {
            $srvResult = Get-ADComputer -Identity $str -Properties $defaultProps,$Props
        }
        else
        {
            $srvResult = Get-ADComputer -Identity $str -Properties $defaultProps
        }
        if ($srvResult)
        {
            if ($PSBoundParameters.ContainsKey('ExpandMemberOf'))
            {
                $srvResult.MemberOf | Sort-Object
            }
            else
            {
                $srvResult
            }
        }
    }
}
function Get-ClusterFailoverEvent
{
    param([string]$Server)
    Get-WinEvent -ComputerName $Server -FilterHashtable @{LogName = 'Microsoft-Windows-FailoverClustering/Operational'; Id = 1641 }
}
function Find-MissingCommands
{
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

    if (-not (Get-Module dbatools))
    {
        Import-Module $ModulePath
    }
    $commands = Get-Command -Module dbatools -CommandType Cmdlet, Function | Where-Object Name -NotIn 'Where-DbaObject','New-DbaTeppCompletionResult' | Select-Object -Expand Name

    if ($Reverse)
    {
        $commandRefs = $commandPage | Select-String '<a href="http://docs.dbatools.io/' | ForEach-Object { $_.ToString().Trim() }
        $commandRefList = foreach ($ref in $commandRefs)
        {
            $ref.ToString().SubString(0,$ref.ToString().IndexOf('">')).TrimStart('<a href="http://docs.dbatools.io/')
        }
        $commandRefList | Where-Object { $_ -notin $commands }
    }
    else
    {
        #find missing
        $notFound = $commands | ForEach-Object -ThrottleLimit 10 -Parallel { $foundIt = $using:commandPage | Select-String -Pattern $_; if (-not $foundIt) { $_ } }

        # found
        $found = $commands | ForEach-Object -ThrottleLimit 10 -Parallel { $foundIt = $using:commandPage | Select-String -Pattern $_; if ($foundIt) { $_ } }

        Write-Host "Tally: Total Commands ($($commands.Count)) | Found ($($found.Count)) | Missing ($($notFound.Count))"
        $notFound
    }
}
function Reset-Az
{
    param(
        [string]
        $TenantId
    )
    Clear-AzContext -Force
    Connect-AzAccount -Tenant $TenantId -WarningAction SilentlyContinue >$null
    Get-AzContext -ListAvailable | ForEach-Object { $n = $_.Name; Rename-AzContext -SourceName $n -TargetName $n.Split(' ')[0] }
    Save-AzContext -Path $azContextImport -Force

    Import-AzContext -Path $azContextImport >$null
}
function New-RandomPassword
{
    [cmdletbinding()]
    param(
        [Parameter(Position = 0)]
        [int]$CharLength = 15
    )
    $charlist = [char]94..[char]126 + [char]65..[char]90 + [char]47..[char]57
    $pwLength = (1..10 | Get-Random) + 80
    $pwdList = @()
    for ($i = 0; $i -lt $pwLength; $i++)
    {
        $pwdList += $charList | Get-Random
    }
    ($pwdList -join '').Substring(0,$CharLength)
}
function Revoke-DomainToken
{
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
    begin
    {
        $justUsername = $Identity.Split('@')[0]
    }
    process
    {
        try
        {
            if ($psedition -eq 'Core')
            {
                Import-Module ActiveDirectory -UseWindowsPowerShell -ErrorAction Stop
            }
            else
            {
                Import-Module ActiveDirectory -ErrorAction Stop
            }
        }
        catch
        {
            throw "Issue loading ActiveDirectory Module: $($_)"
        }

        try
        {
            if ($psedition -eq 'Core')
            {
                Import-Module AzureAD -UseWindowsPowerShell -ErrorAction Stop
            }
            else
            {
                Import-Module AzureAD -ErrorAction Stop
            }
        }
        catch
        {
            throw "Issue loading AzureAD Module: $($_)"
        }

        if ($PSCmdlet.ShouldProcess($justUsername,'Disabling Active Directory Identity'))
        {
            try
            {
                if (Get-ADUser -Identity $justUsername -Credential $ADCredential -ErrorAction SilentlyContinue)
                {
                    Disable-ADAccount -Identity $justUsername -Credential $ADCredential -ErrorAction Stop
                }
                else
                {
                    Write-Warning "No user found matching $justUsername"
                    return
                }
            }
            catch
            {
                throw "Issue disabling User [$justUsername]: $($_)"
            }
        }
        if ($PSCmdlet.ShouldProcess($justUsername,'Reseting password to random value x2'))
        {
            try
            {
                1..2 | ForEach-Object {
                    Set-ADAccountPassword -Identity $justUsername -Credential $ADCredential -Reset -NewPassword (ConvertTo-SecureString -String (New-RandomPassword) -AsPlainText -Force) -ErrorAction Stop
                }
            }
            catch
            {
                throw "Issue reseting password for User [$justUsername]: $($_)"
            }
        }
        try
        {
            Get-AzureADTenantDetail -ErrorAction Stop >$null
            Write-Host 'Connected to Azure AD'
        }
        catch
        {
            Write-Warning "No active connection found to Azure AD"
            Connect-AzureAD >$null
        }

        if ($PSCmdlet.ShouldProcess($Identity,'Disabling Azure AD Identity'))
        {
            try
            {
                Set-AzureADUser -ObjectId $Identity -AccountEnabled $false -ErrorAction Stop
            }
            catch
            {
                throw "Issue disabling Azure AD Account [$Identity]: $($_)"
            }
        }
        if ($PSCmdlet.ShouldProcess($Identity,'Revoking Azure AD Token'))
        {
            try
            {
                Revoke-AzureADUserAllRefreshToken -ObjectId $Identity -ErrorAction Stop
            }
            catch
            {
                throw "Issue revoking Azure AD Account [$Identity]: $($_)"
            }
        }
    }
}
filter Get-AcrTag
{
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
    if (!$Force -and $AzContainerRegistryRepositoryCache.ContainsKey($RegistryName))
    {
        Write-Verbose "Using cached repository list (specify -Force to re-fetch)"
    }
    else
    {
        Write-Verbose "Looking for new repositories"
        $global:AzContainerRegistryRepositoryCache[$RegistryName] = Get-AzContainerRegistryRepository -RegistryName $RegistryName
    }

    $Repositories = $global:AzContainerRegistryRepositoryCache[$RegistryName] -match "($($name -join '|'))$"
    foreach ($repo in $Repositories)
    {
        Write-Verbose "Fetching version tags for $repo"
        foreach ($registry in Get-AzContainerRegistryTag -RegistryName $azContainerRegistry -RepositoryName $repo -ea 0)
        {
            # Sort the tags the opposite direction
            $registry.Tags.Sort( { -1 * $args[0].LastUpdateTime.CompareTo($args[1].LastUpdateTime) } )
            $registry
        }
    }
}
function Set-Subscription
{
    [Alias("ss")]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromRemainingArguments, Position = 0)]
        [string]
        $SubName,

        [string]
        $TenantId = $tenantIdProd
    )
    process
    {
        $cContext = Get-AzContext
        if ($cContext.Name -ne $SubName)
        {
            $result = Select-AzSubscription $SubName -Tenant $TenantId
        }
        if ($result.Name -eq $SubName)
        {
            Write-Host "Context switched to subscription: [$SubName]" -ForegroundColor DarkCyan
        }
    }
}
function Get-AzureAddressSpace
{
    [CmdletBinding()]
    param()
    process
    {
        try
        {
            $subscriptions = Get-AzSubscription -TenantId $tenantIdProd -ErrorAction Stop
        }
        catch
        {
            throw "Issue getting list of Subscriptions: $($_)"
        }
        if ($subscriptions)
        {
            $subscriptions | ForEach-Object -ThrottleLimit 10 -Parallel {
                $subName = $_.Name
                $azContext = Get-AzContext -WarningAction SilentlyContinue
                if ($azContext -and $azContext.SubscriptionName -ne $subName)
                {
                    Set-AzContext -Subscription $subName -WarningAction SilentlyContinue >$null
                }
                $virtualNetworks = Get-AzVirtualNetwork
                foreach ($vnet in $virtualNetworks)
                {
                    $resourceGroup = $vnet.ResourceGroupName.ToLower()
                    $vnetName = $vnet.Name.ToLower()
                    $vnetLocation = $vnet.Location
                    $addressSpaces = $vnet.AddressSpace.AddressPrefixes

                    if ($addressSpaces.Count -gt 1)
                    {
                        foreach ($space in $addressSpaces)
                        {
                            [pscustomobject]@{
                                Subscription      = $subName
                                ResourceGroupName = $resourceGroup
                                VnetName          = $vnetName
                                Location          = $vnetLocation
                                AddressSpace      = $space
                            }
                        }
                    }
                    else
                    {
                        [pscustomobject]@{
                            Subscription      = $subName
                            ResourceGroupName = $resourceGroup
                            VnetName          = $vnetName
                            Location          = $vnetLocation
                            AddressSpace      = $addressSpaces
                        }
                    }
                }
            }
        }
    }
}
function Get-PopeyeReport
{
    if ((Get-Command popeye -ErrorAction SilentlyContinue) -and (Get-Command kubectl -ErrorAction SilentlyContinue))
    {
        $clusterName = kubectl config view --minify --output 'jsonpath={..context.cluster}'
        $currentFileDateTime = Get-Date -Format FileDateTime
        $tempHtmlFileName = "$($clusterName)_$($currentFileDateTime).html"
        try
        {
            $env:POPEYE_REPORT_DIR = $env:temp
            popeye -A -c -o 'html' --save --output-file $tempHtmlFileName
        }
        catch
        {
            throw "Issue running popeye: $($_)"
        }
        Invoke-Item ([IO.Path]::combine($env:temp,$tempHtmlFileName))
    }
}
function Test-ADUserPassword
{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory)]
        [pscredential]
        $Credential,

        [ValidateSet('ApplicationDirectory','Domain','Machine')]
        [string]
        $ContextType = 'Domain',

        [string]
        $Server
    )
    try
    {
        Add-Type -AssemblyName System.DirectoryServices.AccountManagement -ErrorAction Stop
        try
        {
            if ($PSBoundParameters.ContainsKey('Server'))
            {
                $pContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext($ContextType,$Server)
            }
            else
            {
                $pContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext($ContextType)
            }
        }
        catch
        {
            Write-Error -Message "Issue connecting $ContextType -- $($_)"
        }
        try
        {
            $pContext.ValidateCredentials($Credential.UserName, $Credential.GetNetworkCredential().Password,'Negotiate')
        }
        catch [UnauthorizedAccessException]
        {
            Write-Warning -Message "Access denied when connecting to server."
            return $false
        }
        catch
        {
            Write-Error -Exception $_.Exception -Message "Unhandled error occurred: $($_)"
        }
    }
    catch
    {
        throw
    }
}
function findLocalAdmins
{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]
        $Server,

        [pscredential]
        $Credential
    )
    $Server | ForEach-Object -ThrottleLimit 15 -Parallel {
        $s = $_
        $psSessionParams = @{
            ComputerName = $s
        }
        if ($using:Credential)
        {
            $psSessionParams.Add('Credential',$using:Credential)
        }
        try
        {
            $psSession = New-PSSession @psSessionParams -ErrorAction Stop
        }
        catch
        {
            Write-Warning "Unable to connect to server: $($s) | $($_)"
        }
        if ($psSession)
        {
            try
            {
                $resultData = Invoke-Command -Session $psSession -ScriptBlock { Get-LocalGroupMember -Group Administrators } -ErrorAction Stop
                if ($resultData)
                {
                    foreach ($r in $resultData)
                    {
                        [pscustomobject]@{
                            Server  = $s
                            Name    = $r.Name
                            Type    = $r.ObjectClass
                            IsLocal = if ($r.PrincipalSource -eq 'Local') { $true } else { $false }
                        }
                    }
                }
            }
            catch
            {
                $resultOld = Invoke-Command -Session $psSession -ScriptBlock { net localgroup Administrators }
                foreach ($r in ($resultOld | Select-Object -Skip 6))
                {
                    if ($r -notmatch "The command completed successfully" -and -not [string]::IsNullOrEmpty($r))
                    {
                        [pscustomObject]@{
                            Server  = $s
                            Name    = $r
                            Type    = $null
                            IsLocal = $null
                        }
                    }
                }
            }
            Remove-PSSession -Session $psSession
        }
    }
}
function testAdMembership
{
    param(
        [Parameter(Position = 0)]
        [string]$User,
        [Parameter(Position = 1)]
        [string]$Group)
    trap { return "error" }
    $adUserParams = @{
        Filter     = "memberOf -RecursiveMatch '$((Get-ADGroup $Group).DistinguishedName)'"
        SearchBase = $((Get-ADUser $User).DistinguishedName)
    }
    if (Get-ADUser @adUserParams) { $true } else { $false }
}
#endregion functions

#Import-Module Az.Tools.Predictor
#Set-PSReadLineOption -PredictionSource HistoryAndPlugin

# if ((Test-Path $azContextImport) -and (Get-Module Az.Accounts -ListAvailable)) {
#     $data = Get-Content $azContextImport | ConvertFrom-Json
#     if ($data.Contexts.Count -gt 1) {
#         Import-AzContext -Path $azContextImport
#     }
# }

#region shortcuts
Set-Alias -Name gsc -Value 'Get-Secret'
Set-Alias -Name g -Value git
Set-Alias -Name k -Value kubectl
Set-Alias -Name kctx -Value kubectx
Set-Alias -Name kns -Value kubens
#endregion shortcuts

<# VS Code Environment #>
if ($host.Name -eq 'Visual Studio Code Host')
{
    Import-Module EditorServicesCommandSuite
    Import-EditorCommand -Module EditorServicesCommandSuite
}