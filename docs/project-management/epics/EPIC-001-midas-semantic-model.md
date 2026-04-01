# EPIC-001 Build MIDAS Semantic Model

## Objective

Costruire un semantic model `MIDAS` enterprise-ready, riusabile dal team frontend/dashboard, con una base core stabile e una roadmap chiara verso la parity OAS.

## In Scope

- source and platform readiness per il dominio `trusted_starschema_02`
- semantic foundation del modello
- battery core di misure MIDAS
- parity estesa sulle famiglie piu rilevanti
- documentazione e handover

## Out Of Scope For Core Release

- piena parity di tutte le analitiche avanzate OAS
- reporting UX finale multi-pagina
- analitiche specialistiche `Price Effect`, `Volume Effect`, `Mix Effect` nella prima release

## Current blockers

- duplicati su `MIDAS_SALES_ID`
- relazione logica tempo non ancora sicura
- semantica non ancora chiarita delle misure local currency con null
- scelta finale `warehouse` e `storage mode` ancora da fissare

## Milestones

- `M0` Source And Platform Readiness
- `M1` Semantic Foundation
- `M2` Core Enterprise Battery
- `M3` Extended Parity
- `M4` Validation And Team Handover

## Child items

- [ ] `MIDAS-001` Deduplicate `f_midas_sales` on `MIDAS_SALES_ID`
- [ ] `MIDAS-002` Repair `d_time` coverage for `QUARTER_ID`
- [ ] `MIDAS-003` Clarify business semantics of local currency nulls
- [ ] `MIDAS-004` Lock final warehouse and connection strategy
- [ ] `MIDAS-005` Lock storage mode strategy
- [ ] `MIDAS-006` Add governed logical time relationship strategy
- [ ] `MIDAS-007` Define visible business dimensions for MIDAS
- [ ] `MIDAS-008` Apply hide/show policy to surrogate keys and technical columns
- [ ] `MIDAS-009` Create measure folders and naming standard in the model
- [ ] `MIDAS-010` Curate dimensions for business readability
- [ ] `MIDAS-011` Implement Units family
- [ ] `MIDAS-012` Implement Values family
- [ ] `MIDAS-013` Implement Market Share % family
- [ ] `MIDAS-014` Implement Evolution Index family
- [ ] `MIDAS-015` Implement Delta % vs PY family
- [ ] `MIDAS-016` Create thin business-facing measures for core MIDAS battery
- [ ] `MIDAS-017` Implement Values 3MM
- [ ] `MIDAS-018` Implement Delta % vs PP
- [ ] `MIDAS-019` Implement Rank family
- [ ] `MIDAS-020` Implement Average Price family
- [ ] `MIDAS-021` Implement PPG family
- [ ] `MIDAS-022` Decide business packaging for Brand/Generics split
- [ ] `MIDAS-023` Decide business packaging for Region/Channel split
- [ ] `MIDAS-024` Implement Price Effect family
- [ ] `MIDAS-025` Implement Volume Effect family
- [ ] `MIDAS-026` Implement Mix Effect family
- [ ] `MIDAS-027` Implement Segment Share / Penetration family
- [ ] `MIDAS-028` Define MIDAS parity sample test set
- [ ] `MIDAS-029` Run Release 1 sanity and parity checks
- [ ] `MIDAS-030` Create MIDAS domain README and measure catalog
- [ ] `MIDAS-031` Document known data issues and usage caveats
- [ ] `MIDAS-032` Define change workflow for MIDAS semantic model

## Done criteria

L'epic puo considerarsi chiuso quando:

- il semantic layer core e usabile dal team
- le misure core sono validate
- i blocker dati residui sono documentati
- il modello ha documentazione sufficiente per essere riusato da altri team

## Notes

Questo parent item e pensato per essere facilmente convertito in una issue GitHub epic. I child item hanno ID stabili per permettere il collegamento futuro a issue reali o project items.
