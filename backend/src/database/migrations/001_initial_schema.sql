-- ============================================================
-- Vrisharopan Plant Trees Project - Complete Database Schema
-- PostgreSQL 15+
-- ============================================================

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";     -- for geo queries (install postgis)
CREATE EXTENSION IF NOT EXISTS "pg_trgm";     -- for text search

-- ──────────────────────────────────────────────────────────────
-- ENUM TYPES
-- ──────────────────────────────────────────────────────────────

CREATE TYPE user_role         AS ENUM ('customer', 'worker', 'admin', 'superadmin');
CREATE TYPE user_status       AS ENUM ('active', 'inactive', 'suspended', 'pending_verification');
CREATE TYPE tree_health       AS ENUM ('healthy', 'needs_water', 'needs_fertilizer', 'damaged', 'dead', 'unknown');
CREATE TYPE tree_status       AS ENUM ('pending_assignment', 'assigned', 'planted', 'active', 'inactive', 'dead');
CREATE TYPE subscription_status AS ENUM ('active', 'paused', 'cancelled', 'expired', 'pending');
CREATE TYPE payment_status    AS ENUM ('pending', 'captured', 'failed', 'refunded', 'partially_refunded');
CREATE TYPE payment_type      AS ENUM ('subscription', 'one_time', 'refund');
CREATE TYPE order_status      AS ENUM ('pending', 'accepted', 'rejected', 'in_progress', 'completed', 'cancelled');
CREATE TYPE notification_type AS ENUM ('tree_planted', 'tree_updated', 'payment_success', 'payment_failed', 'subscription_renewal', 'new_order', 'payment_credited', 'maintenance_reminder', 'broadcast', 'gift_tree', 'referral_reward');
CREATE TYPE photo_status      AS ENUM ('pending_review', 'approved', 'rejected');
CREATE TYPE worker_status     AS ENUM ('pending_approval', 'active', 'inactive', 'suspended');
CREATE TYPE gift_status       AS ENUM ('pending', 'accepted', 'declined');

-- ──────────────────────────────────────────────────────────────
-- TABLE: admin_users
-- ──────────────────────────────────────────────────────────────

CREATE TABLE admin_users (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name            VARCHAR(150) NOT NULL,
    email           VARCHAR(255) NOT NULL UNIQUE,
    password_hash   TEXT NOT NULL,
    role            user_role NOT NULL DEFAULT 'admin',
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    last_login_at   TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_admin_users_email ON admin_users(email);

-- ──────────────────────────────────────────────────────────────
-- TABLE: users (customers + workers share this base table)
-- ──────────────────────────────────────────────────────────────

CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name            VARCHAR(150) NOT NULL,
    email           VARCHAR(255) NOT NULL UNIQUE,
    password_hash   TEXT NOT NULL,
    mobile          VARCHAR(15),
    role            user_role NOT NULL DEFAULT 'customer',
    status          user_status NOT NULL DEFAULT 'active',
    fcm_token       TEXT,
    referral_code   VARCHAR(20) UNIQUE,
    referred_by_id  UUID REFERENCES users(id) ON DELETE SET NULL,
    avatar_url      TEXT,
    email_verified  BOOLEAN NOT NULL DEFAULT FALSE,
    last_login_at   TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_email       ON users(email);
CREATE INDEX idx_users_mobile      ON users(mobile);
CREATE INDEX idx_users_role        ON users(role);
CREATE INDEX idx_users_referral    ON users(referral_code);

-- ──────────────────────────────────────────────────────────────
-- TABLE: customer_profiles
-- ──────────────────────────────────────────────────────────────

CREATE TABLE customer_profiles (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    address         TEXT,
    city            VARCHAR(100),
    state           VARCHAR(100),
    pin_code        VARCHAR(10),
    razorpay_customer_id VARCHAR(100),
    total_trees     INT NOT NULL DEFAULT 0,
    active_trees    INT NOT NULL DEFAULT 0,
    gifted_trees    INT NOT NULL DEFAULT 0,
    adopted_trees   INT NOT NULL DEFAULT 0,
    referral_trees  INT NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_customer_profiles_user ON customer_profiles(user_id);
CREATE INDEX idx_customer_profiles_pin  ON customer_profiles(pin_code);

-- ──────────────────────────────────────────────────────────────
-- TABLE: worker_profiles
-- ──────────────────────────────────────────────────────────────

CREATE TABLE worker_profiles (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id             UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    address             TEXT,
    city                VARCHAR(100),
    state               VARCHAR(100),
    pin_code            VARCHAR(10),
    worker_status       worker_status NOT NULL DEFAULT 'pending_approval',
    service_area        TEXT[],           -- array of pin codes they serve
    bank_account_name   VARCHAR(150),
    bank_account_number VARCHAR(30),
    bank_ifsc           VARCHAR(15),
    bank_upi_id         VARCHAR(100),
    total_trees_planted INT NOT NULL DEFAULT 0,
    active_trees        INT NOT NULL DEFAULT 0,
    rating              NUMERIC(3,2) NOT NULL DEFAULT 5.00,
    total_earnings      NUMERIC(12,2) NOT NULL DEFAULT 0,
    pending_earnings    NUMERIC(12,2) NOT NULL DEFAULT 0,
    verified_at         TIMESTAMPTZ,
    approved_by_id      UUID REFERENCES admin_users(id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_worker_profiles_user   ON worker_profiles(user_id);
CREATE INDEX idx_worker_profiles_status ON worker_profiles(worker_status);

-- ──────────────────────────────────────────────────────────────
-- TABLE: subscriptions
-- ──────────────────────────────────────────────────────────────

CREATE TABLE subscriptions (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id             UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    razorpay_subscription_id VARCHAR(100) UNIQUE,
    razorpay_plan_id        VARCHAR(100),
    tree_count              INT NOT NULL DEFAULT 1,
    amount_per_cycle        NUMERIC(10,2) NOT NULL,
    status                  subscription_status NOT NULL DEFAULT 'pending',
    current_start           TIMESTAMPTZ,
    current_end             TIMESTAMPTZ,
    charge_at               TIMESTAMPTZ,
    total_count             INT NOT NULL DEFAULT 0,
    paid_count              INT NOT NULL DEFAULT 0,
    auto_renew              BOOLEAN NOT NULL DEFAULT TRUE,
    cancelled_at            TIMESTAMPTZ,
    notes                   JSONB,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_subscriptions_customer ON subscriptions(customer_id);
CREATE INDEX idx_subscriptions_status   ON subscriptions(status);
CREATE INDEX idx_subscriptions_razorpay ON subscriptions(razorpay_subscription_id);

-- ──────────────────────────────────────────────────────────────
-- TABLE: payments
-- ──────────────────────────────────────────────────────────────

CREATE TABLE payments (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id                 UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    subscription_id         UUID REFERENCES subscriptions(id) ON DELETE SET NULL,
    razorpay_payment_id     VARCHAR(100) UNIQUE,
    razorpay_order_id       VARCHAR(100),
    razorpay_signature      TEXT,
    amount                  NUMERIC(10,2) NOT NULL,
    currency                VARCHAR(5) NOT NULL DEFAULT 'INR',
    payment_type            payment_type NOT NULL DEFAULT 'subscription',
    status                  payment_status NOT NULL DEFAULT 'pending',
    method                  VARCHAR(50),   -- card, upi, netbanking, etc.
    description             TEXT,
    captured_at             TIMESTAMPTZ,
    refunded_at             TIMESTAMPTZ,
    refund_id               VARCHAR(100),
    metadata                JSONB,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_payments_user         ON payments(user_id);
CREATE INDEX idx_payments_subscription ON payments(subscription_id);
CREATE INDEX idx_payments_razorpay     ON payments(razorpay_payment_id);
CREATE INDEX idx_payments_status       ON payments(status);
CREATE INDEX idx_payments_created      ON payments(created_at DESC);

-- ──────────────────────────────────────────────────────────────
-- TABLE: trees
-- ──────────────────────────────────────────────────────────────

CREATE TABLE trees (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tree_number     VARCHAR(30) UNIQUE NOT NULL,  -- human-readable e.g. VR-2024-000001
    customer_id     UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    worker_id       UUID REFERENCES users(id) ON DELETE SET NULL,
    subscription_id UUID REFERENCES subscriptions(id) ON DELETE SET NULL,
    species         VARCHAR(150),
    common_name     VARCHAR(150),
    status          tree_status NOT NULL DEFAULT 'pending_assignment',
    health          tree_health NOT NULL DEFAULT 'unknown',
    planted_at      TIMESTAMPTZ,
    latitude        NUMERIC(10,8),
    longitude       NUMERIC(11,8),
    geo_point       GEOGRAPHY(POINT, 4326),       -- PostGIS point
    address_hint    TEXT,
    cover_photo_url TEXT,
    is_gift         BOOLEAN NOT NULL DEFAULT FALSE,
    gift_from_id    UUID REFERENCES users(id) ON DELETE SET NULL,
    gift_message    TEXT,
    is_adopted      BOOLEAN NOT NULL DEFAULT FALSE,
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_trees_customer    ON trees(customer_id);
CREATE INDEX idx_trees_worker      ON trees(worker_id);
CREATE INDEX idx_trees_status      ON trees(status);
CREATE INDEX idx_trees_health      ON trees(health);
CREATE INDEX idx_trees_geo         ON trees USING GIST(geo_point);
CREATE INDEX idx_trees_number      ON trees(tree_number);
CREATE INDEX idx_trees_planted     ON trees(planted_at);

-- ──────────────────────────────────────────────────────────────
-- TABLE: tree_maintenance_logs
-- ──────────────────────────────────────────────────────────────

CREATE TABLE tree_maintenance_logs (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tree_id     UUID NOT NULL REFERENCES trees(id) ON DELETE CASCADE,
    worker_id   UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    action      VARCHAR(100) NOT NULL,   -- watered, fertilized, pruned, inspected, planted
    health      tree_health,
    notes       TEXT,
    latitude    NUMERIC(10,8),
    longitude   NUMERIC(11,8),
    logged_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_maintenance_tree   ON tree_maintenance_logs(tree_id);
CREATE INDEX idx_maintenance_worker ON tree_maintenance_logs(worker_id);
CREATE INDEX idx_maintenance_logged ON tree_maintenance_logs(logged_at DESC);

-- ──────────────────────────────────────────────────────────────
-- TABLE: tree_photos
-- ──────────────────────────────────────────────────────────────

CREATE TABLE tree_photos (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tree_id     UUID NOT NULL REFERENCES trees(id) ON DELETE CASCADE,
    worker_id   UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    photo_url   TEXT NOT NULL,
    thumbnail_url TEXT,
    caption     TEXT,
    latitude    NUMERIC(10,8),
    longitude   NUMERIC(11,8),
    status      photo_status NOT NULL DEFAULT 'pending_review',
    reviewed_by UUID REFERENCES admin_users(id),
    reviewed_at TIMESTAMPTZ,
    taken_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_photos_tree    ON tree_photos(tree_id);
CREATE INDEX idx_photos_worker  ON tree_photos(worker_id);
CREATE INDEX idx_photos_status  ON tree_photos(status);

-- ──────────────────────────────────────────────────────────────
-- TABLE: worker_orders
-- ──────────────────────────────────────────────────────────────

CREATE TABLE worker_orders (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tree_id         UUID NOT NULL REFERENCES trees(id) ON DELETE CASCADE,
    worker_id       UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    order_type      VARCHAR(50) NOT NULL DEFAULT 'plant',  -- plant, maintain, inspect
    status          order_status NOT NULL DEFAULT 'pending',
    assigned_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    accepted_at     TIMESTAMPTZ,
    completed_at    TIMESTAMPTZ,
    rejected_at     TIMESTAMPTZ,
    rejection_reason TEXT,
    deadline        TIMESTAMPTZ,
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_orders_worker ON worker_orders(worker_id);
CREATE INDEX idx_orders_tree   ON worker_orders(tree_id);
CREATE INDEX idx_orders_status ON worker_orders(status);

-- ──────────────────────────────────────────────────────────────
-- TABLE: worker_earnings
-- ──────────────────────────────────────────────────────────────

CREATE TABLE worker_earnings (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    worker_id       UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    tree_id         UUID REFERENCES trees(id) ON DELETE SET NULL,
    payment_id      UUID REFERENCES payments(id) ON DELETE SET NULL,
    amount          NUMERIC(10,2) NOT NULL,
    earning_type    VARCHAR(50) NOT NULL DEFAULT 'monthly_maintenance',
    period_start    DATE,
    period_end      DATE,
    is_paid         BOOLEAN NOT NULL DEFAULT FALSE,
    paid_at         TIMESTAMPTZ,
    payout_ref      VARCHAR(100),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_earnings_worker  ON worker_earnings(worker_id);
CREATE INDEX idx_earnings_is_paid ON worker_earnings(is_paid);

-- ──────────────────────────────────────────────────────────────
-- TABLE: worker_attendance
-- ──────────────────────────────────────────────────────────────

CREATE TABLE worker_attendance (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    worker_id   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    check_in_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    check_out_at TIMESTAMPTZ,
    latitude    NUMERIC(10,8),
    longitude   NUMERIC(11,8),
    date        DATE NOT NULL DEFAULT CURRENT_DATE
);

CREATE INDEX idx_attendance_worker ON worker_attendance(worker_id);
CREATE INDEX idx_attendance_date   ON worker_attendance(date);
CREATE UNIQUE INDEX idx_attendance_worker_date ON worker_attendance(worker_id, date);

-- ──────────────────────────────────────────────────────────────
-- TABLE: referrals
-- ──────────────────────────────────────────────────────────────

CREATE TABLE referrals (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    referrer_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    referred_id     UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    reward_granted  BOOLEAN NOT NULL DEFAULT FALSE,
    reward_tree_id  UUID REFERENCES trees(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_referrals_referrer ON referrals(referrer_id);

-- ──────────────────────────────────────────────────────────────
-- TABLE: gifts
-- ──────────────────────────────────────────────────────────────

CREATE TABLE gifts (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    from_user_id    UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    to_user_id      UUID REFERENCES users(id) ON DELETE SET NULL,
    to_email        VARCHAR(255),
    to_name         VARCHAR(150),
    tree_id         UUID NOT NULL REFERENCES trees(id) ON DELETE RESTRICT,
    message         TEXT,
    status          gift_status NOT NULL DEFAULT 'pending',
    accepted_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_gifts_from  ON gifts(from_user_id);
CREATE INDEX idx_gifts_to    ON gifts(to_user_id);
CREATE INDEX idx_gifts_tree  ON gifts(tree_id);

-- ──────────────────────────────────────────────────────────────
-- TABLE: notifications
-- ──────────────────────────────────────────────────────────────

CREATE TABLE notifications (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID REFERENCES users(id) ON DELETE CASCADE,    -- NULL = broadcast
    title       VARCHAR(255) NOT NULL,
    body        TEXT NOT NULL,
    type        notification_type NOT NULL,
    data        JSONB,
    is_read     BOOLEAN NOT NULL DEFAULT FALSE,
    sent_at     TIMESTAMPTZ,
    read_at     TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_user    ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_created ON notifications(created_at DESC);

-- ──────────────────────────────────────────────────────────────
-- TABLE: refresh_tokens
-- ──────────────────────────────────────────────────────────────

CREATE TABLE refresh_tokens (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash  TEXT NOT NULL,
    expires_at  TIMESTAMPTZ NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    revoked_at  TIMESTAMPTZ
);

CREATE INDEX idx_refresh_tokens_user    ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_hash    ON refresh_tokens(token_hash);

-- ──────────────────────────────────────────────────────────────
-- FUNCTION: update_updated_at trigger
-- ──────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach trigger to all tables that have updated_at
DO $$
DECLARE
    t TEXT;
BEGIN
    FOR t IN SELECT unnest(ARRAY[
        'admin_users','users','customer_profiles','worker_profiles',
        'subscriptions','payments','trees','worker_orders'
    ])
    LOOP
        EXECUTE format('
            CREATE TRIGGER trg_set_updated_at
            BEFORE UPDATE ON %I
            FOR EACH ROW EXECUTE FUNCTION set_updated_at()', t);
    END LOOP;
END;
$$;

-- ──────────────────────────────────────────────────────────────
-- FUNCTION: auto-generate tree_number
-- ──────────────────────────────────────────────────────────────

CREATE SEQUENCE tree_seq START 1;

CREATE OR REPLACE FUNCTION generate_tree_number()
RETURNS TRIGGER AS $$
BEGIN
    NEW.tree_number := 'VR-' || TO_CHAR(NOW(), 'YYYY') || '-' || LPAD(nextval('tree_seq')::TEXT, 6, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_generate_tree_number
    BEFORE INSERT ON trees
    FOR EACH ROW
    WHEN (NEW.tree_number IS NULL)
    EXECUTE FUNCTION generate_tree_number();

-- ──────────────────────────────────────────────────────────────
-- FUNCTION: auto-generate referral code for users
-- ──────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION generate_referral_code()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.referral_code IS NULL THEN
        NEW.referral_code := UPPER(SUBSTRING(MD5(NEW.id::TEXT || NOW()::TEXT) FROM 1 FOR 8));
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_generate_referral_code
    BEFORE INSERT ON users
    FOR EACH ROW
    EXECUTE FUNCTION generate_referral_code();

-- ──────────────────────────────────────────────────────────────
-- VIEW: active_subscriptions_summary
-- ──────────────────────────────────────────────────────────────

CREATE VIEW active_subscriptions_summary AS
SELECT
    s.id,
    s.customer_id,
    u.name AS customer_name,
    u.email AS customer_email,
    s.tree_count,
    s.amount_per_cycle,
    s.status,
    s.current_start,
    s.current_end,
    s.auto_renew
FROM subscriptions s
JOIN users u ON u.id = s.customer_id
WHERE s.status = 'active';

-- ──────────────────────────────────────────────────────────────
-- VIEW: tree_dashboard_view
-- ──────────────────────────────────────────────────────────────

CREATE VIEW tree_dashboard_view AS
SELECT
    t.id,
    t.tree_number,
    t.species,
    t.common_name,
    t.status,
    t.health,
    t.planted_at,
    t.latitude,
    t.longitude,
    t.cover_photo_url,
    t.is_gift,
    t.is_adopted,
    cu.name AS customer_name,
    cu.email AS customer_email,
    wu.name AS worker_name,
    wu.email AS worker_email
FROM trees t
LEFT JOIN users cu ON cu.id = t.customer_id
LEFT JOIN users wu ON wu.id = t.worker_id;

-- ──────────────────────────────────────────────────────────────
-- INITIAL DATA: default admin
-- ──────────────────────────────────────────────────────────────

INSERT INTO admin_users (name, email, password_hash, role)
VALUES (
    'Super Admin',
    'admin@vrisharopan.in',
    -- bcrypt hash for 'Change@Password123' - CHANGE IN PRODUCTION
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewYpfQN7q.0.L7NS',
    'superadmin'
);
