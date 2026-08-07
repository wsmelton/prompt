function Get-AzureAddressSpace {
    [CmdletBinding()]
    param()
    process {
        try {
            $subscriptions = Get-AzSubscription -TenantId $tenantIdProd -ErrorAction Stop
        }
        catch {
            throw "Issue getting list of Subscriptions: $($_)"
        }
        if ($subscriptions) {
            $subscriptions | ForEach-Object -ThrottleLimit 10 -Parallel {
                $subName = $_.Name
                $azContext = Get-AzContext -WarningAction SilentlyContinue
                if ($azContext -and $azContext.SubscriptionName -ne $subName) {
                    Set-AzContext -Subscription $subName -WarningAction SilentlyContinue >$null
                }
                $virtualNetworks = Get-AzVirtualNetwork
                foreach ($vnet in $virtualNetworks) {
                    $resourceGroup = $vnet.ResourceGroupName.ToLower()
                    $vnetName = $vnet.Name.ToLower()
                    $vnetLocation = $vnet.Location
                    $addressSpaces = $vnet.AddressSpace.AddressPrefixes

                    if ($addressSpaces.Count -gt 1) {
                        foreach ($space in $addressSpaces) {
                            [pscustomobject]@{
                                Subscription      = $subName
                                ResourceGroupName = $resourceGroup
                                VnetName          = $vnetName
                                Location          = $vnetLocation
                                AddressSpace      = $space
                            }
                        }
                    }
                    else {
                        [pscustomerobject]@{
                            Subscription      = $subName
                            ResourceGroupName = $resourceGroup
                            VnetName          = $vnetName
                            Location          = $vnetLocation
                            AddressSpace      = $addressSpaces
                        }
                    }
                }
            }
        }
    }
}