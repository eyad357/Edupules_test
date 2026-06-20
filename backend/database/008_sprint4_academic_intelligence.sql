-- ============================================================
-- EduGuard AI — Sprint 4 Migration
-- 008_sprint4_academic_intelligence.sql
-- 
-- Creates all Sprint 4 tables.
-- Designed to be idempotent (CREATE TABLE IF NOT EXISTS).
-- Run after 007_sprint3_import_platform.sql
-- ============================================================

BEGIN;

-- ──────────────────────────────────────────────────────────────────────────
-- ENUMS (create if they do not already exist)
-- ──────────────────────────────────────────────────────────────────────────

DO $$ BEGIN
    CREATE TYPE academic_status    AS ENUM ('active','warning','probation','suspended','dismissed','graduated','inactive','leave');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE transcript_type    AS ENUM ('official','unofficial','semester','graduation');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE grad_eligibility   AS ENUM ('eligible','conditionally_eligible','not_eligible');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE honors_level_snap  AS ENUM ('none','pass','good','very_good','excellent','distinction','honors','high_honors');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE honors_level_rec   AS ENUM ('none','pass','good','very_good','excellent','distinction','honors','high_honors');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE risk_level_s4      AS ENUM ('low','medium','high','critical');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE timeline_event_type AS ENUM (
        'enrollment','registration','course_attempt','grade_posted',
        'grade_changed','gpa_recalculated','cgpa_changed','status_changed',
        'transcript_issued','advisor_note','registrar_action',
        'withdrawal','graduation','honors_awarded'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE note_type AS ENUM ('registrar','advisor','academic','flag','decision');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE audit_action AS ENUM (
        'grade_changed','transcript_generated','gpa_recalculated',
        'status_changed','progress_updated','graduation_decision',
        'override_applied','note_added','snapshot_created'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE acad_status_old AS ENUM ('active','warning','probation','suspended','dismissed','graduated','inactive','leave');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE acad_status_new AS ENUM ('active','warning','probation','suspended','dismissed','graduated','inactive','leave');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ──────────────────────────────────────────────────────────────────────────
-- 1. ACADEMIC RULES CONFIG
-- ──────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS academic_rules_config (
    id          BIGSERIAL    PRIMARY KEY,
    program_id  BIGINT       REFERENCES academic_programs(id) ON DELETE CASCADE,
    rule_key    VARCHAR(80)  NOT NULL,
    rule_value  VARCHAR(50)  NOT NULL,
    description TEXT,
    updated_by  INTEGER      REFERENCES users(id) ON DELETE SET NULL,
    updated_at  TIMESTAMPTZ  DEFAULT NOW(),
    created_at  TIMESTAMPTZ  DEFAULT NOW(),
    UNIQUE (program_id, rule_key)
);

-- Seed default rules (idempotent via INSERT ... ON CONFLICT DO NOTHING)
INSERT INTO academic_rules_config (program_id, rule_key, rule_value, description) VALUES
    (NULL, 'min_cgpa_graduation',         '2.00',          'Minimum CGPA required for graduation'),
    (NULL, 'min_cgpa_good_standing',      '2.00',          'CGPA threshold for good academic standing'),
    (NULL, 'min_cgpa_warning',            '1.70',          'CGPA threshold for academic warning'),
    (NULL, 'min_cgpa_probation',          '1.40',          'CGPA threshold for academic probation'),
    (NULL, 'deans_list_term_gpa',         '3.50',          'Term GPA required for Dean''s List'),
    (NULL, 'deans_list_min_credits',      '15',            'Minimum credit hours attempted for Dean''s List'),
    (NULL, 'honors_cgpa',                 '3.50',          'CGPA for Honors at graduation'),
    (NULL, 'high_honors_cgpa',            '3.75',          'CGPA for High Honors at graduation'),
    (NULL, 'distinction_cgpa',            '3.75',          'CGPA for Distinction'),
    (NULL, 'excellent_cgpa',              '3.50',          'CGPA for Excellent classification'),
    (NULL, 'very_good_cgpa',              '3.00',          'CGPA for Very Good classification'),
    (NULL, 'good_standing_cgpa',          '2.50',          'CGPA for Good classification'),
    (NULL, 'total_required_credits',      '134',           'Total credit hours for graduation'),
    (NULL, 'min_elective_credits',        '9',             'Minimum elective credit hours'),
    (NULL, 'min_university_req_credits',  '14',            'Minimum university requirement credits'),
    (NULL, 'min_field_training_credits',  '4',             'Minimum field training credits'),
    (NULL, 'max_repeat_attempts',         '0',             '0 = unlimited course repeats'),
    (NULL, 'repeat_policy',               'all_attempts',  'GPA repeat policy: all_attempts|best|latest'),
    (NULL, 'transcript_expiry_days',      '365',           'Days until transcript verification link expires'),
    (NULL, 'gpa_scale',                   '4.0',           'GPA scale maximum')
ON CONFLICT (program_id, rule_key) DO NOTHING;

-- Seed grade scale (universal — no program_id)
INSERT INTO grade_scale (program_id, letter_grade, min_percentage, max_percentage, grade_points, counts_in_cgpa, is_passing, description) VALUES
    (NULL, 'A+',  97,  100,  4.0, TRUE,  TRUE,  'Outstanding'),
    (NULL, 'A',   93,  96,   4.0, TRUE,  TRUE,  'Excellent'),
    (NULL, 'A-',  90,  92,   3.7, TRUE,  TRUE,  'Excellent Minus'),
    (NULL, 'B+',  87,  89,   3.3, TRUE,  TRUE,  'Very Good Plus'),
    (NULL, 'B',   83,  86,   3.0, TRUE,  TRUE,  'Very Good'),
    (NULL, 'B-',  80,  82,   2.7, TRUE,  TRUE,  'Very Good Minus'),
    (NULL, 'C+',  77,  79,   2.3, TRUE,  TRUE,  'Good Plus'),
    (NULL, 'C',   73,  76,   2.0, TRUE,  TRUE,  'Good'),
    (NULL, 'C-',  70,  72,   1.7, TRUE,  TRUE,  'Good Minus'),
    (NULL, 'D+',  67,  69,   1.3, TRUE,  TRUE,  'Acceptable Plus'),
    (NULL, 'D',   60,  66,   1.0, TRUE,  TRUE,  'Acceptable (Minimum Pass)'),
    (NULL, 'F',   0,   59,   0.0, TRUE,  FALSE, 'Fail'),
    (NULL, 'FL',  0,   0,    0.0, TRUE,  FALSE, 'Fail Late'),
    (NULL, 'W',   0,   0,    0.0, FALSE, FALSE, 'Withdrawal'),
    (NULL, 'I',   0,   0,    0.0, FALSE, FALSE, 'Incomplete'),
    (NULL, 'P',   0,   0,    0.0, FALSE, TRUE,  'Pass (Pass/Fail)'),
    (NULL, 'IP',  0,   0,    0.0, FALSE, FALSE, 'In Progress')
ON CONFLICT (program_id, letter_grade) DO NOTHING;

-- ──────────────────────────────────────────────────────────────────────────
-- 2. SEMESTER SNAPSHOTS
-- ──────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS semester_snapshots (
    id                   BIGSERIAL PRIMARY KEY,
    student_id           INTEGER   NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    term_id              BIGINT    NOT NULL REFERENCES academic_terms(id) ON DELETE RESTRICT,
    version              SMALLINT  NOT NULL DEFAULT 1,
    term_gpa             NUMERIC(4,3) NOT NULL DEFAULT 0,
    cgpa_after_term      NUMERIC(4,3) NOT NULL DEFAULT 0,
    credits_attempted    SMALLINT  DEFAULT 0,
    credits_earned       SMALLINT  DEFAULT 0,
    credits_failed       SMALLINT  DEFAULT 0,
    credits_withdrawn    SMALLINT  DEFAULT 0,
    cumulative_attempted SMALLINT  DEFAULT 0,
    cumulative_earned    SMALLINT  DEFAULT 0,
    academic_standing    academic_status DEFAULT 'active',
    honors_level         honors_level_snap DEFAULT 'none',
    dean_list_eligible   BOOLEAN   DEFAULT FALSE,
    risk_flags           JSONB     DEFAULT '[]',
    snapshot_hash        VARCHAR(64),
    generated_by         INTEGER   REFERENCES users(id) ON DELETE SET NULL,
    generated_at         TIMESTAMPTZ DEFAULT NOW(),
    is_final             BOOLEAN   DEFAULT FALSE
);
CREATE INDEX IF NOT EXISTS idx_snapshot_student_term ON semester_snapshots(student_id, term_id);

-- ──────────────────────────────────────────────────────────────────────────
-- 3. TRANSCRIPT VERSIONS
-- ──────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS transcript_versions (
    id               BIGSERIAL    PRIMARY KEY,
    student_id       INTEGER      NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    version_number   INTEGER      NOT NULL DEFAULT 1,
    transcript_type  transcript_type NOT NULL DEFAULT 'unofficial',
    transcript_data  JSONB        NOT NULL,
    snapshot_hash    VARCHAR(64)  NOT NULL,
    generated_by     INTEGER      REFERENCES users(id) ON DELETE SET NULL,
    generated_at     TIMESTAMPTZ  DEFAULT NOW(),
    reason           TEXT,
    is_current       BOOLEAN      DEFAULT TRUE
);
CREATE INDEX IF NOT EXISTS idx_transcript_student ON transcript_versions(student_id);

-- ──────────────────────────────────────────────────────────────────────────
-- 4. TRANSCRIPT VERIFICATIONS
-- ──────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS transcript_verifications (
    id                  BIGSERIAL    PRIMARY KEY,
    transcript_id       BIGINT       NOT NULL UNIQUE REFERENCES transcript_versions(id) ON DELETE CASCADE,
    verification_code   VARCHAR(20)  NOT NULL UNIQUE,
    verification_token  VARCHAR(128) NOT NULL UNIQUE,
    qr_identifier       VARCHAR(64)  NOT NULL UNIQUE,
    is_valid            BOOLEAN      DEFAULT TRUE,
    expires_at          TIMESTAMPTZ,
    verified_count      INTEGER      DEFAULT 0,
    last_verified_at    TIMESTAMPTZ,
    invalidated_at      TIMESTAMPTZ,
    invalidated_reason  TEXT,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_verif_code ON transcript_verifications(verification_code);

-- ──────────────────────────────────────────────────────────────────────────
-- 5. ACADEMIC TIMELINE EVENTS
-- ──────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS academic_timeline_events (
    id            BIGSERIAL   PRIMARY KEY,
    student_id    INTEGER     NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    term_id       BIGINT      REFERENCES academic_terms(id) ON DELETE SET NULL,
    event_type    timeline_event_type NOT NULL,
    title         VARCHAR(200) NOT NULL,
    description   TEXT,
    payload       JSONB        DEFAULT '{}',
    actor_id      INTEGER      REFERENCES users(id) ON DELETE SET NULL,
    occurred_at   TIMESTAMPTZ  DEFAULT NOW() NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_timeline_student_ts ON academic_timeline_events(student_id, occurred_at DESC);

-- ──────────────────────────────────────────────────────────────────────────
-- 6. ACADEMIC STATUS HISTORY
-- ──────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS academic_status_history (
    id                   BIGSERIAL    PRIMARY KEY,
    student_id           INTEGER      NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    term_id              BIGINT       REFERENCES academic_terms(id) ON DELETE SET NULL,
    old_status           acad_status_old,
    new_status           acad_status_new NOT NULL,
    cgpa_at_change       NUMERIC(4,3),
    term_gpa_at_change   NUMERIC(4,3),
    reason               TEXT,
    actor_id             INTEGER      REFERENCES users(id) ON DELETE SET NULL,
    occurred_at          TIMESTAMPTZ  DEFAULT NOW() NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_status_student ON academic_status_history(student_id);

-- ──────────────────────────────────────────────────────────────────────────
-- 7. DEGREE PROGRESS SNAPSHOTS
-- ──────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS degree_progress_snapshots (
    id                          BIGSERIAL    PRIMARY KEY,
    student_id                  INTEGER      NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    term_id                     BIGINT       REFERENCES academic_terms(id) ON DELETE SET NULL,
    version                     SMALLINT     DEFAULT 1,
    required_credits            SMALLINT     NOT NULL,
    earned_credits              SMALLINT     DEFAULT 0,
    remaining_credits           SMALLINT     DEFAULT 0,
    completion_percentage       NUMERIC(5,2) DEFAULT 0,
    category_breakdown          JSONB        DEFAULT '{}',
    missing_core_courses        JSONB        DEFAULT '[]',
    missing_elective_slots      SMALLINT     DEFAULT 0,
    missing_categories          JSONB        DEFAULT '[]',
    all_core_complete           BOOLEAN      DEFAULT FALSE,
    all_electives_complete      BOOLEAN      DEFAULT FALSE,
    field_training_complete     BOOLEAN      DEFAULT FALSE,
    graduation_project_complete BOOLEAN      DEFAULT FALSE,
    computed_at                 TIMESTAMPTZ  DEFAULT NOW(),
    computed_by                 INTEGER      REFERENCES users(id) ON DELETE SET NULL
);
CREATE INDEX IF NOT EXISTS idx_progress_student ON degree_progress_snapshots(student_id);

-- ──────────────────────────────────────────────────────────────────────────
-- 8. GRADUATION ELIGIBILITY RECORDS
-- ──────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS graduation_eligibility_records (
    id                    BIGSERIAL      PRIMARY KEY,
    student_id            INTEGER        NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    term_id               BIGINT         REFERENCES academic_terms(id) ON DELETE SET NULL,
    eligibility_status    grad_eligibility NOT NULL DEFAULT 'not_eligible',
    requirements_met      JSONB          DEFAULT '{}',
    missing_requirements  JSONB          DEFAULT '[]',
    cgpa_at_evaluation    NUMERIC(4,3),
    credits_at_evaluation SMALLINT,
    evaluated_by          INTEGER        REFERENCES users(id) ON DELETE SET NULL,
    evaluated_at          TIMESTAMPTZ    DEFAULT NOW(),
    notes                 TEXT,
    is_current            BOOLEAN        DEFAULT TRUE
);
CREATE INDEX IF NOT EXISTS idx_grad_elig_student ON graduation_eligibility_records(student_id);

-- ──────────────────────────────────────────────────────────────────────────
-- 9. HONORS RECORDS
-- ──────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS honors_records (
    id                   BIGSERIAL     PRIMARY KEY,
    student_id           INTEGER       NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    term_id              BIGINT        REFERENCES academic_terms(id) ON DELETE SET NULL,
    honors_level         honors_level_rec NOT NULL,
    is_deans_list        BOOLEAN       DEFAULT FALSE,
    term_gpa_used        NUMERIC(4,3),
    cgpa_used            NUMERIC(4,3),
    credits_used         SMALLINT,
    qualification_data   JSONB         DEFAULT '{}',
    awarded_at           TIMESTAMPTZ   DEFAULT NOW(),
    awarded_by           INTEGER       REFERENCES users(id) ON DELETE SET NULL
);
CREATE INDEX IF NOT EXISTS idx_honors_student_term ON honors_records(student_id, term_id);

-- ──────────────────────────────────────────────────────────────────────────
-- 10. GPA PROJECTIONS
-- ──────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS gpa_projections (
    id                      BIGSERIAL     PRIMARY KEY,
    student_id              INTEGER       NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    term_id                 BIGINT        REFERENCES academic_terms(id) ON DELETE SET NULL,
    projection_type         VARCHAR(50)   NOT NULL,
    current_cgpa            NUMERIC(4,3),
    current_credits         SMALLINT,
    target_cgpa             NUMERIC(4,3),
    remaining_credits       SMALLINT,
    scenario_input          JSONB         DEFAULT '{}',
    projection_result       JSONB         DEFAULT '{}',
    projected_semester_gpa  NUMERIC(4,3),
    projected_cgpa          NUMERIC(4,3),
    is_achievable           BOOLEAN,
    computed_at             TIMESTAMPTZ   DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_proj_student ON gpa_projections(student_id);

-- ──────────────────────────────────────────────────────────────────────────
-- 11. ACADEMIC RISK RECORDS
-- ──────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS academic_risk_records (
    id                       BIGSERIAL     PRIMARY KEY,
    student_id               INTEGER       NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    term_id                  BIGINT        REFERENCES academic_terms(id) ON DELETE SET NULL,
    risk_level               risk_level_s4 NOT NULL,
    risk_score               NUMERIC(5,4),
    gpa_trend                NUMERIC(5,4),
    cgpa_trend               NUMERIC(5,4),
    failed_courses_count     SMALLINT      DEFAULT 0,
    repeated_courses_count   SMALLINT      DEFAULT 0,
    withdrawal_count         SMALLINT      DEFAULT 0,
    degree_completion_pct    NUMERIC(5,2),
    risk_factors             JSONB         DEFAULT '[]',
    recommendations          JSONB         DEFAULT '[]',
    assessed_by              VARCHAR(20)   DEFAULT 'system',
    assessed_at              TIMESTAMPTZ   DEFAULT NOW(),
    is_current               BOOLEAN       DEFAULT TRUE
);
CREATE INDEX IF NOT EXISTS idx_risk_student ON academic_risk_records(student_id);

-- ──────────────────────────────────────────────────────────────────────────
-- 12. REGISTRAR NOTES
-- ──────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS registrar_notes (
    id                   BIGSERIAL    PRIMARY KEY,
    student_id           INTEGER      NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    term_id              BIGINT       REFERENCES academic_terms(id) ON DELETE SET NULL,
    note_type            note_type    NOT NULL DEFAULT 'registrar',
    title                VARCHAR(200) NOT NULL,
    content              TEXT         NOT NULL,
    tags                 JSONB        DEFAULT '[]',
    is_private           BOOLEAN      DEFAULT FALSE,
    version              SMALLINT     DEFAULT 1,
    previous_version_id  BIGINT       REFERENCES registrar_notes(id) ON DELETE SET NULL,
    created_by           INTEGER      REFERENCES users(id) ON DELETE SET NULL,
    updated_by           INTEGER      REFERENCES users(id) ON DELETE SET NULL,
    created_at           TIMESTAMPTZ  DEFAULT NOW(),
    updated_at           TIMESTAMPTZ  DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_note_student ON registrar_notes(student_id);
CREATE INDEX IF NOT EXISTS idx_note_search  ON registrar_notes(student_id, note_type);

-- ──────────────────────────────────────────────────────────────────────────
-- 13. ACADEMIC AUDIT ENTRIES
-- ──────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS academic_audit_entries (
    id            BIGSERIAL    PRIMARY KEY,
    student_id    INTEGER      NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    term_id       BIGINT       REFERENCES academic_terms(id) ON DELETE SET NULL,
    action        audit_action NOT NULL,
    entity_type   VARCHAR(50),
    entity_id     BIGINT,
    old_value     JSONB,
    new_value     JSONB,
    reason        TEXT,
    actor_id      INTEGER      REFERENCES users(id) ON DELETE SET NULL,
    actor_role    VARCHAR(20),
    ip_address    VARCHAR(45),
    occurred_at   TIMESTAMPTZ  DEFAULT NOW() NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_audit_student   ON academic_audit_entries(student_id);
CREATE INDEX IF NOT EXISTS idx_audit_actor_ts  ON academic_audit_entries(actor_id, occurred_at DESC);

COMMIT;
