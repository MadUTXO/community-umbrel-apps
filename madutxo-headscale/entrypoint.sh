#!/bin/bash
set -e

CONFIG_FILE="/etc/headscale/config.yaml"

# Create directories (distroless image has no shell, but has basic utilities)
mkdir -p /etc/headscale /var/lib/headscale /tmp

# If config doesn't exist, download from GitHub using wget
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Downloading Headscale config from GitHub..."
    wget -q -O "$CONFIG_FILE" "https://raw.githubusercontent.com/MadUTXO/community-umbrel-apps/master/madutxo-headscale/config.yaml" || true
fi

# Execute the main command (headscale binary directly, not through shell)
exec "$@"