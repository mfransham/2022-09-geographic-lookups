# create geographic lookup tables between historic small area geographies and modern TTWAs/LADs


# packages ----------------------------------------------------------------------------

library(sf)
library(tidyverse)
library(mapview)


# modern geographies to match to ------------------------------------------------------

# TTWA
# from https://geoportal.statistics.gov.uk/search?collection=Dataset&sort=name&tags=all(BDY_TTWA%2CDEC_2011)
ttwa2011 <- st_read("../../Data/Boundaries/Travel_to_Work_Areas_December_2011_Generalised_Clipped_Boundaries_in_United_Kingdom")
ttwa2011 %>% st_geometry() %>% plot()
# mapview(ttwa2011)

# local authority districts (363, as at April 2021)
# from https://geoportal.statistics.gov.uk/search?collection=Dataset&sort=name&tags=all(BDY_LAD%2CDEC_2021)
lad2021 <- st_read("../../Data/Boundaries/Local_Authority_Districts_(December_2021)_GB_BGC")

# English region and country 
# from https://geoportal.statistics.gov.uk/search?collection=Dataset&sort=name&tags=all(BDY_ITL1%2CJAN_2021)
region <- st_read("../../Data/Boundaries/International_Territorial_Level_1_(January_2021)_UK_BGC")


# 1981 Census geographies --------------------------------------------------------------------------------

# these boundaries downloaded from https://borders.ukdataservice.ac.uk/easy_download.html
# England and Wales are wards; Scotland is actually postcode sectors despite being labelled wards 
ward_eng_81 <- st_read("../../Data/Boundaries/Small areas historic/England_wa_1981")
ward_sco_81 <- st_read("../../Data/Boundaries/Small areas historic/Scotland_wa_1981")
ward_wal_81 <- st_read("../../Data/Boundaries/Small areas historic/Wales_wa_1981")

# join in single GB dataset 
ward_gb_81 <- bind_rows(ward_eng_81, ward_sco_81, ward_wal_81)
rm(ward_eng_81, ward_sco_81, ward_wal_81)

# spatial join of LAD 2021 ----------------
ward_gb_81 <- 
  ward_gb_81 %>% 
  st_join(lad2021 %>% select(LAD21CD, LAD21NM, LAD21NMW), 
          join = st_intersects, 
          largest = T)

# check for any non-matching areas 
ward_gb_81 %>% filter(is.na(LAD21CD) )
# join with nearest feature 
non_matching <- 
  ward_gb_81 %>% 
  filter(is.na(LAD21CD) ) %>% 
  select(-LAD21CD, -LAD21NM, -LAD21NMW) %>% 
  st_join(lad2021 %>% select(LAD21CD, LAD21NM, LAD21NMW), 
          join = st_nearest_feature)
# remove incomplete records, add complete records
ward_gb_81 <- 
  ward_gb_81 %>% 
  filter(!(is.na(LAD21CD) ) ) %>% 
  bind_rows(non_matching)
# remove auxiliary data frame
rm(non_matching)

# spatial join of TTWA 2011 ------------------------
ward_gb_81 <- 
  ward_gb_81 %>% 
  st_join(ttwa2011 %>% select(ttwa11cd, ttwa11nm), 
          join = st_intersects, 
          largest = T)

# check for any non-matching areas 
ward_gb_81 %>% filter(is.na(ttwa11cd) )
# view on map
mapview(ttwa2011) +
  ward_gb_81 %>% filter(label == "35NJAN") %>% mapview()
# join with nearest feature 
non_matching <- 
  ward_gb_81 %>% 
  filter(is.na(ttwa11cd) ) %>% 
  select(-ttwa11cd, -ttwa11nm) %>% 
  st_join(ttwa2011 %>% select(ttwa11cd, ttwa11nm), 
          join = st_nearest_feature)
# remove incomplete records, add complete records
ward_gb_81 <- 
  ward_gb_81 %>% 
  filter(!(is.na(ttwa11cd) ) ) %>% 
  bind_rows(non_matching)
# remove auxiliary data frame
rm(non_matching)

# spatial join of region ----------------------------------------------
ward_gb_81 <- 
  ward_gb_81 %>% 
  st_join(region %>% select(ITL121CD, ITL121NM), 
          join = st_intersects, 
          largest = T)

# check for any non-matching areas 
ward_gb_81 %>% filter(is.na(ITL121CD) )
# join with nearest feature 
non_matching <- 
  ward_gb_81 %>% 
  filter(is.na(ITL121CD) ) %>% 
  select(-ITL121CD, -ITL121NM) %>% 
  st_join(region %>% select(ITL121CD, ITL121NM), 
          join = st_nearest_feature)
# remove incomplete records, add complete records  
ward_gb_81 <- 
  ward_gb_81 %>% 
  filter(!(is.na(ITL121CD) ) ) %>% 
  bind_rows(non_matching)
# remove auxiliary data frame
rm(non_matching)

# create lookup table --------------------------------------------
lkup_ward81_ttwa2011_lad2021 <- 
  ward_gb_81 %>% 
  as.data.frame() %>% 
  select(-geometry) %>% 
  group_by(label) %>% 
  slice_sample(n = 1) %>% 
  ungroup()

# check against 1981 bulk data
# this works - the only missing codes are those for people at sea (codes ending in 'SS')
# census81 <- read_csv("../../Data/Census 1981/England Wales Scotland Small Area Statistics/81sas05ews_3.csv") %>% 
#   select(zoneid, `81sas050380`) %>% 
#   left_join(lkup_ward81_ttwa2011_lad2021, 
#             by = c("zoneid" = "label") )
# census81 %>% filter(is.na(ttwa11cd) ) %>% mutate(ss = substr(zoneid, 5, 6) ) %>% View()

# write out lookup table 
write_csv(lkup_ward81_ttwa2011_lad2021, "lookup-tables/lkup_wardpcs81_ttwa2011_lad2021.csv")


# 1991 Census geographies --------------------------------------------------------------------------------

# these boundaries downloaded from https://borders.ukdataservice.ac.uk/easy_download.html
# England and Wales are wards
ward_eng_91 <- st_read("../../Data/Boundaries/Small areas historic/England_wa_1991")
# note that the file Wales_wa_1991 is missing data, hence using the generalised version which is complete
ward_wal_91 <- st_read("../../Data/Boundaries/Small areas historic/Wales_wa_1991_gen3")

# Scotland areas are listed as "Pseudo Postcode Sectors" on UK Borders service
# https://borders.ukdataservice.ac.uk/easy_download_data.html?data=Scotland_oas_1991
# note that this also contains shapefiles for Lochs (e.g. "Loch1") that have no associated Census data 
pcs_sco_91 <- st_read("../../Data/Boundaries/Small areas historic/Scotland_oas_1991_pseudopcs") 
# fix mislabelled area and remove Lochs and 'gp' variable that just has zeroes in it
pcs_sco_91 <- 
  pcs_sco_91 %>% 
  mutate(label = ifelse(label == "w", "6452AC", label) ) %>% 
  filter(name != "Loch") %>% 
  select(-gp)

# join in single GB dataset 
ward_gb_91 <- bind_rows(ward_eng_91, pcs_sco_91, ward_wal_91)
rm(ward_eng_91, pcs_sco_91, ward_wal_91)

# spatial join of LAD 2021 ----------------
ward_gb_91 <- 
  ward_gb_91 %>% 
  st_join(lad2021 %>% select(LAD21CD, LAD21NM, LAD21NMW), 
          join = st_intersects, 
          largest = T)

# check for any non-matching areas 
ward_gb_91 %>% filter(is.na(LAD21CD) )
# join with nearest feature 
non_matching <- 
  ward_gb_91 %>% 
  filter(is.na(LAD21CD) ) %>% 
  select(-LAD21CD, -LAD21NM, -LAD21NMW) %>% 
  st_join(lad2021 %>% select(LAD21CD, LAD21NM, LAD21NMW), 
          join = st_nearest_feature)
# remove incomplete records, add complete records
ward_gb_91 <- 
  ward_gb_91 %>% 
  filter(!(is.na(LAD21CD) ) ) %>% 
  bind_rows(non_matching)
# remove auxiliary data frame
rm(non_matching)

# spatial join of TTWA 2011 ------------------------
ward_gb_91 <- 
  ward_gb_91 %>% 
  st_join(ttwa2011 %>% select(ttwa11cd, ttwa11nm), 
          join = st_intersects, 
          largest = T)

# check for any non-matching areas 
ward_gb_91 %>% filter(is.na(ttwa11cd) )
# join with nearest feature 
non_matching <- 
  ward_gb_91 %>% 
  filter(is.na(ttwa11cd) ) %>% 
  select(-ttwa11cd, -ttwa11nm) %>% 
  st_join(ttwa2011 %>% select(ttwa11cd, ttwa11nm), 
          join = st_nearest_feature)
# remove incomplete records, add complete records
ward_gb_91 <- 
  ward_gb_91 %>% 
  filter(!(is.na(ttwa11cd) ) ) %>% 
  bind_rows(non_matching)
# remove auxiliary data frame
rm(non_matching)

# spatial join of region ----------------------------------------------
ward_gb_91 <- 
  ward_gb_91 %>% 
  st_join(region %>% select(ITL121CD, ITL121NM), 
          join = st_intersects, 
          largest = T)

# check for any non-matching areas 
ward_gb_91 %>% filter(is.na(ITL121CD) )
# join with nearest feature 
non_matching <- 
  ward_gb_91 %>% 
  filter(is.na(ITL121CD) ) %>% 
  select(-ITL121CD, -ITL121NM) %>% 
  st_join(region %>% select(ITL121CD, ITL121NM), 
          join = st_nearest_feature)
# remove incomplete records, add complete records  
ward_gb_91 <- 
  ward_gb_91 %>% 
  filter(!(is.na(ITL121CD) ) ) %>% 
  bind_rows(non_matching)
# remove auxiliary data frame
rm(non_matching)

# create lookup table, removing any duplicates ------------------------------------------
lkup_ward91_ttwa2011_lad2021 <- 
  ward_gb_91 %>% 
  as.data.frame() %>% 
  select(-geometry) %>% 
  group_by(label) %>% 
  slice_sample(n = 1) %>% 
  ungroup()

# write out lookup table 
write_csv(lkup_ward91_ttwa2011_lad2021, "lookup-tables/lkup_wardpcs91_ttwa2011_lad2021.csv")


# 2001 Census geographies --------------------------------------------------------------------------------

# E&W lower super output areas
lsoa2001 <- read_sf("../../Data/Boundaries/Output Areas 2001/LSOAs_2001_GC_EW")
# Scotland data zones
dz2001 <- read_sf("../../Data/Boundaries/Output Areas 2001/SG_DataZoneBdry_2001")

# join in single GB dataset 
lsoa2001 <- lsoa2001 %>% 
  select(lsoa01cd, lsoa01nm, lsoa01nmw, geometry) %>% 
  rename(areacode = lsoa01cd, 
         areaname = lsoa01nm, 
         areanamealt = lsoa01nmw)
dz2001 <- dz2001 %>% 
  select(DZ_CODE, DZ_NAME, DZ_GAELIC, geometry) %>% 
  rename(areacode = DZ_CODE, 
         areaname = DZ_NAME, 
         areanamealt = DZ_GAELIC)
lsoadz_2001 <- bind_rows(lsoa2001, dz2001)
rm(lsoa2001, dz2001)

# spatial join of LAD 2021 ----------------
lsoadz_2001 <- 
  lsoadz_2001 %>% 
  st_join(lad2021 %>% select(LAD21CD, LAD21NM, LAD21NMW), 
          join = st_intersects, 
          largest = T)

# check for any non-matching areas (all matched)
lsoadz_2001 %>% filter(is.na(LAD21CD) )

# spatial join of TTWA 2011 ------------------------
lsoadz_2001 <- 
  lsoadz_2001 %>% 
  st_join(ttwa2011 %>% select(ttwa11cd, ttwa11nm), 
          join = st_intersects, 
          largest = T)

# check for any non-matching areas (all matched)
lsoadz_2001 %>% filter(is.na(ttwa11cd) )

# lsoadz_2001 join of region ----------------------------------------------
lsoadz_2001 <- 
  lsoadz_2001 %>% 
  st_join(region %>% select(ITL121CD, ITL121NM), 
          join = st_intersects, 
          largest = T)

# check for any non-matching areas (all matched)
lsoadz_2001 %>% filter(is.na(ITL121CD) )

# create lookup table, removing any duplicates ------------------------------------------
lkup_lsoazd01_ttwa2011_lad2021 <- 
  lsoadz_2001 %>% 
  as.data.frame() %>% 
  select(-geometry) %>% 
  group_by(areacode) %>% 
  slice_sample(n = 1) %>% 
  ungroup()

# write out lookup table 
write_csv(lkup_lsoazd01_ttwa2011_lad2021, "lookup-tables/lkup_lsoazd01_ttwa2011_lad2021.csv")




# session info -------------------------------------------------------------------------

# keep this up to date!
writeLines(sessionInfo() %>% capture.output(), "sessionInfo.txt")

