# Tools

## Publish GitHub project tracking

Lo script [Publish-GitHubProjectTracking.ps1](C:/work/MEN_Marketing/PBI_PROJECTS/data_source/midas_trusted_02/tools/Publish-GitHubProjectTracking.ps1) pubblica online milestone e issue GitHub partendo dai file versionati in repo, e aggiunge epic e task al GitHub Project portfolio.

### Prerequisiti

- un PAT GitHub in `GITHUB_TOKEN`
- permessi sulla repo target per creare issue e milestone

### Esempio

```powershell
$env:GITHUB_TOKEN = "ghp_..."
.\tools\Publish-GitHubProjectTracking.ps1 -RepoFullName "LorenzoMorabito/MDS-Semantic-Model"
```

### Esempio con project esplicito

```powershell
.\tools\Publish-GitHubProjectTracking.ps1 `
  -RepoFullName "LorenzoMorabito/MDS-Semantic-Model" `
  -ProjectUrl "https://github.com/users/LorenzoMorabito/projects/5"
```

### Modalita dry run

```powershell
.\tools\Publish-GitHubProjectTracking.ps1 -RepoFullName "LorenzoMorabito/MDS-Semantic-Model" -WhatIf
```

### Cosa crea

- milestone ricavate da [midas-milestones.md](C:/work/MEN_Marketing/PBI_PROJECTS/data_source/midas_trusted_02/docs/project-management/midas-milestones.md)
- issue epic ricavata da [EPIC-001-midas-semantic-model.md](C:/work/MEN_Marketing/PBI_PROJECTS/data_source/midas_trusted_02/docs/project-management/epics/EPIC-001-midas-semantic-model.md)
- child issue ricavate da [midas-work-items.csv](C:/work/MEN_Marketing/PBI_PROJECTS/data_source/midas_trusted_02/docs/project-management/backlog/midas-work-items.csv)
- aggiunta automatica di epic e child issue al GitHub Project `Portfolio-Repository Control Layer`

## Sync status GitHub Project

Lo script [Update-GitHubProjectStatus.ps1](C:/work/MEN_Marketing/PBI_PROJECTS/data_source/midas_trusted_02/tools/Update-GitHubProjectStatus.ps1) sincronizza il campo `Status` del GitHub Project con lo stato presente in [midas-work-items.csv](C:/work/MEN_Marketing/PBI_PROJECTS/data_source/midas_trusted_02/docs/project-management/backlog/midas-work-items.csv).

Mappatura usata:

- `open` -> `Todo`
- `in_progress` -> `In Progress`
- `blocked` -> `Blocked`
- `testing` -> `Testing`
- `done` -> `Done`
- `backlog` -> `Backlog`

### Esempio

```powershell
$env:GITHUB_TOKEN = "ghp_..."
.\tools\Update-GitHubProjectStatus.ps1 `
  -RepoFullName "LorenzoMorabito/MDS-Semantic-Model" `
  -ProjectUrl "https://github.com/users/LorenzoMorabito/projects/5"
```

### Modalita dry run

```powershell
.\tools\Update-GitHubProjectStatus.ps1 `
  -RepoFullName "LorenzoMorabito/MDS-Semantic-Model" `
  -ProjectUrl "https://github.com/users/LorenzoMorabito/projects/5" `
  -WhatIf
```
