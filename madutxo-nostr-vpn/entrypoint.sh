#!/bin/bash
set -e

# Try to create directories, but don't fail if they exist or can't be created
mkdir -p /data/.config/nvpn 2>/dev/null || true
chmod 755 /data 2>/dev/null || true

# Start the web interface
exec /usr/local/bin/nvpn-web