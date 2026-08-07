if (-not $IsMacOS) {
    function Find-MissingCommands {
            <#
            .SYNOPSIS
            Find missing commands between the dbatools.io/commands and dbatools Module public functions
    
            .PARAMETER ModulePath
            Path to dbatools local repository
    
            .PARAMETER CommandPagePath
            Full path to the index.html commands page (e.g. c:\git\web\commands\index.html)
    
            .PARAMETER Reverse
            Compare commands found in the CommandPagePath to those in the module
    
            .EXAMPLE
            Find-MissingCommands
    
            Returns string list of the commands not found in the Commands page.
            #>
            [cmdletbinding()]
            param(
                [string]
                $ModulePath = 'C:\git\dbatools',
    
                [string]
                $CommandPagePath = 'C:\git\web\commands\index.html',
    
                [switch]
                $Reverse
            )
            $commandPage = Get-Content $CommandPagePath
    
            if (-not (Get-Module dbatools)) {
                Import-Module $ModulePath
            }
            $commands = Get-Command -Module dbatools -CommandType Cmdlet, Function | Where-Object Name -NotIn 'Where-DbaObject', 'New-DbaTeppCompletionResult' | Select-Object -Expand Name
    
            if ($Reverse) {
                $commandRefs = $commandPage | Select-String '<a href="http://docs.dbatools.io/' | ForEach-Object { $_.ToString().Trim() }
                $commandRefList = foreach ($ref in $commandRefs) {
                    $ref.ToString().SubString(0, $ref.ToString().IndexOf('">')).TrimStart('<a href="http://docs.dbatools.io/')
                }
                $commandRefList | Where-Object { $_ -notin $commands }
            }
            else {
                #find missing
                $notFound = $commands | ForEach-Object -ThrottleLimit 10 -Parallel { $foundIt = $using:commandPage | Select-String -Pattern $_; if (-not $foundIt) { $_ } }
    
                # found
                $found = $commands | ForEach-Object -ThrottleLimit 10 -Parallel { $foundIt = $using:commandPage | Select-String -Pattern $_; if ($foundIt) { $_ } }
    
                Write-Host "Tally: Total Commands ($($commands.Count)) | Found ($($found.Count)) | Missing ($($notFound.Count))"
                $notFound
            }
        }
}