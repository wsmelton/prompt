if (-not $IsMacOS) {
    function testAdMembership {
            param(
                [Parameter(Position = 0)]
                [string]$User,
                [Parameter(Position = 1)]
                [string]$Group)
            trap { return 'error' }
            $adUserParams = @{
                Filter     = "memberOf -RecursiveMatch '$((Get-ADGroup $Group).DistinguishedName)'"
                SearchBase = $((Get-ADUser $User).DistinguishedName)
            }
            if (Get-ADUser @adUserParams) { $true } else { $false }
        }
}