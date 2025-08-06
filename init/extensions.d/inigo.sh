#!/bin/bash
set -e

# Inigo Extension Installation Script (for weeWXWeatherApp support)
# This script installs the Inigo extension that provides data API for the weeWXWeatherApp Android application

# Set default values
INIGO_VERSION=${INIGO_VERSION:-1.0.17}
ENABLE_INIGO_EXTENSION=${ENABLE_INIGO_EXTENSION:-true}

# Skip if extension is disabled
if [ "$ENABLE_INIGO_EXTENSION" != "true" ]; then
    echo "Inigo extension disabled (ENABLE_INIGO_EXTENSION=false)"
    return 0 2>/dev/null || exit 0
fi

echo "Processing Inigo extension (weeWXWeatherApp support)..."

# Function to validate weewx.conf before proceeding
validate_config() {
    if ! weectl extension list --config=/data/weewx.conf >/dev/null 2>&1; then
        echo "Error: weewx.conf appears to be corrupted. Attempting restore..."
        source /init/backup-config.sh
        if manage_backups restore; then
            echo "Config restored successfully from backup"
            return 0
        else
            echo "Error: Unable to restore config from backup"
            return 1
        fi
    fi
    return 0
}

# Function to check if extension is installed and get version
check_extension_version() {
    local extension_name=$1
    weectl extension list --config=/data/weewx.conf 2>/dev/null | grep "^${extension_name}" | awk '{print $2}' || echo ""
}

# Determine unit system for Inigo extension
UNIT_SYSTEM="metric"
if [ "${WEEWX_UNIT_SYSTEM}" = "us" ]; then
    UNIT_SYSTEM="imperial"
fi

# Validate config before proceeding
if ! validate_config; then
    echo "Error: Cannot proceed with corrupted config file"
    return 1 2>/dev/null || exit 1
fi

# Check current installation status
INSTALLED_INIGO_VERSION=$(check_extension_version "inigo")

# Handle version updates
if [ -n "$INSTALLED_INIGO_VERSION" ] && [ "$INSTALLED_INIGO_VERSION" != "$INIGO_VERSION" ]; then
    echo "Updating Inigo extension: $INSTALLED_INIGO_VERSION → $INIGO_VERSION"
    weectl extension uninstall inigo --config=/data/weewx.conf --yes
    INSTALLED_INIGO_VERSION=""
fi

# Install if not present or after uninstall
if [ -z "$INSTALLED_INIGO_VERSION" ]; then
    echo "Installing Inigo extension v$INIGO_VERSION ($UNIT_SYSTEM units)..."
    INIGO_URL="https://github.com/evilbunny2008/weeWXWeatherApp/releases/download/${INIGO_VERSION}/inigo-${UNIT_SYSTEM}.tar.gz"
    
    # Install extension directly from URL
    echo "Installing from: $INIGO_URL"
    weectl extension install "$INIGO_URL" --config=/data/weewx.conf --yes
    
    # Create Inigo settings file configured from environment variables
    echo "Setting up Inigo settings file for Android app access..."
    if mkdir -p /data/public_html; then
        # Use environment variables with defaults
        STATION_NAME="${WEEWX_LOCATION:-My Weather Station}"
        STATION_LATITUDE="${WEEWX_LATITUDE:-0.0}"
        STATION_LONGITUDE="${WEEWX_LONGITUDE:-0.0}"
        
        echo "Creating inigo-settings.txt with station configuration..."
        cat > "/data/public_html/inigo-settings.txt" << EOF
# Inigo Settings File - Configured automatically from environment variables
# Station identification
station_name=${STATION_NAME}
latitude=${STATION_LATITUDE}
longitude=${STATION_LONGITUDE}

# Data source (points to WeeWX-generated inigo-data.txt)
data=inigo-data.txt

# Additional settings can be added here as needed
# See: https://github.com/evilbunny2008/weeWXWeatherApp/wiki/InigoSettings.txt
EOF
        echo "Settings file created at /data/public_html/inigo-settings.txt"
        echo "Station: ${STATION_NAME} (${STATION_LATITUDE}, ${STATION_LONGITUDE})"
    else
        echo "Warning: Could not create /data/public_html directory"
    fi
    
    # Install pyephem for enhanced almanac data (optional but recommended)
    echo "Installing pyephem for enhanced almanac support..."
    if pip3 install pyephem --target /data/lib/python/site-packages --quiet; then
        echo "pyephem installed successfully"
    else
        echo "Warning: pyephem installation failed, continuing..."
    fi
    
    echo "Inigo extension v$INIGO_VERSION installed successfully"
else
    echo "Inigo extension v$INIGO_VERSION already installed"
fi