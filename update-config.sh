#!/bin/bash
set -e

echo "=========================================="
echo "WeeWX Configuration Update"
echo "=========================================="
echo "This script will update your WeeWX configuration"
echo "with the current environment variables."
echo ""

# Run the configuration and extensions installation
echo "Running weewx-init container to update configuration and extensions..."
docker compose run --rm weewx-init

echo ""
echo "Configuration updated! Restarting WeeWX service..."
docker compose restart weewx

echo ""
echo "=========================================="
echo "Update complete!"
echo "=========================================="
echo "Your WeeWX configuration and extensions have been updated"
echo "with the current environment variables from .env file."
echo ""
echo "Web interface: http://localhost:${NGINX_PORT:-8080}"
echo "=========================================="