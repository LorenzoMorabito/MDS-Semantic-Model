# MIDAS Project Management

Questa cartella contiene il tracking operativo del progetto `MIDAS` direttamente in repo, cosi resta versionato in `git` anche quando il tracker GitHub non e ancora stato popolato.

## Struttura

- [midas-milestones.md](./midas-milestones.md)
  Vista milestone del progetto.
- [epics/EPIC-001-midas-semantic-model.md](./epics/EPIC-001-midas-semantic-model.md)
  Parent item unico del progetto.
- [backlog/midas-work-items.csv](./backlog/midas-work-items.csv)
  Child item sviluppabili, con priorita, dipendenze e commenti.

## Regole d'uso

- Il parent item descrive obiettivo, scope, criteri di done e child item collegati.
- Ogni child item ha un ID stabile, ad esempio `MIDAS-011`.
- Le milestone raggruppano gli item per fase di delivery.
- Gli item upstream dati restano tracciati anche se non implementabili nel `.pbip`.
- Quando il tracker GitHub verra popolato, questa cartella restera la base documentale e potra essere usata per generare issue e milestone corrispondenti.

## Convenzioni

- `P0`: blocca il percorso critico
- `P1`: necessario per release core
- `P2`: parity estesa
- `P3`: analitiche avanzate o hardening

Stati consigliati:

- `open`
- `in_progress`
- `blocked`
- `done`
- `deferred`

## Scope attuale

Questa area governa il lavoro sul semantic model [midas_trusted_02](C:/work/MEN_Marketing/PBI_PROJECTS/data_source/midas_trusted_02) basato su `dev_iqvia_catalog.trusted_starschema_02`.
