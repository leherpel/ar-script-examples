
$tenantId = Read-Host "Enter tenant Id"

# Login to Graph
Connect-MgGraph -Scopes "AccessReview.Read.All" -ContextScope Process -NoWelcome -TenantId $tenantId

# Define the tenant ID and the search string
$parentReviewFilter = "contains(scope/microsoft.graph.accessReviewQueryScope/query, 'accessPackageAssignments')" 
$activeInstanceReviewFilter = "status eq 'InProgress'"

# Define the output CSV file
$outputCsvFile = "AccessReviewPendingDecisions.csv"

# Initialize an array to hold the results
$results = @()

# Get all access review schedule definitions
$allsched = Get-MgIdentityGovernanceAccessReviewDefinition -Filter $parentReviewFilter

# Iterate over each definition
foreach ($definition in $allsched) {

    Write-Output ("Started processing:" + $definition.Id + " with name:" + $definition.DisplayName)
    
    # Get active instance
    $allInstancesFromReview = Get-MgIdentityGovernanceAccessReviewDefinitionInstance -AccessReviewScheduleDefinitionId $definition.Id -Filter $activeInstanceReviewFilter 
    if ($allInstancesFromReview -eq $null) {
        Write-Output ("Could not find active instance for review: " + $definition.Id)
        continue
    } else {
        Write-Output ("Found active instance: " + $allInstancesFromReview.Id + " for review: " + $definition.Id)
    }

    # Get 1st page of decisions from active instance
    [int]$decisionsSkip = 0
    $decisions = Get-MgIdentityGovernanceAccessReviewDefinitionInstanceDecision -AccessReviewScheduleDefinitionId $definition.Id -AccessReviewInstanceId $allInstancesFromReview.Id -Top 100 -Skip $decisionsSkip
    if ($decisions -eq $null -or $decisions.Length -le 0) {
        Write-Output ("Could not find decisions for active stage for review: " + $definition.Id + " and instance: " + $allInstancesFromReview.Id)
        continue
    } else {
        Write-Output ("Found decsiions for active stage: " + $activeStage.Id + " for parent scheduled review: " + $definition.Id + " and instance: " + $allInstancesFromReview.Id)
    }

    while ($decisions -and $decisions.Length -gt 0) {
        
		Write-Output ("Fetched next " + $decisions.Length + " decisions for stage: " + $activeStage.Id + " for parent review: " + $definition.Id + " and instance: " + $allInstancesFromReview.Id)
       
		# Construct CSV object for each decision
        foreach ($decisionItem in $decisions) {	
		
			$cleanedName = $decisionItem.principal.displayName -replace '[,"]', '' -replace ';', ' ' -replace "`n", ""
			$cleanedResourceName = $decisionItem.resource.displayName
			$cleanedJustification = $decisionItem.justification
			
			$result = [PSCustomObject]@{
				Username             = $cleanedName 
				UserId               = $decisionItem.principal.id
				ResourceName         = $cleanedResourceName
				Recommendation       = $decisionItem.recommendation
                Decision             = $decisionItem.decision
                Justification        = $cleanedJustification
                ParentReviewId       = $definition.Id 
                InstanceReviewId     = $allInstancesFromReview.Id
                StageId              = $activeStage.Id
                DecisionId           = $decisionItem.Id
				}
			$results += $result
		}

        # Process next page
        [int]$decisionsSkip += [int]100
        $decisions = Get-MgIdentityGovernanceAccessReviewDefinitionInstanceDecision -AccessReviewScheduleDefinitionId $definition.Id -AccessReviewInstanceId $allInstancesFromReview.Id -Top 100 -Skip $decisionsSkip
    }
}

# Export the results to a CSV file
$results | Export-Csv -Path $outputCsvFile -NoTypeInformation

Write-Output ("Results have been exported to " + $outputCsvFile)