#!/bin/bash
set -e

# Belchertown Skin Patching Script
# This script applies patches and fixes upstream bugs using a hybrid approach

# Source common utilities
source "$(dirname "$0")/../../common.sh"

log_info "Applying patches for Belchertown skin..."

# 2. Handle file additions/corrections with simple operations
copy_missing_language_files() {
    local target_dir="/data/skins/Belchertown/lang"
    local temp_dir="/tmp/belchertown_extract"
    local belchertown_file="/tmp/belchertown-current.tar.gz"
    
    # Check if downloaded file exists
    if [ ! -f "$belchertown_file" ]; then
        echo "Warning: Belchertown download file not found at $belchertown_file"
        return 0
    fi
    
    echo "Extracting and copying missing language files..."
    
    # Create temporary extraction directory
    mkdir -p "$temp_dir"
    
    # Extract the tar.gz file temporarily
    if tar -xzf "$belchertown_file" -C "$temp_dir" 2>/dev/null; then
        # Find the extracted directory (it has a version-specific name)
        local extracted_dir=$(find "$temp_dir" -maxdepth 1 -type d -name "weewx-belchertown-*" | head -1)
        local source_dir="$extracted_dir/skins/Belchertown/lang"
        
        if [ -d "$source_dir" ]; then
            echo "Copying language files from extracted archive to $target_dir"
            mkdir -p "$(dirname "$target_dir")"
            cp -r "$source_dir" "$target_dir"
            echo "Successfully copied language files (de.conf, ca.conf, it.conf)"
        else
            echo "Warning: Language directory not found in extracted archive"
        fi
    else
        echo "Warning: Failed to extract $belchertown_file"
    fi
    
    # Clean up temporary extraction
    rm -rf "$temp_dir"
}

# Apply all patches and fixes
apply_patch_files
copy_missing_language_files

log_success "Belchertown patch phase completed"