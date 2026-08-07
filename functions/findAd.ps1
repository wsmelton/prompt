if (-not $IsMacOS) {
    function findAd {
            [CmdletBinding()]
            param(
                [Parameter(Position = 0, Mandatory)]
                [string]
                $str,
    
                [Parameter(Position = 1)]
                [string[]]
                $Props,
    
                [Parameter(Position = 2)]
                [Alias('emo')]
                [switch]
                $ExpandMemberOf
            )
            begin {
                $hasSpace = $false
            }
            process {
                if ($IsCoreCLR -and -not (Get-Module ActiveDirectory)) {
                    Import-Module ActiveDirectory -UseWindowsPowerShell -ErrorAction Stop
                }
                elseif (-not (Get-Module ActiveDirectory)) {
                    Import-Module ActiveDirectory -ErrorAction Stop
                }
                $hasSpace = $str.Split(' ').Count -gt 1
    
                $adObject = Get-ADObject -Filter "Name -eq '$str'"
    
                if ($adObject) {
                    switch ($adObject.ObjectClass) {
                        'user' {
                            $defaultProps = 'Description', 'MemberOf', 'whenCreated', 'whenChanged', 'LastLogonDate', 'PasswordLastSet', 'UserPrincipalName', 'CannotChangePassword', 'PasswordNeverExpires'
    
                            if ($PSBoundParameters.ContainsKey('Props')) {
                                $defaultProps = $defaultProps, $Props
                            }
                            Write-Verbose "Properties: $($defaultProps -join ',')"
                            $finalAdObject = Get-ADUser -Filter "Name -eq '$str'" -Properties $defaultProps
                        }
                        default {
                            $defaultProps = 'Description', 'MemberOf', 'whenCreated', 'whenChanged', 'UserPrincipalName'
    
                            if ($PSBoundParameters.ContainsKey('Props')) {
                                $defaultProps = $defaultProps, $Props
                            }
                            Write-Verbose "Properties: $($defaultProps -join ',')"
                            $finalAdObject = Get-ADObject -Filter "Name -eq '$str'" -Properties $defaultProps
                        }
                    }
    
                    if ($finalAdObject) {
                        if ($PSBoundParameters.ContainsKey('ExpandMemberOf')) {
                            $finalAdObject.MemberOf | Sort-Object
                        }
                        else {
                            $finalAdObject
                        }
                    }
                }
            }
        }
}