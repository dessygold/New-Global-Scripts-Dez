$TenantId = "60a5b34b-c976-4591-a955-f65531bb4d4b" 
$subscriptionID = "3ed787a6-c475-45af-be22-058195388d44"
$environment    = "AzureCloud"

##################################### Login To Azure Subscription ##################################################
Clear-AzContext -Force
Set-AzContext -Tenant $TenantId -Subscription $subscriptionID
Write-Host  "checking context ................."
Connect-AzAccount -Environment $environment -TenantId $TenantId -Subscription $subscriptionID

# [CmdletBinding()]
# param(
#   $subscriptionId,
#   $subscriptionName,
#   $skip
# )

$reportPath = "./quarterly-review/QRreports/new_App-registrations.csv"
$reportPath2 = "./quarterly-review/QRreports/expired_App-registrations.csv"
$reportPath3 = "./quarterly-review/QRreports/stale_App-registrations.csv"

function UpdateCSV($item) {
    Add-Content -Force -Path $reportPath -Value "$($item.SubscriptionName),$($item.DisplayName),$($item.ObjectId),$($item.Type),$($item.Created),$($item.EndDate)"
}
function UpdateCSV2($item2) {
    Add-Content -Force -Path $reportPath2 -Value "$($item2.SubscriptionName),$($item2.DisplayName),$($item2.ObjectId),$($item2.Type),$($item2.Created),$($item2.EndDate)"
}
function UpdateCSV3($item3) {
    Add-Content -Path $reportPath3 -Value "$($item3.SubscriptionName),$($item3.DisplayName),$($item3.ObjectId),$($item3.Type),$($item3.Created),$($item3.EndDate)"
}


$date = (get-date).ToString('yyyy-MM-dd HH:mm:ss')
$date2 = (get-date).AddYears(50).ToString('yyyy-MM-dd HH:mm:ss')

$adApps = @()
$adApps = Get-AzADApplication
foreach ($adApp in $adApps){
    $appCredentials = @()
    $appCredentials = Get-AzADAppCredential -ObjectId $adApp.Id 
    If($appCredentials){
        foreach($appCredential in $appCredentials | Where-Object { $_.EndDateTime -ge $date2}){
            Write-Output "$($adApp.DisplayName) $($adApp.ObjectId) $($appCredential.Type) created on $($appCredential.StartDateTime) expires on $($appCredential.EndDateTime)"
            updateCSV @{
                "SubscriptionName" = $sub
                "DisplayName" = $adApp.DisplayName
                "ObjectId" = $adApp.Id
                "Type" = $appCredential.Type
                "Created" = $appCredential.StartDateTime
                "EndDate" = $appCredential.EndDateTime
            }
        }
        foreach($appCredential in $appCredentials | Where-Object { $_.EndDateTime -le $date}){
            Write-Output "$($adApp.DisplayName) $($adApp.Id) $($appCredential.Type) created on $($appCredential.StartDateTime) expires on $($appCredential.EndDateTime)"
            updateCSV2 @{
                "SubscriptionName" = $sub
                "DisplayName" = $adApp.DisplayName
                "ObjectId" = $adApp.Id
                "Type" = $appCredential.Type
                "Created" = $appCredential.StartDateTime
                "EndDate" = $appCredential.EndDateTime
            }
        }
    }
    Else{
        Write-Output "$($adApp.DisplayName) has no certificates or secret credentials"
        updateCSV3 @{
            "SubscriptionName" = $sub
            "DisplayName" = $adApp.DisplayName
            "ObjectId" = $adApp.Id
            "Type" = "No Cert or Secrets Found"
            "Created" = "None"
            "EndDate" = "None"
        }
    }
}
