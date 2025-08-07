#!/bin/bash
set -e

# Belchertown Skin Installation Script
# This script installs the modern, responsive Belchertown web interface for WeeWX

# Set default values
BELCHERTOWN_VERSION=${BELCHERTOWN_VERSION:-1.3.1}
ENABLE_BELCHERTOWN_SKIN=${ENABLE_BELCHERTOWN_SKIN:-true}

# Skip if extension is disabled
if [ "$ENABLE_BELCHERTOWN_SKIN" != "true" ]; then
    echo "Belchertown skin disabled (ENABLE_BELCHERTOWN_SKIN=false)"
    return 0 2>/dev/null || exit 0
fi

echo "Processing Belchertown skin..."

# Function to check if extension is installed and get version
check_extension_version() {
    local extension_name=$1
    weectl extension list --config=/data/weewx.conf 2>/dev/null | grep "^${extension_name}" | awk '{print $2}' || echo ""
}

# Check current installation status
INSTALLED_BELCHERTOWN_VERSION=$(check_extension_version "Belchertown")

# Handle version updates
if [ -n "$INSTALLED_BELCHERTOWN_VERSION" ] && [ "$INSTALLED_BELCHERTOWN_VERSION" != "$BELCHERTOWN_VERSION" ]; then
    echo "Updating Belchertown skin: $INSTALLED_BELCHERTOWN_VERSION → $BELCHERTOWN_VERSION"
    weectl extension uninstall Belchertown --config=/data/weewx.conf --yes
    INSTALLED_BELCHERTOWN_VERSION=""
fi

# Install if not present or after uninstall
if [ -z "$INSTALLED_BELCHERTOWN_VERSION" ]; then
    echo "Installing Belchertown skin v$BELCHERTOWN_VERSION..."
    BELCHERTOWN_URL="https://github.com/poblabs/weewx-belchertown/releases/download/weewx-belchertown-${BELCHERTOWN_VERSION}/weewx-belchertown-release.${BELCHERTOWN_VERSION}.tar.gz"
    
    # Install extension directly from URL
    echo "Installing from: $BELCHERTOWN_URL"
    if weectl extension install "$BELCHERTOWN_URL" --config=/data/weewx.conf --yes; then
        echo "Belchertown skin installation successful"
    else
        echo "Error: Belchertown skin installation failed"
        return 1 2>/dev/null || exit 1
    fi
    
    # Apply Python 3.13 locale.format monkey-patch
    source /init/python313-compat.sh
    apply_locale_format_monkeypatch "/data/bin/user/belchertown.py" "Belchertown"
    
    echo "Belchertown skin v$BELCHERTOWN_VERSION installed successfully"
else
    echo "Belchertown skin v$BELCHERTOWN_VERSION already installed"
    
    # Apply Python 3.13 locale.format monkey-patch even if already installed
    source /init/python313-compat.sh
    apply_locale_format_monkeypatch "/data/bin/user/belchertown.py" "Belchertown"
fi

# Configure Belchertown as default skin if WEEWX_SKIN is set to Belchertown
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

# Configure Belchertown skin options using environment variables
# This runs after installation to avoid corrupting config during extension install
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
            
            # Set all Belchertown options using generic API with forced quotes for skin compatibility
            /init/weewx_config_api.py set-multiple-values "[StdReport][Belchertown][Extras]" \
                "site_title=$WEEWX_LOCATION" \
                "manifest_name=$WEEWX_LOCATION" \
                "manifest_short_name=$MANIFEST_SHORT_NAME" \
                "home_page_header=$WEEWX_LOCATION Website" \
                "footer_copyright_text=$WEEWX_LOCATION Website" \
                "powered_by=Observations are powered by $WEEWX_LOCATION" \
                --force-string-quotes
            
            echo "Belchertown skin configuration completed:"
            echo "  - site_title: $WEEWX_LOCATION"
            echo "  - manifest_name: $WEEWX_LOCATION"
            echo "  - manifest_short_name: $MANIFEST_SHORT_NAME"
            echo "  - home_page_header: $WEEWX_LOCATION Website"
            echo "  - footer_copyright_text: $WEEWX_LOCATION Website"
            echo "  - powered_by: Observations are powered by $WEEWX_LOCATION"
        else
            echo "Warning: [[Belchertown]] section not found, skipping skin configuration"
        fi
    fi
}

# Configure Belchertown locale if language is specified and weewx.conf exists
configure_belchertown_locale() {
    if [ -n "$WEEWX_LANGUAGE" ] && [ "$WEEWX_LANGUAGE" != "en" ] && [ -f "/data/weewx.conf" ]; then
        echo "Configuring Belchertown locale for language: $WEEWX_LANGUAGE"
        
        # Use 'auto' for better compatibility - let Belchertown auto-detect
        # This avoids locale installation issues while still supporting internationalization
        local BELCHERTOWN_LOCALE="auto"
        
        echo "Using auto-detection for better locale compatibility"
        
        # Apply locale to [[[Extras]]] section using generic API with forced quotes
        if /init/weewx_config_api.py has-section "[StdReport][Belchertown][Extras]"; then
            /init/weewx_config_api.py set-value "[StdReport][Belchertown][Extras]" "belchertown_locale" "$BELCHERTOWN_LOCALE" --force-string-quotes
            echo "Belchertown locale configuration set: $BELCHERTOWN_LOCALE"
        fi
    fi
}

# Run all configuration functions after installation
echo "Applying post-installation configuration..."

# Configure skin switching (if needed)
# Note: This happens during installation above

# Configure Belchertown options from environment variables
configure_belchertown_options

# Configure locale settings
configure_belchertown_locale

# Validate final configuration using generic API
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