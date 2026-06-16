suppressMessages({library(dplyr)})

args <- commandArgs(trailingOnly = TRUE)

datasetKey = args[1]
v1 = args[2]
log_file = if(length(args) >= 3) args[3] else NULL

# get GBIF version
cat("Checking for cached GBIF download...\n")
dd <- rgbif::occ_download_cached(rgbif::pred("datasetKey",datasetKey))  

if(is.na(dd)) {
cat("Starting new GBIF download (this may take several minutes)...\n")
dd <- rgbif::occ_download(rgbif::pred("datasetKey",datasetKey)) 
rgbif::occ_download_wait(dd)
cat("Download complete!\n")
} else {
cat("Using cached download\n")
}

cat("Importing GBIF data...\n")
gbif_data <- rgbif::occ_download_get(dd) |>
  rgbif::occ_download_import(colClasses = 'character') |> 
  suppressMessages()

migration_file = read.csv(datasetKey, header = FALSE)

## Download the IPT data
cat("Downloading IPT data...\n")
ep = rgbif::dataset_endpoint(datasetKey) %>%
  dplyr::filter(type == "DWC_ARCHIVE") %>%
  dplyr::pull(url) |>
  unique()
link1 = paste0(ep,"&v=",v1)

temp = tempfile()
download.file(link1,temp,mode="wb", quiet=TRUE)
ipt_data = read.table(unz(temp, "occurrence.txt"),sep="\t",quote="",header=TRUE,fill=TRUE,colClasses="character")
unlink(temp)

cat("\n")
cat(rgbif::dataset_get(datasetKey)$title,"\n")
cat(datasetKey,"\n")
cat("n total ids in file : ",length(migration_file$V1),"\n\n")

if(!all(migration_file$V1 %in% gbif_data$occurrenceID)) {
    cat("⚠️  Problems with old occurrenceIds in provided migration csv\n")
    cat("n ids not on GBIF : ",length(migration_file$V1[!migration_file$V1 %in% gbif_data$occurrenceID]),"\n")
    cat("Sample of ids in csv not on GBIF : \n")
    cat(head(migration_file$V1[!migration_file$V1 %in% gbif_data$occurrenceID]),"\n\n")
} else {
    cat("✓ All old IDs found on GBIF\n\n")
}

if(!all(migration_file$V2 %in% ipt_data$occurrenceID)) {
    cat("⚠️  Problems with new occurrenceIds in provided migration csv\n")
    cat("n ids not in new ver on IPT : ",length(migration_file$V2[!migration_file$V2 %in% ipt_data$occurrenceID]),"\n")
    cat("Sample of ids in csv but not in newest ver on IPT : \n")
    cat(head(migration_file$V2[!migration_file$V2 %in% ipt_data$occurrenceID]),"\n\n")
} else {
    cat("✓ All new IDs found on IPT\n\n")
}

if(all(migration_file$V2 %in% ipt_data$occurrenceID) & all(migration_file$V1 %in% gbif_data$occurrenceID)) {
    cat("✅ Migration file ids seem fine!\n")
}

