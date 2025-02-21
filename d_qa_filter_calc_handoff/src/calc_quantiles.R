#' @title Calculate Quantiles for Paired Data
#'
#' @description
#' This function calculates quantiles for various RS measurements (Surface 
#' Temperature, Blue, Green, Red, and NIR) from paired data for early and late
#' missions of Landsat.
#'
#' @param paired_data A data frame or data table containing paired measurements 
#' for early and late LS missions. Expected columns include med_SurfaceTemp, 
#' i.med_SurfaceTemp, med_Blue, i.med_Blue, med_Green, i.med_Green, med_Red, 
#' i.med_Red, med_Nir, and i.med_Nir.
#' @param quant_seq A numeric vector specifying the quantiles to be computed 
#' (e.g., c(0.25, 0.5, 0.75) for quartiles).
#'
#' @returns A list containing five data tables, each representing quantiles for a 
#' specific measurement. Each data table has two columns: 'early' and 'late', 
#' representing the quantiles for the respective periods.
#'
calc_quantiles <- function(paired_data,
                           quant_seq) {
  
  quant_late_ST <- quantile(paired_data$med_SurfaceTemp, quant_seq)
  quant_early_ST <- quantile(paired_data$i.med_SurfaceTemp, quant_seq)
  ST <- data.table(early = quant_early_ST,
                   late = quant_late_ST)
  
  quant_late_Blue <- quantile(paired_data$med_Blue, quant_seq)
  quant_early_Blue <- quantile(paired_data$i.med_Blue, quant_seq)
  Blue <- data.table(early = quant_early_Blue,
                     late = quant_late_Blue)
  
  quant_late_Green <- quantile(paired_data$med_Green, quant_seq)
  quant_early_Green <- quantile(paired_data$i.med_Green, quant_seq)
  Green <- data.table(early = quant_early_Green,
                      late = quant_late_Green)
  
  quant_late_Red <- quantile(paired_data$med_Red, quant_seq)
  quant_early_Red <- quantile(paired_data$i.med_Red, quant_seq)
  Red <- data.table(early = quant_early_Red,
                    late = quant_late_Red)
  
  quant_late_Nir <- quantile(paired_data$med_Nir, quant_seq)
  quant_early_Nir <- quantile(paired_data$i.med_Nir, quant_seq)
  Nir <- data.table(early = quant_early_Nir,
                    late = quant_late_Nir)
  
  return(list(ST, Blue, Green, Red, Nir))
}

