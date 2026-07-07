# PrEP and Moral Hazard — Replication & Extension

**ECON 6103-002** · Morrow, Menn, Noutaha

A replication and extension of Eilam & Delhommer's (2021) *PrEP and Moral
Hazard*, examining the relationship between PrEP adoption and STI rates
across U.S. states, with an extension analyzing age-group heterogeneity.

**Skills demonstrated:** panel data cleaning and merging from multiple raw
sources, fixed-effects regression (difference-in-differences), clustered
standard errors, data visualization (ggplot2), reproducible reporting with
Quarto, R (tidyverse, fixest, modelsummary).

---

## Project Structure

```
prep_project/
│
├── data/
│   ├── raw/                 # Original downloaded files — do not edit
│   └── clean/
│       └── merged_data.csv  # Cleaned, merged analysis dataset
│
├── scripts/
│   ├── 00_setup.R           # Installs packages, sets file paths — run first
│   ├── 01_clean_data.R      # Loads, cleans, and merges all raw datasets
│   └── 02_analysis.R        # Replication and extension models
│
├── outputs/
│   ├── tables/               # Regression tables (.tex, .txt)
│   └── figures/               # Key figures, descriptively named
│
├── prep_replication.qmd      # Main Quarto source document
├── prep_replication.html     # Rendered HTML report
├── prep_replication.docx     # Rendered Word report
└── prep_replication_files/   # Auto-generated Quarto build assets — do not edit
```

---

## How to Run (in order)

1. Open the project (e.g. in Posit Cloud or RStudio)
2. Run `scripts/00_setup.R` — installs packages, sets file paths, checks folders
3. Confirm raw data files are present in `data/raw/` (see **Data Sources** below)
4. Run `scripts/01_clean_data.R` — cleans and merges all datasets into
   `data/clean/merged_data.csv`
5. Run `scripts/02_analysis.R` — runs the replication and extension models
6. Render `prep_replication.qmd` — produces the final HTML/Word report

---

## Data Sources

| File | Source | Download Link |
|---|---|---|
| `chlamydia_male.csv`, `chlamydia_female.csv` | CDC NCHHSTP Atlas | gis.cdc.gov/grasp/nchhstpatlas |
| `gonorrhea_male.csv`, `gonorrhea_female.csv` | CDC NCHHSTP Atlas | gis.cdc.gov/grasp/nchhstpatlas |
| `syphilis_male.csv`, `syphilis_female.csv` | CDC NCHHSTP Atlas | gis.cdc.gov/grasp/nchhstpatlas |
| `hiv_diagnosis_male.csv`, `hiv_diagnosis_female.csv` | CDC NCHHSTP Atlas | gis.cdc.gov/grasp/nchhstpatlas |
| `male_ssp_by_state.csv` | AIDSVu (syringe services program data) | aidsvu.org/data-download |
| `prep_2012.xlsx` – `prep_2018.xlsx` | AIDSVu (PrEP users by state, 2012–2018) | aidsvu.org/data-download |

**Google Trends:** search-interest data for "Grindr" (2010–2018) is included
in the analysis as `grindr_index` in `data/clean/merged_data.csv`. The raw
pull (via the `gtrendsR` package, loaded in `00_setup.R`) is not stored as a
separate CSV; the merged variable is the version used in the models.

**ACS demographic data:** originally planned as a control variable (see the
`tidycensus` call in `00_setup.R`) but was ultimately not included in the
final analysis. Neither `01_clean_data.R` nor `02_analysis.R` depend on it.

---

## Outputs

- **`outputs/tables/heterogeneity_age_regression_table.tex` / `.txt`** —
  extension regression table (STI rates on age-group PrEP rates)
- **`outputs/figures/replication_fig5_chlamydia.png`, `_gonorrhea.png`,
  `_syphilis.png`** — replication of Figure 5 from the original paper
- **`outputs/figures/extension_prep_age_effects_syphilis.png`** —
  coefficient plot of estimated PrEP effects on syphilis by age group

---

## Results Summary

The replication of Table 2 (Eilam & Delhommer) produces a coefficient of
0.414 on the male PrEP rate for chlamydia, close to the paper's reported
0.371; gonorrhea and syphilis estimates follow the same direction and
similar magnitude. The extension finds that most age-group PrEP rate
coefficients are statistically insignificant, likely due to multicollinearity
among age groups. The one significant result — lower syphilis rates
associated with higher PrEP adoption among those under 24 — may reflect more
frequent testing among younger PrEP users rather than a true reduction in
infections. Full discussion is in `prep_replication.qmd` / `.html`.

---

## To Submit

Zip the entire `prep_project/` folder. The professor can run all code by
updating the `project_path` variable in `scripts/00_setup.R`.
