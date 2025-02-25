﻿
$tenantId = Read-Host "Enter tenant Id"

# Login to Graph
Connect-MgGraph -Scopes "AccessReview.Read.All, AccessReview.ReadWrite.All" -ContextScope Process -NoWelcome -TenantId $tenantId

# Define the path to the CSV file
$csvFilePath =  Read-Host "Enter your csv file name (should be in the same directory)"

# Import the CSV file
$csvData = Import-Csv -Path $csvFilePath

# Iterate through each row in the CSV file
foreach ($row in $csvData) {
    
    # Access each column value
    $username = $row.Username
    $userId = $row.UserId
    $groupName = $row.GroupName
    $recommendation = $row.Recommendation
    $decision = $row.Decision
    $justification = $row.Justification
    $parentReviewId = $row.ParentReviewId
    $instanceReviewId = $row.InstanceReviewId
    $stageId = $row.StageId
    $decisionId = $row.DecisionId

    if ($decision -eq "Recommendation") {
        $decision = $row.Recommendation
    }

    # Output the values (or perform any other operation)
    Write-Output "Username: $username"
    Write-Output "UserId: $userId"
    Write-Output "ResourceName: $groupName"
    Write-Output "Recommendation: $recommendation"
    Write-Output "Decision: $decision"
    Write-Output "Justification: $justification"
    Write-Output "ParentReviewId: $parentReviewId"
    Write-Output "InstanceReviewId: $instanceReviewId"
    Write-Output "StageId: $stageId"
    Write-Output "DecisionId: $decisionId"
    Write-Output "-----------------------------"
    
    $params = @{
	    decision = $decision
	    justification = $justification
    }

    if ($null -ne $stageId) {
        $stageId = $instanceReviewId
    }

    try {
        Update-MgIdentityGovernanceAccessReviewDefinitionInstanceStageDecision -AccessReviewScheduleDefinitionId $parentReviewId -AccessReviewInstanceId $instanceReviewId -AccessReviewStageId $stageId -AccessReviewInstanceDecisionItemId $decisionId -BodyParameter $params
    } catch {
        Write-Output "An error occurred when sending decision Error: $_"
    }
}


