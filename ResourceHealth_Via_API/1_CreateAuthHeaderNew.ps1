# Grab credentials from cred.ps1
###.\cred.ps1

# $result = Get-AADAppoAuthToken -ClientID $ClientID -ClientSecret $ClientSecret -TenantId $TenantId 
# $AuthKey = "Bearer " + ($result.access_token)
# $authHeader = @{
#     'Content-Type'  = 'application/json'
#     'Accept'        = 'application/json'
#     'Authorization' = $AuthKey
# }




#####################################################################################################
$TenantId = "e10ddeb6-af98-4762-a6a6-a6caf23f2ba1" 
$ClientID = "45b19b88-611d-4166-b345-66ff89c25403" 
$ClientSecret = "lx44Wb5yqTjq14DuUi3R_.bMyb3EcZozuo"

$TokenEndpoint = {https://login.windows.net/{0}/oauth2/token} -f $TenantId 
$resourceURL = "https://management.core.windows.net/";

$Body = @{
        'resource'= $resourceURL
        'client_id' = $ClientID
        'grant_type' = 'client_credentials'
        'client_secret' = $ClientSecret
}

$params = @{
    ContentType = 'application/x-www-form-urlencoded'
    Headers = @{'accept'='application/json'}
    Body = $Body
    Method = 'Post'
    URI = $TokenEndpoint
}

$token = Invoke-RestMethod @params

Write-Output $token.access_token