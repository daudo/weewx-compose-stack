#!/bin/bash
set -e

# Inigo Extension Patching Script
# This script applies patches to the Inigo extension if needed

# Source common utilities
source /init/common.sh

log_info "Applying patches for Inigo extension..."

# Install pyephem for enhanced almanac data (optional but recommended)
install_pyephem() {
    log_info "Installing pyephem for enhanced almanac support..."
    if pip3 install pyephem --target /data/lib/python/site-packages --quiet; then
        log_success "pyephem installed successfully"
    else
        log_warning "pyephem installation failed, continuing..."
    fi
}

# Apply patches
install_pyephem

# Note: Inigo extension typically doesn't need many patches
# Any future compatibility fixes would go here

log_success "Inigo patch phase completed"