function GitLog {
    [Alias('glc')]
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [int]$LineCount = 5,

        [Parameter(Position = 1)]
        [string]$FilePath
    )
    if ($FilePath) {
        git log --pretty=oneline --all --abbrev-commit --full-history -- $FilePath
    }
    else {
        git log --pretty=oneline -$LineCount
    }
}