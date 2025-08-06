#!/bin/bash
set -e

# Indigo Extension Installation Script (for weeWXWeatherApp support)
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
    
    # Download and install extension
    wget -q -O "/tmp/inigo-${UNIT_SYSTEM}.tar.gz" "$INIGO_URL"
    weectl extension install "/tmp/inigo-${UNIT_SYSTEM}.tar.gz" --config=/data/weewx.conf --yes
    rm "/tmp/inigo-${UNIT_SYSTEM}.tar.gz"
    
    # Download and install settings file
    echo "Installing Inigo settings file..."
    SETTINGS_URL="https://github.com/evilbunny2008/weeWXWeatherApp/releases/download/${INIGO_VERSION}/inigo-settings.txt"
    wget -q -O "/tmp/inigo-settings.txt" "$SETTINGS_URL"
    
    # Copy settings to web-accessible location
    mkdir -p /data/public_html
    cp "/tmp/inigo-settings.txt" "/data/public_html/inigo-settings.txt"
    rm "/tmp/inigo-settings.txt"
    
    # Install pyephem for enhanced almanac data (optional but recommended)
    echo "Installing pyephem for enhanced almanac support..."
    pip3 install pyephem --target /data/lib/python/site-packages --quiet || echo "Warning: pyephem installation failed, continuing..."
    
    echo "Inigo extension v$INIGO_VERSION installed successfully"
else
    echo "Inigo extension v$INIGO_VERSION already installed"
fi