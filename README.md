# README - 2024 ISRDI SDF - NHGIS

This repository details the code and output of the [2024 ISDRI SDF - NHGIS](https://isrdi.umn.edu/summer-2024-projects) project. The main objective of this project is to construct small-area environmental summaries that will be disseminated through IPUMS NHGIS. The output files contain a replicable data processing pipeline in R that:

1. Acquires environmental data, including land cover and climate information, for the United States.
2. Acquires GIS data describing the boundaries of different geographic units, including counties, cities, census tracts, and places.
3. Creates summary measures of land cover for these geographic units (extendable to other measures like climate).
4. Creates output files for dissemination via [IPUMS NHGIS](https://www.nhgis.org/environmental-summaries).

Key outcomes of the project include environmental summary data and a code repository.

This repository provides instructions and code used for the above mentioned project. We do this for two reasons. First, we believe in transparency and want to provide users with the chance to check our work. Second, while we think our summaries are generally useful for scientists, we understand that people may want to customize summaries for their particular analyses. They can use our code as the basis for creating customized summaries.

## Required R Packages
The code relies on a number of R packages. We recommend users install the following packages before they run any of the scripts:

tidyverse: Our code leverages many functions provided by the packages in the tidyverse collection.

ipumsr: We use the ipumsr package to programmatically access IPUMS metadata and generate, submit, and download IPUMS extracts.

exactextractr: We use the exactextractr package to extract summary data from raster datasets.

sf: We use the sf package for handling and analyzing spatial data.

terra: We use the terra package for working with raster data.

dplyr: We use the dplyr package for data manipulation.

tidyr: We use the tidyr package for data tidying.

writexl: We use the writexl package to write Excel files.

The ipumsr package uses IPUMS' Application Programming Interface (API), which requires a key. If you do not have an IPUMS API key, we recommend reading the instructions provided in the Introduction to the IPUMS API for R Users [article](https://tech.popdata.org/ipumsr/articles/ipums-api.html).

## Data Sources
NHGIS environmental summaries draw on a variety of different data sources. We import polygon mapping file depicting the footprints/boundaries of geographic units (e.g, counties, cities, states) from [IPUMS NHGIS](https://www.nhgis.org/data-availability#gis-files). Likewise, the environmental dataset (likely be a raster dataset) describing environmental characteristic (e.g., land cover, climate) are imported from [MRLC](https://www.mrlc.gov/data).

## Processing Pipeline
### 1. Data Acquisition
We acquire input data necessary for each measure through programmatic means using R packages (e.g., ipumsr for IPUMS extracts) or by downloading files from specified sources. 

### 2. Data Processing
Once the data is acquired, the processing involves the following steps:

Acquiring GIS Data: Obtain county-level shapefiles for various years and land cover data from sources such as the National Land Cover Database (NLCD).

Transforming Data: Filter out non-contiguous US states and align the coordinate reference systems of the GIS data to match the land cover data.

Calculating Summary Measures: For each year of land cover data, calculate the land cover fractions by overlaying it with the county-level shapefiles using the exactextract package. The results include summaries of land cover classes for each geographic unit.

### 3. Output Generation
Output the processed data to CSV files for each year, followed by merging them together to a single file. Repeat the same process for any geographic unit of choice.

## Team Members

### Mentors
- David Van Riper (IPUMS) - vanriper@umn.edu
- Steve Manson (Geography, Environment & Society) - manson@umn.edu

### Fellows
- Prayash Pathak Chalise (Graduate Fellow - Applied Economics) - patha106@umn.edu
- Saemi Lee (Undergraduate Fellow - Geography, Environment & Society) - lee03023@umn.edu

### Honorary Fellow
- Kate Vavra-Musser (Post-doc) - katevavramu@umn.edu

