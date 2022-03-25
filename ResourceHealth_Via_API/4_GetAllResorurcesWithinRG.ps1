#Loop through each reasource group and get all resources.
#Add everything to a hash table
$Groups = @()

foreach ($rg in $ResourceGroups) {
    $ResourceGroupUri = "https://management.azure.com/subscriptions/$subscriptionID/resourceGroups/$rg/resources?api-version=$APIVersion"
    $res = (Invoke-RestMethod -Uri $ResourceGroupUri -Method GET -Headers $authHeader).value

    #Create array of all resources
    $resources = @{}
    $resources.Add($rg, $res)

    #Add all resource groups and their resources to a hash table
    $Groups += $resources
}