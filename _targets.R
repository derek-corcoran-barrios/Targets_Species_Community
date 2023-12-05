# _targets.R file
library(targets)
source("R/functions.R")
library(crew)
library(tarchetypes)

tar_option_set(packages = c("data.table", "dplyr", "ENMeval","janitor", "magrittr", "maxnet", "purrr", "readxl",
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
             iteration = "group"),
  tar_target(Phylo_Tree, generate_tree(Filtered_Species)),
  tar_target(Species_LU_Pres, SamplePresLanduse(DF =  Presence_Filtered, file = LandUseTiff),
             pattern = map(Presence_Filtered),
             iteration = "group"),
  tar_target(Fixed_LU_Pres, DuplicateBoth(DF =  Species_LU_Pres),
             pattern = map(Species_LU_Pres),
             iteration = "group"),
  tar_target(Species_LU_BG, SampleBGLanduse(DF =  Presence_Filtered, file = LandUseTiff),
             pattern = map(Presence_Filtered),
             iteration = "group"),
  tar_target(Fixed_LU_BG, DuplicateBoth(DF =  Species_LU_BG),
             pattern = map(Species_LU_BG),
             iteration = "group"),
  # Make a new target joining Fixed_LU_Pres and Fixed_LU_BG
  tar_target(Spp_LU_Both, bind_rows(Fixed_LU_Pres, Fixed_LU_BG,),
             pattern = map(Fixed_LU_Pres),
             iteration = "group"),
  tar_target(ModelAndPredict, ModelSpecies(Spp_LU_Both),
             pattern = map(Spp_LU_Both),
             iteration = "group")
)

