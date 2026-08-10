# Virginia Watershed Water Supply Analysis

This repository contains a completed, automated R pipeline that programmatically ingests, transforms, and visualizes daily mean streamflow data across critical Virginia river basins. It demonstrates core data engineering and analytical workflows required for public water resource management, including automated API consumption, local caching strategies, and data visualization.

(Note: If running this locally for the first time, execute the script to generate and save this high-resolution time-series chart directly to your local /output directory)


# Technical Skills & Methodologies Demonstrated

Hydrological Data Ingestion & API Integration 
- Programmatic Sourcing: Queries the live USGS NWIS API via the dataRetrieval package.
- Parameter Isolation: Targets code 00060 to explicitly capture continuous daily mean streamflow values in cubic feet per second (cfs).
- Automated Architecture: Programmed the script to dynamically generate missing local directory structures (data/raw/, output/).
- Local Caching Design: Implements an automated caching mechanism that skips external API calls if local data exists.

Data Transformation & Schema Standardization
- Relational Mapping: Maps raw alphanumeric USGS gauge IDs into human-readable station names using dplyr::case_when().
- Data Cleansing: Formats raw strings into explicit as.Date types and standardizes namespaces using the tidyverse framework.

Advanced Hydrological Visualization
- Logarithmic Scaling: Utilizes scale_y_log10() to resolve highly disparate flow volumes across small headwaters and major rivers simultaneously.
- Publication-Ready Layouts: Modifies theme layers, applies a colorblind-friendly palette (Set2), and formats labels using thousands-separators.

# Hydrological Insights & Findings

- Flow Differentiation: Log-scale formatting successfully separates baseline low-flow patterns on minor systems from peak discharge events on massive mainstem rivers.
- Seasonal Drawdown Monitoring: The pipeline successfully isolates late-summer drawdown periods from winter/spring recharge events, reflecting characteristic Mid-Atlantic hydrological regimes.
- VWP Permitting Support: Instream flow analysis supports Virginia Water Protection (VWP) permitting workflows by helping identify low-flow thresholds (7Q10) required to establish safe withdrawal limits.
- Drought Evaluation: Automated generation of updated hydrographs assists in regional drought stage declarations across Virginia’s drought evaluation regions.


# Repository Structure

```text
├── analysis.R                  # Core ETL and visualization pipeline script
├── .gitignore                  # Prevents raw cached data from being tracked
├── data/
│   └── raw/                    # Local USGS .csv data cache (Git-ignored)
└── output/
    └── va_streamflow_trends.png # Exported time-series plot output
```


## Getting Started:

### 1. Clone the repo

### 2. Install required packages
install.packages(c("dataRetrieval", "tidyverse", "ggplot2", "lubridate", "here", "dplyr", "scales"))

### 3. Run the complete analysis script
source("analysis.R")

