[CmdletBinding()]
param(
  $subscriptionId,
  $subscriptionName,
  $skip
)

$reportPath = "./quarterly-review/QRreports/new_App-registrations.csv"
$reportPath2 = "./quarterly-review/QRreports/expired_App-registrations.csv"
$reportPath3 = "./quarterly-review/QRreports/stale_App-registrations.csv"

function UpdateCSV($item) {
    Add-Content -Path $reportPath -Value "$($item.SubscriptionName),$($item.DisplayName),$($item.ObjectId),$($item.Type),$($item.Created),$($item.EndDate)"
}
function UpdateCSV2($item2) {
    Add-Content -Path $reportPath2 -Value "$($item2.SubscriptionName),$($item2.DisplayName),$($item2.ObjectId),$($item2.Type),$($item2.Created),$($item2.EndDate)"
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
    $appCredentials = Get-AzADAppCredential -ObjectId $adApp.ObjectId 
    If($appCredentials){
        foreach($appCredential in $appCredentials | Where-Object { $_.EndDateTime -ge $date2}){
            Write-Output "$($adApp.DisplayName) $($adApp.ObjectId) $($appCredential.Type) created on $($appCredential.StartDate) expires on $($appCredential.EndDate)"
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
            Write-Output "$($adApp.DisplayName) $($adApp.Id) $($appCredential.Type) created on $($appCredential.StartDate) expires on $($appCredential.EndDate)"
            updateCSV2 @{
                "SubscriptionName" = $sub
                "DisplayName" = $adApp.DisplayName
                "ObjectId" = $adApp.ObjectId
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
            "ObjectId" = $adApp.ObjectId
            "Type" = "No Cert or Secrets Found"
            "Created" = "None"
            "EndDate" = "None"
        }
    }
}
