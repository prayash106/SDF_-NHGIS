# Load required libraries
if (!require("exactextractr")) install.packages("exactextractr")
if (!require("terra")) install.packages("terra")
if (!require("sf")) install.packages("sf")
if (!require("ipumsr")) install.packages("ipumsr")
if (!require("tidyr")) install.packages("tidyr")
if (!require("dplyr")) install.packages("dplyr")
if (!require("writexl")) install.packages("writexl")

library(exactextractr)
library(terra)
library(sf)
library(ipumsr)
library(tidyr)
library(dplyr)
library(writexl)

#GEOGYEAR = 2020, name of shape file = tract
# Define the extract for the census tract shapefiles
ext_tract <- define_extract_nhgis(
  description = "census tract shapefiles request",
  shapefiles = "us_tract_2020_tl2020"
)

# Send the extract request
ex_submitted_tract <- submit_extract(ext_tract)

# Check the status of the extract
ex_tract_complete <- wait_for_extract(ex_submitted_tract)
ex_tract_complete$status
names(ex_tract_complete$download_links)
is_extract_ready(ex_tract_complete)

# Define the filepath for the census tract shapefiles
tract_fp <- download_extract(ex_submitted_tract)

# Open and read the census tract shapefiles
tract <- read_ipums_sf(tract_fp)

#GEOGYEAR = 2022, name of shape file = tract1
# Define the extract for the census tract shapefiles
ext_tract1 <- define_extract_nhgis(
  description = "census tract shapefiles request",
  shapefiles = "us_tract_2022_tl2022"
)

# Send the extract request
ex_submitted_tract1 <- submit_extract(ext_tract1)

# Check the status of the extract
ex_tract_complete1 <- wait_for_extract(ex_submitted_tract1)
ex_tract_complete1$status
names(ex_tract_complete1$download_links)
is_extract_ready(ex_tract_complete1)

# Define the filepath for the census tract shapefiles
tract_fp1 <- download_extract(ex_submitted_tract1)

# Open and read the census tract shapefiles
tract1 <- read_ipums_sf(tract_fp1)

# Load the NLCD files setting NLCD as working directory
NLCD_2021 <- rast("nlcd_2021_land_cover_l48_20230630.img")
NLCD_2019 <- rast("nlcd_2019_land_cover_l48_20210604.img")
NLCD_2016 <- rast("nlcd_2016_land_cover_l48_20210604.img")
NLCD_2013 <- rast("nlcd_2013_land_cover_l48_20210604.img")
NLCD_2011 <- rast("nlcd_2011_land_cover_l48_20210604.img")
NLCD_2008 <- rast("nlcd_2008_land_cover_l48_20210604.img")
NLCD_2006 <- rast("nlcd_2006_land_cover_l48_20210604.img")
NLCD_2004 <- rast("nlcd_2004_land_cover_l48_20210604.img")
NLCD_2001 <- rast("nlcd_2001_land_cover_l48_20210604.img")

# Remove non-contiguous US states and territories
not_cont_US <- c("02", "15", "72")
tract_shp_data <- subset(tract, !(STATEFP %in% not_cont_US))
#tract_shp_data1 <- subset(tract1, !(STATEFP %in% not_cont_US))

# Transform to Albers Equal Area projection to match the NLCD CRS
tract_shp_data <- st_transform(tract_shp_data, crs(NLCD_2021))
#tract_shp_data1 <- st_transform(tract_shp_data1, crs(NLCD_2021))

# Define land cover classes and descriptions
land_cover_classes <- c(00, 11, 12, 21, 22, 23, 24, 31, 41, 42, 43, 52, 71, 81, 82, 90, 95)
land_cover_descriptions <- c(
  "No Data", "Open Water", "Perennial Ice/Snow", "Developed, Open Space", 
  "Developed, Low Intensity", "Developed, Medium Intensity", "Developed, High Intensity", 
  "Barren Land", "Deciduous Forest", "Evergreen Forest", "Mixed Forest", 
  "Shrub/Scrub", "Grassland/Herbaceous", "Pasture/Hay", "Cultivated Crops", 
  "Woody Wetlands", "Emergent Herbaceous Wetlands"
)

#just like county we need to replace tract_shp_data with tract_shp_data1 for different GEOGYEAR
# Function to calculate land cover fractions for each census tract and year

calculate_fractions_tract <- function(tract_shp_data, NLCD_data, year) {
  # Extract fractions for each land cover class
  fractions <- exact_extract(NLCD_data, tract_shp_data$geometry, "frac")
  
  # Add GISJOIN column from tract_shp_data to fractions
  fractions$GISJOIN <- tract_shp_data$GISJOIN
  
  # Add a column GEOGYEAR that specifies the source year of geographical shape file
  fractions$GEOGYEAR <- "2020"
  
  # Add a column NLCDYEAR that specifies the year of NLCD data
  fractions$NLCDYEAR <- year
  
  # Shift the GISJOIN, GEOGYEAR, and NLCDYEAR columns to the front
  fractions <- fractions %>%
    select(GISJOIN, GEOGYEAR, NLCDYEAR, everything())
  
  return(fractions)
}

# Census tract fraction for each NLCD
tract_fractions_2021 <- calculate_fractions_tract(tract_shp_data, NLCD_2021, "2021")
tract_fractions_2019 <- calculate_fractions_tract(tract_shp_data, NLCD_2019, "2019")
tract_fractions_2016 <- calculate_fractions_tract(tract_shp_data, NLCD_2016, "2016")
tract_fractions_2013 <- calculate_fractions_tract(tract_shp_data, NLCD_2013, "2013")
tract_fractions_2011 <- calculate_fractions_tract(tract_shp_data, NLCD_2011, "2011")
tract_fractions_2008 <- calculate_fractions_tract(tract_shp_data, NLCD_2008, "2008")
tract_fractions_2006 <- calculate_fractions_tract(tract_shp_data, NLCD_2006, "2006")
tract_fractions_2004 <- calculate_fractions_tract(tract_shp_data, NLCD_2004, "2004")
tract_fractions_2001 <- calculate_fractions_tract(tract_shp_data, NLCD_2001, "2001")

# List of census tract fractions dataframes and their corresponding years
tract_fractions_list <- list(
  "2021" = tract_fractions_2021,
  "2019" = tract_fractions_2019,
  "2016" = tract_fractions_2016,
  "2013" = tract_fractions_2013,
  "2011" = tract_fractions_2011,
  "2008" = tract_fractions_2008,
  "2006" = tract_fractions_2006,
  "2004" = tract_fractions_2004,
  "2001" = tract_fractions_2001
)

# Save each census tract fractions dataframe as a CSV file
for (year in names(tract_fractions_list)) {
  write.csv(tract_fractions_list[[year]], paste0("tract_fractions_", year, ".csv"), row.names = FALSE)
}

# Function to rename columns by adding _year to the end, except GISJOIN, GEOGYEAR, and NLCDYEAR
rename_columns <- function(df, year) {
  # Select the first three column names (GISJOIN, GEOGYEAR, NLCDYEAR) without changing them
  unchanged_columns <- names(df)[1:3]
  
  # Select all column names from 4 to (ncol(df)) and append the year
  changed_columns <- paste0(names(df)[4:ncol(df)], "_", year)
  
  # Combine unchanged and changed columns
  new_column_names <- c(unchanged_columns, changed_columns)
  
  # Assign new column names to the dataframe
  colnames(df) <- new_column_names
  
  return(df)
}

# Rename columns in each dataframe
tract_fractions_2021_renamed <- rename_columns(tract_fractions_2021, "2021")
tract_fractions_2019_renamed <- rename_columns(tract_fractions_2019, "2019")
tract_fractions_2016_renamed <- rename_columns(tract_fractions_2016, "2016")
tract_fractions_2013_renamed <- rename_columns(tract_fractions_2013, "2013")
tract_fractions_2011_renamed <- rename_columns(tract_fractions_2011, "2011")
tract_fractions_2008_renamed <- rename_columns(tract_fractions_2008, "2008")
tract_fractions_2006_renamed <- rename_columns(tract_fractions_2006, "2006")
tract_fractions_2004_renamed <- rename_columns(tract_fractions_2004, "2004")
tract_fractions_2001_renamed <- rename_columns(tract_fractions_2001, "2001")

# List of renamed census tract fractions dataframes
tract_fractions_renamed_list <- list(
  tract_fractions_2021_renamed,
  tract_fractions_2019_renamed,
  tract_fractions_2016_renamed,
  tract_fractions_2013_renamed,
  tract_fractions_2011_renamed,
  tract_fractions_2008_renamed,
  tract_fractions_2006_renamed,
  tract_fractions_2004_renamed,
  tract_fractions_2001_renamed
)

# Remove the NLCDYEAR column from each dataframe in the list and remove GEOGYEAR from all but the first dataframe
tract_fractions_renamed_list <- lapply(tract_fractions_renamed_list, function(df) {
  df %>% select(-matches("^NLCDYEAR"))
})

tract_fractions_renamed_list <- map2(tract_fractions_renamed_list, seq_along(tract_fractions_renamed_list), function(df, i) {
  if (i > 1) {
    df %>% select(-GEOGYEAR)
  } else {
    df
  }
})

# Merge all census tract fractions dataframes based on the GISJOIN column
merged_data <- reduce(tract_fractions_renamed_list, left_join, by = "GISJOIN")

# Reorder columns to move GEOGYEAR right after GISJOIN
merged_data <- merged_data %>% select(GISJOIN, GEOGYEAR, everything())

# Save the merged dataframe as a CSV file
write.csv(merged_data, "merged_data_tract.csv", row.names = FALSE)