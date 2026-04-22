#!/bin/bash
# ============================================================
# init-ssl.sh — Run ONCE after setup-droplet.sh to acquire
#               Let's Encrypt SSL certificates via Certbot.
# ============================================================
set -e

APP_DIR="/opt/vriksharopan-app"
EMAIL="admin@vrisharopan.in"
DOMAIN="vrisharopan.in"
DOMAINS="-d vrisharopan.in -d www.vrisharopan.in -d api.vrisharopan.in -d admin.vrisharopan.in"

cd "$APP_DIR"

echo "==> Step 1: Starting nginx with HTTP-only config to serve ACME challenge..."
# Temporarily swap to init config
cp nginx/nginx.conf nginx/nginx.conf.bak
cp nginx/nginx.init.conf nginx/nginx.conf

docker compose up -d nginx

echo "==> Step 2: Requesting SSL certificates from Let's Encrypt..."
docker run --rm \
  -v "$(pwd)/nginx/certbot/www:/var/www/certbot" \
  -v "$(pwd)/nginx/certbot/certs:/etc/letsencrypt" \
  certbot/certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email "$EMAIL" \
    --agree-tos \
    --no-eff-email \
    $DOMAINS

echo "==> Step 3: Restoring SSL nginx config..."
cp nginx/nginx.conf.bak nginx/nginx.conf

echo "==> Step 4: Updating docker-compose.yml to mount Certbot cert paths..."
# Update certbot volume paths in docker-compose to use local paths
sed -i "s|certbot_www:/var/www/certbot|./nginx/certbot/www:/var/www/certbot|g" docker-compose.yml
sed -i "s|certbot_certs:/etc/letsencrypt|./nginx/certbot/certs:/etc/letsencrypt|g" docker-compose.yml
# Also update nginx.conf SSL cert paths
sed -i "s|/etc/letsencrypt/live/vrisharopan.in/fullchain.pem|/etc/nginx/ssl/live/${DOMAIN}/fullchain.pem|g" nginx/nginx.conf
sed -i "s|/etc/letsencrypt/live/vrisharopan.in/privkey.pem|/etc/nginx/ssl/live/${DOMAIN}/privkey.pem|g" nginx/nginx.conf

# Create ssl symlink directory so nginx can find certs
mkdir -p nginx/ssl
ln -sfn "$(pwd)/nginx/certbot/certs/live" "$(pwd)/nginx/ssl/live"

echo "==> Step 5: Starting all services with SSL..."
docker compose down
docker compose up -d --build

echo ""
echo "============================================================"
echo " SSL setup complete! Your app is live at https://${DOMAIN}"
echo "============================================================"
echo ""
echo " Auto-renewal: Add this cron job (run: crontab -e)"
echo " 0 3 * * * cd $APP_DIR && docker run --rm -v \$(pwd)/nginx/certbot/www:/var/www/certbot -v \$(pwd)/nginx/certbot/certs:/etc/letsencrypt certbot/certbot renew --quiet && docker compose exec nginx nginx -s reload"
echo ""
