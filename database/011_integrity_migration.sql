-- ============================================================
-- EduGuard AI — Integrity Migration Script
-- File    : database/011_integrity_migration.sql
-- Purpose : Apply C1-C6 integrity fixes to an EXISTING live
--           database WITHOUT dropping or recreating tables.
--           Safe to run on a populated production database.
-- Run     : psql -U <user> -d <db> -f 011_integrity_migration.sql
-- ============================================================

BEGIN;

-- ============================================================
-- SECTION 1: Fix C2/C3 — Replace destructive ON DELETE CASCADE
-- on academic record tables with RESTRICT or SET NULL.
--
-- Strategy: DROP the existing FK constraint, re-add with
-- corrected delete behavior. All done inside a transaction
-- so any failure rolls back completely.
-- ============================================================

-- 1a. enrollments → students  (CASCADE → RESTRICT)
ALTER TABLE enrollments
    DROP CONSTRAINT IF EXISTS enrollments_student_id_fkey,
    ADD  CONSTRAINT enrollments_student_id_fkey
         FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE RESTRICT;

-- 1b. enrollments → courses  (CASCADE → RESTRICT)
ALTER TABLE enrollments
    DROP CONSTRAINT IF EXISTS enrollments_course_id_fkey,
    ADD  CONSTRAINT enrollments_course_id_fkey
         FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE RESTRICT;

-- 1c. attendances → students  (CASCADE → RESTRICT)
ALTER TABLE attendances
    DROP CONSTRAINT IF EXISTS attendances_student_id_fkey,
    ADD  CONSTRAINT attendances_student_id_fkey
         FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE RESTRICT;

-- 1d. attendances → courses  (CASCADE → RESTRICT)
ALTER TABLE attendances
    DROP CONSTRAINT IF EXISTS attendances_course_id_fkey,
    ADD  CONSTRAINT attendances_course_id_fkey
         FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE RESTRICT;

-- 1e. grade_records → students  (CASCADE → RESTRICT)
ALTER TABLE grade_records
    DROP CONSTRAINT IF EXISTS grade_records_student_id_fkey,
    ADD  CONSTRAINT grade_records_student_id_fkey
         FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE RESTRICT;

-- 1f. grade_records → courses  (CASCADE → RESTRICT)
ALTER TABLE grade_records
    DROP CONSTRAINT IF EXISTS grade_records_course_id_fkey,
    ADD  CONSTRAINT grade_records_course_id_fkey
         FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE RESTRICT;

-- 1g. quiz_submissions → quizzes  (CASCADE → RESTRICT)
ALTER TABLE quiz_submissions
    DROP CONSTRAINT IF EXISTS quiz_submissions_quiz_id_fkey,
    ADD  CONSTRAINT quiz_submissions_quiz_id_fkey
         FOREIGN KEY (quiz_id) REFERENCES quizzes(id) ON DELETE RESTRICT;

-- 1h. quiz_submissions → students  (CASCADE → RESTRICT)
ALTER TABLE quiz_submissions
    DROP CONSTRAINT IF EXISTS quiz_submissions_student_id_fkey,
    ADD  CONSTRAINT quiz_submissions_student_id_fkey
         FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE RESTRICT;

-- 1i. risk_assessments → students  (CASCADE → RESTRICT)
ALTER TABLE risk_assessments
    DROP CONSTRAINT IF EXISTS risk_assessments_student_id_fkey,
    ADD  CONSTRAINT risk_assessments_student_id_fkey
         FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE RESTRICT;

-- 1j. intervention_plans → students  (CASCADE → RESTRICT)
ALTER TABLE intervention_plans
    DROP CONSTRAINT IF EXISTS intervention_plans_student_id_fkey,
    ADD  CONSTRAINT intervention_plans_student_id_fkey
         FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE RESTRICT;

-- 1k. activity_logs → students  (CASCADE → SET NULL)
--     First make column nullable (was NOT NULL)
ALTER TABLE activity_logs
    ALTER COLUMN student_id DROP NOT NULL;
ALTER TABLE activity_logs
    DROP CONSTRAINT IF EXISTS activity_logs_student_id_fkey,
    ADD  CONSTRAINT activity_logs_student_id_fkey
         FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE SET NULL;

-- 1l. quizzes → courses  (CASCADE → RESTRICT)
ALTER TABLE quizzes
    DROP CONSTRAINT IF EXISTS quizzes_course_id_fkey,
    ADD  CONSTRAINT quizzes_course_id_fkey
         FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE RESTRICT;

-- 1m. quizzes → users (created_by)  (CASCADE → SET NULL)
--     First make column nullable (was NOT NULL)
ALTER TABLE quizzes
    ALTER COLUMN created_by DROP NOT NULL;
ALTER TABLE quizzes
    DROP CONSTRAINT IF EXISTS quizzes_created_by_fkey,
    ADD  CONSTRAINT quizzes_created_by_fkey
         FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL;

-- 1n. announcements → users (author_id)  (CASCADE → SET NULL)
ALTER TABLE announcements
    ALTER COLUMN author_id DROP NOT NULL;
ALTER TABLE announcements
    DROP CONSTRAINT IF EXISTS announcements_author_id_fkey,
    ADD  CONSTRAINT announcements_author_id_fkey
         FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE SET NULL;

-- 1o. announcements → courses  (CASCADE → SET NULL)
ALTER TABLE announcements
    DROP CONSTRAINT IF EXISTS announcements_course_id_fkey,
    ADD  CONSTRAINT announcements_course_id_fkey
         FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE SET NULL;

-- 1p. announcements → departments  (CASCADE → SET NULL)
ALTER TABLE announcements
    DROP CONSTRAINT IF EXISTS announcements_department_id_fkey,
    ADD  CONSTRAINT announcements_department_id_fkey
         FOREIGN KEY (department_id) REFERENCES departments(id) ON DELETE SET NULL;


-- ============================================================
-- SECTION 2: Soft-delete columns
-- Adds deleted_at to entities that must survive due to RESTRICT
-- constraints. Physical deletion is replaced by soft-delete.
-- ============================================================

ALTER TABLE students    ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ DEFAULT NULL;
ALTER TABLE professors  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ DEFAULT NULL;
ALTER TABLE courses     ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ DEFAULT NULL;
ALTER TABLE advisors    ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ DEFAULT NULL;

CREATE INDEX IF NOT EXISTS idx_students_deleted_at   ON students(deleted_at)   WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_professors_deleted_at ON professors(deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_courses_deleted_at    ON courses(deleted_at)    WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_advisors_deleted_at   ON advisors(deleted_at)   WHERE deleted_at IS NULL;


-- ============================================================
-- SECTION 3: C5 — Schema type sync
-- departments.id is BIGSERIAL in SQL but was Integer in ORM.
-- The column type in PostgreSQL is already bigint (BIGSERIAL).
-- This section adds the missing FK on head_professor_id which
-- the ORM also lacked.
-- ============================================================

ALTER TABLE departments
    DROP CONSTRAINT IF EXISTS fk_dept_head;

DO $$ BEGIN
    ALTER TABLE departments ADD CONSTRAINT fk_dept_head
        FOREIGN KEY (head_professor_id) REFERENCES professors(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;


-- ============================================================
-- SECTION 4: Verification queries
-- Run these after the migration to confirm integrity.
-- ============================================================

-- 4a. Confirm no CASCADE on academic record tables
SELECT
    tc.table_name,
    kcu.column_name,
    rc.delete_rule
FROM information_schema.table_constraints       tc
JOIN information_schema.key_column_usage        kcu ON kcu.constraint_name = tc.constraint_name
JOIN information_schema.referential_constraints rc  ON rc.constraint_name  = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_name IN (
      'enrollments','attendances','grade_records',
      'quiz_submissions','risk_assessments','intervention_plans',
      'activity_logs','quizzes','announcements'
  )
ORDER BY tc.table_name, kcu.column_name;

-- Expected: No row should show delete_rule = 'CASCADE' for academic record tables.

-- 4b. Confirm soft-delete columns exist
SELECT table_name, column_name, data_type, is_nullable
FROM information_schema.columns
WHERE column_name = 'deleted_at'
  AND table_name IN ('students','professors','courses','advisors')
ORDER BY table_name;

-- Expected: 4 rows, all with data_type = 'timestamp with time zone', is_nullable = YES

COMMIT;

-- ============================================================
-- END OF MIGRATION
-- ============================================================
