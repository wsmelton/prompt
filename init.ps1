if (-not (Get-InstalledScript Install-RequiredModule)) {
    try {
        Install-Script Install-RequiredModule -Repository PSGallery -Force
    } catch {
        throw "Issue installed dependency: Install-RequiredModule script: $($_)"
    }
}

try {
    Install-RequiredModule -RequiredModulesFile $PSScriptRoot\requiredmodules.psd1 -TrustRegisteredRepositories -Scope AllUsers -Quiet
} catch {
    throw "Issue installing required modules: $($_)"
}

# setup initial Secret vault, adjust the configuration as you want or need for security purposes
try {
    Read-Host 'Setting local SecretStore to no authentication, select N if you do not want to apply this in the next prompt (enter to continue)'
    Set-SecretStoreConfiguration -Authentication None -Interaction None
    if (-not (Get-SecretVault -Name myCredentials)) {
        Register-SecretVault -Name myCredentials -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault
    } else {
        Write-Warning 'Secret vault [myCredentials] already exists'
    }

    Write-Host 'Vault [myCredentials] can be used to store credentials used in your local scripts. Use Set-Secret to add'
} catch {
    Write-Warning "Issue creating scripts vault: $($_)"
}