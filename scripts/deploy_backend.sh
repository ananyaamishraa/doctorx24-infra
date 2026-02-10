#!/bin/bash
set -e

STATE_FILE="/var/www/doctorx24-infra/state/active_color"
NGINX_SWITCH_SCRIPT="/var/www/doctorx24-infra/scripts/switch_backend.sh"

# Read active color
ACTIVE_COLOR=$(cat "$STATE_FILE")

# Decide target color
if [ "$ACTIVE_COLOR" = "blue" ]; then
  TARGET_COLOR="green"
  TARGET_PORT=5002
else
  TARGET_COLOR="blue"
  TARGET_PORT=5001
fi

echo "🔁 Active: $ACTIVE_COLOR | Deploying to: $TARGET_COLOR"

# Rollback function
rollback() {
  echo "❌ Health check failed. Rolling back to $ACTIVE_COLOR"
  echo "$ACTIVE_COLOR" > "$STATE_FILE"
  bash "$NGINX_SWITCH_SCRIPT"
  exit 1
}

# Pull latest image for target
echo "📦 Pulling image for backend-$TARGET_COLOR..."
docker compose pull backend-$TARGET_COLOR

# Start / recreate target container
echo "🚀 Starting backend-$TARGET_COLOR..."
docker compose up -d backend-$TARGET_COLOR

# Wait for container to boot
echo "⏳ Waiting for backend-$TARGET_COLOR to start..."
sleep 8

# Health check
echo "🩺 Running health check on backend-$TARGET_COLOR..."
echo "👉 Hitting: http://localhost:$TARGET_PORT/health"

if curl -sf "http://localhost:$TARGET_PORT/health"; then
  echo "📡 HTTP STATUS: 200"
  echo "✅ Health check PASSED for backend-$TARGET_COLOR"
else
  rollback
fi

# Switch traffic
echo "🔀 Switching traffic..."
bash "$NGINX_SWITCH_SCRIPT"

# Persist new active color
echo "$TARGET_COLOR" > "$STATE_FILE"

echo "🎉 Deployment complete. Active backend is now: $TARGET_COLOR"

