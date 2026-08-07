function Get-AzureKeyVaultSecret {
    <#
    .SYNOPSIS
    Retrieve a Secret's value from an Azure Key Vault

    .EXAMPLE
    Get-AzureKeyVaultSecret kvwhatever mysecert, mysecret2

    Grant Key Vault Secrets User to the key vault and retrieves each secret name
    #>
    [Alias('akvs')]
    [CmdletBinding()]
    param(
        # Key Vault name holding the secret
        [Parameter(Position = 0)]
        [string]$KeyVaultName,

        # Secret name(s) to retrieve plain text values
        [Parameter(Position = 1)]
        [string[]]$SecretName,

        # Just list the secrets
        [Parameter(Position = 2)]
        [switch]$ListOnly
    )
    try {
        $keyVault = Get-AzKeyVault -VaultName $KeyVaultName -ErrorAction Stop
        Write-Verbose ($keyVault | Out-String)
    }
    catch {
        throw "Unable to pull the Key Vault $($_)"
    }
    <# Grant Key Vault Secrets User #>
    # $roleParams = @{
    #     SignInName         = $Username
    #     RoleDefinitionName = 'Key Vault Secrets User'
    #     Scope              = $keyVault.ResourceId
    #     ErrorAction        = 'Stop'
    # }
    # try {
    #     $azRoleAssigned = New-AzRoleAssignment @roleParams
    #     Write-Verbose ($azRoleAssigned | Out-String)
    #     Start-Sleep -Seconds 4
    # } catch {
    #     throw "Unable to create role assignment: $($_)"
    # }
    try {
        $kvSecrets = Get-AzKeyVaultSecret -VaultName $keyVault.VaultName -ErrorAction Stop
        if ($kvSecrets) {
            if ($ListOnly) {
                $kvSecrets
            } else {
                $secrets = $kvSecrets.Where({ $_.Name -in $SecretName })
                foreach ($secret in $secrets) {
                    $plainTextValue = Get-AzKeyVaultSecret -VaultName $keyVault.VaultName -Name $secret.Name -AsPlainText -ErrorAction Stop
                    if ([string]::IsNullOrEmpty($plainTextValue)) {
                        Write-Warning "No value found in the secret [$($secret.Name)]"
                    }
                    else {
                        [pscustomobject]@{
                            KeyVaultName = $keyVault.VaultName
                            SecretName   = $secret.Name
                            Value        = $plainTextValue
                        }
                    }
                }
            }
        } else {
            Write-Warning "No secrets found in vault $($keyVault.VaultName)"
        }
    } catch {
        throw "Issue retrieving secret: $($_)"
    } finally {
        Remove-AzRoleAssignment @roleParams >$null
    }
}