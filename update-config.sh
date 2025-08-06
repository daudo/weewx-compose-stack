#!/bin/bash
set -e

echo "=========================================="
echo "WeeWX Configuration Update"
echo "=========================================="
echo "This script will update your WeeWX configuration"
echo "with the current environment variables."
echo ""

# Run only the configuration step
echo "Running weewx-init container to update configuration..."
docker compose run --rm weewx-init /init/configure-weewx.sh

echo ""
echo "Configuration updated! Restarting WeeWX service..."
docker compose restart weewx

echo ""
echo "=========================================="
echo "Update complete!"
echo "=========================================="
echo "Your WeeWX configuration has been updated with"
echo "the current environment variables from .env file."
echo ""
echo "Web interface: http://localhost:${NGINX_PORT:-8080}"
echo "=========================================="