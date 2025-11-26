

download_dwca = function(v=NULL,datasetKey=NULL) {
# endpoint
ep = rgbif::datasets(uuid=datasetKey)$data$endpoints %>%
filter(type == "DWC_ARCHIVE") %>%
pull(url)

link = paste0(ep,"&v=",v)
print(link)

temp = tempfile()
download.file(link,temp,mode="wb")
data = read.table(unz(temp, "occurrence.txt"),sep="\t",quote="",header=TRUE,fill=TRUE)
unlink(temp)

return(data)
}

library(dplyr)

args <- commandArgs(trailingOnly = TRUE)
uuid = args[1]
v1 = args[2]
v2 = args[3]

# uuid = "f05f3c37-1baa-40ea-ae3a-7a225364eee1"
# v1 = "1.2"
# v2 = "1.1"
# download dwca from ipt 
ipt = download_dwca(v = v1,datasetKey=uuid) |>
select_if(~ !all(is.na(.))) |>
glimpse() 

gbif = download_dwca(v = v2,datasetKey=uuid) |>
select_if(~ !all(is.na(.))) |>
glimpse() 

common_columns = intersect(colnames(gbif), colnames(ipt))

gbif_c = gbif |> select(all_of(common_columns))
ipt_c = ipt |> select(all_of(common_columns))

# start random sampling of columns

for(i in 1:1000) {

random_n_columns = sample(1:length(colnames(gbif_c)), 1)
random_columns = sample(colnames(gbif_c), size = random_n_columns)

gbif_random = gbif_c %>% select(all_of(random_columns),occurrenceID)
ipt_random = ipt_c %>% select(all_of(random_columns),occurrenceID)

n_gbif_random = gbif_random |> select(-occurrenceID) |> unique() |> nrow()
n_ipt_random = ipt_random |> select(-occurrenceID) |> unique() |> nrow()

if(n_gbif_random < nrow(gbif) | n_ipt_random < nrow(ipt)) {
  message("Random sampling did not produce unique rows")
  next  
}

gbif_combined = gbif_random |> tidyr::unite("id", -occurrenceID, sep = "_")
ipt_combined = ipt_random |> tidyr::unite("id", -occurrenceID, sep = "_")

if(i == 1000) {
    message("Random sampling did not work")
    
    message("Trying http to https conversion")
    gbif_http = gbif["occurrenceID"]
    ipt_http = ipt["occurrenceID"]

    gbif_http$old = gbif_http$occurrenceID
    gbif_http$occurrenceID = gsub("http://","https://",gbif$occurrenceID)

    out_http = merge(gbif_http, ipt_http, by = "occurrenceID",all.x=TRUE) 
    out_http = out_http[c("old","occurrenceID")]
    if(nrow(out_http) == nrow(gbif)) {
        message("HTTP to HTTPS conversion WORKED")
        write.csv(out_http, paste0("C:/Users/ftw712/Desktop/",uuid), row.names = FALSE, quote=FALSE)
    } else {
        message("HTTP to HTTPS conversion did not work")
    }
} 

out = merge(gbif_combined, ipt_combined, by = "id", all.x = TRUE) 
if(nrow(na.omit(out)) == 0) {
    next 
} 

if(nrow(na.omit(out)) == nrow(gbif)) {
    message("Random sampling WORKED")
    write.csv(out[2:3], paste0("C:/Users/ftw712/Desktop/",uuid), row.names = FALSE)
    break
}

}

print(gbif$occurrenceID |> head())
print(ipt$occurrenceID |> head()) 

