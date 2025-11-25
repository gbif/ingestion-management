#!/usr/bin/env Rscript
# Get installation type from GBIF API using rgbif

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 1) {
  cat("Usage: get_installation_type.R <installationKey>\n")
  quit(status = 1)
}

installation_key <- args[1]

# Load required library
suppressPackageStartupMessages(library(rgbif))

# Get installation type
tryCatch({
  result <- rgbif::installations(uuid = installation_key)
  installation_type <- result$data$type
  
  if (is.null(installation_type) || length(installation_type) == 0) {
    cat("ERROR: Could not retrieve installation type\n", file = stderr())
    quit(status = 1)
  }
  
  # Output the installation type
  cat(installation_type)
  
}, error = function(e) {
  cat(paste("ERROR:", e$message, "\n"), file = stderr())
  quit(status = 1)
})
