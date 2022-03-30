###################################################################################################################
################################ Universal Variables For this Deployment ##########################################
$kvName        = "goldsafekeyvault"
$spDisplayName = "goldapp2022"
$spSecretName  = "goldspsecret"
$TenantId = "e10ddeb6-af98-4762-a6a6-a6caf23f2ba1" 
$subscriptionID = "c93020ea-c4db-48ab-a06f-058949354bab"
$environment    = "AzureCloud"


##################################### Login To Azure Subscription ##################################################
Clear-AzContext -Force
Set-AzContext -Tenant $TenantId -Subscription $subscriptionID
Write-Host  "checking context ................."
Connect-AzAccount -Environment $environment -TenantId $TenantId -Subscription $subscriptionID


$ClientID     = (Get-AzADApplication -DisplayName $spDisplayName).AppId
#$ClientSecret = (Get-AzKeyVaultSecret -VaultName $kvName -Name $spSecretName).SecretValueText
$ClientSecret = Get-AzKeyVaultSecret -VaultName $kvName -Name $spSecretName

$ClientID
$ClientSecret