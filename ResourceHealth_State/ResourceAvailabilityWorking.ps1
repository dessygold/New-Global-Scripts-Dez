<#
    .SYNOPSIS
       This let’s us get health state (availability status) on all resources looping through all subscriptions and resource group.
    .DESCRIPTION
       Resource health helps you diagnose and get support when an Azure issue impacts your resources.
       It informs you about the current and past health of your resources and helps you mitigate issues.
       Resource health provides technical support when you need help with Azure service issues.

    .PARAMETER ClientID
        Azure AD application ID

    .PARAMETER ClientSecret
        Azure AD application secret.

    .PARAMETER TenantId
        Azure tenant ID
      
    .PARAMETER AuthToken
       Generate an authentication token to use against Azure management Rest API’s
          
    .PARAMETER ResourceName
        List/Name of all resources in Azure subscription
                 
    .NOTES
        v1.0
        Desmond Osatuyi 2022
    #>
    
###################################  Get Azure AD application token FROM POST MAN #####################################################

$authToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6ImpTMVhvMU9XRGpfNTJ2YndHTmd2UU8yVnpNYyIsImtpZCI6ImpTMVhvMU9XRGpfNTJ2YndHTmd2UU8yVnpNYyJ9.eyJhdWQiOiJodHRwczovL21hbmFnZW1lbnQuYXp1cmUuY29tLyIsImlzcyI6Imh0dHBzOi8vc3RzLndpbmRvd3MubmV0L2UxMGRkZWI2LWFmOTgtNDc2Mi1hNmE2LWE2Y2FmMjNmMmJhMS8iLCJpYXQiOjE2NDg1ODc4ODMsIm5iZiI6MTY0ODU4Nzg4MywiZXhwIjoxNjQ4NTkxNzgzLCJhaW8iOiJFMlpnWUpnWXNmQnE5VDJyVlc3WHU4Ui8zTnFnQlFBPSIsImFwcGlkIjoiNDViMTliODgtNjExZC00MTY2LWIzNDUtNjZmZjg5YzI1NDAzIiwiYXBwaWRhY3IiOiIxIiwiaWRwIjoiaHR0cHM6Ly9zdHMud2luZG93cy5uZXQvZTEwZGRlYjYtYWY5OC00NzYyLWE2YTYtYTZjYWYyM2YyYmExLyIsImlkdHlwIjoiYXBwIiwib2lkIjoiMGFjZGM5OTQtMTc3Yi00MWUwLWIxNDAtYWUwYjIxODZhZDQwIiwicmgiOiIwLkFVWUF0dDRONFppdllrZW1wcWJLOGo4cm9VWklmM2tBdXRkUHVrUGF3ZmoyTUJPQUFBQS4iLCJzdWIiOiIwYWNkYzk5NC0xNzdiLTQxZTAtYjE0MC1hZTBiMjE4NmFkNDAiLCJ0aWQiOiJlMTBkZGViNi1hZjk4LTQ3NjItYTZhNi1hNmNhZjIzZjJiYTEiLCJ1dGkiOiJzYk1LYlBCOE8wcTM3WlR0VktaVEFBIiwidmVyIjoiMS4wIiwieG1zX3RjZHQiOjE2NDE4Njc5NzJ9.KicIfZQouccR3yKaf0Pohwdkf7zVpPvkS44-XFod54xtZ8GBxgWh6adSoRS9gQP1u_CyX3gPmvt92ckGoVk0HQYVUscdtm7-DLUxr657u57G4UMw0zqUoEuB0_wgm9XZmGvpAs_xQIjg5VmQboswHADJc6msjR_htJXcAZLA4E5pAJ_Mb0y9tseEy5r7Lqx2jQ79MyMH3sFbtMdlfu6loKWXoV8u1nd-XnAbYC-EcApQphRHhEOLkxdwW6WQo0prMi42EFXiOwFSv9o0fzFZYDbYB519aX5jBxB3ZYjcjKe-q5E1io6W8WNJQfgeqh0ELzJV4hChzQy43u-kQN1E1w"

######################## Create Auth Header with the Generated Auth Token###########################################################

$authHeader = @{
    "Content-Type" = "application/json"
    "Authorization"= "Bearer " + $authToken
    }


 #Loop through each reasource group and get all resources.
#Add everything to a hash table
$Subs = Get-AzSubscription
$Subresources = @()
$allHealths = @()
foreach ($Sub in $Subs) {
    Set-AzContext $Sub.id | Out-Null
    Write-Host "Processing Subscription:" $($Sub).name

    $APIVersion = "2022-01-01"
    $RGURI = "https://management.azure.com/subscriptions/$Sub/resourcegroups?api-version=$APIVersion"

    $ResourceGroups = (Invoke-RestMethod –Uri $RGURI –Method GET –Headers $authHeader).value.name

    $resources = @{} ## add all Resources in a particular resource group
    # Get all Azure resources for current subscription
    foreach ($rg in $ResourceGroups) {
        $ResourceGroupUri = "https://management.azure.com/subscriptions/$Sub/resourceGroups/$rg/resources?api-version=$APIVersion"
        $res = (Invoke-RestMethod –Uri $ResourceGroupUri –Method GET –Headers $authHeader).value

        #Create array of all resources
        
        $resources.Add($rg, $res)
        ####################################################################  Resource Health #################
        
        #Set resource group name and use it in our url
        $health = Invoke-RestMethod –Uri "https://management.azure.com/subscriptions/$Sub/resourceGroups/$rg/Providers/Microsoft.ResourceHealth/availabilityStatuses?api-version=2015-01-01" –Method GET –Headers $authHeader

        $healths = $health.value | 
            Select-Object `
            @{n='subscriptionId';e={$_.id.Split("/")[2]}},
            location,
            @{n='resourceGroup';e={$_.id.Split("/")[4]}},
            @{n='resource';e={$_.id.Split("/")[8]}},
            @{n='status';e={$_.properties.availabilityState}}, # ie., Available or Unavailable
            @{n='summary';e={$_.properties.summary}},
            @{n='reason';e={$_.properties.reasonType}},
            @{n='occuredTime';e={$_.properties.occuredTime}},
            @{n='reportedTime';e={$_.properties.reportedTime}}
        
        foreach ($health in $healths) { 
            $allHealths += $health
        }
    }
 }       

$allHealths | Export-Csv -Force -Path ".\AMS_ResourceHealth-$(get-date -f yyyy-MM-dd-HHmm).csv"