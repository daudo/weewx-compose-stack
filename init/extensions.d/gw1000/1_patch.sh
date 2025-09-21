#!/bin/bash
set -e

# GW1000 Driver Patching Script
# This script applies patches to the GW1000 driver if needed

# Source common utilities
source /init/common.sh

log_info "Applying patches for GW1000 driver..."

# Environment variable for piezo rain configuration
GW1000_USE_PIEZO_RAIN="${GW1000_USE_PIEZO_RAIN:-false}"

# Patch GW1000 driver field mapping for piezo rain sensors
patch_piezo_rain_mapping() {
    if [ "$GW1000_USE_PIEZO_RAIN" = "true" ]; then
        log_info "Patching GW1000 driver for piezo rain field mapping..."
        
        # Use field_map_extensions instead of overriding entire field_map
        # This preserves all other sensor mappings while only changing rain fields
        /init/weewx_config_api.py create-section "[GW1000][field_map_extensions]"
        
        # Map standard WeeWX rain fields to piezo rain fields using extensions
        # This fixes the upstream limitation where piezo data doesn't map to standard fields
        /init/weewx_config_api.py set-multiple-values "[GW1000][field_map_extensions]" \
            "rain=p_rain" \
            "rainRate=p_rainrate" \
            "stormRain=p_rainevent" \
            "dayRain=p_rainday" \
            "weekRain=p_rainweek" \
            "monthRain=p_rainmonth" \
            "yearRain=p_rainyear"
        
        log_success "Piezo rain field mapping patch applied"
        log_info "  - Standard 'rain' field now mapped to piezo 'p_rain'"
        log_info "  - Standard 'rainRate' field now mapped to piezo 'p_rainrate'"
    else
        log_info "Piezo rain patch disabled (GW1000_USE_PIEZO_RAIN=false)"
        
        # Remove field mapping extensions if they exist (restore driver defaults)
        # This ensures clean state when switching back to traditional rain gauges
        if /init/weewx_config_api.py has-section "[GW1000][field_map_extensions]"; then
            /init/weewx_config_api.py remove-section "[GW1000][field_map_extensions]"
            log_info "Removed piezo rain field mapping patch, using driver defaults"
        fi
    fi
}

# Apply patches
patch_piezo_rain_mapping

log_success "GW1000 driver patch phase completed"