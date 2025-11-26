#!/usr/bin/env Rscript
# Pre-check script to compare IPT version with GBIF data
# Provides clean, informative output for GitHub Actions workflow

suppressPackageStartupMessages({
  library(rgbif)
  library(dplyr)
  library(rvest)
  library(stringr)
})

# Setup GBIF authentication
cat("→ Checking GBIF authentication...\n")
if (Sys.getenv("GBIF_USER") == "" || Sys.getenv("GBIF_PWD") == "") {
  cat("✗ ERROR: GBIF_USER and GBIF_PWD environment variables must be set\n")
  quit(status = 1)
}

# Set GBIF_EMAIL if not set (use USER as fallback)
if (Sys.getenv("GBIF_EMAIL") == "") {
  Sys.setenv(GBIF_EMAIL = paste0(Sys.getenv("GBIF_USER"), "@gbif.org"))
}

cat("  ✓ GBIF_USER:", Sys.getenv("GBIF_USER"), "\n")
cat("  ✓ GBIF_EMAIL:", Sys.getenv("GBIF_EMAIL"), "\n")
cat("  ✓ GBIF_PWD: [set]\n")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 1) {
  cat("Usage: compare_versions_precheck.R <datasetKey>\n")
  quit(status = 1)
}

datasetKey <- args[1]

cat("\n")
cat("═══════════════════════════════════════════════════════════\n")
cat("  IPT vs GBIF Data Comparison\n")
cat("═══════════════════════════════════════════════════════════\n")
cat("Dataset:", datasetKey, "\n\n")

# Step 1: Get IPT URL
cat("→ Getting IPT endpoint...\n")
tryCatch({
  ipt_url <- rgbif::dataset_identifier(datasetKey) |> 
    dplyr::filter(type == 'URL') |> 
    dplyr::pull(identifier) |> 
    unique() |>
    head(1)
  
  if (is.na(ipt_url) || length(ipt_url) == 0) {
    cat("✗ ERROR: No IPT URL found for dataset\n")
    quit(status = 1)
  }
  
  cat("  ✓ IPT URL:", ipt_url, "\n")
}, error = function(e) {
  cat("✗ ERROR getting IPT URL:", e$message, "\n")
  quit(status = 1)
})

# Step 2: Scrape latest version and modifier from IPT
cat("\n→ Scraping latest version from IPT webpage...\n")
tryCatch({
  ipt_page <- read_html(ipt_url)
  
  # Get all version links
  links <- ipt_page %>% 
    html_nodes("a") %>% 
    html_attr("href") %>% 
    tibble(links = .)
  
  latest_version <- links %>%
    filter(str_detect(links, "&v=")) %>%
    filter(str_detect(links, "archive.do")) %>%
    mutate(version = str_extract(links, "v=\\d+\\.\\d+")) %>%
    mutate(version = str_replace(version, "v=", "")) %>%
    pull(version) |>
    head(1)
  
  if (is.na(latest_version) || length(latest_version) == 0) {
    cat("✗ ERROR: Could not find version information on IPT page\n")
    quit(status = 1)
  }
  
  cat("  ✓ Latest IPT version:", latest_version, "\n")
  
  # Try to get "Last modified by" from JavaScript data array
  page_text <- ipt_page %>% html_text()
  
  # The version data is in JavaScript array format like:
  # ['1.4', '2023-02-01 03:38:43', '26,316', "fix truncated string", '', 'Jefferson Kung']
  # Look for pattern with the version number and extract the last quoted value (name)
  
  last_modified_by <- "Unknown"
  
  # Pattern: find array starting with version and ending with ]
  # The format is: ['version', ..., 'name']
  version_array_pattern <- paste0("\\['[^']*", latest_version, "'[^\\]]+\\]")
  version_array <- str_extract(page_text, version_array_pattern)
  
  if (!is.na(version_array)) {
    # Extract the last single-quoted value before the closing bracket
    # Pattern: get the last occurrence of 'text' before ]
    name_match <- str_match(version_array, "'([^']+)'\\s*\\]$")
    if (!is.na(name_match[1, 2])) {
      last_modified_by <- name_match[1, 2]
    }
  }
  
  if (!is.na(last_modified_by) && last_modified_by != "" && 
      last_modified_by != "Unknown" && nchar(last_modified_by) > 2) {
    cat("  ✓ Last modified by:", last_modified_by, "\n")
  } else {
    cat("  ⚠ Could not determine who last modified the version\n")
    last_modified_by <- "Unknown"
  }
}, error = function(e) {
  cat("✗ ERROR scraping IPT version:", e$message, "\n")
  quit(status = 1)
})

# Step 3: Get GBIF data
cat("\n→ Fetching GBIF data...\n")
cat("  Dataset key:", datasetKey, "\n")
tryCatch({
  cat("  Checking for cached download...\n")
  dd <- rgbif::occ_download_cached(rgbif::pred("datasetKey", datasetKey))
  
  if (is.na(dd)) {
    cat("  No cached download found, requesting new download...\n")
    cat("  (This may take several minutes...)\n")
    cat("  Using credentials: user=", Sys.getenv("GBIF_USER"), " email=", Sys.getenv("GBIF_EMAIL"), "\n")
    dd <- rgbif::occ_download(rgbif::pred("datasetKey", datasetKey), 
                              user = Sys.getenv("GBIF_USER"),
                              pwd = Sys.getenv("GBIF_PWD"),
                              email = Sys.getenv("GBIF_EMAIL"))
    cat("  Download key:", dd[[1]], "\n")
    cat("  Waiting for download to complete...\n")
    rgbif::occ_download_wait(dd, status_ping = 10)
    cat("  ✓ Download completed\n")
  } else {
    cat("  ✓ Using cached download:", dd[[1]], "\n")
  }
  
  cat("  Importing data...\n")
  gbif_data <- rgbif::occ_download_get(dd) |>
    rgbif::occ_download_import(colClasses = 'character')
  
  cat("  ✓ GBIF records:", nrow(gbif_data), "\n")
}, error = function(e) {
  cat("✗ ERROR fetching GBIF data:", conditionMessage(e), "\n")
  cat("  Error class:", class(e), "\n")
  traceback()
  quit(status = 1)
})

# Step 4: Get IPT data
cat("\n→ Downloading IPT archive (version", latest_version, ")...\n")
tryCatch({
  ep <- rgbif::dataset_endpoint(datasetKey) %>%
    dplyr::filter(type == "DWC_ARCHIVE") %>%
    dplyr::pull(url) |>
    unique() |>
    head(1)
  
  download_link <- paste0(ep, "&v=", latest_version)
  cat("  Download:", download_link, "\n")
  
  temp_file <- tempfile()
  download.file(download_link, temp_file, mode = "wb", quiet = TRUE)
  
  ipt_data <- read.table(
    unz(temp_file, "occurrence.txt"),
    sep = "\t",
    quote = "",
    header = TRUE,
    fill = TRUE,
    colClasses = "character"
  )
  unlink(temp_file)
  
  cat("  ✓ IPT records:", nrow(ipt_data), "\n")
}, error = function(e) {
  cat("✗ ERROR downloading IPT data:", e$message, "\n")
  quit(status = 1)
})

# Step 5: Compare occurrenceIDs
cat("\n→ Comparing occurrenceIDs...\n")

# Check for duplicates in IPT source
has_duplicates <- any(duplicated(ipt_data$occurrenceID))
if (has_duplicates) {
  n_duplicates <- sum(duplicated(ipt_data$occurrenceID))
  cat("  ⚠ WARNING: IPT source has", n_duplicates, "duplicate occurrenceIDs\n")
}

# Calculate overlap
ipt_in_gbif <- sum(ipt_data$occurrenceID %in% gbif_data$occurrenceID)
gbif_in_ipt <- sum(gbif_data$occurrenceID %in% ipt_data$occurrenceID)

ipt_in_gbif_pct <- round(100 * ipt_in_gbif / nrow(ipt_data), 1)
gbif_in_ipt_pct <- round(100 * gbif_in_ipt / nrow(gbif_data), 1)

# Calculate record count change
record_diff <- nrow(ipt_data) - nrow(gbif_data)
record_diff_pct <- round(100 * abs(record_diff) / nrow(gbif_data), 1)

# Determine if there's a large change in record counts (>20% change)
has_large_record_change <- record_diff_pct > 20

if (has_large_record_change) {
  if (record_diff > 0) {
    cat("  ⚠ Large increase in records: +", record_diff, " (+", record_diff_pct, "%)\n", sep = "")
  } else {
    cat("  ⚠ Large decrease in records: ", record_diff, " (-", record_diff_pct, "%)\n", sep = "")
  }
}

cat("\n")
cat("───────────────────────────────────────────────────────────\n")
cat("  Comparison Results\n")
cat("───────────────────────────────────────────────────────────\n")
cat("IPT Version:          ", latest_version, "\n", sep = "")
cat("Last Modified By:     ", last_modified_by, "\n", sep = "")
cat("\n")
cat("Record Counts:\n")
cat("  IPT records:        ", nrow(ipt_data), "\n", sep = "")
cat("  GBIF records:       ", nrow(gbif_data), "\n", sep = "")
if (record_diff != 0) {
  cat("  Difference:         ", record_diff, " (", 
      ifelse(record_diff > 0, "+", ""), record_diff_pct, "%)\n", sep = "")
}
if (has_large_record_change) {
  cat("  ⚠ Large change in record counts detected\n")
}
cat("\n")
cat("OccurrenceID Overlap:\n")
cat("  IPT records in GBIF:  ", ipt_in_gbif, "/", nrow(ipt_data), 
    " (", ipt_in_gbif_pct, "%)\n", sep = "")
cat("  GBIF records from IPT:", gbif_in_ipt, "/", nrow(gbif_data), 
    " (", gbif_in_ipt_pct, "%)\n", sep = "")
cat("\n")

# Determine status
if (ipt_in_gbif_pct < 50) {
  cat("✗ CONTACT: Less than 50% of IPT records found in GBIF\n")
  cat("  → Publisher should be contacted about occurrenceID changes\n")
  status <- "contact"
} else if (ipt_in_gbif_pct < 90) {
  cat("⚠ REVIEW: ", 100 - ipt_in_gbif_pct, "% of IPT records not in GBIF\n", sep = "")
  cat("  → Review recommended\n")
  status <- "review"
} else {
  cat("✓ GOOD: Strong overlap between IPT and GBIF data\n")
  status <- "good"
}

# Show sample occurrenceIDs
cat("\n")
cat("Sample OccurrenceIDs:\n")
cat("───────────────────────────────────────────────────────────\n")
cat("GBIF (first 5):\n")
gbif_sample <- head(gbif_data$occurrenceID, 5)
for (i in 1:length(gbif_sample)) {
  cat("  ", i, ". ", gbif_sample[i], "\n", sep = "")
}
cat("\n")
cat("IPT (first 5):\n")
ipt_sample <- head(ipt_data$occurrenceID, 5)
for (i in 1:length(ipt_sample)) {
  cat("  ", i, ". ", ipt_sample[i], "\n", sep = "")
}

cat("\n")
cat("═══════════════════════════════════════════════════════════\n")
cat("\n")

# Output for GitHub Actions
cat("STATUS=", status, "\n", sep = "")
cat("IPT_URL=", ipt_url, "\n", sep = "")
cat("IPT_RECORDS=", nrow(ipt_data), "\n", sep = "")
cat("GBIF_RECORDS=", nrow(gbif_data), "\n", sep = "")
cat("IPT_VERSION=", latest_version, "\n", sep = "")
cat("LAST_MODIFIED_BY=", last_modified_by, "\n", sep = "")
cat("OVERLAP_PCT=", ipt_in_gbif_pct, "\n", sep = "")
cat("HAS_DUPLICATES=", has_duplicates, "\n", sep = "")
cat("RECORD_DIFF=", record_diff, "\n", sep = "")
cat("RECORD_DIFF_PCT=", record_diff_pct, "\n", sep = "")
cat("HAS_LARGE_RECORD_CHANGE=", has_large_record_change, "\n", sep = "")

# Output sample IDs (up to 5 from each)
cat("IPT_SAMPLE_IDS=", paste(head(ipt_data$occurrenceID, 5), collapse = ","), "\n", sep = "")
cat("GBIF_SAMPLE_IDS=", paste(head(gbif_data$occurrenceID, 5), collapse = ","), "\n", sep = "")

# Exit with appropriate code
if (status == "contact") {
  quit(status = 1)
} else {
  quit(status = 0)
}
