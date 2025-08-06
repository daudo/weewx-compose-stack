#!/bin/bash
set -e

echo "Installing WeeWX extensions..."

# Directory containing extension scripts
EXTENSIONS_DIR="${EXTENSIONS_DIR:-/init/extensions.d}"

# Check if extensions directory exists
if [ ! -d "$EXTENSIONS_DIR" ]; then
    echo "Warning: Extensions directory $EXTENSIONS_DIR not found"
    exit 0
fi

# Function to safely run extension scripts
run_extension_script() {
    local script_path=$1
    local script_name=$(basename "$script_path")
    
    echo ""
    echo "Running extension script: $script_name"
    echo "----------------------------------------"
    
    if [ -x "$script_path" ]; then
        # Source the script in the current shell to inherit environment variables
        if bash "$script_path"; then
            echo "Extension script $script_name completed successfully"
        else
            echo "Warning: Extension script $script_name failed (exit code: $?)"
        fi
    else
        echo "Warning: Extension script $script_path is not executable, skipping"
    fi
}

# Get list of extension scripts and sort them for consistent execution order
extension_scripts=$(find "$EXTENSIONS_DIR" -name "*.sh" -type f | sort)

if [ -z "$extension_scripts" ]; then
    echo "No extension scripts found in $EXTENSIONS_DIR"
else
    echo "Found extension scripts:"
    for script in $extension_scripts; do
        echo "  - $(basename "$script")"
    done
    
    # Execute each extension script
    for script in $extension_scripts; do
        run_extension_script "$script"
    done
fi

echo ""
echo "=========================================="
echo "Extension installation completed!"
echo "=========================================="

# Display summary of installed extensions
if command -v weectl >/dev/null 2>&1; then
    echo "Installed extensions:"
    weectl extension list --config=/data/weewx.conf || echo "  Unable to list extensions"
else
    echo "  WeeWX tools not available for extension listing"
fi