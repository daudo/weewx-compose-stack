# WeeWX Docker Stack - Portainer Deployment Guide

This Docker Compose stack provides a complete WeeWX weather station setup with EcoWitt GW1000 driver, nginx web server, and environment variable configuration - optimized for Portainer deployment.

Built on [felddy/weewx-docker](https://github.com/felddy/weewx-docker) container with orchestration and additional services.

**Note**: nginx serves HTTP only - intended to run behind a reverse proxy/load balancer for HTTPS.

## Quick Start

### 1. Prepare Environment Variables

In Portainer, when creating the stack, set these environment variables:

| Variable | Description | Default Value | Required |
|----------|-------------|---------------|----------|
| `GW1000_IP` | IP address of your GW1000 gateway | `192.168.1.10` | Yes |
| `NGINX_PORT` | External port for web interface | `8080` | Yes |
| `WEEWX_LOCATION` | Weather station location description | `Home Weather Station` | Yes |
| `WEEWX_LATITUDE` | Station latitude in decimal degrees | `40.7128` (NYC) | Yes |
| `WEEWX_LONGITUDE` | Station longitude in decimal degrees | `-74.0060` (NYC) | Yes |
| `WEEWX_ALTITUDE` | Station altitude with unit | `100, foot` | Yes |
| `WEEWX_STATION_URL` | Website URL for your station | _(empty)_ | No |
| `WEEWX_RAIN_YEAR_START` | Month when rain year starts (1-12) | `1` (January) | Yes |
| `WEEWX_WEEK_START` | First day of week (0=Mon, 6=Sun) | `6` (Sunday) | Yes |
| `WEEWX_UNIT_SYSTEM` | Unit system for web interface | `metric` | Yes |

**Important Notes:**

- **Latitude/Longitude**: Use decimal degrees, negative for south/west hemispheres
- **Altitude**: Format must be "number, unit" where unit is either "foot" or "meter"
- **Station URL**: Must start with `http://` or `https://` if provided
- **Rain Year Start**: 1=January, 10=October, etc.
- **Week Start**: 0=Monday, 1=Tuesday, ..., 6=Sunday
- **Unit System**: `us` (Fahrenheit, inches), `metric` (Celsius, mm), or `metricwx` (meteorological metric)

### 2. Deploy Stack

1. In Portainer, go to **Stacks** → **Add stack**
2. Give it a reasonable name, eg `weewx5`
3. In Build Method, choose "Repository"
   1. Repository URL: https://github.com/daudo/weewx-compose-stack
   2. Repository Reference: refs/heads/main
   3. Compose path: **docker-compose.yml**
4. Scroll down to **Environment variables** and add:
   - `GW1000_IP=192.168.1.10` (adjust to your device's IP)
   - `NGINX_PORT=8080` (adjust to desired port)
   - `WEEWX_LOCATION=My Cosy Weather Station` (describe your location)
   - `WEEWX_LATITUDE=47.2626` (your latitude in decimal degrees)
   - `WEEWX_LONGITUDE=11.3945` (your longitude in decimal degrees)
   - `WEEWX_ALTITUDE=587, meter` (your altitude with unit)
   - `WEEWX_STATION_URL=https://myweather.example.com` (optional)
   - `WEEWX_RAIN_YEAR_START=10` (optional, eg. 10 = October starts the rain year)
   - `WEEWX_WEEK_START=0` (optional, 0=Monday, 6=Sunday)
   - `WEEWX_UNIT_SYSTEM=metric` (optional, metric for Celsius/mm, us for Fahrenheit/inches)
5. Click **Deploy the stack**

**Note**: The docker-compose.yml file uses volume-based configuration copying to ensure compatibility with both local Docker Compose and Portainer deployments.

### 3. First Run Setup

On first deployment, the stack runs in two stages:

1. **weewx-init** container runs once to:
   - Generate initial WeeWX configuration (`weewx.conf`)
   - Apply environment variable configuration to station settings
   - Install the GW1000 driver to shared volume
   - Install nginx configuration to shared volume  
   - Configure WeeWX for your GW1000 device
   - Set up sensor data collection
   - Exit successfully (code 0)

2. **weewx** container starts normally and:
   - Begins collecting weather data from GW1000
   - Generates web reports every 5 minutes
   - Runs continuously

3. **nginx** container serves the web interface at `http://your-server:8080`

## Architecture

```
┌─────────────────┐     ┌──────────────┐     ┌─────────────────┐
│   weewx-init    │───▶│    weewx     │───▶│     nginx       │
│ (unified setup: │     │  (data gen)  │     │  (web server)   │
│  conf + drivers │     │              │     │                 │
│   + nginx.conf) │     │              │     │                 │
└─────────────────┘     └──────────────┘     └─────────────────┘
         │                      │                      │
         ▼                      ▼                      ▼
┌──────────────────────────────────────────────────────────────────────────────────────┐
│                              weewx_data volume                                       │
│  /data/weewx.conf  /data/bin/user/gw1000.py  /data/nginx/nginx.conf  /data/archive/  │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

## Services

### weewx-init

- **Purpose**: Unified one-time setup container
- **Function**: Creates WeeWX configuration, installs GW1000 driver, sets up nginx config
- **Lifecycle**: Runs once per stack deployment
- **Dependencies**: None

### weewx

- **Purpose**: Main weather data collection and processing
- **Function**: Collects data from GW1000 compatible devices, generates web reports
- **Lifecycle**: Runs continuously, restarts on failure
- **Dependencies**: weewx-init (must complete successfully)

### nginx

- **Purpose**: Web server for weather station interface
- **Function**: Serves static HTML/CSS/images from WeeWX
- **Lifecycle**: Runs continuously, restarts on failure
- **Dependencies**: weewx (for shared volume)

## Configuration

### GW1000 Network Setup

Ensure your GW1000 or compatible device is:

1. Accessible from your Docker host
2. Has a static IP address (recommended)
3. API is accessible (test with: `curl http://GW1000_IP/get_livedata_info`)

### Port Configuration

- **Default nginx port**: 8080
- **To change**: Update `NGINX_PORT` environment variable
- **Load balancer**: Point to `http://docker-host:NGINX_PORT`

### Data Persistence

- **Volume**: `weewx_data` (managed by Docker)
- **Location**: Contains WeeWX config, database, and web files
- **Backup**: Back up this volume for data persistence

## Updating Configuration

If you need to change your environment variables after initial deployment:

### Method 1: Restart the Stack (Recommended)

1. Update your environment variables in Portainer (Stack → weewx5 → Environment variables)
2. Click **Pull and redeploy**
3. The weewx-init container will run again and apply the new settings

### Method 2: Manual Configuration Update (Docker Compose only)

If using Docker Compose locally, you can update configuration without full restart:

```bash
# Edit your .env file with new values
vi .env

# Run the update script
./update-config.sh
```

## Troubleshooting

### Check Container Status

```bash
docker compose ps
```

### View Logs

```bash
# WeeWX logs (data collection)
docker compose logs weewx

# Init container logs (setup)
docker compose logs weewx-init

# Web server logs
docker compose logs nginx
```

### Manual Configuration

If needed, you can access and modify configuration:

```bash
# Access WeeWX container
docker compose exec weewx bash

# Edit configuration
vi /data/weewx.conf

# Restart to apply changes
docker compose restart weewx
```

## GW1000 Driver Setup

The GW1000 driver (`gw1000/gw1000.py`) was obtained from the backup repository:

- **Original Source**: https://github.com/gjr80/weewx-gw1000 (no longer available)
- **Backup Repository**: https://github.com/hoetzgit/weewx-gw1000
- **Version**: v0.6.3 (2 August 2024)

### How the driver was obtained:

```bash
# Clone the backup repository
git clone https://github.com/hoetzgit/weewx-gw1000.git

# Copy the driver file
cp weewx-gw1000/bin/user/gw1000.py /path/to/weewx-compose-stack/gw1000/
```

The driver is automatically installed by the `weewx-init` container during stack deployment.

Unfortunately, the future of the driver is more than uncertain, so future WeeWX version might be incompatible with the latest official version of the GW1000 driver.

## Updates

To update the GW1000 driver:

1. Download latest `gw1000.py` from the backup repository
2. Replace `gw1000/gw1000.py` in the project directory
3. Rebuild the init container: `docker compose build weewx-init`
4. Restart the stack: `docker compose up -d`

## Support

- WeeWX Documentation: https://weewx.com/docs/
- GW1000 Driver: https://github.com/hoetzgit/weewx-gw1000
- Issues: Check container logs first, then consult WeeWX forums
