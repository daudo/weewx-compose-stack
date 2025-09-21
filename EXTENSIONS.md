# WeeWX Extensions

This Docker stack includes several WeeWX extensions that enhance functionality and provide modern interfaces for weather data.

## Available Extensions

### Belchertown

Modern, responsive web skin that provides a mobile-friendly interface with real-time updates, weather maps, and customizable layouts.

**Purpose**: Replaces the default WeeWX web interface with a contemporary design  
**Version**: 1.3.1 (stable release with Python 3.13 compatibility fixes)  
**Status**: Enabled by default

### GW1000 Driver

Hardware driver for Ecowitt/Fine Offset weather stations that connects to GW1000-compatible gateways via LAN/Wi-Fi.

**Purpose**: Enables data collection from Ecowitt weather stations  
**Supported Hardware**: WS3800/WS3900, GW1000/GW1100/GW2000, WH2650/WH2680  
**Status**: Enabled by default

### Inigo

Data API extension that provides JSON endpoints for the weeWXWeatherApp Android application.

**Purpose**: Enables mobile app access to weather data  
**Android App**: [weeWXWeatherApp](https://github.com/evilbunny2008/weeWXWeatherApp)  
**Status**: Enabled by default

## Environment Variables

### Core WeeWX Configuration

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `WEEWX_LOCATION` | Weather station location description | `My Cosy Home Weather Station` | Yes |
| `WEEWX_VERBOSE_HARDWARE` | Verbose description of weather station hardware | `Personal Weather Station` | No |
| `WEEWX_LATITUDE` | Station latitude in decimal degrees | `47.2626` | Yes |
| `WEEWX_LONGITUDE` | Station longitude in decimal degrees | `11.3945` | Yes |
| `WEEWX_ALTITUDE` | Station altitude with unit | `587, meter` | Yes |
| `WEEWX_STATION_URL` | Website URL for your station | _(empty)_ | No |
| `WEEWX_RAIN_YEAR_START` | Month when rain year starts (1-12) | `1` | No |
| `WEEWX_WEEK_START` | First day of week (0=Mon, 6=Sun) | `0` | No |
| `WEEWX_UNIT_SYSTEM` | Unit system for web interface | `metric` | No |
| `WEEWX_LANGUAGE` | Language code for interface | `en` | No |
| `WEEWX_TIMEZONE` | Timezone for display in skins (IANA format) | _(system default)_ | No |
| `WEEWX_SKIN` | Default WeeWX skin selection | `Belchertown` | No |

### Infrastructure Configuration

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `GW1000_IP` | IP address of weather station gateway | `192.168.1.10` | Yes |
| `NGINX_PORT` | External port for web interface | `8080` | Yes |

### Extension Control

| Variable | Description | Default | Extension |
|----------|-------------|---------|-----------|
| `ENABLE_GW1000_DRIVER` | Enable GW1000 driver installation | `true` | GW1000 |
| `GW1000_USE_PIEZO_RAIN` | Use piezo rain sensors (WS90/WS85) instead of traditional rain gauge | `false` | GW1000 |
| `ENABLE_BELCHERTOWN_SKIN` | Enable Belchertown skin installation | `true` | Belchertown |
| `BELCHERTOWN_VERSION` | Belchertown skin version to install | `1.3.1` | Belchertown |
| `ENABLE_INIGO_EXTENSION` | Enable Inigo extension installation | `true` | Inigo |
| `INIGO_VERSION` | Inigo extension version to install | `1.0.17` | Inigo |

## Configuration Notes

### Location and Coordinates

- **Latitude/Longitude**: Use decimal degrees format (negative values for south/west hemispheres)
- **Altitude**: Format must be "number, unit" where unit is "foot" or "meter"
- **Example**: `WEEWX_LATITUDE=47.2626` (Seattle), `WEEWX_ALTITUDE=587, meter`

### Unit Systems

- **us**: Fahrenheit, inches, miles (US Imperial)
- **metric**: Celsius, millimeters, kilometers  
- **metricwx**: Meteorological metric (Celsius, millimeters, knots)

### Language Support

Supported language codes: `en` (English), `de` (German), `fr` (French), `es` (Spanish), `it` (Italian), `ca` (Catalan)

**Note**: Language support varies by skin. Belchertown includes translation files for all supported languages.

### Timezone Support

Configure timezone display using the `WEEWX_TIMEZONE` environment variable:

- **Format**: IANA timezone format (e.g., `Europe/Berlin`, `America/New_York`)
- **Effect**: Sets timezone for Belchertown skin display and includes timezone abbreviation in timestamps
- **Example**: Setting `WEEWX_TIMEZONE=Europe/Berlin` displays times as "21. September 2025, 16:45:00 CEST"
- **Default**: Uses system timezone when not specified

Common European timezones:
- `Europe/Berlin` - Germany (CEST/CET)
- `Europe/Paris` - France (CEST/CET)  
- `Europe/Zurich` - Switzerland (CEST/CET)
- `Europe/Vienna` - Austria (CEST/CET)
- `Europe/Rome` - Italy (CEST/CET)

## Extension Details

### Belchertown Configuration

The Belchertown skin automatically configures itself based on the core WeeWX environment variables:

- **Site title**: Uses `WEEWX_LOCATION`
- **Manifest settings**: Generates progressive web app configuration
- **Labels and footer**: Customized with station information
- **Language**: Respects `WEEWX_LANGUAGE` setting
- **Timezone**: Configures display timezone and moment.js formats with `WEEWX_TIMEZONE`

### GW1000 Driver Configuration

The GW1000 driver automatically configures sensor mapping and accumulator settings:

- **IP address**: Configured from `GW1000_IP`
- **Sensor support**: Lightning detection, air quality, soil sensors, battery monitoring
- **Data collection**: 20-second polling interval for real-time updates

#### Piezo Rain Sensor Support

For weather stations with piezo rain sensors (WS90/WS85), set `GW1000_USE_PIEZO_RAIN=true`:

- **Traditional rain gauges** (default): Uses `t_rain` and `t_rainrate` fields from mechanical rain gauge
- **Piezo rain sensors**: Maps WeeWX standard `rain` and `rainRate` fields to piezo data (`p_rain`, `p_rainrate`)
- **Field mapping**: When enabled, piezo rain data appears in standard WeeWX database fields
- **Skin compatibility**: Works with any WeeWX skin (Belchertown, Seasons, etc.) without modification
- **Backward compatibility**: Can be toggled between piezo and traditional modes

### Inigo Extension Configuration

The Inigo extension creates API endpoints and settings file:

- **Unit system**: Automatically matches `WEEWX_UNIT_SYSTEM` setting
- **Station info**: Uses location and coordinate variables
- **Data format**: Compatible with weeWXWeatherApp Android application

## Adding New Extensions

To add custom extensions to the stack, see the [Extension Development Guide](examples/README.md) which provides:

- **3-phase architecture**: Install → Patch → Configure
- **Template scripts**: Ready-to-use starting points
- **Patch management**: Industry-standard diff/patch system
- **Common utilities**: Shared logging and backup functions

New extensions should be added to the `init/extensions.d/` directory following the established patterns.

## Related Documentation

- **[README.md](README.md)** - Project overview and quick start guide
- **[README-PORTAINER.md](README-PORTAINER.md)** - Complete Portainer deployment instructions  
- **[examples/README.md](examples/README.md)** - Extension development guide and templates
- **[init/extensions.d/README.md](init/extensions.d/README.md)** - Technical extension architecture details