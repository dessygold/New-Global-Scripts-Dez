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
#$TenantId = "desmondosatuyiyahoo.onmicrosoft.com"
$ClientID = "45b19b88-611d-4166-b345-66ff89c25403" 
$ClientSecret = "lx44Wb5yqTjq14DuUi3R_.bMyb3EcZozuo"

## We can get an AAD access token for REST API calls using AzureAD Module.


#Install-Module AzureAD -Force
Import-Module -Name "AzureAD"
$AadModule = Get-Module -Name "AzureAD" -ListAvailable
$adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
[System.Reflection.Assembly]::LoadFrom($adal) | Out-Null

$authority = "https://login.windows.net/$TenantId"
$authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority
$AdUserCred = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.ClientCredential" -ArgumentList $ClientID, $ClientSecret
$token = ($authContext.AcquireTokenAsync("https://management.azure.com/", $AdUserCred)).Result.AccessToken
Write-Output $token
$authHeader = @{
    "Content-Type" = "application/json"
    "Authorization"= "Bearer " + $token
    }