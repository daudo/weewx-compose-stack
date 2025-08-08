#!/bin/bash
set -e

echo "=== WeeWX Configuration Setup ==="

# Create initial backup before any changes
source /init/backup-config.sh
manage_backups init

# Check if weewx.conf already exists
if [ ! -f /data/weewx.conf ]; then
    echo "Creating initial WeeWX configuration..."
    echo "Installing required Python packages..."
    pip install six

    echo "Creating initial WeeWX configuration using original entrypoint..."
    /home/weewx/entrypoint.sh
fi

echo "Configuring WeeWX station settings from environment variables..."

# Update station configuration using generic ConfigObj API
if [ -n "$WEEWX_LOCATION" ]; then
    echo "Setting location: $WEEWX_LOCATION"
    /init/weewx_config_api.py set-value "[Station]" "location" "$WEEWX_LOCATION"
fi

if [ -n "$WEEWX_LATITUDE" ]; then
    echo "Setting latitude: $WEEWX_LATITUDE"
    /init/weewx_config_api.py set-value "[Station]" "latitude" "$WEEWX_LATITUDE"
fi

if [ -n "$WEEWX_LONGITUDE" ]; then
    echo "Setting longitude: $WEEWX_LONGITUDE"
    /init/weewx_config_api.py set-value "[Station]" "longitude" "$WEEWX_LONGITUDE"
fi

if [ -n "$WEEWX_ALTITUDE" ]; then
    echo "Setting altitude: $WEEWX_ALTITUDE"
    /init/weewx_config_api.py set-value "[Station]" "altitude" "$WEEWX_ALTITUDE"
fi

if [ -n "$WEEWX_RAIN_YEAR_START" ]; then
    echo "Setting rain year start: $WEEWX_RAIN_YEAR_START"
    /init/weewx_config_api.py set-value "[Station]" "rain_year_start" "$WEEWX_RAIN_YEAR_START"
fi

if [ -n "$WEEWX_WEEK_START" ]; then
    echo "Setting week start: $WEEWX_WEEK_START"
    /init/weewx_config_api.py set-value "[Station]" "week_start" "$WEEWX_WEEK_START"
fi

# Set unit system for reports (web interface) - nested section
if [ -n "$WEEWX_UNIT_SYSTEM" ]; then
    echo "Setting unit system: $WEEWX_UNIT_SYSTEM"
    /init/weewx_config_api.py set-value "[StdReport][Defaults]" "unit_system" "$WEEWX_UNIT_SYSTEM"
fi

# Set language for all reports - defaults to English if not specified
if [ -n "$WEEWX_LANGUAGE" ] && [ "$WEEWX_LANGUAGE" != "en" ]; then
    echo "Setting language: $WEEWX_LANGUAGE"
    /init/weewx_config_api.py set-value "[StdReport][Defaults]" "lang" "$WEEWX_LANGUAGE"
fi

# Handle station_url (ConfigObj handles both commented and uncommented cases)
if [ -n "$WEEWX_STATION_URL" ]; then
    echo "Setting station URL: $WEEWX_STATION_URL"
    /init/weewx_config_api.py set-value "[Station]" "station_url" "$WEEWX_STATION_URL"
fi

# Note: Skin configuration is handled by individual extension scripts

echo "Station configuration updated successfully"