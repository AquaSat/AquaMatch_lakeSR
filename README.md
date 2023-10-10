# lakeSR

Repository to acquire, collate, and baseline QAQC satellite surface reflectance 
data for all lakes \>1ha in the United States.

This repository is covered by the MIT use license. We request that all downstream 
uses of this work be available to the public when possible.

Repository contact: B Steele (b dot steele at colostate dot edu)

## Targets Architecture

The {targets} workflow defined in this repository acquires, collates, and performs 
baseline QAQC for Landsat Collection 2 Surface Reflectance data for all 
lakes/reservoirs/impoundments greater than 1 hectare for Landsat 4 through 9. 
The architecture is broken up into grouped lists by function, those groups are 
listed below with a description of what each group does.

**a_Calculate_Centers**:

This {targets} list calculates "Point of Inaccessibility", also known as Cheybyshev 
Center for all lakes/reservoirs/impoundments greater than 1ha in surface area 
using the NHDPlusHR polygons using the {nhdplusTools} package and the `poi()` 
function in the {polylabelr} package. For all waterbodies in Alaska, POI were 
calculated based on the NHD Best Resolution file for the entire state because 
the NHDPlusHR is not complete for AK. **Note**: this group of targets will take 
up to 4h to complete.


**b_pull_Landsat_SRST_poi**:

This {targets} group uses the config file `config_files/config_poi.yml` and the 
Chebyshev Center points created in the `a_Calculate_Centers` group to pull 
Landsat Collection 2 Surface Reflectance and Surface Temperature using the GEE
API. In this group, we use the most strict LS4-7 pixel filters which include
the `sr_cloud_mask` filter. This filter is a conservative filter, removing 
artefacts from upstream products that are used to create the SR product. This 
group of targets ends with a branched target that maps over each of the WRS2
path rows that intersect with the points. **Note**: this group of targets takes
a very, very long time, ranging between 8 and 45 minutes per path row branch. 
There are just under 800 path rows with points in them.
