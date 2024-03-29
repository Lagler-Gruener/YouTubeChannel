# Parameter help description
param ([Parameter(Mandatory=$true)]
[string]
$Log
)

$tenantId = ""
$appId = ""
$appSecret = ""
$DcrImmutableId = ""
$DCEURI = ""
$Table = "CT_DCR_Test_CL"


$file_data = Get-Content $Log   

    ## Obtain a bearer token used to authenticate against the data collection endpoint
    $scope = [System.Web.HttpUtility]::UrlEncode("https://monitor.azure.com//.default")   
    $body = "client_id=$appId&scope=$scope&client_secret=$appSecret&grant_type=client_credentials";
    $headers = @{"Content-Type" = "application/x-www-form-urlencoded" };
    $uri = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
    $bearerToken = (Invoke-RestMethod -Uri $uri -Method "Post" -Body $body -Headers $headers).access_token

    #Write-Output $bearerToken

    ## Generate and send some data
    foreach ($line in $file_data) {

        # We are going to send log entries one by one with a small delay
        $log_entry = @{
            # Define the structure of log entry, as it will be sent
            Time = Get-Date ([datetime]::UtcNow) -Format O
            Application = "TestApp"
            RawData = "$line"
        }

        # Sending the data to Log Analytics via the DCR!
        $body = $log_entry | ConvertTo-Json -AsArray;
        $headers = @{"Authorization" = "Bearer $bearerToken"; "Content-Type" = "application/json" };
        $uri = "$DceURI/dataCollectionRules/$DcrImmutableId/streams/Custom-$Table"+"?api-version=2021-11-01-preview";

        $uploadResponse = Invoke-RestMethod -Uri $uri -Method "Post" -Body $body -Headers $headers;

        # Let's see how the response looks
        Write-Output $uploadResponse
        if($uploadResponse -eq "")
        {
            Write-Output "Upload data $line : successful"
        }
        Write-Output "---------------------"

        # Pausing for 1 second before processing the next entry
        Start-Sleep -Seconds 1
    }