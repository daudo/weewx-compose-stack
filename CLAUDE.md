# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Docker Compose stack for WeeWX weather station software. The project provides a production-ready multi-service deployment with nginx web serving, EcoWitt GW1000 driver integration, and Portainer compatibility.

**Built on**: [felddy/weewx-docker](https://github.com/felddy/weewx-docker) - Uses the upstream WeeWX container as the base.

## Development Commands

### Local Development Setup
```bash
# Copy and edit environment configuration
cp .env.example .env
# Edit .env file to set your GW1000 IP, location, coordinates, etc.
```

### Code Quality
```bash
# The project includes configuration for:
# - YAML: yamllint
# - Markdown: markdownlint (via .mdl_config.yaml)
# - General formatting: prettier
```

### Docker Operations
```bash
# Deploy the stack
docker compose up --detach

# Access WeeWX web interface
# Available at http://localhost:8080 (or custom NGINX_PORT)

# Install WeeWX extensions
docker compose run --rm weewx extension install --yes <extension-url>

# Install Python packages
docker compose run --rm --entrypoint pip weewx install <package>

# Update configuration after changing environment variables
./update-config.sh

# View logs for specific services
docker compose logs weewx
docker compose logs nginx
docker compose logs weewx-init
```

## Architecture

### Multi-Service Stack
The project now consists of three Docker services with unified initialization:

1. **weewx-init** - Unified initialization: creates WeeWX configuration, installs GW1000 driver and nginx configuration
2. **weewx** - Main WeeWX weather station service
3. **nginx** - Web server for serving WeeWX-generated content

### Container Structure
- **Base Image**: Python 3.13 with multi-stage build
- **User**: Non-root user `weewx` (UID 1000)
- **Data Volume**: `/data` - persists WeeWX configuration, database, and web content
- **Entrypoint**: `src/entrypoint.sh` - handles initialization and command routing

### Key Components

#### Unified Initialization (weewx-init)
- `init/Dockerfile.unified` - WeeWX-based container for unified setup tasks
- `init/init-weewx-unified.sh` - Main orchestrator that calls modular scripts:
  - `init/configure-weewx.sh` - Creates `weewx.conf` and applies environment variable configuration
  - `init/install-gw1000.sh` - Installs GW1000 driver and configures WeeWX for Ecowitt devices
  - `init/setup-nginx.sh` - Sets up nginx configuration for web interface
- Uses `felddy/weewx:5` image with access to all WeeWX tools
- Installs Python `six` library to shared volume (`/data/lib/python/site-packages`)
- Applies station configuration from environment variables to `weewx.conf`
- Installs GW1000 driver (`gw1000/gw1000.py`) to `/data/bin/user/`
- Installs nginx configuration (`nginx/nginx.conf`) to `/data/nginx/`
- Configures WeeWX to use GW1000 as station driver
- Sets up accumulator configurations for Ecowitt sensors
- Updates IP address configuration from environment variables
- `gw1000/gw1000.py` - Ecowitt Gateway driver for WS3800/WS3900/GW1000+ devices

#### Main WeeWX Service
- Uses `felddy/weewx:5` image which contains the WeeWX entrypoint and daemon

#### Web Server (Nginx)
- Uses `nginx:alpine` image with custom startup command
- Copies nginx configuration from shared volume (`/data/nginx/nginx.conf`) to standard location
- Serves WeeWX-generated web content from `/data/public_html`
- Provides optimized caching for static assets and HTML
- Includes security headers and error handling
- Exposes health check endpoint at `/health`

### Configuration Management
- Environment-driven station configuration using Docker Compose variables
- Initial setup creates `weewx.conf` in `/data` volume with station-specific settings
- **Configuration updates**: Environment variables are applied on every init container run
- Console logging is automatically configured for container environments
- Configuration can be upgraded using `weectl station upgrade`
- Environment variables (via `.env` file):
  - `GW1000_IP` - IP address of the weather station gateway (default: 192.168.1.10)
  - `NGINX_PORT` - Port for web interface access (default: 8080)
  - `WEEWX_LOCATION` - Weather station location description (default: "My Cosy Weather Station")
  - `WEEWX_LATITUDE` - Station latitude in decimal degrees (default: 42.2627)
  - `WEEWX_LONGITUDE` - Station longitude in decimal degrees (default: 11.3945)
  - `WEEWX_ALTITUDE` - Station altitude with unit (default: "587, meter")
  - `WEEWX_STATION_URL` - Optional website URL for the station (default: empty)
  - `WEEWX_RAIN_YEAR_START` - Month when rain year starts 1-12 (default: 1)
  - `WEEWX_WEEK_START` - First day of week 0=Mon, 6=Sun (default: 0)
  - `WEEWX_UNIT_SYSTEM` - Unit system for web interface: us, metric, metricwx (default: metric)

### Service Dependencies
- `weewx-init` runs first to handle all initialization (configuration, driver installation, nginx setup)
- `weewx` service waits for `weewx-init` to complete successfully  
- `nginx` service depends on both `weewx` and `weewx-init` to be ready
- All services share the `weewx_data` volume for data persistence

### Build Process
- Uses upstream `felddy/weewx:5` container image (no custom builds required)
- Multi-architecture support inherited from upstream container  
- Only builds the lightweight Alpine-based init container
- Documentation formatted with yamllint, markdownlint, and prettier

## Development Workflow

1. Make changes to orchestration or configuration
2. Test locally with `docker compose up --detach`
3. Verify configuration updates work with `./update-config.sh` 
4. Check documentation formatting if updating markdown/yaml
5. Submit pull request

## Portainer Deployment

### Universal docker-compose.yml Compatibility
The project now uses a single `docker-compose.yml` file that works with both local Docker Compose and Portainer deployments.

### Volume-Based Configuration Strategy
To avoid Portainer's file bind mounting limitations:
- **GW1000 driver**: Copied from build context to shared volume during `weewx-init`
- **Nginx configuration**: Copied from build context to shared volume during `weewx-init`
- **Python dependencies**: Installed to shared volume during `weewx-config-init`
- **No direct file mounts**: All configuration files are copied to volumes, not bind-mounted

### Portainer Deployment Steps
1. In Portainer: **Stacks** → **Add stack**
2. Choose **Repository** build method
3. Set Repository URL to your Git repository
4. Set Compose path to: `docker-compose.yml`
5. Add environment variables: `GW1000_IP` and `NGINX_PORT`
6. Deploy stack

### Key Solutions Implemented
- **Unified initialization**: Single container handles all setup with modular scripts
- **Shared volume strategy**: Eliminates file bind mounting issues
- **Original entrypoint reuse**: Maintains compatibility with upstream WeeWX changes
- **Standard nginx patterns**: Uses official Docker image practices for configuration
- **Environment-driven configuration**: Station settings configurable via Docker Compose variables

### Troubleshooting Portainer Issues
- **Build context errors**: All files now copied to volumes, no bind mounts required
- **Missing dependencies**: Python `six` library auto-installed during initialization
- **Configuration issues**: Uses original WeeWX entrypoint for reliable config generation
- **Sed pattern errors**: Fixed by using pipe delimiters in sed commands to handle special characters (commas, slashes)

## Hardware Integration

### Supported Weather Stations
The project now includes integrated support for Ecowitt/Fine Offset weather stations through the GW1000 driver:

- **WS3800/WS3900/WS3910** - Weather station consoles with built-in gateways
- **GW1000/GW1100/GW1200/GW2000** - Standalone gateway devices
- **WH2650/WH2680/WN1900** - Wi-Fi weather stations

### Driver Features
- Pulls data via Ecowitt LAN/Wi-Fi Gateway API (not push-based)
- Supports extended sensor arrays including lightning detection, air quality, and soil sensors
- Automatic IP address configuration via environment variables
- Battery and signal strength monitoring for wireless sensors