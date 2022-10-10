if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    throw "This script needs to be run As Admin"
}

if ($psedition -eq 'Core') {
    if (-not (Get-InstalledScript Install-RequiredModule)) {
        try {
            Install-Script Install-RequiredModule -Repository PSGallery -Force
        } catch {
            throw "Issue installed dependency: Install-RequiredModule script: $($_)"
        }
    }
} else {
    if (-not (Get-Module Install-RequiredModule)) {
        try {
            Install-Module Install-RequiredModule -Repository PSGallery -Force
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

<# Make sure Chocolatey is installed #>
try {
    choco --version >$null
} catch {
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

# install some stuff for Kubernetes management
Write-Output "Installing Kubernetes tools"
choco install kubernetes-cli -r -y
choco install kubectx -r -y
choco install kubens -r -y
choco install k9s -r -y

Write-Output "Do not forget to install Popeye as well: https://github.com/derailed/popeye/releases"