<#
.SYNOPSIS
    Docker-based EnergyPlus simulation runner for Windows PowerShell

.DESCRIPTION
    This script builds the Docker container (if needed) and runs an EnergyPlus
    simulation inside the container where EnergyPlus 25.1.0 is installed.

.PARAMETER Build
    Build or rebuild the Docker image before running

.PARAMETER Idf
    Specify IDF file name or path (default: 1ZoneUncontrolled.idf)

.PARAMETER Weather
    Specify weather file name or path (default: San Francisco TMY3)

.EXAMPLE
    # Build Docker image and run default simulation
    .\run_docker_simulation.ps1 -Build

.EXAMPLE
    # Run with default files (1ZoneUncontrolled)
    .\run_docker_simulation.ps1

.EXAMPLE
    # Run with specific files
    .\run_docker_simulation.ps1 -Idf "5ZoneAirCooled.idf" -Weather "USA_CA_San.Francisco.Intl.AP.724940_TMY3.epw"

#>

param(
    [switch]$Build,
    [string]$Idf = "",
    [string]$Weather = "",
    [switch]$Help
)

# Show help if requested
if ($Help) {
    Get-Help $MyInvocation.MyCommand.Path -Detailed
    exit 0
}

# Configuration
$DockerImage = "energyplus-mcp-dev"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Color output functions
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput $Message "Green"
}

function Write-Error-Custom {
    param([string]$Message)
    Write-ColorOutput $Message "Red"
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-ColorOutput $Message "Yellow"
}

function Write-Info {
    param([string]$Message)
    Write-ColorOutput $Message "Cyan"
}

# Header
Write-Info "========================================"
Write-Info "EnergyPlus Docker Simulation Runner"
Write-Info "========================================"
Write-Host ""

# Check if Docker is available
try {
    $dockerVersion = docker --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Docker not found"
    }
} catch {
    Write-Error-Custom "✗ Docker is not installed or not running!"
    Write-Host ""
    Write-Host "Please install Docker Desktop from:"
    Write-Host "  https://www.docker.com/products/docker-desktop/" -ForegroundColor Blue
    Write-Host ""
    Write-Host "After installation:"
    Write-Host "  1. Start Docker Desktop"
    Write-Host "  2. Wait for it to fully start"
    Write-Host "  3. Run this script again"
    exit 1
}

# Check if Docker daemon is running
try {
    docker ps 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Docker daemon not running"
    }
} catch {
    Write-Error-Custom "✗ Docker is installed but not running!"
    Write-Host ""
    Write-Host "Please start Docker Desktop and try again."
    exit 1
}

Write-Success "✓ Docker is running"
Write-Host ""

# Build Docker image if requested or if it doesn't exist
$imageExists = docker images -q $DockerImage 2>&1
if ($Build -or -not $imageExists) {
    Write-Warning-Custom "Building Docker image..."
    Write-Warning-Custom "This may take a few minutes on first run..."
    Write-Host ""

    $devcontainerPath = Join-Path $ScriptDir ".devcontainer"
    Push-Location $devcontainerPath

    try {
        docker build -t $DockerImage . 2>&1 | ForEach-Object { Write-Host $_ }

        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Success "✓ Docker image built successfully!"
            Write-Host ""
        } else {
            Write-Error-Custom "✗ Docker image build failed!"
            Pop-Location
            exit 1
        }
    } finally {
        Pop-Location
    }
} else {
    Write-Success "✓ Docker image '$DockerImage' found"
    Write-Host ""
}

# Prepare Docker run command
$dockerArgs = @(
    "run",
    "--rm",
    "-i",
    "-v", "${ScriptDir}:/workspace",
    "-w", "/workspace",
    $DockerImage,
    "python", "run_simulation.py"
)

# Add optional arguments
if ($Idf) {
    $dockerArgs += @("--idf", $Idf)
}

if ($Weather) {
    $dockerArgs += @("--weather", $Weather)
}

# Show what we're running
Write-Info "Running simulation in Docker container..."
if ($Idf) {
    Write-Host "  IDF File: " -NoNewline
    Write-Success $Idf
}
if ($Weather) {
    Write-Host "  Weather File: " -NoNewline
    Write-Success $Weather
}
Write-Host ""
Write-Warning-Custom "Docker command:"
Write-Host "  docker $($dockerArgs -join ' ')"
Write-Host ""
Write-Info "========================================"
Write-Host ""

# Run the simulation
& docker $dockerArgs

# Check if successful
if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Success "========================================"
    Write-Success "Simulation completed successfully!"
    Write-Success "========================================"
    Write-Host ""
    Write-Host "Check the outputs directory for results:"
    $outputPath = Join-Path $ScriptDir "energyplus-mcp-server\outputs"
    Write-Info "  $outputPath"
    Write-Host ""
} else {
    Write-Host ""
    Write-Error-Custom "========================================"
    Write-Error-Custom "Simulation failed!"
    Write-Error-Custom "========================================"
    Write-Host ""
    Write-Host "Check the error messages above for details."
    exit 1
}
