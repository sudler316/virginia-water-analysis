install.packages(c("dataRetrieval", "tidyverse", "ggplot2", "lubridate", "here", "dplyr", "scales"))

# ==============================================================================
# PORTFOLIO PROJECT: VIRGINIA WATERSHED WATER SUPPLY ANALYSIS
# Data Source: USGS National Water Information System (NWIS)
# Target Parameters: Daily Streamflow (00060)
# Timeline: 2025-01-01 to 2026-08-01
# ==============================================================================

# Load required packages (Install first via console if missing)
library(dataRetrieval)
library(ggplot2)
library(lubridate)
library(here)
library(dplyr)
library(scales)

# ------------------------------------------------------------------------------
# DATA ACQUISITION (Automated & Local Caching)
# ------------------------------------------------------------------------------

# Define cross-platform hidden directories
if (!dir.exists(here("data", "raw"))) {
  dir.create(here("data", "raw"), recursive = TRUE)
}

local_data_path <- here("data", "raw", "va_watershed_streamflow.csv")

# Fetch data via API if not cached locally
if (!file.exists(local_data_path)) {
  message("Local data cache not found. Querying USGS API via dataRetrieval...")
  
  target_va_stations <- c("02037500", "02029000", "01631000", "01643700", "01663500", "0205450393")
  
  va_watershed_data <- readNWISdv(
    siteNumbers = target_va_stations,
    parameterCd = "00060", 
    startDate = "2025-01-01",
    endDate = "2026-08-01"
  )
  
  # Cache the file locally (Git will automatically ignore this file)
  write.csv(va_watershed_data, local_data_path, row.names = FALSE)
  message("Success! Raw data saved to local directory.")
  
} else {
  message("Loading cached USGS water data from local directory...")
  va_watershed_data <- read.csv(local_data_path)
}

# ------------------------------------------------------------------------------
# DATA TRANSFORMATION & CLEANING
# ------------------------------------------------------------------------------

# Format dates explicitly
va_watershed_data$Date <- as.Date(va_watershed_data$Date)

# Restructure columns and re-code raw station numbers to human-readable names
structured_data <- va_watershed_data %>%
  rename(
    station_id = site_no,
    date = Date,
    streamflow_cfs = X_00060_00003,
    status_code = X_00060_00003_cd
  ) %>%
  mutate(
    station_id = as.character(station_id),
    river_name = case_when(
      station_id == "02037500" ~ "James River near Richmond",
      station_id == "02029000" ~ "James River at Cartersville",
      station_id == "01631000" ~ "Shenandoah River at Millville",
      station_id == "01643700" ~ "Potomac River near Wash DC",
      station_id == "01663500" ~ "Rappahannock River near Fredericksburg",
      station_id == "0205450393" ~ "Roanoke River at Roanoke",
      TRUE ~ paste("Station", station_id)
    )
  )

# ------------------------------------------------------------------------------
# VISUALIZATION
# ------------------------------------------------------------------------------

# Generate time-series plot
streamflow_plot <- ggplot(structured_data, aes(x = date, y = streamflow_cfs, color = river_name)) +
  geom_line(alpha = 0.8, linewidth = 0.8) +
  scale_y_log10(labels = scales::comma) + 
  scale_color_brewer(palette = "Set2") +   
  labs(
    title = "Virginia Watershed Daily Streamflow Trends",
    subtitle = "Data Source: USGS NWIS (2025 - 2026)",
    x = "Timeline",
    y = "Streamflow (Cubic Feet per Second - Log Scale)",
    color = "River Monitoring Station"
  ) +
  theme_minimal() +
  theme(
    legend.position = "bottom",
    legend.direction = "vertical", 
    plot.title = element_text(face = "bold", size = 14),
    panel.grid.minor = element_blank()
  )

# Show plot in RStudio
print(streamflow_plot)

# Export visualization to local output folder (Git will automatically ignore)
if (!dir.exists(here("output"))) dir.create(here("output"))
ggsave(here("output", "va_streamflow_trends.png"), plot = streamflow_plot, width = 10, height = 6)
