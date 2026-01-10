-- ============================================================================
-- LIMS Bridge Views v1.0
-- Created: 2026-01-07
-- Purpose: Bridge views connecting LIMS to existing Quiver platform
--
-- Provides:
-- - Entity bridges (LIMS ↔ Neo4j entity references)
-- - Feature vector views (ML-ready data structures)
-- - Sapphire query-optimized views
-- - Cross-system integration views
-- ============================================================================

-- ============================================================================
-- ENTITY BRIDGES (LIMS ↔ Neo4j/Knowledge Graph)
-- ============================================================================

-- Material Entity Bridge
-- Maps LIMS materials to Neo4j entity IDs (drugs, compounds)
CREATE OR REPLACE VIEW v_material_entity_bridge AS
SELECT
    m.material_id,
    m.corporate_id,
    m.external_id,
    m.material_type,
    m.name,
    m.cas_number,
    -- Extract entity_id from metadata if exists (for Neo4j linking)
    (m.metadata->>'neo4j_entity_id')::TEXT AS neo4j_entity_id,
    (m.metadata->>'chembl_id')::TEXT AS chembl_id,
    (m.metadata->>'pubchem_cid')::TEXT AS pubchem_cid,
    -- Batch summary (best available batch)
    (
        SELECT json_agg(
            json_build_object(
                'batch_id', b.batch_id,
                'batch_number', b.batch_number,
                'qc_status', b.qc_status,
                'expiration_date', b.expiration_date,
                'available_aliquots', (
                    SELECT COUNT(*)
                    FROM lims_aliquots a
                    WHERE a.batch_id = b.batch_id
                    AND a.depleted = FALSE
                )
            )
        )
        FROM lims_batches b
        WHERE b.material_id = m.material_id
        AND b.qc_status = 'pass'
        AND (b.expiration_date IS NULL OR b.expiration_date > CURRENT_DATE)
    ) AS available_batches
FROM lims_materials m;

COMMENT ON VIEW v_material_entity_bridge IS 'Bridge between LIMS materials and Neo4j/external entities (drugs, compounds)';

-- Gene Entity Bridge (for samples with gene perturbations)
CREATE OR REPLACE VIEW v_gene_entity_bridge AS
SELECT DISTINCT
    (s.metadata->>'target_gene')::TEXT AS gene_symbol,
    (s.metadata->>'gene_entity_id')::TEXT AS neo4j_entity_id,
    COUNT(DISTINCT s.sample_id) AS sample_count,
    COUNT(DISTINCT o.observation_id) AS observation_count,
    ARRAY_AGG(DISTINCT r.run_id) AS run_ids
FROM lims_samples s
LEFT JOIN lims_observations o ON s.sample_id = o.sample_id
LEFT JOIN lims_runs r ON o.run_id = r.run_id
WHERE s.metadata->>'target_gene' IS NOT NULL
GROUP BY gene_symbol, neo4j_entity_id;

COMMENT ON VIEW v_gene_entity_bridge IS 'Bridge between LIMS samples and gene entities in Neo4j';

-- ============================================================================
-- FEATURE VECTOR VIEWS (ML-Ready Data)
-- ============================================================================

-- Observation Feature Vector
-- Pivots features into columnar format for ML pipelines
-- Note: This is a template view - actual feature columns added dynamically after data load
CREATE OR REPLACE VIEW v_observation_feature_vectors AS
SELECT
    o.observation_id,
    o.run_id,
    o.sample_id,
    s.sample_identifier,
    s.material_id,
    m.corporate_id,
    m.name AS material_name,
    s.treatment_concentration,
    s.treatment_concentration_unit,
    s.cell_line,
    s.differentiation_day,
    o.fov_number,
    o.minutes_from_run_start,
    o.snr,
    o.cell_count,
    r.qc_status AS run_qc_status,
    r.qc_score AS run_qc_score,
    -- Feature values (stored as JSONB for flexibility)
    (
        SELECT jsonb_object_agg(
            fd.feature_name,
            f.feature_value
        )
        FROM lims_features f
        JOIN lims_feature_definitions fd ON f.feature_definition_id = fd.feature_definition_id
        WHERE f.observation_id = o.observation_id
        AND f.is_outlier = FALSE
    ) AS features_jsonb,
    -- Feature count
    (
        SELECT COUNT(*)
        FROM lims_features f
        WHERE f.observation_id = o.observation_id
        AND f.feature_value IS NOT NULL
        AND f.is_outlier = FALSE
    ) AS feature_count
FROM lims_observations o
JOIN lims_samples s ON o.sample_id = s.sample_id
JOIN lims_runs r ON o.run_id = r.run_id
LEFT JOIN lims_materials m ON s.material_id = m.material_id;

COMMENT ON VIEW v_observation_feature_vectors IS 'Feature vectors per observation (ML-ready, JSONB format)';

-- Sample-Level Feature Aggregates
-- Aggregates observation features to sample level (for multi-FOV experiments)
CREATE OR REPLACE VIEW v_sample_feature_aggregates AS
SELECT
    s.sample_id,
    s.sample_identifier,
    s.material_id,
    m.corporate_id,
    m.name AS material_name,
    s.treatment_concentration,
    s.treatment_concentration_unit,
    s.cell_line,
    s.differentiation_day,
    r.run_id,
    r.run_identifier,
    -- Observation stats
    COUNT(DISTINCT o.observation_id) AS observation_count,
    AVG(o.snr) AS avg_snr,
    STDDEV(o.snr) AS stddev_snr,
    AVG(o.cell_count) AS avg_cell_count,
    -- Feature stats (aggregated across observations)
    (
        SELECT jsonb_object_agg(
            fd.feature_name,
            json_build_object(
                'mean', AVG(f.feature_value),
                'std', STDDEV(f.feature_value),
                'min', MIN(f.feature_value),
                'max', MAX(f.feature_value),
                'count', COUNT(f.feature_value)
            )
        )
        FROM lims_features f
        JOIN lims_feature_definitions fd ON f.feature_definition_id = fd.feature_definition_id
        JOIN lims_observations obs ON f.observation_id = obs.observation_id
        WHERE obs.sample_id = s.sample_id
        AND f.is_outlier = FALSE
        GROUP BY fd.feature_name
    ) AS feature_statistics
FROM lims_samples s
LEFT JOIN lims_materials m ON s.material_id = m.material_id
LEFT JOIN lims_observations o ON s.sample_id = o.sample_id
LEFT JOIN lims_runs r ON o.run_id = r.run_id
GROUP BY
    s.sample_id, s.sample_identifier, s.material_id, m.corporate_id, m.name,
    s.treatment_concentration, s.treatment_concentration_unit, s.cell_line,
    s.differentiation_day, r.run_id, r.run_identifier;

COMMENT ON VIEW v_sample_feature_aggregates IS 'Sample-level feature aggregates (mean/std across FOVs)';

-- ============================================================================
-- EXPERIMENTAL DATA VIEWS (Sapphire Integration)
-- ============================================================================

-- Dataset Feature Summary
-- Summary of features available in each dataset
CREATE OR REPLACE VIEW v_dataset_feature_summary AS
SELECT
    d.dataset_id,
    d.dataset_name,
    d.dataset_version,
    d.title,
    d.qc_status,
    -- Sample count
    (
        SELECT COUNT(DISTINCT s.sample_id)
        FROM lims_samples s
        JOIN lims_observations o ON s.sample_id = o.sample_id
        JOIN lims_runs r ON o.run_id = r.run_id
        WHERE r.run_id = ANY(d.run_ids)
    ) AS sample_count,
    -- Observation count
    (
        SELECT COUNT(DISTINCT o.observation_id)
        FROM lims_observations o
        JOIN lims_runs r ON o.run_id = r.run_id
        WHERE r.run_id = ANY(d.run_ids)
    ) AS observation_count,
    -- Feature count
    (
        SELECT COUNT(DISTINCT fd.feature_definition_id)
        FROM lims_features f
        JOIN lims_feature_definitions fd ON f.feature_definition_id = fd.feature_definition_id
        JOIN lims_observations o ON f.observation_id = o.observation_id
        JOIN lims_runs r ON o.run_id = r.run_id
        WHERE r.run_id = ANY(d.run_ids)
    ) AS feature_count,
    -- Feature classes
    (
        SELECT ARRAY_AGG(DISTINCT fd.feature_class)
        FROM lims_features f
        JOIN lims_feature_definitions fd ON f.feature_definition_id = fd.feature_definition_id
        JOIN lims_observations o ON f.observation_id = o.observation_id
        JOIN lims_runs r ON o.run_id = r.run_id
        WHERE r.run_id = ANY(d.run_ids)
    ) AS feature_classes,
    -- Materials tested
    (
        SELECT COUNT(DISTINCT s.material_id)
        FROM lims_samples s
        JOIN lims_observations o ON s.sample_id = o.sample_id
        JOIN lims_runs r ON o.run_id = r.run_id
        WHERE r.run_id = ANY(d.run_ids)
    ) AS material_count,
    -- Cell lines
    (
        SELECT ARRAY_AGG(DISTINCT s.cell_line)
        FROM lims_samples s
        JOIN lims_observations o ON s.sample_id = o.sample_id
        JOIN lims_runs r ON o.run_id = r.run_id
        WHERE r.run_id = ANY(d.run_ids)
        AND s.cell_line IS NOT NULL
    ) AS cell_lines
FROM lims_datasets d
WHERE d.published = TRUE;

COMMENT ON VIEW v_dataset_feature_summary IS 'Summary statistics for published datasets (Sapphire queries)';

-- ============================================================================
-- QC & MONITORING VIEWS
-- ============================================================================

-- QC Dashboard View
CREATE OR REPLACE VIEW v_qc_dashboard AS
SELECT
    r.run_id,
    r.run_identifier,
    r.operator,
    r.run_start_time,
    r.run_status,
    r.qc_status,
    r.qc_score,
    r.qc_grade,
    p.protocol_name,
    p.protocol_version,
    COUNT(DISTINCT s.sample_id) AS sample_count,
    COUNT(DISTINCT o.observation_id) AS observation_count,
    -- Quality metrics
    AVG(o.snr) AS avg_snr,
    MIN(o.snr) AS min_snr,
    MAX(o.snr) AS max_snr,
    STDDEV(o.snr) AS stddev_snr,
    AVG(o.cell_count) AS avg_cell_count,
    -- Outlier counts
    (
        SELECT COUNT(*)
        FROM lims_features f
        JOIN lims_observations obs ON f.observation_id = obs.observation_id
        WHERE obs.run_id = r.run_id
        AND f.is_outlier = TRUE
    ) AS outlier_feature_count,
    -- Control wells
    (
        SELECT COUNT(DISTINCT s2.sample_id)
        FROM lims_samples s2
        JOIN lims_wells w ON s2.well_id = w.well_id
        JOIN lims_observations o2 ON s2.sample_id = o2.sample_id
        WHERE o2.run_id = r.run_id
        AND w.content_type IN ('positive_control', 'negative_control')
    ) AS control_well_count
FROM lims_runs r
LEFT JOIN lims_protocols p ON r.protocol_id = p.protocol_id
LEFT JOIN lims_observations o ON r.run_id = o.run_id
LEFT JOIN lims_samples s ON o.sample_id = s.sample_id
WHERE r.run_status IN ('completed', 'running')
GROUP BY
    r.run_id, r.run_identifier, r.operator, r.run_start_time, r.run_status,
    r.qc_status, r.qc_score, r.qc_grade, p.protocol_name, p.protocol_version;

COMMENT ON VIEW v_qc_dashboard IS 'QC dashboard metrics for run monitoring';

-- Sample Lifecycle View
CREATE OR REPLACE VIEW v_sample_lifecycle AS
SELECT
    s.sample_id,
    s.sample_identifier,
    s.sample_state,
    s.material_id,
    m.corporate_id,
    m.name AS material_name,
    s.treatment_concentration,
    s.treatment_concentration_unit,
    s.created_at AS sample_created,
    -- Lifecycle events from custody log
    (
        SELECT jsonb_agg(
            json_build_object(
                'event_type', cl.event_type,
                'event_timestamp', cl.event_timestamp,
                'actor', cl.actor,
                'from_location', cl.from_location,
                'to_location', cl.to_location
            ) ORDER BY cl.event_timestamp
        )
        FROM lims_custody_log cl
        WHERE cl.entity_type = 'sample'
        AND cl.entity_id = s.sample_id
    ) AS lifecycle_events,
    -- Run information
    (
        SELECT json_build_object(
            'run_id', r.run_id,
            'run_identifier', r.run_identifier,
            'run_status', r.run_status,
            'qc_status', r.qc_status,
            'qc_score', r.qc_score
        )
        FROM lims_observations o
        JOIN lims_runs r ON o.run_id = r.run_id
        WHERE o.sample_id = s.sample_id
        LIMIT 1
    ) AS run_info
FROM lims_samples s
LEFT JOIN lims_materials m ON s.material_id = m.material_id;

COMMENT ON VIEW v_sample_lifecycle IS 'Sample lifecycle tracking with custody chain events';

-- ============================================================================
-- CONCENTRATION-RESPONSE VIEWS
-- ============================================================================

-- Concentration-Response Curve Data
-- Prepares data for dose-response analysis
CREATE OR REPLACE VIEW v_concentration_response AS
SELECT
    s.material_id,
    m.corporate_id,
    m.name AS material_name,
    r.run_id,
    r.run_identifier,
    fd.feature_name,
    fd.feature_class,
    s.treatment_concentration,
    s.treatment_concentration_unit,
    s.cell_line,
    s.differentiation_day,
    -- Feature statistics across replicates at this concentration
    COUNT(DISTINCT o.observation_id) AS replicate_count,
    AVG(f.feature_value) AS mean_feature_value,
    STDDEV(f.feature_value) AS std_feature_value,
    MIN(f.feature_value) AS min_feature_value,
    MAX(f.feature_value) AS max_feature_value,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY f.feature_value) AS median_feature_value
FROM lims_samples s
JOIN lims_materials m ON s.material_id = m.material_id
JOIN lims_observations o ON s.sample_id = o.sample_id
JOIN lims_runs r ON o.run_id = r.run_id
JOIN lims_features f ON o.observation_id = f.observation_id
JOIN lims_feature_definitions fd ON f.feature_definition_id = fd.feature_definition_id
WHERE s.treatment_concentration IS NOT NULL
AND f.is_outlier = FALSE
GROUP BY
    s.material_id, m.corporate_id, m.name, r.run_id, r.run_identifier,
    fd.feature_name, fd.feature_class, s.treatment_concentration,
    s.treatment_concentration_unit, s.cell_line, s.differentiation_day;

COMMENT ON VIEW v_concentration_response IS 'Concentration-response data for dose-response curve fitting';

-- ============================================================================
-- LINEAGE TRAVERSAL VIEWS
-- ============================================================================

-- Dataset Ancestry (all parent datasets)
CREATE OR REPLACE VIEW v_dataset_ancestry AS
WITH RECURSIVE ancestry AS (
    -- Base case: direct parents
    SELECT
        dl.child_dataset_id,
        dl.parent_dataset_id,
        dl.transformation_type,
        d.dataset_name AS parent_name,
        d.dataset_version AS parent_version,
        d.dataset_type AS parent_type,
        1 AS generation
    FROM lims_dataset_lineage dl
    JOIN lims_datasets d ON dl.parent_dataset_id = d.dataset_id

    UNION ALL

    -- Recursive case: grandparents and beyond
    SELECT
        a.child_dataset_id,
        dl.parent_dataset_id,
        dl.transformation_type,
        d.dataset_name AS parent_name,
        d.dataset_version AS parent_version,
        d.dataset_type AS parent_type,
        a.generation + 1 AS generation
    FROM ancestry a
    JOIN lims_dataset_lineage dl ON a.parent_dataset_id = dl.child_dataset_id
    JOIN lims_datasets d ON dl.parent_dataset_id = d.dataset_id
)
SELECT * FROM ancestry;

COMMENT ON VIEW v_dataset_ancestry IS 'Recursive view showing all ancestor datasets';

-- Dataset Descendants (all child datasets)
CREATE OR REPLACE VIEW v_dataset_descendants AS
WITH RECURSIVE descendants AS (
    -- Base case: direct children
    SELECT
        dl.parent_dataset_id,
        dl.child_dataset_id,
        dl.transformation_type,
        d.dataset_name AS child_name,
        d.dataset_version AS child_version,
        d.dataset_type AS child_type,
        1 AS generation
    FROM lims_dataset_lineage dl
    JOIN lims_datasets d ON dl.child_dataset_id = d.dataset_id

    UNION ALL

    -- Recursive case: grandchildren and beyond
    SELECT
        desc.parent_dataset_id,
        dl.child_dataset_id,
        dl.transformation_type,
        d.dataset_name AS child_name,
        d.dataset_version AS child_version,
        d.dataset_type AS child_type,
        desc.generation + 1 AS generation
    FROM descendants desc
    JOIN lims_dataset_lineage dl ON desc.child_dataset_id = dl.parent_dataset_id
    JOIN lims_datasets d ON dl.child_dataset_id = d.dataset_id
)
SELECT * FROM descendants;

COMMENT ON VIEW v_dataset_descendants IS 'Recursive view showing all descendant datasets';

-- ============================================================================
-- UTILITY VIEWS
-- ============================================================================

-- Active Inventory View
CREATE OR REPLACE VIEW v_active_inventory AS
SELECT
    m.material_id,
    m.corporate_id,
    m.name,
    m.material_type,
    COUNT(DISTINCT b.batch_id) AS total_batches,
    SUM(CASE WHEN b.qc_status = 'pass' THEN 1 ELSE 0 END) AS passed_batches,
    COUNT(DISTINCT a.aliquot_id) AS total_aliquots,
    SUM(CASE WHEN a.depleted = FALSE THEN 1 ELSE 0 END) AS available_aliquots,
    SUM(CASE WHEN a.depleted = FALSE THEN a.volume_ul ELSE 0 END) AS total_volume_ul
FROM lims_materials m
LEFT JOIN lims_batches b ON m.material_id = b.material_id
LEFT JOIN lims_aliquots a ON b.batch_id = a.batch_id
GROUP BY m.material_id, m.corporate_id, m.name, m.material_type;

COMMENT ON VIEW v_active_inventory IS 'Active inventory summary with batch and aliquot counts';

-- Instrument Status View
CREATE OR REPLACE VIEW v_instrument_status AS
SELECT
    i.instrument_id,
    i.instrument_name,
    i.instrument_type,
    i.serial_number,
    i.lab_location,
    i.instrument_status,
    i.calibration_status,
    i.last_calibration_date,
    i.calibration_due_date,
    CURRENT_DATE - i.last_calibration_date AS days_since_calibration,
    i.calibration_due_date - CURRENT_DATE AS days_until_calibration_due,
    -- Recent runs
    (
        SELECT COUNT(*)
        FROM lims_runs r
        WHERE r.instrument_id = i.instrument_id
        AND r.run_start_time > NOW() - INTERVAL '30 days'
    ) AS runs_last_30_days,
    -- Recent maintenance
    (
        SELECT MAX(m.maintenance_date)
        FROM lims_instrument_maintenance m
        WHERE m.instrument_id = i.instrument_id
        AND m.status = 'completed'
    ) AS last_maintenance_date
FROM lims_instruments i;

COMMENT ON VIEW v_instrument_status IS 'Instrument status with calibration and usage tracking';

-- ============================================================================
-- GRANT PERMISSIONS (for application roles)
-- ============================================================================

-- Grant SELECT on all views to application role
GRANT SELECT ON v_material_entity_bridge TO lims_app_role;
GRANT SELECT ON v_gene_entity_bridge TO lims_app_role;
GRANT SELECT ON v_observation_feature_vectors TO lims_app_role;
GRANT SELECT ON v_sample_feature_aggregates TO lims_app_role;
GRANT SELECT ON v_dataset_feature_summary TO lims_app_role;
GRANT SELECT ON v_qc_dashboard TO lims_app_role;
GRANT SELECT ON v_sample_lifecycle TO lims_app_role;
GRANT SELECT ON v_concentration_response TO lims_app_role;
GRANT SELECT ON v_dataset_ancestry TO lims_app_role;
GRANT SELECT ON v_dataset_descendants TO lims_app_role;
GRANT SELECT ON v_active_inventory TO lims_app_role;
GRANT SELECT ON v_instrument_status TO lims_app_role;

-- ============================================================================
-- END OF BRIDGE VIEWS
-- ============================================================================
