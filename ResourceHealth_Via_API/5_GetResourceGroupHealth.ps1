#get the health of the whole resource group
# Add each health status to a hashtable before output a complete table with all resource groups and their resource health
$resourceGroupHealth = @{}
foreach ($ResourceGroup in $ResourceGroups) {
    
    #Set resource group name and use it in our url
    $health = Invoke-RestMethod -Uri "https://management.azure.com/subscriptions/$subscriptionID/resourceGroups/$ResourceGroup/Providers/Microsoft.ResourceHealth/availabilityStatuses?api-version=2015-01-01" -Method GET -Headers $authHeader

    $currentHealth = @{}
    $currentHealth = @{
        [string]"$ResourceGroup" = [object]$health
    }

    $resourceGroupHealth += $currentHealth
    
}

$resourceGroupHealth

#Explore the results
$resourceGroupHealth.item('ResourceGroup').Value.Properties