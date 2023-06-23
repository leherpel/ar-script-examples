Install-Module Microsoft.Graph.Identity.Governance
Import-Module Microsoft.Graph.Identity.Governance

Connect-MgGraph

# Define access review properties for a review of all m365 group's direct users which lasts 15 days and runs every quarter
$params1 = @{
	displayName = "Review all M365 group users (no guests)"
	descriptionForAdmins = "Review all direct users"
	descriptionForReviewers = "Review all direct users"
    instanceEnumerationScope = @{
        query = '/groups?$filter=(groupTypes/any(c:c eq ''Unified''))'
        queryType = "MicrosoftGraph"
    }
	scope = @{
		"@odata.type" = "#microsoft.graph.accessReviewQueryScope"
		query = "./members/microsoft.graph.user"
		queryType = "MicrosoftGraph"
	}
	reviewers = @(
		@{
			query = "./owners"
			queryType = "MicrosoftGraph"
		}
	)
	settings = @{
		mailNotificationsEnabled = $true
		reminderNotificationsEnabled = $true
		justificationRequiredOnApproval = $true
		defaultDecisionEnabled = $false
		defaultDecision = "None"
		instanceDurationInDays = 15
		recommendationsEnabled = $true
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
				startDate = "2023-05-17"
			}
		}
	}
}

New-MgIdentityGovernanceAccessReviewDefinition -BodyParameter $params1

Write-Host "Review all M365 group users (no guests)"

# Define access review properties for a review of all m365 group's guest users which lasts 15 days and runs every quarter
$params2 = @{
	displayName = "Review all M365 group guest users"
	descriptionForAdmins = "Review all guest users"
	descriptionForReviewers = "Review all guest users"
    instanceEnumerationScope = @{
        query = '/groups?$filter=(groupTypes/any(c:c eq ''Unified''))'
        queryType = "MicrosoftGraph"
    }
	scope = @{
		"@odata.type" = "#microsoft.graph.accessReviewQueryScope"
		query = './members/microsoft.graph.user/?$filter=(userType eq ''Guest'')'
		queryType = "MicrosoftGraph"
	}
	reviewers = @(
		@{
			query = "./owners"
			queryType = "MicrosoftGraph"
		}
	)
	settings = @{
		mailNotificationsEnabled = $true
		reminderNotificationsEnabled = $true
		justificationRequiredOnApproval = $true
		defaultDecisionEnabled = $false
		defaultDecision = "None"
		instanceDurationInDays = 15
		recommendationsEnabled = $true
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
				startDate = "2023-05-17"
			}
		}
	}
}

New-MgIdentityGovernanceAccessReviewDefinition -BodyParameter $params2

Write-Host "Review all M365 group guest users"
