#requires -Version 7.4
#requires -Modules 'Microsoft.PowerShell.PSResourceGet'
[CmdletBinding()]
param(
    [switch]$NoK8s
)
$ErrorView = 'DetailedView'

if (-not $IsMacOS -and -not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    throw "This script needs to be run As Admin"
}

# Expect you to be on PowerShell 7.4 or higher as this has Microsoft.PowerShell.PSResourceGet built-in now
Set-PSResourceRepository -Name PSGallery -Trusted

if (-not (Get-Module ModuleFast)) {
    try {
        Invoke-WebRequest bit.ly/modulefast | Invoke-Expression
    } catch {
        throw "Issue installed dependency: ModuleFast: $($_)"
    }
}

try {
    Install-ModuleFast -Path $PSScriptRoot/requiredmodules.psd1 -Verbose
} catch {
    throw "Issue installing required modules: $($_)"
}
if ($IsMacOS) {
    #TODO install these from brew
    # install PowerShell using package install from PS team
    <#
        #kubectl krew plugins
        ctx
        foreach
        ns
        sniff
        status
        stern
        validate
        status
    #>
    <#
        # bicep
        brew tap azure/bicep
        brew install bicep
        brew install jq
        brew install helm
        brew install git

        # can't remember install but miniconda3 for python versions (use this with Azure CLI)
        # create env using {conda env list}
        # conda config --set ssl_verify ~/cacert.pem
    #>
    <#
    # specific version of kubectl?
    curl -LO "https://dl.k8s.io/release/v1.26.3/bin/darwin/arm64/kubectl"
    ls -la
    chmod +x ./kubectl
    sudo mv ./kubectl /usr/local/bin/kubectl
    sudo chown root: /usr/local/bin/kubectl
    #>

}
if (-not $IsMacOS) {
    <# Make sure Chocolatey is installed #>
    try {
        $chocoDetail = Get-Command choco -CommandType Application -ErrorAction Stop
        if ($chocoDetail) {
            Write-Host "Choco version detected as: $(choco --version)"
        }
    } catch {
        Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    }

    if ($PSBoundParameters.ContainsKey('NoK8s')) {
        Write-Host 'Skipping install of Kubernetes tools'
    } else {
        if ($chocoDetail) {
            # install some stuff for Kubernetes management
            Write-Output "Installing Kubernetes tools"
            choco install kubernetes-cli --limitoutput --yes
            choco install kubectx --limitoutput --yes
            choco install kubens --limitoutput --yes
            choco install k9s --limitoutput --yes
            Write-Output "Do not forget to install Popeye as well: https://github.com/derailed/popeye/releases"
        }
    }

    # install of basics
    if (-not (Get-Command bicep -CommandType Application -ErrorAction SilentlyContinue)) {
        choco install bicep --limitoutput --yes
    }

    if (-not (Get-Command git -CommandType Application -ErrorAction SilentlyContinue)) {
        choco install git --limitoutput --yes
    }
    if (-not (Get-Command wt -CommandType Application -ErrorAction SilentlyContinue)) {
        choco install windows.terminal --limitoutput --yes
    }
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
        if (-not (Get-SecretVault -Name myCredentials -ErrorAction SilentlyContinue)) {
            Register-SecretVault -Name myCredentials -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault
        } else {
            Write-Warning 'Secret vault [myCredentials] already exists'
        }

        if (Get-SecretVault -Name myCredentials) {
            Write-Host 'Vault [myCredentials] can be used to store credentials used in your local scripts. Use Set-Secret to add'
        } else {
            Write-Warning "Vault [myCredentials] was not created"
        }
    }
} catch {
    Write-Warning "Issue creating scripts vault: $($_)"
}
