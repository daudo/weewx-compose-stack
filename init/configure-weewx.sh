#!/bin/bash
set -e

echo "=== WeeWX Configuration Setup ==="

# Check if weewx.conf already exists
if [ ! -f /data/weewx.conf ]; then
    echo "Creating initial WeeWX configuration..."
    echo "Installing required Python packages..."
    pip install six

    echo "Creating initial WeeWX configuration using original entrypoint..."
    /home/weewx/entrypoint.sh
    
    echo "Adding missing root paths for extension support..."
    # Add WEEWX_ROOT and USER_ROOT to the config for extension installation
    cat >> /data/weewx.conf << EOF

# Root paths for extension installation (added by init container)
WEEWX_ROOT = /data
USER_ROOT = bin/user
EOF
else
    echo "WeeWX configuration exists, updating from environment variables..."
    # Ensure root paths are present for extension installation
    if ! grep -q "^WEEWX_ROOT" /data/weewx.conf; then
        echo "Adding missing WEEWX_ROOT and USER_ROOT for extension support..."
        cat >> /data/weewx.conf << EOF

# Root paths for extension installation (added by init container)
WEEWX_ROOT = /data
USER_ROOT = bin/user
EOF
    fi
fi

echo "Configuring WeeWX station settings from environment variables..."

# Update station configuration in weewx.conf (section-aware replacements)
if [ -n "$WEEWX_LOCATION" ]; then
    echo "Setting location: $WEEWX_LOCATION"
    sed -i "/^\\[Station\\]/,/^\\[.*\\]/ s|^[[:space:]]*location[[:space:]]*=.*|    location = $WEEWX_LOCATION|" /data/weewx.conf
fi

if [ -n "$WEEWX_LATITUDE" ]; then
    echo "Setting latitude: $WEEWX_LATITUDE"
    sed -i "/^\\[Station\\]/,/^\\[.*\\]/ s|^[[:space:]]*latitude[[:space:]]*=.*|    latitude = $WEEWX_LATITUDE|" /data/weewx.conf
fi

if [ -n "$WEEWX_LONGITUDE" ]; then
    echo "Setting longitude: $WEEWX_LONGITUDE"
    sed -i "/^\\[Station\\]/,/^\\[.*\\]/ s|^[[:space:]]*longitude[[:space:]]*=.*|    longitude = $WEEWX_LONGITUDE|" /data/weewx.conf
fi

if [ -n "$WEEWX_ALTITUDE" ]; then
    echo "Setting altitude: $WEEWX_ALTITUDE"
    sed -i "/^\\[Station\\]/,/^\\[.*\\]/ s|^[[:space:]]*altitude[[:space:]]*=.*|    altitude = $WEEWX_ALTITUDE|" /data/weewx.conf
fi

if [ -n "$WEEWX_RAIN_YEAR_START" ]; then
    echo "Setting rain year start: $WEEWX_RAIN_YEAR_START"
    sed -i "/^\\[Station\\]/,/^\\[.*\\]/ s|^[[:space:]]*rain_year_start[[:space:]]*=.*|    rain_year_start = $WEEWX_RAIN_YEAR_START|" /data/weewx.conf
fi

if [ -n "$WEEWX_WEEK_START" ]; then
    echo "Setting week start: $WEEWX_WEEK_START"
    sed -i "/^\\[Station\\]/,/^\\[.*\\]/ s|^[[:space:]]*week_start[[:space:]]*=.*|    week_start = $WEEWX_WEEK_START|" /data/weewx.conf
fi

# Set unit system for reports (web interface)
if [ -n "$WEEWX_UNIT_SYSTEM" ]; then
    echo "Setting unit system: $WEEWX_UNIT_SYSTEM"
    sed -i "/^[[:space:]]*\\[\\[Defaults\\]\\]/,/^[[:space:]]*\\[\\[\\[.*\\]\\]\\]/ s|^[[:space:]]*unit_system[[:space:]]*=.*|        unit_system = $WEEWX_UNIT_SYSTEM|" /data/weewx.conf
fi

# Handle station_url specially (commented by default)
if [ -n "$WEEWX_STATION_URL" ]; then
    echo "Setting station URL: $WEEWX_STATION_URL"
    # Uncomment and set the URL (handles both commented and uncommented cases)
    sed -i "/^\\[Station\\]/,/^\\[.*\\]/ s|^[[:space:]]*#*[[:space:]]*station_url[[:space:]]*=.*|    station_url = $WEEWX_STATION_URL|" /data/weewx.conf
else
    # Ensure it stays commented out if no URL provided
    sed -i '/^\\[Station\\]/,/^\\[.*\\]/ s|^[[:space:]]*station_url[[:space:]]*=.*|#    station_url = https://www.example.com|' /data/weewx.conf
fi

# Configure active skin for web reports
if [ -n "$WEEWX_SKIN" ]; then
    echo "Setting active skin: $WEEWX_SKIN"
    # Update the skin setting in the [StdReport] [[StandardReport]] section
    if grep -q "\\[\\[StandardReport\\]\\]" /data/weewx.conf; then
        sed -i "/\\[\\[StandardReport\\]\\]/,/\\[\\[\\[.*\\]\\]\\]/ s|^[[:space:]]*skin[[:space:]]*=.*|        skin = $WEEWX_SKIN|" /data/weewx.conf
    else
        echo "Warning: StandardReport section not found in weewx.conf"
    fi
fi

echo "Station configuration updated successfully"