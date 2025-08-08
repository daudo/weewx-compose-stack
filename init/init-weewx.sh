#!/bin/bash
set -e

echo "=========================================="
echo "WeeWX Unified Initialization"
echo "=========================================="

# Run modular initialization scripts in order
echo ""
echo "Step 1/3: Configuring WeeWX..."
/init/configure-weewx.sh

echo ""
echo "Step 2/3: Installing extensions..."
/init/install-extensions.sh

echo ""  
echo "Step 3/3: Setting up nginx..."
/init/setup-nginx.sh

echo ""
echo "=========================================="
echo "Initialization complete!"
echo "=========================================="
echo "Station location: ${WEEWX_LOCATION:-My Cozy Weather Station}"
echo "Language: ${WEEWX_LANGUAGE:-en}"
echo "WeeWX configuration: /data/weewx.conf"
echo "Extensions: GW1000 (${ENABLE_GW1000_DRIVER:-true}), Inigo v${INIGO_VERSION:-1.0.17} (${ENABLE_INIGO_EXTENSION:-true}), Belchertown v${BELCHERTOWN_VERSION:-1.3.1} (${ENABLE_BELCHERTOWN_SKIN:-true})"
echo "Nginx configuration: /data/nginx/nginx.conf"
echo "=========================================="