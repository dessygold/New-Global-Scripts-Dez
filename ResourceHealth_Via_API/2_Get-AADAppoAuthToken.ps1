<#
    .SYNOPSIS
       Function to connect to the Microsoft login OAuth endpoint and return an OAuth token.
    .DESCRIPTION
        Generate Azure AD oauth token.
       You can specify the resource you want in the paramenter. Default is management.core.windows.net
       Parts of this function is created from these examples: https://docs.microsoft.com/en-us/azure/monitoring-and-diagnostics/monitoring-rest-api-walkthrough

    .PARAMETER ClientID
        Azure AD application ID

    .PARAMETER ClientSecret
        Your application secret.

    .PARAMETER TenantId
        Your tenant domain name. test.onmicrosoft.com

    .PARAMETER ResourceName
        Specify if you are accessing other resources than https://management.core.windows.net
        For example microsoft partner center would have https://api.partnercenter.microsoft.com

    .EXAMPLE
        Get-AADAppoAuthToken -ClientID 'xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' -ClientSecret <application secret> -TenantId "test.no" will return
        token_type     : Bearer
        expires_in     : 3600
        ext_expires_in : 0
        expires_on     : 1505133623
        not_before     : 1505129723
        resource       : https://management.core.windows.net/
        access_token   : eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6IkhIQnlLVS0wRHFBcU1aaDZaRlBkMlZXYU90ZyIsImtpZCI6IkhIQnlLVS0wRHFBcU1aaDZaRlB
                         kMlZXYU90ZyJ9.eyJhdWQiOiJodHRwczovL21hbmFnZW1lbnQuY29yZS53aW5kb3dzLm5ldC8iLCJpc3MiOiJodHRwczovL3N0cy
                 
    .NOTES
        v1.0
        Martin Ehrnst 2017
    #>
    [Cmdletbinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$ClientID,
        [Parameter(Mandatory = $true)]
        [string]$ClientSecret,
        [Parameter(Mandatory = $true)]
        [string]$TenantId,
        [Parameter(Mandatory = $false)]
        [string]$ResourceName = "https://management.core.windows.net/"
    )

    $LoginURL = 'https://login.windows.net'

    #Get application access token
    $Body = @{
        grant_type    = "client_credentials";
        resource      = $ResourceName;
        client_id     = $ClientID;
        client_secret = $ClientSecret
    }

    Return Invoke-RestMethod -Method Post -Uri $LoginURL/$TenantId/oauth2/token -Body $Body
}