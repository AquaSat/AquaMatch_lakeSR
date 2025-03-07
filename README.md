# AquaMatch_lakeSR

Repository to acquire, collate, and baseline QAQC Landsat Collection 2 Surface 
Reflectance Product for all lakes/reservoirs/impoundments \>1ha in the United States
and Territories. This workflow is part of the AquaMatch dataset, an updated version
of [AquaSat](https://agupubs.onlinelibrary.wiley.com/doi/10.1029/2019WR024883) 
with more robust QAQC measures and added documentation and modularity. 

The code in this repository is covered by the MIT use license. We request that 
all downstream uses of this work be available to the public when possible.

Repository contact: B Steele (b dot steele at colostate dot edu)


## Running the Pipeline

We encourage all users to walk through the `run_targets.Rmd` script to run this
pipeline. This script walks through important configuration and authentication 
steps necessary to successfully run the pipeline. 


## Targets Architecture

The {targets} workflow defined in this repository acquires, collates, and performs 
baseline QAQC for Landsat Collection 2 Surface Reflectance data for non-intermittent 
lakes/reservoirs/impoundments greater than 1 hectare for Landsat 4 through 9 and
intermittent lakes/reservoirs/impoundments greater than 4 hectares. 
The architecture is broken up into grouped lists by function, those groups are 
listed below with a description of what each group does.


### a_Calculate_Centers

This {targets} list calculates "Point of Inaccessibility", also known as Cheybyshev 
Center for all lakes/reservoirs/impoundments greater than 1ha in surface area 
using the NHDPlus polygons using the {nhdplusTools} package and the `poi()` 
function in the {polylabelr} package. Alaska, HI, and some other HUC4 waterbodies 
are not included in the NHDPlusv2, so they are downloaded by url from The 
National Map and are processed in a separate target. 

*Timing Note*
This group of targets will take a few hours to complete.

*Configuration Note*
This group is either run completely or pulled from exisiting files based on lakeSR 
general configuration file using the boolean `calculate_centers` setting. If set
to `FALSE` a version date must be provided in the `centers_version` setting. 
Additional guidance is provided in the README and general configuration file of
the lakeSR repository.


### b_pull_Landsat_SRST_poi

This {targets} group uses the configuration file
`b_pull_Landsat_SRST_poi/config_files/config_poi.yml` and the "Pole of
Inaccessibility" points created in the `a_Calculate_Centers` group to pull
Landsat Collection 2 Surface Reflectance and Surface Temperature using the
Google Earth Engine (GEE) API. In this group, we use the most conservative LS4-7
pixel filters, as we are applying these settings across such a large continuum
of time and space. This group ends with a branched target that sends tasks to
Google Earth engine by mapping over WRS2 path rows that intersect with the
points created in the `a_Calculate_Centers` group. 

*Timing Note*
This group of targets takes a very long time, running 2 minutes - 1 hour per path-row
branch in `b_eeRun_poi`. There are just under 800 path rows executed in this
target. Anecdotally speaking, processing time is often defined by the number of
queued tasks globally, so weekends and nights are often periods of quicker
processing than weekday during business hours. As written for data publication, 
run time is 7-10 days.

*Configuration Note*
This group is either run completely or pulled from exisiting files based on lakeSR 
general configuration file using the boolean `run_GEE` setting. If set
to `FALSE` a version date must be provided in the `collated_version` setting. 
Additional guidance is provided in the README and general configuration file of
the lakeSR repository.


### c_collate_Landsat_data

This {targets} list collates the data from the Google Earth Engine run 
orchestrated in the {targets} group "b_pull_Landsat_SRST_poi" and creates publicly-
available files for downstream use, storing a list of Drive ids in a .csv in the
`c_collate_Landsat_data/out/` folder.

*Timing Note*
This group of targets takes a few hours to run, as the download, 
collation, and upload process is quite time consuming, even with mulitcore 
processing.

*Configuration Note*
This group is either run completely or pulled from exisiting files based on lakeSR 
general configuration file using the boolean `run_GEE` setting. If set
to `FALSE` a version date must be provided in the `collated_version` setting. 
Additional guidance is provided in the README and general configuration file of
the lakeSR repository.


### d_qa_filter_sort

This {targets} list applies some rudimentary QA to the Landsat stacks and saves
them as sorted files locally. LS 4/9 are complete .csv files, LS 578 are broken
up by HUC2 for memory and space considerations. If `update_and_share` is set to TRUE, the workflow
will send dated, publicly available files to Google Drive and save Drive file 
information in the `d_qa_filter_sort/out/` folder. If set to FALSE, no files
will be sent to Drive.


### e_caclculate_handoffs

This {targets} group creates "matched" data for two different 'intermission 
handoff' methods that standardize the SR values relative to LS7
and to LS8. Handoffs are visualized and are saved as tables for use downstream in
this group.


### y_siteSR_targets

This {targets} group pulls information from the siteSR workflow to use in the 
Bookdown. If the configuration setting `update_bookown` is set to FALSE, this 
list will be empty.


### z_render_bookdown

This {targets} group tracks chapters of the bookdown for changes and renders
the bookdown. If the configuration setting `update_bookown` is set to FALSE, this 
list will be empty.