get_data <- function(file) {
  readxl::read_xlsx(file) |>
    janitor::clean_names() |>
    dplyr::filter(rige == "Plantae") |>
    dplyr::filter(taxonrang %in% c("Art", "Form", "Superart", "Underart", "Varietet")) |>
    dplyr::filter(herkomst != "Introduceret" | is.na(herkomst)) |>
    dplyr::select(videnskabeligt_navn, taxonrang) |>
    dplyr::distinct()
}

read_raster <- function(file) {
  Result <- terra::wrap(terra::rast(file))
  return(Result)
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


summarise_presences <- function(df){
  Sum <- as.data.table(df)[, .N, keyby = .(family, genus, species)]
  return(Sum)
}


generate_tree <- function(DF){
  Tree <- as.data.frame(DF) |>
    dplyr::select(species, genus, family) |>
    dplyr::distinct() |>
    V.PhyloMaker::phylo.maker()
  return(Tree)
}

make_buffer_rasterized <- function(DF, raster){
#  Rast <- terra::unwrap(raster)
  Result <- DF |>
    dplyr::select(decimalLatitude, decimalLongitude, family, genus, species) |>
    terra::vect(geom = c( "decimalLongitude", "decimalLatitude"), crs = "+proj=longlat +datum=WGS84") |>
    terra::project(terra::crs(Rast)) |>
    terra::buffer(500) |>
    terra::rasterize(Rast) |>
    terra::as.data.frame(cells = T)
  return(Result)
}
