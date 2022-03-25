<#
    .SYNOPSIS
       Function to connect to the Microsoft login OAuth endpoint and return an OAuth token.
    .DESCRIPTION
        Generate Azure AD oauth token.
       You can specify the resource you want in the paramenter. Default is management.core.windows.net
       Parts of this function is created from these examples: https://docs.microsoft.com/en-us/azure/monitoring-and-diagnostics/monitoring-rest-api-walkthrough

    .PARAMETER ClientID
        Azure AD application ID

    .PARAMETER ClientSecret
        Your application secret.

    .PARAMETER TenantId
        Your tenant domain name. test.onmicrosoft.com

    .PARAMETER ResourceName
        Specify if you are accessing other resources than https://management.core.windows.net
        For example microsoft partner center would have https://api.partnercenter.microsoft.com

    .EXAMPLE
        Get-AADAppoAuthToken -ClientID 'xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' -ClientSecret <application secret> -TenantId "test.no" will return
        token_type     : Bearer
        expires_in     : 3600
        ext_expires_in : 0
        expires_on     : 1505133623
        not_before     : 1505129723
        resource       : https://management.core.windows.net/
        access_token   : eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6IkhIQnlLVS0wRHFBcU1aaDZaRlBkMlZXYU90ZyIsImtpZCI6IkhIQnlLVS0wRHFBcU1aaDZaRlB
                         kMlZXYU90ZyJ9.eyJhdWQiOiJodHRwczovL21hbmFnZW1lbnQuY29yZS53aW5kb3dzLm5ldC8iLCJpc3MiOiJodHRwczovL3N0cy
                 
    .NOTES
        v1.0
        Desmond Osatuyi
    #>

# #This function generate auth token using REST api  
# Function GetAuthTokenInvokingRestApi {  
#     Param(  
#        [Parameter(Mandatory)][ValidateNotNull()][ValidateNotNullOrEmpty()]  
#        [String]$tenantId,  
#        [Parameter(Mandatory)][ValidateNotNull()][ValidateNotNullOrEmpty()]  
#        [String]$applicationId,  
#        [Parameter(Mandatory)][ValidateNotNull()][ValidateNotNullOrEmpty()]  
#        [String]$secret,  
#        [Parameter(Mandatory)][ValidateNotNull()][ValidateNotNullOrEmpty()]  
#        [string]$apiEndpointUri  
#  )  
#  $encodedSecret = [System.Web.HttpUtility]::UrlEncode($secret)  
#  $RequestAccessTokenUri = "https://login.microsoftonline.com/$tenantId/oauth2/token"  
#  $body = "grant_type=client_credentials&client_id=$applicationId&client_secret=$encodedSecret&resource=$apiEndpointUri"  
#  $contentType = 'application/x-www-form-urlencoded'  
#  try {  
#     $Token = Invoke-RestMethod -Method Post -Uri $RequestAccessTokenUri -Body $body -ContentType $contentType  
#     Write-Output $Token  
#     }  
#     catch { throw }  
#  }  
#  $apiEndpointUri = "https://management.azure.com/"  
#  $tenantId = "e10ddeb6-af98-4762-a6a6-a6caf23f2ba1"  
#  $applicationId = "45b19b88-611d-4166-b345-66ff89c25403"  
#  $secret = "lx44Wb5yqTjq14DuUi3R_.bMyb3EcZozuo"  
#  $authToken = GetAuthTokenInvokingRestApi -apiEndpointUri $apiEndpointUri -tenantId $tenantId -applicationId $applicationId -secret $secret  
#  #if (-   not $authToken) { throw "One of the provided login information is invalid 'tenantId: $tenantId', 'applicationId: $applicationId', 'secret: $secret' " }  
#  Write-Host "Auth token by GetAuthTokenInvokingRestApi :"  
#  Write-Host $authToken -ForegroundColor Yellow  
#  #When we run above powerhsell script we can get auth tokens as below  

######### ACCESS TOKEN FROM POST MAN ########################
 $authToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6ImpTMVhvMU9XRGpfNTJ2YndHTmd2UU8yVnpNYyIsImtpZCI6ImpTMVhvMU9XRGpfNTJ2YndHTmd2UU8yVnpNYyJ9.eyJhdWQiOiJodHRwczovL21hbmFnZW1lbnQuYXp1cmUuY29tLyIsImlzcyI6Imh0dHBzOi8vc3RzLndpbmRvd3MubmV0L2UxMGRkZWI2LWFmOTgtNDc2Mi1hNmE2LWE2Y2FmMjNmMmJhMS8iLCJpYXQiOjE2NDgxNzIwMjksIm5iZiI6MTY0ODE3MjAyOSwiZXhwIjoxNjQ4MTc1OTI5LCJhaW8iOiJFMlpnWUVnd1k1UDFXcjdNZm1MQkxJa1pGNlF6QVE9PSIsImFwcGlkIjoiNDViMTliODgtNjExZC00MTY2LWIzNDUtNjZmZjg5YzI1NDAzIiwiYXBwaWRhY3IiOiIxIiwiaWRwIjoiaHR0cHM6Ly9zdHMud2luZG93cy5uZXQvZTEwZGRlYjYtYWY5OC00NzYyLWE2YTYtYTZjYWYyM2YyYmExLyIsImlkdHlwIjoiYXBwIiwib2lkIjoiMGFjZGM5OTQtMTc3Yi00MWUwLWIxNDAtYWUwYjIxODZhZDQwIiwicmgiOiIwLkFVWUF0dDRONFppdllrZW1wcWJLOGo4cm9VWklmM2tBdXRkUHVrUGF3ZmoyTUJPQUFBQS4iLCJzdWIiOiIwYWNkYzk5NC0xNzdiLTQxZTAtYjE0MC1hZTBiMjE4NmFkNDAiLCJ0aWQiOiJlMTBkZGViNi1hZjk4LTQ3NjItYTZhNi1hNmNhZjIzZjJiYTEiLCJ1dGkiOiIxclhBNTBCRFJrZUZsdE01TEFWSkFBIiwidmVyIjoiMS4wIiwieG1zX3RjZHQiOjE2NDE4Njc5NzJ9.mLSVx6kIoo0uQQnYsxPJ4ktPGG2RWv56oD3UrF2W5UudNcImTODwwo2VskMxOSNfzJDYDKit_V0tZ-nE-n0ITUXwq4S9xlvIU33lZ_nK1yxDrwieRbuDWw6psYbDZn3qLU03H6ydSt5EgBnCDFbhooBJthYJOJo42ICodw7ReAs1SLWUbt6VYPhK-JexHjoK9PF7wgfEEjcC_04O0iGh1pxqpGMmGKX2itxD_VdAtHvHDlNNyI-OwYzd7Mluv1oijjhUUi3WmFFtZW7NgPhEBJsJxsm8l292fqX-cqhXTEcTNZsk1p3-eI1VHa5wGuAsB6cJSceA8uC0hrAQfsi8wQ"
######################## Create Auth Header#####################
$authHeader = @{
    "Content-Type" = "application/json"
    "Authorization"= "Bearer " + $authToken
    }


 #Loop through each reasource group and get all resources.
#Add everything to a hash table
$Subs = Get-AzSubscription
$Subresources = @()

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
    $resources = @{}
    $resources.Add($rg, $res)
####################################################################  Resource Health #################

$resourceGroupHealth = @{}
#foreach ($ResourceGroup in $ResourceGroups) {
    
    #Set resource group name and use it in our url
    $health = Invoke-RestMethod –Uri "https://management.azure.com/subscriptions/$Sub/resourceGroups/$rg/Providers/Microsoft.ResourceHealth/availabilityStatuses?api-version=2015-01-01" –Method GET –Headers $authHeader

    $currentHealth = @{}
    $currentHealth = @{
        [string]"$ResourceGroup" = [object]$health
    }

    
    #Add all resource groups and their resources to a hash table
    $Subresources += $resources

    $resourceGroupHealth += $currentHealth

    # Display Health Data for Azure resources in selected subscription
    #$resourcestest = @() 
     $health.value | 
        Select-Object `
           @{n='subscriptionId';e={$_.id.Split("/")[2]}},
           location,
           @{n='resourceGroup';e={$_.id.Split("/")[4]}},
           @{n='resource';e={$_.id.Split("/")[8]}},
           @{n='status';e={$_.properties.availabilityState}}, # ie., Available or Unavailable
           @{n='summary';e={$_.properties.summary}},
           @{n='reason';e={$_.properties.reasonType}},
           @{n='occuredTime';e={$_.properties.occuredTime}},
           @{n='reportedTime';e={$_.properties.reportedTime}} |
           Format-List 
           #| Export-Csv -Force -Path ".\AMS_ResourceHealth3-$(get-date -f yyyy-MM-dd-HHmm).csv"
    ##################################################################
    # $item = [PSCustomObject]@{
    #     subscriptionId = {$_.id.Split("/")[2]}},
    #     location
    #     resourceGroup = $diag.name
    #     StorageAccountName =  $StorageAccountName
    #     EventHubName =  $EventHubName
    #     WorkspaceName =  $WorkspaceName
    #     # Extracting delatied porerties into string format.
    #     Metrics = ($diag.Metrics | ConvertTo-Json -Compress | Out-String).Trim()
    #     Logs =  ($diag.Logs | ConvertTo-Json -Compress | Out-String).Trim()
    #     Subscription = $Sub.Name
    #     ResourceId = $resId
    #     DiagnosticSettingsId = $diag.Id
    #     StorageAccountId =  $StorageAccountId
    #     EventHubId =  $EventHubId
    #     WorkspaceId = $WorkspaceId
    # }
    # Write-Host $item
    # # Add PS Object to array
    # $Results += $item
    ####################################################################
     
    #$Subresources += $item
        
   }

  }
# Save Resource Health Availability to CSV as tabular data
#$resourceGroupHealth | Export-Csv -Force -Path ".\AMS_ResourceHealth-$(get-date -f yyyy-MM-dd-HHmm).csv"
#$item | Export-Csv -Force -Path ".\AMS_ResourceHealth2-$(get-date -f yyyy-MM-dd-HHmm).csv"
#$Subresources | Export-Csv -Force -Path ".\AMS_ResourceHealth3-$(get-date -f yyyy-MM-dd-HHmm).csv"

##########################################
#Store all results for resource in PS Object
# $item = [PSCustomObject]@{
#     ResourceName = $res.name
#     DiagnosticSettingsName = $diag.name
#     StorageAccountName =  $StorageAccountName
#     EventHubName =  $EventHubName
#     WorkspaceName =  $WorkspaceName
#     # Extracting delatied porerties into string format.
#     Metrics = ($diag.Metrics | ConvertTo-Json -Compress | Out-String).Trim()
#     Logs =  ($diag.Logs | ConvertTo-Json -Compress | Out-String).Trim()
#     Subscription = $Sub.Name
#     ResourceId = $resId
#     DiagnosticSettingsId = $diag.Id
#     StorageAccountId =  $StorageAccountId
#     EventHubId =  $EventHubId
#     WorkspaceId = $WorkspaceId
# }
# Write-Host $item
# # Add PS Object to array
# $Results += $item


##############################################
# Set initial URI for calling Resource Health REST API

# $uri = "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.ResourceHealth/availabilityStatuses?api-version=$apiVersion"

# # Call Resource Health REST API

#     $healthData = Invoke-RestMethod `
#         -Uri $Uri `
#         -Method Get `
#         -Headers $requestHeader `
#         -ContentType $contentType

# Display Health Data for Azure resources in selected subscription

    # $healthData.value | 
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
    #     Format-List