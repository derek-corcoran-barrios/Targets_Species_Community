# _targets.R file
library(targets)
source("R/functions.R")
library(crew)
library(tarchetypes)

tar_option_set(packages = c("data.table", "dplyr", "ENMeval","janitor", "magrittr", "maxnet", "purrr", "readxl",
                            "SDMWorkflows", "stringr", "tidyr", "terra", "V.PhyloMaker"),
               controller = crew_controller_local(workers = 60),
               error = "null")
list(
  tar_files(LanduseSuitability, list.files(path = "HabSut/", full.names = T)),
  tar_target(LandUseTiff,
             "Dir/LU.tif",
             format = "file"),
  tar_target(file, "2022-09-21.xlsx", format = "file"),
  tar_target(data, get_data(file)),
  tar_target(Clean, clean_species(data)),
  tar_target(Only_Plants, filter_plants(Clean)),
  tar_target(Presences,
             get_plant_presences(Only_Plants),
             pattern = map(Only_Plants)),

  #tar_target(Joint_Presences, Join_Presences(Presences)),
  tar_target(Presence_summary, summarise_presences(Presences),
             map(Presences),
             iteration = "group"),
  tar_target(Filtered_Species, Minimum_presences(Presence_summary, n = 5)),
  tar_target(Presence_Filtered,
             Select_Prescences(Presences, Filtered_Species$species),
             map(Presences),
             iteration = "group"),
  tar_target(buffer_500, make_buffer_rasterized(DT = Presence_Filtered, file = LandUseTiff),
             pattern = map(Presence_Filtered),
             iteration = "group"),
  tar_target(Long_Buffer, make_long_buffer(DT = buffer_500),
             pattern = map(buffer_500),
             iteration = "group"),
  tar_target(Phylo_Tree, generate_tree(Filtered_Species)),
  tar_target(ModelAndPredict, ModelAndPredictFunc(DF =  Presence_Filtered, file = LandUseTiff),
             pattern = map(Presence_Filtered)),
             #iteration = "group"),
  tar_target(Thresholds, create_thresholds(Model = ModelAndPredict,reference = Spp_LU_Both),
             pattern = map(ModelAndPredict, Spp_LU_Both),
             iteration = "group"),
  tar_target(LookUpTable, Generate_Lookup(Model = ModelAndPredict, Thresholds = Thresholds)),
  tar_target(LanduseTable, generate_landuse_table(path = LanduseSuitability),
             pattern = map(LanduseSuitability)),
  tar_target(Long_LU_table, Make_Long_LU_table(DF = LanduseTable)),
  tar_target(Final_Presences, make_final_presences(Long_LU_table, Long_Buffer, LookUpTable),
             pattern = map(Long_Buffer),
             iteration = "group"),
#  tarchetypes::tar_group_by(joint_final_presences, Join_Final_Presences(Final_Presences), Landuse),
#  tarchetypes::tar_group_by(phylo_divers,
#                            calc_pd(Final_Presences, Phylo_Tree), Landuse),
  tar_target(Richness, GetRichness(Final_Presences))
)

