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
    
    # Check if BelchertownReport section already exists
    if ! grep -q "\\[\\[BelchertownReport\\]\\]" /data/weewx.conf; then
        # Add BelchertownReport section before SeasonsReport
        sed -i "/\\[\\[SeasonsReport\\]\\]/i\\    # Belchertown as the main weather website\\
\\    [[BelchertownReport]]\\
\\        skin = Belchertown\\
\\        enable = true\\
\\        # Generates to public_html/ (main website root)\\
\\
" /data/weewx.conf
    else
        # Ensure BelchertownReport is enabled
        sed -i "/\\[\\[BelchertownReport\\]\\]/,/\\[\\[.*\\]\\]/ s|^[[:space:]]*enable[[:space:]]*=.*|        enable = true|" /data/weewx.conf
    fi
    
    # Move Seasons to subfolder
    if grep -A 10 "\\[\\[SeasonsReport\\]\\]" /data/weewx.conf | grep -q "HTML_ROOT"; then
        sed -i "/\\[\\[SeasonsReport\\]\\]/,/\\[\\[.*\\]\\]/ s|^[[:space:]]*HTML_ROOT[[:space:]]*=.*|        HTML_ROOT = public_html/seasons|" /data/weewx.conf
    else
        # Add HTML_ROOT setting to SeasonsReport
        sed -i "/\\[\\[SeasonsReport\\]\\]/a\\        HTML_ROOT = public_html/seasons" /data/weewx.conf
    fi
    
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
if [ -f "/data/weewx.conf" ] && [ -n "$WEEWX_LOCATION" ]; then
    echo "Configuring Belchertown skin options from environment variables..."
    
    # Generate short name for manifest
    MANIFEST_SHORT_NAME=$(generate_short_name "$WEEWX_LOCATION")
    
    # Ensure BelchertownReport section exists (create if not)
    if ! grep -q "\\[\\[BelchertownReport\\]\\]" /data/weewx.conf; then
        # Add minimal BelchertownReport section 
        sed -i "/\\[StdReport\\]/a\\    [[BelchertownReport]]\\
\\        skin = Belchertown\\
\\        enable = true\\
" /data/weewx.conf
    fi
    
    # Add or update [[[Extras]]] section in BelchertownReport
    if ! grep -A 20 "\\[\\[BelchertownReport\\]\\]" /data/weewx.conf | grep -q "\\[\\[\\[Extras\\]\\]\\]"; then
        # Add [[[Extras]]] section
        sed -i "/\\[\\[BelchertownReport\\]\\]/,/\\[\\[.*\\]\\]/ { 
            /\\[\\[BelchertownReport\\]\\]/a\\        [[[Extras]]]
        }" /data/weewx.conf
    fi
    
    # Configure Belchertown options
    echo "Setting site_title = $WEEWX_LOCATION"
    sed -i "/\\[\\[BelchertownReport\\]\\]/,/\\[\\[.*\\]\\]/ {
        /\\[\\[\\[Extras\\]\\]\\]/a\\            site_title = \"$WEEWX_LOCATION\"
    }" /data/weewx.conf
    
    echo "Setting manifest_name = $WEEWX_LOCATION"
    sed -i "/\\[\\[BelchertownReport\\]\\]/,/\\[\\[.*\\]\\]/ {
        /site_title/a\\            manifest_name = \"$WEEWX_LOCATION\"
    }" /data/weewx.conf
    
    echo "Setting manifest_short_name = $MANIFEST_SHORT_NAME"
    sed -i "/\\[\\[BelchertownReport\\]\\]/,/\\[\\[.*\\]\\]/ {
        /manifest_name/a\\            manifest_short_name = \"$MANIFEST_SHORT_NAME\"
    }" /data/weewx.conf
    
    echo "Setting home_page_header = $WEEWX_LOCATION Website"
    sed -i "/\\[\\[BelchertownReport\\]\\]/,/\\[\\[.*\\]\\]/ {
        /manifest_short_name/a\\            home_page_header = \"$WEEWX_LOCATION Website\"
    }" /data/weewx.conf
    
    echo "Setting footer_copyright_text = $WEEWX_LOCATION Website"
    sed -i "/\\[\\[BelchertownReport\\]\\]/,/\\[\\[.*\\]\\]/ {
        /home_page_header/a\\            footer_copyright_text = \"$WEEWX_LOCATION Website\"
    }" /data/weewx.conf
    
    echo "Setting powered_by = Observations are powered by $WEEWX_LOCATION"
    sed -i "/\\[\\[BelchertownReport\\]\\]/,/\\[\\[.*\\]\\]/ {
        /footer_copyright_text/a\\            powered_by = \"Observations are powered by $WEEWX_LOCATION\"
    }" /data/weewx.conf
    
    echo "Belchertown configuration completed:"
    echo "  - site_title: $WEEWX_LOCATION"
    echo "  - manifest_name: $WEEWX_LOCATION" 
    echo "  - manifest_short_name: $MANIFEST_SHORT_NAME"
    echo "  - home_page_header: $WEEWX_LOCATION Website"
    echo "  - footer_copyright_text: $WEEWX_LOCATION Website"
    echo "  - powered_by: Observations are powered by $WEEWX_LOCATION"
fi

# Configure Belchertown locale if language is specified and weewx.conf exists
if [ -n "$WEEWX_LANGUAGE" ] && [ "$WEEWX_LANGUAGE" != "en" ] && [ -f "/data/weewx.conf" ]; then
    echo "Configuring Belchertown locale for language: $WEEWX_LANGUAGE"
    
    # Use 'auto' for better compatibility - let Belchertown auto-detect
    # This avoids locale installation issues while still supporting internationalization
    BELCHERTOWN_LOCALE="auto"
    
    echo "Using auto-detection for better locale compatibility"
    
    # Apply Belchertown locale configuration to BelchertownReport section
    if grep -q "\\[\\[BelchertownReport\\]\\]" /data/weewx.conf; then
        if ! grep -A 20 "\\[\\[BelchertownReport\\]\\]" /data/weewx.conf | grep -q "belchertown_locale"; then
            sed -i "/\\[\\[BelchertownReport\\]\\]/,/\\[\\[.*\\]\\]/ {
                /powered_by/a\\            belchertown_locale = $BELCHERTOWN_LOCALE
            }" /data/weewx.conf
        else
            sed -i "/\\[\\[BelchertownReport\\]\\]/,/\\[\\[.*\\]\\]/ s|belchertown_locale.*=.*|            belchertown_locale = $BELCHERTOWN_LOCALE|g" /data/weewx.conf
        fi
        echo "Belchertown locale configuration applied: $BELCHERTOWN_LOCALE"
    fi
fi