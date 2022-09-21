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
# England and Wales are wards; Scotland is actually postcode sectors
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
# one shapefile with no LAD match
ward_gb_81 %>% filter(label == "6554AC") %>% mapview(label = "LAD21NM")
# belongs to Orkney Islands
ward_gb_81 %>% filter(label == "6554AC") %>% View()
# add manually
ward_gb_81 <- ward_gb_81 %>% 
  mutate(LAD21CD = ifelse(label == "6554AC", "S12000023", LAD21CD), 
         LAD21NM = ifelse(label == "6554AC", "Orkney Islands", LAD21NM) )

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
write_csv(lkup_ward81_ttwa2011_lad2021, "lookup-tables/lkup_ward81_ttwa2011_lad2021.csv")


# 1991 Census geographies --------------------------------------------------------------------------------

# these boundaries downloaded from https://borders.ukdataservice.ac.uk/easy_download.html
# England and Wales are wards; Scotland is actually postcode sectors
ward_eng_91 <- st_read("../../Data/Boundaries/Small areas historic/England_wa_1991")
ward_wal_91 <- st_read("../../Data/Boundaries/Small areas historic/Wales_wa_1991")

# sort Scotland out!!!
pcs_sco_91 <- st_read("../../Data/Boundaries/Small areas historic/Scotland_pcs_1991")
ward_sco_91 <- st_read("../../Data/Boundaries/Small areas historic/Scotland_wa_1991")

nrow(ward_eng_91) + nrow(ward_wal_91) + nrow(pcs_sco_91)

head(pcs_sco_91)
head(ward_sco_91)

# join in single GB dataset 
ward_gb_91 <- bind_rows(ward_eng_91, pcs_sco_91, ward_wal_91)
rm(ward_eng_91, ward_sco_91, ward_wal_91)

census91 <- read_csv("../../Data/Census 1991/s08ews3.csv") %>% select(1:3)
census91 %>% mutate(ss = substr(zoneid, 5, 6) ) %>% filter(ss != "SS") %>% nrow()
ward_gb_91 %>% as.data.frame() %>% group_by(label) %>% slice_sample(n=1) %>% nrow()

ward_gb_91 %>% as.data.frame() %>% select(-geometry) %>% View()

########## TNT ##########################
# need to sort Scotland out - SAS data is definitely postcode sectors
# but I am not sure if the shapefile I have downloaded is the right postcode sectors
# even if it is, it does not have the same codes - aargh!!


# then move on to 2001, 2011
# later: could do the same for NESPD areas, should be pretty easy if this works (as it seems to be doing) 




# spatial join of LAD 2021 ----------------
ward_gb_81 <- 
  ward_gb_81 %>% 
  st_join(lad2021 %>% select(LAD21CD, LAD21NM, LAD21NMW), 
          join = st_intersects, 
          largest = T)

# check for any non-matching areas 
ward_gb_81 %>% filter(is.na(LAD21CD) )
# one shapefile with no LAD match
ward_gb_81 %>% filter(label == "6554AC") %>% mapview(label = "LAD21NM")
# belongs to Orkney Islands
ward_gb_81 %>% filter(label == "6554AC") %>% View()
# add manually
ward_gb_81 <- ward_gb_81 %>% 
  mutate(LAD21CD = ifelse(label == "6554AC", "S12000023", LAD21CD), 
         LAD21NM = ifelse(label == "6554AC", "Orkney Islands", LAD21NM) )

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
write_csv(lkup_ward81_ttwa2011_lad2021, "lookup-tables/lkup_ward81_ttwa2011_lad2021.csv")




# session info -------------------------------------------------------------------------

# keep this up to date!
writeLines(sessionInfo() %>% capture.output(), "sessionInfo.txt")

