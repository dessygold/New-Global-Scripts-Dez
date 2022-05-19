<#
    .SYNOPSIS
       This let’s us get health state (availability status) on all Azure resources looping through all subscriptions and resource group.
    .DESCRIPTION
       Resource health helps you diagnose and get support when an Azure issue impacts your resources.
       It informs you about the current and past health of your resources and helps you mitigate issues.
       Resource health provides technical support when you need help with Azure service issues.

    .PARAMETER ClientID
        Azure AD application ID
        This will require API Permission ()
        Also will require a read access to all subscription to grab metrics from

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
$kvName          = "kv-it-inf-aad-002"
$spDisplayName   = "pra-resourse-health"
$spkvSecretName  = "pra-resource-health"
$TenantId        = "60a5b34b-c976-4591-a955-f65531bb4d4b" 
#$subscriptionID  = "50664444-1a76-4154-b346-a3702c8b7b47"
$subscriptionID  = "3ed787a6-c475-45af-be22-058195388d44"
$environment     = "AzureCloud"

##################################### Login To Azure Subscription ##################################################
#Clear-AzContext -Force
#Set-AzContext -Tenant $TenantId -Subscription $subscriptionID
#Write-Host  "checking context ................."
#Connect-AzAccount -Environment $environment -TenantId $TenantId -Subscription $subscriptionID
#Connect-AzAccount
################################################################ Log in with Runsas/Identity ################
$automationAccount = "pra-resource-health-test"
$SystemIdentity     = "38606faf-4cc3-418f-b3c9-fb3edea9f221"


# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process | Out-Null

# Connect using a Managed Service Identity
try {
        $AzureContext = (Connect-AzAccount -Identity).context
		#$AzureContext = (Connect-AzAccount -Identity -AccountId $identity.ClientId).context
        $AzureContext = Set-AzContext -Subscription $subscriptionID -DefaultProfile $AzureContext
    }
catch{
        Write-Output "There is no system-assigned user identity. Aborting."; 
        exit
    }


######################### Get App ID and Secret #####################################################################
#$ClientID     = (Get-AzADApplication -DisplayName $spDisplayName).AppId
$ClientID = "b4937906-3e60-4e48-b4d6-7fe048239f59"
$ClientSecret = Get-AzKeyVaultSecret -VaultName $kvName -Name $spkvSecretName -AsPlainText

Write-Output "ClientID"=$ClientID
Write-Output "ClientSecret"=$ClientSecret

############### Generate an authentication token to use against Azure management Rest API’s ##############################
$TokenEndpoint = {https://login.windows.net/{0}/oauth2/token} -f $TenantId 
$resourceURL = "https://management.core.windows.net/";
Write-Output "get body"
$Body = @{
        'resource'= $resourceURL
        'client_id' = $ClientID
        'grant_type' = 'client_credentials'
        'client_secret' = $ClientSecret
}
Write-Output "get param"
$params = @{
    ContentType = 'application/x-www-form-urlencoded'
    Headers = @{'accept'='application/json'}
    Body = $Body
    Method = 'Post'
    URI = $TokenEndpoint
}

$authToken = Invoke-RestMethod @params

Write-Output "authToken"=$authToken


######################## Create Auth Header with the Generated Auth Token ###########################################################
Write-Output "get authheader"
$authHeader = @{
    "Content-Type" = "application/json"
    "Authorization"= "Bearer " + $authToken.access_token
    }

 ##########################  Loop through All Azure Subscription and get all resources using Graph API #######################
############################# Add everything to a hash table ###############################################################
$Subs = Get-AzSubscription
Write-Output $Subs

$allHealths = @()
Write-Output "GET SUB"
foreach ($Sub in $Subs) {
	#$Subid = $Sub

	Set-AzContext -Subscription $Sub.Id -DefaultProfile $AzureContext | Out-Null
    #Set-AzContext $Sub.id | Out-Null
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
$ExportPath = ".\PRA_ResourceHealth-$(get-date -f yyyy-MM-dd-HHmm).csv"
$allHealths | Export-Csv -Force -Path $ExportPath
Write-Host "CSV File has been exported to $ExportPath" -ForegroundColor Green

$StorageAccount = Get-AzStorageAccount -ResourceGroupName "TEST-AUTH-RG" -Name "resourcehealthstore01" 
$Context = $StorageAccount.Context
# upload a file to the default account (inferred) access tier
$Blob1HT = @{
  File             = ".\PRA_ResourceHealth-$(get-date -f yyyy-MM-dd-HHmm).csv"
  Container        = "resource-health-container"
  Blob             = "PRA_ResourceHealth-$(get-date -f yyyy-MM-dd-HHmm).csv"
  Context          = $Context
  StandardBlobTier = 'Hot'
}
Set-AzStorageBlobContent @Blob1HT