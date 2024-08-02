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

# Define the extract for the CBSA shapefiles
ext_cbsa <- define_extract_nhgis(
  description = "CBSA shapefiles request",
  shapefiles = "us_cbsa_2022_tl2021"
)

# Send the extract request
ex_submitted_cbsa <- submit_extract(ext_cbsa)

# Check the status of the extract
ex_cbsa_complete <- wait_for_extract(ex_submitted_cbsa)
ex_cbsa_complete$status
names(ex_cbsa_complete$download_links)
is_extract_ready(ex_cbsa_complete)

# Define the filepath for the CBSA shapefiles
cbsa_fp <- download_extract(ex_submitted_cbsa)

# Open and read the CBSA shapefiles
cbsa <- read_ipums_sf(cbsa_fp)

# Load the NLCD files
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
not_cont_US <- c("AK", "HI", "PR")  # State abbreviations for Alaska, Hawaii, and Puerto Rico

# Function to extract state abbreviations from the Name column
extract_state <- function(name) {
  # Split the name by comma and extract the second part (state abbreviation)
  state_abbreviation <- trimws(strsplit(name, ",")[[1]][2])
  return(state_abbreviation)
}

# Apply the function to create a new column with state abbreviations
cbsa$STATE <- sapply(cbsa$NAME, extract_state)

# Subset the data to remove non-contiguous US states and territories
cbsa_shp_data <- subset(cbsa, !(STATE %in% not_cont_US))

# Remove the temporary STATE column
cbsa_shp_data <- cbsa_shp_data %>% select(-STATE)

# Transform to Albers Equal Area projection to match the NLCD CRS
cbsa_shp_data <- st_transform(cbsa_shp_data, crs(NLCD_2021))

# Function to calculate land cover fractions for each CBSA and year
calculate_fractions_cbsa <- function(cbsa_shp_data, NLCD_data, year) {
  # Extract fractions for each land cover class
  fractions <- exact_extract(NLCD_data, cbsa_shp_data$geometry, "frac")
  
  # Add GISJOIN column from cbsa_shp_data to fractions
  fractions$GISJOIN <- cbsa_shp_data$GISJOIN
  
  # Add a column GEOGYEAR that specifies the source year of geographical shapefile
  fractions$GEOGYEAR <- "2022"
  
  # Add a column NLCDYEAR that specifies the year of NLCD data
  fractions$NLCDYEAR <- year
  
  # Shift the GISJOIN, GEOGYEAR, and NLCDYEAR columns to the front
  fractions <- fractions %>%
    select(GISJOIN, GEOGYEAR, NLCDYEAR, everything())
  
  return(fractions)
}

# CBSA fraction for each NLCD
cbsa_fractions_2021 <- calculate_fractions_cbsa(cbsa_shp_data, NLCD_2021, "2021")
cbsa_fractions_2019 <- calculate_fractions_cbsa(cbsa_shp_data, NLCD_2019, "2019")
cbsa_fractions_2016 <- calculate_fractions_cbsa(cbsa_shp_data, NLCD_2016, "2016")
cbsa_fractions_2013 <- calculate_fractions_cbsa(cbsa_shp_data, NLCD_2013, "2013")
cbsa_fractions_2011 <- calculate_fractions_cbsa(cbsa_shp_data, NLCD_2011, "2011")
cbsa_fractions_2008 <- calculate_fractions_cbsa(cbsa_shp_data, NLCD_2008, "2008")
cbsa_fractions_2006 <- calculate_fractions_cbsa(cbsa_shp_data, NLCD_2006, "2006")
cbsa_fractions_2004 <- calculate_fractions_cbsa(cbsa_shp_data, NLCD_2004, "2004")
cbsa_fractions_2001 <- calculate_fractions_cbsa(cbsa_shp_data, NLCD_2001, "2001")

# List of CBSA fractions dataframes and their corresponding years
cbsa_fractions_list <- list(
  "2021" = cbsa_fractions_2021,
  "2019" = cbsa_fractions_2019,
  "2016" = cbsa_fractions_2016,
  "2013" = cbsa_fractions_2013,
  "2011" = cbsa_fractions_2011,
  "2008" = cbsa_fractions_2008,
  "2006" = cbsa_fractions_2006,
  "2004" = cbsa_fractions_2004,
  "2001" = cbsa_fractions_2001
)

# Save each CBSA fractions dataframe as a CSV file
for (year in names(cbsa_fractions_list)) {
  write.csv(cbsa_fractions_list[[year]], paste0("cbsa_fractions_", year, ".csv"), row.names = FALSE)
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
cbsa_fractions_2021_renamed <- rename_columns(cbsa_fractions_2021, "2021")
cbsa_fractions_2019_renamed <- rename_columns(cbsa_fractions_2019, "2019")
cbsa_fractions_2016_renamed <- rename_columns(cbsa_fractions_2016, "2016")
cbsa_fractions_2013_renamed <- rename_columns(cbsa_fractions_2013, "2013")
cbsa_fractions_2011_renamed <- rename_columns(cbsa_fractions_2011, "2011")
cbsa_fractions_2008_renamed <- rename_columns(cbsa_fractions_2008, "2008")
cbsa_fractions_2006_renamed <- rename_columns(cbsa_fractions_2006, "2006")
cbsa_fractions_2004_renamed <- rename_columns(cbsa_fractions_2004, "2004")
cbsa_fractions_2001_renamed <- rename_columns(cbsa_fractions_2001, "2001")

# List of renamed CBSA fractions dataframes
cbsa_fractions_renamed_list <- list(
  cbsa_fractions_2021_renamed,
  cbsa_fractions_2019_renamed,
  cbsa_fractions_2016_renamed,
  cbsa_fractions_2013_renamed,
  cbsa_fractions_2011_renamed,
  cbsa_fractions_2008_renamed,
  cbsa_fractions_2006_renamed,
  cbsa_fractions_2004_renamed,
  cbsa_fractions_2001_renamed
)

# Remove the NLCDYEAR column from each dataframe in the list and remove GEOGYEAR from all but the first dataframe
cbsa_fractions_renamed_list <- lapply(cbsa_fractions_renamed_list, function(df) {
  df %>% select(-matches("^NLCDYEAR"))
})

cbsa_fractions_renamed_list <- map2(cbsa_fractions_renamed_list, seq_along(cbsa_fractions_renamed_list), function(df, i) {
  if (i > 1) {
    df %>% select(-GEOGYEAR)
  } else {
    df
  }
})

# Merge all CBSA fractions dataframes based on the GISJOIN column
merged_data <- reduce(cbsa_fractions_renamed_list, left_join, by = "GISJOIN")

# Reorder columns to move GEOGYEAR right after GISJOIN
merged_data <- merged_data %>% select(GISJOIN, GEOGYEAR, everything())

# Save the merged dataframe as a CSV file
write.csv(merged_data, "merged_data_cbsa.csv", row.names = FALSE)