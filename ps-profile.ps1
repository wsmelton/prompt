using namespace System.Management.Automation
using namespace System.Management.Automation.Language
using namespace System.Collections.Generic
using namespace Microsoft.Azure.Commands.ContainerRegistry.Models

try {
    Import-Module TerminalBlocks -ErrorAction Stop
    Import-Module posh-git -ErrorAction Stop

    $global:GitPromptSettings = New-GitPromptSettings
    $global:GitPromptSettings.BeforeStatus = ''
    $global:GitPromptSettings.AfterStatus = ''
    $global:GitPromptSettings.PathStatusSeparator = ''
    $global:GitPromptSettings.BeforeStash.Text = "$(Text '&ReverseSeparator;')"
    $global:GitPromptSettings.AfterStash.Text = "$(Text '&Separator;')"

    $global:Prompt = @(
        # Initialize-Prompt
        [PoshCode.TerminalBlock]::LastSuccess = $global:?
        [PoshCode.TerminalBlock]::LastExitCode = $global:LASTEXITCODE

        New-TerminalBlock -Separator ' ' -Content { Update-ZLocation $pwd }
        Show-ElapsedTime -Autoformat -Prefix "`u{231b}" -Caps ([Char]0xe0be), ([Char]0xe0bc) -DefaultBackgroundColor YellowGreen
        Show-Date -Format 'h\:mm' -Prefix "⏰" -DefaultBackgroundColor GreenYellow
        New-TerminalBlock -Newline
        Show-HistoryId
        New-TerminalBlock -Spacer
        Show-KubeContext -Prefix "🐳 " -DefaultForegroundColor WhiteSmoke -DefaultBackgroundColor DarkOrchid1
        Show-AzureContext -Prefix "⛈️  " -DefaultForegroundColor DarkOrchid3 -DefaultBackgroundColor DarkGoldenrod1 -
        Show-Path -HomeString "🏚️ " -Separator '\' -Depth 3
        New-TerminalBlock -Spacer

        if (Get-Module posh-git) {
            Show-PoshGitStatus -DefaultBackgroundColor Grey30
        }
        New-TerminalBlock -Newline
        New-TerminalBlock '❯' -ForegroundColor DarkBlue -AdminBackgroundColor Red

        # Exit-Prompt
        $global:LASTEXITCODE = [PoshCode.TerminalBlock]::LastExitCode
    )

} catch {
    Write-Warning "Issue importing and configuring TerminalBlocks: $($_)"
}

# improve speed of downloads by turning off progress bar
$ProgressPreference = 'SilentlyContinue'

$PSDefaultParameterValues = @{
    'Invoke-Command:HideComputerName' = $true
}

if (Get-Module ImportExcel -List) {
    $PSDefaultParameterValues.Add('Export-Excel:FreezeTopRow', $true)
    $PSDefaultParameterValues.Add('Export-Excel:BoldTopRow', $true)
    $PSDefaultParameterValues.Add('Export-Excel:TableStyle', 'Light14')
}

if (Get-Module Terminal-Icons -ListAvailable) {
    Import-Module Terminal-Icons
}

if ((Get-Module AzureAD -ListAvailable) -and ($PSEdition -eq 'Core' -and -not $IsMacOS)) {
    Import-Module AzureAD -UseWindowsPowerShell -WarningAction SilentlyContinue
}

#region PSReadLine
Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView
#endregion PSReadLine

if ($PSEdition -ne 'Core' -and -not $IsMacOS) {
    [System.Net.ServicePointManager]::SecurityProtocol = @('Tls12', 'Tls11', 'Tls', 'Ssl3')
}

if (Test-Path "$env:USERPROFILE\azure-context.json") {
    $azContextImport = "$env:USERPROFILE\azure-context.json"
}

#region shortcuts
Set-Alias -Name gsc -Value 'Get-Secret'
Set-Alias -Name g -Value git
Set-Alias -Name kx -Value kubectx
Set-Alias -Name kns -Value kubens
Set-Alias -Name ci -Value 'code-insiders'
#endregion shortcuts

#region aliases for kubectl shortcuts
Set-Alias -Name k -Value kubectl -Scope Global
<# alias for kubectl base #>
# function k() { & kubectl @args }
#endregion aliases for kubectl shortcuts

#region functions
$functionPath = Join-Path $PSScriptRoot 'functions'
if (Test-Path $functionPath) {
    Get-ChildItem -Path $functionPath -Filter '*.ps1' | Sort-Object Name | ForEach-Object {
        . $_.FullName
    }
}
#endregion functions

#Import-Module Az.Tools.Predictor
if (CanUsePredictionSource) {
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin -PredictionViewStyle ListView
}
elseif ($PSEdition -eq 'Core') {
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin
}

# if ((Test-Path $azContextImport) -and (Get-Module Az.Accounts -ListAvailable)) {
#     $data = Get-Content $azContextImport | ConvertFrom-Json
#     if ($data.Contexts.Count -gt 1) {
#         Import-AzContext -Path $azContextImport
#     }
# }

<# VS Code Environment #>
# if ($host.Name -eq 'Visual Studio Code Host') {
#     if (Import-Module EditorServicesCommandSuite) {
#         Import-EditorCommand -Module EditorServicesCommandSuite
#     }
# }
