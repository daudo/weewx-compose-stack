#!/bin/bash
set -e

# Extension Installation Script Template
# This script handles downloading and installing the WeeWX extension

# Extension configuration
EXTENSION_NAME="${EXTENSION_NAME:-ExtensionName}"
EXTENSION_VERSION="${EXTENSION_VERSION:-1.0.0}"
ENABLE_EXTENSION="${ENABLE_EXTENSION:-true}"

# Skip if extension is disabled
if [ "$ENABLE_EXTENSION" != "true" ]; then
    echo "$EXTENSION_NAME disabled (ENABLE_EXTENSION=false)"
    return 0 2>/dev/null || exit 0
fi

echo "Installing $EXTENSION_NAME extension v$EXTENSION_VERSION..."

# Function to check if extension is installed and get version
check_extension_version() {
    local extension_name=$1
    weectl extension list --config=/data/weewx.conf 2>/dev/null | grep "^${extension_name}" | awk '{print $2}' || echo ""
}

# Check current installation status
INSTALLED_VERSION=$(check_extension_version "$EXTENSION_NAME")

# Handle version updates
if [ -n "$INSTALLED_VERSION" ] && [ "$INSTALLED_VERSION" != "$EXTENSION_VERSION" ]; then
    echo "Updating $EXTENSION_NAME: $INSTALLED_VERSION → $EXTENSION_VERSION"
    weectl extension uninstall "$EXTENSION_NAME" --config=/data/weewx.conf --yes
    INSTALLED_VERSION=""
fi

# Install if not present or after uninstall
if [ -z "$INSTALLED_VERSION" ]; then
    echo "Installing $EXTENSION_NAME v$EXTENSION_VERSION..."
    
    # TODO: Replace with actual extension URL/source
    EXTENSION_URL="https://github.com/example/extension/releases/download/v${EXTENSION_VERSION}/extension.tar.gz"
    
    # Install extension
    echo "Installing from: $EXTENSION_URL"
    if weectl extension install "$EXTENSION_URL" --config=/data/weewx.conf --yes; then
        echo "$EXTENSION_NAME v$EXTENSION_VERSION installation successful"
    else
        echo "Error: $EXTENSION_NAME installation failed"
        return 1 2>/dev/null || exit 1
    fi
else
    echo "$EXTENSION_NAME v$EXTENSION_VERSION already installed"
fi

echo "$EXTENSION_NAME installation phase completed"