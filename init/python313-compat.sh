#!/bin/bash
# Python 3.13 Compatibility Functions
# This file provides reusable functions to fix Python 3.13 compatibility issues

# Apply Python 3.13 locale.format monkey-patch to a Python file
# Usage: apply_locale_format_monkeypatch "/path/to/file.py" "Extension Name"
apply_locale_format_monkeypatch() {
    local python_file="$1"
    local extension_name="${2:-Extension}"
    
    if [ ! -f "$python_file" ]; then
        echo "Python file not found: $python_file"
        return 1
    fi
    
    # Check if monkey-patch is already applied
    if grep -q "locale.format = locale.format_string" "$python_file"; then
        echo "$extension_name already has Python 3.13 locale.format monkey-patch"
        return 0
    fi
    
    # Check if file uses locale.format (to see if patch is needed)
    if grep -q "locale.format" "$python_file"; then
        echo "Applying Python 3.13 locale.format monkey-patch to $extension_name..."
        
        # Create backup with unique suffix
        local backup_file="${python_file}.py313backup"
        if [ ! -f "$backup_file" ]; then
            cp "$python_file" "$backup_file"
            echo "Created backup: $(basename "$backup_file")"
        fi
        
        # Add monkey-patch at the top of the file after any existing imports
        # First, check if locale is already imported
        if grep -q "^import locale" "$python_file"; then
            # Add monkey-patch after existing locale import
            sed -i '/^import locale/a locale.format = locale.format_string  # Python 3.13 compatibility' "$python_file"
        else
            # Add import and monkey-patch at the beginning
            sed -i '1i import locale\nlocale.format = locale.format_string  # Python 3.13 compatibility\n' "$python_file"
        fi
        
        echo "Python 3.13 locale.format monkey-patch applied to $extension_name"
    else
        echo "$extension_name does not use locale.format - no patch needed"
    fi
    
    return 0
}