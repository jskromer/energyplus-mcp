#!/usr/bin/env python3
"""
Simple EnergyPlus simulation runner script

This script demonstrates how to run an EnergyPlus simulation using the
energyplus_mcp_server package.

Usage:
    python run_simulation.py [--idf IDF_FILE] [--weather EPW_FILE]

Examples:
    # Run with defaults (1ZoneUncontrolled + San Francisco weather)
    python run_simulation.py

    # Run with custom files
    python run_simulation.py --idf 5ZoneAirCooled.idf --weather USA_CA_San.Francisco.Intl.AP.724940_TMY3.epw
"""

import argparse
import json
import sys
from pathlib import Path

# Add the energyplus-mcp-server to Python path
server_path = Path(__file__).parent / "energyplus-mcp-server"
sys.path.insert(0, str(server_path))

try:
    from energyplus_mcp_server.energyplus_tools import EnergyPlusManager
    from energyplus_mcp_server.config import Config, PathConfig
except ImportError as e:
    print(f"Error importing EnergyPlus MCP modules: {e}")
    print("\nPlease ensure dependencies are installed:")
    print("  cd energyplus-mcp-server && uv sync")
    sys.exit(1)


def main():
    parser = argparse.ArgumentParser(
        description="Run an EnergyPlus simulation using the MCP server tools"
    )
    parser.add_argument(
        "--idf",
        default="1ZoneUncontrolled.idf",
        help="IDF file name or path (default: 1ZoneUncontrolled.idf)"
    )
    parser.add_argument(
        "--weather",
        default="USA_CA_San.Francisco.Intl.AP.724940_TMY3.epw",
        help="Weather file name or path (default: San Francisco TMY3)"
    )
    parser.add_argument(
        "--annual",
        action="store_true",
        default=True,
        help="Run annual simulation (default: True)"
    )
    parser.add_argument(
        "--design-day",
        action="store_true",
        default=False,
        help="Run design day simulation (default: False)"
    )

    args = parser.parse_args()

    print("=" * 70)
    print("EnergyPlus MCP Simulation Runner")
    print("=" * 70)
    print()

    # Configure paths to use the current directory structure
    workspace_root = str(Path(__file__).parent / "energyplus-mcp-server")

    # Create necessary directories before initializing config
    import os
    os.makedirs(os.path.join(workspace_root, "logs"), exist_ok=True)
    os.makedirs(os.path.join(workspace_root, "outputs"), exist_ok=True)

    # Set environment variable for EnergyPlus IDD path
    os.environ['EPLUS_IDD_PATH'] = os.path.join(
        os.path.expanduser('~'),
        'energyplus_install',
        'Energy+.idd'
    )

    # Create config with custom paths
    from energyplus_mcp_server.config import EnergyPlusConfig, ServerConfig

    path_config = PathConfig(
        workspace_root=workspace_root,
        sample_files_path=os.path.join(workspace_root, "sample_files"),
        output_dir=os.path.join(workspace_root, "outputs")
    )

    config = Config(
        paths=path_config,
        energyplus=EnergyPlusConfig(),
        server=ServerConfig()
    )

    print(f"Workspace: {workspace_root}")
    print(f"Sample files: {config.paths.sample_files_path}")
    print(f"Output directory: {config.paths.output_dir}")
    print()

    # Initialize the EnergyPlus manager
    print("Initializing EnergyPlus Manager...")
    try:
        manager = EnergyPlusManager(config=config)
        print("✓ EnergyPlus Manager initialized successfully")
    except Exception as e:
        print(f"✗ Error initializing EnergyPlus Manager: {e}")
        print("\nPossible issues:")
        print("  - EnergyPlus not installed")
        print("  - IDD file not found")
        print("\nRecommended solution:")
        print("  Run this script inside the Docker container:")
        print("    docker run -it --rm -v $(pwd):/workspace -w /workspace energyplus-mcp-dev python run_simulation.py")
        sys.exit(1)

    print()
    print("-" * 70)
    print("Simulation Configuration")
    print("-" * 70)
    print(f"IDF File: {args.idf}")
    print(f"Weather File: {args.weather}")
    print(f"Annual Simulation: {args.annual}")
    print(f"Design Day: {args.design_day}")
    print()

    # Run the simulation
    print("-" * 70)
    print("Running Simulation...")
    print("-" * 70)

    try:
        result_json = manager.run_simulation(
            idf_path=args.idf,
            weather_file=args.weather,
            annual=args.annual,
            design_day=args.design_day
        )

        # Parse and display results
        result = json.loads(result_json)

        print()
        print("=" * 70)
        print("SIMULATION COMPLETE!")
        print("=" * 70)
        print()
        print(f"Status: {'✓ SUCCESS' if result.get('success') else '✗ FAILED'}")
        print(f"Duration: {result.get('simulation_duration', 'N/A')}")
        print(f"Output Directory: {result.get('output_directory', 'N/A')}")
        print()

        if result.get('output_files'):
            print("Output Files:")
            for file_info in result['output_files']:
                if isinstance(file_info, dict):
                    print(f"  • {file_info.get('type', 'File')}: {file_info.get('path', 'N/A')}")
                else:
                    print(f"  • {file_info}")

        print()
        print("=" * 70)

        # Save full results to JSON file
        result_file = Path(workspace_root) / "last_simulation_result.json"
        with open(result_file, 'w') as f:
            json.dump(result, f, indent=2)
        print(f"Full results saved to: {result_file}")

        return 0

    except Exception as e:
        print()
        print("=" * 70)
        print("SIMULATION FAILED!")
        print("=" * 70)
        print(f"Error: {e}")
        print()

        import traceback
        print("Full traceback:")
        traceback.print_exc()

        return 1


if __name__ == "__main__":
    sys.exit(main())
