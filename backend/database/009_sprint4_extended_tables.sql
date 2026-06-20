-- ============================================================
-- EduGuard AI — Sprint 4 Extended Migration
-- 009_sprint4_extended_tables.sql
--
-- Adds:
--   scholarship_evaluations
--   gpa_versions
--   academic_achievements
--   gpa_explanations
--
-- Idempotent — safe to run multiple times.
-- Run after 008_sprint4_academic_intelligence.sql
-- ============================================================

BEGIN;

-- ──────────────────────────────────────────────────────────────────────────
-- ENUMS
-- ──────────────────────────────────────────────────────────────────────────

DO $$ BEGIN
    CREATE TYPE scholarship_status AS ENUM (
        'eligible', 'not_eligible', 'pending_policy_configuration'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE achievement_category AS ENUM (
        'academic_standing', 'course_completion', 'gpa_milestone',
        'degree_progress', 'transcript', 'system'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ──────────────────────────────────────────────────────────────────────────
-- 1. SCHOLARSHIP EVALUATIONS
-- ──────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS scholarship_evaluations (
    id                       BIGSERIAL         PRIMARY KEY,
    student_id               INTEGER           NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    term_id                  BIGINT            REFERENCES academic_terms(id) ON DELETE SET NULL,
    status                   scholarship_status NOT NULL DEFAULT 'pending_policy_configuration',
    cgpa_at_evaluation       NUMERIC(4,3),
    credits_at_evaluation    SMALLINT,
    term_gpa_at_evaluation   NUMERIC(4,3),

    -- All thresholds used in this evaluation (preserves the exact values applied)
    rules_applied            JSONB             DEFAULT '{}',
    -- {"scholarship_min_cgpa": "PENDING_POLICY_CONFIGURATION", ...}

    criteria_met             JSONB             DEFAULT '{}',
    -- {"cgpa_requirement": false, "no_fail_requirement": true, ...}

    unmet_criteria           JSONB             DEFAULT '[]',
    -- ["CGPA: requires ≥ X, current = Y", ...]

    policy_gaps              JSONB             DEFAULT '[]',
    -- List of rule_key strings that returned PENDING_POLICY_CONFIGURATION

    notes                    TEXT,
    evaluated_by             INTEGER           REFERENCES users(id) ON DELETE SET NULL,
    evaluated_at             TIMESTAMPTZ       DEFAULT NOW(),
    is_current               BOOLEAN           DEFAULT TRUE,

    CONSTRAINT chk_scholarship_policy_fields
        CHECK (status != 'eligible' OR jsonb_array_length(policy_gaps) = 0)
);

CREATE INDEX IF NOT EXISTS idx_scholarship_student ON scholarship_evaluations(student_id);
CREATE INDEX IF NOT EXISTS idx_scholarship_current  ON scholarship_evaluations(student_id, is_current);

COMMENT ON TABLE scholarship_evaluations IS
'Scholarship eligibility evaluations. All thresholds sourced from academic_rules_config.
 Status = pending_policy_configuration when required rules are not yet configured.
 No assumed scholarship thresholds are ever used.';

COMMENT ON COLUMN scholarship_evaluations.policy_gaps IS
'List of academic_rules_config keys that returned PENDING_POLICY_CONFIGURATION.
 Empty list = all required rules are configured.';

-- ──────────────────────────────────────────────────────────────────────────
-- 2. GPA VERSIONS
-- ──────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS gpa_versions (
    id                    BIGSERIAL     PRIMARY KEY,
    student_id            INTEGER       NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    term_id               BIGINT        REFERENCES academic_terms(id) ON DELETE SET NULL,
    version_number        INTEGER       NOT NULL DEFAULT 1,

    -- GPA values at this point in time
    semester_gpa          NUMERIC(4,3),
    cgpa                  NUMERIC(4,3),
    total_hours_attempted SMALLINT      DEFAULT 0,
    total_hours_earned    SMALLINT      DEFAULT 0,
    total_quality_points  NUMERIC(8,3)  DEFAULT 0,

    -- Change from previous version
    cgpa_delta            NUMERIC(5,4),   -- positive = improved, negative = dropped
    gpa_delta             NUMERIC(5,4),

    -- What caused this version to be created
    trigger_event         VARCHAR(100),
    -- e.g. 'grade_posted:CSE112', 'term_finalized:2024-S1', 'grade_changed:MAT131'

    trigger_details       JSONB         DEFAULT '{}',
    repeat_policy_used    VARCHAR(30)   DEFAULT 'all_attempts',

    computed_by           INTEGER       REFERENCES users(id) ON DELETE SET NULL,
    recorded_at           TIMESTAMPTZ   DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_gpa_version_student ON gpa_versions(student_id);
CREATE INDEX IF NOT EXISTS idx_gpa_version_ts       ON gpa_versions(student_id, recorded_at DESC);

COMMENT ON TABLE gpa_versions IS
'Immutable GPA version ledger. One row per GPA change event.
 Repeat policy is recorded with each version so historical calculations
 can be reproduced exactly.
 Formula source: CGPA_Calculator.xlsx — verified: 100.70/78 = 1.291025641.';

-- ──────────────────────────────────────────────────────────────────────────
-- 3. ACADEMIC ACHIEVEMENTS
-- ──────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS academic_achievements (
    id               BIGSERIAL            PRIMARY KEY,
    student_id       INTEGER              NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    term_id          BIGINT               REFERENCES academic_terms(id) ON DELETE SET NULL,
    category         achievement_category NOT NULL,
    title            VARCHAR(200)         NOT NULL,
    description      TEXT,

    -- The metric that triggered this achievement
    metric_key       VARCHAR(80),    -- e.g. 'completion_pct', 'cgpa', 'term_gpa'
    metric_value     VARCHAR(50),    -- e.g. '75.0', '3.50'
    threshold_used   VARCHAR(50),    -- exact threshold value from academic_rules_config
    rule_key_used    VARCHAR(80),    -- the rule key that triggered this achievement

    -- Whether this achievement is backed by a document-sourced policy
    -- FALSE = threshold was PENDING_POLICY_CONFIGURATION when achievement was recorded
    policy_sourced   BOOLEAN         DEFAULT TRUE,

    achieved_at      TIMESTAMPTZ     DEFAULT NOW(),
    awarded_by       INTEGER         REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_achievement_student  ON academic_achievements(student_id);
CREATE INDEX IF NOT EXISTS idx_achievement_category ON academic_achievements(student_id, category);

COMMENT ON TABLE academic_achievements IS
'Academic Achievement Registry.
 Only achievements backed by document-sourced policies are recorded with policy_sourced=TRUE.
 Achievements that depend on PENDING thresholds are withheld until rules are configured.
 policy_sourced=FALSE records are flagged for review after rules are configured.';

-- ──────────────────────────────────────────────────────────────────────────
-- 4. GPA EXPLANATIONS
-- ──────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS gpa_explanations (
    id                       BIGSERIAL    PRIMARY KEY,
    student_id               INTEGER      NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    term_id                  BIGINT       REFERENCES academic_terms(id) ON DELETE SET NULL,

    -- The formula used (sourced from academic_rules_config 'cgpa_formula' key)
    formula_description      TEXT         NOT NULL,
    -- Default: "CGPA = Σ(grade_points × credit_hours) / Σ(credit_hours attempted)"
    -- Source: CGPA_Calculator.xlsx — formula verified: 100.70/78 = 1.2910256410

    repeat_policy            VARCHAR(30)  NOT NULL,
    -- Sourced from academic_rules_config 'repeat_policy' key

    -- Full line-item breakdown (one entry per course attempt)
    included_attempts        JSONB        DEFAULT '[]',
    -- [{"attempt_id":1,"course_code":"CSE132","term_code":"S1-2023",
    --   "grade":"B-","grade_points":2.7,"credit_hours":3,"contribution":8.1}, ...]

    excluded_attempts        JSONB        DEFAULT '[]',
    -- [{"course_code":"LAN021","grade":"P","credit_hours":0,
    --   "exclusion_reason":"Pass/Fail excluded from CGPA (source: CGPA_Calculator.xlsx, LAN021 row: 0 CH)"}, ...]

    -- Computed totals
    total_quality_points     NUMERIC(8,3),
    total_hours_attempted    SMALLINT,
    computed_cgpa            NUMERIC(12,10),  -- 10 decimal places for exact verification

    -- Semester-specific (when term_id is provided)
    semester_quality_points  NUMERIC(8,3),
    semester_hours_attempted SMALLINT,
    computed_semester_gpa    NUMERIC(12,10),

    -- Policy sourcing validation
    all_rules_sourced        BOOLEAN      DEFAULT TRUE,
    -- FALSE if any rule used was PENDING_POLICY_CONFIGURATION

    policy_notes             JSONB        DEFAULT '[]',
    -- List of pending rule keys that affected this calculation

    generated_at             TIMESTAMPTZ  DEFAULT NOW(),
    is_current               BOOLEAN      DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_gpa_expl_student ON gpa_explanations(student_id);
CREATE INDEX IF NOT EXISTS idx_gpa_expl_current  ON gpa_explanations(student_id, is_current);

COMMENT ON TABLE gpa_explanations IS
'GPA Audit Explainability Engine.
 Every CGPA calculation is fully traceable to individual course attempt rows.
 Excluded courses have documented, source-cited reasons for exclusion.
 Formula source: CGPA_Calculator.xlsx, verified against calculator output.
 Repeat policy source: academic_rules_config repeat_policy key.';

-- ──────────────────────────────────────────────────────────────────────────
-- UPDATE academic_rules_config: add new rule keys for extended features
-- ──────────────────────────────────────────────────────────────────────────

INSERT INTO academic_rules_config (program_id, rule_key, rule_value, description) VALUES
    -- Document-sourced rules (from uploaded files)
    (NULL, 'cgpa_formula',
     'sum(grade_points*credit_hours)/sum(credit_hours)',
     '[SOURCE: CGPA_Calculator.xlsx — formula verified: 100.70/78=1.2910256410]'),

    (NULL, 'gpa_scale',
     '4.0',
     '[SOURCE: CGPA_Calculator.xlsx — maximum grade points = 4.0 (not shown in file; standard Egyptian university scale)]'),

    -- PENDING rules — awaiting university regulation documents
    (NULL, 'scholarship_min_cgpa',
     'PENDING_POLICY_CONFIGURATION',
     '[PENDING: Not in uploaded documents. Upload university scholarship regulations.]'),

    (NULL, 'scholarship_min_credits',
     'PENDING_POLICY_CONFIGURATION',
     '[PENDING: Not in uploaded documents. Upload university scholarship regulations.]'),

    (NULL, 'scholarship_no_fail_required',
     'PENDING_POLICY_CONFIGURATION',
     '[PENDING: Not in uploaded documents. Upload university scholarship regulations.]'),

    (NULL, 'scholarship_min_term_gpa',
     'PENDING_POLICY_CONFIGURATION',
     '[PENDING: Not in uploaded documents. Upload university scholarship regulations.]'),

    (NULL, 'min_cgpa_graduation',
     'PENDING_POLICY_CONFIGURATION',
     '[PENDING: Not in uploaded documents. Upload university graduation regulations.]'),

    (NULL, 'min_cgpa_good_standing',
     'PENDING_POLICY_CONFIGURATION',
     '[PENDING: Not in uploaded documents. Upload university academic standing regulations.]'),

    (NULL, 'min_cgpa_warning',
     'PENDING_POLICY_CONFIGURATION',
     '[PENDING: Not in uploaded documents. Upload university academic standing regulations.]'),

    (NULL, 'min_cgpa_probation',
     'PENDING_POLICY_CONFIGURATION',
     '[PENDING: Not in uploaded documents. Upload university academic standing regulations.]'),

    (NULL, 'min_cgpa_suspension',
     'PENDING_POLICY_CONFIGURATION',
     '[PENDING: Not in uploaded documents. Upload university academic standing regulations.]'),

    (NULL, 'deans_list_term_gpa',
     'PENDING_POLICY_CONFIGURATION',
     '[PENDING: Not in uploaded documents. Upload university Dean''s List regulations.]'),

    (NULL, 'deans_list_min_credits',
     'PENDING_POLICY_CONFIGURATION',
     '[PENDING: Not in uploaded documents. Upload university Dean''s List regulations.]'),

    (NULL, 'honors_cgpa',
     'PENDING_POLICY_CONFIGURATION',
     '[PENDING: Not in uploaded documents. Upload university honors regulations.]'),

    (NULL, 'high_honors_cgpa',
     'PENDING_POLICY_CONFIGURATION',
     '[PENDING: Not in uploaded documents. Upload university honors regulations.]'),

    (NULL, 'distinction_cgpa',
     'PENDING_POLICY_CONFIGURATION',
     '[PENDING: Not in uploaded documents. Upload university honors regulations.]'),

    (NULL, 'excellent_cgpa',
     'PENDING_POLICY_CONFIGURATION',
     '[PENDING: Not in uploaded documents. Upload university honors regulations.]'),

    (NULL, 'very_good_cgpa',
     'PENDING_POLICY_CONFIGURATION',
     '[PENDING: Not in uploaded documents. Upload university honors regulations.]'),

    (NULL, 'good_standing_cgpa',
     'PENDING_POLICY_CONFIGURATION',
     '[PENDING: Not in uploaded documents. Upload university honors regulations.]'),

    (NULL, 'max_repeat_attempts',
     'PENDING_POLICY_CONFIGURATION',
     '[PENDING: Not in uploaded documents. Upload university repeat course regulations.]'),

    (NULL, 'max_credit_load_per_term',
     'PENDING_POLICY_CONFIGURATION',
     '[PENDING: Not in uploaded documents. Upload university academic load regulations.]'),

    (NULL, 'withdrawal_deadline_weeks',
     'PENDING_POLICY_CONFIGURATION',
     '[PENDING: Not in uploaded documents. Upload university withdrawal regulations.]')

ON CONFLICT (program_id, rule_key) DO NOTHING;

COMMIT;
