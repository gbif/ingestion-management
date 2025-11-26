
suppressMessages({library(dplyr)})
suppressMessages({library(purrr)})
suppressMessages({library(tidyr)})

args <- commandArgs(trailingOnly = TRUE)
# setwd("C:/Users/ftw712/Desktop/")

# https://specieslink.net/guid/398/

# datasetKey = "ffb63b32-306e-415c-87a3-34c60d157a2a"
# v1 = "1.113"

datasetKey = args[1]
v1 = args[2]

# get GBIF version
dd <- rgbif::occ_download_cached(rgbif::pred("datasetKey",datasetKey))  

if(is.na(dd)) {
dd <- rgbif::occ_download(rgbif::pred("datasetKey",datasetKey)) 
rgbif::occ_download_wait(dd)
}

gbif_data <- rgbif::occ_download_get(dd) |>
  rgbif::occ_download_import(colClasses = 'character') 

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

com_extract_old = function(id_strings, pattern) {  
matches <- stringr::str_match(id_strings, pattern)
prefix <- stringr::str_extract(id_strings, ".*:")
numbers <- matches[, 2] |> as.numeric() |> as.character()
suffixes <- matches[, 3]
tibble::tibble(id_strings,prefix,numbers,suffixes)
}

com_extract_new = function(id_strings, pattern) {  
matches <- stringr::str_match(id_strings, pattern)
prefix <- stringr::str_extract(id_strings, ".*/")
numbers <- matches[, 2] |> as.numeric() |> as.character()
suffixes <- matches[, 3]
tibble::tibble(id_strings,prefix,numbers,suffixes)
}


id_strings_old = gbif_data$occurrenceID 
id_strings_new = ipt_data$id 

# id_strings_old <- c("BRA:IBT:SP-FUNGI:1234", 
                    # "BRA:IBT:SP-FUNGI:12345-A", 
                    # "BRA:IBT:SP-FUNGI:123456A")

# id_strings_new <- c("https://specieslink.net/guid/398/1234", 
                    # "https://specieslink.net/guid/398/12345-A",
                    # "https://specieslink.net/guid/398/123456_A")


df_old = com_extract_old(id_strings_old, ".*:(\\d+)(.*)?$") |> glimpse()
df_new = com_extract_new(id_strings_new, ".*/(\\d+)(.*)?$") |> glimpse()

new_prefix = df_new$prefix |> unique()

simple_df = df_old |> 
filter(suffixes == "") |>
mutate(new_prefix = df_new$prefix |> unique()) |>
mutate(new_id = paste0(new_prefix,numbers,suffixes)) |>
mutate(old_id = id_strings) |> 
select(old_id,new_id) 

generate_variants <- function(input_string) {
  lower <- tolower(input_string)
  upper <- toupper(input_string)
  
  hyphen_variant_lower <- gsub("(^| )", "-", lower)
  underscore_variant_lower <- gsub("(^| )", "_", lower)
  space_variant_lower <- gsub("_", " ", gsub("-", " ", lower))
  
  hyphen_variant_upper <- gsub("(^| )", "-", upper)
  underscore_variant_upper <- gsub("(^| )", "_", upper)
  space_variant_upper <- gsub("_", " ", gsub("-", " ", upper))

  # Combine all variants into one vector
  variants <- c(
    input_string,
    lower,
    upper,
    hyphen_variant_lower,
    underscore_variant_lower,
    space_variant_lower,
    hyphen_variant_upper,
    underscore_variant_upper,
    space_variant_upper
  )
  
  return(variants)
}

print("--------------------- check here ---------------------")

print(df_old |> filter(!suffixes == ""))

complex_df = df_old |> 
filter(!suffixes == "") |>
group_by(id_strings) |> 
group_split() |>
map(~ { 
variants = generate_variants(.x$suffixes)
.x |>
expand_grid(variant = variants) |>
mutate(new_id = paste0(new_prefix,numbers,variant)) |>
mutate(id_found = new_id %in% id_strings_new) |> 
filter(id_found) |>
unique()
}) |> 
bind_rows() 

complex_df |> glimpse()

if(!nrow(complex_df) == 0) {
  complex_df = complex_df |>
  mutate(old_id = id_strings) |> 
  select(old_id,new_id) 
  
  rbind(simple_df,complex_df) |> 
  glimpse() |>
  write.table(file = datasetKey, sep = ",", row.names = FALSE, col.names = FALSE, quote = FALSE)

} else {
  simple_df |> 
  write.table(file = datasetKey, sep = ",", row.names = FALSE, col.names = FALSE, quote = FALSE)
}


# Rscript.exe C:/Users/ftw712/Desktop/scripts/shell/im/brazil_migrations_file_generator.R ffb63b32-306e-415c-87a3-34c60d157a2a 1.113
# Rscript.exe C:/Users/ftw712/Desktop/scripts/shell/im/brazil_migrations_file_generator.R d40307f5-55e0-4e9e-a42a-5f3612c56f31 1.113













