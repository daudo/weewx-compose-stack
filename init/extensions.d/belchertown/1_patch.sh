#!/bin/bash
set -e

# Belchertown Skin Patching Script
# This script applies patches to fix upstream bugs and missing files

echo "Applying patches for Belchertown skin..."

# Patch 1: Apply Python 3.13 locale.format monkey-patch
apply_python_compatibility() {
    local file_path="/data/bin/user/belchertown.py"
    
    if [ -f "$file_path" ]; then
        echo "Applying Python 3.13 compatibility patch to $file_path"
        
        # Source the compatibility functions
        source /init/python313-compat.sh
        apply_locale_format_monkeypatch "$file_path" "Belchertown"
        
        echo "Python compatibility patch applied successfully"
    else
        echo "Warning: Belchertown script not found at $file_path"
    fi
}

# Patch 2: Copy missing language files (fix for upstream bug)
copy_missing_language_files() {
    local target_dir="/data/skins/Belchertown/lang"
    local temp_dir="/tmp/belchertown_extract"
    local belchertown_file="/tmp/belchertown-current.tar.gz"
    
    # Check if downloaded file exists
    if [ ! -f "$belchertown_file" ]; then
        echo "Warning: Belchertown download file not found at $belchertown_file"
        return 0
    fi
    
    echo "Extracting language files from $belchertown_file"
    
    # Create temporary extraction directory
    mkdir -p "$temp_dir"
    
    # Extract the tar.gz file temporarily
    if tar -xzf "$belchertown_file" -C "$temp_dir" 2>/dev/null; then
        # Find the extracted directory (it has a version-specific name)
        local extracted_dir=$(find "$temp_dir" -maxdepth 1 -type d -name "weewx-belchertown-new-*" | head -1)
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

# Patch 3: Fix Cheetah template parsing issue in v1.4 
fix_template_parsing() {
    local template_file="/data/skins/Belchertown/pi/index.html.tmpl"
    
    if [ -f "$template_file" ]; then
        echo "Fixing Cheetah template parsing issue in $template_file"
        
        # Fix sunrise format string - add missing space between %M and %p
        sed -i 's/%-I:%M%p/%-I:%M %p/g' "$template_file"
        
        echo "Template parsing fix applied successfully"
    else
        echo "Warning: Template file not found at $template_file"
    fi
}

# Apply all patches
apply_python_compatibility
copy_missing_language_files
fix_template_parsing

echo "Belchertown patch phase completed"