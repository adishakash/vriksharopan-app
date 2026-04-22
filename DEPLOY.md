# Vrisharopan — Deployment Guide (DigitalOcean)

This guide gets you from zero to a live production server in under 30 minutes.

---

## What Gets Deployed

| Service      | URL                          |
|--------------|------------------------------|
| Website      | https://vrisharopan.in       |
| Backend API  | https://api.vrisharopan.in   |
| Admin Panel  | https://admin.vrisharopan.in |
| Database     | PostgreSQL (internal only)   |

Everything runs via **Docker Compose** on a single DigitalOcean Droplet behind **Nginx** with **Let's Encrypt SSL** (auto-managed).

---

## Part 1 — One-Time Server Setup

### Step 1: Create a Droplet on DigitalOcean

1. Go to [cloud.digitalocean.com](https://cloud.digitalocean.com) → **Droplets → Create Droplet**
2. Choose:
   - **Image**: Ubuntu 22.04 LTS (x64)
   - **Plan**: Basic — **2 vCPU / 4 GB RAM** ($24/mo) — *recommended for production*
   - **Datacenter**: Mumbai (BLR1) — closest to India
   - **Authentication**: SSH Key (add your public key)
3. Click **Create Droplet** and copy the **IPv4 address**

### Step 2: Point Your Domain to the Droplet

In your domain registrar (or DigitalOcean DNS), create these A records:

| Host             | Type | Value          |
|------------------|------|----------------|
| `vrisharopan.in` | A    | `<Droplet IP>` |
| `www`            | A    | `<Droplet IP>` |
| `api`            | A    | `<Droplet IP>` |
| `admin`          | A    | `<Droplet IP>` |

> DNS can take up to 10–30 minutes to propagate.

### Step 3: Run the One-Time Setup Script

```bash
# SSH into your Droplet
ssh root@<Droplet IP>

# Download and run the setup script
curl -fsSL https://raw.githubusercontent.com/adishakash/vriksharopan-app/main/scripts/setup-droplet.sh | bash
```

This installs Docker, Docker Compose, git, and configures the firewall.

### Step 4: Configure Environment Variables

```bash
cd /opt/vriksharopan-app

# Backend config
cp backend/.env.example backend/.env
nano backend/.env       # Fill in all values (see table below)

# Website config
cp website/.env.example website/.env
nano website/.env       # Fill in Razorpay key and API URL
```

#### Required backend `.env` values

| Variable | Where to get it |
|---|---|
| `POSTGRES_PASSWORD` | Any strong password you choose |
| `JWT_SECRET` | Generate: `openssl rand -hex 32` |
| `JWT_REFRESH_SECRET` | Generate: `openssl rand -hex 32` |
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` | AWS IAM console |
| `AWS_S3_BUCKET` | Your S3 bucket name |
| `RAZORPAY_KEY_ID` / `RAZORPAY_KEY_SECRET` | Razorpay dashboard |
| `RAZORPAY_WEBHOOK_SECRET` | Razorpay dashboard → Webhooks |
| `FIREBASE_PROJECT_ID` / `FIREBASE_CLIENT_EMAIL` / `FIREBASE_PRIVATE_KEY` | Firebase console → Service Accounts |
| `SMTP_USER` / `SMTP_PASSWORD` | Your email provider (Gmail App Password) |

Also update root `docker-compose.yml` → `POSTGRES_PASSWORD` to match what you set in `backend/.env`.

### Step 5: Get SSL Certificates

> Make sure DNS is propagated before this step (verify with `ping vrisharopan.in`)

```bash
cd /opt/vriksharopan-app
bash scripts/init-ssl.sh
```

**That's it — your app is live at https://vrisharopan.in** 🎉

---

## Part 2 — Auto-Deploy on Every Git Push

Set this up once so every `git push` to `main` automatically deploys to the server.

### Step 1: Generate a Deploy SSH Key

On your **Droplet**, run:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/deploy_key -N ""
cat ~/.ssh/deploy_key.pub >> ~/.ssh/authorized_keys
cat ~/.ssh/deploy_key       # Copy the PRIVATE key output
```

### Step 2: Add GitHub Repository Secrets

Go to your GitHub repo → **Settings → Secrets and variables → Actions → New repository secret**:

| Secret Name      | Value                                    |
|------------------|------------------------------------------|
| `DROPLET_HOST`   | Your Droplet's IPv4 address              |
| `DROPLET_USER`   | `root`                                   |
| `DROPLET_SSH_KEY`| The **private key** from the step above  |

### Step 3: Test Auto-Deploy

Make any small change locally, then:

```bash
git add .
git commit -m "test: trigger auto-deploy"
git push origin main
```

Go to GitHub → **Actions** to watch the deployment live. After ~2 minutes, your changes are live.

---

## Useful Commands (on the Droplet)

```bash
# View all running services
docker compose -f /opt/vriksharopan-app/docker-compose.yml ps

# View live logs
docker compose -f /opt/vriksharopan-app/docker-compose.yml logs -f

# View backend logs only
docker compose -f /opt/vriksharopan-app/docker-compose.yml logs -f backend

# Manual deploy (without GitHub push)
bash /opt/vriksharopan-app/scripts/deploy.sh

# Access the database
docker exec -it vrisharopan_postgres psql -U vrisharopan -d vrisharopan_db
```

---

## SSL Certificate Renewal (Automatic)

Add this cron job on the Droplet so certs renew automatically every 3 months:

```bash
crontab -e
```

Add this line:
```
0 3 * * 1 cd /opt/vriksharopan-app && docker run --rm -v $(pwd)/nginx/certbot/www:/var/www/certbot -v $(pwd)/nginx/certbot/certs:/etc/letsencrypt certbot/certbot renew --quiet && docker compose exec nginx nginx -s reload
```

---

## Architecture Overview

```
Internet → Nginx (80/443) → [ website:3000 | api:5000 | admin:3001 ]
                                                ↓
                                         PostgreSQL:5432
```

All services communicate on an internal Docker network (`vrisharopan_net`). Only Nginx is exposed to the internet.
