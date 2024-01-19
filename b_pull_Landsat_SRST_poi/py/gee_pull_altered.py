## Set up the reflectance pull
def ref_pull_457_DSWE1_altered(image):
  """ This function applies all functions to the Landsat 4-7 ee.ImageCollection, extracting
  summary statistics for each geometry area where the DSWE value is 1 (high confidence water)
  and summarizing the LS4-7 sr_cloud_mask

  Args:
      image: ee.Image of an ee.ImageCollection

  Returns:
      summaries for band data within any given geometry area where the DSWE value is 1
  """
  # process image with the radsat mask
  r = add_rad_mask(image).select("radsat")
  # process image with cfmask
  f = cf_mask(image).select("cfmask")
  # process image with SR cloud mask
  s = sr_cloud_mask(image).select("sr_cloud")
  # where the f mask is > 2 (clouds and cloud shadow), call that 1 (otherwise 0) and rename as clouds.
  clouds = f.gte(1).rename("clouds")
  #apply dswe function
  d = DSWE(image).select("dswe")
  pCount = d.gt(0).rename("dswe_gt0").updateMask(f.eq(0)).updateMask(r.eq(1)).updateMask(s.eq(0)).selfMask()
  dswe1 = d.eq(1).rename("dswe1").updateMask(f.eq(0)).updateMask(r.eq(1)).updateMask(s.eq(0)).selfMask()
  # band where dswe is 3 and apply all masks
  dswe3 = d.eq(3).rename("dswe3").updateMask(f.eq(0)).updateMask(r.eq(1)).updateMask(s.eq(0)).selfMask()
  #calculate hillshade
  h = calc_hill_shades(image, feat.geometry()).select("hillShade")
  #calculate hillshadow
  hs = calc_hill_shadows(image, feat.geometry()).select("hillShadow")
  img_mask = (d.eq(1) # only high confidence water
            .updateMask(r.eq(1)) #1 == no saturated pixels
            .updateMask(f.eq(0)) #no snow or clouds
            #.updateMask(s.eq(0)) # no SR processing artefacts
            .updateMask(hs.eq(1)) # only illuminated pixels
            .selfMask())
  pixOut = (image.select(["Blue", "Green", "Red", "Nir", "Swir1", "Swir2", 
                        "SurfaceTemp", "temp_qa", "ST_ATRAN", "ST_DRAD", "ST_EMIS",
                        "ST_EMSD", "ST_TRAD", "ST_URAD"],
                        ["med_Blue", "med_Green", "med_Red", "med_Nir", "med_Swir1", "med_Swir2", 
                        "med_SurfaceTemp", "med_temp_qa", "med_atran", "med_drad", "med_emis",
                        "med_emsd", "med_trad", "med_urad"])
            .addBands(image.select(["SurfaceTemp", "ST_CDIST"],
                                    ["min_SurfaceTemp", "min_cloud_dist"]))
            .addBands(image.select(["Blue", "Green", "Red", 
                                    "Nir", "Swir1", "Swir2", "SurfaceTemp"],
                                  ["sd_Blue", "sd_Green", "sd_Red", 
                                  "sd_Nir", "sd_Swir1", "sd_Swir2", "sd_SurfaceTemp"]))
            .addBands(image.select(["Blue", "Green", "Red", "Nir", 
                                    "Swir1", "Swir2", 
                                    "SurfaceTemp"],
                                  ["mean_Blue", "mean_Green", "mean_Red", "mean_Nir", 
                                  "mean_Swir1", "mean_Swir2", 
                                  "mean_SurfaceTemp"]))
            .addBands(image.select(["SurfaceTemp"]))
            .addBands(s) # to count things that would be flagged in sr_cloud mask
            .updateMask(img_mask.eq(1))
            # add these bands back in to create summary statistics without the influence of the DSWE masks:
            .addBands(pCount) 
            .addBands(dswe1)
            .addBands(dswe3)
            .addBands(clouds) 
            .addBands(hs)
            .addBands(h)
            ) 
  combinedReducer = (ee.Reducer.median().unweighted().forEachBand(pixOut.select(["med_Blue", "med_Green", "med_Red", 
            "med_Nir", "med_Swir1", "med_Swir2", "med_SurfaceTemp", 
            "med_temp_qa","med_atran", "med_drad", "med_emis",
            "med_emsd", "med_trad", "med_urad"]))
    .combine(ee.Reducer.min().unweighted().forEachBand(pixOut.select(["min_SurfaceTemp", "min_cloud_dist"])), sharedInputs = False)
    .combine(ee.Reducer.stdDev().unweighted().forEachBand(pixOut.select(["sd_Blue", "sd_Green", "sd_Red", "sd_Nir", "sd_Swir1", "sd_Swir2", "sd_SurfaceTemp"])), sharedInputs = False)
    .combine(ee.Reducer.mean().unweighted().forEachBand(pixOut.select(["mean_Blue", "mean_Green", "mean_Red", 
              "mean_Nir", "mean_Swir1", "mean_Swir2", "mean_SurfaceTemp"])), sharedInputs = False)
    .combine(ee.Reducer.kurtosis().unweighted().forEachBand(pixOut.select(["SurfaceTemp"])), outputPrefix = "kurt_", sharedInputs = False)
    .combine(ee.Reducer.sum().unweighted().forEachBand(pixOut.select(["sr_cloud"])), outputPrefix = "sum_", sharedInputs = False)
    .combine(ee.Reducer.count().unweighted().forEachBand(pixOut.select(["dswe_gt0", "dswe1", "dswe3"])), outputPrefix = "pCount_", sharedInputs = False)
    .combine(ee.Reducer.mean().unweighted().forEachBand(pixOut.select(["clouds", "hillShadow"])), outputPrefix = "prop_", sharedInputs = False)
    .combine(ee.Reducer.mean().unweighted().forEachBand(pixOut.select(["hillShade"])), outputPrefix = "mean_", sharedInputs = False)
    )
  # apply combinedReducer to the image collection, mapping over each feature
  lsout = (pixOut.reduceRegions(feat, combinedReducer, 30))
  out = lsout.map(remove_geo)
  return out

def ref_pull_457_DSWE3_altered(image):
  """ This function applies all functions to the Landsat 4-7 ee.ImageCollection, extracting
  summary statistics for each geometry area where the DSWE value is 3 (high confidence
  vegetated pixel) and summarizing the LS4-7 sr_cloud_mask

  Args:
      image: ee.Image of an ee.ImageCollection

  Returns:
      summaries for band data within any given geometry area where the DSWE value is 3
  """
  # process image with the radsat mask
  r = add_rad_mask(image).select("radsat")
  # process image with cfmask
  f = cf_mask(image).select("cfmask")
  # process image with st SR cloud mask
  s = sr_cloud_mask(image).select("sr_cloud")
  # where the f mask is >= 1 (clouds and cloud shadow), call that 1 (otherwise 0) and rename as clouds.
  clouds = f.gte(1).rename("clouds")
  #apply dswe function
  d = DSWE(image).select("dswe")
  pCount = d.gt(0).rename("dswe_gt0").updateMask(f.eq(0)).updateMask(r.eq(1)).updateMask(s.eq(0)).selfMask()
  dswe1 = d.eq(1).rename("dswe1").updateMask(f.eq(0)).updateMask(r.eq(1)).updateMask(s.eq(0)).selfMask()
  # band where dswe is 3 and apply all masks
  dswe3 = d.eq(3).rename("dswe3").updateMask(f.eq(0)).updateMask(r.eq(1)).updateMask(s.eq(0)).selfMask()
  #calculate hillshade
  h = calc_hill_shades(image, feat.geometry()).select("hillShade")
  #calculate hillshadow
  hs = calc_hill_shadows(image, feat.geometry()).select("hillShadow")
  img_maks = (d.eq(3) # only vegetated water
          .updateMask(r.eq(1)) #1 == no saturated pixels
          .updateMask(f.eq(0)) #no snow or clouds
          #.updateMask(s.eq(0)) # no SR processing artefacts
          .updateMask(hs.eq(1)) # only illuminated pixels
          .selfMask())
  pixOut = (image.select(["Blue", "Green", "Red", "Nir", "Swir1", "Swir2", 
                      "SurfaceTemp", "temp_qa", "ST_ATRAN", "ST_DRAD", "ST_EMIS",
                      "ST_EMSD", "ST_TRAD", "ST_URAD"],
                      ["med_Blue", "med_Green", "med_Red", "med_Nir", "med_Swir1", "med_Swir2", 
                      "med_SurfaceTemp", "med_temp_qa", "med_atran", "med_drad", "med_emis",
                      "med_emsd", "med_trad", "med_urad"])
          .addBands(image.select(["SurfaceTemp", "ST_CDIST"],
                                  ["min_SurfaceTemp", "min_cloud_dist"]))
          .addBands(image.select(["Blue", "Green", "Red", 
                                  "Nir", "Swir1", "Swir2", "SurfaceTemp"],
                                ["sd_Blue", "sd_Green", "sd_Red", 
                                "sd_Nir", "sd_Swir1", "sd_Swir2", "sd_SurfaceTemp"]))
          .addBands(image.select(["Blue", "Green", "Red", "Nir", 
                                    "Swir1", "Swir2", 
                                    "SurfaceTemp"],
                                  ["mean_Blue", "mean_Green", "mean_Red", "mean_Nir", 
                                  "mean_Swir1", "mean_Swir2", 
                                  "mean_SurfaceTemp"]))
          .addBands(image.select(["SurfaceTemp"]))
          .addBands(s) # to count things that would be flagged in sr_cloud mask
          .updateMask(img_mask.eq(1))
          # add these bands back in to create summary statistics without the influence of the DSWE masks:
          .addBands(pCount) 
          .addBands(dswe1)
          .addBands(dswe3)
          .addBands(clouds) 
          .addBands(hs)
          .addBands(h)
          ) 
  combinedReducer = (ee.Reducer.median().unweighted().forEachBand(pixOut.select(["med_Blue", "med_Green", "med_Red", 
            "med_Nir", "med_Swir1", "med_Swir2", "med_SurfaceTemp", 
            "med_temp_qa","med_atran", "med_drad", "med_emis",
            "med_emsd", "med_trad", "med_urad"]))
    .combine(ee.Reducer.min().unweighted().forEachBand(pixOut.select(["min_SurfaceTemp", "min_cloud_dist"])), sharedInputs = False)
    .combine(ee.Reducer.stdDev().unweighted().forEachBand(pixOut.select(["sd_Blue", "sd_Green", "sd_Red", "sd_Nir", "sd_Swir1", "sd_Swir2", "sd_SurfaceTemp"])), sharedInputs = False)
    .combine(ee.Reducer.mean().unweighted().forEachBand(pixOut.select(["mean_Blue", "mean_Green", "mean_Red", 
              "mean_Nir", "mean_Swir1", "mean_Swir2", "mean_SurfaceTemp"])), sharedInputs = False)
    .combine(ee.Reducer.kurtosis().unweighted().forEachBand(pixOut.select(["SurfaceTemp"])), outputPrefix = "kurt_", sharedInputs = False)
    .combine(ee.Reducer.sum().unweighted().forEachBand(pixOut.select(["sr_cloud"])), outputPrefix = 'sum_', sharedInputs = False)
    .combine(ee.Reducer.count().unweighted().forEachBand(pixOut.select(["dswe_gt0", "dswe1", "dswe3"])), outputPrefix = "pCount_", sharedInputs = False)
    .combine(ee.Reducer.mean().unweighted().forEachBand(pixOut.select(["clouds", "hillShadow"])), outputPrefix = "prop_", sharedInputs = False)
    .combine(ee.Reducer.mean().unweighted().forEachBand(pixOut.select(["hillShade"])), outputPrefix = "mean_", sharedInputs = False)
    )
  # apply combinedReducer to the image collection, mapping over each feature
  lsout = (pixOut.reduceRegions(feat, combinedReducer, 30))
  out = lsout.map(remove_geo)
  return out


def ref_pull_89_DSWE1(image):
  """ This function applies all functions to the Landsat 8 and 9 ee.ImageCollection, extracting
  summary statistics for each geometry area where the DSWE value is 1 (high confidence water)

  Args:
      image: ee.Image of an ee.ImageCollection

  Returns:
      summaries for band data within any given geometry area where the DSWE value is 1
  """
  # process image with the radsat mask
  r = add_rad_mask(image).select("radsat")
  # process image with cfmask
  f = cf_mask(image).select("cfmask")
  # process image with aerosol mask
  a = sr_aerosol(image).select("medHighAero")
  # where the f mask is >= 1 (clouds and cloud shadow), call that 1 (otherwise 0) and rename as clouds.
  clouds = f.gte(1).rename("clouds")
  #apply dswe function
  d = DSWE(image).select("dswe")
  pCount = d.gt(0).rename("dswe_gt0").updateMask(f.eq(0)).updateMask(r.eq(1)).selfMask()
  dswe1 = d.eq(1).rename("dswe1").updateMask(f.eq(0)).updateMask(r.eq(1)).selfMask()
  # band where dswe is 3 and apply all masks
  dswe3 = d.eq(3).rename("dswe3").updateMask(f.eq(0)).updateMask(r.eq(1)).selfMask()
  #calculate hillshade
  h = calc_hill_shades(image, feat.geometry()).select("hillShade")
  #calculate hillshadow
  hs = calc_hill_shadows(image, feat.geometry()).select("hillShadow")
  img_mask = (d.eq(1) # only confident water
          .updateMask(r.eq(1)) # 1 == no saturated pixels
          .updateMask(f.eq(0)) # no snow or clouds
          .updateMask(hs.eq(1)) # only illuminated pixels
          .selfMask())
  pixOut = (image.select(["Aerosol", "Blue", "Green", "Red", "Nir", "Swir1", "Swir2", 
                      "SurfaceTemp", "temp_qa", "ST_ATRAN", "ST_DRAD", "ST_EMIS",
                      "ST_EMSD", "ST_TRAD", "ST_URAD"],
                      ["med_Aerosol", "med_Blue", "med_Green", "med_Red", "med_Nir", "med_Swir1", "med_Swir2", 
                      "med_SurfaceTemp", "med_temp_qa", "med_atran", "med_drad", "med_emis",
                      "med_emsd", "med_trad", "med_urad"])
          .addBands(image.select(["SurfaceTemp", "ST_CDIST"],
                                  ["min_SurfaceTemp", "min_cloud_dist"]))
          .addBands(image.select(["Aerosol", "Blue", "Green", "Red", 
                                  "Nir", "Swir1", "Swir2", "SurfaceTemp"],
                                ["sd_Aerosol", "sd_Blue", "sd_Green", "sd_Red", 
                                "sd_Nir", "sd_Swir1", "sd_Swir2", "sd_SurfaceTemp"]))
          .addBands(image.select(["Aerosol", "Blue", "Green", "Red", "Nir", 
                                  "Swir1", "Swir2", 
                                  "SurfaceTemp"],
                                ["mean_Aerosol", "mean_Blue", "mean_Green", "mean_Red", "mean_Nir", 
                                "mean_Swir1", "mean_Swir2", 
                                "mean_SurfaceTemp"]))
          .addBands(image.select(["SurfaceTemp"]))
          .updateMask(img_mask.eq(1))
          # add these bands back in to create summary statistics without the influence of the DSWE masks:
          .addBands(pCount) 
          .addBands(dswe1)
          .addBands(dswe3)
          .addBands(a)
          .addBands(clouds) 
          .addBands(hs)
          .addBands(h)
          ) 
  combinedReducer = (ee.Reducer.median().unweighted().forEachBand(pixOut.select(["med_Aerosol", "med_Blue", "med_Green", "med_Red", 
            "med_Nir", "med_Swir1", "med_Swir2", "med_SurfaceTemp", 
            "med_temp_qa","med_atran", "med_drad", "med_emis",
            "med_emsd", "med_trad", "med_urad"]))
    .combine(ee.Reducer.min().unweighted().forEachBand(pixOut.select(["min_SurfaceTemp", "min_cloud_dist"])), sharedInputs = False)
    .combine(ee.Reducer.stdDev().unweighted().forEachBand(pixOut.select(["sd_Aerosol", "sd_Blue", "sd_Green", "sd_Red", "sd_Nir", "sd_Swir1", "sd_Swir2", "sd_SurfaceTemp"])), sharedInputs = False)
    .combine(ee.Reducer.mean().unweighted().forEachBand(pixOut.select(["mean_Aerosol", "mean_Blue", "mean_Green", "mean_Red", 
              "mean_Nir", "mean_Swir1", "mean_Swir2", "mean_SurfaceTemp"])), sharedInputs = False)
    .combine(ee.Reducer.kurtosis().unweighted().forEachBand(pixOut.select(["SurfaceTemp"])), outputPrefix = "kurt_", sharedInputs = False)
    .combine(ee.Reducer.count().unweighted().forEachBand(pixOut.select(["dswe_gt0", "dswe1", "dswe3", "medHighAero"])), outputPrefix = "pCount_", sharedInputs = False)
    .combine(ee.Reducer.mean().unweighted().forEachBand(pixOut.select(["clouds", "hillShadow"])), outputPrefix = "prop_", sharedInputs = False)
    .combine(ee.Reducer.mean().unweighted().forEachBand(pixOut.select(["hillShade"])), outputPrefix = "mean_", sharedInputs = False)
    )
  # apply combinedReducer to the image collection, mapping over each feature
  lsout = (pixOut.reduceRegions(feat, combinedReducer, 30))
  out = lsout.map(remove_geo)
  return out

def ref_pull_89_DSWE3(image):
  """ This function applies all functions to the Landsat 8 and 9 ee.ImageCollection, extracting
  summary statistics for each geometry area where the DSWE value is 3 (high confidence vegetated
  pixels)

  Args:
      image: ee.Image of an ee.ImageCollection

  Returns:
      summaries for band data within any given geometry area where the DSWE value is 3
  """
  # process image with the radsat mask
  r = add_rad_mask(image).select("radsat")
  # process image with cfmask
  f = cf_mask(image).select("cfmask")
  # process image with aerosol mask
  a = sr_aerosol(image).select("medHighAero")
  # where the f mask is >= 1 (clouds and cloud shadow), call that 1 (otherwise 0) and rename as clouds.
  clouds = f.gte(1).rename("clouds")
  #apply dswe function
  d = DSWE(image).select("dswe")
  pCount = d.gt(0).rename("dswe_gt0").updateMask(f.eq(0)).updateMask(r.eq(1)).selfMask()
  dswe1 = d.eq(1).rename("dswe1").updateMask(f.eq(0)).updateMask(r.eq(1)).selfMask()
  # band where dswe is 3 and apply all masks
  dswe3 = d.eq(3).rename("dswe3").updateMask(f.eq(0)).updateMask(r.eq(1)).selfMask()
  #calculate hillshade
  h = calc_hill_shades(image, feat.geometry()).select("hillShade")
  #calculate hillshadow
  hs = calc_hill_shadows(image, feat.geometry()).select("hillShadow")
  img_mask = (d.eq(3) # only vegetated water
          .updateMask(r.eq(1)) #1 == no saturated pixels
          .updateMask(f.eq(0)) #no snow or clouds
          .updateMask(hs.eq(1)) # only illuminated pixels
          .selfMask())
  pixOut = (image.select(["Aerosol", "Blue", "Green", "Red", "Nir", "Swir1", "Swir2", 
                      "SurfaceTemp", "temp_qa", "ST_ATRAN", "ST_DRAD", "ST_EMIS",
                      "ST_EMSD", "ST_TRAD", "ST_URAD"],
                      ["med_Aerosol", "med_Blue", "med_Green", "med_Red", "med_Nir", "med_Swir1", "med_Swir2", 
                      "med_SurfaceTemp", "med_temp_qa", "med_atran", "med_drad", "med_emis",
                      "med_emsd", "med_trad", "med_urad"])
          .addBands(image.select(["SurfaceTemp", "ST_CDIST"],
                                  ["min_SurfaceTemp", "min_cloud_dist"]))
          .addBands(image.select(["Aerosol", "Blue", "Green", "Red", 
                                  "Nir", "Swir1", "Swir2", "SurfaceTemp"],
                                ["sd_Aerosol", "sd_Blue", "sd_Green", "sd_Red", 
                                "sd_Nir", "sd_Swir1", "sd_Swir2", "sd_SurfaceTemp"]))
          .addBands(image.select(["Aerosol", "Blue", "Green", "Red", "Nir", 
                                  "Swir1", "Swir2", 
                                  "SurfaceTemp"],
                                ["mean_Aerosol", "mean_Blue", "mean_Green", "mean_Red", "mean_Nir", 
                                "mean_Swir1", "mean_Swir2", 
                                "mean_SurfaceTemp"]))
          .addBands(image.select(["SurfaceTemp"]))
          .updateMask(img_mask.eq(1))
          # add these bands back in to create summary statistics without the influence of the DSWE masks:
          .addBands(pCount) 
          .addBands(dswe1)
          .addBands(dswe3)
          .addBands(a)
          .addBands(clouds) 
          .addBands(hs)
          .addBands(h)
          ) 
  combinedReducer = (ee.Reducer.median().unweighted().forEachBand(pixOut.select(["med_Aerosol", "med_Blue", "med_Green", "med_Red", 
            "med_Nir", "med_Swir1", "med_Swir2", "med_SurfaceTemp", 
            "med_temp_qa","med_atran", "med_drad", "med_emis",
            "med_emsd", "med_trad", "med_urad"]))
    .combine(ee.Reducer.min().unweighted().forEachBand(pixOut.select(["min_SurfaceTemp", "min_cloud_dist"])), sharedInputs = False)
    .combine(ee.Reducer.stdDev().unweighted().forEachBand(pixOut.select(["sd_Aerosol", "sd_Blue", "sd_Green", "sd_Red", "sd_Nir", "sd_Swir1", "sd_Swir2", "sd_SurfaceTemp"])), sharedInputs = False)
    .combine(ee.Reducer.mean().unweighted().forEachBand(pixOut.select(["mean_Aerosol", "mean_Blue", "mean_Green", "mean_Red", 
              "mean_Nir", "mean_Swir1", "mean_Swir2", "mean_SurfaceTemp"])), sharedInputs = False)
    .combine(ee.Reducer.kurtosis().unweighted().forEachBand(pixOut.select(["SurfaceTemp"])), outputPrefix = "kurt_", sharedInputs = False)
    .combine(ee.Reducer.count().unweighted().forEachBand(pixOut.select(["dswe_gt0", "dswe1", "dswe3", "medHighAero"])), outputPrefix = "pCount_", sharedInputs = False)
    .combine(ee.Reducer.mean().unweighted().forEachBand(pixOut.select(["clouds", "hillShadow"])), outputPrefix = "prop_", sharedInputs = False)
    .combine(ee.Reducer.mean().unweighted().forEachBand(pixOut.select(["hillShade"])), outputPrefix = "mean_", sharedInputs = False)
    )
  # apply combinedReducer to the image collection, mapping over each feature
  lsout = (pixOut.reduceRegions(feat, combinedReducer, 30))
  out = lsout.map(remove_geo)
  return out
