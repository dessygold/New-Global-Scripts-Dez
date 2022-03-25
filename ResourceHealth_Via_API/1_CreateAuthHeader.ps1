# Grab credentials from cred.ps1
###.\cred.ps1
# $result = Get-AADAppoAuthToken -ClientID $ClientID -ClientSecret $ClientSecret -TenantId $tenantId 
# $AuthKey = "Bearer " + ($result.access_token)
# $authHeader = @{
#     'Content-Type'  = 'application/json'
#     'Accept'        = 'application/json'
#     'Authorization' = $AuthKey
# }



#####################################################################################################
##$tenantId = "e10ddeb6-af98-4762-a6a6-a6caf23f2ba1" 

$tenantId = "desmondosatuyiyahoo.onmicrosoft.com"
$clientId = "45b19b88-611d-4166-b345-66ff89c25403" 
$clientSecret = "lx44Wb5yqTjq14DuUi3R_.bMyb3EcZozuo"
$subscriptionID = "c93020ea-c4db-48ab-a06f-058949354bab"

$TokenEndpoint = {https://login.windows.net/{0}/oauth2/token} -f $tenantId 
$resourceURL = "https://management.core.windows.net/"

$Body = @{
        'resource'= $resourceURL
        'client_id' = $clientId
        'grant_type' = 'client_credentials'
        'client_secret' = $clientSecret
}

$params = @{
    ContentType = 'application/x-www-form-urlencoded'
    Headers = @{'accept'='application/json'}
    Body = $Body
    Method = 'Post'
    URI = $TokenEndpoint
}



$token = Invoke-RestMethod @params

$authHeader = @{
    "Content-Type" = "application/json"
    "Authorization"= "Bearer " + $token
    }

Write-Output $token.access_token


####################################################
$APIVersion = "2017-05-10"
$subscriptionID = "c93020ea-c4db-48ab-a06f-058949354bab"
$RGuri = "https://management.azure.com/subscriptions/$subscriptionID/resourcegroups?api-version=$APIVersion"

$ResourceGroups = (Invoke-RestMethod -Uri $RGuri -Method GET -Headers $authHeader).value.name

$ResourceGroups