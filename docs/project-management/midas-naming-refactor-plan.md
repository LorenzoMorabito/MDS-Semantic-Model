# MIDAS Naming Refactor Plan

## Objective

Standardize semantic object names to a business-friendly convention while keeping technical stability under control.

## Naming Standard

- Use `Title Case` for visible business objects.
- Preserve acronyms in uppercase: `ATC`, `NFC`, `ISO`, `PY`, `CUM`, `MAT`, `USD`, `EI`, `MS%`.
- Remove technical prefixes like `d_` and `f_` from visible table names.
- Keep technical/helper objects hidden when they are not meant for business browsing.
- Keep the measure table name business-oriented.

## Refactor Scope

This refactor affects:
- table declarations in `definition/tables/*.tmdl`
- `definition/model.tmdl`
- `definition/relationships.tmdl`
- DAX references in measures using table names explicitly
- any sort-by or object references that rely on logical table names

## Target Mapping

| Current logical name | Target logical name | Visibility intent | Priority | Notes |
|---|---|---|---|---|
| `d_atcs` | `ATC` | Visible | High | Preserve acronym |
| `d_categories` | `Categories` | Visible | High | Business-friendly |
| `d_categories_l2` | `Categories L2` | Visible | High | Already aligned at column level |
| `d_categories_l3` | `Categories L3` | Visible | High | Already aligned at column level |
| `d_channels` | `Channels` | Visible | High | Straight rename |
| `d_corporations` | `Corporations` | Visible | High | Straight rename |
| `d_countries` | `Countries` | Visible | High | Straight rename |
| `d_innovation_insights` | `Innovation Insights` | Visible | High | Business wording already used |
| `d_international_brands` | `International Brands` | Visible | High | Straight rename |
| `d_international_packs` | `International Packs` | Visible | High | Important for launch date grain discussions |
| `d_international_prescriptions` | `Prescriptions` | Visible | High | Current browser wording already simplified |
| `d_international_products` | `International Products` | Visible | High | Straight rename |
| `d_molecules` | `Molecules` | Visible | High | Straight rename |
| `d_nfc123` | `NFC` | Visible | High | Preserve acronym and current business label |
| `d_products` | `Products` | Visible | High | Straight rename |
| `d_reconstructed_markets` | `Markets` | Visible | High | More business-friendly than technical source name |
| `d_time` | `Time` | Visible | High | Core model object |
| `'Licensing Status'` | `Licensing Status` | Visible | Medium | Straight rename |
| `'Name Type'` | `Name Type` | Visible | Medium | Straight rename |
| `'Launch Status'` | `Launch Status` | Visible | Medium | Straight rename |
| `Manufacturers` | `Manufacturers` | Visible | Medium | Straight rename |
| `'Generic Product Classification'` | `Generic Product Classification` | Visible | Medium | Long but clear |
| `'Current Protection'` | `Current Protection` | Visible | Medium | More readable than source order |
| `'Historical Protection'` | `Historical Protection` | Visible | Medium | More readable than source order |
| `'Pre/Post Protection Expiry'` | `Pre/Post Protection Expiry` | Visible | Medium | Keep slash for readability if supported |
| `'Estimated Protection Expiry Date'` | `Estimated Protection Expiry Date` | Visible | Medium | Long but explicit |
| `'Biologic Molecules'` | `Biologic Molecules` | Visible | Medium | Straight rename |
| `'Biologic Products'` | `Biologic Products` | Visible | Medium | Straight rename |
| `'Biocomparable Products'` | `Biocomparable Products` | Visible | Medium | Straight rename |
| `'Non Biocomparable Products'` | `Non Biocomparable Products` | Visible | Medium | Straight rename |
| `'All Biocomp/Non Biocomp Products'` | `All Biocomp/Non Biocomp Products` | Visible | Low | Needs final wording confirmation |
| `'Biosimilar Reference Groups'` | `Biosimilar Reference Groups` | Visible | Medium | Straight rename |
| `DIAG` | `DIAG` | Visible | Low | Needs business confirmation on acronym expansion |
| `'Disease Ratio Source'` | `Disease Ratio Source` | Visible | Low | Niche business object |
| `Diseases` | `Diseases` | Visible | Medium | Straight rename |
| `'Molecule Patent Expiry Date'` | `Molecule Patent Expiry Date` | Visible | Low | Long technical/business hybrid |
| `Regimen` | `Regimen` | Visible | Low | Straight rename |
| `'Specialty Products'` | `Specialty Products` | Visible | Medium | Straight rename |
| `'MIDAS Sales'` | `MIDAS Sales` | Hidden | Medium | Hidden fact can also stay technical if preferred |
| `MIDAS Measures` | `MIDAS Measures` | Visible | Keep | Already business-friendly |

## DAX Impact

The following explicit table references exist today in measures and must be updated if the refactor is applied:

- `d_time`
- `d_products`
- `d_international_products`
- `d_international_packs`
- `d_molecules`
- `'Generic Product Classification'`
- `d_corporations`
- `'Current Protection'`
- `d_international_prescriptions`
- `'MIDAS Sales'`

These appear in:
- time intelligence formulas using `DATEADD`, `DATESINPERIOD`, `MAX`, `FILTER`, `ALL`
- `REMOVEFILTERS(...)` helpers for market-share denominators
- `LAUNCH_DATE = SELECTEDVALUE ( 'MIDAS Sales'[PRODUCT_LAUNCH_DATE] )`

## Recommended Execution Order

1. Rename visible dimension tables with highest business value and low semantic ambiguity.
2. Update `model.tmdl` and `relationships.tmdl` references.
3. Update DAX references in `MIDAS Measures.tmdl`.
4. Validate relationships and loadability.
5. Apply secondary/low-priority renames after business wording confirmation.

## Recommended Phase 1

Phase 1 should include only the safest business-facing objects:

- `d_atcs` -> `ATC`
- `d_categories` -> `Categories`
- `d_categories_l2` -> `Categories L2`
- `d_categories_l3` -> `Categories L3`
- `d_channels` -> `Channels`
- `d_corporations` -> `Corporations`
- `d_countries` -> `Countries`
- `d_innovation_insights` -> `Innovation Insights`
- `d_international_brands` -> `International Brands`
- `d_international_packs` -> `International Packs`
- `d_international_prescriptions` -> `Prescriptions`
- `d_international_products` -> `International Products`
- `d_molecules` -> `Molecules`
- `d_nfc123` -> `NFC`
- `d_products` -> `Products`
- `d_reconstructed_markets` -> `Markets`
- `d_time` -> `Time`
- `'MIDAS Sales'` -> `MIDAS Sales` or keep technical because hidden

## Open Wording Decisions

These should be confirmed before applying the rename:

- `DIAG` -> `DIAG` or a fuller business label
- `'All Biocomp/Non Biocomp Products'` target wording
- `'MIDAS Sales'` whether to keep technical because hidden
- whether `Pre/Post Protection Expiry` should use slash or plain words
