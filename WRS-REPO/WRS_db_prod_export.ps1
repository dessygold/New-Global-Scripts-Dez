<#
    .SYNOPSIS
       Using Azure Pipelines to restore a production database to another environment.
    .DESCRIPTION
       PowerShell task to run a script and pass it the information for the production environment.
       This runs against the production environment and creates a blog storage container that holds the exported BACPAC

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
#This function generate auth token using REST api  

###################################################################################################################
################################ Universal Variables For this Deployment ##########################################
$keyvaultname    = "kv-it-inf-aad-002"
$spDisplayName   = "pra-resourse-health"
$spkvSecretName  = "pra-resource-health"
$tenantid        = "60a5b34b-c976-4591-a955-f65531bb4d4b" 
$subscriptionid  = "50664444-1a76-4154-b346-a3702c8b7b47"
$environment     = "AzureCloud"

##################################### Login To Azure Subscription ##################################################
Clear-AzContext -Force
Set-AzContext -Tenant $TenantId -Subscription $subscriptionID
Write-Host  "checking context ................."
Connect-AzAccount -Environment $environment -TenantId $TenantId -Subscription $subscriptionID

######################### Get App ID and Secret #####################################################################
$spn_clientid     = (Get-AzADApplication -DisplayName $spDisplayName).AppId
$spn_secret       = Get-AzKeyVaultSecret -VaultName $keyvaultname  -Name $spkvSecretName -AsPlainText

$spn_clientid 

###############################################################################################################
<# 
Export the production database to blog container
#>
[CmdletBinding()]
param (
    [string] $tenantid,
    [string] $subscriptionid,
    [string] $spn_clientid,
    [string] $spn_secret
)

Write-Host "Variable"  '$tenantid    = '
Write-Host "variables" '$subscriptionid   = '
Write-Host "Variable"  '$keyvaultname    = kv-it-inf-aad-002'
Write-Host "variables" '$spDisplayName   = pra-resourse-health'
Write-Host "variables"  '$spkvSecretName = pra-resource-health'
Write-Host "************************************************"
$environment        = "PRD";
$backups            = 'backups'
$ResourceGroup_Prod = "rg-wrs072-prod-azsqlsrv"
$location1          = "West US 2"
$sqlserver_Prod     = "sql-rain-prod".ToLower()
$keyvaultname       = "au-demo-$environment-1".ToLower()   
$sqladmin           = az keyvault secret show --name 'sqladmin' --vault-name $keyvaultname --query 'value' 
$sqlpassword        = az keyvault secret show --name 'sqlpassword' --vault-name $keyvaultname --query 'value'  
$filename           = "demo_PRD_$(Get-Date -Format "yyyy-MM-dd").bacpac"
$bloburi            = "https://backups.blob.core.windows.net/bacpac/$filename" 

### PRODUCTION
Write-Host "************************************************"
Write-Host "login via SPN which is locked down to production subscription"
Write-Host "************************************************"
az login --service-principal --username $spn_clientid --password $spn_secret --tenant $tenantid 

Write-Host "************************************************"
Write-Host "create blog storage with container called bacpac"
Write-Host "************************************************"
az storage account create -n $backups -g $ResourceGroup_Prod -l $location1 --sku Standard_LRS
$keyvalue = az storage account keys list -g $ResourceGroup_Prod -n $backups --subscription $subscriptionid --query '[0].value' -o json
az storage container create -n bacpac --account-name $backups --account-key $keyvalue --auth-mode key
az storage container policy create --container-name bacpac --name ReadWrite --account-key ""$keyvalue"" --account-name $backups --auth-mode key --permissions rwdl
Write-Host "************************************************"
Write-Host "export bacpac from production to blob container"
Write-Host "************************************************"

az sql db export -s $sqlserver_Prod -n 'AUAZE-PRD-demo-DB1' -g $ResourceGroup_Prod -p $sqlpassword -u $sqladmin --storage-uri $bloburi --storage-key-type "StorageAccessKey" --storage-key "$keyvalue"   