-- Migration: V3 - Add User, Subscription, and Supporting Tables
-- Objective: Establish users, subscriptions, estimate audit trail, chat, clients,
--            invoices, change orders, schedules, pricing overrides, proposals, signatures.
-- Created: 2026-04-05

BEGIN;

-- ============================================================
-- Users (Firebase UID as VARCHAR to avoid UUID format issues)
-- ============================================================
CREATE TABLE contractorlens.Users (
    user_id VARCHAR(255) PRIMARY KEY,  -- Firebase UID (not a proper UUID)
    email VARCHAR(255) UNIQUE NOT NULL,
    display_name VARCHAR(100),
    company_name VARCHAR(200),
    default_quality_tier VARCHAR(20) DEFAULT 'better',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- Subscriptions
-- ============================================================
CREATE TABLE contractorlens.Subscriptions (
    subscription_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(255) NOT NULL,
    stripe_customer_id VARCHAR(100),
    stripe_subscription_id VARCHAR(100) UNIQUE,
    plan_tier VARCHAR(20) CHECK (plan_tier IN ('starter','pro','pro_plus','enterprise')),
    status VARCHAR(20) DEFAULT 'trialing' CHECK (status IN ('trialing','active','past_due','canceled','unpaid')),
    trial_end TIMESTAMP,
    current_period_start TIMESTAMP,
    current_period_end TIMESTAMP,
    cancel_at_period_end BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- EstimateStatusHistory
-- ============================================================
CREATE TABLE contractorlens.EstimateStatusHistory (
    history_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    estimate_id UUID REFERENCES contractorlens.estimates(estimate_id) ON DELETE CASCADE,
    from_status VARCHAR(20),
    to_status VARCHAR(20) NOT NULL,
    changed_by VARCHAR(255),  -- Firebase UID
    changed_at TIMESTAMP DEFAULT NOW(),
    notes TEXT
);

-- ============================================================
-- ChatSessions
-- ============================================================
CREATE TABLE contractorlens.ChatSessions (
    session_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    estimate_id UUID REFERENCES contractorlens.estimates(estimate_id) ON DELETE CASCADE,
    user_id VARCHAR(255) NOT NULL,
    messages JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- clients (must exist before invoices and proposals reference it)
-- ============================================================
CREATE TABLE contractorlens.clients (
    client_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contractor_user_id VARCHAR(255) NOT NULL,
    name VARCHAR(200) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(20),
    address TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- invoices
-- ============================================================
CREATE TABLE contractorlens.invoices (
    invoice_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    estimate_id UUID REFERENCES contractorlens.estimates(estimate_id),
    client_id UUID REFERENCES contractorlens.clients(client_id),
    user_id VARCHAR(255) NOT NULL,
    invoice_number VARCHAR(50),
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft','sent','paid','overdue','void')),
    amount_due DECIMAL(12,2),
    amount_paid DECIMAL(12,2) DEFAULT 0,
    due_date DATE,
    paid_at TIMESTAMP,
    stripe_invoice_id VARCHAR(100),
    line_items JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- change_orders
-- ============================================================
CREATE TABLE contractorlens.change_orders (
    change_order_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    estimate_id UUID REFERENCES contractorlens.estimates(estimate_id),
    user_id VARCHAR(255) NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending','approved','rejected')),
    amount DECIMAL(12,2),
    line_items JSONB,
    approved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- schedule_entries
-- ============================================================
CREATE TABLE contractorlens.schedule_entries (
    entry_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID REFERENCES contractorlens.Projects(project_id),
    user_id VARCHAR(255) NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    start_date DATE,
    end_date DATE,
    status VARCHAR(20) DEFAULT 'scheduled' CHECK (status IN ('scheduled','in_progress','completed','delayed')),
    trade_id UUID REFERENCES contractorlens.Trades(trade_id),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- pricing_overrides
-- ============================================================
CREATE TABLE contractorlens.pricing_overrides (
    override_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(255) NOT NULL,
    item_id UUID REFERENCES contractorlens.Items(item_id),
    override_cost DECIMAL(10,2) NOT NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- proposals (must exist before signatures reference it)
-- ============================================================
CREATE TABLE contractorlens.proposals (
    proposal_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    estimate_id UUID REFERENCES contractorlens.estimates(estimate_id),
    client_id UUID REFERENCES contractorlens.clients(client_id),
    user_id VARCHAR(255) NOT NULL,
    access_token VARCHAR(100) UNIQUE DEFAULT encode(gen_random_bytes(32), 'hex'),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending','viewed','accepted','declined','expired')),
    sent_at TIMESTAMP,
    viewed_at TIMESTAMP,
    responded_at TIMESTAMP,
    expires_at TIMESTAMP,
    terms TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- signatures
-- ============================================================
CREATE TABLE contractorlens.signatures (
    signature_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    proposal_id UUID REFERENCES contractorlens.proposals(proposal_id),
    signer_name VARCHAR(200) NOT NULL,
    signer_email VARCHAR(255),
    signature_data TEXT NOT NULL,  -- base64 SVG/PNG of drawn signature
    ip_address VARCHAR(45),
    signed_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- chat_messages
-- ============================================================
CREATE TABLE contractorlens.chat_messages (
    message_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID REFERENCES contractorlens.ChatSessions(session_id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL CHECK (role IN ('user','assistant','system')),
    content TEXT NOT NULL,
    metadata JSONB,  -- {updatedEstimate, modifications, confidence}
    created_at TIMESTAMP DEFAULT NOW()
);

COMMIT;
