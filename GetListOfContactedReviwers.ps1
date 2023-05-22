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

Set-Content -Path $csvFilePath -Value ""

$header = "Review Name, Review Id, Reviewer Id, Name, UPN, Has been conacted, Has reviewed"
Add-Content -Path $csvFilePath -Value $header 


# Process reviews
[int]$reviewSkip = 0
$accessReviews = Get-MgIdentityGovernanceAccessReviewDefinition -Top 100 -Skip $reviewSkip

while ($accessReviews -and $accessReviews.Length -gt 0) {

    foreach ($accessReview in $accessReviews) {
        $reviewName = $accessReview.DisplayName

        Write-Host "Processing review $reviewName"

        [int]$instancesSkip = 0
        $instances = Get-MgIdentityGovernanceAccessReviewDefinitionInstance -AccessReviewScheduleDefinitionId $accessReview.Id -Top 100 -Skip $instancesSkip

        while ($instances -and $instances.Length -gt 0) {

            foreach ($instance in $instances) {
                $contactedReviewers = Get-MgIdentityGovernanceAccessReviewDefinitionInstanceContactedReviewer -AccessReviewScheduleDefinitionId $accessReview.Id -AccessReviewInstanceId $instance.Id
                $decisions = Get-MgIdentityGovernanceAccessReviewDefinitionInstanceDecision -AccessReviewScheduleDefinitionId $accessReview.Id -AccessReviewInstanceId $instance.Id


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
                            Contacted = "Yes"
                            Reviewed = "No"
                        }

                        $reviewerDictionary.Add($key, $newUser)
                    }
                }

                # Parsing decisions
                foreach ($decision in $decisions) {
                    if ($decision.reviewedBy -and $decision.reviewedBy.Id -ne "00000000-0000-0000-0000-000000000000") {
                    
                        $key = $decision.reviewedBy.Id + $instance.Id
                    
                        if ($reviewerDictionary.ContainsKey($key)) {

                            $reviewerDictionary[$key].Reviewed = "Yes"

                        } else {

                            $newUser = [PSCustomObject]@{
                                ReviewName = $accessReview.DisplayName
                                Id = $decision.reviewedBy.Id
                                Name = $decision.reviewedBy.displayName
                                Upn = $decision.reviewedBy.userPrincipalName
                                Contacted = "No"
                                Reviewed = "Yes"
                            }
                    
                            $reviewerDictionary.Add($key, $newUser)
                        }
                    }
                }
            }

            # Write for review
            foreach ($reviewer in $reviewerDictionary.Values) {
                $line = $reviewName + "," + $accessReview.Id + "," + $reviewer.Id + "," + $reviewer.Name + "," + $reviewer.Upn + "," + $reviewer.Contacted + "," + $reviewer.Reviewed
                Add-Content -Path $csvFilePath -Value $line 
            }

            [int]$instancesSkip += [int]100
            $instances = Get-MgIdentityGovernanceAccessReviewDefinitionInstance -AccessReviewScheduleDefinitionId $accessReview.Id -Top 100 -Skip $instancesSkip
        }

    }

    [int]$reviewSkip += [int]100
    $accessReviews = Get-MgIdentityGovernanceAccessReviewDefinition -Top 100 -Skip $reviewSkip
}

