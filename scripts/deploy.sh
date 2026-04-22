#!/bin/bash
# ============================================================
# deploy.sh — Called by GitHub Actions on the Droplet.
#             Pulls latest code and restarts services.
# ============================================================
set -e

APP_DIR="/opt/vriksharopan-app"

echo "==> Pulling latest code..."
cd "$APP_DIR"
git pull origin main

echo "==> Rebuilding and restarting services..."
docker compose up -d --build --remove-orphans

echo "==> Removing unused Docker images..."
docker image prune -f

echo "==> Deployment complete!"
docker compose ps
