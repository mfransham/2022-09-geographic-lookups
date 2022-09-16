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
# mapview(ttwa2011["ttwa11nm"], fgb = FALSE)

# local authority districts (363, as at April 2021)
# from https://geoportal.statistics.gov.uk/search?collection=Dataset&sort=name&tags=all(BDY_LAD%2CDEC_2021)
lad2021 <- st_read("../../Data/Boundaries/Local_Authority_Districts_(December_2021)_GB_BGC")


# 1981 Census geographies --------------------------------------------------------------

# these boundaries downloaded from https://borders.ukdataservice.ac.uk/easy_download.html
# England and Wales are wards; Scotland is actually enumeration districts or postcode sectors
ward_eng_81 <- st_read("../../Data/Boundaries/Wards historic/England_wa_1981")
ward_sco_81 <- st_read("../../Data/Boundaries/Wards historic/Scotland_wa_1981")
ward_wal_81 <- st_read("../../Data/Boundaries/Wards historic/Wales_wa_1981")

# join in single GB dataset 
ward_gb_81 <- bind_rows(ward_eng_81, ward_sco_81, ward_wal_81)
rm(ward_eng_81, ward_sco_81, ward_wal_81)

# spatial join of LAD 2021
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

# spatial join of TTWA 2011
ward_gb_81 <- 
  ward_gb_81 %>% 
  st_join(ttwa2011 %>% select(ttwa11cd, ttwa11nm), 
          join = st_intersects, 
          largest = T)

# check for any non-matching areas 
ward_gb_81 %>% filter(is.na(ttwa11cd) )
# view on map
mapview(ttwa2011) + 
  ward_gb_81 %>% filter(label == "6332CE") %>% mapview()
# join with nearest feature 
ward_gb_81 %>% 
  filter(is.na(ttwa11cd) ) %>% 
  select(-ttwa11cd, -ttwa11nm) %>% 
  st_join(ttwa2011 %>% select(ttwa11cd, ttwa11nm), 
          join = st_nearest_feature)



########## TNT ##########################
# join these complete records to the main table 
# add region 
# create lookup table, making sure only one entry per ward / postcode sector
# check this lookup table matches with the bulk data downloaded for 1981 Census 
# then move on to 1991, 2001, 2011
# later: could do the same for NESPD areas, should be pretty easy if this works (as it seems to be doing) 



# session info -------------------------------------------------------------------------

# keep this up to date!
writeLines(sessionInfo() %>% capture.output(), "sessionInfo.txt")

