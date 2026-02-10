#!/bin/bash
set -e

STATE_DIR="/var/www/doctorx24-infra/state"
ACTIVE_FILE="$STATE_DIR/active_color"
NGINX_DIR="/var/www/doctorx24-infra/nginx"

ACTIVE=$(cat "$ACTIVE_FILE")

if [ "$ACTIVE" = "blue" ]; then
  NEW="green"
else
  NEW="blue"
fi

echo "🔀 Switching traffic: $ACTIVE → $NEW"

# Point nginx to new backend
ln -sf "$NGINX_DIR/backend-$NEW.conf" "$NGINX_DIR/active-backend.conf"

# Test nginx config
sudo nginx -t

# Reload nginx (zero downtime)
sudo systemctl reload nginx

# Update active color
echo "$NEW" > "$ACTIVE_FILE"

echo "✅ Traffic switched to $NEW"

