#!/bin/bash
set -e

# Belchertown Skin Configuration Script
# This script configures the Belchertown skin using environment variables and weewx_config_api

echo "Configuring Belchertown skin..."

# Function to generate short name from location (first letters of each word)
generate_short_name() {
    local location="$1"
    echo "$location" | awk '{
        short_name = ""
        for(i=1; i<=NF; i++) {
            short_name = short_name substr($i, 1, 1)
        }
        print toupper(short_name)
    }'
}

# Configure Belchertown as default skin if WEEWX_SKIN is set to Belchertown
configure_default_skin() {
    if [ -n "$WEEWX_SKIN" ] && [ "$WEEWX_SKIN" = "Belchertown" ]; then
        echo "Configuring Belchertown as default skin with Seasons in subfolder..."
        
        # Set HTML_ROOT for Belchertown skin to public_html (main website root)
        /init/weewx_config_api.py set-value "[StdReport][Belchertown]" "HTML_ROOT" "public_html"
        echo "Set [[Belchertown]] HTML_ROOT = public_html"
        
        # Move Seasons to subfolder
        /init/weewx_config_api.py set-value "[StdReport][SeasonsReport]" "HTML_ROOT" "public_html/seasons"
        echo "Moved Seasons to public_html/seasons/"
        
        echo "Belchertown configured as main skin, Seasons available at /seasons/"
    fi
}

# Configure Belchertown skin options using environment variables
configure_belchertown_options() {
    if [ -f "/data/weewx.conf" ] && [ -n "$WEEWX_LOCATION" ]; then
        echo "Configuring Belchertown skin options from environment variables..."
        
        # Generate short name for manifest
        local MANIFEST_SHORT_NAME=$(generate_short_name "$WEEWX_LOCATION")
        
        # Check if Belchertown section exists (created by extension installation)
        if /init/weewx_config_api.py has-section "[StdReport][Belchertown]"; then
            echo "Found existing [[Belchertown]] section, configuring options..."
            
            # Remove existing [[[Extras]]] section and recreate it cleanly
            /init/weewx_config_api.py remove-section "[StdReport][Belchertown][Extras]"
            /init/weewx_config_api.py create-section "[StdReport][Belchertown][Extras]"
            
            # Set Belchertown Extras options (for manifest and site title)
            /init/weewx_config_api.py set-multiple-values "[StdReport][Belchertown][Extras]" \
                "site_title=$WEEWX_LOCATION" \
                "manifest_name=$WEEWX_LOCATION" \
                "manifest_short_name=$MANIFEST_SHORT_NAME"
            
            # Set Belchertown Labels (for page headers and footer text)
            /init/weewx_config_api.py set-multiple-values "[StdReport][Belchertown][Labels][Generic]" \
                "home_page_header=$WEEWX_LOCATION Website" \
                "footer_copyright_text=$WEEWX_LOCATION Website" \
                "powered_by=Observations are powered by $WEEWX_VERBOSE_HARDWARE"
            
            echo "Belchertown skin configuration completed:"
            echo "  - site_title: $WEEWX_LOCATION"
            echo "  - manifest_name: $WEEWX_LOCATION"
            echo "  - manifest_short_name: $MANIFEST_SHORT_NAME"
            echo "  - home_page_header: $WEEWX_LOCATION Website"
            echo "  - footer_copyright_text: $WEEWX_LOCATION Website"
            echo "  - powered_by: Observations are powered by $WEEWX_VERBOSE_HARDWARE"
        else
            echo "Warning: [[Belchertown]] section not found, skipping skin configuration"
        fi
    fi
}

# Map language code to proper locale string for Belchertown
get_belchertown_locale() {
    case "${WEEWX_LANGUAGE:-en}" in
        de) echo "de_DE.UTF-8" ;;
        ca) echo "ca_ES.UTF-8" ;;
        it) echo "it_IT.UTF-8" ;;
        en|*) echo "en_US.UTF-8" ;;  # default to English
    esac
}

# Configure Belchertown locale - always set to avoid 'auto' issues in container
configure_belchertown_locale() {
    if [ -f "/data/weewx.conf" ]; then
        local BELCHERTOWN_LOCALE=$(get_belchertown_locale)
        echo "Configuring Belchertown locale: ${WEEWX_LANGUAGE:-en} -> $BELCHERTOWN_LOCALE"
        
        # Apply locale to [[[Extras]]] section using generic API
        if /init/weewx_config_api.py has-section "[StdReport][Belchertown][Extras]"; then
            /init/weewx_config_api.py set-value "[StdReport][Belchertown][Extras]" "belchertown_locale" "$BELCHERTOWN_LOCALE"
            echo "Belchertown locale configuration set: $BELCHERTOWN_LOCALE"
        fi
    fi
}

# Apply all configurations
configure_default_skin
configure_belchertown_options
configure_belchertown_locale

# Validate final configuration
echo "Validating final configuration..."
if /init/weewx_config_api.py validate; then
    echo "Configuration validation successful"
else
    echo "Warning: Configuration validation failed - there may be syntax errors"
    # Try to restore from backup if validation fails
    source /init/backup-config.sh
    if manage_backups restore; then
        echo "Configuration restored from backup after validation failure"
    fi
fi

echo "Belchertown configuration phase completed"