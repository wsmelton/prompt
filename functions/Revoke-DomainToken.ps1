if (-not $IsMacOS) {
    function Revoke-DomainToken {
            <#
            .SYNOPSIS
            Revoking user access in Active Directory and Azure AD Tenant
            Ref: https://docs.microsoft.com/en-us/azure/active-directory/enterprise-users/users-revoke-access
            #>
            [CmdletBinding(SupportsShouldProcess)]
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
            }
            process {
                try {
                    if ($PSEdition -eq 'Core') {
                        Import-Module ActiveDirectory -UseWindowsPowerShell -ErrorAction Stop
                    }
                    else {
                        Import-Module ActiveDirectory -ErrorAction Stop
                    }
                }
                catch {
                    throw "Issue loading ActiveDirectory Module: $($_)"
                }
    
                try {
                    if ($PSEdition -eq 'Core') {
                        Import-Module AzureAD -UseWindowsPowerShell -ErrorAction Stop
                    }
                    else {
                        Import-Module AzureAD -ErrorAction Stop
                    }
                }
                catch {
                    throw "Issue loading AzureAD Module: $($_)"
                }
    
                if ($PSCmdlet.ShouldProcess($justUsername, 'Disabling Active Directory Identity')) {
                    try {
                        if (Get-ADUser -Identity $justUsername -Credential $ADCredential -ErrorAction SilentlyContinue) {
                            Disable-ADAccount -Identity $justUsername -Credential $ADCredential -ErrorAction Stop
                        }
                        else {
                            Write-Warning "No user found matching $justUsername"
                            return
                        }
                    }
                    catch {
                        throw "Issue disabling User [$justUsername]: $($_)"
                    }
                }
                if ($PSCmdlet.ShouldProcess($justUsername, 'Reseting password to random value x2')) {
                    try {
                        1..2 | ForEach-Object {
                            Set-ADAccountPassword -Identity $justUsername -Credential $ADCredential -Reset -NewPassword (ConvertTo-SecureString -String (New-RandomPassword) -AsPlainText -Force) -ErrorAction Stop
                        }
                    }
                    catch {
                        throw "Issue reseting password for User [$justUsername]: $($_)"
                    }
                }
                try {
                    Get-AzureADTenantDetail -ErrorAction Stop >$null
                    Write-Host 'Connected to Azure AD'
                }
                catch {
                    Write-Warning 'No active connection found to Azure AD'
                    Connect-AzureAD >$null
                }
    
                if ($PSCmdlet.ShouldProcess($Identity, 'Disabling Azure AD Identity')) {
                    try {
                        Set-AzureADUser -ObjectId $Identity -AccountEnabled $false -ErrorAction Stop
                    }
                    catch {
                        throw "Issue disabling Azure AD Account [$Identity]: $($_)"
                    }
                }
                if ($PSCmdlet.ShouldProcess($Identity, 'Revoking Azure AD Token')) {
                    try {
                        Revoke-AzureADUserAllRefreshToken -ObjectId $Identity -ErrorAction Stop
                    }
                    catch {
                        throw "Issue revoking Azure AD Account [$Identity]: $($_)"
                    }
                }
            }
        }
}