#!/bin/bash
set -e

# Extension Patching Script Template
# This script applies patches to fix upstream bugs or missing files

EXTENSION_NAME="${EXTENSION_NAME:-ExtensionName}"

echo "Applying patches for $EXTENSION_NAME..."

# Example: Copy missing files (like Belchertown lang files)
copy_missing_files() {
    local source_dir="$1"
    local target_dir="$2"
    local description="$3"
    
    if [ -d "$source_dir" ] && [ ! -d "$target_dir" ]; then
        echo "Copying missing $description from $source_dir to $target_dir"
        mkdir -p "$(dirname "$target_dir")"
        cp -r "$source_dir" "$target_dir"
        echo "Successfully copied $description"
    elif [ -d "$target_dir" ]; then
        echo "$description already present at $target_dir"
    else
        echo "Warning: Source directory $source_dir not found for $description"
    fi
}

# Example: Apply Python compatibility patches
apply_python_compatibility() {
    local file_path="$1"
    local extension_name="$2"
    
    if [ -f "$file_path" ]; then
        echo "Applying Python 3.13 compatibility patch to $file_path"
        
        # Source the compatibility functions
        source /init/python313-compat.sh
        apply_locale_format_monkeypatch "$file_path" "$extension_name"
        
        echo "Python compatibility patch applied successfully"
    else
        echo "Warning: Target file $file_path not found for patching"
    fi
}

# TODO: Add specific patches for this extension
# Examples:
# copy_missing_files "/path/to/source/lang" "/data/skins/Extension/lang" "language files"
# apply_python_compatibility "/data/bin/user/extension.py" "$EXTENSION_NAME"

# For extensions that don't need patches, this script can be empty or just echo
echo "No patches required for $EXTENSION_NAME"

echo "$EXTENSION_NAME patch phase completed"