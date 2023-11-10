get_data <- function(file) {
  readxl::read_xlsx(file) |>
    janitor::clean_names() |>
    dplyr::select(videnskabeligt_navn, taxonrang)
}


clean_species <- function(df){
  Clean_Species <- SDMWorkflows::Clean_Taxa(Taxons = df$videnskabeligt_navn)
}

filter_plants <- function(df){
  result <- df |>
    dplyr::filter(kingdom == "Plantae") |>
    dplyr::pull(species)
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


summarise_presences <- function(list){
  Sum <- list |>
    purrr::map(~as.data.table(.x[[1]])) |>
    purrr::map(~.x[, .N, keyby = .(scientificName, family, genus, species)]) |>
    data.table::rbindlist()
  return(Sum)
}


#mtcars |> dplyr::group_split(am) |>
#  purrr::map(~as.data.table(.x)) |>
#  purrr::map(~.x[, .N, keyby = .(cyl, gear)]) |>
#
