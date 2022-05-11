<#
    .SYNOPSIS
       Using Azure Pipelines to restore a production database to another environment.
    .DESCRIPTION
       PowerShell task to run a script and pass it the information for the production environment.
       This runs against the production environment and imports the bacpac stored in a blog storage container that holds the exported BACPAC

    .PARAMETER ClientID
        Azure AD application ID

    .PARAMETER ClientSecret
        Azure AD application secret.

    .PARAMETER TenantId
        Azure tenant ID
      
    .PARAMETER Subscription
       Production Environment Subscription
          
    .PARAMETER sqlserver_prod
        Name of Production Environment SQL Server to be exported.
                 
    .NOTES
        v1.0
        Desmond Osatuyi 2022
    #>
# 
###############################################################################################################
<# 
Export the production database to blog container
#>
[CmdletBinding()]
param (
    [string] $environment, # to environment
    [string] $tenantid,
    [string] $production_subscriptionid,
    [string] $production_spn_clientid,
    [string] $production_spn_secret,
    [string] $dev_subscriptionid,
    [string] $dev_spn_clientid,
    [string] $dev_spn_secret,
    [string] $skuname
)

###################################################################################################################
################################ Universal Variables For this Deployment ##########################################
$keyvaultname    = "kv-it-inf-aad-002"
$spDisplayName   = "pra-resourse-health"
$spkvSecretName  = "pra-resource-health"
$tenantid        = "60a5b34b-c976-4591-a955-f65531bb4d4b" 
$dev_subscriptionid  = "50664444-1a76-4154-b346-a3702c8b7b47"
$environment     = "AzureCloud"
####################
$environment        = "PRD";
$backups            = 'backups'
$storageKeyType     = "StorageAccessKey"
$ResourceGroup_Prod = "rg-wrs072-prod-azsqlsrv"
$location1          = "West US 2"
$sqlserver_Prod     = "sql-rain-prod".ToLower()
$sqlDatabase_Prod   = ""
$keyvaultname       = "au-demo-$environment-1".ToLower()    
$filename           = "WRS_PRD_$(Get-Date -Format "yyyy-MM-dd").bacpac"
$bloburi            = "https://backups.blob.core.windows.net/bacpac/$filename" 

################################ Variables pulled From Azure Keyvault for this Deployment ##########################################
$sqladmin           = az keyvault secret show --name 'sqladmin' --vault-name $keyvaultname --query 'value' 
$sqlpassword        = az keyvault secret show --name 'sqlpassword' --vault-name $keyvaultname --query 'value'  
$dev_spn_secret     = az keyvault secret show --name 'spn_secret_name' --vault-name $keyvaultname --query 'value' 

##################################### Login To Azure Subscription via Service Principal to Prod, get container key ##################################################
az account clear
Write-Host  "clearing all subscriptions from the CLI's local cache  ................."
Write-Host "login via spn to production and get the container key"
Write-Host "************************************************"
az login --service-principal --username $production_spn_clientid --password $production_spn_secret --tenant $tenantid
$keyvalue = az storage account keys list -g $production_resourcegroup1 -n $backups --subscription $production_subscriptionid --query '[0].value' -o json
az logout --username $production_spn_clientid 
Write-Host  "logging out of prod subscription $production_subscriptionid  . ................."

##################################### Login To Azure Subscription via Service Principal to dev or uat ##################################################
az account clear
Write-Host  "clearing all subscriptions from the CLI's local cache  ................."
Write-Host "login via spn to dev or uat"
Write-Host "************************************************"
az login --service-principal --username $spn_clientid --password $spn_secret --tenant $tenantid
az account set --subscription $dev_subscriptionid
Write-Host  "Setting $dev_subscriptionid  to be the current active subscription. ................."




##################################### Output all Defined Variables ##################################################
Write-Host "Variable"  '$tenantid    = '
Write-Host "variables" '$dev_subscriptionid   = '
Write-Host "Variable"  '$keyvaultname    = kv-it-inf-aad-002'
Write-Host "variables" '$spDisplayName   = pra-resourse-health'
Write-Host "variables"  '$spkvSecretName = pra-resource-health'
Write-Host "************************************************"

##################################### Import bacpac from Prod to blob container ##################################################
Write-Host "************************************************"
Write-Host "import bacpac from production to blob container"
Write-Host "************************************************" 
az account set --subscription $dev_subscriptionid
az sql db delete -g $resourcegroup1 -s $sqlserver1 -n "DEMO" --yes
az sql db create -g $resourcegroup1 -s $sqlserver1 -n "DEMO" --service-objective $skuname
az sql db import -s $sqlserver1 -n "DEMO" -g $resourcegroup1 -u $sqladmin -p $sqlpassword  --auth-type SQL --storage-uri $bloburi --storage-key-type "StorageAccessKey" --storage-key "$keyvalue"   
##################################### Export bacpac to Azure Blob Container ##################################################
Write-Host "************************************************"
Write-Host "export bacpac from production to blob container"
Write-Host "************************************************"

az sql db export -s $sqlserver_Prod -n $sqlDatabase_Prod -g $ResourceGroup_Prod -p $sqlpassword -u $sqladmin --storage-uri $bloburi --storage-key-type $storageKeyType --storage-key "$keyvalue"   