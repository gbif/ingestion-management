# Retrieve command-line arguments
args <- commandArgs(trailingOnly = TRUE)

# Check if the file argument is provided
if (length(args) == 0) {
  cat("ERROR: No file provided.\n")
  stop("No file provided. Please specify a CSV file without header as a command-line argument.")
}

# Read the CSV file without header
file_name <- args[1]

if(!file.exists(file_name)) {
  cat("ERROR: File does not exist:", file_name, "\n")
  stop("File not found")
}

data <- read.csv(file_name, header = FALSE)

# Check for duplicates in either column
duplicates_in_col1 <- duplicated(data[[1]]) | duplicated(data[[1]], fromLast = TRUE)
duplicates_in_col2 <- duplicated(data[[2]]) | duplicated(data[[2]], fromLast = TRUE)

if (any(duplicates_in_col1)) {
  cat("ERROR: Duplicates found in column 1:\n")
  print(data$V1[duplicates_in_col1])
  stop("Duplicates found in column 1:\n")
}

if (any(duplicates_in_col2)) {
  cat("ERROR: Duplicates found in column 2:\n")
  print(data$V2[duplicates_in_col2])
  stop("Duplicates found in column 2:\n")
}

# Check that all rows are unique
if (any(duplicated(data))) {
  cat("ERROR: Duplicate rows found\n")
  stop("Duplicate rows found:\n")
} else {
  cat("✅ All duplicate checks passed!\n")
}
