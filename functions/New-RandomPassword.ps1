function New-RandomPassword {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [int]$CharLength = 15
    )
    $charlist = [char]94..[char]126 + [char]65..[char]90 + [char]47..[char]57
    $pwLength = (1..10 | Get-Random) + 80
    $pwdList = @()
    for ($i = 0; $i -lt $pwLength; $i++) {
        $pwdList += $charList | Get-Random
    }
    ($pwdList -join '').Substring(0, $CharLength)
}