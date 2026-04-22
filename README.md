# Vrisharopan — Complete Setup Guide

## Architecture Overview

```
vrisharopan/
├── backend/          Node.js + Express API (Port 5000)
├── admin-panel/      React 18 + Vite Admin UI (Port 3001)
├── website/          Next.js 14 Public Website (Port 3000)
├── customer-app/     Flutter Android App (Customer)
├── worker-app/       Flutter Android App (Worker)
├── nginx/            Reverse proxy config
└── docker-compose.yml
```

**Business Model:** Customer pays ₹99/month per tree → Worker earns ₹20/tree/month → Platform keeps ₹79/tree/month.

---

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Node.js | 20+ | https://nodejs.org |
| Flutter | 3.x | https://flutter.dev |
| Docker + Compose | Latest | https://docker.com |
| PostgreSQL | 15+ (with PostGIS) | Via Docker preferred |
| Git | Any | https://git-scm.com |

---

## Step 1: Third-Party Service Setup

### 1a. Razorpay
1. Sign up at https://razorpay.com
2. Go to **Settings → API Keys** → Generate key pair
3. Note `Key ID` (starts with `rzp_`) and `Key Secret`
4. Go to **Subscriptions → Plans** → Create a plan:
   - Name: `Tree Subscription Monthly`
   - Period: `monthly`
   - Interval: `1`
   - Amount: `9900` (paise = ₹99)
   - Currency: `INR`
5. Note the `plan_id`
6. Go to **Settings → Webhooks** → Add webhook:
   - URL: `https://api.yourdomain.in/api/payments/webhook`
   - Events: `subscription.activated`, `subscription.charged`, `subscription.cancelled`
   - Note the **Webhook Secret**

### 1b. Firebase
1. Go to https://console.firebase.google.com
2. Create a new project (e.g., `vrisharopan`)
3. Enable **Cloud Messaging (FCM)**
4. Go to **Project Settings → Service Accounts** → Generate new private key
5. Download the JSON file — you'll need:
   - `project_id`
   - `client_email`
   - `private_key`
6. Add Android apps:
   - Customer App: package `com.vrisharopan.customer`
   - Worker App: package `com.vrisharopan.worker`
   - Download each `google-services.json` and place in respective `android/app/` folders

### 1c. Google Maps
1. Go to https://console.cloud.google.com
2. Enable: **Maps SDK for Android**, **Geocoding API**, **Maps JavaScript API**
3. Create API key with restriction to your Android apps + server IPs
4. Note the key

### 1d. AWS S3
1. Create an S3 bucket (e.g., `vrisharopan-assets`)
2. Set bucket policy to allow public read on `trees/` and `profiles/` prefixes (or use CloudFront)
3. Create an IAM user with `AmazonS3FullAccess` on that bucket only
4. Generate access key + secret

---

## Step 2: Environment Configuration

### Backend `.env`
```bash
cp backend/.env.example backend/.env
```

Fill in all values:
```env
NODE_ENV=production
PORT=5000

# Database
DB_HOST=postgres        # Use 'localhost' for local dev
DB_PORT=5432
DB_NAME=vrisharopan_db
DB_USER=vrisharopan
DB_PASSWORD=your_secure_password_here
DB_SSL=false            # Set true for production cloud DB

# JWT (generate with: node -e "console.log(require('crypto').randomBytes(64).toString('hex'))")
JWT_SECRET=your_64_char_hex_secret
JWT_REFRESH_SECRET=another_64_char_hex_secret
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d

# AWS S3
AWS_REGION=ap-south-1
AWS_ACCESS_KEY_ID=AKIAxxxxxxxxxxxxx
AWS_SECRET_ACCESS_KEY=your_aws_secret
AWS_S3_BUCKET=vrisharopan-assets

# Razorpay
RAZORPAY_KEY_ID=rzp_live_xxxxxxxxxxxxxxxx
RAZORPAY_KEY_SECRET=your_razorpay_secret
RAZORPAY_WEBHOOK_SECRET=your_webhook_secret
RAZORPAY_PLAN_ID=plan_xxxxxxxxxxxxxxxxxx

# Firebase (from service account JSON)
FIREBASE_PROJECT_ID=vrisharopan
FIREBASE_CLIENT_EMAIL=firebase-adminsdk@vrisharopan.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----\n...\n-----END RSA PRIVATE KEY-----\n"

# Email (SMTP)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=noreply@vrisharopan.in
SMTP_PASS=your_app_password

# Pricing
TREE_PRICE_MONTHLY=99
WORKER_EARNING_PER_TREE=20
PLATFORM_FEE_PER_TREE=79

# CORS
ALLOWED_ORIGINS=https://vrisharopan.in,https://admin.vrisharopan.in

GOOGLE_MAPS_API_KEY=AIzaSy_your_key
```

### Website `.env`
```bash
cp website/.env.example website/.env
```
```env
NEXT_PUBLIC_API_URL=https://api.vrisharopan.in
NEXT_PUBLIC_RAZORPAY_KEY_ID=rzp_live_xxxxxxxxxxxxxxxx
NEXT_PUBLIC_GOOGLE_MAPS_API_KEY=AIzaSy_your_key
NEXT_PUBLIC_SITE_URL=https://vrisharopan.in
```

### Flutter Apps
Edit `customer-app/lib/core/constants/env.dart` and `worker-app/lib/core/constants/env.dart`:
```dart
const kBaseUrl = 'https://api.vrisharopan.in/api';
const kRazorpayKeyId = 'rzp_live_xxxxxxxxxxxxxxxx';
const kGoogleMapsApiKey = 'AIzaSy_your_key';
```

---

## Step 3: Database Setup

### Option A: Docker (Recommended)
```bash
docker-compose up postgres -d
# Wait for health check to pass
docker-compose exec backend npm run migrate
```

### Option B: Manual Local
```bash
createdb vrisharopan_db
psql vrisharopan_db -c "CREATE EXTENSION postgis;"
cd backend
npm run migrate
```

### Create Admin User
```bash
cd backend
node -e "
const bcrypt = require('bcryptjs');
const hash = bcrypt.hashSync('Admin@123!', 10);
console.log('INSERT INTO admin_users (email, password_hash, name, role) VALUES (\'admin@vrisharopan.in\', \'' + hash + '\', \'Super Admin\', \'super_admin\');');
"
# Run the output SQL in psql
psql vrisharopan_db
```

---

## Step 4: Local Development

### Backend
```bash
cd backend
npm install
npm run dev        # Starts on port 5000 with nodemon
```

### Admin Panel
```bash
cd admin-panel
npm install
npm run dev        # Starts on port 3001, proxies /api → localhost:5000
```

### Website
```bash
cd website
npm install
npm run dev        # Starts on port 3000, proxies /api → localhost:5000
```

### Customer Flutter App
```bash
cd customer-app
flutter pub get
# For Android emulator: ensure GOOGLE_MAPS_API_KEY in local.properties
flutter run
```

### Worker Flutter App
```bash
cd worker-app
flutter pub get
flutter run
```

---

## Step 5: Production Deployment (Docker)

### Server Requirements
- Ubuntu 22.04 LTS
- 2+ CPU cores, 4GB+ RAM
- Open ports: 80, 443

### Initial Server Setup
```bash
# Install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo apt-get install docker-compose-plugin

# Clone repo
git clone https://github.com/youraccount/vrisharopan.git
cd vrisharopan
```

### SSL Certificates (Let's Encrypt)
```bash
# Install certbot
sudo apt install certbot

# Get certs (stop nginx first if running)
sudo certbot certonly --standalone \
  -d vrisharopan.in -d www.vrisharopan.in \
  -d api.vrisharopan.in -d admin.vrisharopan.in

# Certs are at /etc/letsencrypt/live/vrisharopan.in/
# Mount them into nginx container (already configured in docker-compose.yml)
```

### Build & Start
```bash
# Copy env files
cp backend/.env.example backend/.env    # Fill in values
cp website/.env.example website/.env    # Fill in values

# Build & start all services
docker-compose build
docker-compose up -d

# Run migrations
docker-compose exec backend npm run migrate

# View logs
docker-compose logs -f backend
docker-compose logs -f nginx
```

### SSL Auto-Renewal
```bash
# Add to crontab
sudo crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet && docker-compose -f /path/to/docker-compose.yml exec nginx nginx -s reload
```

---

## Step 6: Flutter App Build & Release

### Android Release Build
```bash
# Customer App
cd customer-app
flutter build apk --release
# APK at: build/app/outputs/flutter-apk/app-release.apk

# Worker App
cd worker-app
flutter build apk --release
```

### Google Play Signing
```bash
# Generate keystore
keytool -genkey -v -keystore vrisharopan-release.keystore \
  -alias vrisharopan -keyalg RSA -keysize 2048 -validity 10000

# Add to android/key.properties:
# storePassword=<password>
# keyPassword=<password>
# keyAlias=vrisharopan
# storeFile=../vrisharopan-release.keystore

# Build signed AAB for Play Store
flutter build appbundle --release
```

---

## API Endpoints Reference

### Authentication
| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/auth/register` | Customer registration |
| POST | `/api/auth/login` | Login (customer/worker) |
| POST | `/api/auth/admin/login` | Admin login |
| POST | `/api/auth/refresh` | Refresh tokens |
| POST | `/api/auth/logout` | Logout |

### Customers
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/customers/dashboard` | Dashboard stats |
| PUT | `/api/customers/profile` | Update profile |
| GET | `/api/customers/referrals` | Referral stats |

### Trees
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/trees` | List trees |
| GET | `/api/trees/map` | Geo-tagged trees for map |
| POST | `/api/trees/:id/geo-tag` | GPS tag a tree |
| POST | `/api/trees/:id/photos` | Upload photo |
| POST | `/api/trees/:id/maintenance` | Log maintenance |
| POST | `/api/trees/gift` | Gift a tree |

### Workers
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/workers/dashboard` | Worker dashboard |
| GET | `/api/workers/orders` | My orders |
| PUT | `/api/workers/orders/:id/status` | Update order status |
| GET | `/api/workers/earnings` | Earnings |
| POST | `/api/workers/attendance/check-in` | GPS check-in |
| POST | `/api/workers/attendance/check-out` | GPS check-out |
| POST | `/api/workers/sync` | Sync offline logs |

### Payments
| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/payments/create-subscription` | Create Razorpay subscription |
| POST | `/api/payments/webhook` | Razorpay webhook (raw body) |
| GET | `/api/payments` | Payment history |

---

## Monitoring & Maintenance

### Health Check
```bash
curl https://api.vrisharopan.in/health
```

### Database Backup
```bash
docker-compose exec postgres pg_dump -U vrisharopan vrisharopan_db > backup_$(date +%Y%m%d).sql
```

### View Logs
```bash
docker-compose logs --tail=100 -f backend
```

### Restart a Service
```bash
docker-compose restart backend
```

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| PostGIS not found | Ensure using `postgis/postgis` image |
| FCM not working | Check `FIREBASE_PRIVATE_KEY` has newlines as `\n` in .env |
| Razorpay webhook 400 | Ensure webhook route uses `express.raw()` before JSON parser |
| Maps not loading in app | Check `GOOGLE_MAPS_API_KEY` in Android manifest meta-data |
| S3 upload 403 | Check IAM policy and bucket CORS settings |
| Flutter 401 after 15min | Dio interceptor auto-refreshes; check refresh token in Hive |
