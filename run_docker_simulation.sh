#!/bin/bash
#
# Docker-based EnergyPlus simulation runner
#
# This script builds the Docker container (if needed) and runs an EnergyPlus
# simulation inside the container where EnergyPlus 25.1.0 is installed.
#
# Usage:
#   ./run_docker_simulation.sh [--build] [--idf IDF_FILE] [--weather EPW_FILE]
#
# Examples:
#   # Build Docker image and run default simulation
#   ./run_docker_simulation.sh --build
#
#   # Run with default files (1ZoneUncontrolled)
#   ./run_docker_simulation.sh
#
#   # Run with specific files
#   ./run_docker_simulation.sh --idf 5ZoneAirCooled.idf --weather USA_CA_San.Francisco.Intl.AP.724940_TMY3.epw
#

set -e  # Exit on error

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
BUILD_IMAGE=false
IDF_FILE=""
WEATHER_FILE=""
DOCKER_IMAGE="energyplus-mcp-dev"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --build)
            BUILD_IMAGE=true
            shift
            ;;
        --idf)
            IDF_FILE="$2"
            shift 2
            ;;
        --weather)
            WEATHER_FILE="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --build                Build/rebuild the Docker image before running"
            echo "  --idf FILE            Specify IDF file (default: 1ZoneUncontrolled.idf)"
            echo "  --weather FILE        Specify weather file (default: San Francisco TMY3)"
            echo "  -h, --help            Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}EnergyPlus Docker Simulation Runner${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Build Docker image if requested or if it doesn't exist
if $BUILD_IMAGE || ! docker image inspect $DOCKER_IMAGE &> /dev/null; then
    echo -e "${YELLOW}Building Docker image...${NC}"
    echo -e "${YELLOW}This may take a few minutes on first run...${NC}"
    echo ""

    cd "$SCRIPT_DIR/.devcontainer"
    docker build -t $DOCKER_IMAGE .

    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✓ Docker image built successfully!${NC}"
        echo ""
    else
        echo -e "${RED}✗ Docker image build failed!${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ Docker image '$DOCKER_IMAGE' found${NC}"
    echo ""
fi

# Prepare Docker run command
DOCKER_CMD="docker run --rm -i"
DOCKER_CMD="$DOCKER_CMD -v \"$SCRIPT_DIR:/workspace\""
DOCKER_CMD="$DOCKER_CMD -w /workspace"
DOCKER_CMD="$DOCKER_CMD $DOCKER_IMAGE"
DOCKER_CMD="$DOCKER_CMD python run_simulation.py"

# Add optional arguments
if [ ! -z "$IDF_FILE" ]; then
    DOCKER_CMD="$DOCKER_CMD --idf \"$IDF_FILE\""
fi

if [ ! -z "$WEATHER_FILE" ]; then
    DOCKER_CMD="$DOCKER_CMD --weather \"$WEATHER_FILE\""
fi

# Show what we're running
echo -e "${BLUE}Running simulation in Docker container...${NC}"
if [ ! -z "$IDF_FILE" ]; then
    echo -e "  IDF File: ${GREEN}$IDF_FILE${NC}"
fi
if [ ! -z "$WEATHER_FILE" ]; then
    echo -e "  Weather File: ${GREEN}$WEATHER_FILE${NC}"
fi
echo ""
echo -e "${YELLOW}Docker command:${NC}"
echo -e "  $DOCKER_CMD"
echo ""
echo -e "${BLUE}========================================${NC}"
echo ""

# Run the simulation
eval $DOCKER_CMD

# Check if successful
if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Simulation completed successfully!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "Check the outputs directory for results:"
    echo -e "  ${BLUE}$SCRIPT_DIR/energyplus-mcp-server/outputs/${NC}"
    echo ""
else
    echo ""
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}Simulation failed!${NC}"
    echo -e "${RED}========================================${NC}"
    echo ""
    echo "Check the error messages above for details."
    exit 1
fi
