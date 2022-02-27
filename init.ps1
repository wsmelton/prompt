if (-not (Get-InstalledScript Install-RequiredModule)) {
    try {
        Install-Script Install-RequiredModule -Repository PSGallery -Force
    } catch {
        throw "Issue installed dependency: Install-RequiredModule script: $($_)"
    }
}

try {
    Install-RequiredModule -RequiredModulesFile $PSScriptRoot\requiredmodules.psd1 -Repository PSGallery -Scope AllUsers
} catch {
    throw "Issue installing required modules: $($_)"
}

# setup initial Secret vault, adjust the configuration as you want or need for security purposes
try {
    Set-SecretStoreConfiguration -Authentication None -Interaction None
    Register-SecretVault -Name myCredentials -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault

    Wite-Host 'Vault [myCredentials] created, use Set-Secret to add the needed credential objects'
} catch {
    Write-Warning "Issue creating scripts vault: $($_)"
}