-- ============================================================================
-- LIMS Schema v1.0
-- Created: 2026-01-07
-- Purpose: System-of-record for Quiver empirical operations
--
-- Architecture:
-- - 17 core tables for laboratory data management
-- - UUIDs for primary keys (distributed-friendly)
-- - JSONB for extensibility (metadata, parameters, QC flags)
-- - Immutable lineage tracking (datasets versioned, transformations tracked)
-- - Full referential integrity with foreign keys
-- ============================================================================

-- ============================================================================
-- MATERIALS & INVENTORY
-- ============================================================================

-- Materials (Compounds, Cell Lines, Reagents)
CREATE TABLE lims_materials (
    material_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Identity
    corporate_id TEXT NOT NULL UNIQUE,  -- e.g., QS0298372
    external_id TEXT,  -- Vendor catalog number
    material_type TEXT NOT NULL,  -- compound, cell_line, reagent, buffer

    -- Scientific
    name TEXT NOT NULL,
    description TEXT,
    cas_number TEXT,
    molecular_weight NUMERIC,
    formula TEXT,

    -- Metadata (JSONB for extensibility)
    metadata JSONB DEFAULT '{}'::jsonb,

    -- Audit
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by TEXT NOT NULL,

    -- Constraints
    CONSTRAINT valid_material_type CHECK (
        material_type IN ('compound', 'cell_line', 'reagent', 'buffer', 'control', 'standard')
    )
);

CREATE INDEX idx_materials_corporate_id ON lims_materials(corporate_id);
CREATE INDEX idx_materials_type ON lims_materials(material_type);
CREATE INDEX idx_materials_metadata ON lims_materials USING gin(metadata);

COMMENT ON TABLE lims_materials IS 'Master catalog of all laboratory materials (compounds, cell lines, reagents)';

-- Batches (Specific lots with QC status)
CREATE TABLE lims_batches (
    batch_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    material_id UUID NOT NULL REFERENCES lims_materials(material_id),

    -- Identity
    batch_number TEXT NOT NULL,
    lot_number TEXT,

    -- Source
    vendor TEXT,
    vendor_lot_number TEXT,
    received_date DATE,
    expiration_date DATE,

    -- Quality
    qc_status TEXT NOT NULL DEFAULT 'pending',
    qc_date DATE,
    qc_operator TEXT,
    qc_notes TEXT,

    -- Storage
    storage_location TEXT,
    storage_conditions TEXT,  -- e.g., "-80C", "4C", "RT"

    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,

    -- Audit
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by TEXT NOT NULL,

    -- Constraints
    CONSTRAINT valid_qc_status CHECK (
        qc_status IN ('pending', 'pass', 'fail', 'expired', 'depleted')
    ),
    CONSTRAINT batch_material_lot_unique UNIQUE (material_id, batch_number)
);

CREATE INDEX idx_batches_material ON lims_batches(material_id);
CREATE INDEX idx_batches_qc_status ON lims_batches(qc_status);
CREATE INDEX idx_batches_expiration ON lims_batches(expiration_date) WHERE expiration_date IS NOT NULL;

COMMENT ON TABLE lims_batches IS 'Specific lots/batches of materials with QC status and provenance';

-- Aliquots (Individual portions with barcode)
CREATE TABLE lims_aliquots (
    aliquot_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id UUID NOT NULL REFERENCES lims_batches(batch_id),

    -- Identity
    aliquot_barcode TEXT NOT NULL UNIQUE,

    -- Physical properties
    volume_ul NUMERIC,
    concentration NUMERIC,
    concentration_unit TEXT,

    -- Usage tracking
    freeze_thaw_count INTEGER DEFAULT 0,
    times_used INTEGER DEFAULT 0,
    depleted BOOLEAN DEFAULT FALSE,

    -- Location
    storage_location TEXT,
    container_barcode TEXT,
    well_position TEXT,

    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,

    -- Audit
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by TEXT NOT NULL
);

CREATE INDEX idx_aliquots_barcode ON lims_aliquots(aliquot_barcode);
CREATE INDEX idx_aliquots_batch ON lims_aliquots(batch_id);
CREATE INDEX idx_aliquots_depleted ON lims_aliquots(depleted) WHERE depleted = FALSE;

COMMENT ON TABLE lims_aliquots IS 'Individual aliquots with barcodes, tracking usage and freeze-thaw cycles';

-- ============================================================================
-- CONTAINERS & SAMPLES
-- ============================================================================

-- Containers (Plates, tubes)
CREATE TABLE lims_containers (
    container_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Identity
    container_barcode TEXT NOT NULL UNIQUE,
    container_type TEXT NOT NULL,  -- plate_384, plate_96, tube, flask

    -- Physical properties
    well_count INTEGER,
    rows INTEGER,
    columns INTEGER,

    -- Status
    status TEXT NOT NULL DEFAULT 'active',

    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,

    -- Audit
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by TEXT NOT NULL,

    -- Constraints
    CONSTRAINT valid_container_type CHECK (
        container_type IN ('plate_384', 'plate_96', 'plate_1536', 'tube', 'flask')
    ),
    CONSTRAINT valid_container_status CHECK (
        status IN ('active', 'archived', 'discarded')
    )
);

CREATE INDEX idx_containers_barcode ON lims_containers(container_barcode);
CREATE INDEX idx_containers_type ON lims_containers(container_type);

COMMENT ON TABLE lims_containers IS 'Physical containers (plates, tubes) with barcodes';

-- Wells (Individual wells within plates)
CREATE TABLE lims_wells (
    well_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    container_id UUID NOT NULL REFERENCES lims_containers(container_id),

    -- Position
    well_position TEXT NOT NULL,  -- e.g., 'A01', 'P24'
    row_index INTEGER NOT NULL,
    column_index INTEGER NOT NULL,

    -- Content type
    content_type TEXT,  -- sample, control, blank, empty

    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,

    -- Audit
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT well_position_unique UNIQUE (container_id, well_position),
    CONSTRAINT valid_content_type CHECK (
        content_type IN ('sample', 'positive_control', 'negative_control', 'blank', 'empty', 'standard')
    )
);

CREATE INDEX idx_wells_container ON lims_wells(container_id);
CREATE INDEX idx_wells_position ON lims_wells(container_id, well_position);
CREATE INDEX idx_wells_content_type ON lims_wells(content_type);

COMMENT ON TABLE lims_wells IS 'Individual wells within containers with position tracking';

-- Samples (Experimental samples with treatments)
CREATE TABLE lims_samples (
    sample_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    well_id UUID NOT NULL REFERENCES lims_wells(well_id),

    -- Identity
    sample_identifier TEXT NOT NULL UNIQUE,

    -- Treatment
    material_id UUID REFERENCES lims_materials(material_id),
    treatment_concentration NUMERIC,
    treatment_concentration_unit TEXT,
    treatment_volume_ul NUMERIC,

    -- Biological context
    cell_line TEXT,
    passage_number INTEGER,
    cell_density INTEGER,
    differentiation_day INTEGER,

    -- Sample lifecycle state
    sample_state TEXT NOT NULL DEFAULT 'registered',

    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,

    -- Audit
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by TEXT NOT NULL,

    -- Constraints
    CONSTRAINT valid_sample_state CHECK (
        sample_state IN ('registered', 'received', 'accepted', 'processed', 'published', 'archived')
    )
);

CREATE INDEX idx_samples_identifier ON lims_samples(sample_identifier);
CREATE INDEX idx_samples_material ON lims_samples(material_id);
CREATE INDEX idx_samples_well ON lims_samples(well_id);
CREATE INDEX idx_samples_state ON lims_samples(sample_state);

COMMENT ON TABLE lims_samples IS 'Experimental samples with treatment information and lifecycle tracking';

-- ============================================================================
-- PROTOCOLS & RUNS
-- ============================================================================

-- Protocols (Versioned experimental protocols)
CREATE TABLE lims_protocols (
    protocol_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Identity
    protocol_name TEXT NOT NULL,
    protocol_version TEXT NOT NULL,
    protocol_type TEXT NOT NULL,

    -- Content
    description TEXT,
    steps JSONB NOT NULL,  -- Array of protocol steps
    parameters JSONB DEFAULT '{}'::jsonb,

    -- Validation
    validated BOOLEAN DEFAULT FALSE,
    validation_date DATE,
    validated_by TEXT,

    -- Status
    status TEXT NOT NULL DEFAULT 'draft',

    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,

    -- Audit
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by TEXT NOT NULL,

    -- Constraints
    CONSTRAINT protocol_name_version_unique UNIQUE (protocol_name, protocol_version),
    CONSTRAINT valid_protocol_status CHECK (
        status IN ('draft', 'validated', 'active', 'deprecated', 'retired')
    )
);

CREATE INDEX idx_protocols_name ON lims_protocols(protocol_name);
CREATE INDEX idx_protocols_version ON lims_protocols(protocol_name, protocol_version);
CREATE INDEX idx_protocols_status ON lims_protocols(status);

COMMENT ON TABLE lims_protocols IS 'Versioned experimental protocols with validation tracking';

-- Runs (Run executions)
CREATE TABLE lims_runs (
    run_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    protocol_id UUID NOT NULL REFERENCES lims_protocols(protocol_id),

    -- Identity
    run_identifier TEXT NOT NULL UNIQUE,

    -- Execution
    operator TEXT NOT NULL,
    instrument_id UUID,  -- Foreign key added later
    run_start_time TIMESTAMPTZ,
    run_end_time TIMESTAMPTZ,

    -- Status
    run_status TEXT NOT NULL DEFAULT 'pending',

    -- Environment
    temperature_c NUMERIC,
    humidity_percent NUMERIC,
    co2_percent NUMERIC,

    -- Quality
    qc_status TEXT,
    qc_score NUMERIC,
    qc_grade TEXT,
    qc_metrics JSONB DEFAULT '{}'::jsonb,

    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,

    -- Audit
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by TEXT NOT NULL,

    -- Constraints
    CONSTRAINT valid_run_status CHECK (
        run_status IN ('pending', 'running', 'completed', 'failed', 'aborted')
    ),
    CONSTRAINT valid_qc_status CHECK (
        qc_status IS NULL OR qc_status IN ('pending', 'passed', 'conditional', 'failed')
    )
);

CREATE INDEX idx_runs_identifier ON lims_runs(run_identifier);
CREATE INDEX idx_runs_protocol ON lims_runs(protocol_id);
CREATE INDEX idx_runs_operator ON lims_runs(operator);
CREATE INDEX idx_runs_status ON lims_runs(run_status);
CREATE INDEX idx_runs_qc_status ON lims_runs(qc_status);
CREATE INDEX idx_runs_start_time ON lims_runs(run_start_time);

COMMENT ON TABLE lims_runs IS 'Experimental run executions with QC tracking';

-- Run Containers (Many-to-many: runs ↔ containers)
CREATE TABLE lims_run_containers (
    run_container_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    run_id UUID NOT NULL REFERENCES lims_runs(run_id),
    container_id UUID NOT NULL REFERENCES lims_containers(container_id),

    -- Role in run
    container_role TEXT,  -- assay_plate, control_plate, calibration_plate

    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,

    -- Audit
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT run_container_unique UNIQUE (run_id, container_id)
);

CREATE INDEX idx_run_containers_run ON lims_run_containers(run_id);
CREATE INDEX idx_run_containers_container ON lims_run_containers(container_id);

COMMENT ON TABLE lims_run_containers IS 'Association between runs and containers';

-- ============================================================================
-- INSTRUMENTS
-- ============================================================================

-- Instruments (Lab equipment)
CREATE TABLE lims_instruments (
    instrument_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Identity
    instrument_name TEXT NOT NULL,
    instrument_type TEXT NOT NULL,  -- incucyte, plate_reader, microscope
    serial_number TEXT UNIQUE,

    -- Location
    lab_location TEXT,

    -- Configuration
    config JSONB DEFAULT '{}'::jsonb,

    -- Calibration
    last_calibration_date DATE,
    calibration_due_date DATE,
    calibration_status TEXT DEFAULT 'current',

    -- Status
    instrument_status TEXT NOT NULL DEFAULT 'active',

    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,

    -- Audit
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by TEXT NOT NULL,

    -- Constraints
    CONSTRAINT valid_calibration_status CHECK (
        calibration_status IN ('current', 'due', 'overdue', 'not_required')
    ),
    CONSTRAINT valid_instrument_status CHECK (
        instrument_status IN ('active', 'maintenance', 'retired', 'decommissioned')
    )
);

CREATE INDEX idx_instruments_name ON lims_instruments(instrument_name);
CREATE INDEX idx_instruments_type ON lims_instruments(instrument_type);
CREATE INDEX idx_instruments_status ON lims_instruments(instrument_status);
CREATE INDEX idx_instruments_calibration ON lims_instruments(calibration_status);

COMMENT ON TABLE lims_instruments IS 'Laboratory instruments with calibration tracking';

-- Add foreign key now that lims_instruments exists
ALTER TABLE lims_runs
    ADD CONSTRAINT fk_runs_instrument
    FOREIGN KEY (instrument_id) REFERENCES lims_instruments(instrument_id);

-- Instrument Maintenance (Maintenance logs)
CREATE TABLE lims_instrument_maintenance (
    maintenance_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    instrument_id UUID NOT NULL REFERENCES lims_instruments(instrument_id),

    -- Event
    maintenance_type TEXT NOT NULL,  -- calibration, repair, cleaning, upgrade
    maintenance_date DATE NOT NULL,
    performed_by TEXT NOT NULL,

    -- Details
    description TEXT,
    issues_found TEXT,
    actions_taken TEXT,

    -- Status
    status TEXT NOT NULL DEFAULT 'completed',

    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,

    -- Audit
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by TEXT NOT NULL,

    -- Constraints
    CONSTRAINT valid_maintenance_type CHECK (
        maintenance_type IN ('calibration', 'repair', 'cleaning', 'upgrade', 'validation', 'inspection')
    ),
    CONSTRAINT valid_maintenance_status CHECK (
        status IN ('scheduled', 'in_progress', 'completed', 'cancelled')
    )
);

CREATE INDEX idx_instrument_maintenance_instrument ON lims_instrument_maintenance(instrument_id);
CREATE INDEX idx_instrument_maintenance_date ON lims_instrument_maintenance(maintenance_date);
CREATE INDEX idx_instrument_maintenance_type ON lims_instrument_maintenance(maintenance_type);

COMMENT ON TABLE lims_instrument_maintenance IS 'Instrument maintenance and calibration logs';

-- ============================================================================
-- RESULTS & FEATURES
-- ============================================================================

-- Observations (FOV-level data)
CREATE TABLE lims_observations (
    observation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    run_id UUID NOT NULL REFERENCES lims_runs(run_id),
    sample_id UUID NOT NULL REFERENCES lims_samples(sample_id),

    -- Identity
    observation_identifier TEXT NOT NULL,

    -- FOV (Field of View)
    fov_number INTEGER,
    fov_x_position NUMERIC,
    fov_y_position NUMERIC,

    -- Timing
    minutes_from_run_start NUMERIC,
    observation_timestamp TIMESTAMPTZ,

    -- Quality metrics
    cell_count INTEGER,
    snr NUMERIC,  -- Signal-to-noise ratio
    focus_score NUMERIC,

    -- Data locations
    raw_image_path TEXT,
    processed_image_path TEXT,
    analysis_output_path TEXT,

    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,

    -- Audit
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT observation_identifier_unique UNIQUE (run_id, observation_identifier)
);

CREATE INDEX idx_observations_run ON lims_observations(run_id);
CREATE INDEX idx_observations_sample ON lims_observations(sample_id);
CREATE INDEX idx_observations_identifier ON lims_observations(observation_identifier);
CREATE INDEX idx_observations_fov ON lims_observations(run_id, fov_number);

COMMENT ON TABLE lims_observations IS 'FOV-level experimental observations with timing and quality metrics';

-- Feature Definitions (Catalog of all features from data dictionary)
CREATE TABLE lims_feature_definitions (
    feature_definition_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Identity
    feature_name TEXT NOT NULL UNIQUE,
    feature_type TEXT,  -- raw, normalized, computed
    feature_class TEXT,  -- electrophysiology, morphology, intensity

    -- Context
    epoch_type TEXT,  -- spontaneous, evoked
    epoch_number INTEGER,

    -- Description
    description TEXT,
    unit TEXT,

    -- Validation
    min_possible_value NUMERIC,
    max_possible_value NUMERIC,
    expected_range_min NUMERIC,
    expected_range_max NUMERIC,

    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,

    -- Audit
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_feature_definitions_name ON lims_feature_definitions(feature_name);
CREATE INDEX idx_feature_definitions_class ON lims_feature_definitions(feature_class);

COMMENT ON TABLE lims_feature_definitions IS 'Catalog of all features (from data dictionary) with validation ranges';

-- Features (Computed features per observation)
CREATE TABLE lims_features (
    feature_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    observation_id UUID NOT NULL REFERENCES lims_observations(observation_id),
    feature_definition_id UUID NOT NULL REFERENCES lims_feature_definitions(feature_definition_id),

    -- Value
    feature_value NUMERIC,

    -- Quality
    is_outlier BOOLEAN DEFAULT FALSE,
    outlier_reason TEXT,

    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,

    -- Audit
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT feature_observation_definition_unique UNIQUE (observation_id, feature_definition_id)
);

CREATE INDEX idx_features_observation ON lims_features(observation_id);
CREATE INDEX idx_features_definition ON lims_features(feature_definition_id);
CREATE INDEX idx_features_value ON lims_features(feature_value) WHERE feature_value IS NOT NULL;
CREATE INDEX idx_features_outliers ON lims_features(is_outlier) WHERE is_outlier = TRUE;

COMMENT ON TABLE lims_features IS 'Computed feature values per observation (13.2M rows for DFP Phase II)';

-- ============================================================================
-- COMPUTATION & PUBLISHING
-- ============================================================================

-- Compute Recipes (Versioned pipelines)
CREATE TABLE lims_compute_recipes (
    recipe_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Identity
    recipe_name TEXT NOT NULL,
    recipe_version TEXT NOT NULL,

    -- Code
    git_repository TEXT,
    git_commit_hash TEXT,
    git_branch TEXT,

    -- Pipeline
    pipeline_steps JSONB NOT NULL,  -- Array of transformation steps
    parameters JSONB DEFAULT '{}'::jsonb,

    -- Validation
    validated BOOLEAN DEFAULT FALSE,
    validation_date DATE,

    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,

    -- Audit
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by TEXT NOT NULL,

    -- Constraints
    CONSTRAINT recipe_name_version_unique UNIQUE (recipe_name, recipe_version)
);

CREATE INDEX idx_compute_recipes_name ON lims_compute_recipes(recipe_name);
CREATE INDEX idx_compute_recipes_version ON lims_compute_recipes(recipe_name, recipe_version);

COMMENT ON TABLE lims_compute_recipes IS 'Versioned computational pipelines (batch correction, normalization)';

-- Compute Runs (Recipe executions)
CREATE TABLE lims_compute_runs (
    compute_run_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipe_id UUID NOT NULL REFERENCES lims_compute_recipes(recipe_id),

    -- Execution
    compute_run_identifier TEXT NOT NULL UNIQUE,
    executed_by TEXT NOT NULL,
    execution_start TIMESTAMPTZ,
    execution_end TIMESTAMPTZ,

    -- Input/Output
    input_dataset_id UUID,  -- Foreign key added later
    output_dataset_id UUID,  -- Foreign key added later

    -- Performance
    wall_time_seconds NUMERIC,
    cpu_time_seconds NUMERIC,
    memory_peak_mb NUMERIC,

    -- Status
    status TEXT NOT NULL DEFAULT 'pending',
    error_message TEXT,

    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,

    -- Audit
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT valid_compute_run_status CHECK (
        status IN ('pending', 'running', 'completed', 'failed')
    )
);

CREATE INDEX idx_compute_runs_identifier ON lims_compute_runs(compute_run_identifier);
CREATE INDEX idx_compute_runs_recipe ON lims_compute_runs(recipe_id);
CREATE INDEX idx_compute_runs_status ON lims_compute_runs(status);

COMMENT ON TABLE lims_compute_runs IS 'Executions of compute recipes with performance metrics';

-- Datasets (Gold Datasets for Sapphire)
CREATE TABLE lims_datasets (
    dataset_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Identity
    dataset_name TEXT NOT NULL,
    dataset_version TEXT NOT NULL,
    dataset_type TEXT NOT NULL,  -- raw, cleaned, batch_corrected, gold

    -- Scientific context
    title TEXT NOT NULL,
    description TEXT,
    biological_question TEXT,

    -- Provenance
    run_ids UUID[] DEFAULT ARRAY[]::UUID[],  -- Source runs
    protocol_id UUID REFERENCES lims_protocols(protocol_id),

    -- Computation
    compute_run_id UUID REFERENCES lims_compute_runs(compute_run_id),

    -- Quality
    qc_status TEXT NOT NULL DEFAULT 'pending',
    qc_score NUMERIC,
    qc_grade TEXT,
    qc_metrics JSONB DEFAULT '{}'::jsonb,

    -- Data location
    data_format TEXT,  -- parquet, hdf5, zarr, csv
    data_location TEXT,
    data_size_bytes BIGINT,
    checksum_sha256 TEXT,

    -- Relationships
    related_genes TEXT[] DEFAULT ARRAY[]::TEXT[],
    related_drugs TEXT[] DEFAULT ARRAY[]::TEXT[],

    -- Publication
    published BOOLEAN DEFAULT FALSE,
    published_at TIMESTAMPTZ,
    published_by TEXT,

    -- Metadata (Sapphire Contract)
    metadata JSONB DEFAULT '{}'::jsonb,

    -- Audit
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by TEXT NOT NULL,

    -- Constraints
    CONSTRAINT dataset_name_version_unique UNIQUE (dataset_name, dataset_version),
    CONSTRAINT valid_dataset_type CHECK (
        dataset_type IN ('raw', 'cleaned', 'batch_corrected', 'gold', 'derived')
    ),
    CONSTRAINT valid_dataset_qc_status CHECK (
        qc_status IN ('pending', 'passed', 'conditional', 'failed')
    )
);

CREATE INDEX idx_datasets_name ON lims_datasets(dataset_name);
CREATE INDEX idx_datasets_version ON lims_datasets(dataset_name, dataset_version);
CREATE INDEX idx_datasets_type ON lims_datasets(dataset_type);
CREATE INDEX idx_datasets_qc_status ON lims_datasets(qc_status);
CREATE INDEX idx_datasets_published ON lims_datasets(published) WHERE published = TRUE;
CREATE INDEX idx_datasets_genes ON lims_datasets USING gin(related_genes);
CREATE INDEX idx_datasets_drugs ON lims_datasets USING gin(related_drugs);

COMMENT ON TABLE lims_datasets IS 'Gold Datasets for Sapphire with full provenance and QC';

-- Add foreign keys now that lims_datasets exists
ALTER TABLE lims_compute_runs
    ADD CONSTRAINT fk_compute_runs_input_dataset
    FOREIGN KEY (input_dataset_id) REFERENCES lims_datasets(dataset_id);

ALTER TABLE lims_compute_runs
    ADD CONSTRAINT fk_compute_runs_output_dataset
    FOREIGN KEY (output_dataset_id) REFERENCES lims_datasets(dataset_id);

-- Dataset Lineage (Full transformation history)
CREATE TABLE lims_dataset_lineage (
    lineage_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Datasets
    parent_dataset_id UUID NOT NULL REFERENCES lims_datasets(dataset_id),
    child_dataset_id UUID NOT NULL REFERENCES lims_datasets(dataset_id),

    -- Transformation
    transformation_type TEXT NOT NULL,  -- batch_correction, normalization, filtering, aggregation
    compute_run_id UUID REFERENCES lims_compute_runs(compute_run_id),

    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,

    -- Audit
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT lineage_parent_child_unique UNIQUE (parent_dataset_id, child_dataset_id),
    CONSTRAINT no_self_lineage CHECK (parent_dataset_id != child_dataset_id)
);

CREATE INDEX idx_dataset_lineage_parent ON lims_dataset_lineage(parent_dataset_id);
CREATE INDEX idx_dataset_lineage_child ON lims_dataset_lineage(child_dataset_id);
CREATE INDEX idx_dataset_lineage_compute_run ON lims_dataset_lineage(compute_run_id);

COMMENT ON TABLE lims_dataset_lineage IS 'Immutable lineage tracking (raw → cleaned → batch_corrected → gold)';

-- ============================================================================
-- AUDIT & COMPLIANCE
-- ============================================================================

-- Custody Log (Immutable chain-of-custody events)
CREATE TABLE lims_custody_log (
    custody_log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Entity
    entity_type TEXT NOT NULL,  -- sample, batch, aliquot, container, dataset
    entity_id UUID NOT NULL,

    -- Event
    event_type TEXT NOT NULL,  -- created, received, moved, processed, archived, discarded
    event_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Actor
    actor TEXT NOT NULL,  -- User or system performing action
    actor_role TEXT,

    -- Location
    from_location TEXT,
    to_location TEXT,

    -- Details
    event_details JSONB DEFAULT '{}'::jsonb,

    -- Constraints
    CONSTRAINT valid_entity_type CHECK (
        entity_type IN ('sample', 'batch', 'aliquot', 'container', 'dataset', 'run', 'material')
    ),
    CONSTRAINT valid_event_type CHECK (
        event_type IN ('created', 'received', 'moved', 'processed', 'archived', 'discarded', 'state_change', 'qc_update')
    )
);

CREATE INDEX idx_custody_log_entity ON lims_custody_log(entity_type, entity_id);
CREATE INDEX idx_custody_log_timestamp ON lims_custody_log(event_timestamp);
CREATE INDEX idx_custody_log_actor ON lims_custody_log(actor);
CREATE INDEX idx_custody_log_event_type ON lims_custody_log(event_type);

COMMENT ON TABLE lims_custody_log IS 'Immutable audit trail of all entity lifecycle events';

-- Make custody log immutable (append-only)
CREATE ROLE lims_app_role;
REVOKE UPDATE, DELETE ON lims_custody_log FROM lims_app_role;
GRANT SELECT, INSERT ON lims_custody_log TO lims_app_role;

-- ============================================================================
-- AUTOMATIC UPDATED_AT TRIGGER
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to all tables with updated_at column
CREATE TRIGGER update_materials_updated_at BEFORE UPDATE ON lims_materials
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_batches_updated_at BEFORE UPDATE ON lims_batches
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_aliquots_updated_at BEFORE UPDATE ON lims_aliquots
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_containers_updated_at BEFORE UPDATE ON lims_containers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_samples_updated_at BEFORE UPDATE ON lims_samples
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_protocols_updated_at BEFORE UPDATE ON lims_protocols
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_runs_updated_at BEFORE UPDATE ON lims_runs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_instruments_updated_at BEFORE UPDATE ON lims_instruments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_feature_definitions_updated_at BEFORE UPDATE ON lims_feature_definitions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_compute_recipes_updated_at BEFORE UPDATE ON lims_compute_recipes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_datasets_updated_at BEFORE UPDATE ON lims_datasets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- SCHEMA VERSION
-- ============================================================================

CREATE TABLE lims_schema_version (
    version_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version_number TEXT NOT NULL UNIQUE,
    applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    description TEXT
);

INSERT INTO lims_schema_version (version_number, description)
VALUES ('1.0.0', 'Initial LIMS schema with 17 core tables');

-- ============================================================================
-- END OF SCHEMA
-- ============================================================================
