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
    local source_dir="/home/udo/git/weewx-belchertown/skins/Belchertown/lang"
    local target_dir="/data/skins/Belchertown/lang"
    
    if [ -d "$source_dir" ] && [ ! -d "$target_dir" ]; then
        echo "Copying missing language files from $source_dir to $target_dir"
        mkdir -p "$(dirname "$target_dir")"
        cp -r "$source_dir" "$target_dir"
        echo "Successfully copied language files (de.conf, ca.conf, it.conf)"
    elif [ -d "$target_dir" ]; then
        echo "Language files already present at $target_dir"
    else
        echo "Warning: Source language directory $source_dir not found"
    fi
}

# Apply all patches
apply_python_compatibility
copy_missing_language_files

echo "Belchertown patch phase completed"