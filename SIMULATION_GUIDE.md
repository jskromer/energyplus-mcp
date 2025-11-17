# EnergyPlus Simulation Guide

This guide explains how to run EnergyPlus simulations using the MCP server.

## Quick Start

### Option 1: Using Docker (Recommended)

The easiest way to run simulations is using the provided Docker script:

```bash
# Build Docker image and run default simulation
./run_docker_simulation.sh --build

# Run with default files (1ZoneUncontrolled)
./run_docker_simulation.sh

# Run with specific files
./run_docker_simulation.sh --idf 5ZoneAirCooled.idf --weather USA_CA_San.Francisco.Intl.AP.724940_TMY3.epw
```

The script will:
1. Build the Docker container with EnergyPlus 25.1.0 (if needed)
2. Run the simulation inside the container
3. Save results to `energyplus-mcp-server/outputs/`

### Option 2: Using Python Script Directly

If you have EnergyPlus installed locally:

```bash
cd energyplus-mcp-server
uv run python ../run_simulation.py
```

## Available Sample Files

### IDF Files (Building Models)

Located in `energyplus-mcp-server/sample_files/`:

1. **1ZoneUncontrolled.idf** (20KB)
   - Simple single-zone model
   - No HVAC control
   - Good for quick tests

2. **1ZoneEvapCooler.idf** (30KB)
   - Single zone with evaporative cooling
   - Basic HVAC system

3. **5ZoneAirCooled.idf** (163KB)
   - 5-zone building
   - VAV system with chiller
   - More realistic building

4. **5ZoneAirCooled_with_outputs.idf** (189KB)
   - Same as above
   - Pre-configured output variables

5. **AirflowNetwork_MultiZone_SmallOffice_VAV.idf** (173KB)
   - Small office building
   - Includes airflow network modeling
   - VAV system

6. **LgOffVAV.idf** (280KB)
   - Large office building
   - Complex VAV system
   - Most detailed model

### Weather Files (EPW)

Located in `energyplus-mcp-server/sample_files/`:

1. **USA_CA_San.Francisco.Intl.AP.724940_TMY3.epw** (1.6MB)
   - San Francisco, California
   - Typical Meteorological Year
   - Mild climate

## Simulation Output

Simulation results are saved to timestamped directories:

```
energyplus-mcp-server/outputs/
└── [IDF_NAME]_simulation_[TIMESTAMP]/
    ├── *.csv              # Comma-separated output data
    ├── *.eso              # EnergyPlus Standard Output
    ├── *.mtr              # Meter output
    ├── *.err              # Error/warning messages
    ├── *.html             # Summary reports
    └── *.sql              # SQL database of results
```

### Common Output Files

| File Type | Description |
|-----------|-------------|
| `*.csv` | Time-series data in CSV format |
| `*.eso` | Raw EnergyPlus output |
| `*.err` | Errors and warnings (check this first if simulation fails) |
| `*.html` | HTML summary report |
| `*.sql` | SQLite database with all results |

## Simulation Examples

### Example 1: Quick Test Simulation

Run the smallest model with default weather:

```bash
./run_docker_simulation.sh --idf 1ZoneUncontrolled.idf
```

**Expected runtime:** ~30 seconds
**Output size:** ~5 MB

### Example 2: Complete Building Simulation

Run a realistic 5-zone building:

```bash
./run_docker_simulation.sh --idf 5ZoneAirCooled.idf
```

**Expected runtime:** ~2-3 minutes
**Output size:** ~15 MB

### Example 3: Large Office Building

Run the most detailed model:

```bash
./run_docker_simulation.sh --idf LgOffVAV.idf
```

**Expected runtime:** ~5-10 minutes
**Output size:** ~50 MB

## Python Script Options

The `run_simulation.py` script supports these arguments:

```bash
python run_simulation.py [OPTIONS]

Options:
  --idf FILE          IDF file name or path (default: 1ZoneUncontrolled.idf)
  --weather FILE      Weather file name or path (default: San Francisco TMY3)
  --annual            Run annual simulation (default: True)
  --design-day        Run design day only (default: False)
  -h, --help          Show help message
```

### Examples

```bash
# Default simulation
python run_simulation.py

# Specific IDF file
python run_simulation.py --idf 5ZoneAirCooled.idf

# Design day only
python run_simulation.py --idf 1ZoneUncontrolled.idf --design-day

# Custom weather file
python run_simulation.py --idf 5ZoneAirCooled.idf --weather path/to/custom.epw
```

## Understanding Results

### Check Simulation Success

1. **Look for success message** in console output
2. **Check the .err file** in the output directory:
   ```bash
   cat energyplus-mcp-server/outputs/[SIMULATION_DIR]/*.err
   ```
3. **Verify output files exist**:
   - `.csv` files = simulation ran successfully
   - `.eso` file = raw output generated
   - `.html` file = summary report created

### Common Success Indicators

In the `.err` file, look for:
```
   EnergyPlus Completed Successfully
```

### Common Error Messages

| Error | Meaning | Solution |
|-------|---------|----------|
| "Severe Error: IDF file not found" | File path incorrect | Check file name and location |
| "Weather file not found" | EPW path incorrect | Verify weather file path |
| "Failed to converge" | HVAC sizing issues | Check HVAC system configuration |
| "Temperature out of bounds" | Unrealistic results | Review building envelope settings |

## Analyzing Results

### CSV Output Files

Time-series data in CSV format:

```bash
# View first few lines
head energyplus-mcp-server/outputs/[DIR]/[OUTPUT].csv

# Import to spreadsheet
libreoffice energyplus-mcp-server/outputs/[DIR]/[OUTPUT].csv
```

### HTML Reports

Summary reports with tables and charts:

```bash
# Open in browser
firefox energyplus-mcp-server/outputs/[DIR]/*.html
```

### SQL Database

Complete results in SQLite format:

```bash
# Query with sqlite3
sqlite3 energyplus-mcp-server/outputs/[DIR]/eplusout.sql "SELECT * FROM Zones;"
```

## Troubleshooting

### Docker Issues

**Problem:** Docker not found
```
Solution: Install Docker Desktop from https://www.docker.com/
```

**Problem:** Permission denied building image
```
Solution: Add your user to the docker group:
  sudo usermod -aG docker $USER
  # Then log out and back in
```

**Problem:** Image build fails
```
Solution:
1. Check internet connection
2. Try rebuilding: ./run_docker_simulation.sh --build
3. Check Docker has enough disk space
```

### Simulation Failures

**Problem:** IDD file not found
```
Solution: Make sure you're running inside Docker:
  ./run_docker_simulation.sh
```

**Problem:** Simulation crashes
```
Solution:
1. Check the .err file for specific errors
2. Try a simpler model first (1ZoneUncontrolled.idf)
3. Verify the weather file is valid
```

**Problem:** No output files generated
```
Solution:
1. Check write permissions on outputs/ directory
2. Review .err file for fatal errors
3. Ensure simulation actually ran (check logs)
```

## Advanced Usage

### Running Custom Simulations

1. Add your own IDF files to `energyplus-mcp-server/sample_files/`
2. Run with the new file:
   ```bash
   ./run_docker_simulation.sh --idf your_model.idf
   ```

### Using Different Weather Files

1. Download EPW files from:
   - https://energyplus.net/weather
   - https://climate.onebuilding.org/

2. Place in `energyplus-mcp-server/sample_files/`

3. Run simulation:
   ```bash
   ./run_docker_simulation.sh --weather your_weather.epw
   ```

### Batch Simulations

Run multiple simulations in sequence:

```bash
#!/bin/bash
for idf in energyplus-mcp-server/sample_files/*.idf; do
    ./run_docker_simulation.sh --idf $(basename "$idf")
done
```

## Performance Tips

1. **Start small**: Test with 1ZoneUncontrolled.idf first
2. **Check outputs**: Review .err file after each run
3. **Monitor resources**: Large models may need 4+ GB RAM
4. **Parallel runs**: Docker allows running multiple containers simultaneously

## Getting Help

- **EnergyPlus Documentation**: https://energyplus.net/documentation
- **Example Files**: Check `ExampleFiles/` in EnergyPlus installation
- **Weather Data**: https://energyplus.net/weather
- **MCP Server Tools**: See main README.md for all 35 available tools

## Next Steps

After running simulations:

1. **Visualize Results**
   - Use the MCP `create_interactive_plot` tool
   - Import CSV files into Excel/Python

2. **Modify Models**
   - Use MCP tools to inspect and modify IDF files
   - See `README.md` for available modification tools

3. **HVAC Analysis**
   - Use `discover_hvac_loops` to understand HVAC systems
   - Use `visualize_loop_diagram` to create diagrams

4. **Parametric Studies**
   - Modify parameters and re-run simulations
   - Compare results across different configurations
