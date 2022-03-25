#########################################################################################################################################################################
#########################    Script to Loop through US Bank Azure Subscription and Check resource Diagnostic settings  ##################################################
#########################################################################################################################################################################
<#
.SYNOPSIS
    Get all Azure Diagnostics settings for Azure Resources in US Bank Subscriptions
.DESCRIPTION
    Script cycles through all Subscriptions available to account, and checks every resource for Diagnostic Settings configuration.
    All configuration details are stored in an array ($DiagResults) as well as exported to a CSV in the current running directory.
.NOTES
    Desmond Osatuyi | 2022-03-22 | 
#>
# Install and login with Connect-AzAccount and skip when using Azure Cloud Shell
If ($null -eq (Get-Command -Name Get-CloudDrive -ErrorAction SilentlyContinue)) {
    If ($null -eq (Get-Module Az -ListAvailable -ErrorAction SilentlyContinue)){
        Write-Host "Installing Az module from default repository"
        Install-Module -Name Az -AllowClobber -Scope CurrentUser
    }
    Write-Host "Importing Az"
    Import-Module -Name Az
    Write-Host "Connecting to Az"
    Connect-AzAccount
}

<#
Get all active Azure subscriptions and exclude those leftover from Azure Service Manager.
#>

Write-Host "Getting  Azure subscriptions ."

# Get all Azure Subscriptions


#$ExcludedSubscriptions = @('Access to Azure Active Directory')

$Subs = Get-AzSubscription 

# Set array
$Results = @()
# Loop through all Azure Subscriptions
foreach ($Sub in $Subs) {
    Set-AzContext $Sub.id | Out-Null
    Write-Host "Processing Subscription:" $($Sub).name
    # Get all Azure resources for current subscription
    $Resources = Get-AZResource
    # Get all Azure resources which have Diagnostic settings enabled and configured
    foreach ($res in $Resources) {
        $resId = $res.ResourceId
        $DiagSettings = Get-AzDiagnosticSetting -ResourceId $resId -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | Where-Object { $_.Id -ne $null }
        foreach ($diag in $DiagSettings) {
            If ($diag.StorageAccountId) {
                [string]$StorageAccountId= $diag.StorageAccountId
                [string]$storageAccountName = $StorageAccountId.Split('/')[-1]
            }
            If ($diag.EventHubAuthorizationRuleId) {
                [string]$EventHubId = $diag.EventHubAuthorizationRuleId
                [string]$EventHubName = $EventHubId.Split('/')[-3]
            }
            If ($diag.WorkspaceId) {
                [string]$WorkspaceId = $diag.WorkspaceId
                [string]$WorkspaceName = $WorkspaceId.Split('/')[-1]
            }
            # Store all results for resource in PS Object
            $item = [PSCustomObject]@{
                ResourceName = $res.name
                DiagnosticSettingsName = $diag.name
                StorageAccountName =  $StorageAccountName
                EventHubName =  $EventHubName
                WorkspaceName =  $WorkspaceName
                # Extracting delatied porerties into string format.
                Metrics = ($diag.Metrics | ConvertTo-Json -Compress | Out-String).Trim()
                Logs =  ($diag.Logs | ConvertTo-Json -Compress | Out-String).Trim()
                Subscription = $Sub.Name
                ResourceId = $resId
                DiagnosticSettingsId = $diag.Id
                StorageAccountId =  $StorageAccountId
                EventHubId =  $EventHubId
                WorkspaceId = $WorkspaceId
            }
            Write-Host $item
            # Add PS Object to array
            $Results += $item
        }
    }
    
}
# Save Diagnostic settings to CSV as tabular data
$Results | Export-Csv -Force -Path ".\USBank_AzureResourceDiagnosticSettings-$(get-date -f yyyy-MM-dd-HHmm).csv"
Write-Host 'The array $DiagResults can be used to further refine results within session.'
Write-Host 'eg. $DiagResults | Where-Object {$_.WorkspaceName -like "LAW-LOGS01"}'
