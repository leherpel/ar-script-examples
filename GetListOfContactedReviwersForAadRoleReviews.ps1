Install-Module Microsoft.Graph.Identity.Governance
Import-Module Microsoft.Graph.Identity.Governance

Connect-MgGraph

# Prompt user for csv file path
$userInput = Read-Host -Prompt "Enter path to the csv file"
$csvFilePath = $userInput

# Create file
if (-not (Test-Path -Path $csvFilePath)) {
    # Create the file
    New-Item -Path $csvFilePath -ItemType File | Out-Null
    Write-Host "File created at $csvFilePath"
} else {
    Write-Host "File already exists at $csvFilePath"
}

# Setup dictionary and file
$reviewerDictionary = New-Object System.Collections.Generic.Dictionary"[String,Object]"

$missingDecisionsFor = @{
}

$timestamp = Get-Date -Format "MM-dd-yyyy HH:mm:ss"
$account = Get-MgContext | Select Account
Set-Content -Path $csvFilePath -Value "Generated at $timestamp for $account"
$header = "Review Id, Review Name, Start Date, Review Status, Reviewer Name, Reviewer UPN, Decisions made, Total, Completed?"
Add-Content -Path $csvFilePath -Value $header 

# Start processing reviews
[int]$reviewSkip = 0

$accessReviews = Get-MgIdentityGovernanceAccessReviewDefinition -Top 100 -Skip $reviewSkip

# Process first batch
while ($accessReviews -and $accessReviews.Length -gt 0) {

    foreach ($accessReview in $accessReviews) {
        $reviewName = $accessReview.DisplayName
        $tenantId = $accessReview.TenantId

        # Check if it is the correct review type
        if (!$accessReview -or
            !$accessReview.Scope -or
            !$accessReview.Scope.AdditionalProperties -or
            !$accessReview.Scope.AdditionalProperties.Count -gt 0 -or
            !$accessReview.Scope.AdditionalProperties.resourceScopes -or
            !$accessReview.Scope.AdditionalProperties.resourceScopes.Length -gt 0 -or
            !$accessReview.Scope.AdditionalProperties.resourceScopes[0].query -or
            !$accessReview.Scope.AdditionalProperties.resourceScopes[0].query.Contains("roleManagement")){

            Write-Host "Non-privileged role review"
            continue
        }

        Write-Host "Processing review $reviewName"

        # Get review's instances
        [int]$instancesSkip = 0
        $instances = Get-MgIdentityGovernanceAccessReviewDefinitionInstance -AccessReviewScheduleDefinitionId $accessReview.Id -Top 100 -Skip $instancesSkip -Sort startDateTime

        # Process this batch of instance
        $instanceReviewId = $accessReview.Id
        while ($instances -and $instances.Length -gt 0) {

            foreach ($instance in $instances) {
                $contactedReviewers = Get-MgIdentityGovernanceAccessReviewDefinitionInstanceContactedReviewer -AccessReviewScheduleDefinitionId $accessReview.Id -AccessReviewInstanceId $instance.Id
                $decisions = Get-MgIdentityGovernanceAccessReviewDefinitionInstanceDecision -AccessReviewScheduleDefinitionId $accessReview.Id -AccessReviewInstanceId $instance.Id

                $instanceReviewId = $instance.Id

                # Parsing contacted reviewers
                foreach ($reviewer in $contactedReviewers) {

                    $key = $reviewer.Id + $instance.Id

                    if ($reviewerDictionary.ContainsKey($key)) {

                        $reviewerDictionary[$key].Contacted = "Yes"

                    } else {

                        $newUser = [PSCustomObject]@{
                            ReviewName = $accessReview.DisplayName
                            Id = $reviewer.Id
                            Name = $reviewer.displayName
                            Upn = $reviewer.userPrincipalName
                        }

                        $reviewerDictionary.Add($key, $newUser)
                    }
                }

                $total = 0
                $decisionsMade = 0
                $complete = $false

                # Parsing decisions to see if review complete
                foreach ($decision in $decisions) {
                    if ($decision.reviewedBy -and $decision.reviewedBy.Id -ne "00000000-0000-0000-0000-000000000000") {
                        $decisionsMade += 1
                    }
                    $total += 1
                }

                # Have all decisions been made?
                if ($total -eq $decisionsMade) {
                    $complete = $true
                }

                # Write results for instance
                foreach ($reviewer in $reviewerDictionary.Values) {
                    $line = $instanceReviewId + "," + $reviewName + "," + $instance.startDateTime + "," + $instance.Status + "," + $reviewer.Name + "," + $reviewer.Upn + "," + $decisionsMade + "," + $total + "," + $complete
                    Add-Content -Path $csvFilePath -Value $line 
                }

                $reviewerDictionary.Clear()
            }

            [int]$instancesSkip += [int]100
            $instances = Get-MgIdentityGovernanceAccessReviewDefinitionInstance -AccessReviewScheduleDefinitionId $accessReview.Id -Top 100 -Skip $instancesSkip
        }
    }
    
    [int]$reviewSkip += [int]100
    $accessReviews = Get-MgIdentityGovernanceAccessReviewDefinition -Top 100 -Skip $reviewSkip
}