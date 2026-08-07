function Set-Subscription {
    [Alias('ss')]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromRemainingArguments, Position = 0)]
        [string]
        $SubName,

        [string]
        $TenantId = $tenantIdProd
    )
    process {
        $cContext = Get-AzContext
        if ($cContext.Name -ne $SubName) {
            $result = Select-AzSubscription $SubName -Tenant $TenantId
        }
        if ($result.Name -eq $SubName) {
            Write-Host "Context switched to subscription: [$SubName]" -ForegroundColor DarkCyan
        }
    }
}