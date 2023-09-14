# lakeSR

Repository to acquire, collate, and baseline QAQC satellite surface reflectance
data for all lakes \>1ha in the United States.

This repository is covered by the MIT use license. We request that all
downstream uses of this work be available to the public when possible.

Repository contact: B Steele (b dot steele at colostate dot edu)

## Targets Architecture

The {targets} workflow defined in this repository acquires, collates, and
performs baseline QAQC for Landsat Collection 2 Surface Reflectance data for all
lakes/reservoirs/impoundments greater than 1 hectare for Landsat 4 through 9.
The architecture is broken up into grouped lists by function, those groups are
listed below with a description of what each group does.

**a_Calculate_Centers**:

This {targets} list calculates "Point of Inaccessibility", also known as
Cheybyshev Center for all lakes/reservoirs/impoundments greater than 1ha in 
surface area using the NHDPlusHR polygons using the {nhdplusTools} package
and the `poi()` function in the {polylabelr} package. For all waterbodies in
Alaska, POI were calculated based on the NHD Best Resolution file for the entire
state because the NHDPlusHR is not complete for AK. **Note**: this group of
targets will take up to 4h to complete.
