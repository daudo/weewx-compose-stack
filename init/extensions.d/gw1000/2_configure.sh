#!/bin/bash
set -e

# GW1000 Driver Configuration Script
# This script configures the GW1000 driver using environment variables

# Source common utilities
source /init/common.sh

log_info "Configuring GW1000 driver..."

# Environment variables with defaults
GW1000_IP="${GW1000_IP:-192.168.1.10}"

# Configure GW1000 section
configure_gw1000_driver() {
    log_info "Setting up GW1000 driver configuration..."
    
    # Check if GW1000 driver configuration already exists
    if /init/weewx_config_api.py has-section "[GW1000]" && /init/weewx_config_api.py has-key "[GW1000]" "ip_address"; then
        log_info "GW1000 driver configuration already exists in weewx.conf"
        
        # Update IP address if it has changed
        current_ip=$(/init/weewx_config_api.py get-value "[GW1000]" "ip_address")
        if [ "$current_ip" != "$GW1000_IP" ]; then
            log_info "Updating GW1000 IP address from $current_ip to $GW1000_IP"
            /init/weewx_config_api.py set-value "[GW1000]" "ip_address" "$GW1000_IP"
        fi
    else
        log_info "Adding GW1000 driver configuration to weewx.conf..."
        
        # Create GW1000 section if it doesn't exist (may exist from patch phase)
        if ! /init/weewx_config_api.py has-section "[GW1000]"; then
            /init/weewx_config_api.py create-section "[GW1000]"
        fi
        
        # Set driver configuration values
        /init/weewx_config_api.py set-multiple-values "[GW1000]" \
            "poll_interval=20" \
            "ip_address=$GW1000_IP" \
            "driver=user.gw1000"

        log_success "GW1000 driver configuration added successfully"
    fi
}

# Configure station to use GW1000 driver
configure_station_driver() {
    log_info "Configuring station to use GW1000 driver..."
    
    # Update station configuration to use GW1000 driver
    current_station_type=$(/init/weewx_config_api.py get-value "[Station]" "station_type")
    if [ "$current_station_type" = "Simulator" ] || [ -z "$current_station_type" ]; then
        log_info "Updating station configuration from '$current_station_type' to 'GW1000'..."
        /init/weewx_config_api.py set-value "[Station]" "station_type" "GW1000"
        log_success "Station configuration updated"
    else
        log_info "Station type already set to '$current_station_type', keeping existing configuration"
    fi
}


# Configure accumulator settings for GW1000 sensors
configure_gw1000_accumulators() {
    log_info "Configuring GW1000 sensor accumulators..."
    
    # Create base accumulator config for traditional sensors
    if ! /init/weewx_config_api.py has-key "[Accumulator]" "daymaxwind"; then
        log_info "Adding GW1000 base accumulator configuration..."
        
        # Create temporary file with base accumulator config
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
        
        # Merge base accumulator config using generic API
        /init/weewx_config_api.py merge-config-from-file "/tmp/gw1000_accum.conf" "[Accumulator]"
        rm -f /tmp/gw1000_accum.conf
        log_success "GW1000 base accumulator configuration added"
    else
        log_info "GW1000 base accumulator configuration already exists"
    fi
    
    # Always add piezo rain accumulators for GW1000 stations
    # These are needed for piezo rain field processing regardless of field mapping
    if ! /init/weewx_config_api.py has-key "[Accumulator]" "p_rain"; then
        log_info "Adding piezo rain accumulator configuration..."
        
        # Create temporary file with piezo rain accumulator config
        cat > /tmp/piezo_accum.conf << 'EOF'
[Accumulator]
[[p_rain]]
    extractor = sum
[[p_stormRain]]
    extractor = last
[[p_dayRain]]
    extractor = last
[[p_weekRain]]
    extractor = last
[[p_monthRain]]
    extractor = last
[[p_yearRain]]
    extractor = last
EOF
        
        # Merge piezo accumulator config
        /init/weewx_config_api.py merge-config-from-file "/tmp/piezo_accum.conf" "[Accumulator]"
        rm -f /tmp/piezo_accum.conf
        log_success "Piezo rain accumulator configuration added"
    else
        log_info "Piezo rain accumulator configuration already exists"
    fi
}

# Apply all configuration
configure_gw1000_driver
configure_station_driver
configure_gw1000_accumulators

log_success "GW1000 driver configuration phase completed"
log_info "GW1000 IP address: $GW1000_IP"
log_info "Driver location: /data/bin/user/gw1000.py"