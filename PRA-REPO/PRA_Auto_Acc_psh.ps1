$start=get-date
Write-Output "teste azure automation"
try
{
    # Get the connection "AzureRunAsConnection "
    $connection = Get-AutomationConnection -Name AzureRunAsConnection
    $connectionResult = Connect-AzAccount `
    -ServicePrincipal `
    -Tenant $connection.TenantID `
    -ApplicationId $connection.ApplicationID `
    -CertificateThumbprint $connection.CertificateThumbprint
}
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

$subscriptions=Get-AzSubscription

$allresources=foreach ($subscription in ($subscriptions)) {
    Set-AzContext -Subscription $subscription | Out-Null
    Get-AzResource  | Select-Object ResourceName, ResourceGroupName,ResourceType,Id,Location
}

Write-Output "Total azure subscriptions:"
$subscriptions.count
Write-Output "Azure subscriptions names:"
$subscriptions.name
Write-Output "Total azure resources:"
$allresources.count


Write-Output "Exectution time: $((get-date) - $start)"
