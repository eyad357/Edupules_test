-- ============================================================
-- EduGuard AI — Enterprise Migration
-- 010_enterprise_academic_platform.sql
--
-- Adds 12 new enterprise tables. Idempotent.
-- Run after 009_sprint4_extended_tables.sql
-- ============================================================

BEGIN;

-- ── ENUMS ──────────────────────────────────────────────────────────────────

DO $$ BEGIN CREATE TYPE cohort_status AS ENUM ('active','graduated','delayed','inactive');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE cohort_member_status AS ENUM ('active','graduated','delayed','inactive');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE reg_event_type AS ENUM (
    'registration_created','course_added','course_dropped','withdrawal',
    're_registration','override','approval','registrar_intervention','lock','unlock');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE doc_type AS ENUM (
    'national_id','passport','birth_certificate','high_school_cert',
    'transcript','transfer_document','graduation_document','photo','other');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE doc_status AS ENUM ('pending','verified','rejected','expired');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE case_type AS ENUM (
    'grade_appeal','academic_petition','exception_request','course_waiver',
    'graduation_exception','registration_exception','transfer_credit_appeal');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE case_status AS ENUM ('submitted','under_review','approved','rejected','closed');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE case_decision_from AS ENUM ('submitted','under_review','approved','rejected','closed');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE case_decision_to AS ENUM ('submitted','under_review','approved','rejected','closed');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE transfer_credit_status AS ENUM ('pending','approved','rejected','partial');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE exemption_type AS ENUM ('course_exemption','requirement_exemption','curriculum_exemption');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE exemption_status AS ENUM ('pending','approved','rejected','revoked');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE arv_trigger AS ENUM (
    'grade_change','gpa_recalculation','status_change','progress_update',
    'transcript_issue','graduation_decision','transfer_applied',
    'exemption_applied','registrar_override');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE pdf_job_status AS ENUM ('queued','processing','complete','failed');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE reg_task_type AS ENUM (
    'review_appeal','approve_transfer','review_exemption','approve_transcript',
    'review_exception','pending_override','graduation_review','general');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE task_status AS ENUM ('open','in_progress','complete','cancelled');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE task_priority AS ENUM ('low','medium','high','urgent');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ── 1. STUDENT COHORTS ─────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS student_cohorts (
    id                      BIGSERIAL    PRIMARY KEY,
    program_id              BIGINT       REFERENCES academic_programs(id) ON DELETE SET NULL,
    track_id                BIGINT       REFERENCES academic_tracks(id)   ON DELETE SET NULL,
    cohort_code             VARCHAR(40)  NOT NULL UNIQUE,
    cohort_name             VARCHAR(120),
    intake_year             SMALLINT     NOT NULL,
    intake_semester         VARCHAR(10)  NOT NULL,
    intake_term_id          BIGINT       REFERENCES academic_terms(id) ON DELETE SET NULL,
    expected_grad_term_id   BIGINT       REFERENCES academic_terms(id) ON DELETE SET NULL,
    expected_grad_year      SMALLINT,
    total_semesters_planned SMALLINT     DEFAULT 8,
    status                  cohort_status DEFAULT 'active',
    total_enrolled          INTEGER      DEFAULT 0,
    total_graduated         INTEGER      DEFAULT 0,
    total_delayed           INTEGER      DEFAULT 0,
    total_withdrawn         INTEGER      DEFAULT 0,
    avg_cgpa                NUMERIC(4,3),
    notes                   TEXT,
    created_by              INTEGER      REFERENCES users(id) ON DELETE SET NULL,
    created_at              TIMESTAMPTZ  DEFAULT NOW(),
    updated_at              TIMESTAMPTZ  DEFAULT NOW(),
    UNIQUE (program_id, intake_year, intake_semester)
);

-- ── 2. COHORT MEMBERSHIPS ──────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS cohort_memberships (
    id                  BIGSERIAL         PRIMARY KEY,
    student_id          INTEGER           NOT NULL REFERENCES students(id)        ON DELETE CASCADE,
    cohort_id           BIGINT            NOT NULL REFERENCES student_cohorts(id) ON DELETE CASCADE,
    join_date           DATE,
    expected_grad_date  DATE,
    actual_grad_date    DATE,
    is_delayed          BOOLEAN           DEFAULT FALSE,
    delay_reason        TEXT,
    semesters_completed SMALLINT          DEFAULT 0,
    status              cohort_member_status DEFAULT 'active',
    notes               TEXT,
    created_at          TIMESTAMPTZ       DEFAULT NOW(),
    updated_at          TIMESTAMPTZ       DEFAULT NOW(),
    UNIQUE (student_id, cohort_id)
);
CREATE INDEX IF NOT EXISTS idx_cohort_member ON cohort_memberships(cohort_id, student_id);

-- ── 3. REGISTRATION EVENTS ─────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS registration_events (
    id                BIGSERIAL       PRIMARY KEY,
    student_id        INTEGER         NOT NULL REFERENCES students(id)         ON DELETE CASCADE,
    term_id           BIGINT          NOT NULL REFERENCES academic_terms(id)   ON DELETE RESTRICT,
    course_id         BIGINT          REFERENCES courses(id)                   ON DELETE SET NULL,
    attempt_id        BIGINT          REFERENCES student_course_attempts(id)   ON DELETE SET NULL,
    event_type        reg_event_type  NOT NULL,
    event_detail      TEXT,
    payload           JSONB           DEFAULT '{}',
    requires_approval BOOLEAN         DEFAULT FALSE,
    approved_by       INTEGER         REFERENCES users(id) ON DELETE SET NULL,
    approved_at       TIMESTAMPTZ,
    rejection_reason  TEXT,
    actor_id          INTEGER         REFERENCES users(id) ON DELETE SET NULL,
    actor_role        VARCHAR(30),
    ip_address        VARCHAR(45),
    occurred_at       TIMESTAMPTZ     DEFAULT NOW() NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_reg_event_student_term ON registration_events(student_id, term_id);

COMMENT ON TABLE registration_events IS
'Append-only registration event log. No hard deletes. Every registration action is recorded.';

-- ── 4. STUDENT DOCUMENTS ───────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS student_documents (
    id                  BIGSERIAL    PRIMARY KEY,
    student_id          INTEGER      NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    document_type       doc_type     NOT NULL,
    document_number     VARCHAR(100),
    title               VARCHAR(200) NOT NULL,
    description         TEXT,
    storage_key         VARCHAR(500),
    file_name           VARCHAR(255),
    file_size_bytes     INTEGER,
    mime_type           VARCHAR(100),
    status              doc_status   DEFAULT 'pending',
    verification_status VARCHAR(20)  DEFAULT 'unverified',
    verified_by         INTEGER      REFERENCES users(id) ON DELETE SET NULL,
    verified_at         TIMESTAMPTZ,
    rejection_reason    TEXT,
    issue_date          DATE,
    expiry_date         DATE,
    upload_date         TIMESTAMPTZ  DEFAULT NOW(),
    uploaded_by         INTEGER      REFERENCES users(id) ON DELETE SET NULL,
    revision_history    JSONB        DEFAULT '[]',
    version             SMALLINT     DEFAULT 1,
    is_active           BOOLEAN      DEFAULT TRUE,
    metadata            JSONB        DEFAULT '{}'
);
CREATE INDEX IF NOT EXISTS idx_doc_student_type ON student_documents(student_id, document_type);

-- ── 5. ACADEMIC CASES ──────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS academic_cases (
    id              BIGSERIAL    PRIMARY KEY,
    case_number     VARCHAR(30)  NOT NULL UNIQUE,
    student_id      INTEGER      NOT NULL REFERENCES students(id)               ON DELETE CASCADE,
    term_id         BIGINT       REFERENCES academic_terms(id)                  ON DELETE SET NULL,
    course_id       BIGINT       REFERENCES courses(id)                         ON DELETE SET NULL,
    attempt_id      BIGINT       REFERENCES student_course_attempts(id)         ON DELETE SET NULL,
    case_type       case_type    NOT NULL,
    status          case_status  NOT NULL DEFAULT 'submitted',
    title           VARCHAR(300) NOT NULL,
    description     TEXT         NOT NULL,
    supporting_docs JSONB        DEFAULT '[]',
    assigned_to     INTEGER      REFERENCES users(id) ON DELETE SET NULL,
    assigned_at     TIMESTAMPTZ,
    resolution      TEXT,
    resolved_by     INTEGER      REFERENCES users(id) ON DELETE SET NULL,
    resolved_at     TIMESTAMPTZ,
    priority        VARCHAR(10)  DEFAULT 'medium',
    submitted_by    INTEGER      REFERENCES users(id) ON DELETE SET NULL,
    submitted_at    TIMESTAMPTZ  DEFAULT NOW(),
    due_date        TIMESTAMPTZ,
    closed_at       TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_case_student ON academic_cases(student_id);
CREATE INDEX IF NOT EXISTS idx_case_status  ON academic_cases(status);

-- ── 6. ACADEMIC CASE DECISIONS ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS academic_case_decisions (
    id          BIGSERIAL         PRIMARY KEY,
    case_id     BIGINT            NOT NULL REFERENCES academic_cases(id) ON DELETE CASCADE,
    from_status case_decision_from,
    to_status   case_decision_to  NOT NULL,
    decision    TEXT,
    notes       TEXT,
    decided_by  INTEGER           REFERENCES users(id) ON DELETE SET NULL,
    decided_at  TIMESTAMPTZ       DEFAULT NOW(),
    payload     JSONB             DEFAULT '{}'
);
CREATE INDEX IF NOT EXISTS idx_case_decision ON academic_case_decisions(case_id);

-- ── 7. TRANSFER CREDITS ────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS transfer_credits (
    id                         BIGSERIAL              PRIMARY KEY,
    student_id                 INTEGER                NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    term_id                    BIGINT                 REFERENCES academic_terms(id) ON DELETE SET NULL,
    source_institution         VARCHAR(200)           NOT NULL,
    source_institution_country VARCHAR(80),
    source_course_code         VARCHAR(30)            NOT NULL,
    source_course_name         VARCHAR(200)           NOT NULL,
    source_credit_hours        SMALLINT               NOT NULL,
    source_grade               VARCHAR(5),
    source_grade_points        NUMERIC(4,3),
    source_grade_scale         VARCHAR(20),
    target_course_id           BIGINT                 REFERENCES courses(id) ON DELETE SET NULL,
    target_course_code         VARCHAR(30),
    target_credit_hours        SMALLINT,
    target_grade_points        NUMERIC(4,3),
    counts_in_cgpa             BOOLEAN                DEFAULT FALSE,
    counts_toward_degree       BOOLEAN                DEFAULT TRUE,
    status                     transfer_credit_status DEFAULT 'pending',
    evaluation_notes           TEXT,
    supporting_document_ids    JSONB                  DEFAULT '[]',
    evaluated_by               INTEGER                REFERENCES users(id) ON DELETE SET NULL,
    evaluated_at               TIMESTAMPTZ,
    approved_by                INTEGER                REFERENCES users(id) ON DELETE SET NULL,
    approved_at                TIMESTAMPTZ,
    rejection_reason           TEXT,
    approval_history           JSONB                  DEFAULT '[]',
    submitted_by               INTEGER                REFERENCES users(id) ON DELETE SET NULL,
    submitted_at               TIMESTAMPTZ            DEFAULT NOW(),
    applied_to_record_at       TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_transfer_student ON transfer_credits(student_id);

COMMENT ON COLUMN transfer_credits.counts_in_cgpa IS
'Transfer credits excluded from CGPA by default. No policy document specifies inclusion. Remains PENDING_POLICY_CONFIGURATION.';

-- ── 8. ACADEMIC EXEMPTIONS ─────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS academic_exemptions (
    id               BIGSERIAL         PRIMARY KEY,
    student_id       INTEGER           NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    exemption_type   exemption_type    NOT NULL,
    status           exemption_status  DEFAULT 'pending',
    course_id        BIGINT            REFERENCES courses(id) ON DELETE SET NULL,
    course_code      VARCHAR(20),
    requirement_desc TEXT,
    reason           TEXT              NOT NULL,
    decision_notes   TEXT,
    supporting_doc_ids JSONB           DEFAULT '[]',
    approval_history JSONB             DEFAULT '[]',
    version          SMALLINT          DEFAULT 1,
    requested_by     INTEGER           REFERENCES users(id) ON DELETE SET NULL,
    requested_at     TIMESTAMPTZ       DEFAULT NOW(),
    reviewed_by      INTEGER           REFERENCES users(id) ON DELETE SET NULL,
    reviewed_at      TIMESTAMPTZ,
    approved_by      INTEGER           REFERENCES users(id) ON DELETE SET NULL,
    approved_at      TIMESTAMPTZ,
    revoked_at       TIMESTAMPTZ,
    revoke_reason    TEXT,
    applied_at       TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_exemption_student ON academic_exemptions(student_id);

-- ── 9. ACADEMIC RECORD VERSIONS ────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS academic_record_versions (
    id                    BIGSERIAL    PRIMARY KEY,
    student_id            INTEGER      NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    version_number        INTEGER      NOT NULL,
    trigger               arv_trigger  NOT NULL,
    trigger_detail        TEXT,
    cgpa                  NUMERIC(4,3),
    semester_gpa          NUMERIC(4,3),
    hours_attempted       SMALLINT     DEFAULT 0,
    hours_earned          SMALLINT     DEFAULT 0,
    quality_points        NUMERIC(8,3) DEFAULT 0,
    academic_standing     VARCHAR(20),
    graduation_status     VARCHAR(30),
    degree_completion_pct NUMERIC(5,2),
    record_snapshot       JSONB        NOT NULL,
    snapshot_hash         VARCHAR(64)  NOT NULL,
    is_current            BOOLEAN      DEFAULT TRUE,
    authored_by           INTEGER      REFERENCES users(id) ON DELETE SET NULL,
    authored_at           TIMESTAMPTZ  DEFAULT NOW(),
    notes                 TEXT
);
CREATE INDEX IF NOT EXISTS idx_arv_student ON academic_record_versions(student_id);
CREATE INDEX IF NOT EXISTS idx_arv_current  ON academic_record_versions(student_id, is_current);

COMMENT ON TABLE academic_record_versions IS
'Immutable academic record ledger. Every GPA, standing, progress, or graduation change creates a new version. Records are never overwritten.';

-- ── 10. PDF TRANSCRIPT JOBS ────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS pdf_transcript_jobs (
    id                    BIGSERIAL      PRIMARY KEY,
    student_id            INTEGER        NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    transcript_version_id BIGINT         REFERENCES transcript_versions(id) ON DELETE SET NULL,
    transcript_type       VARCHAR(20)    DEFAULT 'unofficial',
    status                pdf_job_status DEFAULT 'queued',
    page_count            SMALLINT,
    file_size_bytes       INTEGER,
    result_key            VARCHAR(500),
    error_message         TEXT,
    options               JSONB          DEFAULT '{}',
    requested_by          INTEGER        REFERENCES users(id) ON DELETE SET NULL,
    queued_at             TIMESTAMPTZ    DEFAULT NOW(),
    started_at            TIMESTAMPTZ,
    completed_at          TIMESTAMPTZ,
    expires_at            TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_pdf_job_student ON pdf_transcript_jobs(student_id);

-- ── 11. REGISTRAR TASKS ────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS registrar_tasks (
    id               BIGSERIAL       PRIMARY KEY,
    task_number      VARCHAR(30)     NOT NULL UNIQUE,
    task_type        reg_task_type   NOT NULL,
    status           task_status     NOT NULL DEFAULT 'open',
    priority         task_priority   DEFAULT 'medium',
    student_id       INTEGER         REFERENCES students(id)           ON DELETE SET NULL,
    term_id          BIGINT          REFERENCES academic_terms(id)     ON DELETE SET NULL,
    case_id          BIGINT          REFERENCES academic_cases(id)     ON DELETE SET NULL,
    transfer_id      BIGINT          REFERENCES transfer_credits(id)   ON DELETE SET NULL,
    exemption_id     BIGINT          REFERENCES academic_exemptions(id) ON DELETE SET NULL,
    pdf_job_id       BIGINT          REFERENCES pdf_transcript_jobs(id) ON DELETE SET NULL,
    title            VARCHAR(300)    NOT NULL,
    description      TEXT,
    due_date         TIMESTAMPTZ,
    assigned_to      INTEGER         REFERENCES users(id) ON DELETE SET NULL,
    assigned_at      TIMESTAMPTZ,
    completed_by     INTEGER         REFERENCES users(id) ON DELETE SET NULL,
    completed_at     TIMESTAMPTZ,
    resolution_notes TEXT,
    created_by       INTEGER         REFERENCES users(id) ON DELETE SET NULL,
    created_at       TIMESTAMPTZ     DEFAULT NOW(),
    updated_at       TIMESTAMPTZ     DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_reg_task_assignee ON registrar_tasks(assigned_to, status);
CREATE INDEX IF NOT EXISTS idx_reg_task_student  ON registrar_tasks(student_id);

-- ── 12. REGISTRAR TASK ASSIGNMENTS ────────────────────────────────────────

CREATE TABLE IF NOT EXISTS registrar_task_assignments (
    id            BIGSERIAL   PRIMARY KEY,
    task_id       BIGINT      NOT NULL REFERENCES registrar_tasks(id) ON DELETE CASCADE,
    assigned_to   INTEGER     REFERENCES users(id) ON DELETE SET NULL,
    assigned_by   INTEGER     REFERENCES users(id) ON DELETE SET NULL,
    assigned_at   TIMESTAMPTZ DEFAULT NOW(),
    unassigned_at TIMESTAMPTZ,
    notes         TEXT
);
CREATE INDEX IF NOT EXISTS idx_rta_task ON registrar_task_assignments(task_id);

-- ── 13. PREREQUISITE VALIDATIONS ──────────────────────────────────────────

CREATE TABLE IF NOT EXISTS prerequisite_validations (
    id                BIGSERIAL  PRIMARY KEY,
    student_id        INTEGER    NOT NULL REFERENCES students(id)        ON DELETE CASCADE,
    term_id           BIGINT     REFERENCES academic_terms(id)           ON DELETE SET NULL,
    course_id         BIGINT     NOT NULL REFERENCES courses(id)         ON DELETE CASCADE,
    course_code       VARCHAR(20) NOT NULL,
    is_eligible       BOOLEAN    NOT NULL,
    missing_prereqs   JSONB      DEFAULT '[]',
    satisfied_prereqs JSONB      DEFAULT '[]',
    policy_source     VARCHAR(200),
    override_applied  BOOLEAN    DEFAULT FALSE,
    override_by       INTEGER    REFERENCES users(id) ON DELETE SET NULL,
    override_reason   TEXT,
    validated_at      TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_prereq_val_student ON prerequisite_validations(student_id);

COMMIT;
