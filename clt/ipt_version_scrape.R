library(rvest)
library(stringr)
suppressMessages({library(dplyr)})

args <- commandArgs(trailingOnly = TRUE)

datasetKey = args[1]

url <- rgbif::dataset_identifier(datasetKey) |> 
    dplyr::filter(type=='URL') |> 
    dplyr::pull(identifier) |> 
    unique()   

links <- read_html(url) %>% 
    html_nodes("a") %>% 
    html_attr("href") %>% 
    tibble(links=.) 

links %>%
    filter(str_detect(links, "&v=")) %>%
    filter(str_detect(links, "archive.do")) %>%
    mutate(version = str_extract(links, "v=\\d+\\.\\d+")) %>%
    mutate(version = str_replace(version, "v=", "")) %>%
    pull(version) |>
    cat()


