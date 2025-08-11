#!/bin/bash
set -e

# Extension Installation Script Template
# This script handles downloading and installing the WeeWX extension

# Extension configuration
EXTENSION_NAME="${EXTENSION_NAME:-ExtensionName}"
EXTENSION_VERSION="${EXTENSION_VERSION:-1.0.0}"
ENABLE_EXTENSION="${ENABLE_EXTENSION:-true}"

# Source common utilities
source "$(dirname "$0")/../../common.sh"

# Skip if extension is disabled
if [ "$ENABLE_EXTENSION" != "true" ]; then
    log_info "$EXTENSION_NAME disabled (ENABLE_EXTENSION=false)"
    return 0 2>/dev/null || exit 0
fi

log_info "Installing $EXTENSION_NAME extension v$EXTENSION_VERSION..."

# Function to check if extension is installed and get version
check_extension_version() {
    local extension_name=$1
    weectl extension list --config=/data/weewx.conf 2>/dev/null | grep "^${extension_name}" | awk '{print $2}' || echo ""
}

# Check current installation status
INSTALLED_VERSION=$(check_extension_version "$EXTENSION_NAME")

# Handle version updates
if [ -n "$INSTALLED_VERSION" ] && [ "$INSTALLED_VERSION" != "$EXTENSION_VERSION" ]; then
    log_info "Updating $EXTENSION_NAME: $INSTALLED_VERSION → $EXTENSION_VERSION"
    weectl extension uninstall "$EXTENSION_NAME" --config=/data/weewx.conf --yes
    INSTALLED_VERSION=""
fi

# Install if not present or after uninstall
if [ -z "$INSTALLED_VERSION" ]; then
    log_info "Installing $EXTENSION_NAME v$EXTENSION_VERSION..."
    
    # TODO: Replace with actual extension URL/source
    EXTENSION_URL="https://github.com/example/extension/releases/download/v${EXTENSION_VERSION}/extension.tar.gz"
    
    # Install extension
    log_info "Installing from: $EXTENSION_URL"
    if weectl extension install "$EXTENSION_URL" --config=/data/weewx.conf --yes; then
        log_success "$EXTENSION_NAME v$EXTENSION_VERSION installation successful"
    else
        log_error "$EXTENSION_NAME installation failed"
        return 1 2>/dev/null || exit 1
    fi
else
    log_info "$EXTENSION_NAME v$EXTENSION_VERSION already installed"
fi

log_success "$EXTENSION_NAME installation phase completed"