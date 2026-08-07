if (-not $IsMacOS) {
    function findAdSrv {
            [CmdletAttribute()]
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
            process {
                if ($IsCoreCLR -and -not (Get-Module ActiveDirectory)) {
                    Import-Module ActiveDirectory -UseWindowsPowerShell -ErrorAction Stop
                }
                elseif (-not (Get-Module ActiveDirectory)) {
                    Import-Module ActiveDirectory -ErrorAction Stop
                }
    
                $defaultProps = 'Description', 'MemberOf', 'whenCreated', 'LastLogonDate'
                if ($PSBoundParameters.ContainsKey('Props')) {
                    $srvResult = Get-ADComputer -Identity $str -Properties $defaultProps, $Props
                }
                else {
                    $srvResult = Get-ADComputer -Identity $str -Properties $defaultProps
                }
                if ($srvResult) {
                    if ($PSBoundParameters.ContainsKey('ExpandMemberOf')) {
                        $srvResult.MemberOf | Sort-Object
                    }
                    else {
                        $srvResult
                    }
                }
            }
        }
}