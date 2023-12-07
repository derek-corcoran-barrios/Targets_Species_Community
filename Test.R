library(targets)
library(data.table)
# data.table with 2 columns cell (spatial id) and species, the species that can
# migrate to said cell
Long_Buffer <- tar_read("Long_Buffer", branches = 1)

saveRDS(Long_Buffer, "Long_Buffer.rds")
# THere is one long_buffer data.table per species

# data.table with 2 columns  species, the species that can migrate to said cell
# And landuse, the landuse where said species can exist, landuse covers
#"ForestDryRich", "ForestDryPoor", "ForestWetRich", "ForestWetPoor", "OpenDryRich", "OpenDryPoor", "OpenWetPoor", "OpenWetRich"
LookUpTable <- tar_read("LookUpTable")


# data.table with 2 columns cell (spatial id) and Habitat, a class that covers landuse which covers
# "DryPoor", "DryRich", "WetPoor", "WetRich", this says which habitat can exist in which cell
# DryPoor habtat covers both  ForestDryPoor and OpenDryPoor in landuse

Long_LU_table <- tar_read("Long_LU_table")
Long_LU_table <- Long_LU_table[, Habitat := as.character(Habitat)]
# Long buffer checks which cells can be reached by a species by dispersal, Lookup table checks
# which landuse can exist in each spatial cell, and Long_LU_table, shows which habitats are feasible
# To exist in each cell, as an example



# Then check feasible habitats for the particular species

Feasible_Landuses <- LookUpTable[species %in% unique(Long_Buffer$species)]

#Transform Landuse into habitat and  remove the pres
Feasible_Landuses[, Habitat := stringr::str_remove_all(Landuse, "Forest")]
Feasible_Landuses[, Habitat := stringr::str_remove_all(Habitat, "Open")]
Feasible_Landuses[, Pres := NULL]

# From Long_LU_table get only the cells that can become the feasible Landuses
Available_Cells <- Long_LU_table[Habitat %chin% unique(Feasible_Landuses$Habitat)]

# Finally check which of the available cells for the species can be in a habitat suitable for the species
FeasibleCells <- Long_Buffer[cell %chin% unique(Available_Cells$cell)]


## NOw join all three data.tables FeasibleCells, Available_Cells and Feasible_Landuses

result <- FeasibleCells[Available_Cells, on = "cell", nomatch = 0]

small_result <-


# Perform the non-equi join on "Habitat" and "species" columns
result2 <- result[Feasible_Landuses, on = .(Habitat, species), nomatch = 0]

readr::write_csv(result, "result.csv")
readr::write_csv(Feasible_Landuses, "Feasible_Landuses.csv")


# Discard the "Habitat" column
result2[, Habitat := NULL]
