#!/bin/bash
set -e

# GW1000 Driver Installation Script
# This script installs the GW1000 driver for Ecowitt weather stations

# Environment variables for configuration
ENABLE_GW1000_DRIVER=${ENABLE_GW1000_DRIVER:-true}

echo "Installing GW1000 driver..."

# Skip if disabled
if [ "$ENABLE_GW1000_DRIVER" != "true" ]; then
    echo "GW1000 driver installation disabled (ENABLE_GW1000_DRIVER=$ENABLE_GW1000_DRIVER)"
    return 0 2>/dev/null || exit 0
fi

# Configuration
DRIVER_SOURCE="/tmp/gw1000.py"
DRIVER_DEST="/data/bin/user/gw1000.py"

# Check if weewx.conf exists
if [ ! -f "/data/weewx.conf" ]; then
    echo "ERROR: weewx.conf not found. Please run WeeWX configuration setup first."
    exit 1
fi

# Ensure required directories exist
echo "Creating user directory structure..."
mkdir -p /data/bin/user

# Copy GW1000 driver if it doesn't exist
if [ ! -f "$DRIVER_DEST" ]; then
    echo "Installing GW1000 driver from $DRIVER_SOURCE..."
    cp "$DRIVER_SOURCE" "$DRIVER_DEST"
    chmod +x "$DRIVER_DEST"
    echo "GW1000 driver installed successfully at $DRIVER_DEST"
else
    echo "GW1000 driver already exists at $DRIVER_DEST, skipping installation"
fi

echo "GW1000 driver installation phase completed"