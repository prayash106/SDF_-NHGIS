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

#GEOGYEAR = 2020, name of shape file = counties
#specify extract definition
nhgis_ext <- define_extract_nhgis(
  description = "Example shapefiles request",
  shapefiles = "us_county_2020_tl2020"
)

#submit extract for processing
nhgis_ext_submitted <- submit_extract(nhgis_ext)     

#extract status check
nhgis_ext_complete <- wait_for_extract(nhgis_ext_submitted)
nhgis_ext_complete$status
names(nhgis_ext_complete$download_links)
is_extract_ready(nhgis_ext_submitted)

#download extract
filepath <- download_extract(nhgis_ext_submitted)

#open and read the shape file
counties<- read_ipums_sf(filepath)

#GEOGYEAR = 2022, name of shape file = counties1
#specify extract definition
nhgis_ext1 <- define_extract_nhgis(
  description = "Example shapefiles request",
  shapefiles = "us_county_2022_tl2022"
)

#submit extract for processing
nhgis_ext_submitted1 <- submit_extract(nhgis_ext1)     

#extract status check
nhgis_ext_complete1 <- wait_for_extract(nhgis_ext_submitted1)
nhgis_ext_complete1$status
names(nhgis_ext_complete1$download_links)
is_extract_ready(nhgis_ext_submitted1)

#download extract
filepath1 <- download_extract(nhgis_ext_submitted1)

#open and read the shape file
counties1<- read_ipums_sf(filepath1)

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

#create a new folder called result which will be the new working directory from here on
# Remove non-contiguous US states and territories
not_cont_US <- c("02", "15", "72")
county_shp_data <- subset(counties, !(STATEFP %in% not_cont_US))
#county_shp_data1 <- subset(counties1, !(STATEFP %in% not_cont_US))

# Transform to Albers Equal Area projection to match the NLCD CRS
county_shp_data <- st_transform(county_shp_data, crs(NLCD_2021))
#county_shp_data1 <- st_transform(county_shp_data1, crs(NLCD_2021))

# Define land cover classes and descriptions
land_cover_classes <- c(00, 11, 12, 21, 22, 23, 24, 31, 41, 42, 43, 52, 71, 81, 82, 90, 95)
land_cover_descriptions <- c(
  "No Data", "Open Water", "Perennial Ice/Snow", "Developed, Open Space", 
  "Developed, Low Intensity", "Developed, Medium Intensity", "Developed, High Intensity", 
  "Barren Land", "Deciduous Forest", "Evergreen Forest", "Mixed Forest", 
  "Shrub/Scrub", "Grassland/Herbaceous", "Pasture/Hay", "Cultivated Crops", 
  "Woody Wetlands", "Emergent Herbaceous Wetlands"
)

#a reminder to replace county_shp_data with county_shp_data1 parameter if GEOGYEAR = 2022
# and also use different output name for different GEOGYEAR

# Function to calculate land cover fractions for each county and year
calculate_fractions_county <- function(county_shp_data, NLCD_data, year) {
  # Extract fractions for each land cover class
  fractions <- exact_extract(NLCD_data, county_shp_data$geometry, "frac")
  
  # Add GISJOIN column from county_shp_data to fractions
  fractions$GISJOIN <- county_shp_data$GISJOIN
  
  # Add a column GEOGYEAR that specifies the source year of geographical shapefile
  fractions$GEOGYEAR <- "2020"
  
  # Add a column NLCDYEAR that specifies the year of NLCD data
  fractions$NLCDYEAR <- year
  
  # Shift the GISJOIN, GEOGYEAR, and NLCDYEAR columns to the front
  fractions <- fractions %>%
    select(GISJOIN, GEOGYEAR, NLCDYEAR, everything())
  
  return(fractions)
}

# County fraction for each NLCD
county_fractions_2021 <- calculate_fractions_county(county_shp_data, NLCD_2021, "2021")
county_fractions_2019 <- calculate_fractions_county(county_shp_data, NLCD_2019, "2019")
county_fractions_2016 <- calculate_fractions_county(county_shp_data, NLCD_2016, "2016")
county_fractions_2013 <- calculate_fractions_county(county_shp_data, NLCD_2013, "2013")
county_fractions_2011 <- calculate_fractions_county(county_shp_data, NLCD_2011, "2011")
county_fractions_2008 <- calculate_fractions_county(county_shp_data, NLCD_2008, "2008")
county_fractions_2006 <- calculate_fractions_county(county_shp_data, NLCD_2006, "2006")
county_fractions_2004 <- calculate_fractions_county(county_shp_data, NLCD_2004, "2004")
county_fractions_2001 <- calculate_fractions_county(county_shp_data, NLCD_2001, "2001")

# List of county fractions dataframes and their corresponding years
county_fractions_list <- list(
  "2021" = county_fractions_2021,
  "2019" = county_fractions_2019,
  "2016" = county_fractions_2016,
  "2013" = county_fractions_2013,
  "2011" = county_fractions_2011,
  "2008" = county_fractions_2008,
  "2006" = county_fractions_2006,
  "2004" = county_fractions_2004,
  "2001" = county_fractions_2001
)

# Save each county fractions dataframe as a CSV file
for (year in names(county_fractions_list)) {
  write.csv(county_fractions_list[[year]], paste0("county_fractions_", year, ".csv"), row.names = FALSE)
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
county_fractions_2021_renamed <- rename_columns(county_fractions_2021, "2021")
county_fractions_2019_renamed <- rename_columns(county_fractions_2019, "2019")
county_fractions_2016_renamed <- rename_columns(county_fractions_2016, "2016")
county_fractions_2013_renamed <- rename_columns(county_fractions_2013, "2013")
county_fractions_2011_renamed <- rename_columns(county_fractions_2011, "2011")
county_fractions_2008_renamed <- rename_columns(county_fractions_2008, "2008")
county_fractions_2006_renamed <- rename_columns(county_fractions_2006, "2006")
county_fractions_2004_renamed <- rename_columns(county_fractions_2004, "2004")
county_fractions_2001_renamed <- rename_columns(county_fractions_2001, "2001")

# List of renamed county fractions dataframes
county_fractions_renamed_list <- list(
  county_fractions_2021_renamed,
  county_fractions_2019_renamed,
  county_fractions_2016_renamed,
  county_fractions_2013_renamed,
  county_fractions_2011_renamed,
  county_fractions_2008_renamed,
  county_fractions_2006_renamed,
  county_fractions_2004_renamed,
  county_fractions_2001_renamed
)

# Remove the NLCDYEAR column from each dataframe in the list and remove GEOGYEAR from all but the first dataframe
county_fractions_renamed_list <- lapply(county_fractions_renamed_list, function(df) {
  df %>% select(-matches("^NLCDYEAR"))
})
county_fractions_renamed_list <- map2(county_fractions_renamed_list, seq_along(county_fractions_renamed_list), function(df, i) {
  if (i > 1) {
    df %>% select(-GEOGYEAR)
  } else {
    df
  }
})

# Merge all county fractions dataframes based on the GISJOIN column
merged_data <- reduce(county_fractions_renamed_list, left_join, by = "GISJOIN")

# Reorder columns to move GEOGYEAR right after GISJOIN
merged_data <- merged_data %>% select(GISJOIN, GEOGYEAR, everything())

# Save the merged dataframe as a CSV file
write.csv(merged_data, "merged_data_county.csv", row.names = FALSE)