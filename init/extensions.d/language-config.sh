#!/bin/bash
set -e

# Language Configuration Script
# This script configures WeeWX language settings for various skins and extensions

# Skip if no language specified or already in English
if [ -z "$WEEWX_LANGUAGE" ] || [ "$WEEWX_LANGUAGE" = "en" ]; then
    echo "Language configuration: Using default English"
    return 0 2>/dev/null || exit 0
fi

echo "Configuring language settings for: $WEEWX_LANGUAGE"

# Apply language configuration to weewx.conf if it exists
if [ -f "/data/weewx.conf" ]; then
    # Configure Seasons skin language (WeeWX standard approach)
    if ! grep -q "lang.*=" /data/weewx.conf; then
        # Add lang setting to SeasonsReport section
        sed -i "/\[SeasonsReport\]/a\\        lang = $WEEWX_LANGUAGE" /data/weewx.conf
    else
        # Update existing lang setting
        sed -i "s|lang.*=.*|lang = $WEEWX_LANGUAGE|g" /data/weewx.conf
    fi
    
    echo "Language configuration applied to WeeWX skins: $WEEWX_LANGUAGE"
else
    echo "Warning: /data/weewx.conf not found, language configuration will be applied later"
fi