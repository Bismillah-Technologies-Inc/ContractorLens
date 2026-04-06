BEGIN;

-- Subscriptions
CREATE INDEX IF NOT EXISTS idx_subscriptions_user ON contractorlens.Subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_stripe_sub ON contractorlens.Subscriptions(stripe_subscription_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_stripe_cust ON contractorlens.Subscriptions(stripe_customer_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON contractorlens.Subscriptions(status);

-- Estimates
CREATE INDEX IF NOT EXISTS idx_estimates_status ON contractorlens.estimates(status);
CREATE INDEX IF NOT EXISTS idx_estimates_user_status ON contractorlens.estimates(user_id, status);
CREATE INDEX IF NOT EXISTS idx_estimates_project ON contractorlens.estimates(project_id);

-- Chat
CREATE INDEX IF NOT EXISTS idx_chat_sessions_estimate ON contractorlens.ChatSessions(estimate_id);
CREATE INDEX IF NOT EXISTS idx_chat_sessions_user ON contractorlens.ChatSessions(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_session ON contractorlens.chat_messages(session_id);

-- Clients / Proposals
CREATE INDEX IF NOT EXISTS idx_clients_contractor ON contractorlens.clients(contractor_user_id);
CREATE INDEX IF NOT EXISTS idx_proposals_estimate ON contractorlens.proposals(estimate_id);
CREATE INDEX IF NOT EXISTS idx_proposals_token ON contractorlens.proposals(access_token);
CREATE INDEX IF NOT EXISTS idx_proposals_status ON contractorlens.proposals(status);

-- Invoices
CREATE INDEX IF NOT EXISTS idx_invoices_estimate ON contractorlens.invoices(estimate_id);
CREATE INDEX IF NOT EXISTS idx_invoices_user ON contractorlens.invoices(user_id);

-- Change Orders
CREATE INDEX IF NOT EXISTS idx_change_orders_estimate ON contractorlens.change_orders(estimate_id);

-- Estimate Status History
CREATE INDEX IF NOT EXISTS idx_estimate_history_estimate ON contractorlens.EstimateStatusHistory(estimate_id);

-- PostgreSQL Functions:

-- get_localized_item_cost(item_id, zip_code)
CREATE OR REPLACE FUNCTION contractorlens.get_localized_item_cost(
    p_item_id UUID,
    p_zip_code VARCHAR(10)
) RETURNS DECIMAL(10,2) AS $$
DECLARE
    v_retail_price DECIMAL(10,2);
    v_national_cost DECIMAL(10,2);
    v_material_modifier DECIMAL(5,3);
BEGIN
    -- Priority 1: fresh retail price
    SELECT rp.retail_price INTO v_retail_price
    FROM contractorlens.RetailPrices rp
    WHERE rp.item_id = p_item_id
      AND rp.last_scraped > NOW() - INTERVAL '7 days'
    ORDER BY rp.last_scraped DESC
    LIMIT 1;
    
    IF v_retail_price IS NOT NULL THEN
        RETURN v_retail_price;
    END IF;
    
    -- Priority 2: national avg × location modifier
    SELECT i.national_average_cost, COALESCE(lcm.material_modifier, 1.0)
    INTO v_national_cost, v_material_modifier
    FROM contractorlens.Items i
    LEFT JOIN contractorlens.LocationCostModifiers lcm ON (
        p_zip_code >= SPLIT_PART(lcm.zip_code_range, '-', 1) AND
        p_zip_code <= SPLIT_PART(lcm.zip_code_range, '-', 2)
    )
    WHERE i.item_id = p_item_id
    LIMIT 1;
    
    IF v_national_cost IS NOT NULL THEN
        RETURN ROUND(v_national_cost * COALESCE(v_material_modifier, 1.0), 2);
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- calculate_estimate_totals(estimate_id)
CREATE OR REPLACE FUNCTION contractorlens.calculate_estimate_totals(
    p_estimate_id UUID
) RETURNS TABLE(subtotal DECIMAL, markup DECIMAL, tax DECIMAL, grand_total DECIMAL) AS $$
BEGIN
    -- Sums all line item total_cost values from JSONB, applies markup and tax from metadata
    RETURN QUERY
    SELECT
        SUM((item->>'total_cost')::DECIMAL) AS subtotal,
        SUM((item->>'total_cost')::DECIMAL) * 0.25 AS markup,  -- default 25%
        SUM((item->>'total_cost')::DECIMAL) * 1.25 * 0.08 AS tax,  -- default 8%
        SUM((item->>'total_cost')::DECIMAL) * 1.25 * 1.08 AS grand_total
    FROM contractorlens.estimates e,
         LATERAL jsonb_array_elements(e.line_items) AS item
    WHERE e.estimate_id = p_estimate_id;
END;
$$ LANGUAGE plpgsql;

COMMIT;
