-- ============================================================
-- EduGuard AI — Sprint 1: Academic Foundation Migration
-- ============================================================
-- File        : 005_academic_foundation.sql
-- Description : Adds the full academic structure layer on top of the
--               existing EduGuard schema (001_schema.sql).
--               Covers:
--                 1. Academic Programs & Tracks
--                 2. Academic Terms / Semesters
--                 3. Course Catalog enrichment
--                 4. Course Prerequisites & Post-Requisites
--                 5. Student Academic Profile
--                 6. Student Course Attempts (transcript layer)
--                 7. Grade & GPA/CGPA support tables
--                 8. Advising Plans & Items
--                 9. Graduation Requirements & Progress
--                10. Import Jobs / Errors (data-onboarding)
-- Run order   : 5  → after 001_schema.sql, 002_seed.sql,
--                      003_views.sql, 004_demo_users.sql
-- Based on    : New Mansoura University CS – Software Engineering Track
--               curriculum documents + CGPA Calculator Excel sheet
-- ============================================================

-- ============================================================
-- SECTION 0 — NEW ENUMS
-- ============================================================

DO $$ BEGIN
    CREATE TYPE course_category AS ENUM (
        'core',               -- Required program core course
        'elective',           -- Program elective (E1/E2/E3 slots)
        'university_req',     -- University mandatory requirement (UC1…UC7)
        'university_elective',-- University elective requirement (UE1…UE3)
        'field_training'      -- Internship / field training
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE course_status_type AS ENUM (
        'not_taken',
        'in_progress',
        'passed',
        'failed',
        'withdrawn',
        'transferred'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE term_type AS ENUM ('fall', 'spring', 'summer');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE attempt_result AS ENUM (
        'passed',    -- P grade (pass/fail courses) or numeric grade >= pass threshold
        'failed',    -- F / FL
        'withdrawn', -- W – withdrew before deadline
        'incomplete',-- I – grade not yet submitted
        'in_progress'-- currently enrolled
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE advising_plan_status AS ENUM (
        'draft',
        'submitted',
        'advisor_approved',
        'advisor_rejected',
        'registered',
        'archived'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE req_category AS ENUM (
        'core',
        'elective',
        'university_req',
        'university_elective',
        'field_training',
        'graduation_project'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE import_status AS ENUM (
        'pending', 'processing', 'completed', 'failed', 'partial'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============================================================
-- SECTION 1 — ACADEMIC PROGRAMS
-- ============================================================
-- One row per degree program (CS, IS, AI, SE, CyberSec, DataSci…)
-- Currently only CS is seeded, but structure is multi-program ready.
-- ============================================================

CREATE TABLE IF NOT EXISTS academic_programs (
    id              BIGSERIAL       PRIMARY KEY,
    department_id   BIGINT          REFERENCES departments(id) ON DELETE SET NULL,
    code            VARCHAR(20)     UNIQUE NOT NULL,   -- e.g. 'CS'
    name            VARCHAR(150)    NOT NULL,           -- 'Computer Science'
    name_ar         VARCHAR(150),                       -- Arabic name
    total_credit_hours  SMALLINT    NOT NULL DEFAULT 134,
    min_cgpa_grad   NUMERIC(3,2)    DEFAULT 2.00,       -- min CGPA to graduate
    duration_years  SMALLINT        DEFAULT 4,
    is_active       BOOLEAN         DEFAULT TRUE,
    description     TEXT,
    created_at      TIMESTAMPTZ     DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_prog_dept ON academic_programs(department_id);
CREATE INDEX IF NOT EXISTS idx_prog_code ON academic_programs(code);

-- ============================================================
-- SECTION 2 — TRACKS / SPECIALIZATIONS
-- ============================================================
-- e.g. "Software Engineering" track within CS program
-- ============================================================

CREATE TABLE IF NOT EXISTS academic_tracks (
    id              BIGSERIAL       PRIMARY KEY,
    program_id      BIGINT          NOT NULL REFERENCES academic_programs(id) ON DELETE CASCADE,
    code            VARCHAR(30)     UNIQUE NOT NULL,   -- 'CS-SE'
    name            VARCHAR(150)    NOT NULL,           -- 'Software Engineering'
    name_ar         VARCHAR(150),
    is_active       BOOLEAN         DEFAULT TRUE,
    description     TEXT,
    created_at      TIMESTAMPTZ     DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_track_program ON academic_tracks(program_id);

-- ============================================================
-- SECTION 3 — ACADEMIC TERMS
-- ============================================================
-- Canonical semester/term registry (Fall 2024, Spring 2025 …)
-- ============================================================

CREATE TABLE IF NOT EXISTS academic_terms (
    id              BIGSERIAL       PRIMARY KEY,
    code            VARCHAR(20)     UNIQUE NOT NULL,    -- 'FALL-2024'
    name            VARCHAR(80)     NOT NULL,            -- 'Fall Semester 2024'
    term_type       term_type       NOT NULL,
    academic_year   SMALLINT        NOT NULL,            -- 2024 (start year)
    start_date      DATE,
    end_date        DATE,
    registration_start DATE,
    registration_end   DATE,
    is_active       BOOLEAN         DEFAULT FALSE,       -- TRUE for current term
    is_summer       BOOLEAN         DEFAULT FALSE,
    created_at      TIMESTAMPTZ     DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_terms_year ON academic_terms(academic_year, term_type);
CREATE INDEX IF NOT EXISTS idx_terms_active ON academic_terms(is_active) WHERE is_active = TRUE;

-- ============================================================
-- SECTION 4 — COURSE CATALOG ENRICHMENT
-- ============================================================
-- Adds academic metadata columns to the existing `courses` table.
-- We ALTER rather than CREATE a new table to preserve all existing
-- relationships (enrollments, quizzes, attendances …).
-- ============================================================

-- Program / track assignment
ALTER TABLE courses
    ADD COLUMN IF NOT EXISTS program_id      BIGINT      REFERENCES academic_programs(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS track_id        BIGINT      REFERENCES academic_tracks(id)   ON DELETE SET NULL,

    -- Curriculum position
    ADD COLUMN IF NOT EXISTS category        course_category  DEFAULT 'core',
    ADD COLUMN IF NOT EXISTS curriculum_level SMALLINT   CHECK (curriculum_level BETWEEN 1 AND 4),
    -- Plan semester number (1-8) from official study plan table
    ADD COLUMN IF NOT EXISTS plan_semester   SMALLINT   CHECK (plan_semester BETWEEN 1 AND 8),

    -- Contact hours per week (from study plan: LCT, LAB, TUT, OTH)
    ADD COLUMN IF NOT EXISTS lct_hours       SMALLINT   DEFAULT 2,   -- Lecture
    ADD COLUMN IF NOT EXISTS lab_hours       SMALLINT   DEFAULT 0,   -- Lab
    ADD COLUMN IF NOT EXISTS tut_hours       SMALLINT   DEFAULT 0,   -- Tutorial
    ADD COLUMN IF NOT EXISTS oth_hours       SMALLINT   DEFAULT 0,   -- Other

    -- Totals from study plan
    ADD COLUMN IF NOT EXISTS contact_hours   SMALLINT   DEFAULT 2,   -- CNTCT
    ADD COLUMN IF NOT EXISTS ects_credits    SMALLINT   DEFAULT 4,   -- ECTS

    -- Elective slot label (E1, E2, E3 / UC1…UC7 / UE1…UE3)
    ADD COLUMN IF NOT EXISTS slot_label      VARCHAR(10),

    -- Student workload hours (SWL from plan)
    ADD COLUMN IF NOT EXISTS swl_hours       SMALLINT   DEFAULT 90,

    -- Whether this course counts toward CGPA
    ADD COLUMN IF NOT EXISTS counts_in_cgpa  BOOLEAN    DEFAULT TRUE,

    -- Whether pass/fail grading (vs letter grade)
    ADD COLUMN IF NOT EXISTS is_pass_fail    BOOLEAN    DEFAULT FALSE,

    -- Minimum passing grade (out of 100)
    ADD COLUMN IF NOT EXISTS pass_threshold  NUMERIC(5,2) DEFAULT 60.00,

    -- Short Arabic name (future i18n)
    ADD COLUMN IF NOT EXISTS name_ar         VARCHAR(255);

CREATE INDEX IF NOT EXISTS idx_courses_program   ON courses(program_id);
CREATE INDEX IF NOT EXISTS idx_courses_track     ON courses(track_id);
CREATE INDEX IF NOT EXISTS idx_courses_category  ON courses(category);
CREATE INDEX IF NOT EXISTS idx_courses_plan_sem  ON courses(plan_semester);

-- ============================================================
-- SECTION 5 — COURSE PREREQUISITES
-- ============================================================
-- Stores all prerequisite relationships extracted from the
-- official prerequisite document.
-- Supports both hard prerequisites (must pass) and co-requisites.
-- ============================================================

CREATE TABLE IF NOT EXISTS course_prerequisites (
    id              BIGSERIAL   PRIMARY KEY,
    course_id       INTEGER     NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    prerequisite_id INTEGER     NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    -- 'hard'  = must have passed before enrolling
    -- 'co'    = must be taking concurrently or already passed
    -- 'soft'  = advisory only (warning, not block)
    prereq_type     VARCHAR(10) NOT NULL DEFAULT 'hard',
    min_grade       NUMERIC(5,2) DEFAULT 60.00,  -- minimum passing grade required
    notes           TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (course_id, prerequisite_id),
    CHECK (course_id <> prerequisite_id)
);

CREATE INDEX IF NOT EXISTS idx_prereq_course  ON course_prerequisites(course_id);
CREATE INDEX IF NOT EXISTS idx_prereq_prereq  ON course_prerequisites(prerequisite_id);

-- ============================================================
-- SECTION 6 — COURSE POST-REQUISITES (Unlock Map)
-- ============================================================
-- Derived from the post-requisite document.
-- Helps the recommendation engine surface "what this unlocks".
-- This is intentionally a VIEW-friendly materialization — the
-- source of truth is course_prerequisites; post-requisites are
-- the inverse but stored explicitly for query performance.
-- ============================================================

CREATE TABLE IF NOT EXISTS course_postrequisites (
    id              BIGSERIAL   PRIMARY KEY,
    course_id       INTEGER     NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    postreq_id      INTEGER     NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    -- 'C' = core course unlocked,  'E' = elective unlocked
    unlock_type     VARCHAR(5)  DEFAULT 'C',
    notes           TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (course_id, postreq_id),
    CHECK (course_id <> postreq_id)
);

CREATE INDEX IF NOT EXISTS idx_postreq_course  ON course_postrequisites(course_id);
CREATE INDEX IF NOT EXISTS idx_postreq_unlock  ON course_postrequisites(postreq_id);

-- ============================================================
-- SECTION 7 — STUDENT ACADEMIC PROFILE
-- ============================================================
-- Extends the existing `students` table with academic-program
-- level information required for advising and graduation tracking.
-- ============================================================

ALTER TABLE students
    ADD COLUMN IF NOT EXISTS program_id         BIGINT  REFERENCES academic_programs(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS track_id           BIGINT  REFERENCES academic_tracks(id)   ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS admission_term_id  BIGINT  REFERENCES academic_terms(id)    ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS expected_grad_term_id BIGINT REFERENCES academic_terms(id)  ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS academic_level     SMALLINT CHECK (academic_level BETWEEN 1 AND 4),

    -- CGPA tracking (separate from legacy `gpa` float column)
    -- cgpa  = cumulative GPA on 4-point scale
    -- total_credit_hours_attempted = includes failed/repeated courses
    -- total_credit_hours_earned    = only passed courses
    -- total_quality_points         = sum(credit_hours * grade_points) for CGPA calc
    ADD COLUMN IF NOT EXISTS cgpa                       NUMERIC(4,3) DEFAULT 0.000,
    ADD COLUMN IF NOT EXISTS total_credit_hours_attempted SMALLINT    DEFAULT 0,
    ADD COLUMN IF NOT EXISTS total_credit_hours_earned    SMALLINT    DEFAULT 0,
    ADD COLUMN IF NOT EXISTS total_quality_points         NUMERIC(8,3) DEFAULT 0.000,

    -- Academic standing (based on CGPA thresholds from Excel)
    -- 'good'       ≥ 2.00
    -- 'warning'    1.70 – 1.99
    -- 'probation'  < 1.70 for one semester
    -- 'dismissed'  < 1.70 for two consecutive semesters
    ADD COLUMN IF NOT EXISTS academic_standing  VARCHAR(20)  DEFAULT 'good',

    -- Graduation eligibility flag (computed, refreshed each semester)
    ADD COLUMN IF NOT EXISTS is_eligible_for_graduation BOOLEAN DEFAULT FALSE;

CREATE INDEX IF NOT EXISTS idx_students_program ON students(program_id);
CREATE INDEX IF NOT EXISTS idx_students_track   ON students(track_id);
CREATE INDEX IF NOT EXISTS idx_students_cgpa    ON students(cgpa);
CREATE INDEX IF NOT EXISTS idx_students_standing ON students(academic_standing);

-- ============================================================
-- SECTION 8 — STUDENT COURSE ATTEMPTS (Transcript Layer)
-- ============================================================
-- REPLACES the thin `enrollments` table's grade tracking for
-- academic history purposes.  The existing `enrollments` table is
-- preserved for the monitoring/attendance system.
--
-- A new attempt is created EVERY time a student registers a course
-- (including retakes for grade improvement or after failing).
-- This supports:
--   • Multiple attempts per course
--   • Grade improvement detection
--   • Correct CGPA calculation (all attempted credits count)
--   • Transcript generation
-- ============================================================

CREATE TABLE IF NOT EXISTS student_course_attempts (
    id              BIGSERIAL       PRIMARY KEY,
    student_id      INTEGER         NOT NULL REFERENCES students(id)       ON DELETE CASCADE,
    course_id       INTEGER         NOT NULL REFERENCES courses(id)         ON DELETE CASCADE,
    term_id         BIGINT          NOT NULL REFERENCES academic_terms(id)  ON DELETE RESTRICT,

    attempt_number  SMALLINT        NOT NULL DEFAULT 1,  -- 1 = first, 2 = retake, etc.

    -- Grade storage
    -- numeric_grade  : raw score out of 100 (NULL until graded)
    -- letter_grade   : A+, A, B+, B … F, FL (Fail + Absence lock), W, P, I
    -- grade_points   : 4.0-scale value used in CGPA calculation
    -- is_pass_fail   : TRUE for field training, GP, language courses
    numeric_grade   NUMERIC(5,2)    CHECK (numeric_grade BETWEEN 0 AND 100),
    letter_grade    VARCHAR(5),
    grade_points    NUMERIC(3,2)    CHECK (grade_points BETWEEN 0.00 AND 4.00),

    -- Credit hours for THIS attempt (usually equals course.credits,
    -- but can differ for cross-listed or special-arrangement courses)
    credit_hours    SMALLINT        NOT NULL DEFAULT 3,

    -- Result
    result          attempt_result  NOT NULL DEFAULT 'in_progress',

    -- Was this attempt a repeat to improve a previously passing grade?
    is_improvement_attempt  BOOLEAN DEFAULT FALSE,

    -- Counts in CGPA? (FALSE for transferred courses, audits, etc.)
    counts_in_cgpa  BOOLEAN         DEFAULT TRUE,

    -- Timestamps
    registered_at   TIMESTAMPTZ     DEFAULT NOW(),
    grade_posted_at TIMESTAMPTZ,
    withdrawn_at    TIMESTAMPTZ,

    -- Graded by (professor user_id)
    graded_by       INTEGER         REFERENCES users(id) ON DELETE SET NULL,

    notes           TEXT,
    created_at      TIMESTAMPTZ     DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     DEFAULT NOW(),

    UNIQUE (student_id, course_id, attempt_number)
);

CREATE INDEX IF NOT EXISTS idx_sca_student      ON student_course_attempts(student_id);
CREATE INDEX IF NOT EXISTS idx_sca_course       ON student_course_attempts(course_id);
CREATE INDEX IF NOT EXISTS idx_sca_term         ON student_course_attempts(term_id);
CREATE INDEX IF NOT EXISTS idx_sca_result       ON student_course_attempts(result);
CREATE INDEX IF NOT EXISTS idx_sca_student_term ON student_course_attempts(student_id, term_id);

-- ============================================================
-- SECTION 9 — GRADE SCALE REFERENCE
-- ============================================================
-- Derived from the CGPA Calculator Excel file.
-- Maps letter grades → grade points (4.0 scale) and thresholds.
-- ============================================================

CREATE TABLE IF NOT EXISTS grade_scale (
    id              SERIAL      PRIMARY KEY,
    program_id      BIGINT      REFERENCES academic_programs(id) ON DELETE CASCADE,
    letter_grade    VARCHAR(5)  NOT NULL,          -- 'A+', 'A', 'B+' … 'F', 'FL', 'W', 'P'
    min_percentage  NUMERIC(5,2),                  -- lower bound of numeric range
    max_percentage  NUMERIC(5,2),                  -- upper bound of numeric range
    grade_points    NUMERIC(3,2) NOT NULL,          -- GPA points (0.00–4.00)
    counts_in_cgpa  BOOLEAN     DEFAULT TRUE,       -- F & FL count; W & P do not
    is_passing      BOOLEAN     DEFAULT TRUE,
    description     VARCHAR(50),
    UNIQUE (program_id, letter_grade)
);

CREATE INDEX IF NOT EXISTS idx_grade_scale_prog ON grade_scale(program_id);

-- ============================================================
-- SECTION 10 — TERM GPA SNAPSHOTS
-- ============================================================
-- One row per student per term, capturing that term's GPA and
-- cumulative totals AFTER grades are finalized.
-- Supports: semester-by-semester CGPA trend, standing history,
--           analytics dashboards, graduation reports.
-- ============================================================

CREATE TABLE IF NOT EXISTS student_term_gpa (
    id                  BIGSERIAL   PRIMARY KEY,
    student_id          INTEGER     NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    term_id             BIGINT      NOT NULL REFERENCES academic_terms(id) ON DELETE CASCADE,

    -- Semester GPA (only courses in THIS term)
    term_credit_hours_attempted SMALLINT    NOT NULL DEFAULT 0,
    term_credit_hours_earned    SMALLINT    NOT NULL DEFAULT 0,
    term_quality_points         NUMERIC(8,3) DEFAULT 0.000,
    term_gpa                    NUMERIC(4,3) DEFAULT 0.000,

    -- Cumulative values AFTER this term
    cumulative_hours_attempted  SMALLINT    NOT NULL DEFAULT 0,
    cumulative_hours_earned     SMALLINT    NOT NULL DEFAULT 0,
    cumulative_quality_points   NUMERIC(8,3) DEFAULT 0.000,
    cgpa                        NUMERIC(4,3) DEFAULT 0.000,

    academic_standing           VARCHAR(20)  DEFAULT 'good',

    -- Was this term a summer session?
    is_summer                   BOOLEAN     DEFAULT FALSE,

    finalized                   BOOLEAN     DEFAULT FALSE,
    finalized_at                TIMESTAMPTZ,
    created_at                  TIMESTAMPTZ DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE (student_id, term_id)
);

CREATE INDEX IF NOT EXISTS idx_term_gpa_student ON student_term_gpa(student_id);
CREATE INDEX IF NOT EXISTS idx_term_gpa_term    ON student_term_gpa(term_id);
CREATE INDEX IF NOT EXISTS idx_term_gpa_cgpa    ON student_term_gpa(cgpa);

-- ============================================================
-- SECTION 11 — COURSE OFFERINGS
-- ============================================================
-- Semester-specific offering of a catalog course.
-- A course can be offered in multiple semesters, each with
-- its own capacity, schedule, and assigned professor.
-- ============================================================

CREATE TABLE IF NOT EXISTS course_offerings (
    id              BIGSERIAL   PRIMARY KEY,
    course_id       INTEGER     NOT NULL REFERENCES courses(id)         ON DELETE CASCADE,
    term_id         BIGINT      NOT NULL REFERENCES academic_terms(id)  ON DELETE CASCADE,
    professor_id    INTEGER     REFERENCES professors(id)               ON DELETE SET NULL,
    section         VARCHAR(20) DEFAULT 'A',
    max_capacity    SMALLINT    DEFAULT 40,
    current_enrolled SMALLINT   DEFAULT 0,
    room            VARCHAR(50),
    schedule_json   JSONB,          -- {days: ['Sun','Tue'], time: '09:00', lab: '11:00'}
    is_open         BOOLEAN     DEFAULT TRUE,
    notes           TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE (course_id, term_id, section)
);

CREATE INDEX IF NOT EXISTS idx_offering_course ON course_offerings(course_id);
CREATE INDEX IF NOT EXISTS idx_offering_term   ON course_offerings(term_id);
CREATE INDEX IF NOT EXISTS idx_offering_prof   ON course_offerings(professor_id);

-- ============================================================
-- SECTION 12 — GRADUATION REQUIREMENTS
-- ============================================================
-- Defines what a student must complete to graduate from a
-- specific program/track combination.
-- Extracted from the study plan totals (134 CH, 8 semesters, etc.)
-- ============================================================

CREATE TABLE IF NOT EXISTS graduation_requirements (
    id                  BIGSERIAL   PRIMARY KEY,
    program_id          BIGINT      NOT NULL REFERENCES academic_programs(id) ON DELETE CASCADE,
    track_id            BIGINT      REFERENCES academic_tracks(id) ON DELETE CASCADE,

    category            req_category NOT NULL,
    label               VARCHAR(80)  NOT NULL,   -- 'Core Courses', 'Program Electives (3)', etc.
    required_credits    SMALLINT    NOT NULL,
    required_courses    SMALLINT    DEFAULT 0,   -- minimum number of courses (some cats specify count)
    min_cgpa            NUMERIC(3,2) DEFAULT 2.00,
    notes               TEXT,

    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_grad_req_program ON graduation_requirements(program_id);
CREATE INDEX IF NOT EXISTS idx_grad_req_track   ON graduation_requirements(track_id);

-- ============================================================
-- SECTION 13 — STUDENT GRADUATION PROGRESS
-- ============================================================
-- Computed view of a student's progress toward each graduation
-- requirement category. Refreshed after each grade posting.
-- ============================================================

CREATE TABLE IF NOT EXISTS student_graduation_progress (
    id                      BIGSERIAL   PRIMARY KEY,
    student_id              INTEGER     NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    requirement_id          BIGINT      NOT NULL REFERENCES graduation_requirements(id) ON DELETE CASCADE,

    credits_completed       SMALLINT    DEFAULT 0,
    credits_remaining       SMALLINT    DEFAULT 0,
    courses_completed       SMALLINT    DEFAULT 0,
    courses_remaining       SMALLINT    DEFAULT 0,
    completion_pct          NUMERIC(5,2) DEFAULT 0.00,

    last_computed_at        TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE (student_id, requirement_id)
);

CREATE INDEX IF NOT EXISTS idx_grad_prog_student ON student_graduation_progress(student_id);
CREATE INDEX IF NOT EXISTS idx_grad_prog_req     ON student_graduation_progress(requirement_id);

-- ============================================================
-- SECTION 14 — ADVISING RECOMMENDATION PLANS
-- ============================================================
-- Each semester an advisor creates / student requests a plan
-- listing the courses recommended for the coming term.
-- ============================================================

CREATE TABLE IF NOT EXISTS advising_plans (
    id              BIGSERIAL               PRIMARY KEY,
    student_id      INTEGER                 NOT NULL REFERENCES students(id)  ON DELETE CASCADE,
    advisor_id      INTEGER                 REFERENCES advisors(id)           ON DELETE SET NULL,
    term_id         BIGINT                  NOT NULL REFERENCES academic_terms(id) ON DELETE RESTRICT,

    status          advising_plan_status    NOT NULL DEFAULT 'draft',
    total_credits   SMALLINT                DEFAULT 0,
    max_credits     SMALLINT                DEFAULT 18,

    -- AI-generated vs manually created
    is_ai_generated BOOLEAN                 DEFAULT FALSE,
    ai_model_version VARCHAR(20),

    student_notes   TEXT,                   -- notes from student
    advisor_notes   TEXT,                   -- advisor review notes
    rejection_reason TEXT,

    submitted_at    TIMESTAMPTZ,
    reviewed_at     TIMESTAMPTZ,
    approved_at     TIMESTAMPTZ,

    created_at      TIMESTAMPTZ             DEFAULT NOW(),
    updated_at      TIMESTAMPTZ             DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ap_student ON advising_plans(student_id);
CREATE INDEX IF NOT EXISTS idx_ap_advisor ON advising_plans(advisor_id);
CREATE INDEX IF NOT EXISTS idx_ap_term    ON advising_plans(term_id);
CREATE INDEX IF NOT EXISTS idx_ap_status  ON advising_plans(status);

-- ============================================================
-- SECTION 15 — ADVISING PLAN ITEMS
-- ============================================================

CREATE TABLE IF NOT EXISTS advising_plan_items (
    id              BIGSERIAL   PRIMARY KEY,
    plan_id         BIGINT      NOT NULL REFERENCES advising_plans(id) ON DELETE CASCADE,
    course_id       INTEGER     NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    offering_id     BIGINT      REFERENCES course_offerings(id) ON DELETE SET NULL,

    -- Priority assigned by advisor / AI engine
    -- 1 = highest priority (e.g. failed course must retake)
    priority_rank   SMALLINT    DEFAULT 1,

    -- Reason for recommendation
    -- 'prerequisite_unlock', 'graduation_requirement', 'retake_failed',
    -- 'grade_improvement', 'progression', 'elective_requirement', 'ai_recommended'
    reason          VARCHAR(50),

    is_mandatory    BOOLEAN     DEFAULT FALSE,
    notes           TEXT,

    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_api_plan   ON advising_plan_items(plan_id);
CREATE INDEX IF NOT EXISTS idx_api_course ON advising_plan_items(course_id);

-- ============================================================
-- SECTION 16 — COURSE ELIGIBILITY RULES
-- ============================================================
-- Captures complex eligibility rules beyond simple prerequisites:
-- e.g. "Senior Standing" required for CSE493 Graduation Project 1.
-- ============================================================

CREATE TABLE IF NOT EXISTS course_eligibility_rules (
    id              BIGSERIAL   PRIMARY KEY,
    course_id       INTEGER     NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    rule_type       VARCHAR(30) NOT NULL,
    -- rule_types:
    --   'min_credits_earned'  — must have passed N credit hours
    --   'min_cgpa'            — must have CGPA >= threshold
    --   'min_level'           — must be in academic level >= N
    --   'completed_course'    — must have completed specific course (use prereqs)
    --   'special'             — free-text rule (use rule_text)
    rule_value      NUMERIC(6,2),    -- numeric threshold (credits, CGPA, level)
    rule_text       TEXT,            -- for complex/special rules
    is_mandatory    BOOLEAN     DEFAULT TRUE,
    notes           TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_cer_course ON course_eligibility_rules(course_id);

-- ============================================================
-- SECTION 17 — IMPORT JOBS & ERRORS
-- ============================================================
-- Supports bulk import of student records, grades, course catalogs
-- from CSV / Excel files uploaded by admins.
-- ============================================================

CREATE TABLE IF NOT EXISTS import_jobs (
    id              BIGSERIAL       PRIMARY KEY,
    job_type        VARCHAR(50)     NOT NULL,
    -- job_types: 'students', 'grades', 'courses', 'enrollments',
    --            'course_catalog', 'prerequisites', 'term_gpa'
    status          import_status   NOT NULL DEFAULT 'pending',
    file_name       VARCHAR(255),
    file_size_bytes BIGINT,
    total_rows      INTEGER         DEFAULT 0,
    processed_rows  INTEGER         DEFAULT 0,
    success_rows    INTEGER         DEFAULT 0,
    error_rows      INTEGER         DEFAULT 0,
    initiated_by    INTEGER         REFERENCES users(id) ON DELETE SET NULL,
    started_at      TIMESTAMPTZ,
    completed_at    TIMESTAMPTZ,
    error_summary   TEXT,
    metadata_json   JSONB,
    created_at      TIMESTAMPTZ     DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS import_errors (
    id              BIGSERIAL   PRIMARY KEY,
    job_id          BIGINT      NOT NULL REFERENCES import_jobs(id) ON DELETE CASCADE,
    row_number      INTEGER,
    field_name      VARCHAR(100),
    raw_value       TEXT,
    error_message   TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_import_jobs_status ON import_jobs(status);
CREATE INDEX IF NOT EXISTS idx_import_errors_job  ON import_errors(job_id);

-- ============================================================
-- SECTION 18 — updated_at TRIGGERS FOR NEW TABLES
-- ============================================================

DO $$ DECLARE t TEXT; BEGIN
    FOREACH t IN ARRAY ARRAY[
        'academic_programs', 'academic_tracks', 'academic_terms',
        'course_offerings', 'student_course_attempts',
        'student_term_gpa', 'advising_plans',
        'graduation_requirements', 'student_graduation_progress',
        'import_jobs'
    ] LOOP
        EXECUTE format('
            DROP TRIGGER IF EXISTS set_updated_at ON %I;
            CREATE TRIGGER set_updated_at
            BEFORE UPDATE ON %I
            FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
        ', t, t);
    END LOOP;
END $$;

-- ============================================================
-- SECTION 19 — AUDIT TRIGGERS FOR SENSITIVE ACADEMIC TABLES
-- ============================================================

DO $$ DECLARE t TEXT; BEGIN
    FOREACH t IN ARRAY ARRAY[
        'student_course_attempts', 'advising_plans', 'student_term_gpa'
    ] LOOP
        EXECUTE format('
            DROP TRIGGER IF EXISTS trg_audit ON %I;
            CREATE TRIGGER trg_audit
            AFTER INSERT OR UPDATE OR DELETE ON %I
            FOR EACH ROW EXECUTE FUNCTION audit_user_changes();
        ', t, t);
    END LOOP;
END $$;

-- ============================================================
-- SECTION 20 — SEED: CS PROGRAM & SOFTWARE ENGINEERING TRACK
-- ============================================================
-- Inserts the Computer Science program and Software Engineering
-- track as the foundational seed data.  Course catalog seeding
-- should be done via a separate seed script (006_seed_courses.sql).
-- ============================================================

INSERT INTO academic_programs (code, name, name_ar, total_credit_hours, min_cgpa_grad, duration_years, description)
VALUES (
    'CS',
    'Computer Science',
    'علوم الحاسب',
    134,
    2.00,
    4,
    'Bachelor of Science in Computer Science – New Mansoura University'
)
ON CONFLICT (code) DO NOTHING;

INSERT INTO academic_tracks (program_id, code, name, name_ar, description)
SELECT
    p.id,
    'CS-SE',
    'Software Engineering',
    'هندسة البرمجيات',
    'Software Engineering specialization track within the CS program'
FROM academic_programs p
WHERE p.code = 'CS'
ON CONFLICT (code) DO NOTHING;

-- ============================================================
-- SECTION 21 — SEED: GRADE SCALE (from CGPA Calculator Excel)
-- ============================================================
-- Grade scale extracted from CGPA_Calculator.xlsx:
-- A+ (97-100, 4.0), A (93-96, 4.0), A- (90-92, 3.7),
-- B+ (87-89, 3.3), B (83-86, 3.0), B- (80-82, 2.7),
-- C+ (77-79, 2.3), C (73-76, 2.0), C- (70-72, 1.7),
-- D+ (67-69, 1.3), D (60-66, 1.0), F (<60, 0.0),
-- FL (Fail+Lock, 0.0), W (Withdrawn, 0.0), P (Pass, 0.0 — no GPA impact)
-- ============================================================

INSERT INTO grade_scale (program_id, letter_grade, min_percentage, max_percentage, grade_points, counts_in_cgpa, is_passing, description)
SELECT
    p.id,
    v.letter_grade,
    v.min_pct,
    v.max_pct,
    v.gp,
    v.in_cgpa,
    v.passing,
    v.descr
FROM academic_programs p
CROSS JOIN (VALUES
    ('A+',  97.00, 100.00, 4.00, TRUE,  TRUE,  'Excellent Plus'),
    ('A',   93.00,  96.99, 4.00, TRUE,  TRUE,  'Excellent'),
    ('A-',  90.00,  92.99, 3.70, TRUE,  TRUE,  'Excellent Minus'),
    ('B+',  87.00,  89.99, 3.30, TRUE,  TRUE,  'Very Good Plus'),
    ('B',   83.00,  86.99, 3.00, TRUE,  TRUE,  'Very Good'),
    ('B-',  80.00,  82.99, 2.70, TRUE,  TRUE,  'Very Good Minus'),
    ('C+',  77.00,  79.99, 2.30, TRUE,  TRUE,  'Good Plus'),
    ('C',   73.00,  76.99, 2.00, TRUE,  TRUE,  'Good'),
    ('C-',  70.00,  72.99, 1.70, TRUE,  TRUE,  'Good Minus'),
    ('D+',  67.00,  69.99, 1.30, TRUE,  TRUE,  'Pass Plus'),
    ('D',   60.00,  66.99, 1.00, TRUE,  TRUE,  'Pass'),
    ('F',    0.00,  59.99, 0.00, TRUE,  FALSE, 'Fail'),
    ('FL',   0.00,  59.99, 0.00, TRUE,  FALSE, 'Fail + Absence Lock'),
    ('W',   NULL,   NULL,  0.00, FALSE, FALSE, 'Withdrawn'),
    ('P',   NULL,   NULL,  0.00, FALSE, TRUE,  'Pass (non-graded)')
) AS v(letter_grade, min_pct, max_pct, gp, in_cgpa, passing, descr)
WHERE p.code = 'CS'
ON CONFLICT (program_id, letter_grade) DO NOTHING;

-- ============================================================
-- SECTION 22 — SEED: GRADUATION REQUIREMENTS (CS-SE Track)
-- ============================================================
-- Based on the study plan totals:
-- Total: 134 CH across 8 semesters
-- Core Courses + University Requirements + Electives
-- ============================================================

INSERT INTO graduation_requirements (program_id, track_id, category, label, required_credits, required_courses, notes)
SELECT
    p.id,
    t.id,
    v.cat::req_category,
    v.label,
    v.credits,
    v.num_courses,
    v.notes
FROM academic_programs p
JOIN academic_tracks t ON t.program_id = p.id AND t.code = 'CS-SE'
CROSS JOIN (VALUES
    ('core',               'Program Core Courses',              96, 0,  'All core CS courses including field trainings and graduation project'),
    ('elective',           'Program Elective Courses (E1–E3)',   9, 3,  'Three elective courses from the approved elective list'),
    ('university_req',     'University Requirements (UC1–UC7)',  14, 7,  'Seven university mandatory requirement courses'),
    ('university_elective','University Electives (UE1–UE3)',      6, 3,  'Three university elective courses'),
    ('graduation_project', 'Graduation Project (GP1 + GP2)',      4, 2,  'CSE493 + CSE494 senior standing required for GP1'),
    ('field_training',     'Field Training (FT1 + FT2)',          4, 2,  'CSE191 + CSE292')
) AS v(cat, label, credits, num_courses, notes)
WHERE p.code = 'CS'
ON CONFLICT DO NOTHING;

-- ============================================================
-- END OF MIGRATION
-- Next: run 006_seed_courses.sql to populate course catalog
-- ============================================================
