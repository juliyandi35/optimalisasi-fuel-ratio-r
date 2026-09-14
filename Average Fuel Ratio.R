library(openxlsx)
library(dplyr)

# Baca file Excel yang memiliki 31 sheet
input_file <- "updated_excel.xlsx"
wb <- loadWorkbook(input_file)

# Buat workbook baru untuk menyimpan hasil analisis
output_wb <- createWorkbook()

# Inisialisasi list untuk menyimpan fuel burn dan total HM/KM dari setiap sheet
fuel_burn_list <- list()

# Loop untuk membaca setiap sheet dan menghitung total HM/KM, LITER, serta Fuel Burn
for (sheet_name in names(wb)[-1]) {
  data <- read.xlsx(input_file, sheet = sheet_name)
  
  # Agregasi data berdasarkan Equipment
  summary_data <- data %>%
    group_by(EQUIPMENT) %>%
    summarise(
      TOTAL_HM_KM = sum(na.omit(`HM/KM`)),
      TOTAL_LITER = sum(na.omit(LITER)),
      FUEL_BURN = TOTAL_LITER / TOTAL_HM_KM
    )
  
  # Simpan hasil agregasi dalam sheet baru
  addWorksheet(output_wb, sheetName = sheet_name)
  writeData(output_wb, sheet = sheet_name, summary_data)
  
  # Simpan fuel burn dan total HM/KM untuk analisis rata-rata
  fuel_burn_list[[sheet_name]] <- summary_data %>%
    select(EQUIPMENT, FUEL_BURN, TOTAL_HM_KM)
}

# Gabungkan semua data fuel burn dari setiap sheet
fuel_burn_data <- bind_rows(fuel_burn_list) %>%
  group_by(EQUIPMENT) %>%
  summarise(
    AVG_FUEL_BURN = mean(na.omit(FUEL_BURN)),
    AVG_HM_KM = mean(na.omit(TOTAL_HM_KM))
  )

# Tambahkan sheet baru untuk menyimpan hasil rata-rata fuel burn
addWorksheet(output_wb, sheetName = "Average Fuel Burn")
writeData(output_wb, sheet = "Average Fuel Burn", fuel_burn_data)

# Simpan file hasil analisis
output_file <- "fuel_burn_analysis.xlsx"
saveWorkbook(output_wb, output_file, overwrite = TRUE)

cat("Analisis selesai! File 'fuel_burn_analysis.xlsx' telah dibuat.\n")
