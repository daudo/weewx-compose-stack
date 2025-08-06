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
echo "Step 2/3: Installing GW1000 driver..."
/init/install-gw1000.sh

echo ""  
echo "Step 3/3: Setting up nginx..."
/init/setup-nginx.sh

echo ""
echo "=========================================="
echo "Initialization complete!"
echo "=========================================="
echo "GW1000 IP address: ${GW1000_IP:-192.168.1.10}"
echo "Station location: ${WEEWX_LOCATION:-My Cozy Weather Station}"
echo "WeeWX configuration: /data/weewx.conf"
echo "GW1000 driver: /data/bin/user/gw1000.py"
echo "Nginx configuration: /data/nginx/nginx.conf"
echo "=========================================="