# ABC Logistics — Lead Time Data Cleaning & Exploration

**STA 4233/6233 Final Project** · Periale Noutaha

## Overview

Cleans, validates, and explores shipment lead-time data for ABC Logistics,
identifying the strongest drivers of in-transit delay across shipping modes
and origin sites. Built as an R replication of an original Python analysis,
with matching validation checkpoints to confirm the two pipelines agree.

**Skills demonstrated:** data cleaning and validation, missing-value
imputation, text standardization, date/quarter matching against a calendar
table, correlation analysis, data visualization (ggplot2), R (tidyverse,
readxl, stringr, fastDummies).

## Data

- `ABC_Logistics_Raw_Data.xlsx` — raw shipment records (`Raw-Data` sheet) and
  a fiscal calendar (`Calendar` sheet) used to map receipt dates to
  quarter/year

## What the script does (`ABC_Logistics_Coding.R`)

1. Loads and inspects the raw shipment and calendar data
2. Standardizes text fields (line of business, origin, ship mode)
3. Matches each shipment to its fiscal quarter/year via the calendar table
4. Flags and imputes negative/invalid lead time values
5. Produces summary statistics and distribution plots (in-transit lead time
   by ship mode, by origin site; manufacturing vs. in-transit lead time)
6. Computes correlations to identify the strongest drivers of in-transit
   delay
7. Validates results against known checkpoints (row counts, imputation
   counts, expected means, strongest correlate) to confirm consistency with
   the original Python analysis

## Key Result

Ship mode is the strongest driver of in-transit lead time — ocean shipments
show the highest positive correlation with delay (~0.79) among the
variables tested.

## How to Run

1. Open `ABC_Logistics_Coding.R` in R/RStudio
2. Update the `input_file` path at the top of the script to point to your
   local copy of `ABC_Logistics_Raw_Data.xlsx`
3. Run the script top to bottom — required packages install automatically
   if missing

## Contents

- `ABC_Logistics_Coding.R` — full cleaning and analysis script
- `ABC_Logistics_Raw_Data.xlsx` — raw data
- `ABC_Logistics_Paper.docx` — written report
