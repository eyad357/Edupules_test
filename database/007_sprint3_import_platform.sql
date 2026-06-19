-- ============================================================================
-- EduGuard AI — Sprint 3 Migration
-- File: database/007_sprint3_import_platform.sql
--
-- Academic Data Import & Validation Platform
-- ALL CHANGES ARE ADDITIVE — no existing tables modified.
-- Safe to run on a live Sprint 1 + Sprint 2 database.
--
-- Tables created:
--   import_batches
--   import_row_errors
--   mapping_templates
--   mapping_template_versions
--   validation_rules
--   validation_results
--   reconciliation_reports
--   reconciliation_items
--   import_audit_events
-- ============================================================================

BEGIN;

-- ── Enum types ───────────────────────────────────────────────────────────────

DO $$ BEGIN
    CREATE TYPE batch_status_enum AS ENUM (
        'pending', 'processing', 'completed', 'failed', 'partially_completed'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE import_type_enum AS ENUM (
        'students', 'transcripts', 'curriculum'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE file_format_enum AS ENUM (
        'csv', 'xlsx', 'json'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE source_system_enum AS ENUM (
        'registrar', 'sis', 'erp', 'curriculum', 'manual', 'api', 'unknown'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE val_severity_enum AS ENUM (
        'error', 'warning', 'info'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE val_category_enum AS ENUM (
        'referential', 'academic', 'curriculum', 'integrity', 'business'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE recon_type_enum AS ENUM (
        'duplicate', 'conflict', 'mismatch'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE recon_status_enum AS ENUM (
        'open', 'resolved', 'ignored'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE audit_event_type_enum AS ENUM (
        'import_started', 'import_completed', 'import_failed',
        'validation_ran', 'reconcile_ran', 'mapping_applied',
        'row_inserted', 'row_failed', 'row_skipped', 'duplicate_blocked'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;


-- ── mapping_templates ─────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS mapping_templates (
    id            BIGSERIAL PRIMARY KEY,
    name          VARCHAR(100)        NOT NULL,
    description   TEXT,
    import_type   import_type_enum    NOT NULL,
    source_system source_system_enum  NOT NULL DEFAULT 'manual',
    is_active     BOOLEAN             NOT NULL DEFAULT TRUE,
    created_by    INTEGER             REFERENCES users(id) ON DELETE SET NULL,
    created_at    TIMESTAMPTZ         NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ         NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_mapping_templates_name_type UNIQUE (name, import_type)
);


-- ── mapping_template_versions ─────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS mapping_template_versions (
    id             BIGSERIAL PRIMARY KEY,
    template_id    BIGINT              NOT NULL REFERENCES mapping_templates(id) ON DELETE CASCADE,
    version_number SMALLINT            NOT NULL,
    field_mappings JSONB               NOT NULL,
    transformations JSONB,
    is_current     BOOLEAN             NOT NULL DEFAULT FALSE,
    published_by   INTEGER             REFERENCES users(id) ON DELETE SET NULL,
    published_at   TIMESTAMPTZ         NOT NULL DEFAULT NOW(),
    notes          TEXT,
    CONSTRAINT uq_mtv_template_version UNIQUE (template_id, version_number)
);

CREATE INDEX IF NOT EXISTS ix_mtv_template_id ON mapping_template_versions (template_id);
CREATE INDEX IF NOT EXISTS ix_mtv_is_current  ON mapping_template_versions (template_id, is_current);


-- ── import_batches ────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS import_batches (
    id                   BIGSERIAL PRIMARY KEY,
    batch_ref            VARCHAR(64)         NOT NULL UNIQUE,
    file_hash            VARCHAR(64)         NOT NULL,
    file_name            VARCHAR(512)        NOT NULL,
    file_size_bytes      BIGINT              NOT NULL DEFAULT 0,
    file_format          file_format_enum    NOT NULL DEFAULT 'csv',
    import_type          import_type_enum    NOT NULL,
    source_system        source_system_enum  NOT NULL DEFAULT 'manual',
    status               batch_status_enum   NOT NULL DEFAULT 'pending',
    total_rows           INTEGER             NOT NULL DEFAULT 0,
    success_rows         INTEGER             NOT NULL DEFAULT 0,
    failed_rows          INTEGER             NOT NULL DEFAULT 0,
    skipped_rows         INTEGER             NOT NULL DEFAULT 0,
    warning_count        INTEGER             NOT NULL DEFAULT 0,
    imported_by          INTEGER             REFERENCES users(id) ON DELETE SET NULL,
    assigned_to          INTEGER             REFERENCES users(id) ON DELETE SET NULL,
    started_at           TIMESTAMPTZ,
    completed_at         TIMESTAMPTZ,
    duration_ms          INTEGER,
    retry_count          SMALLINT            NOT NULL DEFAULT 0,
    is_reprocess         BOOLEAN             NOT NULL DEFAULT FALSE,
    mapping_version_id   BIGINT              REFERENCES mapping_template_versions(id) ON DELETE SET NULL,
    notes                TEXT,
    extra_meta           JSONB,
    created_at           TIMESTAMPTZ         NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ         NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_import_batches_file_hash UNIQUE (file_hash)
);

CREATE INDEX IF NOT EXISTS ix_import_batches_status      ON import_batches (status);
CREATE INDEX IF NOT EXISTS ix_import_batches_import_type ON import_batches (import_type);
CREATE INDEX IF NOT EXISTS ix_import_batches_created_at  ON import_batches (created_at DESC);


-- ── import_row_errors ────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS import_row_errors (
    id            BIGSERIAL PRIMARY KEY,
    batch_id      BIGINT              NOT NULL REFERENCES import_batches(id) ON DELETE CASCADE,
    row_number    INTEGER,
    field_name    VARCHAR(100),
    raw_value     TEXT,
    error_code    VARCHAR(50),
    error_message TEXT                NOT NULL,
    severity      val_severity_enum   NOT NULL DEFAULT 'error',
    category      val_category_enum,
    extra_context JSONB,
    created_at    TIMESTAMPTZ         NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS ix_import_row_errors_batch_id ON import_row_errors (batch_id);
CREATE INDEX IF NOT EXISTS ix_import_row_errors_severity ON import_row_errors (severity);


-- ── validation_rules ──────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS validation_rules (
    id          BIGSERIAL PRIMARY KEY,
    rule_code   VARCHAR(50)         NOT NULL,
    rule_name   VARCHAR(150)        NOT NULL,
    description TEXT,
    category    val_category_enum   NOT NULL,
    import_type import_type_enum,
    severity    val_severity_enum   NOT NULL DEFAULT 'error',
    is_active   BOOLEAN             NOT NULL DEFAULT TRUE,
    rule_config JSONB,
    created_at  TIMESTAMPTZ         NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ         NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_validation_rules_code UNIQUE (rule_code)
);


-- ── validation_results ────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS validation_results (
    id         BIGSERIAL PRIMARY KEY,
    batch_id   BIGINT              NOT NULL REFERENCES import_batches(id) ON DELETE CASCADE,
    row_number INTEGER,
    rule_code  VARCHAR(50),
    field_name VARCHAR(100),
    raw_value  TEXT,
    passed     BOOLEAN             NOT NULL,
    severity   val_severity_enum   NOT NULL DEFAULT 'error',
    message    TEXT,
    created_at TIMESTAMPTZ         NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS ix_validation_results_batch_id ON validation_results (batch_id);
CREATE INDEX IF NOT EXISTS ix_validation_results_passed   ON validation_results (passed);


-- ── reconciliation_reports ────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS reconciliation_reports (
    id               BIGSERIAL PRIMARY KEY,
    batch_id         BIGINT              NOT NULL REFERENCES import_batches(id) ON DELETE CASCADE,
    import_type      import_type_enum    NOT NULL,
    total_checked    INTEGER             NOT NULL DEFAULT 0,
    duplicates_found INTEGER             NOT NULL DEFAULT 0,
    conflicts_found  INTEGER             NOT NULL DEFAULT 0,
    mismatches_found INTEGER             NOT NULL DEFAULT 0,
    summary          JSONB,
    generated_at     TIMESTAMPTZ         NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS ix_recon_reports_batch_id    ON reconciliation_reports (batch_id);
CREATE INDEX IF NOT EXISTS ix_recon_reports_import_type ON reconciliation_reports (import_type);


-- ── reconciliation_items ──────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS reconciliation_items (
    id              BIGSERIAL PRIMARY KEY,
    report_id       BIGINT              NOT NULL REFERENCES reconciliation_reports(id) ON DELETE CASCADE,
    recon_type      recon_type_enum     NOT NULL,
    entity_type     VARCHAR(50),
    entity_key      VARCHAR(255),
    incoming_value  JSONB,
    existing_value  JSONB,
    conflict_fields JSONB,
    status          recon_status_enum   NOT NULL DEFAULT 'open',
    resolved_by     INTEGER             REFERENCES users(id) ON DELETE SET NULL,
    resolved_at     TIMESTAMPTZ,
    resolution_note TEXT,
    created_at      TIMESTAMPTZ         NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS ix_recon_items_report_id ON reconciliation_items (report_id);
CREATE INDEX IF NOT EXISTS ix_recon_items_status    ON reconciliation_items (status);


-- ── import_audit_events ───────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS import_audit_events (
    id         BIGSERIAL PRIMARY KEY,
    batch_id   BIGINT                  NOT NULL REFERENCES import_batches(id) ON DELETE CASCADE,
    event_type audit_event_type_enum   NOT NULL,
    actor_id   INTEGER                 REFERENCES users(id) ON DELETE SET NULL,
    row_number INTEGER,
    message    TEXT,
    payload    JSONB,
    created_at TIMESTAMPTZ             NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS ix_import_audit_batch_id   ON import_audit_events (batch_id);
CREATE INDEX IF NOT EXISTS ix_import_audit_event_type ON import_audit_events (event_type);
CREATE INDEX IF NOT EXISTS ix_import_audit_created_at ON import_audit_events (created_at DESC);


-- ── Seed built-in validation rules ───────────────────────────────────────────

INSERT INTO validation_rules (rule_code, rule_name, description, category, import_type, severity) VALUES
  ('REQ_STUDENT_CODE',    'Student Code Required',         'student_code field must be present and non-empty', 'integrity',   'students',    'error'),
  ('REQ_FULL_NAME',       'Full Name Required',            'full_name field must be present and non-empty',    'integrity',   'students',    'error'),
  ('REQ_COURSE_CODE',     'Course Code Required',          'course_code field must be present and non-empty',  'integrity',   'transcripts', 'error'),
  ('REQ_COURSE_NAME',     'Course Name Required',          'course_name required for curriculum import',       'integrity',   'curriculum',  'error'),
  ('REF_STUDENT_EXISTS',  'Student Exists Check',          'Imported student_code must exist in the DB',       'referential', 'transcripts', 'error'),
  ('REF_COURSE_EXISTS',   'Course Exists Check',           'Imported course_code must exist in the catalog',   'referential', 'transcripts', 'error'),
  ('REF_TERM_EXISTS',     'Term Exists Check',             'Imported term_name must exist in academic_terms',  'referential', 'transcripts', 'warning'),
  ('ACAD_INVALID_GRADE',  'Grade Validity Check',          'grade must be a recognised letter grade',          'academic',    'transcripts', 'error'),
  ('ACAD_INVALID_CREDITS','Credit Hours Range Check',      'credit_hours must be numeric and 0–6',             'academic',    NULL,          'warning'),
  ('ACAD_GPA_OUT_OF_RANGE','GPA Range Check',              'GPA values must be in range 0.0–4.0',              'academic',    NULL,          'warning'),
  ('BIZ_INVALID_EMAIL',   'Email Format Check',            'university_email must contain @',                  'business',    'students',    'warning'),
  ('BIZ_INVALID_ENROLL_YEAR','Enrollment Year Range Check','enrollment_year must be 2000–2030',               'business',    'students',    'warning'),
  ('INT_DUPLICATE_IN_BATCH','Intra-Batch Duplicate Check', 'Same student_code must not appear twice in file',  'integrity',   'students',    'error'),
  ('INT_DUPLICATE_ATTEMPT','Duplicate Attempt in Batch',   'Same student+course+attempt key in one file',      'integrity',   'transcripts', 'error'),
  ('CURR_INVALID_CATEGORY','Curriculum Category Check',    'category must be a valid curriculum category',     'curriculum',  'curriculum',  'warning'),
  ('CURR_INVALID_YEAR',   'Curriculum Year Range Check',   'curriculum_year must be 2010–2030',                'curriculum',  'curriculum',  'warning')
ON CONFLICT (rule_code) DO NOTHING;

COMMIT;
