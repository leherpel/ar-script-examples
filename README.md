# ar-script-examples
Collection of Powershell scripts for automating processes in Access Reviews, such as review creation

## Scenarios
- [Get contacted reviewers and reviewers with decisions](#GetListOfContactedReviwersForAadRoleReviews)

## Prerequisites

1. Getting approved for Access Reviews Graph API permissions:   
    - The person or app which executes any script for managing/reading Access Reviews or makes the equivalent API calls needs to have the proper Graph permissions for Access Reviews in their tenant.
    -	Some more information:
        - [Required Graph permissions for Azure AD access reviews](https://learn.microsoft.com/en-us/graph/api/resources/accessreviewsv2-overview?view=graph-rest-1.0#role-and-application-permission-authorization-checks)
        - [Get access on behalf of a user](https://learn.microsoft.com/en-us/graph/auth-v2-user)
2. One simple way to add Graph permissions for a user principal is for a tenant admin to grant them permissions via the Portal or Graph Explorer.
    -	Grant permissions via Graph Explorer:
        1. In your browser navigate to [Graph Explorer](https://developer.microsoft.com/en-us/graph/graph-explorer)
        2. Log-in as your user who is tenant admin (top right corner)
        3. Fill out the URL text box with an Access Review’s URL: https://graph.microsoft.com/v1.0/identityGovernance/accessReviews/definitions
        4. The permissions you require will appear in the box below
        5. You need these Graph Permissions:
            - **AccessReview.Read.All**
            - **AccessReview.ReadWrite.All**
        6. Click '**Consent**' if you don’t already have the permissions, if it reads '**Unconsent**' you already have the permissions.

### Executing the scripts

1. Run the desired Powershell script like so `.\asdf.ps1`.
3. You might be prompted for an interactive login as the user you granted permissions to in Prerequisites.


## GetListOfContactedReviwersForAadRoleReviews

1. [Powershell script](./GetListOfContactedReviwers.ps1)
2. Sample execution and output:
![image](https://github.com/leherpel/ar-script-examples/assets/81385520/1517e2ed-36aa-4755-b12e-f7444238daf0)
![image](https://github.com/leherpel/ar-script-examples/assets/81385520/d372f13a-7e93-4299-8020-21b67eb0af52)

### Use the APIs to find contacted reviewers and find decisions made:
1. Get a list of review definitions
    - [List definitions](https://learn.microsoft.com/en-us/graph/api/accessreviewset-list-definitions?view=graph-rest-1.0&tabs=http)
    - `GET - https://graph.microsoft.com/v1.0/identityGovernance/accessReviews/definitions`
2. For each definition get a list of instances:
    - [List instances](https://learn.microsoft.com/en-us/graph/api/accessreviewscheduledefinition-list-instances?view=graph-rest-1.0&tabs=http)
    - `GET - https://graph.microsoft.com/v1.0/identityGovernance/accessReviews/definitions/fd3c47e4-c606-472e-b7de-6a217aa68c57/instances`
3. For each instance get a list of contacted reviewers (reviewers who have been notified to review):
    - [List contactedReviewers](https://learn.microsoft.com/en-us/graph/api/accessreviewinstance-list-contactedreviewers?view=graph-rest-1.0&tabs=http)
    - `GET - https://graph.microsoft.com/v1.0/identityGovernance/accessReviews/definitions/fd3c47e4-c606-472e-b7de-6a217aa68c57/instances/fd3c47e4-c606-472e-b7de-6a217aa68c57/contactedReviewers`
4. For each instance get a list of decision items:
    - [List decisions](https://learn.microsoft.com/en-us/graph/api/accessreviewinstance-list-decisions?view=graph-rest-1.0&tabs=http)
    - `GET - https://graph.microsoft.com/v1.0/identityGovernance/accessReviews/definitions/fd3c47e4-c606-472e-b7de-6a217aa68c57/instances/fd3c47e4-c606-472e-b7de-6a217aa68c57/decisions`
