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

# Function to run 3-phase extension (install, patch, configure)
run_extension_phases() {
    local extension_dir=$1
    local extension_name=$(basename "$extension_dir")
    
    echo ""
    echo "Processing extension: $extension_name"
    echo "=========================================="
    
    # Phase 0: Install
    local install_script="$extension_dir/0_install.sh"
    if [ -f "$install_script" ] && [ -x "$install_script" ]; then
        echo ""
        echo "Phase 0: Installing $extension_name..."
        echo "----------------------------------------"
        if bash "$install_script"; then
            echo "Installation phase completed successfully"
        else
            echo "Warning: Installation phase failed (exit code: $?)"
            return 1
        fi
    else
        echo "No installation script found or not executable: $install_script"
    fi
    
    # Phase 1: Patch
    local patch_script="$extension_dir/1_patch.sh"
    if [ -f "$patch_script" ] && [ -x "$patch_script" ]; then
        echo ""
        echo "Phase 1: Patching $extension_name..."
        echo "----------------------------------------"
        if bash "$patch_script"; then
            echo "Patch phase completed successfully"
        else
            echo "Warning: Patch phase failed (exit code: $?)"
            return 1
        fi
    else
        echo "No patch script found or not executable: $patch_script (skipping)"
    fi
    
    # Phase 2: Configure
    local configure_script="$extension_dir/2_configure.sh"
    if [ -f "$configure_script" ] && [ -x "$configure_script" ]; then
        echo ""
        echo "Phase 2: Configuring $extension_name..."
        echo "----------------------------------------"
        if bash "$configure_script"; then
            echo "Configuration phase completed successfully"
        else
            echo "Warning: Configuration phase failed (exit code: $?)"
            return 1
        fi
    else
        echo "No configuration script found or not executable: $configure_script (skipping)"
    fi
    
    echo "Extension $extension_name processing completed"
}

# Find extension directories (excluding templates)
extension_dirs=$(find "$EXTENSIONS_DIR" -maxdepth 1 -type d ! -path "$EXTENSIONS_DIR" ! -name "templates" 2>/dev/null | sort)

if [ -n "$extension_dirs" ]; then
    echo "Found extension directories:"
    for ext_dir in $extension_dirs; do
        echo "  - $(basename "$ext_dir")"
    done
    
    # Process each extension directory
    for ext_dir in $extension_dirs; do
        run_extension_phases "$ext_dir"
    done
else
    echo "No extensions found in $EXTENSIONS_DIR"
fi

echo ""
echo "=========================================="
echo "Extension installation completed!"
echo "=========================================="

# Clean up excess backup files created during extension installations
echo "Cleaning up backup files..."
source /init/backup-config.sh
manage_backups cleanup

# Display summary of installed extensions
if command -v weectl >/dev/null 2>&1; then
    echo "Installed extensions:"
    weectl extension list --config=/data/weewx.conf || echo "  Unable to list extensions"
else
    echo "  WeeWX tools not available for extension listing"
fi