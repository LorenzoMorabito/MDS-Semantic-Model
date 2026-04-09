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
| `d_licensing_status` | `Licensing Status` | Visible | Medium | Straight rename |
| `d_name_type` | `Name Type` | Visible | Medium | Straight rename |
| `d_launch_status` | `Launch Status` | Visible | Medium | Straight rename |
| `d_manufacturers` | `Manufacturers` | Visible | Medium | Straight rename |
| `d_generic_product_classification` | `Generic Product Classification` | Visible | Medium | Long but clear |
| `d_protection_current` | `Current Protection` | Visible | Medium | More readable than source order |
| `d_protection_historical` | `Historical Protection` | Visible | Medium | More readable than source order |
| `d_pre_post_protection_expiry` | `Pre/Post Protection Expiry` | Visible | Medium | Keep slash for readability if supported |
| `d_estimated_protection_expiry_date` | `Estimated Protection Expiry Date` | Visible | Medium | Long but explicit |
| `d_biologic_molecules` | `Biologic Molecules` | Visible | Medium | Straight rename |
| `d_biologic_products` | `Biologic Products` | Visible | Medium | Straight rename |
| `d_biocomparable_products` | `Biocomparable Products` | Visible | Medium | Straight rename |
| `d_non_biocomparable_products` | `Non Biocomparable Products` | Visible | Medium | Straight rename |
| `d_all_biocomp_non_biocomp_products` | `All Biocomp/Non Biocomp Products` | Visible | Low | Needs final wording confirmation |
| `d_biosimilar_reference_groups` | `Biosimilar Reference Groups` | Visible | Medium | Straight rename |
| `d_diags` | `DIAG` | Visible | Low | Needs business confirmation on acronym expansion |
| `d_disease_ratio_source` | `Disease Ratio Source` | Visible | Low | Niche business object |
| `d_diseases` | `Diseases` | Visible | Medium | Straight rename |
| `d_molecule_patent_expiry_date` | `Molecule Patent Expiry Date` | Visible | Low | Long technical/business hybrid |
| `d_regimen` | `Regimen` | Visible | Low | Straight rename |
| `d_specialty_products` | `Specialty Products` | Visible | Medium | Straight rename |
| `f_midas_sales` | `MIDAS Sales` | Hidden | Medium | Hidden fact can also stay technical if preferred |
| `MIDAS Measures` | `MIDAS Measures` | Visible | Keep | Already business-friendly |

## DAX Impact

The following explicit table references exist today in measures and must be updated if the refactor is applied:

- `d_time`
- `d_products`
- `d_international_products`
- `d_international_packs`
- `d_molecules`
- `d_generic_product_classification`
- `d_corporations`
- `d_protection_current`
- `d_international_prescriptions`
- `f_midas_sales`

These appear in:
- time intelligence formulas using `DATEADD`, `DATESINPERIOD`, `MAX`, `FILTER`, `ALL`
- `REMOVEFILTERS(...)` helpers for market-share denominators
- `LAUNCH_DATE = SELECTEDVALUE ( f_midas_sales[PRODUCT_LAUNCH_DATE] )`

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
- `f_midas_sales` -> `MIDAS Sales` or keep technical because hidden

## Open Wording Decisions

These should be confirmed before applying the rename:

- `d_diags` -> `DIAG` or a fuller business label
- `d_all_biocomp_non_biocomp_products` target wording
- `f_midas_sales` whether to keep technical because hidden
- whether `Pre/Post Protection Expiry` should use slash or plain words
