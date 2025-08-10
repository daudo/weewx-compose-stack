#!/bin/bash
set -e

# Extension Patching Script Template
# This script applies patches using a hybrid approach: patch files for code changes, simple operations for file additions

EXTENSION_NAME="${EXTENSION_NAME:-ExtensionName}"

echo "Applying patches for $EXTENSION_NAME..."

# 1. Apply code patches using patch files
apply_patch_files() {
    local patch_dir="$(dirname "$0")/patches"
    
    if [ -d "$patch_dir" ]; then
        echo "Applying patch files from $patch_dir"
        for patch_file in "$patch_dir"/*.patch; do
            if [ -f "$patch_file" ]; then
                echo "Applying $(basename "$patch_file")..."
                if patch -p0 -d /data < "$patch_file"; then
                    echo "Successfully applied $(basename "$patch_file")"
                else
                    echo "Warning: Failed to apply $(basename "$patch_file")"
                fi
            fi
        done
    else
        echo "No patches directory found at $patch_dir"
    fi
}

# 2. Handle file additions/corrections with simple operations
fix_missing_files() {
    # Example: Copy missing files from downloaded archive
    # This is useful when upstream installation is incomplete
    
    echo "Checking for missing files..."
    
    # Add your file operation logic here
    # Example:
    # if [ ! -f "/data/expected/file.txt" ]; then
    #     echo "Copying missing file..."
    #     cp "/tmp/source/file.txt" "/data/expected/file.txt"
    # fi
}

# Apply all patches and fixes
apply_patch_files
fix_missing_files

echo "$EXTENSION_NAME patch phase completed"