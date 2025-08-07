#!/bin/bash
set -e

echo "=== GW1000 Driver Installation ==="

# Configuration
WEEWX_CONF="/data/weewx.conf"
DRIVER_SOURCE="/tmp/gw1000.py"
DRIVER_DEST="/data/bin/user/gw1000.py"
GW1000_IP="${GW1000_IP:-192.168.1.10}"

# Check if weewx.conf exists
if [ ! -f "$WEEWX_CONF" ]; then
    echo "ERROR: weewx.conf not found. Please run WeeWX configuration setup first."
    exit 1
fi

# Ensure required directories exist
mkdir -p /data/bin/user

# Copy GW1000 driver if it doesn't exist
if [ ! -f "$DRIVER_DEST" ]; then
    echo "Installing GW1000 driver..."
    cp "$DRIVER_SOURCE" "$DRIVER_DEST"
    chmod +x "$DRIVER_DEST"
    echo "GW1000 driver installed successfully"
else
    echo "GW1000 driver already exists, skipping installation"
fi

# Check if GW1000 configuration already exists
if /init/weewx_config_api.py has-section "[GW1000]"; then
    echo "GW1000 configuration already exists in weewx.conf"
    
    # Update IP address if it has changed
    current_ip=$(/init/weewx_config_api.py get-value "[GW1000]" "ip_address")
    if [ "$current_ip" != "$GW1000_IP" ]; then
        echo "Updating GW1000 IP address from $current_ip to $GW1000_IP"
        /init/weewx_config_api.py set-value "[GW1000]" "ip_address" "$GW1000_IP"
    fi
else
    echo "Adding GW1000 configuration to weewx.conf..."
    
    # Create GW1000 section and set all values using generic API
    /init/weewx_config_api.py create-section "[GW1000]"
    /init/weewx_config_api.py set-multiple-values "[GW1000]" \
        "poll_interval=20" \
        "ip_address=$GW1000_IP" \
        "driver=user.gw1000"

    echo "GW1000 configuration added successfully"
fi

# Update station configuration to use GW1000 driver
current_station_type=$(/init/weewx_config_api.py get-value "[Station]" "station_type")
if [ "$current_station_type" = "Simulator" ] || [ -z "$current_station_type" ]; then
    echo "Updating station configuration to use GW1000 driver..."
    /init/weewx_config_api.py set-value "[Station]" "station_type" "GW1000"
    echo "Station configuration updated"
fi

# Add/update accumulator configuration for GW1000 sensors
if ! /init/weewx_config_api.py has-key "[Accumulator]" "daymaxwind"; then
    echo "Adding GW1000 accumulator configuration..."
    
    # Create temporary file with accumulator config for bulk merge
    cat > /tmp/gw1000_accum.conf << 'EOF'
[Accumulator]
[[daymaxwind]]
    extractor = last
[[lightning_distance]]
    extractor = last
[[lightning_strike_count]]
    extractor = sum
[[lightningcount]]
    extractor = last
[[lightning_last_det_time]]
    extractor = last
[[stormRain]]
    extractor = last
[[hourRain]]
    extractor = last
[[dayRain]]
    extractor = last
[[weekRain]]
    extractor = last
[[monthRain]]
    extractor = last
[[yearRain]]
    extractor = last
[[totalRain]]
    extractor = last
[[ws90_batt]]
    extractor = last
[[ws90_sig]]
    extractor = last
[[wh25_batt]]
    extractor = last
[[wh25_sig]]
    extractor = last
EOF
    
    # Merge accumulator config using generic API
    /init/weewx_config_api.py merge-config-from-file "/tmp/gw1000_accum.conf" "[Accumulator]"
    rm -f /tmp/gw1000_accum.conf
    echo "GW1000 accumulator configuration added"
fi

echo "GW1000 driver installation complete!"
echo "GW1000 IP address: $GW1000_IP"
echo "Driver location: $DRIVER_DEST"