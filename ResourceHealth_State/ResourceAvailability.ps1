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
#This function generate auth token using REST api  

###################################################################################################################
################################ Universal Variables For this Deployment ##########################################
$kvName        = "goldsafekeyvault"
$spDisplayName = "goldapp2022"
$spkvSecretName  = "goldspsecret"
$TenantId = "e10ddeb6-af98-4762-a6a6-a6caf23f2ba1" 
$subscriptionID = "c93020ea-c4db-48ab-a06f-058949354bab"
$environment    = "AzureCloud"

##################################### Login To Azure Subscription ##################################################
Clear-AzContext -Force
Set-AzContext -Tenant $TenantId -Subscription $subscriptionID
Write-Host  "checking context ................."
Connect-AzAccount -Environment $environment -TenantId $TenantId -Subscription $subscriptionID

######################### Get App ID and Secret #####################################################################
$ClientID     = (Get-AzADApplication -DisplayName $spDisplayName).AppId
$ClientSecret = Get-AzKeyVaultSecret -VaultName $kvName -Name $spkvSecretName -AsPlainText

$ClientID

############### Generate an authentication token to use against Azure management Rest API’s ##############################
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

$authToken = Invoke-RestMethod @params


######################## Create Auth Header with the Generated Auth Token ###########################################################

$authHeader = @{
    "Content-Type" = "application/json"
    "Authorization"= "Bearer " + $authToken.access_token
    }

 ##########################  Loop through All Azure Subscription and get all resources using Graph API #######################
############################# Add everything to a hash table ###############################################################
$Subs = Get-AzSubscription
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
##################################  Export Result to CSV File ############################################
$allHealths | Export-Csv -Force -Path ".\AMS_ResourceHealth-$(get-date -f yyyy-MM-dd-HHmm).csv"