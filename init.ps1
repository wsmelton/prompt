if ($psedition -eq 'Core') {
    if (-not (Get-InstalledScript Install-RequiredModule)) {
        try {
            Install-Script Install-RequiredModule -Repository PSGallery -Force
        } catch {
            throw "Issue installed dependency: Install-RequiredModule script: $($_)"
        }
    }
} else {
    if (-not (Get-PSResource Install-RequiredModule)) {
        try {
            Install-PSresource Install-RequiredModule -Repository PSGallery -Force
        } catch {
            throw "Issue installed dependency: Install-RequiredModule script: $($_)"
        }
    }
}

try {
    Install-RequiredModule -RequiredModulesFile $PSScriptRoot\requiredmodules.psd1 -TrustRegisteredRepositories -Scope AllUsers -Quiet
} catch {
    throw "Issue installing required modules: $($_)"
}

# setup initial Secret vault, adjust the configuration as you want or need for security purposes
try {
    if (Get-Module Microsoft.PowerShell.SecretStore -ListAvailable) {
        if ((Get-SecretStoreConfiguration).Authentication -ne 'None') {
            Read-Host 'Setting Secret Store to no authentication, select N if you do not want to apply this in the next prompt (enter to continue)'
            Set-SecretStoreConfiguration -Authentication None -Interaction None
        } else {
            Write-Host 'Secret Store authentication already set to [None]'
        }
        if (-not (Get-SecretVault -Name myCredentials)) {
            Register-SecretVault -Name myCredentials -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault
        } else {
            Write-Warning 'Secret vault [myCredentials] already exists'
        }

        Write-Host 'Vault [myCredentials] can be used to store credentials used in your local scripts. Use Set-Secret to add'
    }
} catch {
    Write-Warning "Issue creating scripts vault: $($_)"
}