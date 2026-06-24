-- ============================================================
-- EduGuard AI — Sprint 5: Student Success & Academic Operations
-- 011_sprint5_student_success.sql
--
-- New tables (idempotent — safe to run multiple times):
--   MODULE A: Configuration Center
--     system_config_categories
--     system_config_settings
--     system_config_audit
--
--   MODULE B: Workflow Engine Extensions
--     workflow_templates
--     workflow_steps
--     workflow_instances
--     workflow_step_instances
--     workflow_sla_rules
--     workflow_analytics_cache
--
--   MODULE C: Academic Calendar Engine
--     academic_years
--     calendar_events
--     calendar_versions
--     calendar_audit
--
--   MODULE D: Student Success Platform
--     student_success_scores
--     student_early_warnings
--     student_interventions_s5
--     student_escalations
--     graduation_readiness_cache
--     advisor_intervention_notes
--     advisor_meetings
--
--   MODULE E: Notification Infrastructure
--     notification_templates      ← schema-reconciled (pre-existing table)
--     notification_queue
--     notification_delivery_log   ← schema-reconciled (pre-existing table)
--     notification_preferences    ← schema-reconciled (pre-existing table)
--
--   MODULE F: Seed Batches
--     seed_batches
--
--   MODULE G/H: Reporting & Retention Analytics
--     report_definitions
--     report_runs
--     retention_snapshots
--
-- Run after: 010_enterprise_academic_platform.sql
--
-- Schema-drift notes:
--   notification_templates, notification_delivery_log, and
--   notification_preferences pre-date Sprint 5 and may exist with
--   an older column set.  MODULE E uses ALTER TABLE … ADD COLUMN IF
--   NOT EXISTS to reconcile both fresh and upgraded installations
--   safely.  All operations are fully idempotent.
-- ============================================================

BEGIN;

-- ── ENUMS ─────────────────────────────────────────────────────────────────────

DO $$ BEGIN CREATE TYPE config_data_type AS ENUM ('string','integer','decimal','boolean','json','text');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE warning_type AS ENUM (
    'low_gpa','low_cgpa','repeated_failure','high_absence','delayed_graduation',
    'probation_risk','dismissal_risk','graduation_risk','missing_prerequisite',
    'credit_deficit','attendance_critical');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE warning_status AS ENUM ('active','acknowledged','resolved','dismissed');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE warning_severity AS ENUM ('info','warning','critical','urgent');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE success_score_band AS ENUM ('excellent','good','warning','critical');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE escalation_level AS ENUM (
    'student','advisor','professor','registrar','academic_affairs','dean');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE escalation_status AS ENUM ('pending','in_progress','resolved','closed');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE readiness_status AS ENUM ('ready','nearly_ready','needs_attention','not_eligible');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE workflow_status AS ENUM ('draft','active','paused','completed','cancelled','rejected');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE workflow_step_type AS ENUM (
    'review','approval','notification','escalation','auto_action','decision');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE calendar_event_type AS ENUM (
    'academic_year_start','academic_year_end','semester_start','semester_end',
    'registration_open','registration_close','add_drop_open','add_drop_close',
    'withdrawal_deadline','exam_period_start','exam_period_end',
    'graduation_deadline','grade_submission_deadline','holiday','other');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE notif_channel AS ENUM ('in_app','email','sms','push');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE notif_delivery_status AS ENUM ('queued','sent','delivered','failed','cancelled');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE report_format AS ENUM ('json','csv','pdf','excel');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE intervention_s5_status AS ENUM (
    'recommended','scheduled','in_progress','completed','cancelled','no_response');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============================================================
-- MODULE A: CONFIGURATION CENTER
-- ============================================================

CREATE TABLE IF NOT EXISTS system_config_categories (
    id           BIGSERIAL    PRIMARY KEY,
    key          VARCHAR(80)  NOT NULL UNIQUE,
    label        VARCHAR(150) NOT NULL,
    description  TEXT,
    icon         VARCHAR(50),
    sort_order   SMALLINT     DEFAULT 0,
    is_active    BOOLEAN      DEFAULT TRUE,
    created_at   TIMESTAMPTZ  DEFAULT NOW(),
    updated_at   TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS system_config_settings (
    id              BIGSERIAL       PRIMARY KEY,
    category_id     BIGINT          REFERENCES system_config_categories(id) ON DELETE CASCADE,
    key             VARCHAR(120)    NOT NULL UNIQUE,
    label           VARCHAR(200)    NOT NULL,
    description     TEXT,
    data_type       config_data_type NOT NULL DEFAULT 'string',
    current_value   TEXT,
    default_value   TEXT,
    min_value       TEXT,
    max_value       TEXT,
    allowed_values  JSONB,
    is_required     BOOLEAN         DEFAULT FALSE,
    is_sensitive    BOOLEAN         DEFAULT FALSE,
    requires_restart BOOLEAN        DEFAULT FALSE,
    program_id      BIGINT          REFERENCES academic_programs(id) ON DELETE CASCADE,
    sort_order      SMALLINT        DEFAULT 0,
    created_at      TIMESTAMPTZ     DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     DEFAULT NOW(),
    updated_by      INTEGER         REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS system_config_audit (
    id            BIGSERIAL    PRIMARY KEY,
    setting_id    BIGINT       REFERENCES system_config_settings(id) ON DELETE CASCADE,
    setting_key   VARCHAR(120) NOT NULL,
    old_value     TEXT,
    new_value     TEXT,
    changed_by    INTEGER      REFERENCES users(id) ON DELETE SET NULL,
    change_reason TEXT,
    rollback_of   BIGINT       REFERENCES system_config_audit(id) ON DELETE SET NULL,
    created_at    TIMESTAMPTZ  DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_config_audit_setting ON system_config_audit(setting_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_config_audit_user    ON system_config_audit(changed_by);

-- ============================================================
-- MODULE B: WORKFLOW ENGINE EXTENSIONS
-- ============================================================

CREATE TABLE IF NOT EXISTS workflow_templates (
    id               BIGSERIAL    PRIMARY KEY,
    name             VARCHAR(150) NOT NULL,
    description      TEXT,
    case_type        VARCHAR(80),
    is_active        BOOLEAN      DEFAULT TRUE,
    max_days_sla     SMALLINT,
    auto_escalate    BOOLEAN      DEFAULT FALSE,
    version          SMALLINT     DEFAULT 1,
    created_by       INTEGER      REFERENCES users(id) ON DELETE SET NULL,
    created_at       TIMESTAMPTZ  DEFAULT NOW(),
    updated_at       TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS workflow_steps (
    id               BIGSERIAL          PRIMARY KEY,
    template_id      BIGINT             REFERENCES workflow_templates(id) ON DELETE CASCADE,
    step_number      SMALLINT           NOT NULL,
    name             VARCHAR(150)       NOT NULL,
    step_type        workflow_step_type NOT NULL,
    assigned_role    VARCHAR(50),
    sla_hours        SMALLINT,
    auto_approve_after_hours SMALLINT,
    notification_template_key VARCHAR(80),
    conditions       JSONB,
    actions          JSONB,
    is_optional      BOOLEAN            DEFAULT FALSE,
    created_at       TIMESTAMPTZ        DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS workflow_instances (
    id               BIGSERIAL       PRIMARY KEY,
    template_id      BIGINT          REFERENCES workflow_templates(id) ON DELETE SET NULL,
    case_id          BIGINT          REFERENCES academic_cases(id) ON DELETE CASCADE,
    student_id       INTEGER         REFERENCES students(id) ON DELETE CASCADE,
    current_step     SMALLINT        DEFAULT 1,
    status           workflow_status DEFAULT 'active',
    metadata         JSONB,
    started_at       TIMESTAMPTZ     DEFAULT NOW(),
    due_at           TIMESTAMPTZ,
    completed_at     TIMESTAMPTZ,
    created_by       INTEGER         REFERENCES users(id) ON DELETE SET NULL,
    created_at       TIMESTAMPTZ     DEFAULT NOW(),
    updated_at       TIMESTAMPTZ     DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS workflow_step_instances (
    id               BIGSERIAL       PRIMARY KEY,
    instance_id      BIGINT          REFERENCES workflow_instances(id) ON DELETE CASCADE,
    step_id          BIGINT          REFERENCES workflow_steps(id) ON DELETE SET NULL,
    step_number      SMALLINT        NOT NULL,
    step_name        VARCHAR(150),
    assigned_to      INTEGER         REFERENCES users(id) ON DELETE SET NULL,
    assigned_role    VARCHAR(50),
    status           workflow_status DEFAULT 'active',
    decision         VARCHAR(50),
    notes            TEXT,
    started_at       TIMESTAMPTZ,
    due_at           TIMESTAMPTZ,
    completed_at     TIMESTAMPTZ,
    response_time_hours NUMERIC(8,2),
    created_at       TIMESTAMPTZ     DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS workflow_sla_rules (
    id               BIGSERIAL    PRIMARY KEY,
    case_type        VARCHAR(80),
    role             VARCHAR(50),
    max_hours        SMALLINT     NOT NULL,
    escalate_to_role VARCHAR(50),
    is_active        BOOLEAN      DEFAULT TRUE,
    created_at       TIMESTAMPTZ  DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_workflow_instances_case      ON workflow_instances(case_id);
CREATE INDEX IF NOT EXISTS idx_workflow_instances_student   ON workflow_instances(student_id);
CREATE INDEX IF NOT EXISTS idx_workflow_step_inst_instance  ON workflow_step_instances(instance_id);

-- ============================================================
-- MODULE C: ACADEMIC CALENDAR ENGINE
-- ============================================================

CREATE TABLE IF NOT EXISTS academic_years (
    id           BIGSERIAL    PRIMARY KEY,
    label        VARCHAR(50)  NOT NULL UNIQUE,  -- e.g. "2024/2025"
    start_date   DATE         NOT NULL,
    end_date     DATE         NOT NULL,
    is_current   BOOLEAN      DEFAULT FALSE,
    is_active    BOOLEAN      DEFAULT TRUE,
    notes        TEXT,
    created_by   INTEGER      REFERENCES users(id) ON DELETE SET NULL,
    created_at   TIMESTAMPTZ  DEFAULT NOW(),
    updated_at   TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS calendar_events (
    id               BIGSERIAL           PRIMARY KEY,
    academic_year_id BIGINT              REFERENCES academic_years(id) ON DELETE CASCADE,
    term_id          BIGINT              REFERENCES academic_terms(id) ON DELETE SET NULL,
    event_type       calendar_event_type NOT NULL,
    label            VARCHAR(200)        NOT NULL,
    description      TEXT,
    start_date       DATE                NOT NULL,
    end_date         DATE,
    affects_all_programs BOOLEAN         DEFAULT TRUE,
    program_id       BIGINT              REFERENCES academic_programs(id) ON DELETE CASCADE,
    is_active        BOOLEAN             DEFAULT TRUE,
    metadata         JSONB,
    created_by       INTEGER             REFERENCES users(id) ON DELETE SET NULL,
    created_at       TIMESTAMPTZ         DEFAULT NOW(),
    updated_at       TIMESTAMPTZ         DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS calendar_versions (
    id               BIGSERIAL    PRIMARY KEY,
    academic_year_id BIGINT       REFERENCES academic_years(id) ON DELETE CASCADE,
    version_number   SMALLINT     NOT NULL,
    snapshot         JSONB        NOT NULL,
    notes            TEXT,
    created_by       INTEGER      REFERENCES users(id) ON DELETE SET NULL,
    created_at       TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS calendar_audit (
    id               BIGSERIAL    PRIMARY KEY,
    event_id         BIGINT       REFERENCES calendar_events(id) ON DELETE CASCADE,
    action           VARCHAR(50)  NOT NULL,
    old_data         JSONB,
    new_data         JSONB,
    changed_by       INTEGER      REFERENCES users(id) ON DELETE SET NULL,
    created_at       TIMESTAMPTZ  DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_calendar_events_year  ON calendar_events(academic_year_id);
CREATE INDEX IF NOT EXISTS idx_calendar_events_dates ON calendar_events(start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_calendar_events_type  ON calendar_events(event_type);

-- ============================================================
-- MODULE D: STUDENT SUCCESS PLATFORM
-- ============================================================

-- D1 Early Warning System
CREATE TABLE IF NOT EXISTS student_early_warnings (
    id               BIGSERIAL        PRIMARY KEY,
    student_id       INTEGER          REFERENCES students(id) ON DELETE CASCADE,
    warning_type     warning_type     NOT NULL,
    severity         warning_severity NOT NULL DEFAULT 'warning',
    status           warning_status   NOT NULL DEFAULT 'active',
    title            VARCHAR(200)     NOT NULL,
    description      TEXT,
    triggered_value  NUMERIC(8,3),
    threshold_value  NUMERIC(8,3),
    term_id          BIGINT           REFERENCES academic_terms(id) ON DELETE SET NULL,
    course_id        INTEGER          REFERENCES courses(id) ON DELETE SET NULL,
    auto_generated   BOOLEAN          DEFAULT TRUE,
    acknowledged_by  INTEGER          REFERENCES users(id) ON DELETE SET NULL,
    acknowledged_at  TIMESTAMPTZ,
    resolved_at      TIMESTAMPTZ,
    resolution_notes TEXT,
    metadata         JSONB,
    created_at       TIMESTAMPTZ      DEFAULT NOW(),
    updated_at       TIMESTAMPTZ      DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_early_warnings_student  ON student_early_warnings(student_id, status);
CREATE INDEX IF NOT EXISTS idx_early_warnings_severity ON student_early_warnings(severity, status);
CREATE INDEX IF NOT EXISTS idx_early_warnings_type     ON student_early_warnings(warning_type);

-- D2 Student Success Score
CREATE TABLE IF NOT EXISTS student_success_scores (
    id                      BIGSERIAL          PRIMARY KEY,
    student_id              INTEGER            REFERENCES students(id) ON DELETE CASCADE,
    term_id                 BIGINT             REFERENCES academic_terms(id) ON DELETE SET NULL,
    score                   NUMERIC(5,2)       NOT NULL CHECK (score >= 0 AND score <= 100),
    band                    success_score_band NOT NULL,
    -- Component scores (0-100 each)
    cgpa_score              NUMERIC(5,2)       DEFAULT 0,
    attendance_score        NUMERIC(5,2)       DEFAULT 0,
    course_completion_score NUMERIC(5,2)       DEFAULT 0,
    progress_score          NUMERIC(5,2)       DEFAULT 0,
    risk_score              NUMERIC(5,2)       DEFAULT 0,
    -- Context
    active_warnings         SMALLINT           DEFAULT 0,
    active_interventions    SMALLINT           DEFAULT 0,
    trend                   VARCHAR(20)        DEFAULT 'stable',  -- improving, declining, stable
    notes                   TEXT,
    computed_at             TIMESTAMPTZ        DEFAULT NOW(),
    created_at              TIMESTAMPTZ        DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_success_scores_student ON student_success_scores(student_id, computed_at DESC);
CREATE INDEX IF NOT EXISTS idx_success_scores_band    ON student_success_scores(band);

-- D4 Graduation Readiness Cache
CREATE TABLE IF NOT EXISTS graduation_readiness_cache (
    id                        BIGSERIAL        PRIMARY KEY,
    student_id                INTEGER          REFERENCES students(id) ON DELETE CASCADE UNIQUE,
    readiness_pct             NUMERIC(5,2)     NOT NULL DEFAULT 0,
    status                    readiness_status NOT NULL DEFAULT 'not_eligible',
    total_required_credits    SMALLINT         DEFAULT 0,
    completed_credits         SMALLINT         DEFAULT 0,
    remaining_credits         SMALLINT         DEFAULT 0,
    total_required_courses    SMALLINT         DEFAULT 0,
    completed_courses         SMALLINT         DEFAULT 0,
    missing_required          JSONB,           -- list of missing course codes
    cgpa_eligible             BOOLEAN          DEFAULT FALSE,
    uc_requirements_met       BOOLEAN          DEFAULT FALSE,
    pending_issues            JSONB,
    estimated_graduation_term VARCHAR(20),
    computed_at               TIMESTAMPTZ      DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_grad_readiness_status ON graduation_readiness_cache(status);

-- D5 Intervention Engine (Sprint 5 layer — extends existing)
CREATE TABLE IF NOT EXISTS student_interventions_s5 (
    id                   BIGSERIAL              PRIMARY KEY,
    student_id           INTEGER                REFERENCES students(id) ON DELETE CASCADE,
    warning_id           BIGINT                 REFERENCES student_early_warnings(id) ON DELETE SET NULL,
    assigned_to          INTEGER                REFERENCES users(id) ON DELETE SET NULL,
    status               intervention_s5_status NOT NULL DEFAULT 'recommended',
    intervention_type    VARCHAR(80)            NOT NULL,
    title                VARCHAR(200)           NOT NULL,
    description          TEXT,
    recommendations      JSONB,                 -- computed recommendations
    target_gpa           NUMERIC(4,3),
    target_cgpa          NUMERIC(4,3),
    marks_needed         JSONB,                 -- per-course marks needed
    required_next_gpa    NUMERIC(4,3),
    graduation_path      JSONB,
    priority             VARCHAR(20)            DEFAULT 'medium',
    due_date             DATE,
    completed_at         TIMESTAMPTZ,
    outcome              TEXT,
    created_by           INTEGER                REFERENCES users(id) ON DELETE SET NULL,
    created_at           TIMESTAMPTZ            DEFAULT NOW(),
    updated_at           TIMESTAMPTZ            DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_interventions_s5_student  ON student_interventions_s5(student_id, status);
CREATE INDEX IF NOT EXISTS idx_interventions_s5_assigned ON student_interventions_s5(assigned_to);

-- D7 Escalation Engine
CREATE TABLE IF NOT EXISTS student_escalations (
    id                   BIGSERIAL         PRIMARY KEY,
    student_id           INTEGER           REFERENCES students(id) ON DELETE CASCADE,
    warning_id           BIGINT            REFERENCES student_early_warnings(id) ON DELETE SET NULL,
    intervention_id      BIGINT            REFERENCES student_interventions_s5(id) ON DELETE SET NULL,
    from_level           escalation_level  NOT NULL,
    to_level             escalation_level  NOT NULL,
    reason               TEXT              NOT NULL,
    status               escalation_status DEFAULT 'pending',
    escalated_by         INTEGER           REFERENCES users(id) ON DELETE SET NULL,
    assigned_to          INTEGER           REFERENCES users(id) ON DELETE SET NULL,
    response_notes       TEXT,
    responded_at         TIMESTAMPTZ,
    resolved_at          TIMESTAMPTZ,
    response_time_hours  NUMERIC(8,2),
    metadata             JSONB,
    created_at           TIMESTAMPTZ       DEFAULT NOW(),
    updated_at           TIMESTAMPTZ       DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_escalations_student  ON student_escalations(student_id, status);
CREATE INDEX IF NOT EXISTS idx_escalations_assigned ON student_escalations(assigned_to);

-- D8 Advisor / TA Platform
CREATE TABLE IF NOT EXISTS advisor_intervention_notes (
    id               BIGSERIAL    PRIMARY KEY,
    intervention_id  BIGINT       REFERENCES student_interventions_s5(id) ON DELETE CASCADE,
    student_id       INTEGER      REFERENCES students(id) ON DELETE CASCADE,
    author_id        INTEGER      REFERENCES users(id) ON DELETE SET NULL,
    note_type        VARCHAR(50)  DEFAULT 'general',  -- follow_up, meeting, phone, email
    content          TEXT         NOT NULL,
    is_private       BOOLEAN      DEFAULT FALSE,
    created_at       TIMESTAMPTZ  DEFAULT NOW(),
    updated_at       TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS advisor_meetings (
    id               BIGSERIAL    PRIMARY KEY,
    student_id       INTEGER      REFERENCES students(id) ON DELETE CASCADE,
    advisor_id       INTEGER      REFERENCES users(id) ON DELETE SET NULL,
    intervention_id  BIGINT       REFERENCES student_interventions_s5(id) ON DELETE SET NULL,
    meeting_type     VARCHAR(50)  DEFAULT 'in_person',  -- in_person, online, phone
    scheduled_at     TIMESTAMPTZ  NOT NULL,
    duration_minutes SMALLINT,
    status           VARCHAR(30)  DEFAULT 'scheduled',  -- scheduled, completed, cancelled, no_show
    notes            TEXT,
    outcomes         JSONB,
    follow_up_date   DATE,
    created_at       TIMESTAMPTZ  DEFAULT NOW(),
    updated_at       TIMESTAMPTZ  DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_advisor_meetings_student    ON advisor_meetings(student_id);
CREATE INDEX IF NOT EXISTS idx_advisor_meetings_advisor    ON advisor_meetings(advisor_id);
CREATE INDEX IF NOT EXISTS idx_advisor_notes_intervention  ON advisor_intervention_notes(intervention_id);

-- ============================================================
-- MODULE E: NOTIFICATION INFRASTRUCTURE
-- ============================================================
--
-- SCHEMA RECONCILIATION
-- ---------------------
-- notification_templates, notification_delivery_log, and
-- notification_preferences were created before Sprint 5 with a
-- narrower column set.  PostgreSQL's "CREATE TABLE IF NOT EXISTS"
-- silently skips recreation when the table already exists, which
-- means newly required columns are never added on upgraded
-- databases.
--
-- The blocks below use ALTER TABLE … ADD COLUMN IF NOT EXISTS to
-- guarantee every Sprint 5 column is present, regardless of
-- whether the table was just created or has existed since a
-- prior sprint.  Every ALTER is idempotent; re-running this
-- migration is always safe.
-- ============================================================

-- ── E0: Create notification_queue FIRST so the delivery-log FK resolves ──────

CREATE TABLE IF NOT EXISTS notification_queue (
    id               BIGSERIAL             PRIMARY KEY,
    recipient_id     INTEGER               REFERENCES users(id) ON DELETE CASCADE,
    template_id      BIGINT,               -- FK added below after notification_templates is reconciled
    channel          notif_channel         NOT NULL DEFAULT 'in_app',
    subject          TEXT,
    body             TEXT                  NOT NULL,
    variables        JSONB,
    priority         VARCHAR(20)           DEFAULT 'normal',
    status           notif_delivery_status DEFAULT 'queued',
    scheduled_at     TIMESTAMPTZ           DEFAULT NOW(),
    sent_at          TIMESTAMPTZ,
    retry_count      SMALLINT              DEFAULT 0,
    max_retries      SMALLINT              DEFAULT 3,
    error_message    TEXT,
    related_entity   VARCHAR(50),
    related_id       BIGINT,
    created_at       TIMESTAMPTZ           DEFAULT NOW(),
    updated_at       TIMESTAMPTZ           DEFAULT NOW()
);

-- ── E1: Reconcile notification_templates ──────────────────────────────────────
--
-- Sprint 5 full schema:
--   id               BIGSERIAL    PK
--   key              VARCHAR(100) NOT NULL UNIQUE   ← new; used by seed inserts
--   name             VARCHAR(200) NOT NULL
--   channel          notif_channel DEFAULT 'in_app' ← new ENUM column
--   subject_template TEXT                           ← new
--   body_template    TEXT NOT NULL                  ← new (was possibly absent or named differently)
--   variables        JSONB                          ← new
--   is_active        BOOLEAN DEFAULT TRUE           ← new
--   created_at       TIMESTAMPTZ DEFAULT NOW()
--   updated_at       TIMESTAMPTZ DEFAULT NOW()      ← new

CREATE TABLE IF NOT EXISTS notification_templates (
    id               BIGSERIAL     PRIMARY KEY,
    key              VARCHAR(100)  NOT NULL UNIQUE,
    name             VARCHAR(200)  NOT NULL,
    channel          notif_channel NOT NULL DEFAULT 'in_app',
    subject_template TEXT,
    body_template    TEXT          NOT NULL,
    variables        JSONB,
    is_active        BOOLEAN       DEFAULT TRUE,
    created_at       TIMESTAMPTZ   DEFAULT NOW(),
    updated_at       TIMESTAMPTZ   DEFAULT NOW()
);

-- Reconcile columns for databases where the table already existed.
-- Each ADD COLUMN IF NOT EXISTS is a no-op when the column is present.
DO $$
BEGIN
    -- key: the unique business identifier used by all seed inserts and FK references
    ALTER TABLE notification_templates
        ADD COLUMN IF NOT EXISTS key VARCHAR(100);

    -- Apply NOT NULL + default only when the column was just added (i.e. values are NULL).
    -- We back-fill with a generated placeholder so the constraint is satisfiable.
    UPDATE notification_templates
    SET key = 'legacy_' || id::TEXT
    WHERE key IS NULL;

    -- Now enforce NOT NULL (safe because we just filled every NULL row).
    ALTER TABLE notification_templates
        ALTER COLUMN key SET NOT NULL;

    -- Add the UNIQUE constraint only if it does not already exist.
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conrelid = 'notification_templates'::regclass
          AND contype   = 'u'
          AND conname   = 'notification_templates_key_key'
    ) THEN
        ALTER TABLE notification_templates
            ADD CONSTRAINT notification_templates_key_key UNIQUE (key);
    END IF;

    -- channel: notif_channel ENUM column
    ALTER TABLE notification_templates
        ADD COLUMN IF NOT EXISTS channel notif_channel NOT NULL DEFAULT 'in_app';

    -- subject_template: nullable, for email subjects
    ALTER TABLE notification_templates
        ADD COLUMN IF NOT EXISTS subject_template TEXT;

    -- body_template: the notification body; back-fill from any existing body-like column
    ALTER TABLE notification_templates
        ADD COLUMN IF NOT EXISTS body_template TEXT;

    UPDATE notification_templates
    SET body_template = ''
    WHERE body_template IS NULL;

    ALTER TABLE notification_templates
        ALTER COLUMN body_template SET NOT NULL;

    -- variables: JSONB list of template variable names
    ALTER TABLE notification_templates
        ADD COLUMN IF NOT EXISTS variables JSONB;

    -- is_active: soft-delete / enable flag
    ALTER TABLE notification_templates
        ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;

    -- updated_at: audit timestamp
    ALTER TABLE notification_templates
        ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
END;
$$;

-- ── E2: Add FK from notification_queue → notification_templates ───────────────
--   The FK could not be declared inline above because notification_templates
--   may not have existed yet.  We add it here, idempotently.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conrelid = 'notification_queue'::regclass
          AND conname   = 'notification_queue_template_id_fkey'
    ) THEN
        ALTER TABLE notification_queue
            ADD CONSTRAINT notification_queue_template_id_fkey
            FOREIGN KEY (template_id)
            REFERENCES notification_templates(id)
            ON DELETE SET NULL;
    END IF;
END;
$$;

-- ── E3: Reconcile notification_delivery_log ───────────────────────────────────
--
-- Sprint 5 full schema:
--   id                   BIGSERIAL  PK
--   queue_id             BIGINT     FK → notification_queue(id)  ← new (was root cause of round-1 error)
--   channel              notif_channel NOT NULL                  ← may be missing
--   status               notif_delivery_status NOT NULL          ← may be missing
--   provider             VARCHAR(50)                             ← new
--   provider_message_id  VARCHAR(200)                            ← new
--   error_details        TEXT                                    ← new
--   attempt_number       SMALLINT DEFAULT 1                      ← new
--   attempted_at         TIMESTAMPTZ DEFAULT NOW()               ← new

CREATE TABLE IF NOT EXISTS notification_delivery_log (
    id                   BIGSERIAL             PRIMARY KEY,
    queue_id             BIGINT                REFERENCES notification_queue(id) ON DELETE CASCADE,
    channel              notif_channel         NOT NULL,
    status               notif_delivery_status NOT NULL,
    provider             VARCHAR(50),
    provider_message_id  VARCHAR(200),
    error_details        TEXT,
    attempt_number       SMALLINT              DEFAULT 1,
    attempted_at         TIMESTAMPTZ           DEFAULT NOW()
);

DO $$
BEGIN
    -- queue_id: FK to notification_queue; add column then constraint separately
    ALTER TABLE notification_delivery_log
        ADD COLUMN IF NOT EXISTS queue_id BIGINT;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conrelid = 'notification_delivery_log'::regclass
          AND conname   = 'notification_delivery_log_queue_id_fkey'
    ) THEN
        ALTER TABLE notification_delivery_log
            ADD CONSTRAINT notification_delivery_log_queue_id_fkey
            FOREIGN KEY (queue_id)
            REFERENCES notification_queue(id)
            ON DELETE CASCADE;
    END IF;

    -- channel: notif_channel ENUM; use TEXT as transit type then cast
    ALTER TABLE notification_delivery_log
        ADD COLUMN IF NOT EXISTS channel notif_channel;

    -- status: notif_delivery_status ENUM
    ALTER TABLE notification_delivery_log
        ADD COLUMN IF NOT EXISTS status notif_delivery_status;

    -- provider: external delivery provider name
    ALTER TABLE notification_delivery_log
        ADD COLUMN IF NOT EXISTS provider VARCHAR(50);

    -- provider_message_id: message ID returned by external provider
    ALTER TABLE notification_delivery_log
        ADD COLUMN IF NOT EXISTS provider_message_id VARCHAR(200);

    -- error_details: full error payload on failed deliveries
    ALTER TABLE notification_delivery_log
        ADD COLUMN IF NOT EXISTS error_details TEXT;

    -- attempt_number: which retry attempt this row records
    ALTER TABLE notification_delivery_log
        ADD COLUMN IF NOT EXISTS attempt_number SMALLINT DEFAULT 1;

    -- attempted_at: wall-clock time of the delivery attempt
    ALTER TABLE notification_delivery_log
        ADD COLUMN IF NOT EXISTS attempted_at TIMESTAMPTZ DEFAULT NOW();
END;
$$;

-- ── E4: Reconcile notification_preferences ────────────────────────────────────
--
-- Sprint 5 full schema adds seven preference columns and updated_at
-- to what was previously a simpler channel-toggle table.

CREATE TABLE IF NOT EXISTS notification_preferences (
    id                   BIGSERIAL    PRIMARY KEY,
    user_id              INTEGER      REFERENCES users(id) ON DELETE CASCADE UNIQUE,
    in_app_enabled       BOOLEAN      DEFAULT TRUE,
    email_enabled        BOOLEAN      DEFAULT TRUE,
    sms_enabled          BOOLEAN      DEFAULT FALSE,
    push_enabled         BOOLEAN      DEFAULT FALSE,
    warning_alerts       BOOLEAN      DEFAULT TRUE,
    intervention_alerts  BOOLEAN      DEFAULT TRUE,
    grade_alerts         BOOLEAN      DEFAULT TRUE,
    calendar_alerts      BOOLEAN      DEFAULT TRUE,
    digest_frequency     VARCHAR(20)  DEFAULT 'daily',  -- realtime, daily, weekly
    quiet_hours_start    TIME,
    quiet_hours_end      TIME,
    created_at           TIMESTAMPTZ  DEFAULT NOW(),
    updated_at           TIMESTAMPTZ  DEFAULT NOW()
);

ALTER TABLE notification_preferences
    ADD COLUMN IF NOT EXISTS warning_alerts      BOOLEAN     DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS intervention_alerts BOOLEAN     DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS grade_alerts        BOOLEAN     DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS calendar_alerts     BOOLEAN     DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS digest_frequency    VARCHAR(20) DEFAULT 'daily',
    ADD COLUMN IF NOT EXISTS quiet_hours_start   TIME,
    ADD COLUMN IF NOT EXISTS quiet_hours_end     TIME,
    ADD COLUMN IF NOT EXISTS updated_at          TIMESTAMPTZ DEFAULT NOW();

-- ── E5: Indexes (all IF NOT EXISTS — safe to re-run) ─────────────────────────

CREATE INDEX IF NOT EXISTS idx_notif_queue_recipient ON notification_queue(recipient_id, status);
CREATE INDEX IF NOT EXISTS idx_notif_queue_scheduled ON notification_queue(scheduled_at, status);
CREATE INDEX IF NOT EXISTS idx_notif_delivery_queue  ON notification_delivery_log(queue_id);

-- ============================================================
-- MODULE F: SEED BATCHES
-- ============================================================

CREATE TABLE IF NOT EXISTS seed_batches (
    id               BIGSERIAL    PRIMARY KEY,
    batch_key        VARCHAR(80)  NOT NULL UNIQUE,
    label            VARCHAR(200),
    description      TEXT,
    student_count    INTEGER      DEFAULT 0,
    status           VARCHAR(30)  DEFAULT 'completed',
    metadata         JSONB,
    created_by       INTEGER      REFERENCES users(id) ON DELETE SET NULL,
    created_at       TIMESTAMPTZ  DEFAULT NOW(),
    deleted_at       TIMESTAMPTZ
);

-- Track which students/users belong to which seed batch
CREATE TABLE IF NOT EXISTS seed_batch_members (
    id               BIGSERIAL    PRIMARY KEY,
    batch_id         BIGINT       REFERENCES seed_batches(id) ON DELETE CASCADE,
    entity_type      VARCHAR(30)  NOT NULL,  -- 'student', 'user', 'attempt', 'term_gpa'
    entity_id        BIGINT       NOT NULL,
    created_at       TIMESTAMPTZ  DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_seed_batch_members ON seed_batch_members(batch_id, entity_type);

-- ============================================================
-- MODULE G: REPORTING FOUNDATION
-- ============================================================

CREATE TABLE IF NOT EXISTS report_definitions (
    id               BIGSERIAL     PRIMARY KEY,
    key              VARCHAR(100)  NOT NULL UNIQUE,
    name             VARCHAR(200)  NOT NULL,
    description      TEXT,
    report_type      VARCHAR(80)   NOT NULL,
    query_config     JSONB,
    default_format   report_format DEFAULT 'json',
    is_active        BOOLEAN       DEFAULT TRUE,
    created_at       TIMESTAMPTZ   DEFAULT NOW(),
    updated_at       TIMESTAMPTZ   DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS report_runs (
    id               BIGSERIAL     PRIMARY KEY,
    definition_id    BIGINT        REFERENCES report_definitions(id) ON DELETE SET NULL,
    report_key       VARCHAR(100),
    parameters       JSONB,
    format           report_format DEFAULT 'json',
    status           VARCHAR(30)   DEFAULT 'running',
    result_data      JSONB,
    row_count        INTEGER,
    requested_by     INTEGER       REFERENCES users(id) ON DELETE SET NULL,
    started_at       TIMESTAMPTZ   DEFAULT NOW(),
    completed_at     TIMESTAMPTZ,
    error_message    TEXT,
    created_at       TIMESTAMPTZ   DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_report_runs_def  ON report_runs(definition_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_report_runs_user ON report_runs(requested_by);

-- ============================================================
-- MODULE H: RETENTION ANALYTICS
-- ============================================================

CREATE TABLE IF NOT EXISTS retention_snapshots (
    id                      BIGSERIAL    PRIMARY KEY,
    snapshot_date           DATE         NOT NULL,
    term_id                 BIGINT       REFERENCES academic_terms(id) ON DELETE SET NULL,
    program_id              BIGINT       REFERENCES academic_programs(id) ON DELETE SET NULL,
    total_students          INTEGER      DEFAULT 0,
    active_students         INTEGER      DEFAULT 0,
    below_2_cgpa            INTEGER      DEFAULT 0,
    between_2_and_2_5_cgpa  INTEGER      DEFAULT 0,
    above_2_5_cgpa          INTEGER      DEFAULT 0,
    dismissal_risk_count    INTEGER      DEFAULT 0,
    probation_count         INTEGER      DEFAULT 0,
    expected_graduates      INTEGER      DEFAULT 0,
    graduation_delay_count  INTEGER      DEFAULT 0,
    critical_warnings_count INTEGER      DEFAULT 0,
    avg_success_score       NUMERIC(5,2),
    avg_cgpa                NUMERIC(4,3),
    retention_rate          NUMERIC(5,2),
    metadata                JSONB,
    created_at              TIMESTAMPTZ  DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_retention_snapshots_date ON retention_snapshots(snapshot_date DESC);
CREATE INDEX IF NOT EXISTS idx_retention_snapshots_term ON retention_snapshots(term_id);

-- ============================================================
-- SEED DEFAULT CONFIGURATION
-- ============================================================

INSERT INTO system_config_categories (key, label, description, icon, sort_order) VALUES
('academic_rules',       'Academic Rules Configuration', 'Core academic rules and thresholds', 'BookOpen',      1),
('risk_thresholds',      'Risk Thresholds',              'Risk monitoring thresholds',          'AlertTriangle', 2),
('graduation_rules',     'Graduation Rules',             'Graduation eligibility rules',        'GraduationCap', 3),
('dismissal_rules',      'Dismissal Rules',              'Academic dismissal rules',            'ShieldOff',     4),
('notification_settings','Notification Settings',        'Notification channels and triggers',  'Bell',          5),
('workflow_settings',    'Workflow Settings',            'Workflow engine configuration',       'GitBranch',     6),
('student_success',      'Student Success Settings',     'Student success score weights',       'TrendingUp',    7),
('calendar_settings',    'Calendar Settings',            'Academic calendar defaults',          'Calendar',      8),
('retention_settings',   'Retention Settings',           'Retention monitoring rules',          'Users',         9),
('escalation_rules',     'Escalation Rules',             'Auto-escalation thresholds',          'ArrowUp',      10),
('semester_rules',       'Semester Rules',               'Semester counting and classification','School',       11),
('alert_settings',       'Alert Settings',               'Warning generation thresholds',       'AlertCircle',  12)
ON CONFLICT (key) DO NOTHING;

INSERT INTO system_config_settings (category_id, key, label, description, data_type, current_value, default_value) VALUES
-- Academic Dismissal Rules
((SELECT id FROM system_config_categories WHERE key = 'dismissal_rules'),
 'dismissal_min_regular_semesters', 'Minimum Regular Semesters Before Dismissal',
 'Student must complete this many regular semesters before dismissal is possible', 'integer', '6', '6'),
((SELECT id FROM system_config_categories WHERE key = 'dismissal_rules'),
 'dismissal_cgpa_threshold', 'CGPA Threshold for Dismissal Risk',
 'Students below this CGPA after min semesters are at dismissal risk', 'decimal', '2.00', '2.00'),
((SELECT id FROM system_config_categories WHERE key = 'dismissal_rules'),
 'dismissal_count_summer', 'Count Summer Semesters',
 'Whether to count summer semesters toward dismissal evaluation', 'boolean', 'false', 'false'),
-- Risk Monitoring
((SELECT id FROM system_config_categories WHERE key = 'risk_thresholds'),
 'risk_monitor_cgpa_low', 'CGPA Low Risk Lower Bound',
 'CGPA lower bound for high monitoring priority', 'decimal', '2.00', '2.00'),
((SELECT id FROM system_config_categories WHERE key = 'risk_thresholds'),
 'risk_monitor_cgpa_high', 'CGPA Low Risk Upper Bound',
 'CGPA upper bound for high monitoring priority', 'decimal', '2.50', '2.50'),
((SELECT id FROM system_config_categories WHERE key = 'risk_thresholds'),
 'risk_low_gpa_threshold', 'Low GPA Warning Threshold',
 'Term GPA below this triggers a low GPA warning', 'decimal', '2.00', '2.00'),
((SELECT id FROM system_config_categories WHERE key = 'risk_thresholds'),
 'risk_high_absence_pct', 'High Absence Warning Threshold (%)',
 'Absence percentage above this triggers a warning', 'decimal', '25.0', '25.0'),
-- Graduation Rules
((SELECT id FROM system_config_categories WHERE key = 'graduation_rules'),
 'graduation_min_cgpa', 'Minimum CGPA for Graduation',
 'Minimum CGPA required for graduation eligibility', 'decimal', '2.00', '2.00'),
((SELECT id FROM system_config_categories WHERE key = 'graduation_rules'),
 'graduation_total_credits', 'Total Required Credit Hours',
 'Total credit hours required to graduate', 'integer', '134', '134'),
-- Student Success Score Weights
((SELECT id FROM system_config_categories WHERE key = 'student_success'),
 'success_weight_cgpa', 'CGPA Component Weight (%)',
 'Weight of CGPA component in student success score', 'integer', '40', '40'),
((SELECT id FROM system_config_categories WHERE key = 'student_success'),
 'success_weight_attendance', 'Attendance Component Weight (%)',
 'Weight of attendance component in student success score', 'integer', '20', '20'),
((SELECT id FROM system_config_categories WHERE key = 'student_success'),
 'success_weight_completion', 'Course Completion Weight (%)',
 'Weight of course completion rate in success score', 'integer', '20', '20'),
((SELECT id FROM system_config_categories WHERE key = 'student_success'),
 'success_weight_progress', 'Academic Progress Weight (%)',
 'Weight of degree progress in success score', 'integer', '20', '20'),
((SELECT id FROM system_config_categories WHERE key = 'student_success'),
 'success_band_excellent', 'Excellent Band Threshold',
 'Score >= this value = Excellent', 'integer', '80', '80'),
((SELECT id FROM system_config_categories WHERE key = 'student_success'),
 'success_band_good', 'Good Band Threshold',
 'Score >= this value = Good', 'integer', '60', '60'),
((SELECT id FROM system_config_categories WHERE key = 'student_success'),
 'success_band_warning', 'Warning Band Threshold',
 'Score >= this value = Warning', 'integer', '40', '40'),
-- Escalation Rules
((SELECT id FROM system_config_categories WHERE key = 'escalation_rules'),
 'escalation_warning_days_advisor', 'Days Before Escalating to Advisor',
 'Days after warning creation before auto-escalate to advisor', 'integer', '3', '3'),
((SELECT id FROM system_config_categories WHERE key = 'escalation_rules'),
 'escalation_warning_days_registrar', 'Days Before Escalating to Registrar',
 'Days after advisor escalation before escalating to registrar', 'integer', '7', '7'),
((SELECT id FROM system_config_categories WHERE key = 'escalation_rules'),
 'escalation_auto_enabled', 'Auto-Escalation Enabled',
 'Whether automatic escalation is active', 'boolean', 'true', 'true'),
-- Semester Rules
((SELECT id FROM system_config_categories WHERE key = 'semester_rules'),
 'semester_types_regular', 'Regular Semester Types',
 'Comma-separated semester type keys that count as regular', 'string', 'fall,spring', 'fall,spring'),
((SELECT id FROM system_config_categories WHERE key = 'semester_rules'),
 'semester_types_summer', 'Summer Semester Types',
 'Comma-separated semester type keys classified as summer', 'string', 'summer', 'summer')
ON CONFLICT (key) DO NOTHING;

-- Seed default notification templates
-- ON CONFLICT (key) is now safe: the key column and its UNIQUE constraint
-- are guaranteed to exist by the reconciliation block above.
INSERT INTO notification_templates (key, name, channel, subject_template, body_template, variables) VALUES
('warning_low_cgpa',
 'Low CGPA Warning', 'in_app', NULL,
 'Your CGPA has dropped to {{cgpa}}. Please contact your advisor for support.',
 '["student_name","cgpa","threshold"]'::JSONB),

('warning_high_absence',
 'High Absence Alert', 'in_app', NULL,
 'Your absence rate in {{course_name}} has reached {{absence_pct}}%. This may affect your academic standing.',
 '["student_name","course_name","absence_pct","threshold"]'::JSONB),

('intervention_assigned',
 'Intervention Plan Assigned', 'in_app', NULL,
 'An intervention plan has been assigned to you: {{title}}. Please respond to your advisor.',
 '["student_name","title","advisor_name"]'::JSONB),

('escalation_notice',
 'Escalation Notice', 'in_app', NULL,
 'Academic concern for {{student_name}} has been escalated to {{to_level}}.',
 '["student_name","from_level","to_level","reason"]'::JSONB),

('graduation_readiness',
 'Graduation Readiness Update', 'in_app', NULL,
 'Your graduation readiness is now {{readiness_pct}}%. {{status_message}}',
 '["student_name","readiness_pct","status_message"]'::JSONB)

ON CONFLICT (key) DO NOTHING;

-- Seed default report definitions
INSERT INTO report_definitions (key, name, description, report_type, default_format) VALUES
('student_progress_report',     'Student Progress Report',     'Individual student academic progress',       'student_progress',    'json'),
('academic_risk_report',        'Academic Risk Report',        'Students at academic risk',                  'academic_risk',       'json'),
('graduation_readiness_report', 'Graduation Readiness Report', 'Students graduation readiness status',       'graduation_readiness','json'),
('retention_report',            'Retention Report',            'Student retention analytics',                'retention',           'json'),
('advisor_workload_report',     'Advisor Workload Report',     'Advisor caseload and intervention tracking', 'advisor_workload',    'json'),
('intervention_report',         'Intervention Report',         'Intervention effectiveness report',          'interventions',       'json'),
('success_score_report',        'Success Score Report',        'Student success score distribution',         'success_scores',      'json'),
('dismissal_risk_report',       'Dismissal Risk Report',       'Students at dismissal risk',                 'dismissal_risk',      'json')
ON CONFLICT (key) DO NOTHING;

COMMIT;
