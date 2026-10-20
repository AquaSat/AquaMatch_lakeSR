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
  inversion downstream. This matches the original intent of the Roy handoff calculation 
  and mirrors the application for the Gardner handoff calculation. This impacted 42 
  lines of the handoff csv file.
- All DSWE1 Roy handoff coefficients and diagnostic figures were recalculated
  as a result; values differ from the previous release.
- **`prop_hillShadow` was inverted** (`b_pull_Landsat_SRST_poi/py/run_GEE_per_pathrow.py`):
  it was the mean of the `ee.Terrain.hillShadow` band (1 = illuminated), so it
  reported the proportion of the buffer that was *illuminated*, not shaded as
  documented. The band is now inverted before the reduction, so
  `prop_hillShadow` is the proportion of the buffer shaded by terrain. Values
  in previous releases equal 1 minus the documented value. This is a diagnostic
  tally only; masking of summarized pixels was not affected. 
- **Landsat 8/9 aerosol mask was inverted** (`b_pull_Landsat_SRST_poi/py/run_GEE_per_pathrow.py`,
  AquaSat/AquaMatch_siteSR#47, #66): `add_sr_aero_mask` returns 1 for
  climatology/low aerosol, but the `ref_pull_89_*` functions took `.eq(0)` of
  it, so medium/high-aerosol pixels were *kept* and climatology/low pixels
  were masked. The `ref_pull_89_*` functions now take `.eq(1)`, so
  medium/high-aerosol pixels are masked as documented. `pCount_high_aero`
  was inverted in the same way and now counts medium/high-aerosol pixels.
  All Landsat 8/9 summaries in previous releases are affected.
- **Chunked GEE pulls failed after the first 5,000 sites** (`csv_to_eeFeat` in
  `b_pull_Landsat_SRST_poi/py/run_GEE_per_pathrow.py`): a July 2025 change
  switched row lookup from label-based to positional (`df.iloc`) but kept the
  per-chunk index offsets, so any path-row with more than 5,000 locations (73
  path-rows) raised an `IndexError` on its second chunk. `csv_to_eeFeat` now
  iterates over every row of the chunk it is given, with no offsets. The
  2025-02-12 GEE run predates this change and is not affected.

### Added
- New worked example in `bookdown/07-intermission_handoffs.Rmd`: applies
  handoff coefficients to a single densely-sampled site (`1102_668`, Nee
  Noshe Reservoir, CO) across all bands and Landsat missions.

### Changed
- `run_GEE_per_pathrow.py`: consolidated `add_realistic_mask_457` and the
  unused `add_realistic_mask_89` into a single `add_realistic_mask`. All
  missions were already using the Landsat 4-7 version, so the Landsat 8/9
  Aerosol band has never been screened for unrealistic values; there is no
  change to the data. `bookdown/05-lakeSR_LS_C2_SRST.Rmd` now documents this
  and states that Aerosol band summaries are for diagnostic use only
  ([Maciel et al. 2023](https://doi.org/10.1002/lol2.10344)).
- `python/pySetup.R`: rewritten so a missing or empty `env/` is actually
  (re)built (the previous `tryCatch` install branches could never run).
  Updated to Python 3.12 and current `earthengine-api`/`pandas`/`numpy`/`pyyaml`
  (versions pinned in `py_versions`); dropped the unused `pyreadr`.
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
