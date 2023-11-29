# _targets.R file
library(targets)
source("R/functions.R")
library(crew)

tar_option_set(packages = c("dplyr", "readxl", "SDMWorkflows", "terra", "janitor", "purrr", "data.table", "V.PhyloMaker"),
               controller = crew_controller_local(workers = 50),
               error = "null")
list(
  tar_target(LandUseTiff,
             "O:/Nat_Sustain-proj/_user/HanneNicolaisen_au704629/Data/Land_cover_maps/Basemap/basemap_reclass_SN_ModelClass.tif",
             format = "file"),
  #tar_target(LanduseRaster, read_raster(LandUseTiff), format = "qs"),
  tar_target(file, "2022-09-21.xlsx", format = "file"),
  tar_target(data, get_data(file)),
  tar_target(Clean, clean_species(data)),
  tar_target(Only_Plants, filter_plants(Clean)),
  tar_target(Presences,
             get_plant_presences(Only_Plants),
             pattern = map(Only_Plants)),
  tar_target(Presence_summary, summarise_presences(Presences),
             pattern = map(Presences)),
  tar_target(Trees, generate_tree(c))#,
#  tar_target(buffer_500, make_buffer_rasterized(DF =Presences, Rast = LanduseRaster),
#             pattern = map(Presences))
)

