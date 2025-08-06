#!/bin/bash
set -e

echo "=========================================="
echo "WeeWX Unified Initialization"
echo "=========================================="

# Run modular initialization scripts in order
echo ""
echo "Step 1/4: Configuring WeeWX..."
/init/configure-weewx.sh

echo ""
echo "Step 2/4: Installing GW1000 driver..."
/init/install-gw1000.sh

echo ""
echo "Step 3/4: Installing extensions..."
/init/install-extensions.sh

echo ""  
echo "Step 4/4: Setting up nginx..."
/init/setup-nginx.sh

echo ""
echo "=========================================="
echo "Initialization complete!"
echo "=========================================="
echo "GW1000 IP address: ${GW1000_IP:-192.168.1.10}"
echo "Station location: ${WEEWX_LOCATION:-My Cozy Weather Station}"
echo "Language: ${WEEWX_LANGUAGE:-en}"
echo "WeeWX configuration: /data/weewx.conf"
echo "GW1000 driver: /data/bin/user/gw1000.py"
echo "Extensions: Inigo v${INIGO_VERSION:-1.0.17} (${ENABLE_INIGO_EXTENSION:-true}), Belchertown v${BELCHERTOWN_VERSION:-1.3.1} (${ENABLE_BELCHERTOWN_SKIN:-true})"
echo "Nginx configuration: /data/nginx/nginx.conf"
echo "=========================================="