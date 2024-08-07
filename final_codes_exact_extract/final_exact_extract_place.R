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

# Define the extract for the place shapefiles
ext_place <- define_extract_nhgis(
  description = "place shapefiles request",
  shapefiles = "us_place_2022_tl2022"
)

# Send the extract request
ex_submitted_place <- submit_extract(ext_place)

# Check the status of the extract
ex_place_complete <- wait_for_extract(ex_submitted_place)
ex_place_complete$status
names(ex_place_complete$download_links)
is_extract_ready(ex_place_complete)

# Define the filepath for the census tract shapefiles
place_fp <- download_extract(ex_submitted_place)

# Open and read the census tract shapefiles
place <- read_ipums_sf(place_fp)

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
place_shp_data <- subset(place, !(STATEFP %in% not_cont_US))

# Transform to Albers Equal Area projection to match the NLCD CRS
place_shp_data <- st_transform(place_shp_data, crs(NLCD_2021))

# Define land cover classes and descriptions
land_cover_classes <- c(00, 11, 12, 21, 22, 23, 24, 31, 41, 42, 43, 52, 71, 81, 82, 90, 95)
land_cover_descriptions <- c(
  "No Data", "Open Water", "Perennial Ice/Snow", "Developed, Open Space", 
  "Developed, Low Intensity", "Developed, Medium Intensity", "Developed, High Intensity", 
  "Barren Land", "Deciduous Forest", "Evergreen Forest", "Mixed Forest", 
  "Shrub/Scrub", "Grassland/Herbaceous", "Pasture/Hay", "Cultivated Crops", 
  "Woody Wetlands", "Emergent Herbaceous Wetlands"
)

# Function to calculate land cover fractions for each place and year
calculate_fractions_place <- function(place_shp_data, NLCD_data, year) {
  # Extract fractions for each land cover class
  fractions <- exact_extract(NLCD_data, place_shp_data$geometry, "frac")
  
  # Add GISJOIN column from place_shp_data to fractions
  fractions$GISJOIN <- place_shp_data$GISJOIN
  
  # Add a column GEOGYEAR that specifies the source year of geographical shapefile
  fractions$GEOGYEAR <- "2022"
  
  # Add a column NLCDYEAR that specifies the year of NLCD data
  fractions$NLCDYEAR <- year
  
  # Shift the GISJOIN, GEOGYEAR, and NLCDYEAR columns to the front
  fractions <- fractions %>%
    select(GISJOIN, GEOGYEAR, NLCDYEAR, everything())
  
  return(fractions)
}

# Place fraction for each NLCD
place_fractions_2021 <- calculate_fractions_place(place_shp_data, NLCD_2021, "2021")
place_fractions_2019 <- calculate_fractions_place(place_shp_data, NLCD_2019, "2019")
place_fractions_2016 <- calculate_fractions_place(place_shp_data, NLCD_2016, "2016")
place_fractions_2013 <- calculate_fractions_place(place_shp_data, NLCD_2013, "2013")
place_fractions_2011 <- calculate_fractions_place(place_shp_data, NLCD_2011, "2011")
place_fractions_2008 <- calculate_fractions_place(place_shp_data, NLCD_2008, "2008")
place_fractions_2006 <- calculate_fractions_place(place_shp_data, NLCD_2006, "2006")
place_fractions_2004 <- calculate_fractions_place(place_shp_data, NLCD_2004, "2004")
place_fractions_2001 <- calculate_fractions_place(place_shp_data, NLCD_2001, "2001")

# List of place fractions dataframes and their corresponding years
place_fractions_list <- list(
  "2021" = place_fractions_2021,
  "2019" = place_fractions_2019,
  "2016" = place_fractions_2016,
  "2013" = place_fractions_2013,
  "2011" = place_fractions_2011,
  "2008" = place_fractions_2008,
  "2006" = place_fractions_2006,
  "2004" = place_fractions_2004,
  "2001" = place_fractions_2001
)

# Save each place fractions dataframe as a CSV file
for (year in names(place_fractions_list)) {
  write.csv(place_fractions_list[[year]], paste0("place_fractions_", year, ".csv"), row.names = FALSE)
}

# Function to calculate land cover fractions for each place and year
calculate_fractions_place <- function(place_shp_data, NLCD_data, year) {
  # Extract fractions for each land cover class
  fractions <- exact_extract(NLCD_data, place_shp_data$geometry, "frac")
  
  # Add GISJOIN column from place_shp_data to fractions
  fractions$GISJOIN <- place_shp_data$GISJOIN
  
  # Add a column GEOGYEAR that specifies the source year of geographical shapefile
  fractions$GEOGYEAR <- "2022"
  
  # Add a column NLCDYEAR that specifies the year of NLCD data
  fractions$NLCDYEAR <- year
  
  # Shift the GISJOIN, GEOGYEAR, and NLCDYEAR columns to the front
  fractions <- fractions %>%
    select(GISJOIN, GEOGYEAR, NLCDYEAR, everything())
  
  return(fractions)
}

# Rename columns in each dataframe
place_fractions_2021_renamed <- rename_columns(place_fractions_2021, "2021")
place_fractions_2019_renamed <- rename_columns(place_fractions_2019, "2019")
place_fractions_2016_renamed <- rename_columns(place_fractions_2016, "2016")
place_fractions_2013_renamed <- rename_columns(place_fractions_2013, "2013")
place_fractions_2011_renamed <- rename_columns(place_fractions_2011, "2011")
place_fractions_2008_renamed <- rename_columns(place_fractions_2008, "2008")
place_fractions_2006_renamed <- rename_columns(place_fractions_2006, "2006")
place_fractions_2004_renamed <- rename_columns(place_fractions_2004, "2004")
place_fractions_2001_renamed <- rename_columns(place_fractions_2001, "2001")

# List of renamed place fractions dataframes
place_fractions_renamed_list <- list(
  place_fractions_2021_renamed,
  place_fractions_2019_renamed,
  place_fractions_2016_renamed,
  place_fractions_2013_renamed,
  place_fractions_2011_renamed,
  place_fractions_2008_renamed,
  place_fractions_2006_renamed,
  place_fractions_2004_renamed,
  place_fractions_2001_renamed
)

# Remove the NLCDYEAR column from each dataframe in the list and remove GEOGYEAR from all but the first dataframe
place_fractions_renamed_list <- lapply(place_fractions_renamed_list, function(df) {
  df %>% select(-matches("^NLCDYEAR"))
})

place_fractions_renamed_list <- map2(place_fractions_renamed_list, seq_along(place_fractions_renamed_list), function(df, i) {
  if (i > 1) {
    df %>% select(-GEOGYEAR)
  } else {
    df
  }
})

# Merge all place fractions dataframes based on the GISJOIN column
merged_data <- reduce(place_fractions_renamed_list, left_join, by = "GISJOIN")

# Reorder columns to move GEOGYEAR right after GISJOIN
merged_data <- merged_data %>% select(GISJOIN, GEOGYEAR, everything())

# Save the merged dataframe as a CSV file
write.csv(merged_data, "merged_data_place.csv", row.names = FALSE)