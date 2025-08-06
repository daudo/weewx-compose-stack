#!/bin/bash
set -e

echo "=== Nginx Configuration Setup ==="

# Configuration
NGINX_CONF_SOURCE="/tmp/nginx.conf"
NGINX_CONF_DEST="/data/nginx/nginx.conf"

# Ensure required directories exist
mkdir -p /data/nginx

# Copy nginx configuration if it doesn't exist
if [ ! -f "$NGINX_CONF_DEST" ]; then
    echo "Installing nginx configuration..."
    cp "$NGINX_CONF_SOURCE" "$NGINX_CONF_DEST"
    echo "Nginx configuration installed successfully"
else
    echo "Nginx configuration already exists, skipping installation"
fi

echo "Nginx configuration setup complete!"
echo "Configuration location: $NGINX_CONF_DEST"