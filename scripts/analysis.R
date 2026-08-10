# ==============================================================================
# PORTFOLIO PROJECT: VIRGINIA WATERSHED 7Q10 LOW-FLOW FREQUENCY ANALYSIS
# Data Source: USGS National Water Information System (NWIS)
# Timeline: 1996-01-01 to 2026-08-01 (30-Year Required Climate Record)
# ==============================================================================


# ENVIRONMENT SETUP & DEPENDENCIES

# Master Package Installation Rule (Uncomment if setting up on a new machine)
# install.packages(c("dataRetrieval", "lubridate", "here", "dplyr", "fasstr", "ggplot2"))

library(dataRetrieval)  # Direct API client for USGS water data
library(lubridate)      # Advanced date and time manipulation
library(here)           # Cross-platform project path management
library(dplyr)          # Data manipulation grammar
library(fasstr)         # Hydrologic summary statistics tool


# DATA ACQUISITION & LOCAL CACHING

# Establish localized raw data directory
if (!dir.exists(here("data", "raw"))) {
  dir.create(here("data", "raw"), recursive = TRUE)
}

local_data_path <- here("data", "raw", "va_watershed_30yr_streamflow.csv")

# Query the USGS API if a local file cache is not found
if (!file.exists(local_data_path)) {
  message("Local cache not found. Querying USGS API for 30-year record...")
  
  # 5 primary Virginia streamgages with continuous 30-year records
  target_va_stations <- c("02037500", "02029000", "01631000", "01643700", "01663500")
  
  va_watershed_data <- readNWISdv(
    siteNumbers = target_va_stations,
    parameterCd = "00060",   # Parameter code for Mean Daily Streamflow (cfs)
    startDate = "1996-01-01",  # 30-year minimum climate baseline
    endDate = "2026-08-01"
  )
  
  # Save to local directory (Git-ignored to protect repository size)
  write.csv(va_watershed_data, local_data_path, row.names = FALSE)
  message("Success! Raw 30-year data saved to local directory.")
  
} else {
  message("Loading cached 30-year USGS water data from local directory...")
  va_watershed_data <- read.csv(local_data_path)
}


# DATA TRANSFORMATION & COLUMN REFACTORING

# Clean and rename columns to match standard 'fasstr' specifications
fasstr_ready_data <- va_watershed_data %>%
  mutate(Date = as.Date(Date)) %>%  
  rename(
    STATION_NUMBER = site_no,       
    Value = X_00060_00003           
  ) %>%
  mutate(
    # FIXED: Convert to character AND pad with a leading zero if it is only 7 digits long
    STATION_NUMBER = stringr::str_pad(as.character(STATION_NUMBER), width = 8, side = "left", pad = "0"),
    
    # Map USGS numeric IDs to human-readable river strings
    river_name = case_when(
      STATION_NUMBER == "02037500" ~ "James River near Richmond",
      STATION_NUMBER == "02029000" ~ "James River at Cartersville",
      STATION_NUMBER == "01631000" ~ "Shenandoah River at Millville",
      STATION_NUMBER == "01643700" ~ "Potomac River near Wash DC",
      STATION_NUMBER == "01663500" ~ "Rappahannock River near Fredericksburg",
      TRUE ~ paste("Station", STATION_NUMBER)
    )
  )


# 7Q10 STATISTICAL MODELING & AUTOMATED DISTRIBUTION PLOTTING

message("Running Log-Pearson Type III distribution loops via fasstr...")

# Initialize blank dataframe to compile multi-station calculations
final_7q10_table <- data.frame(
  River_Location = character(),
  `7Q10_cfs` = numeric(),
  stringsAsFactors = FALSE
)

# Establish localized public output directory
if (!dir.exists(here("output"))) dir.create(here("output"))

unique_rivers <- unique(fasstr_ready_data$river_name)

# Sequentially calculate statistics and graphs for each river system
for (river in unique_rivers) {
  message(paste("Processing frequency analysis for:", river))
  
  # Filter to current river iteration and replace any 0 or negative values with 0.01.
  # This prevents log-transformation failures (log of 0 is mathematically undefined) 
  # while preserving extreme historical drought signatures.
  river_subset <- fasstr_ready_data %>% 
    filter(river_name == river) %>%
    mutate(Value = ifelse(Value <= 0, 0.01, Value))
  
  # A. Isolate specific 7Q10 quantile metrics directly
  q10_value <- fasstr::compute_frequency_quantile(
    data = river_subset,
    dates = Date,
    values = Value,
    roll_days = 7,          # The '7' in 7Q10: 7-day moving average window
    return_period = 10,     # The '10' in 7Q10: 10-year recurrence interval (10% annual chance)
    use_max = FALSE         # Directs calculation to evaluate minimum low-flow extremes
  )
  
  # Merge row into master compilation dataframe
  final_7q10_table <- rbind(
    final_7q10_table, 
    data.frame(River_Location = river, `7Q10_cfs` = q10_value)
  )
  
  # B. Generate comprehensive annual frequency plots
  freq_analysis <- fasstr::compute_annual_frequencies(
    data = river_subset,
    dates = Date,
    values = Value,
    roll_days = 7,          
    use_max = FALSE,
    fit_distr = "PIII"      # Fits data explicitly to Log-Pearson Type III
  )
  
  # FIXED: Extract using the exact 'Freq_Plot' tag exported by fasstr
  plot_obj <- freq_analysis$Freq_Plot
  
  if (!is.null(plot_obj)) {
    # Generate clean, lowercase file naming convention for local Mac workspace
    safe_name <- gsub(" ", "_", tolower(river))
    file_target <- here("output", paste0("plot_7q10_fit_", safe_name, ".png"))
    
    # Save crisp distribution graph to git-tracked local output directory
    ggplot2::ggsave(file_target, plot = plot_obj, width = 9, height = 6, dpi = 300)
  }
}

# RESULTS EXPORT & CONSOLE SUMMARY

# Print final calculation grid cleanly inside RStudio/VS Code console
print("--- FINAL CALCULATED 7Q10 VALUES (CFS) ---")
print(final_7q10_table)

# Save final matrix cleanly to your output folder
write.csv(final_7q10_table, here("output", "va_watershed_7Q10_results.csv"), row.names = FALSE)
message("Analysis complete! Clean 7Q10 data and curve plots written to /output.")
