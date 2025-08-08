#!/bin/bash
set -e

# Inigo Extension Patching Script
# This script applies patches to the Inigo extension if needed

echo "Applying patches for Inigo extension..."

# Install pyephem for enhanced almanac data (optional but recommended)
install_pyephem() {
    echo "Installing pyephem for enhanced almanac support..."
    if pip3 install pyephem --target /data/lib/python/site-packages --quiet; then
        echo "pyephem installed successfully"
    else
        echo "Warning: pyephem installation failed, continuing..."
    fi
}

# Apply patches
install_pyephem

# Note: Inigo extension typically doesn't need many patches
# Any future compatibility fixes would go here

echo "Inigo patch phase completed"