#!/bin/bash
set -e

DATA_DIR="/data"
KEY_FILE="$DATA_DIR/api_key.txt"
HTML_FILE="$DATA_DIR/setup.html"
HS_SOCKET="/var/run/headscale/headscale.sock"

echo "=== Headscale Setup Server ==="
echo "Waiting for Headscale..."

# Wait for Headscale to be ready
for i in $(seq 1 60); do
    if [ -S "$HS_SOCKET" ]; then
        echo "Headscale is ready!"
        break
    fi
    sleep 1
done

# Give Headscale a moment to fully start
sleep 3

# Generate API key if not exists
if [ ! -f "$KEY_FILE" ]; then
    echo "Generating API key..."
    KEY_OUTPUT=$(headscale -c /etc/headscale/config.yaml apikeys create --expiration 8760h 2>&1 || true)
    KEY=$(echo "$KEY_OUTPUT" | grep -oP 'Key: \K[^\s]+' || echo "")
    
    if [ -n "$KEY" ]; then
        echo "$KEY" > "$KEY_FILE"
        chmod 600 "$KEY_FILE"
        echo "API Key generated!"
    else
        echo "Warning: Could not extract key: $KEY_OUTPUT"
    fi
fi

# Read the key for the HTML
if [ -f "$KEY_FILE" ]; then
    API_KEY=$(cat "$KEY_FILE")
else
    API_KEY="Not ready. Check container logs."
fi

# Create HTML page with embedded key
cat > "$HTML_FILE" << HTMLEOF
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Headscale Setup</title>
  <style>
    * { box-sizing: border-box; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; 
           max-width: 500px; margin: 40px auto; padding: 20px; background: #0f0f23; color: #eee; }
    .box { background: #1a1a2e; padding: 24px; border-radius: 12px; }
    h1 { color: #00d4ff; margin-top: 0; }
    .step { background: #16213e; padding: 12px; border-radius: 8px; margin: 10px 0; }
    .key { background: #0f3460; padding: 14px; border-radius: 8px; 
           font-family: 'SF Mono', Monaco, monospace; word-break: break-all; margin: 16px 0; 
           font-size: 14px; }
    .btn { background: #00d4ff; color: #0f0f23; padding: 14px 24px; 
           border: none; border-radius: 8px; cursor: pointer; font-size: 16px; width: 100%; 
           font-weight: 600; }
    .btn:hover { background: #00b8e6; }
    .warn { background: #ff6b6b20; border-left: 3px solid #ff6b6b; 
            padding: 12px; margin-top: 16px; font-size: 13px; }
    code { background: #0f3460; padding: 2px 6px; border-radius: 4px; font-size: 13px; }
  </style>
</head>
<body>
  <div class="box">
    <h1>Headscale Setup</h1>
    
    <div class="step">
      <strong>Quick Guide:</strong><br>
      1. Copy the API key below<br>
      2. Open Web UI at port 8083<br>
      3. Enter API URL: <code>http://YOUR_IP:8080</code><br>
      4. Paste the key and save
    </div>
    
    <div class="key" id="key">$API_KEY</div>
    <button class="btn" onclick="copyKey()">📋 Copy API Key</button>
    
    <div class="warn" id="warn">
      ⚠️ After copying, the key will be <strong>DELETED</strong> for security!
    </div>
  </div>
  
  <script>
    let deleted = false;
    async function copyKey() {
      if (deleted) return;
      
      const key = document.getElementById('key').textContent.trim();
      await navigator.clipboard.writeText(key);
      
      document.querySelector('.btn').textContent = '✓ Copied!';
      deleted = true;
      
      // Delete the key
      try {
        await fetch('/delete', { method: 'POST' });
      } catch(e) {}
      
      setTimeout(() => {
        document.getElementById('key').textContent = '[DELETED FOR SECURITY]';
        document.getElementById('warn').style.display = 'none';
        document.querySelector('.btn').style.display = 'none';
      }, 2000);
    }
  </script>
</body>
</html>
HTMLEOF

# Create delete script
echo '#!/bin/sh' > "$DATA_DIR/delete"
echo "rm -f $KEY_FILE $DATA_DIR/delete $HTML_FILE" >> "$DATA_DIR/delete"
chmod +x "$DATA_DIR/delete"

echo "========================================"
echo "Setup page: http://127.0.0.1:8084"
echo "========================================"

# Start nginx on localhost only for security
exec nginx -g 'daemon off;'
