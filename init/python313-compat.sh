#!/bin/bash
# Python 3.13 Compatibility Functions
# This file provides reusable functions to fix Python 3.13 compatibility issues

# Fix locale.format() compatibility issues in a given Python file
# Usage: fix_locale_format_compatibility "/path/to/file.py" "Extension Name"
fix_locale_format_compatibility() {
    local python_file="$1"
    local extension_name="${2:-Extension}"
    
    if [ ! -f "$python_file" ]; then
        echo "Python file not found: $python_file"
        return 1
    fi
    
    if grep -q "locale.format" "$python_file"; then
        echo "Applying Python 3.13 compatibility fixes to $extension_name..."
        
        # Create backup with unique suffix
        local backup_file="${python_file}.py313backup"
        if [ ! -f "$backup_file" ]; then
            cp "$python_file" "$backup_file"
            echo "Created backup: $(basename "$backup_file")"
        fi
        
        # Replace locale.format() patterns with modern format() equivalents
        sed -i 's/locale\.format("%.1f", 0)/format(0, ".1f")/g' "$python_file"
        sed -i 's/locale\.format("%.0f", \([^)]*\))/format(\1, ".0f")/g' "$python_file"
        sed -i 's/locale\.format("%.1f", \([^)]*\))/format(\1, ".1f")/g' "$python_file"
        sed -i 's/locale\.format("%.2f", \([^)]*\))/format(\1, ".2f")/g' "$python_file"
        sed -i 's/locale\.format("%d", \([^)]*\))/format(\1, "d")/g' "$python_file"
        
        # Verify the fix was applied
        if ! grep -q "locale.format" "$python_file"; then
            echo "Python 3.13 compatibility fixes applied successfully to $extension_name"
        else
            echo "Warning: Some locale.format() patterns may remain in $extension_name"
        fi
    else
        echo "$extension_name is already compatible with Python 3.13"
    fi
    
    return 0
}