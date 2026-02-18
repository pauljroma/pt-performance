-- ============================================================================
-- Revenue Analytics RPC Functions
-- ACP-976: Revenue Analytics for MRR/ARR tracking, LTV, churn analysis
-- ============================================================================
-- Provides server-side aggregation for revenue metrics across both
-- user_subscriptions (App Store) and user_pack_subscriptions (premium packs).
--
-- Functions:
--   get_revenue_metrics(period_days INT) - MRR, ARR, active subs, churn rate
--   get_revenue_by_cohort(cohort_month TEXT) - Revenue breakdown by signup month
--   get_ltv_by_tier() - Estimated lifetime value per subscription tier
-- ============================================================================

-- ============================================================================
-- 1. get_revenue_metrics
-- ============================================================================
-- Returns core revenue KPIs for a given lookback period.
-- Combines App Store subscriptions with premium pack subscriptions.
-- ============================================================================

CREATE OR REPLACE FUNCTION get_revenue_metrics(period_days INT DEFAULT 30)
RETURNS JSON AS $$
DECLARE
    result JSON;
    v_period_start TIMESTAMPTZ;
    v_previous_period_start TIMESTAMPTZ;
    v_now TIMESTAMPTZ := NOW();

    -- App Store subscription metrics
    v_app_store_active INT;
    v_app_store_mrr NUMERIC(12,2);

    -- Pack subscription metrics
    v_pack_active INT;
    v_pack_mrr NUMERIC(12,2);
    v_pack_trial INT;

    -- Churn metrics
    v_churned_current INT;
    v_active_previous INT;
    v_churn_rate NUMERIC(5,2);

    -- Expansion revenue (upgrades in current period)
    v_expansion_revenue NUMERIC(12,2);

    -- Revenue by tier
    v_revenue_by_tier JSON;

    -- Active subscriber count by tier
    v_subscribers_by_tier JSON;
BEGIN
    v_period_start := v_now - (period_days || ' days')::INTERVAL;
    v_previous_period_start := v_period_start - (period_days || ' days')::INTERVAL;

    -- ========================================================================
    -- Active App Store subscriptions (status = 'active' and not expired)
    -- ========================================================================
    SELECT COUNT(*)
    INTO v_app_store_active
    FROM user_subscriptions
    WHERE status = 'active'
      AND (expires_date IS NULL OR expires_date > v_now)
      AND is_trial = false;

    -- ========================================================================
    -- Active pack subscriptions and MRR from packs
    -- ========================================================================
    SELECT
        COUNT(*) FILTER (WHERE ups.status = 'active'),
        COALESCE(SUM(pp.base_price_monthly) FILTER (WHERE ups.status = 'active'), 0),
        COUNT(*) FILTER (WHERE ups.status = 'trial')
    INTO v_pack_active, v_pack_mrr, v_pack_trial
    FROM user_pack_subscriptions ups
    JOIN premium_packs pp ON pp.id = ups.pack_id
    WHERE ups.status IN ('active', 'trial')
      AND (ups.expires_at IS NULL OR ups.expires_at > v_now);

    -- ========================================================================
    -- Estimate App Store MRR
    -- We derive price from the product_id naming convention. Premium packs
    -- give us exact pricing; App Store subscriptions use product_id mapping.
    -- For simplicity, count each active App Store sub at BASE pack price.
    -- ========================================================================
    SELECT COALESCE(
        (SELECT base_price_monthly FROM premium_packs WHERE code = 'BASE' LIMIT 1),
        29.00
    ) * v_app_store_active
    INTO v_app_store_mrr;

    -- ========================================================================
    -- Churn rate: subscriptions that expired or cancelled in current period
    -- vs subscriptions that were active at the start of current period
    -- ========================================================================

    -- Count subs that churned during current period (pack subscriptions)
    SELECT COUNT(*)
    INTO v_churned_current
    FROM user_pack_subscriptions
    WHERE status IN ('cancelled', 'expired')
      AND (
          (cancelled_at IS NOT NULL AND cancelled_at >= v_period_start AND cancelled_at < v_now)
          OR (expires_at IS NOT NULL AND expires_at >= v_period_start AND expires_at < v_now AND status = 'expired')
      );

    -- Add App Store churn
    SELECT v_churned_current + COUNT(*)
    INTO v_churned_current
    FROM user_subscriptions
    WHERE status IN ('cancelled', 'expired')
      AND updated_at >= v_period_start
      AND updated_at < v_now;

    -- Count subs active at the start of the period (pack subscriptions)
    SELECT COUNT(*)
    INTO v_active_previous
    FROM user_pack_subscriptions
    WHERE started_at < v_period_start
      AND (expires_at IS NULL OR expires_at > v_period_start)
      AND (cancelled_at IS NULL OR cancelled_at > v_period_start);

    -- Add App Store subs active at period start
    SELECT v_active_previous + COUNT(*)
    INTO v_active_previous
    FROM user_subscriptions
    WHERE created_at < v_period_start
      AND (expires_date IS NULL OR expires_date > v_period_start)
      AND (status = 'active' OR updated_at > v_period_start);

    -- Calculate churn rate
    v_churn_rate := CASE
        WHEN v_active_previous > 0 THEN
            ROUND((v_churned_current::NUMERIC / v_active_previous) * 100, 2)
        ELSE 0
    END;

    -- ========================================================================
    -- Expansion revenue: new pack subscriptions added during the period
    -- by users who already had at least one active subscription before
    -- ========================================================================
    SELECT COALESCE(SUM(pp.base_price_monthly), 0)
    INTO v_expansion_revenue
    FROM user_pack_subscriptions ups
    JOIN premium_packs pp ON pp.id = ups.pack_id
    WHERE ups.started_at >= v_period_start
      AND ups.started_at < v_now
      AND ups.status IN ('active', 'trial')
      AND EXISTS (
          SELECT 1 FROM user_pack_subscriptions older
          WHERE older.user_id = ups.user_id
            AND older.id != ups.id
            AND older.started_at < v_period_start
      );

    -- ========================================================================
    -- Revenue by tier (pack code)
    -- ========================================================================
    SELECT json_agg(tier_row)
    INTO v_revenue_by_tier
    FROM (
        SELECT
            pp.code AS tier,
            pp.name AS tier_name,
            COUNT(*) AS active_subscribers,
            pp.base_price_monthly AS price_monthly,
            ROUND(COUNT(*) * pp.base_price_monthly, 2) AS monthly_revenue
        FROM user_pack_subscriptions ups
        JOIN premium_packs pp ON pp.id = ups.pack_id
        WHERE ups.status = 'active'
          AND (ups.expires_at IS NULL OR ups.expires_at > v_now)
        GROUP BY pp.code, pp.name, pp.base_price_monthly
        ORDER BY monthly_revenue DESC
    ) tier_row;

    -- ========================================================================
    -- Subscribers by tier
    -- ========================================================================
    SELECT json_agg(sub_row)
    INTO v_subscribers_by_tier
    FROM (
        SELECT
            pp.code AS tier,
            pp.name AS tier_name,
            COUNT(*) FILTER (WHERE ups.status = 'active') AS active,
            COUNT(*) FILTER (WHERE ups.status = 'trial') AS trial,
            COUNT(*) FILTER (WHERE ups.status = 'cancelled') AS cancelled
        FROM user_pack_subscriptions ups
        JOIN premium_packs pp ON pp.id = ups.pack_id
        GROUP BY pp.code, pp.name
        ORDER BY active DESC
    ) sub_row;

    -- ========================================================================
    -- Assemble result
    -- ========================================================================
    result := json_build_object(
        'period_days', period_days,
        'period_start', v_period_start,
        'period_end', v_now,
        'mrr', ROUND(v_app_store_mrr + v_pack_mrr, 2),
        'arr', ROUND((v_app_store_mrr + v_pack_mrr) * 12, 2),
        'mrr_breakdown', json_build_object(
            'app_store', v_app_store_mrr,
            'pack_subscriptions', v_pack_mrr
        ),
        'active_subscribers', json_build_object(
            'total', v_app_store_active + v_pack_active,
            'app_store', v_app_store_active,
            'pack_subscriptions', v_pack_active,
            'trials', v_pack_trial
        ),
        'churn', json_build_object(
            'rate_percent', v_churn_rate,
            'churned_in_period', v_churned_current,
            'active_at_period_start', v_active_previous
        ),
        'expansion_revenue', v_expansion_revenue,
        'revenue_by_tier', COALESCE(v_revenue_by_tier, '[]'::JSON),
        'subscribers_by_tier', COALESCE(v_subscribers_by_tier, '[]'::JSON)
    );

    RETURN result;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

COMMENT ON FUNCTION get_revenue_metrics IS 'ACP-976: Returns MRR, ARR, active subscriber counts, churn rate, and revenue by tier for a given lookback period';

-- ============================================================================
-- 2. get_revenue_by_cohort
-- ============================================================================
-- Groups subscribers by the month they first subscribed and returns
-- revenue contribution and retention metrics for each cohort.
-- If cohort_month is NULL, returns all cohorts.
-- ============================================================================

CREATE OR REPLACE FUNCTION get_revenue_by_cohort(cohort_month TEXT DEFAULT NULL)
RETURNS JSON AS $$
DECLARE
    result JSON;
    v_now TIMESTAMPTZ := NOW();
BEGIN
    SELECT json_agg(cohort_row ORDER BY cohort_row.cohort)
    INTO result
    FROM (
        SELECT
            TO_CHAR(ups.started_at, 'YYYY-MM') AS cohort,
            COUNT(DISTINCT ups.user_id) AS total_users,
            COUNT(DISTINCT ups.user_id) FILTER (
                WHERE ups.status = 'active'
                AND (ups.expires_at IS NULL OR ups.expires_at > v_now)
            ) AS retained_users,
            ROUND(
                COUNT(DISTINCT ups.user_id) FILTER (
                    WHERE ups.status = 'active'
                    AND (ups.expires_at IS NULL OR ups.expires_at > v_now)
                )::NUMERIC
                / NULLIF(COUNT(DISTINCT ups.user_id), 0) * 100,
                2
            ) AS retention_rate_percent,
            COUNT(*) AS total_subscriptions,
            COUNT(*) FILTER (WHERE ups.status = 'active') AS active_subscriptions,
            COUNT(*) FILTER (WHERE ups.status IN ('cancelled', 'expired')) AS churned_subscriptions,
            ROUND(
                COALESCE(SUM(pp.base_price_monthly) FILTER (
                    WHERE ups.status = 'active'
                    AND (ups.expires_at IS NULL OR ups.expires_at > v_now)
                ), 0),
                2
            ) AS current_mrr_contribution,
            -- Average months retained for this cohort
            ROUND(
                AVG(
                    EXTRACT(EPOCH FROM (
                        COALESCE(ups.cancelled_at, ups.expires_at, v_now) - ups.started_at
                    )) / (30.44 * 86400)
                ),
                1
            ) AS avg_months_retained,
            -- Revenue per user in this cohort (cumulative estimated)
            ROUND(
                AVG(
                    EXTRACT(EPOCH FROM (
                        COALESCE(ups.cancelled_at, ups.expires_at, v_now) - ups.started_at
                    )) / (30.44 * 86400)
                ) * AVG(pp.base_price_monthly),
                2
            ) AS avg_revenue_per_user
        FROM user_pack_subscriptions ups
        JOIN premium_packs pp ON pp.id = ups.pack_id
        WHERE (cohort_month IS NULL OR TO_CHAR(ups.started_at, 'YYYY-MM') = cohort_month)
        GROUP BY TO_CHAR(ups.started_at, 'YYYY-MM')
    ) cohort_row;

    RETURN COALESCE(result, '[]'::JSON);
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

COMMENT ON FUNCTION get_revenue_by_cohort IS 'ACP-976: Returns revenue and retention metrics grouped by the month users first subscribed';

-- ============================================================================
-- 3. get_ltv_by_tier
-- ============================================================================
-- Estimates Customer Lifetime Value per premium pack tier based on:
--   LTV = ARPU * Average Lifespan (months)
-- Also includes churn-based LTV: ARPU / monthly_churn_rate
-- ============================================================================

CREATE OR REPLACE FUNCTION get_ltv_by_tier()
RETURNS JSON AS $$
DECLARE
    result JSON;
    v_now TIMESTAMPTZ := NOW();
BEGIN
    SELECT json_agg(ltv_row ORDER BY ltv_row.estimated_ltv DESC)
    INTO result
    FROM (
        SELECT
            pp.code AS tier,
            pp.name AS tier_name,
            pp.base_price_monthly AS monthly_price,
            COUNT(*) AS total_subscriptions,
            COUNT(*) FILTER (WHERE ups.status = 'active') AS active_subscriptions,
            COUNT(*) FILTER (WHERE ups.status IN ('cancelled', 'expired')) AS churned_subscriptions,

            -- Average lifespan in months
            ROUND(
                AVG(
                    EXTRACT(EPOCH FROM (
                        COALESCE(ups.cancelled_at, ups.expires_at, v_now) - ups.started_at
                    )) / (30.44 * 86400)
                ),
                1
            ) AS avg_lifespan_months,

            -- Median lifespan in months (approximated via percentile)
            ROUND(
                PERCENTILE_CONT(0.5) WITHIN GROUP (
                    ORDER BY EXTRACT(EPOCH FROM (
                        COALESCE(ups.cancelled_at, ups.expires_at, v_now) - ups.started_at
                    )) / (30.44 * 86400)
                ),
                1
            ) AS median_lifespan_months,

            -- Monthly churn rate for this tier
            ROUND(
                CASE
                    WHEN COUNT(*) > 0 THEN
                        COUNT(*) FILTER (WHERE ups.status IN ('cancelled', 'expired'))::NUMERIC
                        / NULLIF(COUNT(*), 0)
                        / NULLIF(
                            AVG(
                                EXTRACT(EPOCH FROM (
                                    COALESCE(ups.cancelled_at, ups.expires_at, v_now) - ups.started_at
                                )) / (30.44 * 86400)
                            ),
                            0
                        )
                    ELSE 0
                END * 100,
                2
            ) AS monthly_churn_rate_percent,

            -- LTV estimate: price * average lifespan
            ROUND(
                pp.base_price_monthly * AVG(
                    EXTRACT(EPOCH FROM (
                        COALESCE(ups.cancelled_at, ups.expires_at, v_now) - ups.started_at
                    )) / (30.44 * 86400)
                ),
                2
            ) AS estimated_ltv,

            -- LTV via churn method: ARPU / churn_rate (if churn > 0)
            ROUND(
                CASE
                    WHEN COUNT(*) FILTER (WHERE ups.status IN ('cancelled', 'expired')) > 0
                    THEN pp.base_price_monthly / NULLIF(
                        COUNT(*) FILTER (WHERE ups.status IN ('cancelled', 'expired'))::NUMERIC
                        / NULLIF(COUNT(*), 0)
                        / NULLIF(
                            AVG(
                                EXTRACT(EPOCH FROM (
                                    COALESCE(ups.cancelled_at, ups.expires_at, v_now) - ups.started_at
                                )) / (30.44 * 86400)
                            ),
                            0
                        ),
                        0
                    )
                    ELSE NULL
                END,
                2
            ) AS estimated_ltv_churn_method,

            -- Trial conversion rate for this tier
            ROUND(
                CASE
                    WHEN COUNT(*) FILTER (WHERE ups.status = 'trial' OR ups.status = 'active') > 0
                    THEN COUNT(*) FILTER (WHERE ups.status = 'active')::NUMERIC
                         / NULLIF(COUNT(*), 0) * 100
                    ELSE 0
                END,
                2
            ) AS conversion_rate_percent

        FROM premium_packs pp
        LEFT JOIN user_pack_subscriptions ups ON ups.pack_id = pp.id
        WHERE pp.is_active = true
        GROUP BY pp.code, pp.name, pp.base_price_monthly
        HAVING COUNT(ups.id) > 0
    ) ltv_row;

    RETURN COALESCE(result, '[]'::JSON);
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

COMMENT ON FUNCTION get_ltv_by_tier IS 'ACP-976: Estimates customer lifetime value per premium pack tier using average lifespan and churn-based methods';

-- ============================================================================
-- 4. Permissions
-- ============================================================================
-- These functions use SECURITY DEFINER so they run with the owner's
-- permissions. Grant execute only to service_role to prevent unauthorized
-- access to aggregate revenue data.
-- ============================================================================

REVOKE EXECUTE ON FUNCTION get_revenue_metrics FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION get_revenue_by_cohort FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION get_ltv_by_tier FROM PUBLIC;

-- Only service_role can call these (via Edge Functions)
GRANT EXECUTE ON FUNCTION get_revenue_metrics TO service_role;
GRANT EXECUTE ON FUNCTION get_revenue_by_cohort TO service_role;
GRANT EXECUTE ON FUNCTION get_ltv_by_tier TO service_role;

-- ============================================================================
-- 5. Supporting index for revenue analytics queries
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_user_pack_subscriptions_started_at
    ON user_pack_subscriptions(started_at);

CREATE INDEX IF NOT EXISTS idx_user_pack_subscriptions_cancelled_at
    ON user_pack_subscriptions(cancelled_at)
    WHERE cancelled_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_user_subscriptions_updated_at
    ON user_subscriptions(updated_at);
