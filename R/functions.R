get_data <- function(file) {
  readxl::read_xlsx(file) |>
    janitor::clean_names() |>
    dplyr::filter(rige == "Plantae") |>
    dplyr::filter(taxonrang %in% c("Art", "Form", "Superart", "Underart", "Varietet")) |>
    dplyr::filter(herkomst != "Introduceret" | is.na(herkomst)) |>
    dplyr::select(videnskabeligt_navn, taxonrang) |>
    dplyr::distinct()
}


clean_species <- function(df){
  Clean_Species <- SDMWorkflows::Clean_Taxa(Taxons = df$videnskabeligt_navn)
}

filter_plants <- function(df){
  result <- df |>
    dplyr::filter(kingdom == "Plantae") |>
    dplyr::pull(species) |>
    unique() |>
    head(10)
  return(result)
}

get_plant_presences <- function(species){
  SDMWorkflows::GetOccs(Species = unique(species),
                        WriteFile = FALSE,
                        Log = FALSE,
                        country = "DK",
                        limit = 100000,
                        year='1999,2023')
}


Join_Presences <- function(List){
  DT <- data.table::rbindlist(List, fill = T)
  DT <-  DT[, .(scientificName, decimalLatitude, decimalLongitude, family, genus, species)]
  return(DT)
}

summarise_presences <- function(df){
  Sum <- as.data.table(df)[, .N, keyby = .(family, genus, species)]
  return(Sum)
}

Minimum_presences <- function(DT, n = 1){
  DT <- DT[N >= n]
  return(DT)
}

Select_Prescences <- function(Presences, speciesList){
  DT <- Presences[species %chin% speciesList]
  DT <- DT |>
    as.data.frame()# |>
    #dplyr::group_by(species)
  return(DT)
}

generate_tree <- function(DF){
  Tree <- as.data.frame(DF) |>
    dplyr::select(species, genus, family) |>
    dplyr::distinct() |>
    V.PhyloMaker::phylo.maker()
  return(Tree)
}

make_buffer_rasterized <- function(DT, file){
  Rast <- terra::rast(file)
  Result <- DT |>
    dplyr::select(decimalLatitude, decimalLongitude, family, genus, species) |>
    dplyr::mutate(presence = 1)

  Temp <- Result |> terra::vect(geom = c( "decimalLongitude", "decimalLatitude"), crs = "+proj=longlat +datum=WGS84") |>
    terra::project(terra::crs(Rast)) |>
    terra::buffer(500) |>
    terra::rasterize(Rast, field = "presence") |>
    terra::as.data.frame(cells = T) |>
    magrittr::set_colnames(c("cell", janitor::make_clean_names(unique(Result$species))))
  return(Temp)
}

SamplePresLanduse <- function(DF, file){
  Denmark_LU <- terra::rast(file)

  Temp <- DF |>
    dplyr::select(species, decimalLongitude, decimalLatitude) |>
    dplyr::mutate(Presence = 1) |>
    terra::vect(geom=c("decimalLongitude", "decimalLatitude"), crs = "epsg:4326") |>
    terra::project(terra::crs(Denmark_LU))

  Pres <- terra::extract(Denmark_LU, Temp) |>
    dplyr::mutate(Landuse = as.character(SN_ModelClass), Pres = 1) |>
    dplyr::filter(!is.na(Landuse))
  return(Pres)
}

DuplicateBoth <- function(DF){
  is_both <- stringr::str_detect(DF$Landuse, "Both")
  duplicated_rows1 <- DF[is_both, ]
  duplicated_rows2 <- DF[is_both, ]
  duplicated_rows1$Landuse <- stringr::str_replace_all(duplicated_rows1$Landuse, "Both", "Poor")
  duplicated_rows2$Landuse <- stringr::str_replace_all(duplicated_rows2$Landuse, "Both", "Rich")
  duplicated_rows <- bind_rows(duplicated_rows1, duplicated_rows2)
  DF <- DF[!is_both,] |>
    bind_rows(duplicated_rows)
  return(DF)
}
