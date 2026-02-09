#!/bin/bash
set -e

ACTIVE_PORT=$(grep server /etc/nginx/conf.d/active-backend.conf | grep -o '[0-9]\+')

if [ "$ACTIVE_PORT" = "5001" ]; then
  NEW="green"
  NEW_PORT=5002
else
  NEW="blue"
  NEW_PORT=5001
fi

echo "Deploying to $NEW ($NEW_PORT)"

docker compose pull backend-$NEW
docker compose up -d backend-$NEW

echo "Waiting for health check..."
sleep 15

curl -f http://127.0.0.1:$NEW_PORT/health

sed -i "s/$ACTIVE_PORT/$NEW_PORT/" /etc/nginx/conf.d/active-backend.conf
nginx -s reload

echo "Switched traffic to $NEW"

