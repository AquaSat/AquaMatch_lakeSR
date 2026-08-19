# Changelog

All notable changes to this repository are documented in this file. Releases
are tagged by date (`vYYYY-MM-DD`) rather than semantic version, matching this
repo's [GitHub releases](https://github.com/AquaSat/AquaMatch_lakeSR/releases).

## [Unreleased]

### Fixed
- **Roy intermission handoff calculation** (`e_calculate_handoffs/src/get_matches.R`,
  `calculate_roy_handoff.R`): matched early/late-mission records shared
  unprefixed column names (`date`, `sat_id`, `source`, `prop_clouds`,
  `flag_temp_min/max`, `mission`) after the join, so filters and the
  surface-temperature NA check could silently operate on the wrong mission's
  data. All columns are now prefixed `early_`/`late_` at read-in, removing the
  ambiguity. Model x/y assignment was also corrected to consistently fit
  `sat_to ~ sat_corr`, so fitted coefficients apply forward without needing
  inversion downstream. This matches the original intent of the Roy handoff calculation and mirrors the application for the Gardner handoff calculation. This impacted 42 lines of the handoff csv file.
- All DSWE1 Roy handoff coefficients and diagnostic figures were recalculated
  as a result; values differ from the previous release.

### Added
- New worked example in `bookdown/07-intermission_handoffs.Rmd`: applies
  handoff coefficients to a single densely-sampled site (`1102_668`, Nee
  Noshe Reservoir, CO) across all bands and Landsat missions.

### Changed
- Regenerated `collated_handoffs_GEEv2025-02-12_QAv2025-06-04.csv` and all
  `roy_handoff`/`roy_deming_residuals` diagnostic plots.
- Full bookdown re-render.

## [v2026-01-28] - 2026-01-28
"Finalized lakeSR codebase for publication." Minor changes not reflected in
the previous release: supervisor/USGS readthrough edits across bookdown
chapters 1-8, a reference update (closes #60), and small bookdown rendering
consistency fixes.

## [v2026-01-16] - 2026-01-16
"Updated lakeSR codebase for initial USGS release."

## [v2025-03-20] - 2025-03-20
"Pre-USGS review release." Version release for USGS review, March 2025.

[Unreleased]: https://github.com/AquaSat/AquaMatch_lakeSR/compare/v2026-01-28...HEAD
[v2026-01-28]: https://github.com/AquaSat/AquaMatch_lakeSR/releases/tag/v2026-01-28
[v2026-01-16]: https://github.com/AquaSat/AquaMatch_lakeSR/releases/tag/v2026-01-16
[v2025-03-20]: https://github.com/AquaSat/AquaMatch_lakeSR/releases/tag/v2025-03-20
