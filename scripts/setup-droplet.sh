#!/bin/bash
# ============================================================
# setup-droplet.sh — ONE-TIME setup for DigitalOcean Droplet
# Run as root on a fresh Ubuntu 22.04 LTS Droplet
# ============================================================
set -e

APP_DIR="/opt/vriksharopan-app"
REPO_URL="https://github.com/adishakash/vriksharopan-app.git"

echo "==> Updating system packages..."
apt-get update -y && apt-get upgrade -y

echo "==> Installing Docker..."
curl -fsSL https://get.docker.com | sh
systemctl enable docker
systemctl start docker

echo "==> Installing Docker Compose plugin..."
apt-get install -y docker-compose-plugin

echo "==> Installing git and other utilities..."
apt-get install -y git curl wget ufw

echo "==> Configuring firewall (UFW)..."
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

echo "==> Creating app directory..."
mkdir -p "$APP_DIR"
cd "$APP_DIR"

echo "==> Cloning repository..."
git clone "$REPO_URL" .

echo ""
echo "============================================================"
echo " Setup complete!"
echo "============================================================"
echo ""
echo " Next steps:"
echo "  1. cd $APP_DIR"
echo "  2. cp backend/.env.example backend/.env   && fill in values"
echo "  3. cp website/.env.example  website/.env  && fill in values"
echo "  4. Make sure your domain DNS points to this server's IP"
echo "  5. Run: bash scripts/init-ssl.sh"
echo ""
