# Virginia Watershed Water Supply Analysis: 7Q10 Drought Metric Pipeline

## Project Overview
This project establishes an automated, reproducible engineering pipeline in R to calculate the **7Q10 low-flow statistic** across primary major river systems in Virginia. The 7Q10 metric represents the lowest 7-day average streamflow expected to occur once every 10 years (a 10% non-exceedance probability in any given year). It serves as a foundational baseline for state regulatory limits, National Pollutant Discharge Elimination System (NPDES) dilution allowances, and municipal water security planning.

## Data Source & Core Methodology
- **Source:** USGS National Water Information System (NWIS) using the `dataRetrieval` API client.
- **Parameter:** Daily Mean Streamflow in Cubic Feet per Second (cfs), Parameter Code `00060`.
- **Duration:** 30 years of continuous daily data (1996 to 2026) to fulfill legal and statistical return-period validation benchmarks.
- **Framework:** The pipeline leverages the **`fasstr` (Flow Analysis Summary Statistics Tool for R)** package to compute continuous 7-day moving averages and isolate annual minimums aligned with the hydrologic climatic year (starting April 1st to prevent seasonal drought artificial splitting).

## Technical Implementation, Code Debugging & Corrections
During development, several technical constraints, namespace updates, and data anomalies were caught, refactored, and optimized to ensure pipeline stability:

1. **Function Name & Namespace Calibration:** Standard structural calculations were updated from unexported placeholders to `fasstr`'s explicit core function `compute_frequency_quantile()`. Visual plot tracking was adjusted to target the correct list item `Freq_Plot` to ensure line graphs compile without returning empty (`NULL`) variables.
2. **String Key Constraints:** The distribution configuration argument was debugged from a Roman numeral variant (`"PIIII"`) to the strict, four-character package syntax identifier **`"PIII"`** to satisfy internal string validation rules.
3. **Data Type & Leading Zero Alignment:** When loading local CSV cache files, the R runtime dropped leading zeros from station IDs (e.g., converting `"01631000"` to `1631000`), breaking string-matching logic. This was corrected by integrating `stringr::str_pad()` to dynamically re-apply 8-digit padding, allowing human-readable string mapping to succeed seamlessly.
4. **Zero-Flow & Negative Value Transformations:** The Log-Pearson Type III distribution requires converting raw streamflow values into logarithmic values ($log_{10}(Q)$). Because the logarithm of zero or negative numbers is mathematically undefined, gauges experiencing absolute dry-ups or sensor interference cause statistical engines to crash. This was resolved by implementing an inline conditional mutation (`ifelse(Value <= 0, 0.01, Value)`) to ensure mathematical convergence while accurately preserving historical drought realities.

## Key Findings & Summary Data
The calculated 7Q10 thresholds represent the absolute physical boundaries below which point-source waste dilution fails and aquatic habitats collapse. 

| River Location Monitoring Station | USGS Gauge ID | Calculated 7Q10 Threshold (cfs) | Water Supply Vulnerability Assessment |
| :--- | :--- | :--- | :--- |
| **James River near Richmond** | 02037500 | 569.41 | **Low Vulnerability:** High, stable baseflow reservoir. |
| **James River at Cartersville** | 02029000 | 621.45 | **Low Vulnerability:** Large drainage basin provides upstream buffer. |
| **Shenandoah River at Millville** | 01631000 | 235.36 | **Medium-Low Vulnerability:** Regional karst geology sustains baseline flows. |
| **Rappahannock River near Fredericksburg** | 01663500 | 4.63 | **High Vulnerability:** Prone to extreme seasonal depletion. |
| **Potomac River near Wash DC** | 01643700 | 0.10 | **Critical Vulnerability:** Near-complete flow cessation; zero allocation margin. |

### Summary Visualizations
The automated processing loop generates individual Log-Pearson Type III distribution curve plots for each basin, located in the `/output/` directory as `plot_7q10_fit_[river_name].png`. These plots visualize the correlation between historical low-flow observations and the statistical distribution model.

## Directory Structure & Security Model
The project relies on strict cross-platform local caching and file isolation to ensure massive underlying streamflow records remain localized:
- `/data/raw/`: Locally caches multi-megabyte raw API queries. (Configured in `.gitignore` to prevent repository bloating or raw data leakage).
- `/output/`: Holds the computed `va_watershed_7Q10_results.csv` data summaries and individual Log-Pearson Type III return-frequency graphs. This directory is explicitly **tracked and exposed** to publicly display final pipeline capabilities.

## Future Work & Scalability
To build upon this foundational asset, future iterations of this pipeline will prioritize the following expansion modules:
- **Climate Trend Stationarity Assessments:** The standard 7Q10 metric assumes hydrologic stationarity (that the past 30 years represent future probabilities). Future work will incorporate Mann-Kendall trend tests to evaluate if low-flow regimes are shifting over time due to climate warming.
- **Dynamic Climate Scenario Comparisons:** Compare the historical 30-year 7Q10 baseline against localized climate model projections to estimate future reductions in safe drinking water withdrawal caps.
- **Automated Gauge Filtering:** Implement an upstream boundary filter to dynamically detect and drop gauges that feature artificial flow augmentations (like dam releases or reservoir controls) to isolate true unimpaired runoff trends.

