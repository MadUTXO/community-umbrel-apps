#!/bin/bash
set -e

DATA_DIR="/var/lib/headscale"
KEY_FILE="$DATA_DIR/api_key.txt"

echo "=== Headscale Setup ==="

if [ ! -f "$KEY_FILE" ]; then
    echo "Waiting for Headscale to be ready..."
    sleep 5
    
    echo "Generating API key..."
    KEY=$(headscale apikeys create --expiration 8760h 2>&1 | grep -oP 'Key: \K[^\s]+' || true)
    
    if [ -n "$KEY" ]; then
        echo "$KEY" > "$KEY_FILE"
        chmod 600 "$KEY_FILE"
        echo "========================================"
        echo "API KEY GENERATED: $KEY"
        echo "========================================"
        echo "Use this key in the web UI at port 9080"
    else
        echo "Warning: Could not extract API key automatically"
        echo "You may need to create it manually after server starts"
    fi
else
    echo "API key already exists"
fi

echo "=== Starting Headscale ==="
exec "$@"