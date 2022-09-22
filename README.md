# 2022-09-geographic-lookups

This code creates lookup tables between historic small area geographies and modern geographies, so that it is possible to aggregate historic small area Census data to larger modern boundaries.  The modern boundaries currently of interest (as part of the [LNRI project](https://sites.google.com/view/regional-inequality/home)) are 2011 Travel to Work Areas and 2021 local authority districts for Great Britain.  

The small areas depend upon the Census year, as they have changed over time

## Bulk data downloads of small area Census data

A single .zip file with small area statistics data is available for each of the 1971, 1981, 1991, 1981 and 2001 Censuses from the [UK Data Service](https://statistics.ukdataservice.ac.uk/).  These are not always as helpful as they could be, as they come with minimal (or no!) documentation, and understanding what the tables refer to often requires referring to the small area statistics tables on [Nomis](https://www.nomisweb.co.uk/default.asp) (at the time of writing I think this service is under development so it may improve).  

There are legacy UKDS services at [Casweb](https://casweb.ukdataservice.ac.uk//) and [InFuse](http://infuse.ukdataservice.ac.uk/).  

Historic boundary datasets for the UK Censuses from 1971 onwards are available from the [UK Borders service](https://borders.ukdataservice.ac.uk/index.html) (not all boundaries are available as 'easy download' - see the 'boundary data selector' for all available boundaries); more recent boundary sets are available from the [ONS geography portal](https://geoportal.statistics.gov.uk/). 


## 1981 Census small areas

- England & Wales: electoral wards used for small area statistics (area code example 01AAAA)
- Scotland: ward equivalent is postcode sectors, see [guidance on NRS website](https://www.nrscotland.gov.uk/files//geography/products/1991-census-bkgrd.pdf) (area code example 6554AC)
- total of 10,445 wards and postcode sectors on land - 'shipping' geographic codes were also included to count people not present on land at the time of the Census.  These codes all end in 'SS' (e.g. 01AASS). Including these shipping codes there are 10,903 small areas 

Below this level there are enumeration districts for Scotland (e.g. 5601AB03) and England & Wales (e.g. 01AAAA01).  

Full small area datasets with Great Britain data combined are available from UK Data Service bulk download.  Hierarchy number 3 has wards for England & Wales and postcode sectors for Scotland; hierarchy number 4 has enumeration districts.  

Shapefiles are available from UK Borders website.  Dataset listed as [Scottish Wards is actually postcode sectors](https://borders.ukdataservice.ac.uk/easy_download_data.html?data=Scotland_wa_1981).  

## 1991 Census small areas 

- England & Wales: use wards for small area statistics (area code example 17FEFL)
- Scotland: ward equivalent is postcode sectors, see [guidance on NRS website](https://www.nrscotland.gov.uk/files//geography/products/1991-census-bkgrd.pdf) (area code example 6123AL)
- total of 10,528 wards and postcode sectors, excluding 'SS' shipping codes and lochs (the latter are included in the Scottish postcode sector shapefile)

Full small area datasets with Great Britain data combined are available from UK Data Service bulk download.  Hierarchy number 3 has wards for England & Wales and postcode sectors for Scotland; hierarchy number 4 has enumeration districts for England & Wales and Output Areas for Scotland.  

Boundaries are available from UK Borders service, however it is tricky to find the right ones. For England, it is [electoral wards](https://borders.ukdataservice.ac.uk/easy_download_data.html?data=England_wa_1991) which is straightforward.  For Wales it is also [electoral wards](https://borders.ukdataservice.ac.uk/easy_download_data.html?data=Wales_wa_1991) but the standard boundary dataset is incomplete - the one listed as 'super generalised' is complete.  For Scotland you need to find the ['pseudo postcode sectors'](https://borders.ukdataservice.ac.uk/easy_download_data.html?data=Scotland_oas_1991).  One of the areas in the Scotland dataset is mislabelled, see code for details.  

## 2001 Census

[Nomis](www.nomisweb.co.uk) only has data for England & Wales

Data Zone data for Scotland is available on the [NRS website](https://www.scotlandscensus.gov.uk/documents/2001-census-table-data-2001-datazones/)

