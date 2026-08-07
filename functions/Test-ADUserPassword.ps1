function Test-ADUserPassword {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCredential]
        $Credential,

        [ValidateSet('ApplicationDirectory', 'Domain', 'Machine')]
        [string]
        $ContextType = 'Domain',

        [string]
        $Server
    )
    try {
        Add-Type -AssemblyName System.DirectoryServices.AccountManagement -ErrorAction Stop
        try {
            if ($PSBoundParameters.ContainsKey('Server')) {
                $pContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext($ContextType, $Server)
            }
            else {
                $pContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext($ContextType)
            }
        }
        catch {
            Write-Error -Message "Issue connecting $ContextType -- $($_)"
        }
        try {
            $pContext.ValidateCredentials($Credential.UserName, $Credential.GetNetworkCredential().Password, 'Negotiate')
        }
        catch [UnauthorizedAccessException] {
            Write-Warning -Message 'Access denied when connecting to server.'
            return $false
        }
        catch {
            Write-Error -Exception $_.Exception -Message "Unhandled error occurred: $($_)"
        }
    }
    catch {
        throw
    }
}