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

echo "Installing Inigo extension (weeWXWeatherApp support)..."

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
    
    echo "Inigo extension v$INIGO_VERSION installed successfully"
else
    echo "Inigo extension v$INIGO_VERSION already installed"
fi

echo "Inigo installation phase completed"