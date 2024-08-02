# README - 2024 ISRDI SDF - NHGIS

This repository details the code and output of the [2024 ISDRI SDF - NHGIS](https://isrdi.umn.edu/summer-2024-projects). The main objective of this project is to construct small-area environmental summaries that will be disseminated through IPUMS NHGIS. The output files contain a replicable data processing pipeline in R that:

1. Acquires environmental data, including land cover and climate information, for the United States.
2. Acquires GIS data describing the boundaries of different geographic units, including counties, cities, census tracts, and places.
3. Creates summary measures of land cover for counties, cities, and census tracts (extendable to other measures like climate).
4. Creates output files for dissemination via [IPUMS NHGIS](https://www.nhgis.org/environmental-summaries).

Key outcomes of the project include environmental summary data and a code repository.

We created land cover summaries from the National Land Cover Database ([NLCD](https://www.mrlc.gov)) for the following geographic units:
- 2020 and 2022 US counties
- 2020 and 2022 US census tracts
- 2022 Core-Based Statistical Areas (CBSAs)
- 2022 place points

The core workflow of our code involves the use of the [ipumsr](https://tech.popdata.org/ipumsr/) package to extract the boundary files for our geographic unit of choice, followed by the use of the [exactextractr](https://github.com/isciences/exactextractr) package to extract the summary data for all [epochs](https://www.mrlc.gov/data) and 22 [land cover classes](https://www.mrlc.gov/data/legends/national-land-cover-database-class-legend-and-description) of NLCD.

The main output of the project is a CSV file containing these environmental summaries, ready to be disseminated via IPUMS NHGIS. The code first generates time-varied file outputs for all epochs of NLCD, followed immediately by a merged CSV file of these epochs. We also provide a codebook describing the rows and columns of the dataset, which should be referred to for detailed information.

## Team Members

### Mentors
- David Van Riper (IPUMS) - vanriper@umn.edu
- Steve Manson (Geography, Environment & Society) - manson@umn.edu

### Fellows
- Prayash Pathak Chalise (Graduate Fellow - Applied Economics) - patha106@umn.edu
- Saemi Lee (Undergraduate Fellow - Geography, Environment & Society) - lee03023@umn.edu

### Honorary Fellow
- Kate Vavra-Musser (Post-doc) - katevavramu@umn.edu

