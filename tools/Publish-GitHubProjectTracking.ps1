param(
    [Parameter(Mandatory = $true)]
    [string]$RepoFullName,

    [string]$EpicPath = ".\docs\project-management\epics\EPIC-001-midas-semantic-model.md",

    [string]$MilestonesPath = ".\docs\project-management\midas-milestones.md",

    [string]$WorkItemsPath = ".\docs\project-management\backlog\midas-work-items.csv",

    [string]$ProjectUrl = "https://github.com/users/LorenzoMorabito/projects/5",

    [switch]$WhatIf
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-GitHubHeaders {
    if (-not $env:GITHUB_TOKEN) {
        throw "GITHUB_TOKEN non impostato. Imposta un PAT con permessi repo/issue prima di eseguire lo script."
    }

    return @{
        Authorization = "Bearer $($env:GITHUB_TOKEN)"
        Accept        = "application/vnd.github+json"
        "User-Agent"  = "midas-semantic-model-tracking"
        "X-GitHub-Api-Version" = "2022-11-28"
    }
}

function Invoke-GitHubApi {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("GET","POST","PATCH")]
        [string]$Method,

        [Parameter(Mandatory = $true)]
        [string]$Uri,

        [object]$Body
    )

    $headers = Get-GitHubHeaders

    if ($Body) {
        $json = $Body | ConvertTo-Json -Depth 10
        return Invoke-RestMethod -Method $Method -Uri $Uri -Headers $headers -Body $json -ContentType "application/json"
    }

    return Invoke-RestMethod -Method $Method -Uri $Uri -Headers $headers
}

function Invoke-GitHubGraphQL {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Query,

        [hashtable]$Variables
    )

    $headers = Get-GitHubHeaders
    $body = @{
        query = $Query
    }
    if ($Variables) {
        $body.variables = $Variables
    }

    $json = $body | ConvertTo-Json -Depth 20
    $response = Invoke-RestMethod -Method POST -Uri "https://api.github.com/graphql" -Headers $headers -Body $json -ContentType "application/json"

    $hasErrorsProperty = $response.PSObject.Properties.Name -contains "errors"
    if ($hasErrorsProperty -and $response.errors) {
        $messages = ($response.errors | ForEach-Object { $_.message }) -join "; "
        throw "GitHub GraphQL error: $messages"
    }

    return $response.data
}

function Parse-ProjectReference {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url
    )

    if ($Url -match '^https://github\.com/(?<kind>users|orgs)/(?<owner>[^/]+)/projects/(?<number>\d+)$') {
        return @{
            Kind   = $matches["kind"]
            Owner  = $matches["owner"]
            Number = [int]$matches["number"]
        }
    }

    throw "Formato ProjectUrl non supportato: $Url"
}

function Get-ProjectInfo {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectUrl
    )

    $projectRef = Parse-ProjectReference -Url $ProjectUrl

    if ($projectRef.Kind -eq "users") {
        $query = @'
query($login:String!, $number:Int!) {
  user(login:$login) {
    projectV2(number:$number) {
      id
      title
    }
  }
}
'@

        $data = Invoke-GitHubGraphQL -Query $query -Variables @{
            login  = $projectRef.Owner
            number = $projectRef.Number
        }

        if (-not $data.user.projectV2) {
            throw "Project non trovato: $ProjectUrl"
        }

        return $data.user.projectV2
    }

    $query = @'
query($login:String!, $number:Int!) {
  organization(login:$login) {
    projectV2(number:$number) {
      id
      title
    }
  }
}
'@

    $data = Invoke-GitHubGraphQL -Query $query -Variables @{
        login  = $projectRef.Owner
        number = $projectRef.Number
    }

    if (-not $data.organization.projectV2) {
        throw "Project non trovato: $ProjectUrl"
    }

    return $data.organization.projectV2
}

function Get-ProjectItemContentIds {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectId
    )

    $query = @'
query($projectId:ID!, $cursor:String) {
  node(id:$projectId) {
    ... on ProjectV2 {
      items(first:100, after:$cursor) {
        pageInfo {
          hasNextPage
          endCursor
        }
        nodes {
          content {
            ... on Issue {
              id
            }
          }
        }
      }
    }
  }
}
'@

    $contentIds = [System.Collections.Generic.HashSet[string]]::new()
    $cursor = $null

    while ($true) {
        $variables = @{ projectId = $ProjectId; cursor = $cursor }
        $data = Invoke-GitHubGraphQL -Query $query -Variables $variables
        $items = $data.node.items

        foreach ($node in $items.nodes) {
            $hasContent = $node.PSObject.Properties.Name -contains "content"
            if (-not $hasContent -or -not $node.content) {
                continue
            }

            $hasId = $node.content.PSObject.Properties.Name -contains "id"
            if ($hasId -and $node.content.id) {
                [void]$contentIds.Add([string]$node.content.id)
            }
        }

        if (-not $items.pageInfo.hasNextPage) {
            break
        }

        $cursor = $items.pageInfo.endCursor
    }

    return $contentIds
}

function Add-IssueToProjectIfMissing {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectId,

        [Parameter(Mandatory = $true)]
        [string]$IssueNodeId,

        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.HashSet[string]]$ExistingContentIds,

        [Parameter(Mandatory = $true)]
        [string]$IssueTitle
    )

    if ($ExistingContentIds.Contains($IssueNodeId)) {
        return
    }

    if ($WhatIf) {
        Write-Host "[WhatIf] Add issue to project: $IssueTitle"
        return
    }

    $mutation = @'
mutation($projectId:ID!, $contentId:ID!) {
  addProjectV2ItemById(input:{projectId:$projectId, contentId:$contentId}) {
    item {
      id
    }
  }
}
'@

    Write-Host "Adding issue to project: $IssueTitle"
    [void](Invoke-GitHubGraphQL -Query $mutation -Variables @{
        projectId = $ProjectId
        contentId = $IssueNodeId
    })
    [void]$ExistingContentIds.Add($IssueNodeId)
}

function Get-MilestoneTitles {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $titles = [System.Collections.Generic.List[string]]::new()
    foreach ($line in Get-Content -Path $Path) {
        if ($line -match '^##\s+(M\d+\.\s+.+)$') {
            $titles.Add($matches[1].Trim())
        }
    }

    return $titles
}

function Get-AllMilestones {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoFullName
    )

    $repoApi = "https://api.github.com/repos/$RepoFullName"
    return @(Invoke-GitHubApi -Method GET -Uri "$repoApi/milestones?state=all&per_page=100")
}

function Get-OrCreateMilestone {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoFullName,

        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [object[]]$ExistingMilestones
    )

    $repoApi = "https://api.github.com/repos/$RepoFullName"
    $match = $ExistingMilestones | Where-Object { $_.title -eq $Title } | Select-Object -First 1
    if ($match) {
        return $match
    }

    if ($WhatIf) {
        Write-Host "[WhatIf] Create milestone: $Title"
        return [pscustomobject]@{ number = -1; title = $Title }
    }

    Write-Host "Creating milestone: $Title"
    return Invoke-GitHubApi -Method POST -Uri "$repoApi/milestones" -Body @{ title = $Title }
}

function Get-AllIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoFullName
    )

    $repoApi = "https://api.github.com/repos/$RepoFullName"
    $issues = [System.Collections.Generic.List[object]]::new()
    $page = 1

    while ($true) {
        $batch = @(Invoke-GitHubApi -Method GET -Uri "$repoApi/issues?state=all&per_page=100&page=$page")
        if ($batch.Count -eq 0) {
            break
        }

        foreach ($issue in $batch) {
            $hasPullRequestProperty = $issue.PSObject.Properties.Name -contains "pull_request"
            if (-not $hasPullRequestProperty) {
                $issues.Add($issue)
            }
        }

        if ($batch.Count -lt 100) {
            break
        }

        $page += 1
    }

    return $issues
}

function Get-EpicTitle {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $firstHeading = Get-Content -Path $Path | Where-Object { $_ -match '^# ' } | Select-Object -First 1
    if (-not $firstHeading) {
        throw "Impossibile determinare il titolo epic da $Path"
    }

    return $firstHeading.Substring(2).Trim()
}

function Get-OrCreateIssue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoFullName,

        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [string]$Body,

        [Parameter(Mandatory = $true)]
        [object[]]$ExistingIssues,

        [string[]]$Labels = @(),

        [int]$MilestoneNumber = 0
    )

    $repoApi = "https://api.github.com/repos/$RepoFullName"
    $existing = $ExistingIssues | Where-Object { $_.title -eq $Title } | Select-Object -First 1
    if ($existing) {
        return $existing
    }

    if ($WhatIf) {
        Write-Host "[WhatIf] Create issue: $Title"
        return [pscustomobject]@{ number = -1; title = $Title; html_url = "" }
    }

    $payload = @{
        title = $Title
        body  = $Body
        labels = $Labels
    }
    if ($MilestoneNumber -gt 0) {
        $payload.milestone = $MilestoneNumber
    }

    Write-Host "Creating issue: $Title"
    return Invoke-GitHubApi -Method POST -Uri "$repoApi/issues" -Body $payload
}

function New-ChildIssueBody {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Row,

        [Parameter(Mandatory = $true)]
        [string]$EpicReference
    )

    @"
Parent item: $EpicReference

ID: `$($Row.id)`
Milestone: `$($Row.milestone)`
Priority: `$($Row.priority)`
Type: `$($Row.item_type)`
Dependencies: `$($Row.depends_on)`

Comment:
$($Row.comment)
"@
}

$workItems = Import-Csv -Path $WorkItemsPath
$milestoneTitles = Get-MilestoneTitles -Path $MilestonesPath
$existingMilestones = Get-AllMilestones -RepoFullName $RepoFullName
$existingIssues = Get-AllIssues -RepoFullName $RepoFullName
$projectInfo = Get-ProjectInfo -ProjectUrl $ProjectUrl
$existingProjectContentIds = Get-ProjectItemContentIds -ProjectId $projectInfo.id

$milestoneMap = @{}
foreach ($title in $milestoneTitles) {
    $milestone = Get-OrCreateMilestone -RepoFullName $RepoFullName -Title $title -ExistingMilestones $existingMilestones
    $milestoneMap[$title.Substring(0,2)] = $milestone
}

$epicTitle = Get-EpicTitle -Path $EpicPath
$epicBody = Get-Content -Path $EpicPath -Raw
$epicMilestone = $milestoneMap["M0"]
$epicIssue = Get-OrCreateIssue -RepoFullName $RepoFullName -Title "[EPIC] $epicTitle" -Body $epicBody -ExistingIssues $existingIssues -Labels @("epic","semantic-model") -MilestoneNumber $epicMilestone.number
Add-IssueToProjectIfMissing -ProjectId $projectInfo.id -IssueNodeId $epicIssue.node_id -ExistingContentIds $existingProjectContentIds -IssueTitle $epicIssue.title

foreach ($row in $workItems) {
    $milestone = $milestoneMap[$row.milestone]
    $title = "[TASK] $($row.id) $($row.title)"
    $body = New-ChildIssueBody -Row $row -EpicReference "#$($epicIssue.number)"
    $issue = Get-OrCreateIssue -RepoFullName $RepoFullName -Title $title -Body $body -ExistingIssues $existingIssues -Labels @("semantic-model",$row.item_type.ToLower()) -MilestoneNumber $milestone.number
    Add-IssueToProjectIfMissing -ProjectId $projectInfo.id -IssueNodeId $issue.node_id -ExistingContentIds $existingProjectContentIds -IssueTitle $issue.title
}

Write-Host "Done."
