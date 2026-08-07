function findLocalAdmins {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]
        $Server,

        [PSCredential]
        $Credential
    )
    $Server | ForEach-Object -ThrottleLimit 15 -Parallel {
        $s = $_
        $psSessionParams = @{
            ComputerName = $s
        }
        if ($using:Credential) {
            $psSessionParams.Add('Credential', $using:Credential)
        }
        try {
            $psSession = New-PSSession @psSessionParams -ErrorAction Stop
        }
        catch {
            Write-Warning "Unable to connect to server: $($s) | $($_)"
        }
        if ($psSession) {
            try {
                $resultData = Invoke-Command -Session $psSession -ScriptBlock { Get-LocalGroupMember -Group Administrators } -ErrorAction Stop
                if ($resultData) {
                    foreach ($r in $resultData) {
                        [pscustomobject]@{
                            Server  = $s
                            Name    = $r.Name
                            Type    = $r.ObjectClass
                            IsLocal = if ($r.PrincipalSource -eq 'Local') { $true } else { $false }
                        }
                    }
                }
            }
            catch {
                $resultOld = Invoke-Command -Session $psSession -ScriptBlock { net localgroup Administrators }
                foreach ($r in ($resultOld | Select-Object -Skip 6)) {
                    if ($r -notmatch 'The command completed successfully' -and -not [string]::IsNullOrEmpty($r)) {
                        [pscustomobject]@{
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