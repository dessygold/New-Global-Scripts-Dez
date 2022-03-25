#get all resource groups within a subscription

$TenantId = "e10ddeb6-af98-4762-a6a6-a6caf23f2ba1" 
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
####################################################
$APIVersion = "2017-05-10"
$subscriptionID = "c93020ea-c4db-48ab-a06f-058949354bab"
$RGuri = "https://management.azure.com/subscriptions/$subscriptionID/resourcegroups?api-version=$APIVersion"

$ResourceGroups = (Invoke-RestMethod -Uri $RGuri -Method GET -Headers $authHeader).value.name

$ResourceGroups