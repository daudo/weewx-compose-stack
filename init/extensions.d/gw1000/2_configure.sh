#!/bin/bash
set -e

# GW1000 Driver Configuration Script
# This script configures the GW1000 driver using environment variables

echo "Configuring GW1000 driver..."

# Environment variables with defaults
GW1000_IP="${GW1000_IP:-192.168.1.10}"

# Configure GW1000 section
configure_gw1000_driver() {
    echo "Setting up GW1000 driver configuration..."
    
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
}

# Configure station to use GW1000 driver
configure_station_driver() {
    echo "Configuring station to use GW1000 driver..."
    
    # Update station configuration to use GW1000 driver
    current_station_type=$(/init/weewx_config_api.py get-value "[Station]" "station_type")
    if [ "$current_station_type" = "Simulator" ] || [ -z "$current_station_type" ]; then
        echo "Updating station configuration from '$current_station_type' to 'GW1000'..."
        /init/weewx_config_api.py set-value "[Station]" "station_type" "GW1000"
        echo "Station configuration updated"
    else
        echo "Station type already set to '$current_station_type', keeping existing configuration"
    fi
}

# Configure accumulator settings for GW1000 sensors
configure_gw1000_accumulators() {
    echo "Configuring GW1000 sensor accumulators..."
    
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
    else
        echo "GW1000 accumulator configuration already exists, skipping"
    fi
}

# Apply all configuration
configure_gw1000_driver
configure_station_driver  
configure_gw1000_accumulators

echo "GW1000 driver configuration phase completed"
echo "GW1000 IP address: $GW1000_IP"
echo "Driver location: /data/bin/user/gw1000.py"