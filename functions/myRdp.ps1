if (-not $IsMacOS) {
    function myRdp {
            [CmdletBinding()]
            param (
                $server,
                [switch]$fullScreen
            )
            if ($fullScreen) {
                mstsc.exe -v $server -f
            }
            else {
                mstsc.exe -v $server /w 2150 /h 1250
            }
        }
}