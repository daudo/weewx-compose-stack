#!/bin/bash
set -e

# Belchertown Skin Installation Script
# This script installs the modern, responsive Belchertown web interface for WeeWX

# Set default values
BELCHERTOWN_VERSION=${BELCHERTOWN_VERSION:-1.4}
ENABLE_BELCHERTOWN_SKIN=${ENABLE_BELCHERTOWN_SKIN:-true}

# Source common utilities
source /init/common.sh

# Skip if extension is disabled
if [ "$ENABLE_BELCHERTOWN_SKIN" != "true" ]; then
    log_info "Belchertown skin disabled (ENABLE_BELCHERTOWN_SKIN=false)"
    return 0 2>/dev/null || exit 0
fi

log_info "Installing Belchertown skin v$BELCHERTOWN_VERSION..."

# Function to check if extension is installed and get version
check_extension_version() {
    local extension_name=$1
    weectl extension list --config=/data/weewx.conf 2>/dev/null | grep "^${extension_name}" | awk '{print $2}' || echo ""
}

# Check current installation status
INSTALLED_BELCHERTOWN_VERSION=$(check_extension_version "Belchertown")

# Handle version updates
if [ -n "$INSTALLED_BELCHERTOWN_VERSION" ] && [ "$INSTALLED_BELCHERTOWN_VERSION" != "$BELCHERTOWN_VERSION" ]; then
    log_info "Updating Belchertown skin: $INSTALLED_BELCHERTOWN_VERSION → $BELCHERTOWN_VERSION"
    weectl extension uninstall Belchertown --config=/data/weewx.conf --yes
    INSTALLED_BELCHERTOWN_VERSION=""
fi

# Install if not present or after uninstall
if [ -z "$INSTALLED_BELCHERTOWN_VERSION" ]; then
    log_info "Installing Belchertown skin v$BELCHERTOWN_VERSION..."
    BELCHERTOWN_URL="https://github.com/poblabs/weewx-belchertown/releases/download/weewx-belchertown-${BELCHERTOWN_VERSION}/weewx-belchertown-release.${BELCHERTOWN_VERSION}.tar.gz"
    BELCHERTOWN_FILE="/tmp/belchertown-current.tar.gz"

    # Download the tar.gz file first
    log_info "Downloading from: $BELCHERTOWN_URL"
    if wget -q -O "$BELCHERTOWN_FILE" "$BELCHERTOWN_URL"; then
        log_success "Belchertown skin downloaded successfully"
    else
        log_error "Failed to download Belchertown skin"
        return 1 2>/dev/null || exit 1
    fi

    # Install extension from downloaded local file
    log_info "Installing from downloaded file: $BELCHERTOWN_FILE"
    if weectl extension install "$BELCHERTOWN_FILE" --config=/data/weewx.conf --yes; then
        log_success "Belchertown skin installation successful"
    else
        log_error "Belchertown skin installation failed"
        return 1 2>/dev/null || exit 1
    fi
    
    log_success "Belchertown skin v$BELCHERTOWN_VERSION installed successfully"
else
    log_info "Belchertown skin v$BELCHERTOWN_VERSION already installed"
fi

log_success "Belchertown installation phase completed"