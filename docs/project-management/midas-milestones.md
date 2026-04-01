# MIDAS Milestones

## M0. Source And Platform Readiness

Obiettivo:
- chiudere i prerequisiti che possono invalidare il semantic model

Include:
- deduplica fact
- copertura tempo
- chiarimento delle misure currency con null
- scelta warehouse
- scelta storage mode

Exit criteria:
- i blocker dati e piattaforma sono almeno documentati con decisione esplicita
- il team sa cosa puo essere implementato subito e cosa no

## M1. Semantic Foundation

Obiettivo:
- trasformare l'import grezzo in un semantic layer leggibile e governato

Include:
- strategia tempo
- dimensioni visibili
- hide/show
- naming
- folders

Exit criteria:
- il model browser e usabile da utenti non tecnici
- il layer esposto non e un dump di 39 tabelle importate

## M2. Core Enterprise Battery

Obiettivo:
- consegnare il primo set di misure enterprise-ready per il team

Include:
- `Units`
- `Values`
- `MS%`
- `EI`
- `Delta % vs PY`
- thin measures business-facing

Exit criteria:
- la batteria core e implementata e validata su casi campione

## M3. Extended Parity

Obiettivo:
- chiudere i gap legacy piu importanti senza entrare nelle analitiche specialistiche

Include:
- `Values 3MM`
- `Delta % vs PP`
- `Rank`
- `Average Price`
- `PPG`
- decisioni su `Brand/Generics` e `Region/Channel`

Exit criteria:
- parity estesa chiara e governata
- i principali gap OAS sono classificati come `done`, `deferred` o `out_of_scope`

## M4. Validation And Team Handover

Obiettivo:
- rendere il modello pronto all'uso da parte del team

Include:
- sanity check
- parity sample test
- measure catalog
- limiti noti
- workflow di change

Exit criteria:
- il semantic model puo essere usato da altri team con documentazione minima sufficiente
