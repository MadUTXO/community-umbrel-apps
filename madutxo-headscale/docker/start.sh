#!/bin/bash
set -e

DATA_DIR="/data"

echo "=== Headscale Setup Server ==="

# Wait for key to be generated
for i in $(seq 1 60); do
    [ -f "$DATA_DIR/api_key.txt" ] && break
    sleep 2
done

# Get key
KEY=$(cat "$DATA_DIR/api_key.txt" 2>/dev/null || echo "Not ready")

# Create HTML page
cat > "$DATA_DIR/index.html" << HTMLEOF
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Headscale Setup</title>
  <style>
    body{font-family:-apple-system,sans-serif;max-width:450px;margin:40px auto;padding:20px;background:#0f0f23;color:#eee}
    .box{background:#1a1a2e;padding:24px;border-radius:12px}
    h1{color:#00d4ff}
    .key{background:#0f3460;padding:14px;border-radius:8px;font-family:monospace;word-break:break-all;margin:16px 0}
    .btn{background:#00d4ff;color:#0f0f23;padding:14px;border:none;border-radius:8px;cursor:pointer;width:100%}
  </style>
</head>
<body>
  <div class="box">
    <h1>Headscale Setup</h1>
    <p>Copy key → paste in Web UI (port 8083)</p>
    <div class="key" id="k">$KEY</div>
    <button class="btn" onclick="cp()">Copy</button>
  </div>
  <script>
    function cp(){navigator.clipboard.writeText(document.getElementById('k').textContent);document.querySelector('.btn').textContent='✓'}
  </script>
</body>
</html>
HTMLEOF

echo "========================================"
echo "Setup: http://127.0.0.1:8084"
echo "========================================"

# Start nginx
exec nginx -g 'daemon off;'
