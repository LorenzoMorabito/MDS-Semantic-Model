param(
    [Parameter(Mandatory = $true)]
    [string]$RepoFullName,

    [string]$WorkItemsPath = ".\docs\project-management\backlog\midas-work-items.csv",

    [string]$ProjectUrl = "https://github.com/users/LorenzoMorabito/projects/5",

    [switch]$WhatIf
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-GitHubHeaders {
    if (-not $env:GITHUB_TOKEN) {
        throw "GITHUB_TOKEN non impostato. Imposta un PAT con permessi repo/issues/projects prima di eseguire lo script."
    }

    return @{
        Authorization         = "Bearer $($env:GITHUB_TOKEN)"
        Accept                = "application/vnd.github+json"
        "User-Agent"          = "midas-project-status-sync"
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
        $json = $Body | ConvertTo-Json -Depth 20
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
    $body = @{ query = $Query }
    if ($Variables) {
        $body.variables = $Variables
    }

    $json = $body | ConvertTo-Json -Depth 30
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

function Get-ProjectWithStatusField {
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
      fields(first:50) {
        nodes {
          ... on ProjectV2Field {
            id
            name
          }
          ... on ProjectV2SingleSelectField {
            id
            name
            options {
              id
              name
            }
          }
        }
      }
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
      fields(first:50) {
        nodes {
          ... on ProjectV2Field {
            id
            name
          }
          ... on ProjectV2SingleSelectField {
            id
            name
            options {
              id
              name
            }
          }
        }
      }
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

function Get-ProjectItems {
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
          id
          content {
            ... on Issue {
              id
              number
              title
            }
          }
          fieldValueByName(name:"Status") {
            ... on ProjectV2ItemFieldSingleSelectValue {
              name
              optionId
            }
          }
        }
      }
    }
  }
}
'@

    $items = [System.Collections.Generic.List[object]]::new()
    $cursor = $null

    while ($true) {
        $data = Invoke-GitHubGraphQL -Query $query -Variables @{
            projectId = $ProjectId
            cursor    = $cursor
        }

        $page = $data.node.items
        foreach ($node in $page.nodes) {
            $items.Add($node)
        }

        if (-not $page.pageInfo.hasNextPage) {
            break
        }

        $cursor = $page.pageInfo.endCursor
    }

    return $items
}

function Convert-BacklogStatusToProjectStatus {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BacklogStatus
    )

    switch ($BacklogStatus.Trim().ToLowerInvariant()) {
        "open"        { return "Todo" }
        "todo"        { return "Todo" }
        "backlog"     { return "Backlog" }
        "in_progress" { return "In Progress" }
        "blocked"     { return "Blocked" }
        "testing"     { return "Testing" }
        "done"        { return "Done" }
        default {
            throw "Status backlog non supportato: $BacklogStatus"
        }
    }
}

function Update-ProjectItemStatus {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectId,

        [Parameter(Mandatory = $true)]
        [string]$ItemId,

        [Parameter(Mandatory = $true)]
        [string]$FieldId,

        [Parameter(Mandatory = $true)]
        [string]$OptionId,

        [Parameter(Mandatory = $true)]
        [string]$ItemTitle,

        [Parameter(Mandatory = $true)]
        [string]$StatusName
    )

    if ($WhatIf) {
        Write-Host "[WhatIf] Set project status '$StatusName' for $ItemTitle"
        return
    }

    $mutation = @'
mutation($projectId:ID!, $itemId:ID!, $fieldId:ID!, $optionId:String!) {
  updateProjectV2ItemFieldValue(
    input: {
      projectId: $projectId
      itemId: $itemId
      fieldId: $fieldId
      value: { singleSelectOptionId: $optionId }
    }
  ) {
    projectV2Item {
      id
    }
  }
}
'@

    Write-Host "Updating project status to '$StatusName': $ItemTitle"
    [void](Invoke-GitHubGraphQL -Query $mutation -Variables @{
        projectId = $ProjectId
        itemId    = $ItemId
        fieldId   = $FieldId
        optionId  = $OptionId
    })
}

$project = Get-ProjectWithStatusField -ProjectUrl $ProjectUrl
$statusField = $project.fields.nodes | Where-Object { $_.name -eq "Status" } | Select-Object -First 1
if (-not $statusField) {
    throw "Campo 'Status' non trovato nel project $ProjectUrl"
}

$statusOptionByName = @{}
foreach ($option in $statusField.options) {
    $statusOptionByName[$option.name] = $option.id
}

$allIssues = Get-AllIssues -RepoFullName $RepoFullName
$issueByTitle = @{}
foreach ($issue in $allIssues) {
    $issueByTitle[$issue.title] = $issue
}

$projectItems = Get-ProjectItems -ProjectId $project.id
$projectItemByIssueNumber = @{}
foreach ($item in $projectItems) {
    $hasContent = $item.PSObject.Properties.Name -contains "content"
    if (-not $hasContent -or -not $item.content) {
        continue
    }
    $projectItemByIssueNumber[[string]$item.content.number] = $item
}

$workItems = Import-Csv -Path $WorkItemsPath
$updated = 0
$skipped = 0

foreach ($row in $workItems) {
    $issueTitle = "[TASK] $($row.id) $($row.title)"
    if (-not $issueByTitle.ContainsKey($issueTitle)) {
        Write-Warning "Issue non trovata per item backlog: $issueTitle"
        $skipped += 1
        continue
    }

    $issue = $issueByTitle[$issueTitle]
    $issueNumberKey = [string]$issue.number
    if (-not $projectItemByIssueNumber.ContainsKey($issueNumberKey)) {
        Write-Warning "Project item non trovato per issue #$issueNumberKey $issueTitle"
        $skipped += 1
        continue
    }

    $projectItem = $projectItemByIssueNumber[$issueNumberKey]
    $targetStatus = Convert-BacklogStatusToProjectStatus -BacklogStatus $row.status

    if (-not $statusOptionByName.ContainsKey($targetStatus)) {
        throw "Opzione di status '$targetStatus' non trovata nel project. Opzioni disponibili: $($statusOptionByName.Keys -join ', ')"
    }

    $currentStatus = $null
    $hasFieldValue = $projectItem.PSObject.Properties.Name -contains "fieldValueByName"
    if ($hasFieldValue -and $projectItem.fieldValueByName) {
        $currentStatus = $projectItem.fieldValueByName.name
    }

    if ($currentStatus -eq $targetStatus) {
        Write-Host "No change: $issueTitle -> $targetStatus"
        continue
    }

    Update-ProjectItemStatus -ProjectId $project.id -ItemId $projectItem.id -FieldId $statusField.id -OptionId $statusOptionByName[$targetStatus] -ItemTitle $issueTitle -StatusName $targetStatus
    $updated += 1
}

Write-Host "Done. Updated: $updated. Skipped: $skipped."
