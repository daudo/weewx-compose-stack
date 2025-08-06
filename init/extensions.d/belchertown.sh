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
    
    echo "Belchertown skin v$BELCHERTOWN_VERSION installed successfully"
else
    echo "Belchertown skin v$BELCHERTOWN_VERSION already installed"
fi

# Configure Belchertown locale if language is specified and weewx.conf exists
if [ -n "$WEEWX_LANGUAGE" ] && [ "$WEEWX_LANGUAGE" != "en" ] && [ -f "/data/weewx.conf" ]; then
    echo "Configuring Belchertown locale for language: $WEEWX_LANGUAGE"
    
    # Set belchertown_locale based on language (simple mapping for common cases)
    case "$WEEWX_LANGUAGE" in
        "de") BELCHERTOWN_LOCALE="de_DE.UTF-8" ;;
        "fr") BELCHERTOWN_LOCALE="fr_FR.UTF-8" ;;
        "es") BELCHERTOWN_LOCALE="es_ES.UTF-8" ;;
        "it") BELCHERTOWN_LOCALE="it_IT.UTF-8" ;;
        *) BELCHERTOWN_LOCALE="auto" ;;
    esac
    
    # Apply Belchertown locale configuration
    if grep -q "\[\[Belchertown\]\]" /data/weewx.conf; then
        if ! grep -A 10 "\[\[Belchertown\]\]" /data/weewx.conf | grep -q "belchertown_locale"; then
            sed -i "/\[\[Belchertown\]\]/,/\[\[/ { /\[\[\[Extras\]\]\]/a\\                belchertown_locale = $BELCHERTOWN_LOCALE
            }" /data/weewx.conf
        else
            sed -i "s|belchertown_locale.*=.*|belchertown_locale = $BELCHERTOWN_LOCALE|g" /data/weewx.conf
        fi
        echo "Belchertown locale configuration applied: $BELCHERTOWN_LOCALE"
    fi
fi