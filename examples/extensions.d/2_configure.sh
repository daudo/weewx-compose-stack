#!/bin/bash
set -e

# Extension Configuration Script Template
# This script configures the extension using environment variables and weewx_config_api

# Source common utilities
source "$(dirname "$0")/../../common.sh"

EXTENSION_NAME="${EXTENSION_NAME:-ExtensionName}"

log_info "Configuring $EXTENSION_NAME..."

# Only configure if weewx.conf exists and extension section is present
if [ ! -f "/data/weewx.conf" ]; then
    log_warning "/data/weewx.conf not found, skipping configuration"
    return 0 2>/dev/null || exit 0
fi

# Check if extension section exists (created by extension installation)
if ! /init/weewx_config_api.py has-section "[StdReport][${EXTENSION_NAME}Report]"; then
    log_warning "[StdReport][${EXTENSION_NAME}Report] section not found, skipping configuration"
    return 0 2>/dev/null || exit 0
fi

log_info "Found existing [${EXTENSION_NAME}Report] section, applying configuration..."

# Example: Configure extension-specific settings
configure_extension_basics() {
    log_info "Configuring basic $EXTENSION_NAME settings..."
    
    # TODO: Replace with actual configuration using weewx_config_api
    # Examples:
    # /init/weewx_config_api.py set-value "[StdReport][${EXTENSION_NAME}Report][Extras]" "setting1" "$ENVIRONMENT_VAR1"
    # /init/weewx_config_api.py set-value "[StdReport][${EXTENSION_NAME}Report][Extras]" "setting2" "$ENVIRONMENT_VAR2"
    
    log_success "Basic configuration completed"
}

# Example: Configure labels/translations
configure_extension_labels() {
    log_info "Configuring $EXTENSION_NAME labels and translations..."
    
    # TODO: Replace with actual label configuration
    # Examples:
    # /init/weewx_config_api.py set-multiple-values "[StdReport][${EXTENSION_NAME}Report][Labels][Generic]" \
    #     "label1=Custom Label 1" \
    #     "label2=Custom Label 2"
    
    log_success "Labels configuration completed"
}

# Apply configurations
configure_extension_basics
configure_extension_labels

# Validate configuration
log_info "Validating final configuration..."
if /init/weewx_config_api.py validate; then
    log_success "Configuration validation successful"
else
    log_warning "Configuration validation failed - there may be syntax errors"
    # Try to restore from backup if validation fails
    # manage_backups is available from common.sh
    if manage_backups restore; then
        log_success "Configuration restored from backup after validation failure"
    fi
fi

log_success "$EXTENSION_NAME configuration completed"