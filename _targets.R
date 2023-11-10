# _targets.R file
library(targets)
source("R/functions.R")
library(crew)

tar_option_set(packages = c("dplyr", "readxl", "SDMWorkflows", "terra", "janitor", "purrr", "data.table"),
               controller = crew_controller_local(workers = 12))
list(
  tar_target(file, "2022-09-21.xlsx", format = "file"),
  tar_target(data, get_data(file)),
  tar_target(Clean, clean_species(data)),
  tar_target(Only_Plants, filter_plants(Clean)),
  tar_target(Presences,
             get_plant_presences(Only_Plants),
             pattern = map(Only_Plants)),
  tar_target(Presence_summary, summarise_presences(Presences),
             pattern = head(Presences))
)

