#!/bin/bash
set -e

# Extension Configuration Script Template
# This script configures the extension using environment variables and weewx_config_api

EXTENSION_NAME="${EXTENSION_NAME:-ExtensionName}"

echo "Configuring $EXTENSION_NAME..."

# Only configure if weewx.conf exists and extension section is present
if [ ! -f "/data/weewx.conf" ]; then
    echo "Warning: /data/weewx.conf not found, skipping configuration"
    return 0 2>/dev/null || exit 0
fi

# Check if extension section exists (created by extension installation)
if ! /init/weewx_config_api.py has-section "[StdReport][${EXTENSION_NAME}Report]"; then
    echo "Warning: [StdReport][${EXTENSION_NAME}Report] section not found, skipping configuration"
    return 0 2>/dev/null || exit 0
fi

echo "Found existing [${EXTENSION_NAME}Report] section, applying configuration..."

# Example: Configure extension-specific settings
configure_extension_basics() {
    echo "Configuring basic $EXTENSION_NAME settings..."
    
    # TODO: Replace with actual configuration using weewx_config_api
    # Examples:
    # /init/weewx_config_api.py set-value "[StdReport][${EXTENSION_NAME}Report][Extras]" "setting1" "$ENVIRONMENT_VAR1"
    # /init/weewx_config_api.py set-value "[StdReport][${EXTENSION_NAME}Report][Extras]" "setting2" "$ENVIRONMENT_VAR2"
    
    echo "Basic configuration completed"
}

# Example: Configure labels/translations
configure_extension_labels() {
    echo "Configuring $EXTENSION_NAME labels and translations..."
    
    # TODO: Replace with actual label configuration
    # Examples:
    # /init/weewx_config_api.py set-multiple-values "[StdReport][${EXTENSION_NAME}Report][Labels][Generic]" \
    #     "label1=Custom Label 1" \
    #     "label2=Custom Label 2"
    
    echo "Labels configuration completed"
}

# Apply configurations
configure_extension_basics
configure_extension_labels

# Validate configuration
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

echo "$EXTENSION_NAME configuration completed"