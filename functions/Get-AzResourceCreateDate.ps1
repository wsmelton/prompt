function Get-AzResourceCreateDate {
    [CmdletBinding()]
    param(
        [string]$ResourceGroupName
    )

    $context = Get-AzContext
    $subName = $context.Subscription.Name
    $subId = $context.Subscription.Id
    if ($ResourceGroupName) {
        $uri = "/subscriptions/$($subId)/resourceGroups/$($ResourceGroupName)/resources?`$expand=createdTime&api-version=2021-04-01"
        Write-Verbose "URI: $uri"
    }
    else {
        $uri = "/subscriptions/$($subId)/resources?api-version=2021-04-01&`$expand=createdTime"
    }

    Write-Host "Subscription Context: $subName"
    $data = Invoke-AzRestMethod -Method GET -Path $uri
    ($data.Content | ConvertFrom-Json).value | ForEach-Object -Throttle 10 -Parallel {
        $resource = $_
        [pscustomobject]@{
            Name               = $resource.name
            #        CreatedDateUTC     = $resource.createdTime
            CreatedDatePacific = ([System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId([datetime]$resource.createdTime, 'Pacific Standard Time'))
            Type               = $resource.type
            Sku                = $resource.sku
            Location           = $resource.location
            Tags               = $resource.tags
        }
    }
}