# _targets.R file
library(targets)
source("R/functions.R")
library(crew)
library(tarchetypes)

tar_option_set(packages = c("data.table", "dplyr", "janitor", "magrittr", "purrr", "readxl",
                            "SDMWorkflows", "terra", "V.PhyloMaker"),
               controller = crew_controller_local(workers = 50),
               error = "null")
list(
  tar_target(LandUseTiff,
             "O:/Nat_Sustain-proj/_user/HanneNicolaisen_au704629/Data/Land_cover_maps/Basemap/basemap_reclass_SN_ModelClass.tif",
             format = "file"),
  tar_target(file, "2022-09-21.xlsx", format = "file"),
  tar_target(data, get_data(file)),
  tar_target(Clean, clean_species(data)),
  tar_target(Only_Plants, filter_plants(Clean)),
  tar_target(Presences,
             get_plant_presences(Only_Plants),
             pattern = map(Only_Plants)),

  tar_target(Joint_Presences, Join_Presences(Presences)),
  tar_target(Presence_summary, summarise_presences(Joint_Presences)),
  tar_target(Filtered_Species, Minimum_presences(Presence_summary, n = 5)),
  tarchetypes::tar_group_by(Presence_Filtered,
             Select_Prescences(Joint_Presences, Filtered_Species$species), species),
  tar_target(buffer_500, make_buffer_rasterized(DT = Presence_Filtered, file = LandUseTiff),
             pattern = map(Presence_Filtered),
             iteration = "group")

)

