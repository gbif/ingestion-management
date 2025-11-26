compare_versions <- function(datasetKey=NULL,
                      v1=NULL,ep=NULL,occ_file=NULL,sep=NULL,quote=NULL) {

# get GBIF version
dd <- rgbif::occ_download_cached(rgbif::pred("datasetKey",datasetKey))  

if(is.na(dd)) {
dd <- rgbif::occ_download(rgbif::pred("datasetKey",datasetKey)) 
rgbif::occ_download_wait(dd)
}

gbif_data <- rgbif::occ_download_get(dd) |>
  rgbif::occ_download_import(colClasses = 'character') 

if(is.null(ep)) {
ep = rgbif::dataset_endpoint(datasetKey) %>%
  dplyr::filter(type == "DWC_ARCHIVE") %>%
  dplyr::pull(url) |>
  unique()
link1 = paste0(ep,"&v=",v1)
}

link1 = ep

if(is.null(occ_file)) {
occ_file = "occurrence.txt"
}

if(is.null(sep)) {
sep = "\t"
}

if(is.null(quote)) {
quote=""
}

if(quote=="default") quote = "\"'"  

cat("download link:", link1,"\n",sep=",")

temp1 = tempfile()
download.file(link1,temp1,mode="wb")
data1 = read.table(unz(temp1, occ_file),sep=sep,quote=quote,header=TRUE,fill=TRUE,colClasses="character")
unlink(temp1)

# cat(data1$occurrenceID)
# cat(gbif_data$occurrenceID)

cat("id from ipt in gbif_data: ",  data1$occurrenceID %in% gbif_data$occurrenceID,"\n",sep=",")
cat("If you see a bunch of FALSE above, probably email the publisher!","\n",sep=",")

cat("nrow gbif: ", gbif_data |> nrow(),"\n",sep=",")
cat("nrow ipt: ", data1 |> nrow(),"\n",sep=",")

cat("gbif data from v1: ",  sum(gbif_data$occurrenceID %in% data1$occurrenceID),"\n",sep=",")
cat("v1 data in gbif: ",  sum(data1$occurrenceID %in% gbif_data$occurrenceID),"\n",sep=",")

cat("Any occurrenceIds duplicated from the ipt source: ", any(duplicated(data1$occurrenceID)),"\n",sep=",")
}