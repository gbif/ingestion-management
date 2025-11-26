suppressMessages({library(dplyr)})

args <- commandArgs(trailingOnly = TRUE)

datasetKey = args[1]
v1 = args[2]
log_file = args[3]

## Download the IPT data
ep = rgbif::dataset_endpoint(datasetKey) %>%
  dplyr::filter(type == "DWC_ARCHIVE") %>%
  dplyr::pull(url) |>
  unique()
link1 = paste0(ep,"&v=",v1)

temp = tempfile()
download.file(link1,temp,mode="wb")
ipt_data = read.table(unz(temp, "occurrence.txt"),sep="\t",quote="",header=TRUE,fill=TRUE,colClasses="character")
unlink(temp)

migration_file = read.csv(datasetKey, header = FALSE)

if(!all(migration_file$V2 %in% ipt_data$occurrenceID)) {
    cat("Problems with new occurrenceIds in provided migration csv\n")
    cat("n ids not in new ver on IPT : ",length(migration_file$V2[!migration_file$V2 %in% ipt_data$occurrenceID]),"\n")
    cat("Sample of ids in csv but not in newest ver on IPT : \n")
    cat(head(migration_file$V2[!migration_file$V2 %in% ipt_data$occurrenceID]),"\n\n")

    cat("Going to remove problematics ids from migrations file", "\n")
    migration_file <- migration_file[migration_file$V2 %in% ipt_data$occurrenceID,]
    cat("n rows in new migration file : ",nrow(migration_file),"\n")
}

cat("Do you want to overwrite migrations file? (y/n): ")
answer <- tolower(trimws(readLines("stdin", n = 1)))

if (answer %in% c("y", "yes")) {
  message("Continuing...")
  write.table(
  migration_file,
  file = datasetKey,
  sep = ",",
  row.names = FALSE,
  col.names = FALSE,
  quote = FALSE
  )
#   write.csv(migration_file, "no_header.csv", row.names = FALSE, col.names = FALSE)  
} else {
  stop("User chose not to continue.")
}


