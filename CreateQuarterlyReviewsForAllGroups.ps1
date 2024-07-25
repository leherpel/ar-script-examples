#Might need to install first: Install-Module Microsoft.Graph -AllowClobber -Force
Import-Module Microsoft.Graph
#Might need to install first: Install-Module Microsoft.Graph.Identity.Governance
# Also might need to increase allowed function count Might need to install first: $MaximumFunctionCount = 8192
Import-Module Microsoft.Graph.Identity.Governance

Connect-MgGraph

$groups = Get-MgGroup

foreach ($group in $groups) {
    $groupId = $group.Id
    $groupName = $group.DisplayName
    $groupCreationDate = $group.CreatedDateTime
    $groupLabels = $group.AssignedLabels
    $groupOwners = Get-MgGroupOwner -GroupId $groupId

    $accessReviewScheduleDefinition = @{
        displayName = "Quarterly Access Review for $groupName - $groupId"
        descriptionForAdmins = "Quarterly review of user access to ensure compliance."
        descriptionForReviewers = "Please review the access of users to ensure they still need it."
        scope = @{
            query = "/groups/$groupId/members"
            queryType = "MicrosoftGraph"
        }
        reviewers = @{
            query = "./owners"
            queryType = "MicrosoftGraph"
        }
        settings = @{
		    mailNotificationsEnabled = $true
		    reminderNotificationsEnabled = $true
		    justificationRequiredOnApproval = $true
		    defaultDecisionEnabled = $false
		    defaultDecision = "None"
		    instanceDurationInDays = 15
		    recommendationsEnabled = $true
            autoApplyDecisionsEnabled = $true
            recurrence = @{
                pattern = @{
                    type = "absoluteMonthly"
                    interval = 3
                    month = 0
                    dayOfMonth = 0
                    firstDayOfWeek = "sunday"
                    index = "first"
                }
                range = @{
                    type = "noEnd"
                    startDate = Get-Date
                }
            }
        }
    }

    
    New-MgIdentityGovernanceAccessReviewDefinition -BodyParameter $accessReviewScheduleDefinition

    # Convert the definition to JSON
    $accessReviewScheduleDefinitionJson = $accessReviewScheduleDefinition | ConvertTo-Json -Depth 10

    Write-Host "Created review for group: $groupName ($groupId)"
}


Disconnect-MgGraph
