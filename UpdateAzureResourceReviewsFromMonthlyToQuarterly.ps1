# Install the AzureAD module if not installed
if (-not (Get-Module -Name AzureAD -ErrorAction SilentlyContinue)) {
    Install-Module -Name AzureAD -Force -AllowClobber -Scope CurrentUser
}

# Import the AzureAD module
Import-Module AzureAD
 
# Set the subscription and tenant ID
$subscriptionId = "c3e45a88-6154-44ea-8fbb-99de177d2281"
$tenantId = "72f988bf-86f1-41af-91ab-2d7cd011db47"

# Set the API version
$apiVersion = "2021-12-01-preview"

# Construct the URL
$url = "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.Authorization/accessReviewScheduleDefinitions?api-version=$apiVersion"

# Authenticate to Azure using the Az module
Connect-AzAccount -TenantId $tenantId

# Get the access token
$accessToken = (Get-AzAccessToken -ResourceUrl https://management.azure.com).Token

# Make the GET request
$response = Invoke-RestMethod -Uri $url -Method Get -Headers @{
    Authorization = "Bearer $accessToken"
}

# Process paginated results
do {
    # Make the GET request
    $response = Invoke-RestMethod -Uri $url -Method Get -Headers @{
        Authorization = "Bearer $accessToken"
    }

    # Process the results
    $response.value | ForEach-Object {
        Write-Output "Review Id: $($_.id)"
        Write-Output "Recurrence: $($_.properties.settings.recurrence.pattern.type)"

        if ($_.properties.settings.recurrence.pattern.type -eq "absoluteMonthly" -and $_.properties.settings.recurrence.pattern.interval -eq 1) {
            # Clone the object to avoid modifying the original
            $tmpBody = $_.PSObject.Copy()

            # Modify the recurrence pattern type
            $tmpBody.properties.settings.recurrence.pattern.type = "absoluteMonthly"
            $tmpBody.properties.settings.recurrence.pattern.interval = 3

            # You might need/want to modify this property: 
            # $tmpBody.properties.settings.instanceDurationInDay = 5

            $putUrl = "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.Authorization/accessReviewScheduleDefinitions/$($_.name)?api-version=$apiVersion"
            
            Write-Output $putUrl

            $jsonString = $tmpBody | ConvertTo-Json -Depth 10

            Write-Output $jsonString

            # Make the PUT request to update the Access Review Schedule Definition
            $response2 = Invoke-RestMethod -Uri $putUrl -Method Put -Headers @{
                Authorization = "Bearer $accessToken"
                'Content-Type' = 'application/json'
            } -Body $jsonString

        }
    }

    # Check for the presence of a nextLink
    $url = $response.NextLink

} while ($url -ne $null)


# Disconnect from Azure
Disconnect-AzAccount

