# Retrieve command-line arguments
args <- commandArgs(trailingOnly = TRUE)

# Check if the file argument is provided
if (length(args) == 0) {
  stop("No file provided. Please specify a CSV file without header as a command-line argument.")
}

# Read the CSV file without header
file_name <- args[1]
print(file_name)
data <- read.csv(file_name, header = FALSE)


# Check for duplicates in either column
duplicates_in_col1 <- duplicated(data[[1]]) | duplicated(data[[1]], fromLast = TRUE)
duplicates_in_col2 <- duplicated(data[[2]]) | duplicated(data[[2]], fromLast = TRUE)

if (any(duplicates_in_col1)) {
  print(data$V1[duplicates_in_col1])
  stop("Duplicates found in column 1:\n")
} 

if (any(duplicates_in_col2)) {
  print(data$V2[duplicates_in_col2])
  stop("Duplicates found in column 2:\n")
} 

# Check that all rows are unique
if (any(duplicated(data))) {
  stop("Duplicate rows found:\n")
} else {
  cat("All no duplicates OK.\n")
}
