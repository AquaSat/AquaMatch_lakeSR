# lakeSR

Repository to acquire, collate, and baseline QAQC satellite surface reflectance data for all lakes \>1ha in the United States.

This repository is covered by the MIT use license. We request that all downstream uses of this work be available to the public when possible.

Repository contact: B Steele (b dot steele at colostate dot edu)

## Earth Engine Set Up and Authentication

In order to use this workflow, you must have a [Google Earth Engine account](https://earthengine.google.com/signup/), and you will need to [download, install, and initialize gcloud](https://cloud.google.com/sdk/docs/install). For common issues with `gcloud`, please [see the notes here](https://github.com/rossyndicate/ROSS_RS_mini_tools/blob/main/helps/CommonIssues.md).

Note, before any code that requires access to Google Earth Engine is run, you must execute the following command in your **zsh** terminal and follow the prompts in your browser:

`earthengine authenticate`

When complete, your terminal will read:

`Successfully saved authorization token.`

This token is valid for 7 days from the time of authentication.

## Targets Architecture

The {targets} workflow defined in this repository acquires, collates, and performs baseline QAQC for Landsat Collection 2 Surface Reflectance data for all lakes/reservoirs/impoundments greater than 1 hectare for Landsat 4 through 9. The architecture is broken up into grouped lists by function, those groups are listed below with a description of what each group does.

**a_Calculate_Centers**:

This {targets} list calculates "Point of Inaccessibility", also known as Cheybyshev Center for all lakes/reservoirs/impoundments greater than 1ha in surface area using the NHDPlusHR polygons using the {nhdplusTools} package and the `poi()` function in the {polylabelr} package. For all waterbodies in Alaska, POI were calculated based on the NHD Best Resolution file for the entire state because the NHDPlusHR is not complete for AK. **Note**: this group of targets will take up to 4h to complete.

**b_pull_Landsat_SRST_poi**:

This {targets} list initiates the pull of Landsat SRST for all POI calculated in the {targets} group 'a_Calculate_Centers'.

### Monitoring the Workflow

Since many steps of this process take a lot of time to complete and this workflow uses dynamic branching with unintelligible branch names and quantities, the optimal way to track progress is by using the `targets::tar_watch()` command in a new RStudio window within the lakeSR project. `tar_watch()` will open a browser window - the 'branch' tab will show branch completion progress.
