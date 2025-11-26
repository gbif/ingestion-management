library(dplyr)

setwd("C:/Users/ftw712/Desktop/inaturalist-taxonomy.dwca/")

list.files()

readr::read_csv("taxa.csv") |> 
mutate(parentNameUsageID = gsub("https://www.inaturalist.org/taxa/","",parentNameUsageID)) |> 
glimpse() |>
readr::write_csv("taxa1.csv")
