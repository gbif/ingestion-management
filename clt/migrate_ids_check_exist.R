suppressMessages({library(dplyr)})

args <- commandArgs(trailingOnly = TRUE)
# setwd("C:/Users/ftw712/Desktop/")

# datasetKey="76823beb-2f33-47a6-96a1-ccd2df47ac28"
# v1="1.120"

datasetKey = args[1]
v1 = args[2]
log_file = args[3]

# get GBIF version
dd <- rgbif::occ_download_cached(rgbif::pred("datasetKey",datasetKey))  
# dd <- NA_character_

if(is.na(dd)) {
dd <- rgbif::occ_download(rgbif::pred("datasetKey",datasetKey)) 
rgbif::occ_download_wait(dd)
}

gbif_data <- rgbif::occ_download_get(dd) |>
  rgbif::occ_download_import(colClasses = 'character') |> 
  suppressMessages()


migration_file = read.csv(datasetKey, header = FALSE)

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

cat(rgbif::dataset_get(datasetKey)$title,"\n")
cat(datasetKey,"\n")
cat("n total ids in file : ",length(migration_file$V1),"\n\n")

if(!all(migration_file$V1 %in% gbif_data$occurrenceID)) {
    cat("Problems with old occurrenceIds in provided migration csv\n")
    cat("n ids not on GBIF : ",length(migration_file$V1[!migration_file$V1 %in% gbif_data$occurrenceID]),"\n")
    cat("Sample of ids in csv not on GBIF : \n")
    cat(head(migration_file$V1[!migration_file$V1 %in% gbif_data$occurrenceID]),"\n\n")
}

if(!all(migration_file$V2 %in% ipt_data$occurrenceID)) {
    cat("Problems with new occurrenceIds in provided migration csv\n")
    cat("n ids not in new ver on IPT : ",length(migration_file$V2[!migration_file$V2 %in% ipt_data$occurrenceID]),"\n")
    cat("Sample of ids in csv but not in newest ver on IPT : \n")
    cat(head(migration_file$V2[!migration_file$V2 %in% ipt_data$occurrenceID]),"\n\n")
}

if(all(migration_file$V2 %in% ipt_data$occurrenceID) & all(migration_file$V1 %in% gbif_data$occurrenceID)) {
    # cat(datasetKey,"\n")
    cat("Migration file ids seem fine!\n")
}

