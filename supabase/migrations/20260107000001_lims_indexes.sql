-- ============================================================================
-- LIMS Performance Indexes v1.0
-- Created: 2026-01-07
-- Purpose: Additional performance indexes for LIMS queries and analytics
--
-- Note: Basic indexes are already in 20260107000000_lims_schema.sql
-- This file adds composite indexes, partial indexes, and query-specific indexes
-- ============================================================================

-- ============================================================================
-- MATERIALS & INVENTORY - Advanced Indexes
-- ============================================================================

-- Composite index for material lookup by type and QC status
CREATE INDEX idx_batches_material_type_qc ON lims_batches(material_id, qc_status)
    WHERE qc_status IN ('pass', 'pending');

-- Index for finding expiring batches
CREATE INDEX idx_batches_expiring_soon ON lims_batches(expiration_date, qc_status)
    WHERE expiration_date > CURRENT_DATE
    AND qc_status = 'pass';

-- Index for available aliquots (not depleted, with volume)
CREATE INDEX idx_aliquots_available ON lims_aliquots(batch_id, volume_ul)
    WHERE depleted = FALSE
    AND volume_ul > 0;

-- Index for high freeze-thaw count aliquots
CREATE INDEX idx_aliquots_freeze_thaw ON lims_aliquots(freeze_thaw_count, depleted)
    WHERE freeze_thaw_count > 3;

-- ============================================================================
-- SAMPLES & RUNS - Query Optimization
-- ============================================================================

-- Composite index for sample queries by material and state
CREATE INDEX idx_samples_material_state ON lims_samples(material_id, sample_state)
    WHERE sample_state IN ('accepted', 'processed');

-- Index for finding samples by cell line and differentiation day
CREATE INDEX idx_samples_cell_diff ON lims_samples(cell_line, differentiation_day)
    WHERE cell_line IS NOT NULL;

-- Index for sample concentration range queries
CREATE INDEX idx_samples_concentration ON lims_samples(treatment_concentration, treatment_concentration_unit)
    WHERE treatment_concentration IS NOT NULL;

-- Composite index for run queries by protocol, status, and QC
CREATE INDEX idx_runs_protocol_status_qc ON lims_runs(protocol_id, run_status, qc_status);

-- Index for finding recent runs by operator
CREATE INDEX idx_runs_operator_recent ON lims_runs(operator, run_start_time DESC)
    WHERE run_start_time IS NOT NULL;

-- Index for QC analysis (runs needing review)
CREATE INDEX idx_runs_qc_pending ON lims_runs(qc_status, run_end_time)
    WHERE qc_status = 'pending'
    AND run_status = 'completed';

-- Index for time-based run analysis
CREATE INDEX idx_runs_time_range ON lims_runs(run_start_time, run_end_time)
    WHERE run_status = 'completed';

-- ============================================================================
-- OBSERVATIONS & FEATURES - High Performance for Analytics
-- ============================================================================

-- Composite index for observation queries by run and FOV
CREATE INDEX idx_observations_run_fov_time ON lims_observations(run_id, fov_number, minutes_from_run_start);

-- Index for quality filtering (good SNR and cell count)
CREATE INDEX idx_observations_quality ON lims_observations(run_id, snr, cell_count)
    WHERE snr > 5
    AND cell_count > 10;

-- Index for outlier detection
CREATE INDEX idx_observations_outliers ON lims_observations(sample_id, snr)
    WHERE snr IS NOT NULL;

-- CRITICAL: Composite index for feature value queries (primary analytics query)
CREATE INDEX idx_features_definition_value ON lims_features(feature_definition_id, feature_value)
    WHERE feature_value IS NOT NULL
    AND is_outlier = FALSE;

-- Index for feature queries by observation (retrieve all features for one observation)
CREATE INDEX idx_features_observation_definition ON lims_features(observation_id, feature_definition_id)
    INCLUDE (feature_value);

-- Index for feature statistics (group by feature definition)
CREATE INDEX idx_features_stats ON lims_features(feature_definition_id, is_outlier)
    WHERE feature_value IS NOT NULL;

-- Partial index for outlier analysis
CREATE INDEX idx_features_outlier_analysis ON lims_features(feature_definition_id, outlier_reason)
    WHERE is_outlier = TRUE;

-- ============================================================================
-- DATASETS & LINEAGE - Sapphire Integration Queries
-- ============================================================================

-- Composite index for dataset queries by type, QC, and publication status
CREATE INDEX idx_datasets_type_qc_published ON lims_datasets(dataset_type, qc_status, published);

-- Index for finding datasets by genes (GIN index for array containment)
-- Already created in schema, adding expression index for better query planning
CREATE INDEX idx_datasets_genes_count ON lims_datasets((cardinality(related_genes)), published)
    WHERE published = TRUE;

-- Index for finding datasets by drugs (GIN index for array containment)
-- Already created in schema, adding expression index
CREATE INDEX idx_datasets_drugs_count ON lims_datasets((cardinality(related_drugs)), published)
    WHERE published = TRUE;

-- Index for dataset versioning queries
CREATE INDEX idx_datasets_name_latest ON lims_datasets(dataset_name, dataset_version DESC, published)
    WHERE published = TRUE;

-- Index for lineage traversal (parent → children)
CREATE INDEX idx_lineage_parent_transformation ON lims_dataset_lineage(parent_dataset_id, transformation_type);

-- Index for lineage traversal (child → parents)
CREATE INDEX idx_lineage_child_transformation ON lims_dataset_lineage(child_dataset_id, transformation_type);

-- Recursive lineage queries (find all ancestors/descendants)
CREATE INDEX idx_lineage_recursive ON lims_dataset_lineage(parent_dataset_id, child_dataset_id);

-- ============================================================================
-- COMPUTE RUNS - Performance Monitoring
-- ============================================================================

-- Index for finding compute runs by recipe and status
CREATE INDEX idx_compute_runs_recipe_status ON lims_compute_runs(recipe_id, status, execution_start DESC);

-- Index for performance analysis
CREATE INDEX idx_compute_runs_performance ON lims_compute_runs(recipe_id, wall_time_seconds, execution_start)
    WHERE status = 'completed';

-- Index for finding failed compute runs
CREATE INDEX idx_compute_runs_failed ON lims_compute_runs(recipe_id, status, execution_start)
    WHERE status = 'failed';

-- ============================================================================
-- CUSTODY LOG - Audit Queries
-- ============================================================================

-- Composite index for entity custody history
CREATE INDEX idx_custody_entity_timeline ON lims_custody_log(entity_type, entity_id, event_timestamp DESC);

-- Index for actor activity tracking
CREATE INDEX idx_custody_actor_timeline ON lims_custody_log(actor, event_timestamp DESC);

-- Index for event type analysis
CREATE INDEX idx_custody_event_actor ON lims_custody_log(event_type, actor, event_timestamp);

-- Index for location tracking (sample movement)
CREATE INDEX idx_custody_location_timeline ON lims_custody_log(from_location, to_location, event_timestamp)
    WHERE event_type = 'moved';

-- ============================================================================
-- INSTRUMENTS - Calibration Tracking
-- ============================================================================

-- Index for calibration due dates
CREATE INDEX idx_instruments_calibration_due ON lims_instruments(calibration_due_date, instrument_status)
    WHERE calibration_status IN ('due', 'overdue')
    AND instrument_status = 'active';

-- Index for instrument maintenance history
CREATE INDEX idx_maintenance_instrument_recent ON lims_instrument_maintenance(instrument_id, maintenance_date DESC)
    WHERE status = 'completed';

-- ============================================================================
-- QUERY-SPECIFIC COMPOSITE INDEXES
-- ============================================================================

-- "Find all samples from a run with their features"
CREATE INDEX idx_run_samples_features ON lims_samples(well_id)
    INCLUDE (sample_id, material_id, treatment_concentration);

CREATE INDEX idx_sample_observations ON lims_observations(sample_id, run_id)
    INCLUDE (observation_id, fov_number, snr);

-- "Find all datasets from a protocol version"
CREATE INDEX idx_datasets_protocol ON lims_datasets(protocol_id, published)
    WHERE published = TRUE;

-- "Find all observations for a specific compound"
CREATE INDEX idx_compound_observations ON lims_samples(material_id)
    INCLUDE (sample_id, treatment_concentration);

-- ============================================================================
-- STATISTICS & VACUUM SETTINGS
-- ============================================================================

-- Increase statistics target for high-cardinality columns
ALTER TABLE lims_features ALTER COLUMN feature_value SET STATISTICS 1000;
ALTER TABLE lims_observations ALTER COLUMN snr SET STATISTICS 500;
ALTER TABLE lims_samples ALTER COLUMN treatment_concentration SET STATISTICS 500;

-- Set autovacuum settings for large tables (features table will be 13M+ rows)
ALTER TABLE lims_features SET (
    autovacuum_vacuum_scale_factor = 0.05,  -- Vacuum when 5% of rows change
    autovacuum_analyze_scale_factor = 0.02,  -- Analyze when 2% change
    autovacuum_vacuum_cost_delay = 10        -- Faster vacuum
);

ALTER TABLE lims_observations SET (
    autovacuum_vacuum_scale_factor = 0.1,
    autovacuum_analyze_scale_factor = 0.05
);

ALTER TABLE lims_custody_log SET (
    autovacuum_vacuum_scale_factor = 0.1,
    autovacuum_analyze_scale_factor = 0.05,
    fillfactor = 100  -- Append-only, no updates
);

-- ============================================================================
-- PERFORMANCE VIEWS (Materialized for expensive queries)
-- ============================================================================

-- Materialized view: Sample summary with run and QC info
CREATE MATERIALIZED VIEW mv_sample_summary AS
SELECT
    s.sample_id,
    s.sample_identifier,
    s.sample_state,
    s.material_id,
    m.corporate_id,
    m.name AS material_name,
    s.treatment_concentration,
    s.treatment_concentration_unit,
    s.cell_line,
    s.differentiation_day,
    w.well_position,
    c.container_barcode,
    r.run_id,
    r.run_identifier,
    r.qc_status AS run_qc_status,
    r.qc_score AS run_qc_score,
    COUNT(o.observation_id) AS observation_count,
    AVG(o.snr) AS avg_snr,
    AVG(o.cell_count) AS avg_cell_count
FROM lims_samples s
LEFT JOIN lims_materials m ON s.material_id = m.material_id
LEFT JOIN lims_wells w ON s.well_id = w.well_id
LEFT JOIN lims_containers c ON w.container_id = c.container_id
LEFT JOIN lims_observations o ON s.sample_id = o.sample_id
LEFT JOIN lims_runs r ON o.run_id = r.run_id
GROUP BY
    s.sample_id, s.sample_identifier, s.sample_state, s.material_id,
    m.corporate_id, m.name, s.treatment_concentration, s.treatment_concentration_unit,
    s.cell_line, s.differentiation_day, w.well_position, c.container_barcode,
    r.run_id, r.run_identifier, r.qc_status, r.qc_score;

-- Index on materialized view
CREATE INDEX idx_mv_sample_summary_material ON mv_sample_summary(material_id, run_qc_status);
CREATE INDEX idx_mv_sample_summary_run ON mv_sample_summary(run_id);
CREATE INDEX idx_mv_sample_summary_identifier ON mv_sample_summary(sample_identifier);

-- Refresh function (to be called after data loads)
CREATE OR REPLACE FUNCTION refresh_sample_summary()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_sample_summary;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- PERFORMANCE MONITORING VIEWS
-- ============================================================================

-- View: Dataset summary for Sapphire queries
CREATE VIEW v_dataset_summary AS
SELECT
    d.dataset_id,
    d.dataset_name,
    d.dataset_version,
    d.dataset_type,
    d.title,
    d.qc_status,
    d.qc_score,
    d.qc_grade,
    d.published,
    d.published_at,
    d.related_genes,
    d.related_drugs,
    d.data_format,
    d.data_size_bytes,
    p.protocol_name,
    p.protocol_version,
    cr.recipe_name AS compute_recipe_name,
    cr.recipe_version AS compute_recipe_version,
    cardinality(d.run_ids) AS run_count,
    cardinality(d.related_genes) AS gene_count,
    cardinality(d.related_drugs) AS drug_count
FROM lims_datasets d
LEFT JOIN lims_protocols p ON d.protocol_id = p.protocol_id
LEFT JOIN lims_compute_runs crun ON d.compute_run_id = crun.compute_run_id
LEFT JOIN lims_compute_recipes cr ON crun.recipe_id = cr.recipe_id;

-- View: Run summary with sample and observation counts
CREATE VIEW v_run_summary AS
SELECT
    r.run_id,
    r.run_identifier,
    r.protocol_id,
    p.protocol_name,
    p.protocol_version,
    r.operator,
    r.run_start_time,
    r.run_end_time,
    r.run_status,
    r.qc_status,
    r.qc_score,
    r.qc_grade,
    EXTRACT(EPOCH FROM (r.run_end_time - r.run_start_time)) / 3600.0 AS run_duration_hours,
    COUNT(DISTINCT s.sample_id) AS sample_count,
    COUNT(DISTINCT o.observation_id) AS observation_count,
    COUNT(DISTINCT rc.container_id) AS container_count,
    AVG(o.snr) AS avg_snr,
    AVG(o.cell_count) AS avg_cell_count
FROM lims_runs r
LEFT JOIN lims_protocols p ON r.protocol_id = p.protocol_id
LEFT JOIN lims_observations o ON r.run_id = o.run_id
LEFT JOIN lims_samples s ON o.sample_id = s.sample_id
LEFT JOIN lims_run_containers rc ON r.run_id = rc.run_id
GROUP BY
    r.run_id, r.run_identifier, r.protocol_id, p.protocol_name, p.protocol_version,
    r.operator, r.run_start_time, r.run_end_time, r.run_status, r.qc_status,
    r.qc_score, r.qc_grade;

-- ============================================================================
-- EXPLAIN ANALYZE HELPER FUNCTIONS
-- ============================================================================

-- Function to analyze query performance
CREATE OR REPLACE FUNCTION analyze_query_performance(query_text TEXT)
RETURNS TABLE (
    plan_line TEXT
) AS $$
BEGIN
    RETURN QUERY EXECUTE 'EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) ' || query_text;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- INDEX USAGE MONITORING
-- ============================================================================

-- View: Index usage statistics
CREATE VIEW v_index_usage AS
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
    AND tablename LIKE 'lims_%'
ORDER BY idx_scan DESC;

-- View: Unused indexes (candidates for removal)
CREATE VIEW v_unused_indexes AS
SELECT
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
    AND tablename LIKE 'lims_%'
    AND idx_scan = 0
    AND indexrelid NOT IN (
        SELECT conindid FROM pg_constraint WHERE contype IN ('p', 'u')  -- Exclude PK and unique constraints
    )
ORDER BY pg_relation_size(indexrelid) DESC;

-- ============================================================================
-- PERFORMANCE COMMENTS
-- ============================================================================

COMMENT ON INDEX idx_features_definition_value IS 'CRITICAL: Primary index for feature analytics queries. Used by Sapphire tools.';
COMMENT ON INDEX idx_datasets_genes IS 'GIN index for array containment queries (e.g., find datasets related to SCN1A)';
COMMENT ON MATERIALIZED VIEW mv_sample_summary IS 'Pre-computed sample summary. Refresh after bulk data loads.';
COMMENT ON VIEW v_dataset_summary IS 'Dataset metadata for Sapphire query_experimental_datasets tool';

-- ============================================================================
-- END OF PERFORMANCE INDEXES
-- ============================================================================
