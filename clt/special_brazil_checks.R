suppressMessages({library(dplyr)})

args <- commandArgs(trailingOnly = TRUE)
# setwd("C:/Users/ftw712/Desktop/")

datasetKey = args[1]
v1 = args[2]
# log_file = args[3]

# get GBIF version
# dd <- rgbif::occ_download_cached(rgbif::pred("datasetKey",datasetKey))  

# if(is.na(dd)) {
# dd <- rgbif::occ_download(rgbif::pred("datasetKey",datasetKey)) 
# rgbif::occ_download_wait(dd)
# }

# gbif_data <- rgbif::occ_download_get(dd) |>
#   rgbif::occ_download_import(colClasses = 'character') |> 
#   suppressMessages()

# gbif_data |> glimpse()

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

print(ipt_data$id)
print(grepl("BRA:",ipt_data$id))

# Rscript.exe C:/Users/ftw712/Desktop/scripts/shell/im/special_brazil_checks.R d40307f5-55e0-4e9e-a42a-5f3612c56f31 1.59





