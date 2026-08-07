function Reset-Az {
    param(
        [string]
        $TenantId,
        [switch]
        $DeviceAuth
    )
    Clear-AzContext -Force
    Connect-AzAccount -UseDeviceAuthentication:$DeviceAuth -Tenant $TenantId -WarningAction SilentlyContinue >$null
    Get-AzContext -ListAvailable | ForEach-Object { $n = $_.Name; Rename-AzContext -SourceName $n -TargetName $n.Split(' ')[0] }
    Save-AzContext -Path $azContextImport -Force

    Import-AzContext -Path $azContextImport >$null
}