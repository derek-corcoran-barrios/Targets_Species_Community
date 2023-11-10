get_data <- function(file) {
  readxl::read_xlsx(file, col_types = cols()) |>
    janitor::clean_names() |>
    dplyr::select(videnskabeligt_navn, taxonrang)
}
