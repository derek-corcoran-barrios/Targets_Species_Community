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
    head(100)
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
    magrittr::set_colnames(c("cell", stringr::str_replace_all(unique(Result$species), " ", "_")))
  return(Temp)
}


make_long_buffer <- function(DT){
  DT <- as.data.table(DT)
  Species <- stringr::str_replace_all(colnames(DT)[2], "_", " ")
  DT[, .(cell, species = Species)]
}

Join_long_buffer <- function(List){
  DT <- data.table::rbindlist(List, fill = T)
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

  Pres$species <- unique(Temp$species)
  return(Pres)
}

SampleBGLanduse <- function(DF, file){
  Denmark_LU <- terra::rast(file)

  Temp <- DF |>
    dplyr::select(species, decimalLongitude, decimalLatitude) |>
    terra::vect(geom=c("decimalLongitude", "decimalLatitude"), crs = "epsg:4326") |>
    terra::project(terra::crs(Denmark_LU))

  BG <- Denmark_LU |>
    terra::crop(Convex_20(as.data.frame(Temp, geom = "xy"), lon = "x", lat = "y",
                          proj = terra::crs(Denmark_LU))) |>
    terra::spatSample(10000, na.rm = T) |>
    dplyr::mutate(Landuse = as.character(SN_ModelClass), Pres = 0) |>
    dplyr::filter(!is.na(Landuse))
  BG$species <- unique(Temp$species)
  return(BG)
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

ModelSpecies <- function(DF){
  All <- DF |> dplyr::mutate(Landuse = as.factor(Landuse))
  Data <- dplyr::select(All, Landuse)
  # Factor is made into dummy vars
  if(length(table(Data$Landuse)) > 1){
    Landuse_matrix <- model.matrix(~ Landuse - 1, data = Data)
  }


  # Use tryCatch for model fitting
  Mod <- tryCatch(
    maxnet::maxnet(p = All$Pres, data = as.data.frame(Landuse_matrix)),
    error = function(e) {
      cat("Error in model fitting:", conditionMessage(e), "\n")
      return(NULL)  # Return NULL if model fitting fails
    }
  )

  if (is.null(Mod)) {
    # Model fitting failed, set Preds$Pred to a column of 0s
    Preds <- data.frame(Landuse = unique(as.factor(All$Landuse)), Pred = 0, species = unique(All$species))
  } else {
    # Model fitting succeeded, proceed with prediction
    Preds <- Landuse_matrix |> as.data.frame() |> distinct()
    Preds$Pred <- tryCatch(
      predict(Mod, Preds, type = "cloglog") |> as.vector(),
      error = function(e) {
        cat("Error in prediction:", conditionMessage(e), "\n")
        return(rep(0, nrow(Preds)))  # Return a column of 0s if prediction fails
      }
    )
    Preds <- Preds |>
      tidyr::pivot_longer(-Pred, names_to = "Landuse", values_to = "Pres") |>
      dplyr::filter(Pres == 1) |>
      mutate(Landuse = stringr::str_remove_all(Landuse, "Landuse")) |>
      arrange(desc(Pred)) |>
      dplyr::select(-Pres)
  }

  Preds$species <- unique(All$species)

  return(Preds)
}



create_thresholds <- function(Model, reference){
  Thres <- data.frame(species = unique(Model$species),Thres_99 = NA, Thres_95 = NA, Thres_90 = NA)
  Thres$Thres_99 <- reference |>
    dplyr::left_join(Model) |>
    dplyr::filter(Pres == 1) |>
    slice_max(order_by = Pred,prop = 0.99, with_ties = F) |>
    pull(Pred) |>
    min()

  Thres$Thres_95 <- reference |>
    dplyr::left_join(Model) |>
    dplyr::filter(Pres == 1) |>
    slice_max(order_by = Pred,prop = 0.95, with_ties = F) |>
    pull(Pred) |>
    min()

  Thres$Thres_90 <- reference |>
    dplyr::left_join(Model) |>
    dplyr::filter(Pres == 1) |>
    slice_max(order_by = Pred,prop = 0.90, with_ties = F) |>
    pull(Pred) |>
    min()

  return(Thres)
}

Generate_Lookup <- function(Model, Thresholds) {
  joined_data <- merge(as.data.table(Model), as.data.table(Thresholds), by = c("species"), all = TRUE)
  joined_data[, Pres := ifelse(Pred > Thres_95, 1, 0)]
  joined_data <- joined_data[Pres > 0]  # Assign the filtered result to joined_data
  joined_data[, .(species, Landuse, Pres)]  # Return the selected columns
}


generate_landuse_table <- function(path){
  Names <- path |>
    stringr::str_remove_all("HabSut/RF_predict_binary_") |>
    stringr::str_remove_all("_thresh_5.tif")
  DF <- terra::rast(path) |>
    terra::as.data.frame(cells = T) |>
    dplyr::filter(layer == 1)
  colnames(DF)[2] <- Names
  return(DF)
}


Make_Long_LU_table <- function(DF){
  DF <-  as.data.table(DF) |> melt(id.vars       = "cell",
                                   measure.vars  = c("DryPoor", "DryRich", "WetPoor", "WetRich"),
                                   variable.name = "Habitat",
                                   value.name    = "Suitability", na.rm = T)
  DF <- DF[, Suitability := NULL]
  return(DF)
}

make_final_presences <- function(Long_LU_table, Long_Buffer, LookUpTable) {

  # Modify Long_LU_table
  Long_LU_table[, Habitat := as.character(Habitat)]

  # Check feasible habitats for the particular species
  Feasible_Landuses <- LookUpTable[species %in% unique(Long_Buffer$species)]

  # Transform Landuse into habitat and remove the prefix
  Feasible_Landuses[, Habitat := stringr::str_remove_all(Landuse, "Forest")]
  Feasible_Landuses[, Habitat := stringr::str_remove_all(Habitat, "Open")]
  Feasible_Landuses[, Pres := NULL]

  # Get only the cells that can become the feasible Landuses
  Available_Cells <- Long_LU_table[Habitat %chin% unique(Feasible_Landuses$Habitat)]

  # Check which of the available cells for the species can be in a habitat suitable for the species
  FeasibleCells <- Long_Buffer[cell %chin% unique(Available_Cells$cell)]

  # Join all three data.tables
  result <- FeasibleCells[Available_Cells, on = "cell", nomatch = 0]
  result2 <- result[Feasible_Landuses, on = .(Habitat, species), nomatch = 0, allow.cartesian = TRUE]
  result2[, Habitat := NULL]

  # Return the final result
  return(result2)
}

GetRichness <- function(df){
  Sum <- df[, .N, keyby = .(cell, Landuse)]
  return(Sum)
}

Join_Final_Presences <- function(List){
  DT <- data.table::rbindlist(List, fill = T)
}


calc_pd <- function(Fin, Tree){
  Fin <- as.data.table(Fin)
  Leaves <- Tree$scenario.3$tip.label
  Landuse <- unique(Fin$Landuse)
  Fin[,Pres := 1]
  Fin[, species := stringr::str_replace_all(species, " ", "_")]

  Fin2 <- dcast(Fin, cell~species, value.var="Pres", fill = 0)
  Index <- which(colnames(Fin2) %in% Leaves)
  Mat <- as.matrix(Fin2)[,Index]

  PD <- picante::pd(samp = Mat, Tree$scenario.3, include.root = F) |>
    as.data.table()
  PD[, PD := ifelse(is.na(PD), 0 , PD)]

  PD$cell <- Fin2$cell
  PD$Landuse <- Landuse
  return(PD)
}
