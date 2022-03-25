######### ACCESS TOKEN FROM POST MAN ########################
$authToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6ImpTMVhvMU9XRGpfNTJ2YndHTmd2UU8yVnpNYyIsImtpZCI6ImpTMVhvMU9XRGpfNTJ2YndHTmd2UU8yVnpNYyJ9.eyJhdWQiOiJodHRwczovL21hbmFnZW1lbnQuYXp1cmUuY29tLyIsImlzcyI6Imh0dHBzOi8vc3RzLndpbmRvd3MubmV0L2UxMGRkZWI2LWFmOTgtNDc2Mi1hNmE2LWE2Y2FmMjNmMmJhMS8iLCJpYXQiOjE2NDgxNzU3NTAsIm5iZiI6MTY0ODE3NTc1MCwiZXhwIjoxNjQ4MTc5NjUwLCJhaW8iOiJFMllBZ3JZVExNemRLV0xoRHNsTWdiT1Ywd0U9IiwiYXBwaWQiOiI0NWIxOWI4OC02MTFkLTQxNjYtYjM0NS02NmZmODljMjU0MDMiLCJhcHBpZGFjciI6IjEiLCJpZHAiOiJodHRwczovL3N0cy53aW5kb3dzLm5ldC9lMTBkZGViNi1hZjk4LTQ3NjItYTZhNi1hNmNhZjIzZjJiYTEvIiwiaWR0eXAiOiJhcHAiLCJvaWQiOiIwYWNkYzk5NC0xNzdiLTQxZTAtYjE0MC1hZTBiMjE4NmFkNDAiLCJyaCI6IjAuQVVZQXR0NE40Wml2WWtlbXBxYks4ajhyb1VaSWYza0F1dGRQdWtQYXdmajJNQk9BQUFBLiIsInN1YiI6IjBhY2RjOTk0LTE3N2ItNDFlMC1iMTQwLWFlMGIyMTg2YWQ0MCIsInRpZCI6ImUxMGRkZWI2LWFmOTgtNDc2Mi1hNmE2LWE2Y2FmMjNmMmJhMSIsInV0aSI6InJBRnNqMkZJczBTZndoc1RfcjE0QUEiLCJ2ZXIiOiIxLjAiLCJ4bXNfdGNkdCI6MTY0MTg2Nzk3Mn0.Np1JA5RAH91_hCgBzZA8r4g7qycmUnhXvUGFY1q4p-3MkXCwQ6qPVXA_yHINZ4pC3z7VS-Cnqn_1C_-6GFVrQ-ZJu0-c1IsgqgLS3cnPASwwS4SlJmFMJWx71Tg19VEE-JYxtiOJlxQe-CFJqBQVhNNQdmicXbxziJ-hWoRSLE73hKEgDrSASUmE5zofRfTLIK_SQzdQzzLvKALabWZdgCVp0C-Cp31QRVE9FT0v57gS91QttwF6ml56qPVVfkqeKuPCXNt4_2PgO7oDk98Co1FFL2w9ZUYpkyFJENEIw7q2DXUnQW37FL5oJ7-39gEhetoa12Lp6pl2MWYW7zJfhw"
######################## Create Auth Header#####################
$authHeader = @{
    "Content-Type" = "application/json"
    "Authorization"= "Bearer " + $authToken
    }


 #Loop through each reasource group and get all resources.
#Add everything to a hash table
$Subs = Get-AzSubscription
#$Subresources = @()
   foreach ($Sub in $Subs) {
    Set-AzContext $Sub.id | Out-Null
    Write-Host "Processing Subscription:" $($Sub).name

    #get all resource groups within a subscription

$APIVersion = "2022-01-01"
$RGURI = "https://management.azure.com/subscriptions/$Sub/resourcegroups?api-version=$APIVersion"

$ResourceGroups = (Invoke-RestMethod –Uri $RGURI –Method GET –Headers $authHeader).value.name

    # Get all Azure resources for current subscription
    foreach ($rg in $ResourceGroups) {
    $ResourceGroupUri = "https://management.azure.com/subscriptions/$Sub/resourceGroups/$rg/resources?api-version=$APIVersion"
    $res = (Invoke-RestMethod –Uri $ResourceGroupUri –Method GET –Headers $authHeader).value

    #Create array of all resources
    $resourceGroupHealth = @{}
    $resources.Add($rg, $res)
####################################################################  Resource Health #################


#foreach ($ResourceGroup in $ResourceGroups) {
    
    #Set resource group name and use it in our url
    $health = Invoke-RestMethod –Uri "https://management.azure.com/subscriptions/$Sub/resourceGroups/$rg/Providers/Microsoft.ResourceHealth/availabilityStatuses?api-version=2015-01-01" –Method GET –Headers $authHeader

    $currentHealth = @{}
    $currentHealth = @{
        [string]"$rg" = [object]$health
    }

    #Add all resource groups and their resources to a hash table
    #$Subresources += $resources

    $resourceGroupHealth += $currentHealth

    $resourceGroupHealth

#Explore the results
$resourceGroupHealth.item('ResourceGroup').Value.Properties

    # Display Health Data for Azure resources in selected subscription
    #$resourcestest = @() 
    #  $health.value | 
    #     Select-Object `
    #        @{n='subscriptionId';e={$_.id.Split("/")[2]}},
    #        location,
    #        @{n='resourceGroup';e={$_.id.Split("/")[4]}},
    #        @{n='resource';e={$_.id.Split("/")[8]}},
    #        @{n='status';e={$_.properties.availabilityState}}, # ie., Available or Unavailable
    #        @{n='summary';e={$_.properties.summary}},
    #        @{n='reason';e={$_.properties.reasonType}},
    #        @{n='occuredTime';e={$_.properties.occuredTime}},
    #        @{n='reportedTime';e={$_.properties.reportedTime}} |
    #        Format-List 

        }
 }    
 
 

 ########################
 #get the health of the whole resource group
# Add each health status to a hashtable before output a complete table with all resource groups and their resource health
# $resourceGroupHealth = @{}
# foreach ($ResourceGroup in $ResourceGroups) {
    
#     #Set resource group name and use it in our url
#     $health = Invoke-RestMethod -Uri "https://management.azure.com/subscriptions/$subscriptionID/resourceGroups/$ResourceGroup/Providers/Microsoft.ResourceHealth/availabilityStatuses?api-version=2015-01-01" -Method GET -Headers $authHeader

#     $currentHealth = @{}
#     $currentHealth = @{
#         [string]"$ResourceGroup" = [object]$health
#     }

#     $resourceGroupHealth += $currentHealth
    
# }

# $resourceGroupHealth

# #Explore the results
# $resourceGroupHealth.item('ResourceGroup').Value.Properties