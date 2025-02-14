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

