
# ============================================================
# STA 4233/6233 Final Project
# ABC Logistics Lead Time - Data Exploration and Cleaning
# R Version of the Analysis
# ============================================================

# -----------------------------
# 0. Package setup
# -----------------------------
required_packages <- c(
  "readxl", "dplyr", "stringr", "ggplot2",
  "fastDummies", "knitr"
)

missing_packages <- required_packages[!sapply(required_packages, requireNamespace, quietly = TRUE)]
if (length(missing_packages) > 0) {
  stop(
    paste0(
      "Please install these packages before running the script: ",
      paste(missing_packages, collapse = ", ")
    )
  )
}

library(readxl)
library(dplyr)
library(stringr)
library(ggplot2)
library(fastDummies)
library(knitr)

options(stringsAsFactors = FALSE)

# -----------------------------
# 1. Input file path
# -----------------------------
# User-specified local file path
input_file <- "C:/Users/omer6/Downloads/Rdata.xlsx"

if (!file.exists(input_file)) {
  stop(paste0("Input workbook not found at: ", input_file))
}

cat("Using input file:
", input_file, "

")

# -----------------------------
# 2. Read worksheets
# -----------------------------
raw <- read_excel(input_file, sheet = "Raw-Data")
calendar <- read_excel(input_file, sheet = "Calendar")

cat("Raw-Data shape:", nrow(raw), "rows and", ncol(raw), "columns\n")
cat("Calendar shape:", nrow(calendar), "rows and", ncol(calendar), "columns\n\n")

print(head(raw))
print(calendar)

# Optional in RStudio:
# View(raw)
# View(calendar)

# -----------------------------
# 3. User-defined helper functions
# -----------------------------
standardize_text_columns <- function(df) {
  df %>%
    mutate(
      LOB = str_to_title(str_trim(as.character(LOB))),
      Origin = str_to_title(str_trim(as.character(Origin))),
      `Ship Mode` = str_to_upper(str_trim(as.character(`Ship Mode`))),
      `Ship Mode` = ifelse(`Ship Mode` == "FASTBOAT", "FAST BOAT", `Ship Mode`)
    )
}

assign_quarter_year <- function(receipt_dates, cal_df) {
  quarter <- rep(NA_character_, length(receipt_dates))
  year <- rep(NA_integer_, length(receipt_dates))

  for (i in seq_len(nrow(cal_df))) {
    idx <- !is.na(receipt_dates) &
      receipt_dates >= cal_df$Start_Date[i] &
      receipt_dates <= cal_df$End_date[i]

    quarter[idx] <- cal_df$Quarter[i]
    year[idx] <- cal_df$Year[i]
  }

  data.frame(Quarter = quarter, Year = year)
}

add_lead_times <- function(df) {
  df %>%
    mutate(
      `Manufacturing Lead Time` = as.numeric(`Ship Date` - `PO Download Date`),
      `In-transit Lead Time` = as.numeric(`Receipt Date` - `Ship Date`)
    )
}

mode_value <- function(x) {
  ux <- unique(x[!is.na(x)])
  ux[which.max(tabulate(match(x, ux)))]
}

# -----------------------------
# 4. Standardize fields and calculate lead times
# -----------------------------
calendar <- calendar %>%
  mutate(
    Start_Date = as.Date(Start_Date),
    End_date = as.Date(End_date)
  )

df <- raw %>%
  standardize_text_columns() %>%
  mutate(
    `PO Download Date` = as.Date(`PO Download Date`),
    `Ship Date` = as.Date(`Ship Date`),
    `Receipt Date` = as.Date(`Receipt Date`)
  )

qy <- assign_quarter_year(df$`Receipt Date`, calendar)
df$Quarter <- qy$Quarter
df$Year <- qy$Year

df <- add_lead_times(df)

cat("\nMissing Quarter values after direct calendar match:", sum(is.na(df$Quarter)), "\n")
cat("Missing Year values after direct calendar match:", sum(is.na(df$Year)), "\n\n")

print(head(df))

# -----------------------------
# 5. Diagnose unusual values before cleaning
# -----------------------------
quality_summary <- data.frame(
  column_name = names(df),
  missing_count = sapply(df, function(x) sum(is.na(x))),
  unique_values = sapply(df, function(x) dplyr::n_distinct(x, na.rm = FALSE))
)

print(quality_summary)

cat("\nNegative Manufacturing Lead Time rows:", sum(df$`Manufacturing Lead Time` < 0, na.rm = TRUE), "\n")
cat("Negative In-transit Lead Time rows:", sum(df$`In-transit Lead Time` < 0, na.rm = TRUE), "\n\n")

print(summary(df[, c("Manufacturing Lead Time", "In-transit Lead Time")]))

# -----------------------------
# 6. Clean and impute unusual values
# -----------------------------
clean <- df

mfg_thresholds <- clean %>%
  group_by(Origin, LOB) %>%
  summarise(mfg_hi = quantile(`Manufacturing Lead Time`, 0.99, na.rm = TRUE), .groups = "drop")

trans_thresholds <- clean %>%
  group_by(Origin, `Ship Mode`) %>%
  summarise(trans_hi = quantile(`In-transit Lead Time`, 0.99, na.rm = TRUE), .groups = "drop")

mfg_medians <- clean %>%
  group_by(Origin, LOB) %>%
  summarise(mfg_med = median(`Manufacturing Lead Time`, na.rm = TRUE), .groups = "drop")

trans_medians <- clean %>%
  group_by(Origin, `Ship Mode`) %>%
  summarise(trans_med = median(`In-transit Lead Time`, na.rm = TRUE), .groups = "drop")

clean <- clean %>%
  left_join(mfg_thresholds, by = c("Origin", "LOB")) %>%
  left_join(trans_thresholds, by = c("Origin", "Ship Mode")) %>%
  left_join(mfg_medians, by = c("Origin", "LOB")) %>%
  left_join(trans_medians, by = c("Origin", "Ship Mode")) %>%
  mutate(
    mfg_flagged = is.na(`Manufacturing Lead Time`) |
      `Manufacturing Lead Time` < 0 |
      `Manufacturing Lead Time` > mfg_hi,
    trans_flagged = is.na(`In-transit Lead Time`) |
      `In-transit Lead Time` < 0 |
      `In-transit Lead Time` > trans_hi,
    `Manufacturing Lead Time Clean` = ifelse(mfg_flagged, mfg_med, `Manufacturing Lead Time`),
    `In-transit Lead Time Clean` = ifelse(trans_flagged, trans_med, `In-transit Lead Time`)
  )

clean <- clean %>%
  mutate(
    `Ship Date Est` = `Ship Date`,
    `Ship Date Est` = ifelse(
      is.na(`Ship Date Est`),
      `PO Download Date` + `Manufacturing Lead Time Clean`,
      `Ship Date Est`
    ),
    `Ship Date Est` = as.Date(`Ship Date Est`, origin = "1970-01-01"),
    `Receipt Date Est` = `Receipt Date`,
    `Receipt Date Est` = ifelse(
      is.na(`Receipt Date Est`),
      `Ship Date Est` + `In-transit Lead Time Clean`,
      `Receipt Date Est`
    ),
    `Receipt Date Est` = as.Date(`Receipt Date Est`, origin = "1970-01-01")
  )

qy_est <- assign_quarter_year(clean$`Receipt Date Est`, calendar)
clean$Quarter <- ifelse(is.na(clean$Quarter), qy_est$Quarter, clean$Quarter)
clean$Year <- ifelse(is.na(clean$Year), qy_est$Year, clean$Year)
clean$Year <- as.integer(clean$Year)

rows_original <- nrow(raw)
rows_removed <- 0
rows_final <- nrow(clean)

cat("\nRows in original dataset:", rows_original, "\n")
cat("Rows removed during cleaning:", rows_removed, "\n")
cat("Rows retained for analysis:", rows_final, "\n\n")
cat("Manufacturing Lead Time values imputed:", sum(clean$mfg_flagged), "\n")
cat("In-transit Lead Time values imputed:", sum(clean$trans_flagged), "\n")
cat("Remaining missing Quarter values:", sum(is.na(clean$Quarter)), "\n")
cat("Remaining missing Year values:", sum(is.na(clean$Year)), "\n")

# -----------------------------
# 7. Final analysis dataset
# -----------------------------
analysis_df <- clean %>%
  select(
    LOB, Origin, `Ship Mode`, `PO Download Date`, `Ship Date`, `Receipt Date`,
    Quarter, Year, `Manufacturing Lead Time Clean`, `In-transit Lead Time Clean`
  )

cat("\nFinal dataset shape:", nrow(analysis_df), "rows and", ncol(analysis_df), "columns\n\n")
print(head(analysis_df))

# -----------------------------
# 8. Descriptive statistics
# -----------------------------
numeric_summary <- analysis_df %>%
  summarise(
    Year_count = sum(!is.na(Year)),
    Year_mean = mean(Year, na.rm = TRUE),
    Year_sd = sd(Year, na.rm = TRUE),
    Year_min = min(Year, na.rm = TRUE),
    Year_q1 = quantile(Year, 0.25, na.rm = TRUE),
    Year_median = median(Year, na.rm = TRUE),
    Year_q3 = quantile(Year, 0.75, na.rm = TRUE),
    Year_max = max(Year, na.rm = TRUE),
    Mfg_count = sum(!is.na(`Manufacturing Lead Time Clean`)),
    Mfg_mean = mean(`Manufacturing Lead Time Clean`, na.rm = TRUE),
    Mfg_sd = sd(`Manufacturing Lead Time Clean`, na.rm = TRUE),
    Mfg_min = min(`Manufacturing Lead Time Clean`, na.rm = TRUE),
    Mfg_q1 = quantile(`Manufacturing Lead Time Clean`, 0.25, na.rm = TRUE),
    Mfg_median = median(`Manufacturing Lead Time Clean`, na.rm = TRUE),
    Mfg_q3 = quantile(`Manufacturing Lead Time Clean`, 0.75, na.rm = TRUE),
    Mfg_max = max(`Manufacturing Lead Time Clean`, na.rm = TRUE),
    Transit_count = sum(!is.na(`In-transit Lead Time Clean`)),
    Transit_mean = mean(`In-transit Lead Time Clean`, na.rm = TRUE),
    Transit_sd = sd(`In-transit Lead Time Clean`, na.rm = TRUE),
    Transit_min = min(`In-transit Lead Time Clean`, na.rm = TRUE),
    Transit_q1 = quantile(`In-transit Lead Time Clean`, 0.25, na.rm = TRUE),
    Transit_median = median(`In-transit Lead Time Clean`, na.rm = TRUE),
    Transit_q3 = quantile(`In-transit Lead Time Clean`, 0.75, na.rm = TRUE),
    Transit_max = max(`In-transit Lead Time Clean`, na.rm = TRUE)
  )

cat("\nNumeric summary:\n")
print(numeric_summary)

categorical_summary <- data.frame(
  Variable = c("LOB", "Origin", "Ship Mode", "Quarter"),
  Unique_Values = c(
    n_distinct(analysis_df$LOB),
    n_distinct(analysis_df$Origin),
    n_distinct(analysis_df$`Ship Mode`),
    n_distinct(analysis_df$Quarter)
  ),
  Top_Category = c(
    mode_value(analysis_df$LOB),
    mode_value(analysis_df$Origin),
    mode_value(analysis_df$`Ship Mode`),
    mode_value(analysis_df$Quarter)
  ),
  Top_Count = c(
    max(table(analysis_df$LOB)),
    max(table(analysis_df$Origin)),
    max(table(analysis_df$`Ship Mode`)),
    max(table(analysis_df$Quarter))
  )
)

cat("\nCategorical summary:\n")
print(categorical_summary)

for (col_name in c("LOB", "Origin", "Ship Mode", "Quarter")) {
  cat("\nDistribution for", col_name, ":\n")
  print(as.data.frame(table(analysis_df[[col_name]])))
}

# -----------------------------
# 9. Graphical exploration
# -----------------------------
p1 <- ggplot(analysis_df, aes(x = `In-transit Lead Time Clean`)) +
  geom_histogram(bins = 30, color = "black", fill = "skyblue") +
  labs(
    title = "Distribution of Cleaned In-transit Lead Time",
    x = "Days",
    y = "Frequency"
  ) +
  theme_minimal()

p2 <- ggplot(analysis_df, aes(x = `Ship Mode`, y = `In-transit Lead Time Clean`)) +
  geom_boxplot(fill = "lightgreen") +
  labs(
    title = "In-transit Lead Time by Ship Mode",
    x = "Ship Mode",
    y = "In-transit Lead Time (days)"
  ) +
  theme_minimal()

p3 <- ggplot(analysis_df, aes(x = Origin, y = `In-transit Lead Time Clean`)) +
  geom_boxplot(fill = "orange") +
  labs(
    title = "In-transit Lead Time by Origin Site",
    x = "Origin",
    y = "In-transit Lead Time (days)"
  ) +
  theme_minimal()

p4 <- ggplot(
  analysis_df,
  aes(
    x = `Manufacturing Lead Time Clean`,
    y = `In-transit Lead Time Clean`,
    color = `Ship Mode`
  )
) +
  geom_point(alpha = 0.6) +
  labs(
    title = "Manufacturing vs In-transit Lead Time",
    x = "Manufacturing Lead Time (days)",
    y = "In-transit Lead Time (days)"
  ) +
  theme_minimal()

print(p1)
print(p2)
print(p3)
print(p4)

# -----------------------------
# 10. Correlation analysis
# -----------------------------
corr_input <- analysis_df %>%
  select(
    `Manufacturing Lead Time Clean`,
    `In-transit Lead Time Clean`,
    Year,
    LOB,
    Origin,
    `Ship Mode`,
    Quarter
  )

dummy_df <- fastDummies::dummy_cols(
  corr_input,
  select_columns = c("LOB", "Origin", "Ship Mode", "Quarter"),
  remove_selected_columns = TRUE,
  remove_first_dummy = FALSE
)

corr_matrix <- cor(dummy_df, use = "pairwise.complete.obs")
corr_with_target <- sort(corr_matrix[, "In-transit Lead Time Clean"], decreasing = TRUE)

cat("\nCorrelation with In-transit Lead Time Clean:\n")
print(round(corr_with_target, 6))

top_features <- names(corr_with_target)[2:11]
heatmap_cols <- c("In-transit Lead Time Clean", top_features)
heatmap_matrix <- corr_matrix[heatmap_cols, heatmap_cols]

image(
  1:ncol(heatmap_matrix),
  1:nrow(heatmap_matrix),
  t(heatmap_matrix[nrow(heatmap_matrix):1, ]),
  axes = FALSE,
  xlab = "",
  ylab = "",
  main = "Correlation Heatmap for Top In-transit Drivers",
  col = colorRampPalette(c("blue", "white", "red"))(100)
)
axis(1, at = 1:ncol(heatmap_matrix), labels = colnames(heatmap_matrix), las = 2, cex.axis = 0.7)
axis(2, at = 1:nrow(heatmap_matrix), labels = rev(rownames(heatmap_matrix)), las = 2, cex.axis = 0.7)

# -----------------------------
# 11. Validation checkpoints
# -----------------------------
cat("\nValidation checkpoints against the Python notebook:\n")
cat("- Original rows should be 9124\n")
cat("- Rows retained should be 9124\n")
cat("- Manufacturing imputations should be 470\n")
cat("- In-transit imputations should be 319\n")
cat("- Remaining missing Quarter values should be 0\n")
cat("- Remaining missing Year values should be 0\n")
cat("- Mean of cleaned in-transit lead time should be approximately 13.65936\n")
cat("- Mean of cleaned manufacturing lead time should be approximately 8.08527\n")
cat("- Strongest positive driver should be Ship Mode_OCEAN with correlation about 0.793217\n")
