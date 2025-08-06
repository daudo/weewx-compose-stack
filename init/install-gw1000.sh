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
if grep -q "^\[GW1000\]" "$WEEWX_CONF"; then
    echo "GW1000 configuration already exists in weewx.conf"
    
    # Update IP address if it has changed
    current_ip=$(grep -A 10 "^\[GW1000\]" "$WEEWX_CONF" | grep "ip_address" | cut -d'=' -f2 | tr -d ' ')
    if [ "$current_ip" != "$GW1000_IP" ]; then
        echo "Updating GW1000 IP address from $current_ip to $GW1000_IP"
        sed -i "/^\[GW1000\]/,/^\[/ s/ip_address = .*/ip_address = $GW1000_IP/" "$WEEWX_CONF"
    fi
else
    echo "Adding GW1000 configuration to weewx.conf..."
    
    # Backup original config
    cp "$WEEWX_CONF" "${WEEWX_CONF}.backup"
    
    # Add GW1000 configuration before [Engine] section
    sed -i '/^\[Engine\]/i \
##############################################################################\
\
#   This section is for the Ecowitt Gateway driver.\
\
[GW1000]\
    # How often to poll the API, default is every 20 seconds:\
    poll_interval = 20\
    \
    # The IP address of the GW1000 gateway device:\
    ip_address = '"$GW1000_IP"'\
    \
    # The driver to use:\
    driver = user.gw1000\
\
' "$WEEWX_CONF"

    echo "GW1000 configuration added successfully"
fi

# Update station configuration to use GW1000 driver
if grep -q "station_type = Simulator" "$WEEWX_CONF"; then
    echo "Updating station configuration to use GW1000 driver..."
    sed -i 's/station_type = Simulator/station_type = GW1000/' "$WEEWX_CONF"
    echo "Station configuration updated"
fi

# Add/update accumulator configuration for GW1000 sensors
if ! grep -q "# Start Ecowitt Gateway driver extractors" "$WEEWX_CONF"; then
    echo "Adding GW1000 accumulator configuration..."
    
    # Create temporary file with accumulator config
    cat >> /tmp/gw1000_accum.conf << 'EOF'

    # Start Ecowitt Gateway driver extractors
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
    # End Ecowitt Gateway driver extractors
EOF
    
    # Insert accumulator config into [Accumulator] section
    sed -i '/^\[Accumulator\]/r /tmp/gw1000_accum.conf' "$WEEWX_CONF"
    rm /tmp/gw1000_accum.conf
    echo "GW1000 accumulator configuration added"
fi

echo "GW1000 driver installation complete!"
echo "GW1000 IP address: $GW1000_IP"
echo "Driver location: $DRIVER_DEST"