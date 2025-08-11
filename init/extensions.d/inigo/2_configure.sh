#!/bin/bash
set -e

# Inigo Extension Configuration Script
# This script configures the Inigo extension using environment variables

# Source common utilities
source /init/common.sh

log_info "Configuring Inigo extension..."

# Create Inigo settings file configured from environment variables
configure_inigo_settings() {
    log_info "Setting up Inigo settings file for Android app access..."
    if mkdir -p /data/public_html; then
        # Use environment variables with defaults
        STATION_NAME="${WEEWX_LOCATION:-My Weather Station}"
        STATION_LATITUDE="${WEEWX_LATITUDE:-0.0}"
        STATION_LONGITUDE="${WEEWX_LONGITUDE:-0.0}"
        
        log_info "Creating inigo-settings.txt with station configuration..."
        cat > "/data/public_html/inigo-settings.txt" << EOF
# Inigo Settings File - Configured automatically from environment variables
# Station identification
station_name=${STATION_NAME}
latitude=${STATION_LATITUDE}
longitude=${STATION_LONGITUDE}

# Data source (points to WeeWX-generated inigo-data.txt)
data=inigo-data.txt

# Additional settings can be added here as needed
# See: https://github.com/evilbunny2008/weeWXWeatherApp/wiki/InigoSettings.txt
EOF
        log_success "Settings file created at /data/public_html/inigo-settings.txt"
        log_info "Station: ${STATION_NAME} (${STATION_LATITUDE}, ${STATION_LONGITUDE})"
    else
        log_warning "Could not create /data/public_html directory"
    fi
}

# Apply configuration
configure_inigo_settings

log_success "Inigo configuration phase completed"