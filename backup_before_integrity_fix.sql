--
-- PostgreSQL database dump
--

\restrict KLRDScjCEl7MqvciU7LblMAAFYPBGarcVaauC5J63yoqOc2xaSdbJjYDI7bXbob

-- Dumped from database version 18.3
-- Dumped by pg_dump version 18.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: acad_status_new; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.acad_status_new AS ENUM (
    'active',
    'warning',
    'probation',
    'suspended',
    'dismissed',
    'graduated',
    'inactive',
    'leave'
);


ALTER TYPE public.acad_status_new OWNER TO postgres;

--
-- Name: acad_status_old; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.acad_status_old AS ENUM (
    'active',
    'warning',
    'probation',
    'suspended',
    'dismissed',
    'graduated',
    'inactive',
    'leave'
);


ALTER TYPE public.acad_status_old OWNER TO postgres;

--
-- Name: academic_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.academic_status AS ENUM (
    'active',
    'warning',
    'probation',
    'suspended',
    'dismissed',
    'graduated',
    'inactive',
    'leave'
);


ALTER TYPE public.academic_status OWNER TO postgres;

--
-- Name: achievement_category; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.achievement_category AS ENUM (
    'academic_standing',
    'course_completion',
    'gpa_milestone',
    'degree_progress',
    'transcript',
    'system'
);


ALTER TYPE public.achievement_category OWNER TO postgres;

--
-- Name: advising_plan_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.advising_plan_status AS ENUM (
    'draft',
    'submitted',
    'advisor_approved',
    'advisor_rejected',
    'registered',
    'archived'
);


ALTER TYPE public.advising_plan_status OWNER TO postgres;

--
-- Name: arv_trigger; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.arv_trigger AS ENUM (
    'grade_change',
    'gpa_recalculation',
    'status_change',
    'progress_update',
    'transcript_issue',
    'graduation_decision',
    'transfer_applied',
    'exemption_applied',
    'registrar_override'
);


ALTER TYPE public.arv_trigger OWNER TO postgres;

--
-- Name: attempt_result; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.attempt_result AS ENUM (
    'passed',
    'failed',
    'withdrawn',
    'incomplete',
    'in_progress'
);


ALTER TYPE public.attempt_result OWNER TO postgres;

--
-- Name: attendance_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.attendance_status AS ENUM (
    'present',
    'absent',
    'late',
    'excused'
);


ALTER TYPE public.attendance_status OWNER TO postgres;

--
-- Name: audit_action; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.audit_action AS ENUM (
    'grade_changed',
    'transcript_generated',
    'gpa_recalculated',
    'status_changed',
    'progress_updated',
    'graduation_decision',
    'override_applied',
    'note_added',
    'snapshot_created'
);


ALTER TYPE public.audit_action OWNER TO postgres;

--
-- Name: audit_event_type_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.audit_event_type_enum AS ENUM (
    'import_started',
    'import_completed',
    'import_failed',
    'validation_ran',
    'reconcile_ran',
    'mapping_applied',
    'row_inserted',
    'row_failed',
    'row_skipped',
    'duplicate_blocked'
);


ALTER TYPE public.audit_event_type_enum OWNER TO postgres;

--
-- Name: batch_status_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.batch_status_enum AS ENUM (
    'pending',
    'processing',
    'completed',
    'failed',
    'partially_completed'
);


ALTER TYPE public.batch_status_enum OWNER TO postgres;

--
-- Name: case_decision_from; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.case_decision_from AS ENUM (
    'submitted',
    'under_review',
    'approved',
    'rejected',
    'closed'
);


ALTER TYPE public.case_decision_from OWNER TO postgres;

--
-- Name: case_decision_to; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.case_decision_to AS ENUM (
    'submitted',
    'under_review',
    'approved',
    'rejected',
    'closed'
);


ALTER TYPE public.case_decision_to OWNER TO postgres;

--
-- Name: case_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.case_status AS ENUM (
    'submitted',
    'under_review',
    'approved',
    'rejected',
    'closed'
);


ALTER TYPE public.case_status OWNER TO postgres;

--
-- Name: case_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.case_type AS ENUM (
    'grade_appeal',
    'academic_petition',
    'exception_request',
    'course_waiver',
    'graduation_exception',
    'registration_exception',
    'transfer_credit_appeal'
);


ALTER TYPE public.case_type OWNER TO postgres;

--
-- Name: cohort_member_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.cohort_member_status AS ENUM (
    'active',
    'graduated',
    'delayed',
    'inactive'
);


ALTER TYPE public.cohort_member_status OWNER TO postgres;

--
-- Name: cohort_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.cohort_status AS ENUM (
    'active',
    'graduated',
    'delayed',
    'inactive'
);


ALTER TYPE public.cohort_status OWNER TO postgres;

--
-- Name: course_category; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.course_category AS ENUM (
    'core',
    'elective',
    'university_req',
    'university_elective',
    'field_training'
);


ALTER TYPE public.course_category OWNER TO postgres;

--
-- Name: course_status_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.course_status_type AS ENUM (
    'not_taken',
    'in_progress',
    'passed',
    'failed',
    'withdrawn',
    'transferred'
);


ALTER TYPE public.course_status_type OWNER TO postgres;

--
-- Name: doc_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.doc_status AS ENUM (
    'pending',
    'verified',
    'rejected',
    'expired'
);


ALTER TYPE public.doc_status OWNER TO postgres;

--
-- Name: doc_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.doc_type AS ENUM (
    'national_id',
    'passport',
    'birth_certificate',
    'high_school_cert',
    'transcript',
    'transfer_document',
    'graduation_document',
    'photo',
    'other'
);


ALTER TYPE public.doc_type OWNER TO postgres;

--
-- Name: enrollment_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.enrollment_status AS ENUM (
    'active',
    'dropped',
    'completed',
    'withdrawn'
);


ALTER TYPE public.enrollment_status OWNER TO postgres;

--
-- Name: exemption_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.exemption_status AS ENUM (
    'pending',
    'approved',
    'rejected',
    'revoked'
);


ALTER TYPE public.exemption_status OWNER TO postgres;

--
-- Name: exemption_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.exemption_type AS ENUM (
    'course_exemption',
    'requirement_exemption',
    'curriculum_exemption'
);


ALTER TYPE public.exemption_type OWNER TO postgres;

--
-- Name: file_format_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.file_format_enum AS ENUM (
    'csv',
    'xlsx',
    'json'
);


ALTER TYPE public.file_format_enum OWNER TO postgres;

--
-- Name: grad_eligibility; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.grad_eligibility AS ENUM (
    'eligible',
    'conditionally_eligible',
    'not_eligible'
);


ALTER TYPE public.grad_eligibility OWNER TO postgres;

--
-- Name: grade_stage; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.grade_stage AS ENUM (
    'draft',
    'reviewed',
    'final'
);


ALTER TYPE public.grade_stage OWNER TO postgres;

--
-- Name: honors_level_rec; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.honors_level_rec AS ENUM (
    'none',
    'pass',
    'good',
    'very_good',
    'excellent',
    'distinction',
    'honors',
    'high_honors'
);


ALTER TYPE public.honors_level_rec OWNER TO postgres;

--
-- Name: honors_level_snap; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.honors_level_snap AS ENUM (
    'none',
    'pass',
    'good',
    'very_good',
    'excellent',
    'distinction',
    'honors',
    'high_honors'
);


ALTER TYPE public.honors_level_snap OWNER TO postgres;

--
-- Name: import_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.import_status AS ENUM (
    'pending',
    'processing',
    'completed',
    'failed',
    'partial'
);


ALTER TYPE public.import_status OWNER TO postgres;

--
-- Name: import_type_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.import_type_enum AS ENUM (
    'students',
    'transcripts',
    'curriculum'
);


ALTER TYPE public.import_type_enum OWNER TO postgres;

--
-- Name: intervention_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.intervention_status AS ENUM (
    'pending',
    'active',
    'completed',
    'cancelled'
);


ALTER TYPE public.intervention_status OWNER TO postgres;

--
-- Name: mt_import_type_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.mt_import_type_enum AS ENUM (
    'students',
    'transcripts',
    'curriculum'
);


ALTER TYPE public.mt_import_type_enum OWNER TO postgres;

--
-- Name: mt_source_system_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.mt_source_system_enum AS ENUM (
    'registrar',
    'sis',
    'erp',
    'curriculum',
    'manual',
    'api',
    'unknown'
);


ALTER TYPE public.mt_source_system_enum OWNER TO postgres;

--
-- Name: note_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.note_type AS ENUM (
    'registrar',
    'advisor',
    'academic',
    'flag',
    'decision'
);


ALTER TYPE public.note_type OWNER TO postgres;

--
-- Name: notification_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.notification_type AS ENUM (
    'risk_alert',
    'intervention',
    'quiz',
    'grade',
    'system',
    'attendance'
);


ALTER TYPE public.notification_type OWNER TO postgres;

--
-- Name: pdf_job_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.pdf_job_status AS ENUM (
    'queued',
    'processing',
    'complete',
    'failed'
);


ALTER TYPE public.pdf_job_status OWNER TO postgres;

--
-- Name: priority_level; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.priority_level AS ENUM (
    'low',
    'medium',
    'high'
);


ALTER TYPE public.priority_level OWNER TO postgres;

--
-- Name: question_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.question_type AS ENUM (
    'multiple_choice',
    'true_false',
    'short_answer',
    'essay'
);


ALTER TYPE public.question_type OWNER TO postgres;

--
-- Name: quiz_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.quiz_status AS ENUM (
    'draft',
    'published',
    'closed',
    'archived'
);


ALTER TYPE public.quiz_status OWNER TO postgres;

--
-- Name: recon_status_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.recon_status_enum AS ENUM (
    'open',
    'resolved',
    'ignored'
);


ALTER TYPE public.recon_status_enum OWNER TO postgres;

--
-- Name: recon_type_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.recon_type_enum AS ENUM (
    'duplicate',
    'conflict',
    'mismatch'
);


ALTER TYPE public.recon_type_enum OWNER TO postgres;

--
-- Name: reg_event_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.reg_event_type AS ENUM (
    'registration_created',
    'course_added',
    'course_dropped',
    'withdrawal',
    're_registration',
    'override',
    'approval',
    'registrar_intervention',
    'lock',
    'unlock'
);


ALTER TYPE public.reg_event_type OWNER TO postgres;

--
-- Name: reg_task_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.reg_task_type AS ENUM (
    'review_appeal',
    'approve_transfer',
    'review_exemption',
    'approve_transcript',
    'review_exception',
    'pending_override',
    'graduation_review',
    'general'
);


ALTER TYPE public.reg_task_type OWNER TO postgres;

--
-- Name: req_category; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.req_category AS ENUM (
    'core',
    'elective',
    'university_req',
    'university_elective',
    'field_training',
    'graduation_project'
);


ALTER TYPE public.req_category OWNER TO postgres;

--
-- Name: risk_level; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.risk_level AS ENUM (
    'Normal',
    'Low',
    'High',
    'Critical'
);


ALTER TYPE public.risk_level OWNER TO postgres;

--
-- Name: risk_level_s4; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.risk_level_s4 AS ENUM (
    'low',
    'medium',
    'high',
    'critical'
);


ALTER TYPE public.risk_level_s4 OWNER TO postgres;

--
-- Name: rr_import_type_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.rr_import_type_enum AS ENUM (
    'students',
    'transcripts',
    'curriculum'
);


ALTER TYPE public.rr_import_type_enum OWNER TO postgres;

--
-- Name: s2_calendar_period; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.s2_calendar_period AS ENUM (
    'registration',
    'add_drop',
    'withdrawal',
    'midterm',
    'final_exam',
    'grade_submission',
    'graduation_review',
    'break'
);


ALTER TYPE public.s2_calendar_period OWNER TO postgres;

--
-- Name: s2_notif_channel; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.s2_notif_channel AS ENUM (
    'in_app',
    'email',
    'sms'
);


ALTER TYPE public.s2_notif_channel OWNER TO postgres;

--
-- Name: s2_notif_event; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.s2_notif_event AS ENUM (
    'registration_eligible',
    'academic_risk',
    'graduation_approaching',
    'missing_requirement',
    'registration_opening',
    'registration_closing',
    'grade_posted',
    'prerequisite_cleared',
    'plan_approved',
    'plan_rejected',
    'intervention_assigned',
    'cgpa_threshold_crossed',
    'academic_standing_change',
    'override_decision'
);


ALTER TYPE public.s2_notif_event OWNER TO postgres;

--
-- Name: s2_override_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.s2_override_status AS ENUM (
    'pending',
    'approved',
    'rejected',
    'expired'
);


ALTER TYPE public.s2_override_status OWNER TO postgres;

--
-- Name: s2_override_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.s2_override_type AS ENUM (
    'prerequisite_waiver',
    'registration_override',
    'graduation_override',
    'credit_load_override',
    'grade_exception'
);


ALTER TYPE public.s2_override_type OWNER TO postgres;

--
-- Name: scan_verification_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.scan_verification_status AS ENUM (
    'verified',
    'duplicate',
    'expired_token',
    'invalid_token',
    'session_closed'
);


ALTER TYPE public.scan_verification_status OWNER TO postgres;

--
-- Name: scholarship_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.scholarship_status AS ENUM (
    'eligible',
    'not_eligible',
    'pending_policy_configuration'
);


ALTER TYPE public.scholarship_status OWNER TO postgres;

--
-- Name: session_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.session_status AS ENUM (
    'active',
    'expired',
    'closed'
);


ALTER TYPE public.session_status OWNER TO postgres;

--
-- Name: source_system_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.source_system_enum AS ENUM (
    'registrar',
    'sis',
    'erp',
    'curriculum',
    'manual',
    'api',
    'unknown'
);


ALTER TYPE public.source_system_enum OWNER TO postgres;

--
-- Name: submission_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.submission_status AS ENUM (
    'not_submitted',
    'submitted',
    'late',
    'reviewed'
);


ALTER TYPE public.submission_status OWNER TO postgres;

--
-- Name: ta_event_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.ta_event_type AS ENUM (
    'attendance',
    'quiz_score',
    'practical_score'
);


ALTER TYPE public.ta_event_type OWNER TO postgres;

--
-- Name: task_priority; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.task_priority AS ENUM (
    'low',
    'medium',
    'high',
    'urgent'
);


ALTER TYPE public.task_priority OWNER TO postgres;

--
-- Name: task_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.task_status AS ENUM (
    'open',
    'in_progress',
    'complete',
    'cancelled'
);


ALTER TYPE public.task_status OWNER TO postgres;

--
-- Name: term_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.term_type AS ENUM (
    'fall',
    'spring',
    'summer'
);


ALTER TYPE public.term_type OWNER TO postgres;

--
-- Name: timeline_event_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.timeline_event_type AS ENUM (
    'enrollment',
    'registration',
    'course_attempt',
    'grade_posted',
    'grade_changed',
    'gpa_recalculated',
    'cgpa_changed',
    'status_changed',
    'transcript_issued',
    'advisor_note',
    'registrar_action',
    'withdrawal',
    'graduation',
    'honors_awarded'
);


ALTER TYPE public.timeline_event_type OWNER TO postgres;

--
-- Name: transcript_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.transcript_type AS ENUM (
    'official',
    'unofficial',
    'semester',
    'graduation'
);


ALTER TYPE public.transcript_type OWNER TO postgres;

--
-- Name: transfer_credit_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.transfer_credit_status AS ENUM (
    'pending',
    'approved',
    'rejected',
    'partial'
);


ALTER TYPE public.transfer_credit_status OWNER TO postgres;

--
-- Name: user_role; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.user_role AS ENUM (
    'student',
    'professor',
    'advisor',
    'admin',
    'ta'
);


ALTER TYPE public.user_role OWNER TO postgres;

--
-- Name: val_category_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.val_category_enum AS ENUM (
    'referential',
    'academic',
    'curriculum',
    'integrity',
    'business'
);


ALTER TYPE public.val_category_enum OWNER TO postgres;

--
-- Name: val_severity_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.val_severity_enum AS ENUM (
    'error',
    'warning',
    'info'
);


ALTER TYPE public.val_severity_enum OWNER TO postgres;

--
-- Name: vr_category_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.vr_category_enum AS ENUM (
    'referential',
    'academic',
    'curriculum',
    'integrity',
    'business'
);


ALTER TYPE public.vr_category_enum OWNER TO postgres;

--
-- Name: vr_import_type_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.vr_import_type_enum AS ENUM (
    'students',
    'transcripts',
    'curriculum'
);


ALTER TYPE public.vr_import_type_enum OWNER TO postgres;

--
-- Name: vr_severity_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.vr_severity_enum AS ENUM (
    'error',
    'warning',
    'info'
);


ALTER TYPE public.vr_severity_enum OWNER TO postgres;

--
-- Name: vres_severity_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.vres_severity_enum AS ENUM (
    'error',
    'warning',
    'info'
);


ALTER TYPE public.vres_severity_enum OWNER TO postgres;

--
-- Name: audit_user_changes(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.audit_user_changes() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        INSERT INTO audit_logs (action, entity_type, entity_id, old_value)
        VALUES ('DELETE', TG_TABLE_NAME, OLD.id, to_jsonb(OLD));
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_logs (action, entity_type, entity_id, old_value, new_value)
        VALUES ('UPDATE', TG_TABLE_NAME, NEW.id, to_jsonb(OLD), to_jsonb(NEW));
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO audit_logs (action, entity_type, entity_id, new_value)
        VALUES ('INSERT', TG_TABLE_NAME, NEW.id, to_jsonb(NEW));
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$;


ALTER FUNCTION public.audit_user_changes() OWNER TO postgres;

--
-- Name: refresh_department_analytics(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.refresh_department_analytics() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_department_analytics;
END;
$$;


ALTER FUNCTION public.refresh_department_analytics() OWNER TO postgres;

--
-- Name: refresh_quiz_performance(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.refresh_quiz_performance() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_quiz_performance;
END;
$$;


ALTER FUNCTION public.refresh_quiz_performance() OWNER TO postgres;

--
-- Name: trigger_set_updated_at(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trigger_set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.trigger_set_updated_at() OWNER TO postgres;

--
-- Name: update_student_gpa(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_student_gpa() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE avg_grade NUMERIC;
BEGIN
    SELECT AVG(grade)
      INTO avg_grade
      FROM enrollments
     WHERE student_id = COALESCE(NEW.student_id, OLD.student_id)
       AND grade IS NOT NULL;

    UPDATE students
       SET gpa = LEAST(4.00, GREATEST(0.00,
                    ROUND(COALESCE(avg_grade, 0) / 25.0, 2)))
     WHERE id = COALESCE(NEW.student_id, OLD.student_id);

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_student_gpa() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: academic_achievements; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.academic_achievements (
    id bigint NOT NULL,
    student_id integer NOT NULL,
    term_id bigint,
    category public.achievement_category NOT NULL,
    title character varying(200) NOT NULL,
    description text,
    metric_key character varying(80),
    metric_value character varying(50),
    threshold_used character varying(50),
    rule_key_used character varying(80),
    policy_sourced boolean,
    achieved_at timestamp with time zone DEFAULT now(),
    awarded_by integer
);


ALTER TABLE public.academic_achievements OWNER TO postgres;

--
-- Name: TABLE academic_achievements; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.academic_achievements IS 'Academic Achievement Registry.
 Only achievements backed by document-sourced policies are recorded with policy_sourced=TRUE.
 Achievements that depend on PENDING thresholds are withheld until rules are configured.
 policy_sourced=FALSE records are flagged for review after rules are configured.';


--
-- Name: academic_achievements_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.academic_achievements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.academic_achievements_id_seq OWNER TO postgres;

--
-- Name: academic_achievements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.academic_achievements_id_seq OWNED BY public.academic_achievements.id;


--
-- Name: academic_audit_entries; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.academic_audit_entries (
    id bigint NOT NULL,
    student_id integer NOT NULL,
    term_id bigint,
    action public.audit_action NOT NULL,
    entity_type character varying(50),
    entity_id bigint,
    old_value jsonb,
    new_value jsonb,
    reason text,
    actor_id integer,
    actor_role character varying(20),
    ip_address character varying(45),
    occurred_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.academic_audit_entries OWNER TO postgres;

--
-- Name: academic_audit_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.academic_audit_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.academic_audit_entries_id_seq OWNER TO postgres;

--
-- Name: academic_audit_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.academic_audit_entries_id_seq OWNED BY public.academic_audit_entries.id;


--
-- Name: academic_calendar_periods; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.academic_calendar_periods (
    id bigint NOT NULL,
    term_id bigint NOT NULL,
    period_type public.s2_calendar_period NOT NULL,
    label character varying(100) NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    is_active boolean,
    notes text,
    created_by integer,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.academic_calendar_periods OWNER TO postgres;

--
-- Name: academic_calendar_periods_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.academic_calendar_periods_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.academic_calendar_periods_id_seq OWNER TO postgres;

--
-- Name: academic_calendar_periods_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.academic_calendar_periods_id_seq OWNED BY public.academic_calendar_periods.id;


--
-- Name: academic_case_decisions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.academic_case_decisions (
    id bigint NOT NULL,
    case_id bigint NOT NULL,
    from_status public.case_decision_from,
    to_status public.case_decision_to NOT NULL,
    decision text,
    notes text,
    decided_by integer,
    decided_at timestamp with time zone DEFAULT now(),
    payload jsonb
);


ALTER TABLE public.academic_case_decisions OWNER TO postgres;

--
-- Name: academic_case_decisions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.academic_case_decisions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.academic_case_decisions_id_seq OWNER TO postgres;

--
-- Name: academic_case_decisions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.academic_case_decisions_id_seq OWNED BY public.academic_case_decisions.id;


--
-- Name: academic_cases; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.academic_cases (
    id bigint NOT NULL,
    case_number character varying(30) NOT NULL,
    student_id integer NOT NULL,
    term_id bigint,
    course_id bigint,
    attempt_id bigint,
    case_type public.case_type NOT NULL,
    status public.case_status NOT NULL,
    title character varying(300) NOT NULL,
    description text NOT NULL,
    supporting_docs jsonb,
    assigned_to integer,
    assigned_at timestamp with time zone,
    resolution text,
    resolved_by integer,
    resolved_at timestamp with time zone,
    priority character varying(10),
    submitted_by integer,
    submitted_at timestamp with time zone DEFAULT now(),
    due_date timestamp with time zone,
    closed_at timestamp with time zone
);


ALTER TABLE public.academic_cases OWNER TO postgres;

--
-- Name: academic_cases_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.academic_cases_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.academic_cases_id_seq OWNER TO postgres;

--
-- Name: academic_cases_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.academic_cases_id_seq OWNED BY public.academic_cases.id;


--
-- Name: academic_decision_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.academic_decision_log (
    id bigint NOT NULL,
    decision_type character varying(50) NOT NULL,
    student_id integer NOT NULL,
    course_id integer,
    term_id bigint,
    outcome boolean NOT NULL,
    decision_reason text NOT NULL,
    rule_triggered character varying(100),
    explanation text,
    input_snapshot jsonb,
    output_snapshot jsonb,
    decided_by character varying(50),
    decided_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.academic_decision_log OWNER TO postgres;

--
-- Name: academic_decision_log_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.academic_decision_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.academic_decision_log_id_seq OWNER TO postgres;

--
-- Name: academic_decision_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.academic_decision_log_id_seq OWNED BY public.academic_decision_log.id;


--
-- Name: academic_exemptions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.academic_exemptions (
    id bigint NOT NULL,
    student_id integer NOT NULL,
    exemption_type public.exemption_type NOT NULL,
    status public.exemption_status,
    course_id bigint,
    course_code character varying(20),
    requirement_desc text,
    reason text NOT NULL,
    decision_notes text,
    supporting_doc_ids jsonb,
    approval_history jsonb,
    version smallint,
    requested_by integer,
    requested_at timestamp with time zone DEFAULT now(),
    reviewed_by integer,
    reviewed_at timestamp with time zone,
    approved_by integer,
    approved_at timestamp with time zone,
    revoked_at timestamp with time zone,
    revoke_reason text,
    applied_at timestamp with time zone
);


ALTER TABLE public.academic_exemptions OWNER TO postgres;

--
-- Name: academic_exemptions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.academic_exemptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.academic_exemptions_id_seq OWNER TO postgres;

--
-- Name: academic_exemptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.academic_exemptions_id_seq OWNED BY public.academic_exemptions.id;


--
-- Name: academic_override_history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.academic_override_history (
    id bigint NOT NULL,
    override_id bigint NOT NULL,
    action character varying(50) NOT NULL,
    performed_by integer,
    old_status character varying(30),
    new_status character varying(30),
    notes text,
    performed_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.academic_override_history OWNER TO postgres;

--
-- Name: academic_override_history_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.academic_override_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.academic_override_history_id_seq OWNER TO postgres;

--
-- Name: academic_override_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.academic_override_history_id_seq OWNED BY public.academic_override_history.id;


--
-- Name: academic_overrides; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.academic_overrides (
    id bigint NOT NULL,
    override_type public.s2_override_type NOT NULL,
    student_id integer NOT NULL,
    course_id integer,
    term_id bigint,
    requested_by integer NOT NULL,
    reviewed_by integer,
    status public.s2_override_status NOT NULL,
    reason text NOT NULL,
    reviewer_notes text,
    decision_reason text,
    rule_triggered character varying(100),
    explanation text,
    metadata_json jsonb,
    requested_at timestamp with time zone DEFAULT now(),
    reviewed_at timestamp with time zone,
    expires_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.academic_overrides OWNER TO postgres;

--
-- Name: academic_overrides_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.academic_overrides_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.academic_overrides_id_seq OWNER TO postgres;

--
-- Name: academic_overrides_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.academic_overrides_id_seq OWNED BY public.academic_overrides.id;


--
-- Name: academic_programs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.academic_programs (
    id bigint NOT NULL,
    department_id bigint,
    code character varying(20) NOT NULL,
    name character varying(150) NOT NULL,
    name_ar character varying(150),
    total_credit_hours smallint DEFAULT 134 NOT NULL,
    min_cgpa_grad numeric(3,2) DEFAULT 2.00,
    duration_years smallint DEFAULT 4,
    is_active boolean DEFAULT true,
    description text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.academic_programs OWNER TO postgres;

--
-- Name: academic_programs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.academic_programs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.academic_programs_id_seq OWNER TO postgres;

--
-- Name: academic_programs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.academic_programs_id_seq OWNED BY public.academic_programs.id;


--
-- Name: academic_record_versions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.academic_record_versions (
    id bigint NOT NULL,
    student_id integer NOT NULL,
    version_number integer NOT NULL,
    trigger public.arv_trigger NOT NULL,
    trigger_detail text,
    cgpa numeric(4,3),
    semester_gpa numeric(4,3),
    hours_attempted smallint,
    hours_earned smallint,
    quality_points numeric(8,3),
    academic_standing character varying(20),
    graduation_status character varying(30),
    degree_completion_pct numeric(5,2),
    record_snapshot jsonb NOT NULL,
    snapshot_hash character varying(64) NOT NULL,
    is_current boolean,
    authored_by integer,
    authored_at timestamp with time zone DEFAULT now(),
    notes text
);


ALTER TABLE public.academic_record_versions OWNER TO postgres;

--
-- Name: TABLE academic_record_versions; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.academic_record_versions IS 'Immutable academic record ledger. Every GPA, standing, progress, or graduation change creates a new version. Records are never overwritten.';


--
-- Name: academic_record_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.academic_record_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.academic_record_versions_id_seq OWNER TO postgres;

--
-- Name: academic_record_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.academic_record_versions_id_seq OWNED BY public.academic_record_versions.id;


--
-- Name: academic_risk_records; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.academic_risk_records (
    id bigint NOT NULL,
    student_id integer NOT NULL,
    term_id bigint,
    risk_level public.risk_level_s4 NOT NULL,
    risk_score numeric(5,4),
    gpa_trend numeric(5,4),
    cgpa_trend numeric(5,4),
    failed_courses_count smallint,
    repeated_courses_count smallint,
    withdrawal_count smallint,
    degree_completion_pct numeric(5,2),
    risk_factors jsonb,
    recommendations jsonb,
    assessed_by character varying(20),
    assessed_at timestamp with time zone DEFAULT now(),
    is_current boolean
);


ALTER TABLE public.academic_risk_records OWNER TO postgres;

--
-- Name: academic_risk_records_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.academic_risk_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.academic_risk_records_id_seq OWNER TO postgres;

--
-- Name: academic_risk_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.academic_risk_records_id_seq OWNED BY public.academic_risk_records.id;


--
-- Name: academic_rules_config; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.academic_rules_config (
    id bigint NOT NULL,
    program_id bigint,
    rule_key character varying(80) NOT NULL,
    rule_value character varying(50) NOT NULL,
    description text,
    updated_by integer,
    updated_at timestamp with time zone DEFAULT now(),
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.academic_rules_config OWNER TO postgres;

--
-- Name: academic_rules_config_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.academic_rules_config_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.academic_rules_config_id_seq OWNER TO postgres;

--
-- Name: academic_rules_config_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.academic_rules_config_id_seq OWNED BY public.academic_rules_config.id;


--
-- Name: academic_status_history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.academic_status_history (
    id bigint NOT NULL,
    student_id integer NOT NULL,
    term_id bigint,
    old_status public.acad_status_old,
    new_status public.acad_status_new NOT NULL,
    cgpa_at_change numeric(4,3),
    term_gpa_at_change numeric(4,3),
    reason text,
    actor_id integer,
    occurred_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.academic_status_history OWNER TO postgres;

--
-- Name: academic_status_history_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.academic_status_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.academic_status_history_id_seq OWNER TO postgres;

--
-- Name: academic_status_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.academic_status_history_id_seq OWNED BY public.academic_status_history.id;


--
-- Name: academic_terms; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.academic_terms (
    id bigint NOT NULL,
    code character varying(20) NOT NULL,
    name character varying(80) NOT NULL,
    term_type public.term_type NOT NULL,
    academic_year smallint NOT NULL,
    start_date date,
    end_date date,
    registration_start date,
    registration_end date,
    is_active boolean DEFAULT false,
    is_summer boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.academic_terms OWNER TO postgres;

--
-- Name: academic_terms_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.academic_terms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.academic_terms_id_seq OWNER TO postgres;

--
-- Name: academic_terms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.academic_terms_id_seq OWNED BY public.academic_terms.id;


--
-- Name: academic_timeline_events; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.academic_timeline_events (
    id bigint NOT NULL,
    student_id integer NOT NULL,
    term_id bigint,
    event_type public.timeline_event_type NOT NULL,
    title character varying(200) NOT NULL,
    description text,
    payload jsonb,
    actor_id integer,
    occurred_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.academic_timeline_events OWNER TO postgres;

--
-- Name: academic_timeline_events_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.academic_timeline_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.academic_timeline_events_id_seq OWNER TO postgres;

--
-- Name: academic_timeline_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.academic_timeline_events_id_seq OWNED BY public.academic_timeline_events.id;


--
-- Name: academic_tracks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.academic_tracks (
    id bigint NOT NULL,
    program_id bigint NOT NULL,
    code character varying(30) NOT NULL,
    name character varying(150) NOT NULL,
    name_ar character varying(150),
    is_active boolean DEFAULT true,
    description text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.academic_tracks OWNER TO postgres;

--
-- Name: academic_tracks_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.academic_tracks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.academic_tracks_id_seq OWNER TO postgres;

--
-- Name: academic_tracks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.academic_tracks_id_seq OWNED BY public.academic_tracks.id;


--
-- Name: activity_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.activity_logs (
    id integer NOT NULL,
    student_id integer NOT NULL,
    action character varying(100) NOT NULL,
    duration_minutes integer DEFAULT 0,
    resource_type character varying(50),
    resource_id bigint,
    metadata_json jsonb,
    "timestamp" timestamp with time zone DEFAULT now()
);


ALTER TABLE public.activity_logs OWNER TO postgres;

--
-- Name: activity_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.activity_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.activity_logs_id_seq OWNER TO postgres;

--
-- Name: activity_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.activity_logs_id_seq OWNED BY public.activity_logs.id;


--
-- Name: advising_plan_items; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.advising_plan_items (
    id bigint NOT NULL,
    plan_id bigint NOT NULL,
    course_id integer NOT NULL,
    offering_id bigint,
    priority_rank smallint DEFAULT 1,
    reason character varying(50),
    is_mandatory boolean DEFAULT false,
    notes text,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.advising_plan_items OWNER TO postgres;

--
-- Name: advising_plan_items_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.advising_plan_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.advising_plan_items_id_seq OWNER TO postgres;

--
-- Name: advising_plan_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.advising_plan_items_id_seq OWNED BY public.advising_plan_items.id;


--
-- Name: advising_plans; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.advising_plans (
    id bigint NOT NULL,
    student_id integer NOT NULL,
    advisor_id integer,
    term_id bigint NOT NULL,
    status public.advising_plan_status DEFAULT 'draft'::public.advising_plan_status NOT NULL,
    total_credits smallint DEFAULT 0,
    max_credits smallint DEFAULT 18,
    is_ai_generated boolean DEFAULT false,
    ai_model_version character varying(20),
    student_notes text,
    advisor_notes text,
    rejection_reason text,
    submitted_at timestamp with time zone,
    reviewed_at timestamp with time zone,
    approved_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.advising_plans OWNER TO postgres;

--
-- Name: advising_plans_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.advising_plans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.advising_plans_id_seq OWNER TO postgres;

--
-- Name: advising_plans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.advising_plans_id_seq OWNED BY public.advising_plans.id;


--
-- Name: advisors; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.advisors (
    id integer NOT NULL,
    user_id integer NOT NULL,
    department_id bigint,
    specialization character varying(150),
    max_students smallint DEFAULT 30,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.advisors OWNER TO postgres;

--
-- Name: advisors_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.advisors_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.advisors_id_seq OWNER TO postgres;

--
-- Name: advisors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.advisors_id_seq OWNED BY public.advisors.id;


--
-- Name: announcements; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.announcements (
    id bigint NOT NULL,
    title character varying(255) NOT NULL,
    content text NOT NULL,
    author_id integer NOT NULL,
    course_id integer,
    department_id bigint,
    is_global boolean DEFAULT false,
    published_at timestamp with time zone,
    expires_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.announcements OWNER TO postgres;

--
-- Name: announcements_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.announcements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.announcements_id_seq OWNER TO postgres;

--
-- Name: announcements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.announcements_id_seq OWNED BY public.announcements.id;


--
-- Name: assignment_submissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.assignment_submissions (
    id integer NOT NULL,
    assignment_id integer NOT NULL,
    student_id integer NOT NULL,
    submission_file character varying(500),
    submitted_at timestamp with time zone DEFAULT now(),
    status public.submission_status,
    grade double precision,
    feedback text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.assignment_submissions OWNER TO postgres;

--
-- Name: assignment_submissions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.assignment_submissions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.assignment_submissions_id_seq OWNER TO postgres;

--
-- Name: assignment_submissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.assignment_submissions_id_seq OWNED BY public.assignment_submissions.id;


--
-- Name: assignments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.assignments (
    id integer NOT NULL,
    title character varying(255) NOT NULL,
    description text,
    file_path character varying(500),
    uploaded_by integer,
    course_id integer,
    due_date timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.assignments OWNER TO postgres;

--
-- Name: assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.assignments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.assignments_id_seq OWNER TO postgres;

--
-- Name: assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.assignments_id_seq OWNED BY public.assignments.id;


--
-- Name: attendances; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.attendances (
    id integer NOT NULL,
    student_id integer NOT NULL,
    course_id integer NOT NULL,
    date date NOT NULL,
    status public.attendance_status DEFAULT 'absent'::public.attendance_status NOT NULL,
    notes text,
    recorded_by integer,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.attendances OWNER TO postgres;

--
-- Name: departments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.departments (
    id bigint NOT NULL,
    name character varying(150) NOT NULL,
    code character varying(20) NOT NULL,
    head_professor_id bigint,
    description text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.departments OWNER TO postgres;

--
-- Name: risk_assessments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.risk_assessments (
    id integer NOT NULL,
    student_id integer NOT NULL,
    risk_level public.risk_level NOT NULL,
    probability numeric(5,2) DEFAULT 0.00,
    grades_impact numeric(5,2) DEFAULT 0.00,
    attendance_impact numeric(5,2) DEFAULT 0.00,
    activity_impact numeric(5,2) DEFAULT 0.00,
    dropout_probability numeric(5,2) DEFAULT 0.00,
    graduation_delay_likelihood numeric(5,2) DEFAULT 0.00,
    scholarship_eligibility numeric(5,2) DEFAULT 100.00,
    trend character varying(30) DEFAULT 'stable'::character varying,
    explanation text,
    recommendations jsonb,
    features_snapshot jsonb,
    assessed_at timestamp with time zone DEFAULT now(),
    assessed_by character varying(50) DEFAULT 'ai_engine'::character varying,
    model_version character varying(20) DEFAULT 'v2.0'::character varying,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.risk_assessments OWNER TO postgres;

--
-- Name: students; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.students (
    id integer NOT NULL,
    user_id integer NOT NULL,
    student_number character varying(50) NOT NULL,
    department_id bigint,
    major character varying(100),
    year smallint,
    gpa numeric(3,2) DEFAULT 0.00,
    enrollment_date date DEFAULT CURRENT_DATE,
    phone character varying(30),
    address text,
    emergency_contact character varying(255),
    advisor_id bigint,
    is_scholarship boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    program_id bigint,
    track_id bigint,
    admission_term_id bigint,
    expected_grad_term_id bigint,
    academic_level smallint,
    cgpa numeric(4,3) DEFAULT 0.000,
    total_credit_hours_attempted smallint DEFAULT 0,
    total_credit_hours_earned smallint DEFAULT 0,
    total_quality_points numeric(8,3) DEFAULT 0.000,
    academic_standing character varying(20) DEFAULT 'good'::character varying,
    is_eligible_for_graduation boolean DEFAULT false,
    CONSTRAINT students_academic_level_check CHECK (((academic_level >= 1) AND (academic_level <= 4))),
    CONSTRAINT students_gpa_check CHECK (((gpa >= 0.00) AND (gpa <= 4.00))),
    CONSTRAINT students_year_check CHECK (((year >= 1) AND (year <= 6)))
);


ALTER TABLE public.students OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    email_verified_at timestamp with time zone,
    hashed_password character varying(255) NOT NULL,
    role public.user_role DEFAULT 'student'::public.user_role NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    avatar_url text,
    remember_token character varying(100),
    last_login timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: student_risk_summary; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.student_risk_summary AS
 SELECT s.id,
    u.name,
    u.email,
    s.student_number,
    s.major,
    s.year,
    s.gpa,
    s.is_scholarship,
    d.name AS department,
    ra.risk_level,
    ra.probability,
    ra.trend,
    ra.assessed_at,
    ra.dropout_probability,
    ra.graduation_delay_likelihood,
    ra.scholarship_eligibility,
    count(a.id) FILTER (WHERE (a.status = 'present'::public.attendance_status)) AS present_count,
    count(a.id) AS total_attendance,
    round(((100.0 * (count(a.id) FILTER (WHERE (a.status = 'present'::public.attendance_status)))::numeric) / (NULLIF(count(a.id), 0))::numeric), 1) AS attendance_pct
   FROM ((((public.students s
     JOIN public.users u ON ((u.id = s.user_id)))
     LEFT JOIN public.departments d ON ((d.id = s.department_id)))
     LEFT JOIN public.attendances a ON ((a.student_id = s.id)))
     LEFT JOIN LATERAL ( SELECT risk_assessments.id,
            risk_assessments.student_id,
            risk_assessments.risk_level,
            risk_assessments.probability,
            risk_assessments.grades_impact,
            risk_assessments.attendance_impact,
            risk_assessments.activity_impact,
            risk_assessments.dropout_probability,
            risk_assessments.graduation_delay_likelihood,
            risk_assessments.scholarship_eligibility,
            risk_assessments.trend,
            risk_assessments.explanation,
            risk_assessments.recommendations,
            risk_assessments.features_snapshot,
            risk_assessments.assessed_at,
            risk_assessments.assessed_by,
            risk_assessments.model_version,
            risk_assessments.created_at
           FROM public.risk_assessments
          WHERE (risk_assessments.student_id = s.id)
          ORDER BY risk_assessments.assessed_at DESC
         LIMIT 1) ra ON (true))
  GROUP BY s.id, u.name, u.email, s.student_number, s.major, s.year, s.gpa, s.is_scholarship, d.name, ra.risk_level, ra.probability, ra.trend, ra.assessed_at, ra.dropout_probability, ra.graduation_delay_likelihood, ra.scholarship_eligibility;


ALTER VIEW public.student_risk_summary OWNER TO postgres;

--
-- Name: VIEW student_risk_summary; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.student_risk_summary IS 'Latest AI risk assessment per student with attendance KPIs.';


--
-- Name: at_risk_students; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.at_risk_students AS
 SELECT id,
    name,
    email,
    student_number,
    major,
    year,
    gpa,
    is_scholarship,
    department,
    risk_level,
    probability,
    trend,
    assessed_at,
    dropout_probability,
    graduation_delay_likelihood,
    scholarship_eligibility,
    present_count,
    total_attendance,
    attendance_pct
   FROM public.student_risk_summary
  WHERE (risk_level = ANY (ARRAY['High'::public.risk_level, 'Critical'::public.risk_level]))
  ORDER BY probability DESC;


ALTER VIEW public.at_risk_students OWNER TO postgres;

--
-- Name: VIEW at_risk_students; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.at_risk_students IS 'Filtered view of students with High or Critical risk level.';


--
-- Name: attendance_scan_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.attendance_scan_log (
    id integer NOT NULL,
    session_id integer NOT NULL,
    student_id integer NOT NULL,
    qr_token_used character varying(128) NOT NULL,
    verification_status public.scan_verification_status NOT NULL,
    scanned_at timestamp with time zone DEFAULT now(),
    ip_address character varying(45),
    user_agent text,
    device_fingerprint character varying(255),
    attendance_id integer
);


ALTER TABLE public.attendance_scan_log OWNER TO postgres;

--
-- Name: attendance_scan_log_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.attendance_scan_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.attendance_scan_log_id_seq OWNER TO postgres;

--
-- Name: attendance_scan_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.attendance_scan_log_id_seq OWNED BY public.attendance_scan_log.id;


--
-- Name: attendance_sessions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.attendance_sessions (
    id integer NOT NULL,
    course_id integer NOT NULL,
    professor_id integer NOT NULL,
    lecture_topic character varying(255) NOT NULL,
    status public.session_status NOT NULL,
    started_at timestamp with time zone DEFAULT now(),
    ended_at timestamp with time zone,
    expires_at timestamp with time zone,
    current_qr_token character varying(128),
    token_issued_at timestamp with time zone,
    token_expires_at timestamp with time zone,
    token_rotation_sec smallint,
    total_present smallint,
    total_enrolled smallint,
    room character varying(100),
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.attendance_sessions OWNER TO postgres;

--
-- Name: attendance_sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.attendance_sessions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.attendance_sessions_id_seq OWNER TO postgres;

--
-- Name: attendance_sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.attendance_sessions_id_seq OWNED BY public.attendance_sessions.id;


--
-- Name: attendances_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.attendances_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.attendances_id_seq OWNER TO postgres;

--
-- Name: attendances_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.attendances_id_seq OWNED BY public.attendances.id;


--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.audit_logs (
    id integer NOT NULL,
    user_id integer,
    action character varying(100) NOT NULL,
    entity_type character varying(50),
    entity_id integer,
    old_value jsonb,
    new_value jsonb,
    ip_address inet,
    user_agent text,
    "timestamp" timestamp with time zone DEFAULT now()
);


ALTER TABLE public.audit_logs OWNER TO postgres;

--
-- Name: audit_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.audit_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.audit_logs_id_seq OWNER TO postgres;

--
-- Name: audit_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.audit_logs_id_seq OWNED BY public.audit_logs.id;


--
-- Name: cohort_memberships; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cohort_memberships (
    id bigint NOT NULL,
    student_id integer NOT NULL,
    cohort_id bigint NOT NULL,
    join_date date,
    expected_grad_date date,
    actual_grad_date date,
    is_delayed boolean,
    delay_reason text,
    semesters_completed smallint,
    status public.cohort_member_status,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.cohort_memberships OWNER TO postgres;

--
-- Name: cohort_memberships_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.cohort_memberships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cohort_memberships_id_seq OWNER TO postgres;

--
-- Name: cohort_memberships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.cohort_memberships_id_seq OWNED BY public.cohort_memberships.id;


--
-- Name: courses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.courses (
    id integer NOT NULL,
    code character varying(20) NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    credits smallint DEFAULT 3,
    semester character varying(30),
    year smallint,
    professor_id integer,
    department_id bigint,
    max_students smallint DEFAULT 40,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    program_id bigint,
    track_id bigint,
    category public.course_category DEFAULT 'core'::public.course_category,
    curriculum_level smallint,
    plan_semester smallint,
    lct_hours smallint DEFAULT 2,
    lab_hours smallint DEFAULT 0,
    tut_hours smallint DEFAULT 0,
    oth_hours smallint DEFAULT 0,
    contact_hours smallint DEFAULT 2,
    ects_credits smallint DEFAULT 4,
    slot_label character varying(10),
    swl_hours smallint DEFAULT 90,
    counts_in_cgpa boolean DEFAULT true,
    is_pass_fail boolean DEFAULT false,
    pass_threshold numeric(5,2) DEFAULT 60.00,
    name_ar character varying(255),
    CONSTRAINT courses_credits_check CHECK (((credits >= 1) AND (credits <= 6))),
    CONSTRAINT courses_curriculum_level_check CHECK (((curriculum_level >= 1) AND (curriculum_level <= 4))),
    CONSTRAINT courses_plan_semester_check CHECK (((plan_semester >= 1) AND (plan_semester <= 8)))
);


ALTER TABLE public.courses OWNER TO postgres;

--
-- Name: enrollments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.enrollments (
    id integer NOT NULL,
    student_id integer NOT NULL,
    course_id integer NOT NULL,
    status character varying(20) DEFAULT 'active'::character varying,
    grade numeric(4,2),
    letter_grade character varying(5),
    enrolled_at timestamp with time zone DEFAULT now(),
    dropped_at timestamp with time zone,
    completed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT enrollments_grade_check CHECK (((grade >= 0.00) AND (grade <= 100.00)))
);


ALTER TABLE public.enrollments OWNER TO postgres;

--
-- Name: course_analytics; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.course_analytics AS
 SELECT c.id,
    c.code,
    c.name,
    c.semester,
    c.year,
    c.credits,
    c.max_students,
    count(DISTINCT e.student_id) AS enrolled_count,
    round(avg(e.grade), 2) AS avg_grade,
    count(DISTINCT a.id) FILTER (WHERE (a.status = 'present'::public.attendance_status)) AS total_present,
    count(DISTINCT a.id) AS total_attendance_records,
    round(((100.0 * (count(DISTINCT a.id) FILTER (WHERE (a.status = 'present'::public.attendance_status)))::numeric) / (NULLIF(count(DISTINCT a.id), 0))::numeric), 1) AS attendance_pct
   FROM ((public.courses c
     LEFT JOIN public.enrollments e ON (((e.course_id = c.id) AND ((e.status)::text = 'active'::text))))
     LEFT JOIN public.attendances a ON ((a.course_id = c.id)))
  GROUP BY c.id, c.code, c.name, c.semester, c.year, c.credits, c.max_students;


ALTER VIEW public.course_analytics OWNER TO postgres;

--
-- Name: VIEW course_analytics; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.course_analytics IS 'Enrollment, grade, and attendance aggregates per course.';


--
-- Name: course_eligibility_rules; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.course_eligibility_rules (
    id bigint NOT NULL,
    course_id integer NOT NULL,
    rule_type character varying(30) NOT NULL,
    rule_value numeric(6,2),
    rule_text text,
    is_mandatory boolean DEFAULT true,
    notes text,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.course_eligibility_rules OWNER TO postgres;

--
-- Name: course_eligibility_rules_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.course_eligibility_rules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.course_eligibility_rules_id_seq OWNER TO postgres;

--
-- Name: course_eligibility_rules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.course_eligibility_rules_id_seq OWNED BY public.course_eligibility_rules.id;


--
-- Name: course_grade_weights; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.course_grade_weights (
    id integer NOT NULL,
    course_id integer NOT NULL,
    attendance_weight numeric(4,2),
    quiz_weight numeric(4,2),
    practical_weight numeric(4,2),
    coursework_weight numeric(4,2),
    max_quiz_score numeric(5,2),
    max_practical numeric(5,2),
    total_sessions integer,
    updated_by integer,
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.course_grade_weights OWNER TO postgres;

--
-- Name: TABLE course_grade_weights; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.course_grade_weights IS 'Professor-configurable grade weight formula';


--
-- Name: course_grade_weights_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.course_grade_weights_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.course_grade_weights_id_seq OWNER TO postgres;

--
-- Name: course_grade_weights_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.course_grade_weights_id_seq OWNED BY public.course_grade_weights.id;


--
-- Name: course_offerings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.course_offerings (
    id bigint NOT NULL,
    course_id integer NOT NULL,
    term_id bigint NOT NULL,
    professor_id integer,
    section character varying(20) DEFAULT 'A'::character varying,
    max_capacity smallint DEFAULT 40,
    current_enrolled smallint DEFAULT 0,
    room character varying(50),
    schedule_json jsonb,
    is_open boolean DEFAULT true,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.course_offerings OWNER TO postgres;

--
-- Name: course_offerings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.course_offerings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.course_offerings_id_seq OWNER TO postgres;

--
-- Name: course_offerings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.course_offerings_id_seq OWNED BY public.course_offerings.id;


--
-- Name: course_postrequisites; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.course_postrequisites (
    id bigint NOT NULL,
    course_id integer NOT NULL,
    postreq_id integer NOT NULL,
    unlock_type character varying(5) DEFAULT 'C'::character varying,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT course_postrequisites_check CHECK ((course_id <> postreq_id))
);


ALTER TABLE public.course_postrequisites OWNER TO postgres;

--
-- Name: course_postrequisites_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.course_postrequisites_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.course_postrequisites_id_seq OWNER TO postgres;

--
-- Name: course_postrequisites_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.course_postrequisites_id_seq OWNED BY public.course_postrequisites.id;


--
-- Name: course_prerequisites; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.course_prerequisites (
    id bigint NOT NULL,
    course_id integer NOT NULL,
    prerequisite_id integer NOT NULL,
    prereq_type character varying(10) DEFAULT 'hard'::character varying NOT NULL,
    min_grade numeric(5,2) DEFAULT 60.00,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    logic_group smallint DEFAULT 1,
    logic_type character varying(5) DEFAULT 'AND'::character varying,
    CONSTRAINT course_prerequisites_check CHECK ((course_id <> prerequisite_id))
);


ALTER TABLE public.course_prerequisites OWNER TO postgres;

--
-- Name: course_prerequisites_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.course_prerequisites_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.course_prerequisites_id_seq OWNER TO postgres;

--
-- Name: course_prerequisites_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.course_prerequisites_id_seq OWNED BY public.course_prerequisites.id;


--
-- Name: course_sections; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.course_sections (
    id bigint NOT NULL,
    course_id integer NOT NULL,
    ta_id bigint,
    section_name character varying(50) NOT NULL,
    schedule jsonb,
    room character varying(50),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.course_sections OWNER TO postgres;

--
-- Name: course_sections_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.course_sections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.course_sections_id_seq OWNER TO postgres;

--
-- Name: course_sections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.course_sections_id_seq OWNED BY public.course_sections.id;


--
-- Name: courses_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.courses_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.courses_id_seq OWNER TO postgres;

--
-- Name: courses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.courses_id_seq OWNED BY public.courses.id;


--
-- Name: degree_progress_snapshots; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.degree_progress_snapshots (
    id bigint NOT NULL,
    student_id integer NOT NULL,
    term_id bigint,
    version smallint,
    required_credits smallint NOT NULL,
    earned_credits smallint,
    remaining_credits smallint,
    completion_percentage numeric(5,2),
    category_breakdown jsonb,
    missing_core_courses jsonb,
    missing_elective_slots smallint,
    missing_categories jsonb,
    all_core_complete boolean,
    all_electives_complete boolean,
    field_training_complete boolean,
    graduation_project_complete boolean,
    computed_at timestamp with time zone DEFAULT now(),
    computed_by integer
);


ALTER TABLE public.degree_progress_snapshots OWNER TO postgres;

--
-- Name: degree_progress_snapshots_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.degree_progress_snapshots_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.degree_progress_snapshots_id_seq OWNER TO postgres;

--
-- Name: degree_progress_snapshots_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.degree_progress_snapshots_id_seq OWNED BY public.degree_progress_snapshots.id;


--
-- Name: departments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.departments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.departments_id_seq OWNER TO postgres;

--
-- Name: departments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.departments_id_seq OWNED BY public.departments.id;


--
-- Name: elective_pool_courses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.elective_pool_courses (
    id bigint NOT NULL,
    pool_id bigint NOT NULL,
    course_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.elective_pool_courses OWNER TO postgres;

--
-- Name: elective_pool_courses_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.elective_pool_courses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.elective_pool_courses_id_seq OWNER TO postgres;

--
-- Name: elective_pool_courses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.elective_pool_courses_id_seq OWNED BY public.elective_pool_courses.id;


--
-- Name: elective_pools; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.elective_pools (
    id bigint NOT NULL,
    program_id bigint,
    track_id bigint,
    pool_code character varying(20) NOT NULL,
    pool_name character varying(150) NOT NULL,
    min_selections smallint NOT NULL,
    max_selections smallint NOT NULL,
    required_selections smallint NOT NULL,
    plan_semesters character varying(50),
    notes text,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.elective_pools OWNER TO postgres;

--
-- Name: elective_pools_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.elective_pools_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.elective_pools_id_seq OWNER TO postgres;

--
-- Name: elective_pools_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.elective_pools_id_seq OWNED BY public.elective_pools.id;


--
-- Name: enrollments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.enrollments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.enrollments_id_seq OWNER TO postgres;

--
-- Name: enrollments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.enrollments_id_seq OWNED BY public.enrollments.id;


--
-- Name: gpa_explanations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.gpa_explanations (
    id bigint NOT NULL,
    student_id integer NOT NULL,
    term_id bigint,
    formula_description text NOT NULL,
    repeat_policy character varying(30) NOT NULL,
    included_attempts jsonb,
    excluded_attempts jsonb,
    total_quality_points numeric(8,3),
    total_hours_attempted smallint,
    computed_cgpa numeric(4,3),
    semester_quality_points numeric(8,3),
    semester_hours_attempted smallint,
    computed_semester_gpa numeric(4,3),
    all_rules_sourced boolean,
    policy_notes jsonb,
    generated_at timestamp with time zone DEFAULT now(),
    is_current boolean
);


ALTER TABLE public.gpa_explanations OWNER TO postgres;

--
-- Name: TABLE gpa_explanations; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.gpa_explanations IS 'GPA Audit Explainability Engine.
 Every CGPA calculation is fully traceable to individual course attempt rows.
 Excluded courses have documented, source-cited reasons for exclusion.
 Formula source: CGPA_Calculator.xlsx, verified against calculator output.
 Repeat policy source: academic_rules_config repeat_policy key.';


--
-- Name: gpa_explanations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.gpa_explanations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.gpa_explanations_id_seq OWNER TO postgres;

--
-- Name: gpa_explanations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.gpa_explanations_id_seq OWNED BY public.gpa_explanations.id;


--
-- Name: gpa_projections; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.gpa_projections (
    id bigint NOT NULL,
    student_id integer NOT NULL,
    term_id bigint,
    projection_type character varying(50) NOT NULL,
    current_cgpa numeric(4,3),
    current_credits smallint,
    target_cgpa numeric(4,3),
    remaining_credits smallint,
    scenario_input jsonb,
    projection_result jsonb,
    projected_semester_gpa numeric(4,3),
    projected_cgpa numeric(4,3),
    is_achievable boolean,
    computed_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.gpa_projections OWNER TO postgres;

--
-- Name: gpa_projections_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.gpa_projections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.gpa_projections_id_seq OWNER TO postgres;

--
-- Name: gpa_projections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.gpa_projections_id_seq OWNED BY public.gpa_projections.id;


--
-- Name: gpa_versions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.gpa_versions (
    id bigint NOT NULL,
    student_id integer NOT NULL,
    term_id bigint,
    version_number integer NOT NULL,
    semester_gpa numeric(4,3),
    cgpa numeric(4,3),
    total_hours_attempted smallint,
    total_hours_earned smallint,
    total_quality_points numeric(8,3),
    cgpa_delta numeric(5,4),
    gpa_delta numeric(5,4),
    trigger_event character varying(100),
    trigger_details jsonb,
    repeat_policy_used character varying(30),
    computed_by integer,
    recorded_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.gpa_versions OWNER TO postgres;

--
-- Name: TABLE gpa_versions; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.gpa_versions IS 'Immutable GPA version ledger. One row per GPA change event.
 Repeat policy is recorded with each version so historical calculations
 can be reproduced exactly.
 Formula source: CGPA_Calculator.xlsx â€” verified: 100.70/78 = 1.291025641.';


--
-- Name: gpa_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.gpa_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.gpa_versions_id_seq OWNER TO postgres;

--
-- Name: gpa_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.gpa_versions_id_seq OWNED BY public.gpa_versions.id;


--
-- Name: grade_records; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.grade_records (
    id bigint NOT NULL,
    student_id integer NOT NULL,
    course_id integer NOT NULL,
    assessment_type character varying(50) NOT NULL,
    assessment_name character varying(255),
    score numeric(5,2) NOT NULL,
    max_score numeric(5,2) NOT NULL,
    weight numeric(5,2) DEFAULT 1.00,
    graded_at timestamp with time zone DEFAULT now(),
    graded_by integer,
    notes text,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.grade_records OWNER TO postgres;

--
-- Name: grade_records_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.grade_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.grade_records_id_seq OWNER TO postgres;

--
-- Name: grade_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.grade_records_id_seq OWNED BY public.grade_records.id;


--
-- Name: grade_scale; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.grade_scale (
    id integer NOT NULL,
    program_id bigint,
    letter_grade character varying(5) NOT NULL,
    min_percentage numeric(5,2),
    max_percentage numeric(5,2),
    grade_points numeric(3,2) NOT NULL,
    counts_in_cgpa boolean DEFAULT true,
    is_passing boolean DEFAULT true,
    description character varying(50),
    failure_type character varying(20)
);


ALTER TABLE public.grade_scale OWNER TO postgres;

--
-- Name: grade_scale_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.grade_scale_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.grade_scale_id_seq OWNER TO postgres;

--
-- Name: grade_scale_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.grade_scale_id_seq OWNED BY public.grade_scale.id;


--
-- Name: grading_audit_trail; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.grading_audit_trail AS
 SELECT al.id,
    al."timestamp",
    u.name AS actor_name,
    u.role AS actor_role,
    al.action,
    al.entity_type,
    al.entity_id,
    al.old_value,
    al.new_value,
    (al.new_value ->> 'student_name'::text) AS student_name
   FROM (public.audit_logs al
     JOIN public.users u ON ((u.id = al.user_id)))
  WHERE ((al.entity_type)::text = ANY ((ARRAY['ta_grade_event'::character varying, 'grade_version'::character varying, 'grade_aggregate'::character varying])::text[]))
  ORDER BY al."timestamp" DESC;


ALTER VIEW public.grading_audit_trail OWNER TO postgres;

--
-- Name: graduation_audit_results; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.graduation_audit_results (
    id bigint NOT NULL,
    student_id integer NOT NULL,
    audited_at timestamp with time zone DEFAULT now(),
    is_eligible boolean NOT NULL,
    total_ch_required smallint NOT NULL,
    total_ch_earned smallint NOT NULL,
    core_courses_required smallint,
    core_courses_completed smallint,
    electives_required smallint,
    electives_completed smallint,
    field_training_done boolean,
    graduation_project_done boolean,
    univ_req_done boolean,
    cgpa_at_audit numeric(4,3),
    blocking_reasons jsonb,
    completed_requirements jsonb,
    missing_courses jsonb,
    audit_version character varying(20),
    triggered_by character varying(50),
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.graduation_audit_results OWNER TO postgres;

--
-- Name: graduation_audit_results_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.graduation_audit_results_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.graduation_audit_results_id_seq OWNER TO postgres;

--
-- Name: graduation_audit_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.graduation_audit_results_id_seq OWNED BY public.graduation_audit_results.id;


--
-- Name: graduation_eligibility_records; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.graduation_eligibility_records (
    id bigint NOT NULL,
    student_id integer NOT NULL,
    term_id bigint,
    eligibility_status public.grad_eligibility NOT NULL,
    requirements_met jsonb,
    missing_requirements jsonb,
    cgpa_at_evaluation numeric(4,3),
    credits_at_evaluation smallint,
    evaluated_by integer,
    evaluated_at timestamp with time zone DEFAULT now(),
    notes text,
    is_current boolean
);


ALTER TABLE public.graduation_eligibility_records OWNER TO postgres;

--
-- Name: graduation_eligibility_records_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.graduation_eligibility_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.graduation_eligibility_records_id_seq OWNER TO postgres;

--
-- Name: graduation_eligibility_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.graduation_eligibility_records_id_seq OWNED BY public.graduation_eligibility_records.id;


--
-- Name: graduation_requirements; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.graduation_requirements (
    id bigint NOT NULL,
    program_id bigint NOT NULL,
    track_id bigint,
    category public.req_category NOT NULL,
    label character varying(80) NOT NULL,
    required_credits smallint NOT NULL,
    required_courses smallint DEFAULT 0,
    min_cgpa numeric(3,2) DEFAULT 2.00,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.graduation_requirements OWNER TO postgres;

--
-- Name: graduation_requirements_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.graduation_requirements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.graduation_requirements_id_seq OWNER TO postgres;

--
-- Name: graduation_requirements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.graduation_requirements_id_seq OWNED BY public.graduation_requirements.id;


--
-- Name: honors_records; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.honors_records (
    id bigint NOT NULL,
    student_id integer NOT NULL,
    term_id bigint,
    honors_level public.honors_level_rec NOT NULL,
    is_deans_list boolean,
    term_gpa_used numeric(4,3),
    cgpa_used numeric(4,3),
    credits_used smallint,
    qualification_data jsonb,
    awarded_at timestamp with time zone DEFAULT now(),
    awarded_by integer
);


ALTER TABLE public.honors_records OWNER TO postgres;

--
-- Name: honors_records_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.honors_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.honors_records_id_seq OWNER TO postgres;

--
-- Name: honors_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.honors_records_id_seq OWNED BY public.honors_records.id;


--
-- Name: import_audit_events; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.import_audit_events (
    id bigint NOT NULL,
    batch_id bigint NOT NULL,
    event_type public.audit_event_type_enum NOT NULL,
    actor_id integer,
    row_number integer,
    message text,
    payload jsonb,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.import_audit_events OWNER TO postgres;

--
-- Name: import_audit_events_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.import_audit_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.import_audit_events_id_seq OWNER TO postgres;

--
-- Name: import_audit_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.import_audit_events_id_seq OWNED BY public.import_audit_events.id;


--
-- Name: import_batches; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.import_batches (
    id bigint NOT NULL,
    batch_ref character varying(64) NOT NULL,
    file_hash character varying(64) NOT NULL,
    file_name character varying(512) NOT NULL,
    file_size_bytes bigint,
    file_format public.file_format_enum NOT NULL,
    import_type public.import_type_enum NOT NULL,
    source_system public.source_system_enum NOT NULL,
    status public.batch_status_enum NOT NULL,
    total_rows integer,
    success_rows integer,
    failed_rows integer,
    skipped_rows integer,
    warning_count integer,
    imported_by integer,
    assigned_to integer,
    started_at timestamp with time zone,
    completed_at timestamp with time zone,
    duration_ms integer,
    retry_count smallint,
    is_reprocess boolean,
    mapping_version_id bigint,
    notes text,
    extra_meta jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.import_batches OWNER TO postgres;

--
-- Name: import_batches_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.import_batches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.import_batches_id_seq OWNER TO postgres;

--
-- Name: import_batches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.import_batches_id_seq OWNED BY public.import_batches.id;


--
-- Name: import_errors; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.import_errors (
    id bigint NOT NULL,
    job_id bigint NOT NULL,
    row_number integer,
    field_name character varying(100),
    raw_value text,
    error_message text,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.import_errors OWNER TO postgres;

--
-- Name: import_errors_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.import_errors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.import_errors_id_seq OWNER TO postgres;

--
-- Name: import_errors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.import_errors_id_seq OWNED BY public.import_errors.id;


--
-- Name: import_jobs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.import_jobs (
    id bigint NOT NULL,
    job_type character varying(50) NOT NULL,
    status public.import_status DEFAULT 'pending'::public.import_status NOT NULL,
    file_name character varying(255),
    file_size_bytes bigint,
    total_rows integer DEFAULT 0,
    processed_rows integer DEFAULT 0,
    success_rows integer DEFAULT 0,
    error_rows integer DEFAULT 0,
    initiated_by integer,
    started_at timestamp with time zone,
    completed_at timestamp with time zone,
    error_summary text,
    metadata_json jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.import_jobs OWNER TO postgres;

--
-- Name: import_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.import_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.import_jobs_id_seq OWNER TO postgres;

--
-- Name: import_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.import_jobs_id_seq OWNED BY public.import_jobs.id;


--
-- Name: import_row_errors; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.import_row_errors (
    id bigint NOT NULL,
    batch_id bigint NOT NULL,
    row_number integer,
    field_name character varying(100),
    raw_value text,
    error_code character varying(50),
    error_message text NOT NULL,
    severity public.val_severity_enum NOT NULL,
    category public.val_category_enum,
    extra_context jsonb,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.import_row_errors OWNER TO postgres;

--
-- Name: import_row_errors_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.import_row_errors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.import_row_errors_id_seq OWNER TO postgres;

--
-- Name: import_row_errors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.import_row_errors_id_seq OWNED BY public.import_row_errors.id;


--
-- Name: intervention_actions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.intervention_actions (
    id integer NOT NULL,
    plan_id integer NOT NULL,
    description text NOT NULL,
    completed boolean DEFAULT false,
    completed_at timestamp with time zone,
    due_date timestamp with time zone,
    order_index smallint DEFAULT 0,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.intervention_actions OWNER TO postgres;

--
-- Name: intervention_actions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.intervention_actions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.intervention_actions_id_seq OWNER TO postgres;

--
-- Name: intervention_actions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.intervention_actions_id_seq OWNED BY public.intervention_actions.id;


--
-- Name: intervention_plans; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.intervention_plans (
    id integer NOT NULL,
    student_id integer NOT NULL,
    advisor_id integer,
    title character varying(255) NOT NULL,
    description text,
    status public.intervention_status DEFAULT 'pending'::public.intervention_status,
    priority public.priority_level DEFAULT 'medium'::public.priority_level,
    deadline timestamp with time zone,
    completed_at timestamp with time zone,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.intervention_plans OWNER TO postgres;

--
-- Name: intervention_overview; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.intervention_overview AS
 SELECT ip.id AS plan_id,
    ip.title,
    ip.status,
    ip.priority,
    ip.deadline,
    s.student_number,
    u_s.name AS student_name,
    u_a.name AS advisor_name,
    count(ia.id) AS total_actions,
    count(ia.id) FILTER (WHERE (ia.completed = true)) AS completed_actions,
    round(((100.0 * (count(ia.id) FILTER (WHERE (ia.completed = true)))::numeric) / (NULLIF(count(ia.id), 0))::numeric), 1) AS completion_pct
   FROM (((((public.intervention_plans ip
     JOIN public.students s ON ((s.id = ip.student_id)))
     JOIN public.users u_s ON ((u_s.id = s.user_id)))
     JOIN public.advisors adv ON ((adv.id = ip.advisor_id)))
     JOIN public.users u_a ON ((u_a.id = adv.user_id)))
     LEFT JOIN public.intervention_actions ia ON ((ia.plan_id = ip.id)))
  GROUP BY ip.id, ip.title, ip.status, ip.priority, ip.deadline, s.student_number, u_s.name, u_a.name;


ALTER VIEW public.intervention_overview OWNER TO postgres;

--
-- Name: VIEW intervention_overview; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.intervention_overview IS 'Intervention plans with advisor info and action completion progress.';


--
-- Name: intervention_plans_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.intervention_plans_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.intervention_plans_id_seq OWNER TO postgres;

--
-- Name: intervention_plans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.intervention_plans_id_seq OWNED BY public.intervention_plans.id;


--
-- Name: mapping_template_versions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mapping_template_versions (
    id bigint NOT NULL,
    template_id bigint NOT NULL,
    version_number smallint NOT NULL,
    field_mappings jsonb NOT NULL,
    transformations jsonb,
    is_current boolean,
    published_by integer,
    published_at timestamp with time zone DEFAULT now(),
    notes text
);


ALTER TABLE public.mapping_template_versions OWNER TO postgres;

--
-- Name: mapping_template_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.mapping_template_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.mapping_template_versions_id_seq OWNER TO postgres;

--
-- Name: mapping_template_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.mapping_template_versions_id_seq OWNED BY public.mapping_template_versions.id;


--
-- Name: mapping_templates; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mapping_templates (
    id bigint NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    import_type public.mt_import_type_enum NOT NULL,
    source_system public.mt_source_system_enum NOT NULL,
    is_active boolean,
    created_by integer,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.mapping_templates OWNER TO postgres;

--
-- Name: mapping_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.mapping_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.mapping_templates_id_seq OWNER TO postgres;

--
-- Name: mapping_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.mapping_templates_id_seq OWNED BY public.mapping_templates.id;


--
-- Name: mv_department_analytics; Type: MATERIALIZED VIEW; Schema: public; Owner: postgres
--

CREATE MATERIALIZED VIEW public.mv_department_analytics AS
 SELECT COALESCE(d.name, s.major, 'Unknown'::character varying) AS department,
    d.code,
    count(DISTINCT s.id) AS total_students,
    count(DISTINCT
        CASE
            WHEN (ra.risk_level = ANY (ARRAY['High'::public.risk_level, 'Critical'::public.risk_level])) THEN s.id
            ELSE NULL::integer
        END) AS at_risk_count,
    round(((100.0 * (count(DISTINCT
        CASE
            WHEN (ra.risk_level = ANY (ARRAY['High'::public.risk_level, 'Critical'::public.risk_level])) THEN s.id
            ELSE NULL::integer
        END))::numeric) / (NULLIF(count(DISTINCT s.id), 0))::numeric), 1) AS at_risk_pct,
    round(avg(s.gpa), 2) AS avg_gpa,
    round(avg(ra.dropout_probability), 2) AS avg_dropout_risk,
    count(DISTINCT ip.id) AS active_interventions,
    count(DISTINCT
        CASE
            WHEN s.is_scholarship THEN s.id
            ELSE NULL::integer
        END) AS scholarship_count
   FROM (((public.students s
     LEFT JOIN public.departments d ON ((d.id = s.department_id)))
     LEFT JOIN LATERAL ( SELECT risk_assessments.id,
            risk_assessments.student_id,
            risk_assessments.risk_level,
            risk_assessments.probability,
            risk_assessments.grades_impact,
            risk_assessments.attendance_impact,
            risk_assessments.activity_impact,
            risk_assessments.dropout_probability,
            risk_assessments.graduation_delay_likelihood,
            risk_assessments.scholarship_eligibility,
            risk_assessments.trend,
            risk_assessments.explanation,
            risk_assessments.recommendations,
            risk_assessments.features_snapshot,
            risk_assessments.assessed_at,
            risk_assessments.assessed_by,
            risk_assessments.model_version,
            risk_assessments.created_at
           FROM public.risk_assessments
          WHERE (risk_assessments.student_id = s.id)
          ORDER BY risk_assessments.assessed_at DESC
         LIMIT 1) ra ON (true))
     LEFT JOIN public.intervention_plans ip ON (((ip.student_id = s.id) AND (ip.status = 'active'::public.intervention_status))))
  GROUP BY d.name, d.code, s.major
  WITH NO DATA;


ALTER MATERIALIZED VIEW public.mv_department_analytics OWNER TO postgres;

--
-- Name: MATERIALIZED VIEW mv_department_analytics; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON MATERIALIZED VIEW public.mv_department_analytics IS 'Department-level KPIs. Refresh with refresh_department_analytics().';


--
-- Name: quiz_submissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.quiz_submissions (
    id integer NOT NULL,
    quiz_id integer NOT NULL,
    student_id integer NOT NULL,
    answers_json jsonb DEFAULT '{}'::jsonb,
    score numeric(5,2),
    max_score numeric(5,2),
    percentage numeric(5,2),
    passed boolean,
    attempt_number smallint DEFAULT 1 NOT NULL,
    time_taken_minutes integer,
    submitted_at timestamp with time zone DEFAULT now(),
    graded_at timestamp with time zone,
    graded_by integer,
    feedback text
);


ALTER TABLE public.quiz_submissions OWNER TO postgres;

--
-- Name: quizzes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.quizzes (
    id integer NOT NULL,
    title character varying(255) NOT NULL,
    description text,
    course_id integer NOT NULL,
    created_by integer NOT NULL,
    duration_minutes integer DEFAULT 60 NOT NULL,
    attempts_limit smallint DEFAULT 1 NOT NULL,
    start_time timestamp with time zone,
    end_time timestamp with time zone,
    shuffle_questions boolean DEFAULT false,
    randomize_options boolean DEFAULT false,
    show_results boolean DEFAULT true,
    passing_score numeric(5,2) DEFAULT 60.00,
    status public.quiz_status DEFAULT 'draft'::public.quiz_status NOT NULL,
    total_points integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    secure_mode boolean DEFAULT false,
    require_fullscreen boolean DEFAULT false,
    detect_focus_loss boolean DEFAULT true,
    detect_tab_switch boolean DEFAULT true,
    block_copy_paste boolean DEFAULT true,
    block_right_click boolean DEFAULT true,
    block_shortcuts boolean DEFAULT true,
    detect_devtools boolean DEFAULT true,
    max_violations integer DEFAULT 3,
    auto_submit_on_limit boolean DEFAULT true,
    warning_message text
);


ALTER TABLE public.quizzes OWNER TO postgres;

--
-- Name: mv_quiz_performance; Type: MATERIALIZED VIEW; Schema: public; Owner: postgres
--

CREATE MATERIALIZED VIEW public.mv_quiz_performance AS
 SELECT q.id AS quiz_id,
    q.title,
    q.course_id,
    c.code AS course_code,
    q.passing_score,
    q.total_points,
    count(qs.id) AS total_submissions,
    round(avg(qs.percentage), 2) AS avg_percentage,
    round(min(qs.percentage), 2) AS min_percentage,
    round(max(qs.percentage), 2) AS max_percentage,
    count(qs.id) FILTER (WHERE (qs.passed = true)) AS passed_count,
    round(((100.0 * (count(qs.id) FILTER (WHERE (qs.passed = true)))::numeric) / (NULLIF(count(qs.id), 0))::numeric), 1) AS pass_rate_pct
   FROM ((public.quizzes q
     JOIN public.courses c ON ((c.id = q.course_id)))
     LEFT JOIN public.quiz_submissions qs ON ((qs.quiz_id = q.id)))
  GROUP BY q.id, q.title, q.course_id, c.code, q.passing_score, q.total_points
  WITH NO DATA;


ALTER MATERIALIZED VIEW public.mv_quiz_performance OWNER TO postgres;

--
-- Name: MATERIALIZED VIEW mv_quiz_performance; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON MATERIALIZED VIEW public.mv_quiz_performance IS 'Quiz pass rates and score stats. Refresh with refresh_quiz_performance().';


--
-- Name: notification_delivery_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notification_delivery_log (
    id bigint NOT NULL,
    notification_id integer NOT NULL,
    channel public.s2_notif_channel NOT NULL,
    event_type public.s2_notif_event,
    sent_at timestamp with time zone DEFAULT now(),
    delivered boolean,
    error_message text,
    metadata_json jsonb
);


ALTER TABLE public.notification_delivery_log OWNER TO postgres;

--
-- Name: notification_delivery_log_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.notification_delivery_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.notification_delivery_log_id_seq OWNER TO postgres;

--
-- Name: notification_delivery_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.notification_delivery_log_id_seq OWNED BY public.notification_delivery_log.id;


--
-- Name: notification_preferences; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notification_preferences (
    id integer NOT NULL,
    user_id integer NOT NULL,
    event_type public.s2_notif_event NOT NULL,
    in_app boolean,
    email boolean,
    sms boolean,
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.notification_preferences OWNER TO postgres;

--
-- Name: notification_preferences_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.notification_preferences_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.notification_preferences_id_seq OWNER TO postgres;

--
-- Name: notification_preferences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.notification_preferences_id_seq OWNED BY public.notification_preferences.id;


--
-- Name: notification_templates; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notification_templates (
    id integer NOT NULL,
    event_type public.s2_notif_event NOT NULL,
    channel public.s2_notif_channel NOT NULL,
    subject_template text NOT NULL,
    body_template text NOT NULL,
    priority character varying(10),
    is_active boolean,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.notification_templates OWNER TO postgres;

--
-- Name: notification_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.notification_templates_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.notification_templates_id_seq OWNER TO postgres;

--
-- Name: notification_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.notification_templates_id_seq OWNED BY public.notification_templates.id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notifications (
    id integer NOT NULL,
    user_id integer NOT NULL,
    title character varying(255) NOT NULL,
    message text,
    type public.notification_type DEFAULT 'system'::public.notification_type NOT NULL,
    priority public.priority_level DEFAULT 'low'::public.priority_level NOT NULL,
    read boolean DEFAULT false,
    read_at timestamp with time zone,
    metadata jsonb,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.notifications OWNER TO postgres;

--
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.notifications_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.notifications_id_seq OWNER TO postgres;

--
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.notifications_id_seq OWNED BY public.notifications.id;


--
-- Name: pdf_transcript_jobs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pdf_transcript_jobs (
    id bigint NOT NULL,
    student_id integer NOT NULL,
    transcript_version_id bigint,
    transcript_type character varying(20),
    status public.pdf_job_status,
    page_count smallint,
    file_size_bytes integer,
    result_key character varying(500),
    error_message text,
    options jsonb,
    requested_by integer,
    queued_at timestamp with time zone DEFAULT now(),
    started_at timestamp with time zone,
    completed_at timestamp with time zone,
    expires_at timestamp with time zone
);


ALTER TABLE public.pdf_transcript_jobs OWNER TO postgres;

--
-- Name: pdf_transcript_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pdf_transcript_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pdf_transcript_jobs_id_seq OWNER TO postgres;

--
-- Name: pdf_transcript_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pdf_transcript_jobs_id_seq OWNED BY public.pdf_transcript_jobs.id;


--
-- Name: personal_access_tokens; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.personal_access_tokens (
    id bigint NOT NULL,
    tokenable_type character varying(255) NOT NULL,
    tokenable_id bigint NOT NULL,
    name character varying(255) NOT NULL,
    token character varying(64) NOT NULL,
    abilities text,
    last_used_at timestamp with time zone,
    expires_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.personal_access_tokens OWNER TO postgres;

--
-- Name: personal_access_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.personal_access_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.personal_access_tokens_id_seq OWNER TO postgres;

--
-- Name: personal_access_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.personal_access_tokens_id_seq OWNED BY public.personal_access_tokens.id;


--
-- Name: prerequisite_exceptions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.prerequisite_exceptions (
    id bigint NOT NULL,
    student_id integer NOT NULL,
    course_id integer NOT NULL,
    waived_prereq_id integer NOT NULL,
    granted_by integer,
    reason text NOT NULL,
    approved_at timestamp with time zone DEFAULT now(),
    expires_at timestamp with time zone,
    is_active boolean,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.prerequisite_exceptions OWNER TO postgres;

--
-- Name: prerequisite_exceptions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.prerequisite_exceptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.prerequisite_exceptions_id_seq OWNER TO postgres;

--
-- Name: prerequisite_exceptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.prerequisite_exceptions_id_seq OWNED BY public.prerequisite_exceptions.id;


--
-- Name: prerequisite_validation_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.prerequisite_validation_log (
    id bigint NOT NULL,
    student_id integer NOT NULL,
    course_id integer NOT NULL,
    term_id bigint,
    check_result boolean NOT NULL,
    missing_prereqs jsonb,
    rule_triggered character varying(100),
    explanation text,
    decision_reason text,
    checked_at timestamp with time zone DEFAULT now(),
    checked_by character varying(50)
);


ALTER TABLE public.prerequisite_validation_log OWNER TO postgres;

--
-- Name: prerequisite_validation_log_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.prerequisite_validation_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.prerequisite_validation_log_id_seq OWNER TO postgres;

--
-- Name: prerequisite_validation_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.prerequisite_validation_log_id_seq OWNED BY public.prerequisite_validation_log.id;


--
-- Name: prerequisite_validations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.prerequisite_validations (
    id bigint NOT NULL,
    student_id integer NOT NULL,
    term_id bigint,
    course_id bigint NOT NULL,
    course_code character varying(20) NOT NULL,
    is_eligible boolean NOT NULL,
    missing_prereqs jsonb,
    satisfied_prereqs jsonb,
    policy_source character varying(200),
    override_applied boolean,
    override_by integer,
    override_reason text,
    validated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.prerequisite_validations OWNER TO postgres;

--
-- Name: prerequisite_validations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.prerequisite_validations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.prerequisite_validations_id_seq OWNER TO postgres;

--
-- Name: prerequisite_validations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.prerequisite_validations_id_seq OWNED BY public.prerequisite_validations.id;


--
-- Name: professors; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.professors (
    id integer NOT NULL,
    user_id integer NOT NULL,
    department_id bigint,
    department character varying(100),
    title character varying(50),
    specialization character varying(150),
    office_location character varying(100),
    office_hours text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.professors OWNER TO postgres;

--
-- Name: professors_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.professors_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.professors_id_seq OWNER TO postgres;

--
-- Name: professors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.professors_id_seq OWNED BY public.professors.id;


--
-- Name: questions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.questions (
    id integer NOT NULL,
    quiz_id integer NOT NULL,
    type character varying(30) DEFAULT 'multiple_choice'::character varying NOT NULL,
    text text NOT NULL,
    options_json jsonb,
    correct_answer character varying(500),
    explanation text,
    points smallint DEFAULT 1 NOT NULL,
    order_index smallint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.questions OWNER TO postgres;

--
-- Name: questions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.questions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.questions_id_seq OWNER TO postgres;

--
-- Name: questions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.questions_id_seq OWNED BY public.questions.id;


--
-- Name: quiz_sessions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.quiz_sessions (
    id integer NOT NULL,
    quiz_id integer NOT NULL,
    student_id integer NOT NULL,
    started_at timestamp with time zone DEFAULT now() NOT NULL,
    ended_at timestamp with time zone,
    violation_count integer DEFAULT 0 NOT NULL,
    fullscreen_exits integer DEFAULT 0 NOT NULL,
    focus_losses integer DEFAULT 0 NOT NULL,
    tab_switches integer DEFAULT 0 NOT NULL,
    copy_attempts integer DEFAULT 0 NOT NULL,
    paste_attempts integer DEFAULT 0 NOT NULL,
    right_clicks integer DEFAULT 0 NOT NULL,
    devtools_attempts integer DEFAULT 0 NOT NULL,
    status character varying(30) DEFAULT 'active'::character varying NOT NULL,
    final_reason text,
    browser_info text,
    ip_address character varying(45)
);


ALTER TABLE public.quiz_sessions OWNER TO postgres;

--
-- Name: quiz_sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.quiz_sessions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.quiz_sessions_id_seq OWNER TO postgres;

--
-- Name: quiz_sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.quiz_sessions_id_seq OWNED BY public.quiz_sessions.id;


--
-- Name: quiz_submissions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.quiz_submissions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.quiz_submissions_id_seq OWNER TO postgres;

--
-- Name: quiz_submissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.quiz_submissions_id_seq OWNED BY public.quiz_submissions.id;


--
-- Name: quiz_violations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.quiz_violations (
    id integer NOT NULL,
    quiz_id integer NOT NULL,
    student_id integer NOT NULL,
    submission_id integer,
    violation_type character varying(60) NOT NULL,
    severity character varying(20) DEFAULT 'warning'::character varying NOT NULL,
    violation_count integer DEFAULT 1 NOT NULL,
    metadata_json text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.quiz_violations OWNER TO postgres;

--
-- Name: quiz_violations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.quiz_violations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.quiz_violations_id_seq OWNER TO postgres;

--
-- Name: quiz_violations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.quiz_violations_id_seq OWNED BY public.quiz_violations.id;


--
-- Name: quizzes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.quizzes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.quizzes_id_seq OWNER TO postgres;

--
-- Name: quizzes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.quizzes_id_seq OWNED BY public.quizzes.id;


--
-- Name: rbac_permissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.rbac_permissions (
    id integer NOT NULL,
    role character varying(30) NOT NULL,
    resource character varying(100) NOT NULL,
    action character varying(50) NOT NULL,
    conditions jsonb,
    is_active boolean,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.rbac_permissions OWNER TO postgres;

--
-- Name: rbac_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.rbac_permissions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rbac_permissions_id_seq OWNER TO postgres;

--
-- Name: rbac_permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.rbac_permissions_id_seq OWNED BY public.rbac_permissions.id;


--
-- Name: reconciliation_items; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reconciliation_items (
    id bigint NOT NULL,
    report_id bigint NOT NULL,
    recon_type public.recon_type_enum NOT NULL,
    entity_type character varying(50),
    entity_key character varying(255),
    incoming_value jsonb,
    existing_value jsonb,
    conflict_fields jsonb,
    status public.recon_status_enum NOT NULL,
    resolved_by integer,
    resolved_at timestamp with time zone,
    resolution_note text,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.reconciliation_items OWNER TO postgres;

--
-- Name: reconciliation_items_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.reconciliation_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.reconciliation_items_id_seq OWNER TO postgres;

--
-- Name: reconciliation_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.reconciliation_items_id_seq OWNED BY public.reconciliation_items.id;


--
-- Name: reconciliation_reports; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reconciliation_reports (
    id bigint NOT NULL,
    batch_id bigint NOT NULL,
    import_type public.rr_import_type_enum NOT NULL,
    total_checked integer,
    duplicates_found integer,
    conflicts_found integer,
    mismatches_found integer,
    summary jsonb,
    generated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.reconciliation_reports OWNER TO postgres;

--
-- Name: reconciliation_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.reconciliation_reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.reconciliation_reports_id_seq OWNER TO postgres;

--
-- Name: reconciliation_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.reconciliation_reports_id_seq OWNED BY public.reconciliation_reports.id;


--
-- Name: registrar_notes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.registrar_notes (
    id bigint NOT NULL,
    student_id integer NOT NULL,
    term_id bigint,
    note_type public.note_type NOT NULL,
    title character varying(200) NOT NULL,
    content text NOT NULL,
    tags jsonb,
    is_private boolean,
    version smallint,
    previous_version_id bigint,
    created_by integer,
    updated_by integer,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.registrar_notes OWNER TO postgres;

--
-- Name: registrar_notes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.registrar_notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.registrar_notes_id_seq OWNER TO postgres;

--
-- Name: registrar_notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.registrar_notes_id_seq OWNED BY public.registrar_notes.id;


--
-- Name: registrar_task_assignments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.registrar_task_assignments (
    id bigint NOT NULL,
    task_id bigint NOT NULL,
    assigned_to integer,
    assigned_by integer,
    assigned_at timestamp with time zone DEFAULT now(),
    unassigned_at timestamp with time zone,
    notes text
);


ALTER TABLE public.registrar_task_assignments OWNER TO postgres;

--
-- Name: registrar_task_assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.registrar_task_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.registrar_task_assignments_id_seq OWNER TO postgres;

--
-- Name: registrar_task_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.registrar_task_assignments_id_seq OWNED BY public.registrar_task_assignments.id;


--
-- Name: registrar_tasks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.registrar_tasks (
    id bigint NOT NULL,
    task_number character varying(30) NOT NULL,
    task_type public.reg_task_type NOT NULL,
    status public.task_status NOT NULL,
    priority public.task_priority,
    student_id integer,
    term_id bigint,
    case_id bigint,
    transfer_id bigint,
    exemption_id bigint,
    pdf_job_id bigint,
    title character varying(300) NOT NULL,
    description text,
    due_date timestamp with time zone,
    assigned_to integer,
    assigned_at timestamp with time zone,
    completed_by integer,
    completed_at timestamp with time zone,
    resolution_notes text,
    created_by integer,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.registrar_tasks OWNER TO postgres;

--
-- Name: registrar_tasks_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.registrar_tasks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.registrar_tasks_id_seq OWNER TO postgres;

--
-- Name: registrar_tasks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.registrar_tasks_id_seq OWNED BY public.registrar_tasks.id;


--
-- Name: registration_events; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.registration_events (
    id bigint NOT NULL,
    student_id integer NOT NULL,
    term_id bigint NOT NULL,
    course_id bigint,
    attempt_id bigint,
    event_type public.reg_event_type NOT NULL,
    event_detail text,
    payload jsonb,
    requires_approval boolean,
    approved_by integer,
    approved_at timestamp with time zone,
    rejection_reason text,
    actor_id integer,
    actor_role character varying(30),
    ip_address character varying(45),
    occurred_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.registration_events OWNER TO postgres;

--
-- Name: TABLE registration_events; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.registration_events IS 'Append-only registration event log. No hard deletes. Every registration action is recorded.';


--
-- Name: registration_events_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.registration_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.registration_events_id_seq OWNER TO postgres;

--
-- Name: registration_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.registration_events_id_seq OWNED BY public.registration_events.id;


--
-- Name: risk_assessments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.risk_assessments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.risk_assessments_id_seq OWNER TO postgres;

--
-- Name: risk_assessments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.risk_assessments_id_seq OWNED BY public.risk_assessments.id;


--
-- Name: scholarship_evaluations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.scholarship_evaluations (
    id bigint NOT NULL,
    student_id integer NOT NULL,
    term_id bigint,
    status public.scholarship_status NOT NULL,
    cgpa_at_evaluation numeric(4,3),
    credits_at_evaluation smallint,
    term_gpa_at_evaluation numeric(4,3),
    rules_applied jsonb,
    criteria_met jsonb,
    unmet_criteria jsonb,
    policy_gaps jsonb,
    notes text,
    evaluated_by integer,
    evaluated_at timestamp with time zone DEFAULT now(),
    is_current boolean
);


ALTER TABLE public.scholarship_evaluations OWNER TO postgres;

--
-- Name: TABLE scholarship_evaluations; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.scholarship_evaluations IS 'Scholarship eligibility evaluations. All thresholds sourced from academic_rules_config.
 Status = pending_policy_configuration when required rules are not yet configured.
 No assumed scholarship thresholds are ever used.';


--
-- Name: COLUMN scholarship_evaluations.policy_gaps; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.scholarship_evaluations.policy_gaps IS 'List of academic_rules_config keys that returned PENDING_POLICY_CONFIGURATION.
 Empty list = all required rules are configured.';


--
-- Name: scholarship_evaluations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.scholarship_evaluations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.scholarship_evaluations_id_seq OWNER TO postgres;

--
-- Name: scholarship_evaluations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.scholarship_evaluations_id_seq OWNED BY public.scholarship_evaluations.id;


--
-- Name: semester_snapshots; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.semester_snapshots (
    id bigint NOT NULL,
    student_id integer NOT NULL,
    term_id bigint NOT NULL,
    version smallint NOT NULL,
    term_gpa numeric(4,3) NOT NULL,
    cgpa_after_term numeric(4,3) NOT NULL,
    credits_attempted smallint,
    credits_earned smallint,
    credits_failed smallint,
    credits_withdrawn smallint,
    cumulative_attempted smallint,
    cumulative_earned smallint,
    academic_standing public.academic_status,
    honors_level public.honors_level_snap,
    dean_list_eligible boolean,
    risk_flags jsonb,
    snapshot_hash character varying(64),
    generated_by integer,
    generated_at timestamp with time zone DEFAULT now(),
    is_final boolean
);


ALTER TABLE public.semester_snapshots OWNER TO postgres;

--
-- Name: semester_snapshots_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.semester_snapshots_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.semester_snapshots_id_seq OWNER TO postgres;

--
-- Name: semester_snapshots_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.semester_snapshots_id_seq OWNED BY public.semester_snapshots.id;


--
-- Name: student_cohorts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.student_cohorts (
    id bigint NOT NULL,
    program_id bigint,
    track_id bigint,
    cohort_code character varying(40) NOT NULL,
    cohort_name character varying(120),
    intake_year smallint NOT NULL,
    intake_semester character varying(10) NOT NULL,
    intake_term_id bigint,
    expected_grad_term_id bigint,
    expected_grad_year smallint,
    total_semesters_planned smallint,
    status public.cohort_status,
    total_enrolled integer,
    total_graduated integer,
    total_delayed integer,
    total_withdrawn integer,
    avg_cgpa numeric(4,3),
    notes text,
    created_by integer,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.student_cohorts OWNER TO postgres;

--
-- Name: student_cohorts_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.student_cohorts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.student_cohorts_id_seq OWNER TO postgres;

--
-- Name: student_cohorts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.student_cohorts_id_seq OWNED BY public.student_cohorts.id;


--
-- Name: student_course_attempts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.student_course_attempts (
    id bigint NOT NULL,
    student_id integer NOT NULL,
    course_id integer NOT NULL,
    term_id bigint NOT NULL,
    attempt_number smallint DEFAULT 1 NOT NULL,
    numeric_grade numeric(5,2),
    letter_grade character varying(5),
    grade_points numeric(3,2),
    credit_hours smallint DEFAULT 3 NOT NULL,
    result public.attempt_result DEFAULT 'in_progress'::public.attempt_result NOT NULL,
    is_improvement_attempt boolean DEFAULT false,
    counts_in_cgpa boolean DEFAULT true,
    registered_at timestamp with time zone DEFAULT now(),
    grade_posted_at timestamp with time zone,
    withdrawn_at timestamp with time zone,
    graded_by integer,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT student_course_attempts_grade_points_check CHECK (((grade_points >= 0.00) AND (grade_points <= 4.00))),
    CONSTRAINT student_course_attempts_numeric_grade_check CHECK (((numeric_grade >= (0)::numeric) AND (numeric_grade <= (100)::numeric)))
);


ALTER TABLE public.student_course_attempts OWNER TO postgres;

--
-- Name: student_course_attempts_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.student_course_attempts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.student_course_attempts_id_seq OWNER TO postgres;

--
-- Name: student_course_attempts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.student_course_attempts_id_seq OWNED BY public.student_course_attempts.id;


--
-- Name: student_documents; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.student_documents (
    id bigint NOT NULL,
    student_id integer NOT NULL,
    document_type public.doc_type NOT NULL,
    document_number character varying(100),
    title character varying(200) NOT NULL,
    description text,
    storage_key character varying(500),
    file_name character varying(255),
    file_size_bytes integer,
    mime_type character varying(100),
    status public.doc_status,
    verification_status character varying(20),
    verified_by integer,
    verified_at timestamp with time zone,
    rejection_reason text,
    issue_date date,
    expiry_date date,
    upload_date timestamp with time zone DEFAULT now(),
    uploaded_by integer,
    revision_history jsonb,
    version smallint,
    is_active boolean,
    metadata jsonb
);


ALTER TABLE public.student_documents OWNER TO postgres;

--
-- Name: student_documents_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.student_documents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.student_documents_id_seq OWNER TO postgres;

--
-- Name: student_documents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.student_documents_id_seq OWNED BY public.student_documents.id;


--
-- Name: student_elective_selections; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.student_elective_selections (
    id bigint NOT NULL,
    student_id integer NOT NULL,
    pool_id bigint NOT NULL,
    course_id integer NOT NULL,
    term_id bigint,
    selected_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.student_elective_selections OWNER TO postgres;

--
-- Name: student_elective_selections_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.student_elective_selections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.student_elective_selections_id_seq OWNER TO postgres;

--
-- Name: student_elective_selections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.student_elective_selections_id_seq OWNED BY public.student_elective_selections.id;


--
-- Name: student_engagement_summary; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.student_engagement_summary AS
 SELECT s.id AS student_id,
    u.name AS student_name,
    s.gpa,
    count(al.id) AS total_actions,
    COALESCE(sum(al.duration_minutes), (0)::bigint) AS total_minutes,
    round(avg(al.duration_minutes), 1) AS avg_session_minutes,
    count(al.id) FILTER (WHERE ((al.action)::text = 'quiz_attempt'::text)) AS quiz_attempts,
    count(al.id) FILTER (WHERE ((al.action)::text = 'course_view'::text)) AS course_views,
    count(al.id) FILTER (WHERE ((al.action)::text = 'material_view'::text)) AS material_views,
    max(al."timestamp") AS last_active_at
   FROM ((public.students s
     JOIN public.users u ON ((u.id = s.user_id)))
     LEFT JOIN public.activity_logs al ON (((al.student_id = s.id) AND (al."timestamp" >= (now() - '30 days'::interval)))))
  GROUP BY s.id, u.name, s.gpa;


ALTER VIEW public.student_engagement_summary OWNER TO postgres;

--
-- Name: VIEW student_engagement_summary; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.student_engagement_summary IS 'LMS engagement metrics per student for the last 30 days.';


--
-- Name: student_grade_aggregates; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.student_grade_aggregates (
    id integer NOT NULL,
    student_id integer NOT NULL,
    course_id integer NOT NULL,
    total_sessions integer,
    attended_sessions integer,
    attendance_rate numeric(5,2),
    quiz_scores_json jsonb,
    quiz_avg numeric(5,2),
    quiz_total numeric(5,2),
    practical_scores_json jsonb,
    practical_score_total numeric(5,2),
    weighted_score numeric(5,2),
    last_computed_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.student_grade_aggregates OWNER TO postgres;

--
-- Name: TABLE student_grade_aggregates; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.student_grade_aggregates IS 'Auto-computed grade summaries per student/course';


--
-- Name: student_grade_aggregates_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.student_grade_aggregates_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.student_grade_aggregates_id_seq OWNER TO postgres;

--
-- Name: student_grade_aggregates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.student_grade_aggregates_id_seq OWNED BY public.student_grade_aggregates.id;


--
-- Name: student_grade_versions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.student_grade_versions (
    id integer NOT NULL,
    student_id integer NOT NULL,
    course_id integer NOT NULL,
    stage public.grade_stage NOT NULL,
    version_number integer NOT NULL,
    attendance_rate numeric(5,2),
    quiz_avg numeric(5,2),
    practical_total numeric(5,2),
    weighted_score numeric(5,2),
    bonus_marks numeric(5,2),
    coursework_marks numeric(5,2),
    professor_notes text,
    final_grade numeric(5,2),
    submitted_by_ta integer,
    reviewed_by_prof integer,
    approved_by_admin integer,
    submitted_at timestamp with time zone,
    reviewed_at timestamp with time zone,
    approved_at timestamp with time zone,
    snapshot_json jsonb,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.student_grade_versions OWNER TO postgres;

--
-- Name: TABLE student_grade_versions; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.student_grade_versions IS 'Versioned grade snapshots: draftâ†’reviewedâ†’final';


--
-- Name: student_grade_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.student_grade_versions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.student_grade_versions_id_seq OWNER TO postgres;

--
-- Name: student_grade_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.student_grade_versions_id_seq OWNED BY public.student_grade_versions.id;


--
-- Name: student_graduation_progress; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.student_graduation_progress (
    id bigint NOT NULL,
    student_id integer NOT NULL,
    requirement_id bigint NOT NULL,
    credits_completed smallint DEFAULT 0,
    credits_remaining smallint DEFAULT 0,
    courses_completed smallint DEFAULT 0,
    courses_remaining smallint DEFAULT 0,
    completion_pct numeric(5,2) DEFAULT 0.00,
    last_computed_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.student_graduation_progress OWNER TO postgres;

--
-- Name: student_graduation_progress_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.student_graduation_progress_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.student_graduation_progress_id_seq OWNER TO postgres;

--
-- Name: student_graduation_progress_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.student_graduation_progress_id_seq OWNED BY public.student_graduation_progress.id;


--
-- Name: student_term_gpa; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.student_term_gpa (
    id bigint NOT NULL,
    student_id integer NOT NULL,
    term_id bigint NOT NULL,
    term_credit_hours_attempted smallint DEFAULT 0 NOT NULL,
    term_credit_hours_earned smallint DEFAULT 0 NOT NULL,
    term_quality_points numeric(8,3) DEFAULT 0.000,
    term_gpa numeric(4,3) DEFAULT 0.000,
    cumulative_hours_attempted smallint DEFAULT 0 NOT NULL,
    cumulative_hours_earned smallint DEFAULT 0 NOT NULL,
    cumulative_quality_points numeric(8,3) DEFAULT 0.000,
    cgpa numeric(4,3) DEFAULT 0.000,
    academic_standing character varying(20) DEFAULT 'good'::character varying,
    is_summer boolean DEFAULT false,
    finalized boolean DEFAULT false,
    finalized_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.student_term_gpa OWNER TO postgres;

--
-- Name: student_term_gpa_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.student_term_gpa_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.student_term_gpa_id_seq OWNER TO postgres;

--
-- Name: student_term_gpa_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.student_term_gpa_id_seq OWNED BY public.student_term_gpa.id;


--
-- Name: students_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.students_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.students_id_seq OWNER TO postgres;

--
-- Name: students_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.students_id_seq OWNED BY public.students.id;


--
-- Name: ta_grade_events; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ta_grade_events (
    id integer NOT NULL,
    ta_user_id integer NOT NULL,
    student_id integer NOT NULL,
    course_id integer NOT NULL,
    event_type public.ta_event_type NOT NULL,
    event_date date DEFAULT CURRENT_DATE NOT NULL,
    attendance_status character varying(20),
    quiz_label character varying(100),
    quiz_score numeric(5,2),
    quiz_max numeric(5,2),
    practical_label character varying(100),
    practical_score numeric(5,2),
    practical_max numeric(5,2),
    notes text,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.ta_grade_events OWNER TO postgres;

--
-- Name: TABLE ta_grade_events; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.ta_grade_events IS 'Immutable raw TA input events';


--
-- Name: ta_grade_events_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ta_grade_events_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ta_grade_events_id_seq OWNER TO postgres;

--
-- Name: ta_grade_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ta_grade_events_id_seq OWNED BY public.ta_grade_events.id;


--
-- Name: teaching_assistants; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.teaching_assistants (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    professor_id bigint,
    department_id bigint,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.teaching_assistants OWNER TO postgres;

--
-- Name: teaching_assistants_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.teaching_assistants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.teaching_assistants_id_seq OWNER TO postgres;

--
-- Name: teaching_assistants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.teaching_assistants_id_seq OWNED BY public.teaching_assistants.id;


--
-- Name: transcript_verifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.transcript_verifications (
    id bigint NOT NULL,
    transcript_id bigint NOT NULL,
    verification_code character varying(20) NOT NULL,
    verification_token character varying(128) NOT NULL,
    qr_identifier character varying(64) NOT NULL,
    is_valid boolean,
    expires_at timestamp with time zone,
    verified_count integer,
    last_verified_at timestamp with time zone,
    invalidated_at timestamp with time zone,
    invalidated_reason text,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.transcript_verifications OWNER TO postgres;

--
-- Name: transcript_verifications_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.transcript_verifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.transcript_verifications_id_seq OWNER TO postgres;

--
-- Name: transcript_verifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.transcript_verifications_id_seq OWNED BY public.transcript_verifications.id;


--
-- Name: transcript_versions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.transcript_versions (
    id bigint NOT NULL,
    student_id integer NOT NULL,
    version_number integer NOT NULL,
    transcript_type public.transcript_type NOT NULL,
    transcript_data jsonb NOT NULL,
    snapshot_hash character varying(64) NOT NULL,
    generated_by integer,
    generated_at timestamp with time zone DEFAULT now(),
    reason text,
    is_current boolean
);


ALTER TABLE public.transcript_versions OWNER TO postgres;

--
-- Name: transcript_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.transcript_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.transcript_versions_id_seq OWNER TO postgres;

--
-- Name: transcript_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.transcript_versions_id_seq OWNED BY public.transcript_versions.id;


--
-- Name: transfer_credits; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.transfer_credits (
    id bigint NOT NULL,
    student_id integer NOT NULL,
    term_id bigint,
    source_institution character varying(200) NOT NULL,
    source_institution_country character varying(80),
    source_course_code character varying(30) NOT NULL,
    source_course_name character varying(200) NOT NULL,
    source_credit_hours smallint NOT NULL,
    source_grade character varying(5),
    source_grade_points numeric(4,3),
    source_grade_scale character varying(20),
    target_course_id bigint,
    target_course_code character varying(30),
    target_credit_hours smallint,
    target_grade_points numeric(4,3),
    counts_in_cgpa boolean,
    counts_toward_degree boolean,
    status public.transfer_credit_status,
    evaluation_notes text,
    supporting_document_ids jsonb,
    evaluated_by integer,
    evaluated_at timestamp with time zone,
    approved_by integer,
    approved_at timestamp with time zone,
    rejection_reason text,
    approval_history jsonb,
    submitted_by integer,
    submitted_at timestamp with time zone DEFAULT now(),
    applied_to_record_at timestamp with time zone
);


ALTER TABLE public.transfer_credits OWNER TO postgres;

--
-- Name: COLUMN transfer_credits.counts_in_cgpa; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.transfer_credits.counts_in_cgpa IS 'Transfer credits excluded from CGPA by default. No policy document specifies inclusion. Remains PENDING_POLICY_CONFIGURATION.';


--
-- Name: transfer_credits_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.transfer_credits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.transfer_credits_id_seq OWNER TO postgres;

--
-- Name: transfer_credits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.transfer_credits_id_seq OWNED BY public.transfer_credits.id;


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: validation_results; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.validation_results (
    id bigint NOT NULL,
    batch_id bigint NOT NULL,
    row_number integer,
    rule_code character varying(50),
    field_name character varying(100),
    raw_value text,
    passed boolean NOT NULL,
    severity public.vres_severity_enum NOT NULL,
    message text,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.validation_results OWNER TO postgres;

--
-- Name: validation_results_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.validation_results_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.validation_results_id_seq OWNER TO postgres;

--
-- Name: validation_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.validation_results_id_seq OWNED BY public.validation_results.id;


--
-- Name: validation_rules; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.validation_rules (
    id bigint NOT NULL,
    rule_code character varying(50) NOT NULL,
    rule_name character varying(150) NOT NULL,
    description text,
    category public.vr_category_enum NOT NULL,
    import_type public.vr_import_type_enum,
    severity public.vr_severity_enum NOT NULL,
    is_active boolean,
    rule_config jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.validation_rules OWNER TO postgres;

--
-- Name: validation_rules_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.validation_rules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.validation_rules_id_seq OWNER TO postgres;

--
-- Name: validation_rules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.validation_rules_id_seq OWNED BY public.validation_rules.id;


--
-- Name: academic_achievements id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_achievements ALTER COLUMN id SET DEFAULT nextval('public.academic_achievements_id_seq'::regclass);


--
-- Name: academic_audit_entries id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_audit_entries ALTER COLUMN id SET DEFAULT nextval('public.academic_audit_entries_id_seq'::regclass);


--
-- Name: academic_calendar_periods id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_calendar_periods ALTER COLUMN id SET DEFAULT nextval('public.academic_calendar_periods_id_seq'::regclass);


--
-- Name: academic_case_decisions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_case_decisions ALTER COLUMN id SET DEFAULT nextval('public.academic_case_decisions_id_seq'::regclass);


--
-- Name: academic_cases id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_cases ALTER COLUMN id SET DEFAULT nextval('public.academic_cases_id_seq'::regclass);


--
-- Name: academic_decision_log id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_decision_log ALTER COLUMN id SET DEFAULT nextval('public.academic_decision_log_id_seq'::regclass);


--
-- Name: academic_exemptions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_exemptions ALTER COLUMN id SET DEFAULT nextval('public.academic_exemptions_id_seq'::regclass);


--
-- Name: academic_override_history id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_override_history ALTER COLUMN id SET DEFAULT nextval('public.academic_override_history_id_seq'::regclass);


--
-- Name: academic_overrides id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_overrides ALTER COLUMN id SET DEFAULT nextval('public.academic_overrides_id_seq'::regclass);


--
-- Name: academic_programs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_programs ALTER COLUMN id SET DEFAULT nextval('public.academic_programs_id_seq'::regclass);


--
-- Name: academic_record_versions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_record_versions ALTER COLUMN id SET DEFAULT nextval('public.academic_record_versions_id_seq'::regclass);


--
-- Name: academic_risk_records id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_risk_records ALTER COLUMN id SET DEFAULT nextval('public.academic_risk_records_id_seq'::regclass);


--
-- Name: academic_rules_config id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_rules_config ALTER COLUMN id SET DEFAULT nextval('public.academic_rules_config_id_seq'::regclass);


--
-- Name: academic_status_history id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_status_history ALTER COLUMN id SET DEFAULT nextval('public.academic_status_history_id_seq'::regclass);


--
-- Name: academic_terms id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_terms ALTER COLUMN id SET DEFAULT nextval('public.academic_terms_id_seq'::regclass);


--
-- Name: academic_timeline_events id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_timeline_events ALTER COLUMN id SET DEFAULT nextval('public.academic_timeline_events_id_seq'::regclass);


--
-- Name: academic_tracks id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_tracks ALTER COLUMN id SET DEFAULT nextval('public.academic_tracks_id_seq'::regclass);


--
-- Name: activity_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity_logs ALTER COLUMN id SET DEFAULT nextval('public.activity_logs_id_seq'::regclass);


--
-- Name: advising_plan_items id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advising_plan_items ALTER COLUMN id SET DEFAULT nextval('public.advising_plan_items_id_seq'::regclass);


--
-- Name: advising_plans id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advising_plans ALTER COLUMN id SET DEFAULT nextval('public.advising_plans_id_seq'::regclass);


--
-- Name: advisors id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advisors ALTER COLUMN id SET DEFAULT nextval('public.advisors_id_seq'::regclass);


--
-- Name: announcements id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.announcements ALTER COLUMN id SET DEFAULT nextval('public.announcements_id_seq'::regclass);


--
-- Name: assignment_submissions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assignment_submissions ALTER COLUMN id SET DEFAULT nextval('public.assignment_submissions_id_seq'::regclass);


--
-- Name: assignments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assignments ALTER COLUMN id SET DEFAULT nextval('public.assignments_id_seq'::regclass);


--
-- Name: attendance_scan_log id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance_scan_log ALTER COLUMN id SET DEFAULT nextval('public.attendance_scan_log_id_seq'::regclass);


--
-- Name: attendance_sessions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance_sessions ALTER COLUMN id SET DEFAULT nextval('public.attendance_sessions_id_seq'::regclass);


--
-- Name: attendances id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendances ALTER COLUMN id SET DEFAULT nextval('public.attendances_id_seq'::regclass);


--
-- Name: audit_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs ALTER COLUMN id SET DEFAULT nextval('public.audit_logs_id_seq'::regclass);


--
-- Name: cohort_memberships id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cohort_memberships ALTER COLUMN id SET DEFAULT nextval('public.cohort_memberships_id_seq'::regclass);


--
-- Name: course_eligibility_rules id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_eligibility_rules ALTER COLUMN id SET DEFAULT nextval('public.course_eligibility_rules_id_seq'::regclass);


--
-- Name: course_grade_weights id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_grade_weights ALTER COLUMN id SET DEFAULT nextval('public.course_grade_weights_id_seq'::regclass);


--
-- Name: course_offerings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_offerings ALTER COLUMN id SET DEFAULT nextval('public.course_offerings_id_seq'::regclass);


--
-- Name: course_postrequisites id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_postrequisites ALTER COLUMN id SET DEFAULT nextval('public.course_postrequisites_id_seq'::regclass);


--
-- Name: course_prerequisites id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_prerequisites ALTER COLUMN id SET DEFAULT nextval('public.course_prerequisites_id_seq'::regclass);


--
-- Name: course_sections id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_sections ALTER COLUMN id SET DEFAULT nextval('public.course_sections_id_seq'::regclass);


--
-- Name: courses id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.courses ALTER COLUMN id SET DEFAULT nextval('public.courses_id_seq'::regclass);


--
-- Name: degree_progress_snapshots id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.degree_progress_snapshots ALTER COLUMN id SET DEFAULT nextval('public.degree_progress_snapshots_id_seq'::regclass);


--
-- Name: departments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.departments ALTER COLUMN id SET DEFAULT nextval('public.departments_id_seq'::regclass);


--
-- Name: elective_pool_courses id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.elective_pool_courses ALTER COLUMN id SET DEFAULT nextval('public.elective_pool_courses_id_seq'::regclass);


--
-- Name: elective_pools id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.elective_pools ALTER COLUMN id SET DEFAULT nextval('public.elective_pools_id_seq'::regclass);


--
-- Name: enrollments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.enrollments ALTER COLUMN id SET DEFAULT nextval('public.enrollments_id_seq'::regclass);


--
-- Name: gpa_explanations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gpa_explanations ALTER COLUMN id SET DEFAULT nextval('public.gpa_explanations_id_seq'::regclass);


--
-- Name: gpa_projections id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gpa_projections ALTER COLUMN id SET DEFAULT nextval('public.gpa_projections_id_seq'::regclass);


--
-- Name: gpa_versions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gpa_versions ALTER COLUMN id SET DEFAULT nextval('public.gpa_versions_id_seq'::regclass);


--
-- Name: grade_records id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grade_records ALTER COLUMN id SET DEFAULT nextval('public.grade_records_id_seq'::regclass);


--
-- Name: grade_scale id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grade_scale ALTER COLUMN id SET DEFAULT nextval('public.grade_scale_id_seq'::regclass);


--
-- Name: graduation_audit_results id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.graduation_audit_results ALTER COLUMN id SET DEFAULT nextval('public.graduation_audit_results_id_seq'::regclass);


--
-- Name: graduation_eligibility_records id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.graduation_eligibility_records ALTER COLUMN id SET DEFAULT nextval('public.graduation_eligibility_records_id_seq'::regclass);


--
-- Name: graduation_requirements id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.graduation_requirements ALTER COLUMN id SET DEFAULT nextval('public.graduation_requirements_id_seq'::regclass);


--
-- Name: honors_records id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.honors_records ALTER COLUMN id SET DEFAULT nextval('public.honors_records_id_seq'::regclass);


--
-- Name: import_audit_events id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.import_audit_events ALTER COLUMN id SET DEFAULT nextval('public.import_audit_events_id_seq'::regclass);


--
-- Name: import_batches id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.import_batches ALTER COLUMN id SET DEFAULT nextval('public.import_batches_id_seq'::regclass);


--
-- Name: import_errors id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.import_errors ALTER COLUMN id SET DEFAULT nextval('public.import_errors_id_seq'::regclass);


--
-- Name: import_jobs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.import_jobs ALTER COLUMN id SET DEFAULT nextval('public.import_jobs_id_seq'::regclass);


--
-- Name: import_row_errors id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.import_row_errors ALTER COLUMN id SET DEFAULT nextval('public.import_row_errors_id_seq'::regclass);


--
-- Name: intervention_actions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.intervention_actions ALTER COLUMN id SET DEFAULT nextval('public.intervention_actions_id_seq'::regclass);


--
-- Name: intervention_plans id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.intervention_plans ALTER COLUMN id SET DEFAULT nextval('public.intervention_plans_id_seq'::regclass);


--
-- Name: mapping_template_versions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mapping_template_versions ALTER COLUMN id SET DEFAULT nextval('public.mapping_template_versions_id_seq'::regclass);


--
-- Name: mapping_templates id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mapping_templates ALTER COLUMN id SET DEFAULT nextval('public.mapping_templates_id_seq'::regclass);


--
-- Name: notification_delivery_log id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification_delivery_log ALTER COLUMN id SET DEFAULT nextval('public.notification_delivery_log_id_seq'::regclass);


--
-- Name: notification_preferences id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification_preferences ALTER COLUMN id SET DEFAULT nextval('public.notification_preferences_id_seq'::regclass);


--
-- Name: notification_templates id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification_templates ALTER COLUMN id SET DEFAULT nextval('public.notification_templates_id_seq'::regclass);


--
-- Name: notifications id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications ALTER COLUMN id SET DEFAULT nextval('public.notifications_id_seq'::regclass);


--
-- Name: pdf_transcript_jobs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pdf_transcript_jobs ALTER COLUMN id SET DEFAULT nextval('public.pdf_transcript_jobs_id_seq'::regclass);


--
-- Name: personal_access_tokens id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personal_access_tokens ALTER COLUMN id SET DEFAULT nextval('public.personal_access_tokens_id_seq'::regclass);


--
-- Name: prerequisite_exceptions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prerequisite_exceptions ALTER COLUMN id SET DEFAULT nextval('public.prerequisite_exceptions_id_seq'::regclass);


--
-- Name: prerequisite_validation_log id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prerequisite_validation_log ALTER COLUMN id SET DEFAULT nextval('public.prerequisite_validation_log_id_seq'::regclass);


--
-- Name: prerequisite_validations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prerequisite_validations ALTER COLUMN id SET DEFAULT nextval('public.prerequisite_validations_id_seq'::regclass);


--
-- Name: professors id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.professors ALTER COLUMN id SET DEFAULT nextval('public.professors_id_seq'::regclass);


--
-- Name: questions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.questions ALTER COLUMN id SET DEFAULT nextval('public.questions_id_seq'::regclass);


--
-- Name: quiz_sessions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quiz_sessions ALTER COLUMN id SET DEFAULT nextval('public.quiz_sessions_id_seq'::regclass);


--
-- Name: quiz_submissions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quiz_submissions ALTER COLUMN id SET DEFAULT nextval('public.quiz_submissions_id_seq'::regclass);


--
-- Name: quiz_violations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quiz_violations ALTER COLUMN id SET DEFAULT nextval('public.quiz_violations_id_seq'::regclass);


--
-- Name: quizzes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quizzes ALTER COLUMN id SET DEFAULT nextval('public.quizzes_id_seq'::regclass);


--
-- Name: rbac_permissions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rbac_permissions ALTER COLUMN id SET DEFAULT nextval('public.rbac_permissions_id_seq'::regclass);


--
-- Name: reconciliation_items id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reconciliation_items ALTER COLUMN id SET DEFAULT nextval('public.reconciliation_items_id_seq'::regclass);


--
-- Name: reconciliation_reports id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reconciliation_reports ALTER COLUMN id SET DEFAULT nextval('public.reconciliation_reports_id_seq'::regclass);


--
-- Name: registrar_notes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.registrar_notes ALTER COLUMN id SET DEFAULT nextval('public.registrar_notes_id_seq'::regclass);


--
-- Name: registrar_task_assignments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.registrar_task_assignments ALTER COLUMN id SET DEFAULT nextval('public.registrar_task_assignments_id_seq'::regclass);


--
-- Name: registrar_tasks id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.registrar_tasks ALTER COLUMN id SET DEFAULT nextval('public.registrar_tasks_id_seq'::regclass);


--
-- Name: registration_events id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.registration_events ALTER COLUMN id SET DEFAULT nextval('public.registration_events_id_seq'::regclass);


--
-- Name: risk_assessments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.risk_assessments ALTER COLUMN id SET DEFAULT nextval('public.risk_assessments_id_seq'::regclass);


--
-- Name: scholarship_evaluations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scholarship_evaluations ALTER COLUMN id SET DEFAULT nextval('public.scholarship_evaluations_id_seq'::regclass);


--
-- Name: semester_snapshots id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.semester_snapshots ALTER COLUMN id SET DEFAULT nextval('public.semester_snapshots_id_seq'::regclass);


--
-- Name: student_cohorts id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_cohorts ALTER COLUMN id SET DEFAULT nextval('public.student_cohorts_id_seq'::regclass);


--
-- Name: student_course_attempts id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_course_attempts ALTER COLUMN id SET DEFAULT nextval('public.student_course_attempts_id_seq'::regclass);


--
-- Name: student_documents id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_documents ALTER COLUMN id SET DEFAULT nextval('public.student_documents_id_seq'::regclass);


--
-- Name: student_elective_selections id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_elective_selections ALTER COLUMN id SET DEFAULT nextval('public.student_elective_selections_id_seq'::regclass);


--
-- Name: student_grade_aggregates id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_grade_aggregates ALTER COLUMN id SET DEFAULT nextval('public.student_grade_aggregates_id_seq'::regclass);


--
-- Name: student_grade_versions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_grade_versions ALTER COLUMN id SET DEFAULT nextval('public.student_grade_versions_id_seq'::regclass);


--
-- Name: student_graduation_progress id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_graduation_progress ALTER COLUMN id SET DEFAULT nextval('public.student_graduation_progress_id_seq'::regclass);


--
-- Name: student_term_gpa id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_term_gpa ALTER COLUMN id SET DEFAULT nextval('public.student_term_gpa_id_seq'::regclass);


--
-- Name: students id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.students ALTER COLUMN id SET DEFAULT nextval('public.students_id_seq'::regclass);


--
-- Name: ta_grade_events id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ta_grade_events ALTER COLUMN id SET DEFAULT nextval('public.ta_grade_events_id_seq'::regclass);


--
-- Name: teaching_assistants id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teaching_assistants ALTER COLUMN id SET DEFAULT nextval('public.teaching_assistants_id_seq'::regclass);


--
-- Name: transcript_verifications id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transcript_verifications ALTER COLUMN id SET DEFAULT nextval('public.transcript_verifications_id_seq'::regclass);


--
-- Name: transcript_versions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transcript_versions ALTER COLUMN id SET DEFAULT nextval('public.transcript_versions_id_seq'::regclass);


--
-- Name: transfer_credits id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transfer_credits ALTER COLUMN id SET DEFAULT nextval('public.transfer_credits_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: validation_results id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.validation_results ALTER COLUMN id SET DEFAULT nextval('public.validation_results_id_seq'::regclass);


--
-- Name: validation_rules id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.validation_rules ALTER COLUMN id SET DEFAULT nextval('public.validation_rules_id_seq'::regclass);


--
-- Data for Name: academic_achievements; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.academic_achievements (id, student_id, term_id, category, title, description, metric_key, metric_value, threshold_used, rule_key_used, policy_sourced, achieved_at, awarded_by) FROM stdin;
\.


--
-- Data for Name: academic_audit_entries; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.academic_audit_entries (id, student_id, term_id, action, entity_type, entity_id, old_value, new_value, reason, actor_id, actor_role, ip_address, occurred_at) FROM stdin;
\.


--
-- Data for Name: academic_calendar_periods; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.academic_calendar_periods (id, term_id, period_type, label, start_date, end_date, is_active, notes, created_by, created_at, updated_at) FROM stdin;
1	1	registration	Registration Period Fall 2025	2025-08-01	2025-08-31	\N	\N	\N	2026-06-24 04:24:30.975852+03	2026-06-24 04:24:30.975852+03
2	1	add_drop	Add/Drop Period Fall 2025	2025-09-01	2025-09-14	\N	\N	\N	2026-06-24 04:24:30.975852+03	2026-06-24 04:24:30.975852+03
3	1	withdrawal	Withdrawal Period Fall 2025	2025-09-15	2025-10-31	\N	\N	\N	2026-06-24 04:24:30.975852+03	2026-06-24 04:24:30.975852+03
4	1	midterm	Midterm Examination Period	2025-10-20	2025-11-03	\N	\N	\N	2026-06-24 04:24:30.975852+03	2026-06-24 04:24:30.975852+03
5	1	final_exam	Final Examination Period Fall 2025	2025-12-20	2026-01-10	\N	\N	\N	2026-06-24 04:24:30.975852+03	2026-06-24 04:24:30.975852+03
6	1	grade_submission	Grade Submission Deadline	2026-01-10	2026-01-15	\N	\N	\N	2026-06-24 04:24:30.975852+03	2026-06-24 04:24:30.975852+03
7	1	graduation_review	Graduation Review Period	2026-01-16	2026-01-31	\N	\N	\N	2026-06-24 04:24:30.975852+03	2026-06-24 04:24:30.975852+03
\.


--
-- Data for Name: academic_case_decisions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.academic_case_decisions (id, case_id, from_status, to_status, decision, notes, decided_by, decided_at, payload) FROM stdin;
\.


--
-- Data for Name: academic_cases; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.academic_cases (id, case_number, student_id, term_id, course_id, attempt_id, case_type, status, title, description, supporting_docs, assigned_to, assigned_at, resolution, resolved_by, resolved_at, priority, submitted_by, submitted_at, due_date, closed_at) FROM stdin;
\.


--
-- Data for Name: academic_decision_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.academic_decision_log (id, decision_type, student_id, course_id, term_id, outcome, decision_reason, rule_triggered, explanation, input_snapshot, output_snapshot, decided_by, decided_at) FROM stdin;
\.


--
-- Data for Name: academic_exemptions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.academic_exemptions (id, student_id, exemption_type, status, course_id, course_code, requirement_desc, reason, decision_notes, supporting_doc_ids, approval_history, version, requested_by, requested_at, reviewed_by, reviewed_at, approved_by, approved_at, revoked_at, revoke_reason, applied_at) FROM stdin;
\.


--
-- Data for Name: academic_override_history; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.academic_override_history (id, override_id, action, performed_by, old_status, new_status, notes, performed_at) FROM stdin;
\.


--
-- Data for Name: academic_overrides; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.academic_overrides (id, override_type, student_id, course_id, term_id, requested_by, reviewed_by, status, reason, reviewer_notes, decision_reason, rule_triggered, explanation, metadata_json, requested_at, reviewed_at, expires_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: academic_programs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.academic_programs (id, department_id, code, name, name_ar, total_credit_hours, min_cgpa_grad, duration_years, is_active, description, created_at, updated_at) FROM stdin;
3	1	CS	Computer Science	ط¹ظ„ظˆظ… ط§ظ„ط­ط§ط³ط¨	134	2.00	4	t	NMU CS Program â€” 8 semesters, 134 CH, 268 ECTS. Source: Vol.4 Study Programs MASH.	2026-06-24 04:24:25.336411+03	2026-06-24 04:24:30.965521+03
\.


--
-- Data for Name: academic_record_versions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.academic_record_versions (id, student_id, version_number, trigger, trigger_detail, cgpa, semester_gpa, hours_attempted, hours_earned, quality_points, academic_standing, graduation_status, degree_completion_pct, record_snapshot, snapshot_hash, is_current, authored_by, authored_at, notes) FROM stdin;
\.


--
-- Data for Name: academic_risk_records; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.academic_risk_records (id, student_id, term_id, risk_level, risk_score, gpa_trend, cgpa_trend, failed_courses_count, repeated_courses_count, withdrawal_count, degree_completion_pct, risk_factors, recommendations, assessed_by, assessed_at, is_current) FROM stdin;
\.


--
-- Data for Name: academic_rules_config; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.academic_rules_config (id, program_id, rule_key, rule_value, description, updated_by, updated_at, created_at) FROM stdin;
63	\N	min_cgpa_graduation	2.00	Minimum CGPA required for graduation	\N	2026-06-24 04:24:35.788232+03	2026-06-24 04:24:35.788232+03
64	\N	min_cgpa_good_standing	2.00	CGPA threshold for good academic standing	\N	2026-06-24 04:24:35.788232+03	2026-06-24 04:24:35.788232+03
65	\N	min_cgpa_warning	1.70	CGPA threshold for academic warning	\N	2026-06-24 04:24:35.788232+03	2026-06-24 04:24:35.788232+03
66	\N	min_cgpa_probation	1.40	CGPA threshold for academic probation	\N	2026-06-24 04:24:35.788232+03	2026-06-24 04:24:35.788232+03
67	\N	deans_list_term_gpa	3.50	Term GPA required for Dean's List	\N	2026-06-24 04:24:35.788232+03	2026-06-24 04:24:35.788232+03
68	\N	deans_list_min_credits	15	Minimum credit hours attempted for Dean's List	\N	2026-06-24 04:24:35.788232+03	2026-06-24 04:24:35.788232+03
69	\N	honors_cgpa	3.50	CGPA for Honors at graduation	\N	2026-06-24 04:24:35.788232+03	2026-06-24 04:24:35.788232+03
70	\N	high_honors_cgpa	3.75	CGPA for High Honors at graduation	\N	2026-06-24 04:24:35.788232+03	2026-06-24 04:24:35.788232+03
71	\N	distinction_cgpa	3.75	CGPA for Distinction	\N	2026-06-24 04:24:35.788232+03	2026-06-24 04:24:35.788232+03
72	\N	excellent_cgpa	3.50	CGPA for Excellent classification	\N	2026-06-24 04:24:35.788232+03	2026-06-24 04:24:35.788232+03
73	\N	very_good_cgpa	3.00	CGPA for Very Good classification	\N	2026-06-24 04:24:35.788232+03	2026-06-24 04:24:35.788232+03
74	\N	good_standing_cgpa	2.50	CGPA for Good classification	\N	2026-06-24 04:24:35.788232+03	2026-06-24 04:24:35.788232+03
75	\N	total_required_credits	134	Total credit hours for graduation	\N	2026-06-24 04:24:35.788232+03	2026-06-24 04:24:35.788232+03
76	\N	min_elective_credits	9	Minimum elective credit hours	\N	2026-06-24 04:24:35.788232+03	2026-06-24 04:24:35.788232+03
77	\N	min_university_req_credits	14	Minimum university requirement credits	\N	2026-06-24 04:24:35.788232+03	2026-06-24 04:24:35.788232+03
78	\N	min_field_training_credits	4	Minimum field training credits	\N	2026-06-24 04:24:35.788232+03	2026-06-24 04:24:35.788232+03
79	\N	max_repeat_attempts	0	0 = unlimited course repeats	\N	2026-06-24 04:24:35.788232+03	2026-06-24 04:24:35.788232+03
80	\N	repeat_policy	all_attempts	GPA repeat policy: all_attempts|best|latest	\N	2026-06-24 04:24:35.788232+03	2026-06-24 04:24:35.788232+03
81	\N	transcript_expiry_days	365	Days until transcript verification link expires	\N	2026-06-24 04:24:35.788232+03	2026-06-24 04:24:35.788232+03
82	\N	gpa_scale	4.0	GPA scale maximum	\N	2026-06-24 04:24:35.788232+03	2026-06-24 04:24:35.788232+03
83	\N	cgpa_formula	sum(grade_points*credit_hours)/sum(credit_hours)	[SOURCE: CGPA_Calculator.xlsx â€” formula verified: 100.70/78=1.2910256410]	\N	2026-06-24 04:24:38.499578+03	2026-06-24 04:24:38.499578+03
84	\N	gpa_scale	4.0	[SOURCE: CGPA_Calculator.xlsx â€” maximum grade points = 4.0 (not shown in file; standard Egyptian university scale)]	\N	2026-06-24 04:24:38.499578+03	2026-06-24 04:24:38.499578+03
85	\N	scholarship_min_cgpa	PENDING_POLICY_CONFIGURATION	[PENDING: Not in uploaded documents. Upload university scholarship regulations.]	\N	2026-06-24 04:24:38.499578+03	2026-06-24 04:24:38.499578+03
86	\N	scholarship_min_credits	PENDING_POLICY_CONFIGURATION	[PENDING: Not in uploaded documents. Upload university scholarship regulations.]	\N	2026-06-24 04:24:38.499578+03	2026-06-24 04:24:38.499578+03
87	\N	scholarship_no_fail_required	PENDING_POLICY_CONFIGURATION	[PENDING: Not in uploaded documents. Upload university scholarship regulations.]	\N	2026-06-24 04:24:38.499578+03	2026-06-24 04:24:38.499578+03
88	\N	scholarship_min_term_gpa	PENDING_POLICY_CONFIGURATION	[PENDING: Not in uploaded documents. Upload university scholarship regulations.]	\N	2026-06-24 04:24:38.499578+03	2026-06-24 04:24:38.499578+03
89	\N	min_cgpa_graduation	PENDING_POLICY_CONFIGURATION	[PENDING: Not in uploaded documents. Upload university graduation regulations.]	\N	2026-06-24 04:24:38.499578+03	2026-06-24 04:24:38.499578+03
90	\N	min_cgpa_good_standing	PENDING_POLICY_CONFIGURATION	[PENDING: Not in uploaded documents. Upload university academic standing regulations.]	\N	2026-06-24 04:24:38.499578+03	2026-06-24 04:24:38.499578+03
91	\N	min_cgpa_warning	PENDING_POLICY_CONFIGURATION	[PENDING: Not in uploaded documents. Upload university academic standing regulations.]	\N	2026-06-24 04:24:38.499578+03	2026-06-24 04:24:38.499578+03
92	\N	min_cgpa_probation	PENDING_POLICY_CONFIGURATION	[PENDING: Not in uploaded documents. Upload university academic standing regulations.]	\N	2026-06-24 04:24:38.499578+03	2026-06-24 04:24:38.499578+03
93	\N	min_cgpa_suspension	PENDING_POLICY_CONFIGURATION	[PENDING: Not in uploaded documents. Upload university academic standing regulations.]	\N	2026-06-24 04:24:38.499578+03	2026-06-24 04:24:38.499578+03
94	\N	deans_list_term_gpa	PENDING_POLICY_CONFIGURATION	[PENDING: Not in uploaded documents. Upload university Dean's List regulations.]	\N	2026-06-24 04:24:38.499578+03	2026-06-24 04:24:38.499578+03
95	\N	deans_list_min_credits	PENDING_POLICY_CONFIGURATION	[PENDING: Not in uploaded documents. Upload university Dean's List regulations.]	\N	2026-06-24 04:24:38.499578+03	2026-06-24 04:24:38.499578+03
96	\N	honors_cgpa	PENDING_POLICY_CONFIGURATION	[PENDING: Not in uploaded documents. Upload university honors regulations.]	\N	2026-06-24 04:24:38.499578+03	2026-06-24 04:24:38.499578+03
97	\N	high_honors_cgpa	PENDING_POLICY_CONFIGURATION	[PENDING: Not in uploaded documents. Upload university honors regulations.]	\N	2026-06-24 04:24:38.499578+03	2026-06-24 04:24:38.499578+03
98	\N	distinction_cgpa	PENDING_POLICY_CONFIGURATION	[PENDING: Not in uploaded documents. Upload university honors regulations.]	\N	2026-06-24 04:24:38.499578+03	2026-06-24 04:24:38.499578+03
99	\N	excellent_cgpa	PENDING_POLICY_CONFIGURATION	[PENDING: Not in uploaded documents. Upload university honors regulations.]	\N	2026-06-24 04:24:38.499578+03	2026-06-24 04:24:38.499578+03
100	\N	very_good_cgpa	PENDING_POLICY_CONFIGURATION	[PENDING: Not in uploaded documents. Upload university honors regulations.]	\N	2026-06-24 04:24:38.499578+03	2026-06-24 04:24:38.499578+03
101	\N	good_standing_cgpa	PENDING_POLICY_CONFIGURATION	[PENDING: Not in uploaded documents. Upload university honors regulations.]	\N	2026-06-24 04:24:38.499578+03	2026-06-24 04:24:38.499578+03
102	\N	max_repeat_attempts	PENDING_POLICY_CONFIGURATION	[PENDING: Not in uploaded documents. Upload university repeat course regulations.]	\N	2026-06-24 04:24:38.499578+03	2026-06-24 04:24:38.499578+03
103	\N	max_credit_load_per_term	PENDING_POLICY_CONFIGURATION	[PENDING: Not in uploaded documents. Upload university academic load regulations.]	\N	2026-06-24 04:24:38.499578+03	2026-06-24 04:24:38.499578+03
104	\N	withdrawal_deadline_weeks	PENDING_POLICY_CONFIGURATION	[PENDING: Not in uploaded documents. Upload university withdrawal regulations.]	\N	2026-06-24 04:24:38.499578+03	2026-06-24 04:24:38.499578+03
\.


--
-- Data for Name: academic_status_history; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.academic_status_history (id, student_id, term_id, old_status, new_status, cgpa_at_change, term_gpa_at_change, reason, actor_id, occurred_at) FROM stdin;
\.


--
-- Data for Name: academic_terms; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.academic_terms (id, code, name, term_type, academic_year, start_date, end_date, registration_start, registration_end, is_active, is_summer, created_at, updated_at) FROM stdin;
1	2025-FALL	Fall Semester 2025	fall	2025	2025-09-01	2026-01-15	2025-08-01	2025-08-31	t	f	2026-06-24 04:24:30.969176+03	2026-06-24 04:24:30.969176+03
\.


--
-- Data for Name: academic_timeline_events; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.academic_timeline_events (id, student_id, term_id, event_type, title, description, payload, actor_id, occurred_at) FROM stdin;
\.


--
-- Data for Name: academic_tracks; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.academic_tracks (id, program_id, code, name, name_ar, is_active, description, created_at, updated_at) FROM stdin;
3	3	CS-SE	Software Engineering	ظ‡ظ†ط¯ط³ط© ط§ظ„ط¨ط±ظ…ط¬ظٹط§طھ	t	Software Engineering specialization track within the CS program	2026-06-24 04:24:25.339352+03	2026-06-24 04:24:25.339352+03
\.


--
-- Data for Name: activity_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.activity_logs (id, student_id, action, duration_minutes, resource_type, resource_id, metadata_json, "timestamp") FROM stdin;
\.


--
-- Data for Name: advising_plan_items; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.advising_plan_items (id, plan_id, course_id, offering_id, priority_rank, reason, is_mandatory, notes, created_at) FROM stdin;
\.


--
-- Data for Name: advising_plans; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.advising_plans (id, student_id, advisor_id, term_id, status, total_credits, max_credits, is_ai_generated, ai_model_version, student_notes, advisor_notes, rejection_reason, submitted_at, reviewed_at, approved_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: advisors; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.advisors (id, user_id, department_id, specialization, max_students, created_at, updated_at) FROM stdin;
3	10	1	CS & AI Counseling	35	2026-06-24 04:24:16.53465+03	2026-06-24 04:24:16.53465+03
4	11	3	IS & Networks Counseling	30	2026-06-24 04:24:16.53465+03	2026-06-24 04:24:16.53465+03
\.


--
-- Data for Name: announcements; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.announcements (id, title, content, author_id, course_id, department_id, is_global, published_at, expires_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: assignment_submissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.assignment_submissions (id, assignment_id, student_id, submission_file, submitted_at, status, grade, feedback, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: assignments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.assignments (id, title, description, file_path, uploaded_by, course_id, due_date, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: attendance_scan_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.attendance_scan_log (id, session_id, student_id, qr_token_used, verification_status, scanned_at, ip_address, user_agent, device_fingerprint, attendance_id) FROM stdin;
\.


--
-- Data for Name: attendance_sessions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.attendance_sessions (id, course_id, professor_id, lecture_topic, status, started_at, ended_at, expires_at, current_qr_token, token_issued_at, token_expires_at, token_rotation_sec, total_present, total_enrolled, room, notes, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: attendances; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.attendances (id, student_id, course_id, date, status, notes, recorded_by, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.audit_logs (id, user_id, action, entity_type, entity_id, old_value, new_value, ip_address, user_agent, "timestamp") FROM stdin;
1899	\N	INSERT	users	1	\N	{"id": 1, "name": "Dr. Sarah Mitchell", "role": "admin", "email": "admin@eduguard.edu", "is_active": true, "avatar_url": null, "created_at": "2026-06-24T04:24:16.517373+03:00", "last_login": null, "updated_at": "2026-06-24T04:24:16.517373+03:00", "remember_token": null, "hashed_password": "$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi", "email_verified_at": null}	\N	\N	2026-06-24 04:24:16.517373+03
1900	\N	INSERT	users	2	\N	{"id": 2, "name": "System Administrator", "role": "admin", "email": "sysadmin@eduguard.edu", "is_active": true, "avatar_url": null, "created_at": "2026-06-24T04:24:16.517373+03:00", "last_login": null, "updated_at": "2026-06-24T04:24:16.517373+03:00", "remember_token": null, "hashed_password": "$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi", "email_verified_at": null}	\N	\N	2026-06-24 04:24:16.517373+03
1901	\N	INSERT	users	3	\N	{"id": 3, "name": "Prof. James Anderson", "role": "professor", "email": "j.anderson@eduguard.edu", "is_active": true, "avatar_url": null, "created_at": "2026-06-24T04:24:16.526891+03:00", "last_login": null, "updated_at": "2026-06-24T04:24:16.526891+03:00", "remember_token": null, "hashed_password": "$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi", "email_verified_at": null}	\N	\N	2026-06-24 04:24:16.526891+03
1902	\N	INSERT	users	4	\N	{"id": 4, "name": "Prof. Emily Chen", "role": "professor", "email": "e.chen@eduguard.edu", "is_active": true, "avatar_url": null, "created_at": "2026-06-24T04:24:16.526891+03:00", "last_login": null, "updated_at": "2026-06-24T04:24:16.526891+03:00", "remember_token": null, "hashed_password": "$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi", "email_verified_at": null}	\N	\N	2026-06-24 04:24:16.526891+03
1903	\N	INSERT	users	5	\N	{"id": 5, "name": "Prof. Robert Davis", "role": "professor", "email": "r.davis@eduguard.edu", "is_active": true, "avatar_url": null, "created_at": "2026-06-24T04:24:16.526891+03:00", "last_login": null, "updated_at": "2026-06-24T04:24:16.526891+03:00", "remember_token": null, "hashed_password": "$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi", "email_verified_at": null}	\N	\N	2026-06-24 04:24:16.526891+03
1904	\N	INSERT	users	6	\N	{"id": 6, "name": "Prof. Lisa Thompson", "role": "professor", "email": "l.thompson@eduguard.edu", "is_active": true, "avatar_url": null, "created_at": "2026-06-24T04:24:16.526891+03:00", "last_login": null, "updated_at": "2026-06-24T04:24:16.526891+03:00", "remember_token": null, "hashed_password": "$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi", "email_verified_at": null}	\N	\N	2026-06-24 04:24:16.526891+03
1905	\N	INSERT	users	7	\N	{"id": 7, "name": "Prof. Michael Wong", "role": "professor", "email": "m.wong@eduguard.edu", "is_active": true, "avatar_url": null, "created_at": "2026-06-24T04:24:16.526891+03:00", "last_login": null, "updated_at": "2026-06-24T04:24:16.526891+03:00", "remember_token": null, "hashed_password": "$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi", "email_verified_at": null}	\N	\N	2026-06-24 04:24:16.526891+03
1906	\N	INSERT	users	8	\N	{"id": 8, "name": "Prof. Anna Martinez", "role": "professor", "email": "a.martinez@eduguard.edu", "is_active": true, "avatar_url": null, "created_at": "2026-06-24T04:24:16.526891+03:00", "last_login": null, "updated_at": "2026-06-24T04:24:16.526891+03:00", "remember_token": null, "hashed_password": "$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi", "email_verified_at": null}	\N	\N	2026-06-24 04:24:16.526891+03
1907	\N	INSERT	users	9	\N	{"id": 9, "name": "Prof. David Nguyen", "role": "professor", "email": "d.nguyen@eduguard.edu", "is_active": true, "avatar_url": null, "created_at": "2026-06-24T04:24:16.526891+03:00", "last_login": null, "updated_at": "2026-06-24T04:24:16.526891+03:00", "remember_token": null, "hashed_password": "$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi", "email_verified_at": null}	\N	\N	2026-06-24 04:24:16.526891+03
1908	\N	INSERT	users	10	\N	{"id": 10, "name": "Dr. Kevin Park", "role": "advisor", "email": "k.park@eduguard.edu", "is_active": true, "avatar_url": null, "created_at": "2026-06-24T04:24:16.527878+03:00", "last_login": null, "updated_at": "2026-06-24T04:24:16.527878+03:00", "remember_token": null, "hashed_password": "$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi", "email_verified_at": null}	\N	\N	2026-06-24 04:24:16.527878+03
1909	\N	INSERT	users	11	\N	{"id": 11, "name": "Dr. Rachel Green", "role": "advisor", "email": "r.green@eduguard.edu", "is_active": true, "avatar_url": null, "created_at": "2026-06-24T04:24:16.527878+03:00", "last_login": null, "updated_at": "2026-06-24T04:24:16.527878+03:00", "remember_token": null, "hashed_password": "$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi", "email_verified_at": null}	\N	\N	2026-06-24 04:24:16.527878+03
1910	\N	INSERT	users	12	\N	{"id": 12, "name": "Marcus Johnson", "role": "ta", "email": "ta.marcus@eduguard.edu", "is_active": true, "avatar_url": null, "created_at": "2026-06-24T04:24:16.528458+03:00", "last_login": null, "updated_at": "2026-06-24T04:24:16.528458+03:00", "remember_token": null, "hashed_password": "$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi", "email_verified_at": null}	\N	\N	2026-06-24 04:24:16.528458+03
1911	\N	INSERT	users	13	\N	{"id": 13, "name": "Sofia Rodriguez", "role": "ta", "email": "ta.sofia@eduguard.edu", "is_active": true, "avatar_url": null, "created_at": "2026-06-24T04:24:16.528458+03:00", "last_login": null, "updated_at": "2026-06-24T04:24:16.528458+03:00", "remember_token": null, "hashed_password": "$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi", "email_verified_at": null}	\N	\N	2026-06-24 04:24:16.528458+03
1912	\N	INSERT	users	14	\N	{"id": 14, "name": "Alice Johnson", "role": "student", "email": "alice@student.eduguard.edu", "is_active": true, "avatar_url": null, "created_at": "2026-06-24T04:24:16.529185+03:00", "last_login": null, "updated_at": "2026-06-24T04:24:16.529185+03:00", "remember_token": null, "hashed_password": "$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi", "email_verified_at": null}	\N	\N	2026-06-24 04:24:16.529185+03
1913	\N	INSERT	users	15	\N	{"id": 15, "name": "Bob Smith", "role": "student", "email": "bob@student.eduguard.edu", "is_active": true, "avatar_url": null, "created_at": "2026-06-24T04:24:16.529185+03:00", "last_login": null, "updated_at": "2026-06-24T04:24:16.529185+03:00", "remember_token": null, "hashed_password": "$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi", "email_verified_at": null}	\N	\N	2026-06-24 04:24:16.529185+03
1914	\N	INSERT	users	16	\N	{"id": 16, "name": "Carol White", "role": "student", "email": "carol@student.eduguard.edu", "is_active": true, "avatar_url": null, "created_at": "2026-06-24T04:24:16.529185+03:00", "last_login": null, "updated_at": "2026-06-24T04:24:16.529185+03:00", "remember_token": null, "hashed_password": "$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi", "email_verified_at": null}	\N	\N	2026-06-24 04:24:16.529185+03
1915	\N	INSERT	users	17	\N	{"id": 17, "name": "David Brown", "role": "student", "email": "david@student.eduguard.edu", "is_active": true, "avatar_url": null, "created_at": "2026-06-24T04:24:16.529185+03:00", "last_login": null, "updated_at": "2026-06-24T04:24:16.529185+03:00", "remember_token": null, "hashed_password": "$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi", "email_verified_at": null}	\N	\N	2026-06-24 04:24:16.529185+03
1916	\N	INSERT	users	18	\N	{"id": 18, "name": "Eva Martinez", "role": "student", "email": "eva@student.eduguard.edu", "is_active": true, "avatar_url": null, "created_at": "2026-06-24T04:24:16.529185+03:00", "last_login": null, "updated_at": "2026-06-24T04:24:16.529185+03:00", "remember_token": null, "hashed_password": "$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi", "email_verified_at": null}	\N	\N	2026-06-24 04:24:16.529185+03
1917	\N	INSERT	users	19	\N	{"id": 19, "name": "Frank Lee", "role": "student", "email": "frank@student.eduguard.edu", "is_active": true, "avatar_url": null, "created_at": "2026-06-24T04:24:16.529185+03:00", "last_login": null, "updated_at": "2026-06-24T04:24:16.529185+03:00", "remember_token": null, "hashed_password": "$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi", "email_verified_at": null}	\N	\N	2026-06-24 04:24:16.529185+03
1918	\N	INSERT	users	20	\N	{"id": 20, "name": "Grace Kim", "role": "student", "email": "grace@student.eduguard.edu", "is_active": true, "avatar_url": null, "created_at": "2026-06-24T04:24:16.529185+03:00", "last_login": null, "updated_at": "2026-06-24T04:24:16.529185+03:00", "remember_token": null, "hashed_password": "$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi", "email_verified_at": null}	\N	\N	2026-06-24 04:24:16.529185+03
1919	\N	INSERT	users	21	\N	{"id": 21, "name": "Henry Wilson", "role": "student", "email": "henry@student.eduguard.edu", "is_active": true, "avatar_url": null, "created_at": "2026-06-24T04:24:16.529185+03:00", "last_login": null, "updated_at": "2026-06-24T04:24:16.529185+03:00", "remember_token": null, "hashed_password": "$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi", "email_verified_at": null}	\N	\N	2026-06-24 04:24:16.529185+03
1920	\N	INSERT	users	22	\N	{"id": 22, "name": "Iris Patel", "role": "student", "email": "iris@student.eduguard.edu", "is_active": true, "avatar_url": null, "created_at": "2026-06-24T04:24:16.529185+03:00", "last_login": null, "updated_at": "2026-06-24T04:24:16.529185+03:00", "remember_token": null, "hashed_password": "$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi", "email_verified_at": null}	\N	\N	2026-06-24 04:24:16.529185+03
1921	\N	INSERT	users	23	\N	{"id": 23, "name": "Jake Turner", "role": "student", "email": "jake@student.eduguard.edu", "is_active": true, "avatar_url": null, "created_at": "2026-06-24T04:24:16.529185+03:00", "last_login": null, "updated_at": "2026-06-24T04:24:16.529185+03:00", "remember_token": null, "hashed_password": "$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi", "email_verified_at": null}	\N	\N	2026-06-24 04:24:16.529185+03
1922	\N	INSERT	users	24	\N	{"id": 24, "name": "Karen Liu", "role": "student", "email": "karen@student.eduguard.edu", "is_active": true, "avatar_url": null, "created_at": "2026-06-24T04:24:16.529185+03:00", "last_login": null, "updated_at": "2026-06-24T04:24:16.529185+03:00", "remember_token": null, "hashed_password": "$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi", "email_verified_at": null}	\N	\N	2026-06-24 04:24:16.529185+03
1923	\N	INSERT	users	25	\N	{"id": 25, "name": "Leo Santos", "role": "student", "email": "leo@student.eduguard.edu", "is_active": true, "avatar_url": null, "created_at": "2026-06-24T04:24:16.529185+03:00", "last_login": null, "updated_at": "2026-06-24T04:24:16.529185+03:00", "remember_token": null, "hashed_password": "$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi", "email_verified_at": null}	\N	\N	2026-06-24 04:24:16.529185+03
1924	\N	INSERT	users	26	\N	{"id": 26, "name": "Mia Chen", "role": "student", "email": "mia@student.eduguard.edu", "is_active": true, "avatar_url": null, "created_at": "2026-06-24T04:24:16.529185+03:00", "last_login": null, "updated_at": "2026-06-24T04:24:16.529185+03:00", "remember_token": null, "hashed_password": "$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi", "email_verified_at": null}	\N	\N	2026-06-24 04:24:16.529185+03
1925	\N	INSERT	users	27	\N	{"id": 27, "name": "Noah Adams", "role": "student", "email": "noah@student.eduguard.edu", "is_active": true, "avatar_url": null, "created_at": "2026-06-24T04:24:16.529185+03:00", "last_login": null, "updated_at": "2026-06-24T04:24:16.529185+03:00", "remember_token": null, "hashed_password": "$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi", "email_verified_at": null}	\N	\N	2026-06-24 04:24:16.529185+03
1926	\N	INSERT	users	28	\N	{"id": 28, "name": "Olivia Clark", "role": "student", "email": "olivia@student.eduguard.edu", "is_active": true, "avatar_url": null, "created_at": "2026-06-24T04:24:16.529185+03:00", "last_login": null, "updated_at": "2026-06-24T04:24:16.529185+03:00", "remember_token": null, "hashed_password": "$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi", "email_verified_at": null}	\N	\N	2026-06-24 04:24:16.529185+03
1927	\N	INSERT	users	29	\N	{"id": 29, "name": "Peter Wright", "role": "student", "email": "peter@student.eduguard.edu", "is_active": true, "avatar_url": null, "created_at": "2026-06-24T04:24:16.529185+03:00", "last_login": null, "updated_at": "2026-06-24T04:24:16.529185+03:00", "remember_token": null, "hashed_password": "$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi", "email_verified_at": null}	\N	\N	2026-06-24 04:24:16.529185+03
1928	\N	INSERT	users	30	\N	{"id": 30, "name": "Quinn Harris", "role": "student", "email": "quinn@student.eduguard.edu", "is_active": true, "avatar_url": null, "created_at": "2026-06-24T04:24:16.529185+03:00", "last_login": null, "updated_at": "2026-06-24T04:24:16.529185+03:00", "remember_token": null, "hashed_password": "$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi", "email_verified_at": null}	\N	\N	2026-06-24 04:24:16.529185+03
1929	\N	INSERT	users	31	\N	{"id": 31, "name": "Rachel Scott", "role": "student", "email": "rachel@student.eduguard.edu", "is_active": true, "avatar_url": null, "created_at": "2026-06-24T04:24:16.529185+03:00", "last_login": null, "updated_at": "2026-06-24T04:24:16.529185+03:00", "remember_token": null, "hashed_password": "$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi", "email_verified_at": null}	\N	\N	2026-06-24 04:24:16.529185+03
1930	\N	INSERT	users	32	\N	{"id": 32, "name": "Sam Baker", "role": "student", "email": "sam@student.eduguard.edu", "is_active": true, "avatar_url": null, "created_at": "2026-06-24T04:24:16.529185+03:00", "last_login": null, "updated_at": "2026-06-24T04:24:16.529185+03:00", "remember_token": null, "hashed_password": "$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi", "email_verified_at": null}	\N	\N	2026-06-24 04:24:16.529185+03
1931	\N	INSERT	users	33	\N	{"id": 33, "name": "Tara Nelson", "role": "student", "email": "tara@student.eduguard.edu", "is_active": true, "avatar_url": null, "created_at": "2026-06-24T04:24:16.529185+03:00", "last_login": null, "updated_at": "2026-06-24T04:24:16.529185+03:00", "remember_token": null, "hashed_password": "$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi", "email_verified_at": null}	\N	\N	2026-06-24 04:24:16.529185+03
1932	\N	INSERT	users	34	\N	{"id": 34, "name": "Uma Patel", "role": "student", "email": "uma@student.eduguard.edu", "is_active": true, "avatar_url": null, "created_at": "2026-06-24T04:24:16.529185+03:00", "last_login": null, "updated_at": "2026-06-24T04:24:16.529185+03:00", "remember_token": null, "hashed_password": "$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi", "email_verified_at": null}	\N	\N	2026-06-24 04:24:16.529185+03
1933	\N	UPDATE	users	1	{"id": 1, "name": "Dr. Sarah Mitchell", "role": "admin", "email": "admin@eduguard.edu", "is_active": true, "avatar_url": null, "created_at": "2026-06-24T04:24:16.517373+03:00", "last_login": null, "updated_at": "2026-06-24T04:24:16.517373+03:00", "remember_token": null, "hashed_password": "$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi", "email_verified_at": null}	{"id": 1, "name": "Dr. Sarah Mitchell", "role": "admin", "email": "admin@eduguard.edu", "is_active": true, "avatar_url": null, "created_at": "2026-06-24T04:24:16.517373+03:00", "last_login": null, "updated_at": "2026-06-24T04:24:23.112601+03:00", "remember_token": null, "hashed_password": "$2b$12$wjx2p3/7UEWmn8CBZbjggeNup8OYvxLKAl1DJ12Fao77VE8JX9FZe", "email_verified_at": null}	\N	\N	2026-06-24 04:24:23.112601+03
1934	\N	UPDATE	users	3	{"id": 3, "name": "Prof. James Anderson", "role": "professor", "email": "j.anderson@eduguard.edu", "is_active": true, "avatar_url": null, "created_at": "2026-06-24T04:24:16.526891+03:00", "last_login": null, "updated_at": "2026-06-24T04:24:16.526891+03:00", "remember_token": null, "hashed_password": "$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi", "email_verified_at": null}	{"id": 3, "name": "Prof. James Anderson", "role": "professor", "email": "j.anderson@eduguard.edu", "is_active": true, "avatar_url": null, "created_at": "2026-06-24T04:24:16.526891+03:00", "last_login": null, "updated_at": "2026-06-24T04:24:23.124413+03:00", "remember_token": null, "hashed_password": "$2b$12$Y5Kr.EeJ65ZCLXqyGWdomutnTRKW8BB9pmCI0fkV8gBAKA9LNGcYC", "email_verified_at": null}	\N	\N	2026-06-24 04:24:23.124413+03
1935	\N	UPDATE	users	12	{"id": 12, "name": "Marcus Johnson", "role": "ta", "email": "ta.marcus@eduguard.edu", "is_active": true, "avatar_url": null, "created_at": "2026-06-24T04:24:16.528458+03:00", "last_login": null, "updated_at": "2026-06-24T04:24:16.528458+03:00", "remember_token": null, "hashed_password": "$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi", "email_verified_at": null}	{"id": 12, "name": "Marcus Johnson", "role": "ta", "email": "ta.marcus@eduguard.edu", "is_active": true, "avatar_url": null, "created_at": "2026-06-24T04:24:16.528458+03:00", "last_login": null, "updated_at": "2026-06-24T04:24:23.125138+03:00", "remember_token": null, "hashed_password": "$2b$12$zJDzhRUHdS6kCNevedO9Eu27AUuo36XseizgZ3cgU7Bp.CTHkyAJG", "email_verified_at": null}	\N	\N	2026-06-24 04:24:23.125138+03
1936	\N	UPDATE	users	14	{"id": 14, "name": "Alice Johnson", "role": "student", "email": "alice@student.eduguard.edu", "is_active": true, "avatar_url": null, "created_at": "2026-06-24T04:24:16.529185+03:00", "last_login": null, "updated_at": "2026-06-24T04:24:16.529185+03:00", "remember_token": null, "hashed_password": "$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi", "email_verified_at": null}	{"id": 14, "name": "Alice Johnson", "role": "student", "email": "alice@student.eduguard.edu", "is_active": true, "avatar_url": null, "created_at": "2026-06-24T04:24:16.529185+03:00", "last_login": null, "updated_at": "2026-06-24T04:24:23.126086+03:00", "remember_token": null, "hashed_password": "$2b$12$liMRI6nZ1G9DM.PwhB.qYOwwVqrC8Ri4GtuxrsnVzEVPLQo0D40VW", "email_verified_at": null}	\N	\N	2026-06-24 04:24:23.126086+03
1937	\N	INSERT	courses	29	\N	{"id": 29, "code": "CSE014", "name": "Structured Programming", "year": null, "credits": 3, "name_ar": null, "category": "core", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 3, "lct_hours": 2, "oth_hours": 0, "swl_hours": 150, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": null, "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 6, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 5, "department_id": null, "plan_semester": 1, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": 1}	\N	\N	2026-06-24 04:24:27.430504+03
1938	\N	INSERT	courses	30	\N	{"id": 30, "code": "PHY211", "name": "Physics II", "year": null, "credits": 3, "name_ar": null, "category": "core", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 2, "lct_hours": 2, "oth_hours": 0, "swl_hours": 150, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": null, "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 6, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 4, "department_id": null, "plan_semester": 1, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": 1}	\N	\N	2026-06-24 04:24:27.430504+03
1939	\N	INSERT	courses	31	\N	{"id": 31, "code": "MAT114", "name": "Analytical Geometry & Calculus I", "year": null, "credits": 4, "name_ar": null, "category": "core", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 0, "lct_hours": 3, "oth_hours": 0, "swl_hours": 195, "tut_hours": 2, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": null, "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 8, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 5, "department_id": null, "plan_semester": 1, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": 1}	\N	\N	2026-06-24 04:24:27.430504+03
1940	\N	INSERT	courses	32	\N	{"id": 32, "code": "UC1", "name": "University Requirement (1)", "year": null, "credits": 2, "name_ar": null, "category": "university_req", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 0, "lct_hours": 2, "oth_hours": 0, "swl_hours": 90, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": null, "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 4, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 2, "department_id": null, "plan_semester": 1, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": 1}	\N	\N	2026-06-24 04:24:27.430504+03
1941	\N	INSERT	courses	33	\N	{"id": 33, "code": "UE1", "name": "Elective University (1)", "year": null, "credits": 2, "name_ar": null, "category": "university_elective", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 0, "lct_hours": 2, "oth_hours": 0, "swl_hours": 90, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": null, "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 4, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 2, "department_id": null, "plan_semester": 1, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": 1}	\N	\N	2026-06-24 04:24:27.430504+03
1942	\N	INSERT	courses	34	\N	{"id": 34, "code": "UC2", "name": "University Requirement (2)", "year": null, "credits": 2, "name_ar": null, "category": "university_req", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 0, "lct_hours": 2, "oth_hours": 0, "swl_hours": 90, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": null, "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 4, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 2, "department_id": null, "plan_semester": 1, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": 1}	\N	\N	2026-06-24 04:24:27.430504+03
1943	\N	INSERT	courses	35	\N	{"id": 35, "code": "CSE015", "name": "Object Oriented Programming", "year": null, "credits": 3, "name_ar": null, "category": "core", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 3, "lct_hours": 2, "oth_hours": 0, "swl_hours": 150, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": null, "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 6, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 5, "department_id": null, "plan_semester": 2, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": 1}	\N	\N	2026-06-24 04:24:27.430504+03
1944	\N	INSERT	courses	36	\N	{"id": 36, "code": "CSE113", "name": "Electric & Electronic Circuits", "year": null, "credits": 3, "name_ar": null, "category": "core", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 2, "lct_hours": 2, "oth_hours": 0, "swl_hours": 150, "tut_hours": 1, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": null, "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 6, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 5, "department_id": null, "plan_semester": 2, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": 1}	\N	\N	2026-06-24 04:24:27.430504+03
1945	\N	INSERT	courses	37	\N	{"id": 37, "code": "MAT131", "name": "Statistics", "year": null, "credits": 2, "name_ar": null, "category": "core", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 0, "lct_hours": 1, "oth_hours": 0, "swl_hours": 105, "tut_hours": 2, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": null, "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 4, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 3, "department_id": null, "plan_semester": 2, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": 1}	\N	\N	2026-06-24 04:24:27.430504+03
1946	\N	INSERT	courses	38	\N	{"id": 38, "code": "MAT112", "name": "Mathematics II", "year": null, "credits": 3, "name_ar": null, "category": "core", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 0, "lct_hours": 2, "oth_hours": 0, "swl_hours": 150, "tut_hours": 2, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": null, "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 6, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 4, "department_id": null, "plan_semester": 2, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": 1}	\N	\N	2026-06-24 04:24:27.430504+03
1947	\N	INSERT	courses	39	\N	{"id": 39, "code": "UC3", "name": "University Requirement (3)", "year": null, "credits": 2, "name_ar": null, "category": "university_req", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 0, "lct_hours": 2, "oth_hours": 0, "swl_hours": 90, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": null, "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 4, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 2, "department_id": null, "plan_semester": 2, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": 1}	\N	\N	2026-06-24 04:24:27.430504+03
1948	\N	INSERT	courses	40	\N	{"id": 40, "code": "UE2", "name": "Elective University Requirement (2)", "year": null, "credits": 2, "name_ar": null, "category": "university_elective", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 0, "lct_hours": 2, "oth_hours": 0, "swl_hours": 90, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": null, "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 4, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 2, "department_id": null, "plan_semester": 2, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": 1}	\N	\N	2026-06-24 04:24:27.430504+03
1949	\N	INSERT	courses	41	\N	{"id": 41, "code": "CSE111", "name": "Data Structures", "year": null, "credits": 3, "name_ar": null, "category": "core", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 3, "lct_hours": 2, "oth_hours": 0, "swl_hours": 150, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": null, "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 6, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 5, "department_id": null, "plan_semester": 3, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": 2}	\N	\N	2026-06-24 04:24:27.430504+03
1950	\N	INSERT	courses	42	\N	{"id": 42, "code": "CSE131", "name": "Logic Design", "year": null, "credits": 3, "name_ar": null, "category": "core", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 3, "lct_hours": 2, "oth_hours": 0, "swl_hours": 150, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": null, "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 6, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 5, "department_id": null, "plan_semester": 3, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": 2}	\N	\N	2026-06-24 04:24:27.430504+03
1951	\N	INSERT	courses	43	\N	{"id": 43, "code": "CSE191", "name": "Field Training 1 In Computer Science", "year": null, "credits": 2, "name_ar": null, "category": "field_training", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 0, "lct_hours": 2, "oth_hours": 0, "swl_hours": 90, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": null, "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 4, "is_pass_fail": true, "max_students": 40, "professor_id": null, "contact_hours": 2, "department_id": null, "plan_semester": 3, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": 2}	\N	\N	2026-06-24 04:24:27.430504+03
1952	\N	INSERT	courses	44	\N	{"id": 44, "code": "MAT313", "name": "Differential Equations & Numerical Analysis", "year": null, "credits": 4, "name_ar": null, "category": "core", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 0, "lct_hours": 3, "oth_hours": 0, "swl_hours": 195, "tut_hours": 2, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": null, "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 8, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 5, "department_id": null, "plan_semester": 3, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": 2}	\N	\N	2026-06-24 04:24:27.430504+03
1953	\N	INSERT	courses	45	\N	{"id": 45, "code": "MAT231", "name": "Probability & Statistics", "year": null, "credits": 3, "name_ar": null, "category": "core", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 0, "lct_hours": 2, "oth_hours": 0, "swl_hours": 150, "tut_hours": 2, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": null, "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 6, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 4, "department_id": null, "plan_semester": 3, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": 2}	\N	\N	2026-06-24 04:24:27.430504+03
1954	\N	INSERT	courses	46	\N	{"id": 46, "code": "MAT212", "name": "Linear Algebra", "year": null, "credits": 3, "name_ar": null, "category": "core", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 0, "lct_hours": 2, "oth_hours": 0, "swl_hours": 150, "tut_hours": 2, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": null, "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 6, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 4, "department_id": null, "plan_semester": 3, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": 2}	\N	\N	2026-06-24 04:24:27.430504+03
1955	\N	INSERT	courses	47	\N	{"id": 47, "code": "CSE112", "name": "Design & Analysis of Algorithms", "year": null, "credits": 3, "name_ar": null, "category": "core", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 3, "lct_hours": 2, "oth_hours": 0, "swl_hours": 150, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": null, "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 6, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 5, "department_id": null, "plan_semester": 4, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": 2}	\N	\N	2026-06-24 04:24:27.430504+03
1956	\N	INSERT	courses	48	\N	{"id": 48, "code": "CSE132", "name": "Computer Architecture & Organization", "year": null, "credits": 3, "name_ar": null, "category": "core", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 3, "lct_hours": 2, "oth_hours": 0, "swl_hours": 150, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": null, "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 6, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 5, "department_id": null, "plan_semester": 4, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": 2}	\N	\N	2026-06-24 04:24:27.430504+03
1957	\N	INSERT	courses	49	\N	{"id": 49, "code": "CSE221", "name": "Database Systems", "year": null, "credits": 3, "name_ar": null, "category": "core", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 3, "lct_hours": 2, "oth_hours": 0, "swl_hours": 150, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": null, "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 6, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 5, "department_id": null, "plan_semester": 4, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": 2}	\N	\N	2026-06-24 04:24:27.430504+03
1958	\N	INSERT	courses	50	\N	{"id": 50, "code": "CSE251", "name": "Software Engineering", "year": null, "credits": 3, "name_ar": null, "category": "core", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 3, "lct_hours": 2, "oth_hours": 0, "swl_hours": 150, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": null, "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 6, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 5, "department_id": null, "plan_semester": 4, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": 2}	\N	\N	2026-06-24 04:24:27.430504+03
1959	\N	INSERT	courses	51	\N	{"id": 51, "code": "CSE315", "name": "Discrete Mathematics", "year": null, "credits": 3, "name_ar": null, "category": "core", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 0, "lct_hours": 2, "oth_hours": 0, "swl_hours": 150, "tut_hours": 2, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": null, "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 6, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 4, "department_id": null, "plan_semester": 4, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": 2}	\N	\N	2026-06-24 04:24:27.430504+03
1960	\N	INSERT	courses	52	\N	{"id": 52, "code": "UC4", "name": "University Requirement (4)", "year": null, "credits": 2, "name_ar": null, "category": "university_req", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 0, "lct_hours": 2, "oth_hours": 0, "swl_hours": 90, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": null, "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 4, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 2, "department_id": null, "plan_semester": 4, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": 2}	\N	\N	2026-06-24 04:24:27.430504+03
1961	\N	INSERT	courses	53	\N	{"id": 53, "code": "CSE211", "name": "Web Programming", "year": null, "credits": 3, "name_ar": null, "category": "core", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 3, "lct_hours": 2, "oth_hours": 0, "swl_hours": 150, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": null, "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 6, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 5, "department_id": null, "plan_semester": 5, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": 3}	\N	\N	2026-06-24 04:24:27.430504+03
1962	\N	INSERT	courses	54	\N	{"id": 54, "code": "CSE233", "name": "Operating Systems", "year": null, "credits": 3, "name_ar": null, "category": "core", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 3, "lct_hours": 2, "oth_hours": 0, "swl_hours": 150, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": null, "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 6, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 5, "department_id": null, "plan_semester": 5, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": 3}	\N	\N	2026-06-24 04:24:27.430504+03
1963	\N	INSERT	courses	55	\N	{"id": 55, "code": "CSE241", "name": "Security of Information Systems", "year": null, "credits": 3, "name_ar": null, "category": "core", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 3, "lct_hours": 2, "oth_hours": 0, "swl_hours": 150, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": null, "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 6, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 5, "department_id": null, "plan_semester": 5, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": 3}	\N	\N	2026-06-24 04:24:27.430504+03
1964	\N	INSERT	courses	56	\N	{"id": 56, "code": "CSE261", "name": "Computer Networks", "year": null, "credits": 3, "name_ar": null, "category": "core", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 3, "lct_hours": 2, "oth_hours": 0, "swl_hours": 150, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": null, "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 6, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 5, "department_id": null, "plan_semester": 5, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": 3}	\N	\N	2026-06-24 04:24:27.430504+03
1965	\N	INSERT	courses	57	\N	{"id": 57, "code": "AIE111", "name": "Artificial Intelligence", "year": null, "credits": 3, "name_ar": null, "category": "core", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 3, "lct_hours": 2, "oth_hours": 0, "swl_hours": 150, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": null, "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 6, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 5, "department_id": null, "plan_semester": 5, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": 3}	\N	\N	2026-06-24 04:24:27.430504+03
1966	\N	INSERT	courses	58	\N	{"id": 58, "code": "UC5", "name": "University Requirement (5)", "year": null, "credits": 2, "name_ar": null, "category": "university_req", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 0, "lct_hours": 2, "oth_hours": 0, "swl_hours": 90, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": null, "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 4, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 2, "department_id": null, "plan_semester": 5, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": 3}	\N	\N	2026-06-24 04:24:27.430504+03
1967	\N	INSERT	courses	59	\N	{"id": 59, "code": "CSE212", "name": "Theory of Computation & Compilers", "year": null, "credits": 3, "name_ar": null, "category": "core", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 3, "lct_hours": 2, "oth_hours": 0, "swl_hours": 150, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": null, "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 6, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 5, "department_id": null, "plan_semester": 6, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": 3}	\N	\N	2026-06-24 04:24:27.430504+03
1968	\N	INSERT	courses	60	\N	{"id": 60, "code": "CSE292", "name": "Field Training 2 In Computer Science", "year": null, "credits": 2, "name_ar": null, "category": "field_training", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 0, "lct_hours": 2, "oth_hours": 0, "swl_hours": 90, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": null, "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 4, "is_pass_fail": true, "max_students": 40, "professor_id": null, "contact_hours": 2, "department_id": null, "plan_semester": 6, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": 3}	\N	\N	2026-06-24 04:24:27.430504+03
1969	\N	INSERT	courses	61	\N	{"id": 61, "code": "CSE323", "name": "Advanced Database Systems", "year": null, "credits": 3, "name_ar": null, "category": "core", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 3, "lct_hours": 2, "oth_hours": 0, "swl_hours": 150, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": null, "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 6, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 5, "department_id": null, "plan_semester": 6, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": 3}	\N	\N	2026-06-24 04:24:27.430504+03
1970	\N	INSERT	courses	62	\N	{"id": 62, "code": "CSE352", "name": "Systems Analysis & Design", "year": null, "credits": 3, "name_ar": null, "category": "core", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 3, "lct_hours": 2, "oth_hours": 0, "swl_hours": 150, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": null, "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 6, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 5, "department_id": null, "plan_semester": 6, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": 3}	\N	\N	2026-06-24 04:24:27.430504+03
1971	\N	INSERT	courses	63	\N	{"id": 63, "code": "AIE121", "name": "Machine Learning", "year": null, "credits": 3, "name_ar": null, "category": "core", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 3, "lct_hours": 2, "oth_hours": 0, "swl_hours": 150, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": null, "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 6, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 5, "department_id": null, "plan_semester": 6, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": 3}	\N	\N	2026-06-24 04:24:27.430504+03
1972	\N	INSERT	courses	64	\N	{"id": 64, "code": "UC6", "name": "University Requirement (6)", "year": null, "credits": 2, "name_ar": null, "category": "university_req", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 0, "lct_hours": 2, "oth_hours": 0, "swl_hours": 90, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": null, "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 4, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 2, "department_id": null, "plan_semester": 6, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": 3}	\N	\N	2026-06-24 04:24:27.430504+03
1973	\N	INSERT	courses	65	\N	{"id": 65, "code": "UE3", "name": "Elective University (3)", "year": null, "credits": 2, "name_ar": null, "category": "university_elective", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 0, "lct_hours": 2, "oth_hours": 0, "swl_hours": 90, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": null, "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 4, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 2, "department_id": null, "plan_semester": 6, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": 3}	\N	\N	2026-06-24 04:24:27.430504+03
1974	\N	INSERT	courses	66	\N	{"id": 66, "code": "CSE454", "name": "Advanced Software Engineering", "year": null, "credits": 3, "name_ar": null, "category": "core", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 3, "lct_hours": 2, "oth_hours": 0, "swl_hours": 150, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": null, "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 6, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 5, "department_id": null, "plan_semester": 7, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": 4}	\N	\N	2026-06-24 04:24:27.430504+03
1975	\N	INSERT	courses	67	\N	{"id": 67, "code": "CSE475", "name": "Distributed Information Systems", "year": null, "credits": 3, "name_ar": null, "category": "core", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 3, "lct_hours": 2, "oth_hours": 0, "swl_hours": 150, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": null, "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 6, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 5, "department_id": null, "plan_semester": 7, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": 4}	\N	\N	2026-06-24 04:24:27.430504+03
1976	\N	INSERT	courses	68	\N	{"id": 68, "code": "CSE493", "name": "Graduation Project 1", "year": null, "credits": 2, "name_ar": null, "category": "core", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 0, "lct_hours": 2, "oth_hours": 0, "swl_hours": 90, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": null, "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 4, "is_pass_fail": true, "max_students": 40, "professor_id": null, "contact_hours": 2, "department_id": null, "plan_semester": 7, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": 4}	\N	\N	2026-06-24 04:24:27.430504+03
1977	\N	INSERT	courses	69	\N	{"id": 69, "code": "CSE313", "name": "Mobile Development", "year": null, "credits": 3, "name_ar": null, "category": "core", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 3, "lct_hours": 2, "oth_hours": 0, "swl_hours": 150, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": null, "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 6, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 5, "department_id": null, "plan_semester": 7, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": 4}	\N	\N	2026-06-24 04:24:27.430504+03
1978	\N	INSERT	courses	70	\N	{"id": 70, "code": "UC7", "name": "University Requirement (7)", "year": null, "credits": 2, "name_ar": null, "category": "university_req", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 0, "lct_hours": 2, "oth_hours": 0, "swl_hours": 90, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": null, "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 4, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 2, "department_id": null, "plan_semester": 7, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": 4}	\N	\N	2026-06-24 04:24:27.430504+03
1979	\N	INSERT	courses	71	\N	{"id": 71, "code": "CSE363", "name": "Cloud Computing", "year": null, "credits": 3, "name_ar": null, "category": "core", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 3, "lct_hours": 2, "oth_hours": 0, "swl_hours": 150, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": null, "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 6, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 5, "department_id": null, "plan_semester": 8, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": 4}	\N	\N	2026-06-24 04:24:27.430504+03
1980	\N	INSERT	courses	72	\N	{"id": 72, "code": "CSE494", "name": "Graduation Project 2", "year": null, "credits": 2, "name_ar": null, "category": "core", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 0, "lct_hours": 2, "oth_hours": 0, "swl_hours": 90, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": null, "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 4, "is_pass_fail": true, "max_students": 40, "professor_id": null, "contact_hours": 2, "department_id": null, "plan_semester": 8, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": 4}	\N	\N	2026-06-24 04:24:27.430504+03
1981	\N	INSERT	courses	73	\N	{"id": 73, "code": "AIE323", "name": "Data Mining", "year": null, "credits": 3, "name_ar": null, "category": "core", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 3, "lct_hours": 2, "oth_hours": 0, "swl_hours": 150, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": null, "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 6, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 5, "department_id": null, "plan_semester": 8, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": 4}	\N	\N	2026-06-24 04:24:27.430504+03
1982	\N	INSERT	courses	74	\N	{"id": 74, "code": "CSE312", "name": "Advanced Web Programming", "year": null, "credits": 3, "name_ar": null, "category": "core", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 3, "lct_hours": 2, "oth_hours": 0, "swl_hours": 150, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": null, "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 6, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 5, "department_id": null, "plan_semester": 8, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": 4}	\N	\N	2026-06-24 04:24:27.430504+03
1983	\N	INSERT	courses	75	\N	{"id": 75, "code": "ELE432", "name": "Digital Signal Processing", "year": null, "credits": 3, "name_ar": null, "category": "elective", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 0, "lct_hours": 2, "oth_hours": 0, "swl_hours": 90, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": "E1:E3", "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 4, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 2, "department_id": null, "plan_semester": null, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": null}	\N	\N	2026-06-24 04:24:27.430504+03
1984	\N	INSERT	courses	76	\N	{"id": 76, "code": "CSE271", "name": "Introduction to Parallel Computing", "year": null, "credits": 3, "name_ar": null, "category": "elective", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 0, "lct_hours": 2, "oth_hours": 0, "swl_hours": 90, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": "E1:E3", "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 4, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 2, "department_id": null, "plan_semester": null, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": null}	\N	\N	2026-06-24 04:24:27.430504+03
1985	\N	INSERT	courses	77	\N	{"id": 77, "code": "CSE272", "name": "Embedded Systems", "year": null, "credits": 3, "name_ar": null, "category": "elective", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 0, "lct_hours": 2, "oth_hours": 0, "swl_hours": 90, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": "E1:E3", "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 4, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 2, "department_id": null, "plan_semester": null, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": null}	\N	\N	2026-06-24 04:24:27.430504+03
1986	\N	INSERT	courses	78	\N	{"id": 78, "code": "CSE281", "name": "Image Processing", "year": null, "credits": 3, "name_ar": null, "category": "elective", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 0, "lct_hours": 2, "oth_hours": 0, "swl_hours": 90, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": "E1:E3", "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 4, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 2, "department_id": null, "plan_semester": null, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": null}	\N	\N	2026-06-24 04:24:27.430504+03
1987	\N	INSERT	courses	79	\N	{"id": 79, "code": "CSE322", "name": "Big Data Analytics 1", "year": null, "credits": 3, "name_ar": null, "category": "elective", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 0, "lct_hours": 2, "oth_hours": 0, "swl_hours": 90, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": "E1:E3", "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 4, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 2, "department_id": null, "plan_semester": null, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": null}	\N	\N	2026-06-24 04:24:27.430504+03
1988	\N	INSERT	courses	80	\N	{"id": 80, "code": "CSE344", "name": "Introduction to Cyber Security", "year": null, "credits": 3, "name_ar": null, "category": "elective", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 0, "lct_hours": 2, "oth_hours": 0, "swl_hours": 90, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": "E1:E3", "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 4, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 2, "department_id": null, "plan_semester": null, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": null}	\N	\N	2026-06-24 04:24:27.430504+03
1989	\N	INSERT	courses	81	\N	{"id": 81, "code": "CSE424", "name": "Data Warehousing", "year": null, "credits": 3, "name_ar": null, "category": "elective", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 0, "lct_hours": 2, "oth_hours": 0, "swl_hours": 90, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": "E1:E3", "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 4, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 2, "department_id": null, "plan_semester": null, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": null}	\N	\N	2026-06-24 04:24:27.430504+03
1990	\N	INSERT	courses	82	\N	{"id": 82, "code": "CSE426", "name": "Selected Topics in Data Science", "year": null, "credits": 3, "name_ar": null, "category": "elective", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 0, "lct_hours": 2, "oth_hours": 0, "swl_hours": 90, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": "E1:E3", "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 4, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 2, "department_id": null, "plan_semester": null, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": null}	\N	\N	2026-06-24 04:24:27.430504+03
1991	\N	INSERT	courses	83	\N	{"id": 83, "code": "CSE453", "name": "Software Testing", "year": null, "credits": 3, "name_ar": null, "category": "elective", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 0, "lct_hours": 2, "oth_hours": 0, "swl_hours": 90, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": "E1:E3", "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 4, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 2, "department_id": null, "plan_semester": null, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": null}	\N	\N	2026-06-24 04:24:27.430504+03
1992	\N	INSERT	courses	84	\N	{"id": 84, "code": "CSE455", "name": "Selected Topics in Software Engineering", "year": null, "credits": 3, "name_ar": null, "category": "elective", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 0, "lct_hours": 2, "oth_hours": 0, "swl_hours": 90, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": "E1:E3", "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 4, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 2, "department_id": null, "plan_semester": null, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": null}	\N	\N	2026-06-24 04:24:27.430504+03
1993	\N	INSERT	courses	85	\N	{"id": 85, "code": "CSE464", "name": "Internet of Things", "year": null, "credits": 3, "name_ar": null, "category": "elective", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 0, "lct_hours": 2, "oth_hours": 0, "swl_hours": 90, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": "E1:E3", "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 4, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 2, "department_id": null, "plan_semester": null, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": null}	\N	\N	2026-06-24 04:24:27.430504+03
1994	\N	INSERT	courses	86	\N	{"id": 86, "code": "CSE478", "name": "High Performance Computing", "year": null, "credits": 3, "name_ar": null, "category": "elective", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 0, "lct_hours": 2, "oth_hours": 0, "swl_hours": 90, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": "E1:E3", "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 4, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 2, "department_id": null, "plan_semester": null, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": null}	\N	\N	2026-06-24 04:24:27.430504+03
1995	\N	INSERT	courses	87	\N	{"id": 87, "code": "AIE231", "name": "Neural Networks", "year": null, "credits": 3, "name_ar": null, "category": "elective", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 0, "lct_hours": 2, "oth_hours": 0, "swl_hours": 90, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": "E1:E3", "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 4, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 2, "department_id": null, "plan_semester": null, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": null}	\N	\N	2026-06-24 04:24:27.430504+03
1996	\N	INSERT	courses	88	\N	{"id": 88, "code": "AIE241", "name": "Natural Language Processing", "year": null, "credits": 3, "name_ar": null, "category": "elective", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 0, "lct_hours": 2, "oth_hours": 0, "swl_hours": 90, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": "E1:E3", "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 4, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 2, "department_id": null, "plan_semester": null, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": null}	\N	\N	2026-06-24 04:24:27.430504+03
1997	\N	INSERT	courses	89	\N	{"id": 89, "code": "AIE314", "name": "Ai-Based Programming", "year": null, "credits": 3, "name_ar": null, "category": "elective", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 0, "lct_hours": 2, "oth_hours": 0, "swl_hours": 90, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": "E1:E3", "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 4, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 2, "department_id": null, "plan_semester": null, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": null}	\N	\N	2026-06-24 04:24:27.430504+03
1998	\N	INSERT	courses	90	\N	{"id": 90, "code": "AIE322", "name": "Advanced Machine Learning", "year": null, "credits": 3, "name_ar": null, "category": "elective", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 0, "lct_hours": 2, "oth_hours": 0, "swl_hours": 90, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": "E1:E3", "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 4, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 2, "department_id": null, "plan_semester": null, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": null}	\N	\N	2026-06-24 04:24:27.430504+03
1999	\N	INSERT	courses	91	\N	{"id": 91, "code": "AIE332", "name": "Deep Learning", "year": null, "credits": 3, "name_ar": null, "category": "elective", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 0, "lct_hours": 2, "oth_hours": 0, "swl_hours": 90, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": "E1:E3", "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 4, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 2, "department_id": null, "plan_semester": null, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": null}	\N	\N	2026-06-24 04:24:27.430504+03
2000	\N	INSERT	courses	92	\N	{"id": 92, "code": "AIE342", "name": "Advanced Methods for Data Analysis", "year": null, "credits": 3, "name_ar": null, "category": "elective", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 0, "lct_hours": 2, "oth_hours": 0, "swl_hours": 90, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": "E1:E3", "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 4, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 2, "department_id": null, "plan_semester": null, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": null}	\N	\N	2026-06-24 04:24:27.430504+03
2001	\N	INSERT	courses	93	\N	{"id": 93, "code": "AIE343", "name": "Machine Learning for Text Mining", "year": null, "credits": 3, "name_ar": null, "category": "elective", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 0, "lct_hours": 2, "oth_hours": 0, "swl_hours": 90, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": "E1:E3", "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 4, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 2, "department_id": null, "plan_semester": null, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": null}	\N	\N	2026-06-24 04:24:27.430504+03
2002	\N	INSERT	courses	94	\N	{"id": 94, "code": "AIE424", "name": "Intelligent Decision Support Systems", "year": null, "credits": 3, "name_ar": null, "category": "elective", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 0, "lct_hours": 2, "oth_hours": 0, "swl_hours": 90, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": "E1:E3", "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 4, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 2, "department_id": null, "plan_semester": null, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": null}	\N	\N	2026-06-24 04:24:27.430504+03
2003	\N	INSERT	courses	95	\N	{"id": 95, "code": "AIE425", "name": "Intelligent Recommender Systems", "year": null, "credits": 3, "name_ar": null, "category": "elective", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 0, "lct_hours": 2, "oth_hours": 0, "swl_hours": 90, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": "E1:E3", "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 4, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 2, "department_id": null, "plan_semester": null, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": null}	\N	\N	2026-06-24 04:24:27.430504+03
2004	\N	INSERT	courses	96	\N	{"id": 96, "code": "CSE467", "name": "Client/Server Technologies & Applications", "year": null, "credits": 3, "name_ar": null, "category": "elective", "semester": null, "track_id": 3, "is_active": true, "lab_hours": 0, "lct_hours": 2, "oth_hours": 0, "swl_hours": 90, "tut_hours": 0, "created_at": "2026-06-24T04:24:27.430504+03:00", "program_id": 3, "slot_label": "E1:E3", "updated_at": "2026-06-24T04:24:27.430504+03:00", "description": null, "ects_credits": 4, "is_pass_fail": false, "max_students": 40, "professor_id": null, "contact_hours": 2, "department_id": null, "plan_semester": null, "counts_in_cgpa": true, "pass_threshold": 60.00, "curriculum_level": null}	\N	\N	2026-06-24 04:24:27.430504+03
\.


--
-- Data for Name: cohort_memberships; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cohort_memberships (id, student_id, cohort_id, join_date, expected_grad_date, actual_grad_date, is_delayed, delay_reason, semesters_completed, status, notes, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: course_eligibility_rules; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.course_eligibility_rules (id, course_id, rule_type, rule_value, rule_text, is_mandatory, notes, created_at) FROM stdin;
5	68	min_credits_earned	90.00	Senior Standing: must have earned at least 90 credit hours	t	\N	2026-06-24 04:24:27.478511+03
6	60	completed_course	\N	Must have completed CSE191 (Field Training 1)	t	\N	2026-06-24 04:24:27.481445+03
\.


--
-- Data for Name: course_grade_weights; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.course_grade_weights (id, course_id, attendance_weight, quiz_weight, practical_weight, coursework_weight, max_quiz_score, max_practical, total_sessions, updated_by, updated_at) FROM stdin;
\.


--
-- Data for Name: course_offerings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.course_offerings (id, course_id, term_id, professor_id, section, max_capacity, current_enrolled, room, schedule_json, is_open, notes, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: course_postrequisites; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.course_postrequisites (id, course_id, postreq_id, unlock_type, notes, created_at) FROM stdin;
67	29	35	C	\N	2026-06-24 04:24:27.466299+03
68	29	59	C	\N	2026-06-24 04:24:27.466299+03
69	35	41	C	\N	2026-06-24 04:24:27.466299+03
70	35	50	C	\N	2026-06-24 04:24:27.466299+03
71	35	69	C	\N	2026-06-24 04:24:27.466299+03
72	41	47	C	\N	2026-06-24 04:24:27.466299+03
73	41	54	C	\N	2026-06-24 04:24:27.466299+03
74	42	48	C	\N	2026-06-24 04:24:27.466299+03
75	43	60	C	\N	2026-06-24 04:24:27.466299+03
76	46	78	E	\N	2026-06-24 04:24:27.466299+03
77	47	55	C	\N	2026-06-24 04:24:27.466299+03
78	47	96	E	\N	2026-06-24 04:24:27.466299+03
79	48	54	C	\N	2026-06-24 04:24:27.466299+03
80	49	61	C	\N	2026-06-24 04:24:27.466299+03
81	49	96	E	\N	2026-06-24 04:24:27.466299+03
82	50	62	C	\N	2026-06-24 04:24:27.466299+03
83	50	66	C	\N	2026-06-24 04:24:27.466299+03
84	53	74	C	\N	2026-06-24 04:24:27.466299+03
85	54	80	E	\N	2026-06-24 04:24:27.466299+03
86	56	80	E	\N	2026-06-24 04:24:27.466299+03
87	56	71	C	\N	2026-06-24 04:24:27.466299+03
88	57	63	C	\N	2026-06-24 04:24:27.466299+03
89	57	88	E	\N	2026-06-24 04:24:27.466299+03
90	61	81	E	\N	2026-06-24 04:24:27.466299+03
91	63	73	C	\N	2026-06-24 04:24:27.466299+03
92	63	87	E	\N	2026-06-24 04:24:27.466299+03
93	63	90	E	\N	2026-06-24 04:24:27.466299+03
94	68	72	C	\N	2026-06-24 04:24:27.466299+03
95	73	93	E	\N	2026-06-24 04:24:27.466299+03
96	73	94	E	\N	2026-06-24 04:24:27.466299+03
97	73	95	E	\N	2026-06-24 04:24:27.466299+03
98	73	92	E	\N	2026-06-24 04:24:27.466299+03
99	87	91	E	\N	2026-06-24 04:24:27.466299+03
\.


--
-- Data for Name: course_prerequisites; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.course_prerequisites (id, course_id, prerequisite_id, prereq_type, min_grade, notes, created_at, logic_group, logic_type) FROM stdin;
67	35	29	hard	60.00	\N	2026-06-24 04:24:27.453731+03	1	AND
68	41	35	hard	60.00	\N	2026-06-24 04:24:27.453731+03	1	AND
69	47	41	hard	60.00	\N	2026-06-24 04:24:27.453731+03	1	AND
70	48	42	hard	60.00	\N	2026-06-24 04:24:27.453731+03	1	AND
71	54	41	hard	60.00	\N	2026-06-24 04:24:27.453731+03	1	AND
72	54	48	hard	60.00	\N	2026-06-24 04:24:27.453731+03	1	AND
73	59	35	hard	60.00	\N	2026-06-24 04:24:27.453731+03	1	AND
74	55	47	hard	60.00	\N	2026-06-24 04:24:27.453731+03	1	AND
75	50	35	hard	60.00	\N	2026-06-24 04:24:27.453731+03	1	AND
76	63	57	hard	60.00	\N	2026-06-24 04:24:27.453731+03	1	AND
77	78	46	hard	60.00	\N	2026-06-24 04:24:27.453731+03	1	AND
78	61	49	hard	60.00	\N	2026-06-24 04:24:27.453731+03	1	AND
79	62	50	hard	60.00	\N	2026-06-24 04:24:27.453731+03	1	AND
80	66	50	hard	60.00	\N	2026-06-24 04:24:27.453731+03	1	AND
81	69	35	hard	60.00	\N	2026-06-24 04:24:27.453731+03	1	AND
82	74	53	hard	60.00	\N	2026-06-24 04:24:27.453731+03	1	AND
83	71	56	hard	60.00	\N	2026-06-24 04:24:27.453731+03	1	AND
84	73	63	hard	60.00	\N	2026-06-24 04:24:27.453731+03	1	AND
85	60	43	hard	60.00	\N	2026-06-24 04:24:27.453731+03	1	AND
86	72	68	hard	60.00	\N	2026-06-24 04:24:27.453731+03	1	AND
87	96	47	hard	60.00	\N	2026-06-24 04:24:27.453731+03	1	AND
88	96	49	hard	60.00	\N	2026-06-24 04:24:27.453731+03	1	AND
89	80	54	hard	60.00	\N	2026-06-24 04:24:27.453731+03	1	AND
90	80	56	hard	60.00	\N	2026-06-24 04:24:27.453731+03	1	AND
91	87	63	hard	60.00	\N	2026-06-24 04:24:27.453731+03	1	AND
92	88	57	hard	60.00	\N	2026-06-24 04:24:27.453731+03	1	AND
93	90	63	hard	60.00	\N	2026-06-24 04:24:27.453731+03	1	AND
94	91	87	hard	60.00	\N	2026-06-24 04:24:27.453731+03	1	AND
95	92	73	hard	60.00	\N	2026-06-24 04:24:27.453731+03	1	AND
96	93	73	hard	60.00	\N	2026-06-24 04:24:27.453731+03	1	AND
97	94	73	hard	60.00	\N	2026-06-24 04:24:27.453731+03	1	AND
98	95	73	hard	60.00	\N	2026-06-24 04:24:27.453731+03	1	AND
99	81	61	hard	60.00	\N	2026-06-24 04:24:27.453731+03	1	AND
\.


--
-- Data for Name: course_sections; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.course_sections (id, course_id, ta_id, section_name, schedule, room, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: courses; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.courses (id, code, name, description, credits, semester, year, professor_id, department_id, max_students, is_active, created_at, updated_at, program_id, track_id, category, curriculum_level, plan_semester, lct_hours, lab_hours, tut_hours, oth_hours, contact_hours, ects_credits, slot_label, swl_hours, counts_in_cgpa, is_pass_fail, pass_threshold, name_ar) FROM stdin;
29	CSE014	Structured Programming	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	core	1	1	2	3	0	0	5	6	\N	150	t	f	60.00	\N
30	PHY211	Physics II	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	core	1	1	2	2	0	0	4	6	\N	150	t	f	60.00	\N
31	MAT114	Analytical Geometry & Calculus I	\N	4	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	core	1	1	3	0	2	0	5	8	\N	195	t	f	60.00	\N
32	UC1	University Requirement (1)	\N	2	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	university_req	1	1	2	0	0	0	2	4	\N	90	t	f	60.00	\N
33	UE1	Elective University (1)	\N	2	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	university_elective	1	1	2	0	0	0	2	4	\N	90	t	f	60.00	\N
34	UC2	University Requirement (2)	\N	2	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	university_req	1	1	2	0	0	0	2	4	\N	90	t	f	60.00	\N
35	CSE015	Object Oriented Programming	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	core	1	2	2	3	0	0	5	6	\N	150	t	f	60.00	\N
36	CSE113	Electric & Electronic Circuits	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	core	1	2	2	2	1	0	5	6	\N	150	t	f	60.00	\N
37	MAT131	Statistics	\N	2	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	core	1	2	1	0	2	0	3	4	\N	105	t	f	60.00	\N
38	MAT112	Mathematics II	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	core	1	2	2	0	2	0	4	6	\N	150	t	f	60.00	\N
39	UC3	University Requirement (3)	\N	2	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	university_req	1	2	2	0	0	0	2	4	\N	90	t	f	60.00	\N
40	UE2	Elective University Requirement (2)	\N	2	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	university_elective	1	2	2	0	0	0	2	4	\N	90	t	f	60.00	\N
41	CSE111	Data Structures	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	core	2	3	2	3	0	0	5	6	\N	150	t	f	60.00	\N
42	CSE131	Logic Design	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	core	2	3	2	3	0	0	5	6	\N	150	t	f	60.00	\N
43	CSE191	Field Training 1 In Computer Science	\N	2	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	field_training	2	3	2	0	0	0	2	4	\N	90	t	t	60.00	\N
44	MAT313	Differential Equations & Numerical Analysis	\N	4	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	core	2	3	3	0	2	0	5	8	\N	195	t	f	60.00	\N
45	MAT231	Probability & Statistics	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	core	2	3	2	0	2	0	4	6	\N	150	t	f	60.00	\N
46	MAT212	Linear Algebra	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	core	2	3	2	0	2	0	4	6	\N	150	t	f	60.00	\N
47	CSE112	Design & Analysis of Algorithms	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	core	2	4	2	3	0	0	5	6	\N	150	t	f	60.00	\N
48	CSE132	Computer Architecture & Organization	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	core	2	4	2	3	0	0	5	6	\N	150	t	f	60.00	\N
49	CSE221	Database Systems	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	core	2	4	2	3	0	0	5	6	\N	150	t	f	60.00	\N
50	CSE251	Software Engineering	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	core	2	4	2	3	0	0	5	6	\N	150	t	f	60.00	\N
51	CSE315	Discrete Mathematics	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	core	2	4	2	0	2	0	4	6	\N	150	t	f	60.00	\N
52	UC4	University Requirement (4)	\N	2	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	university_req	2	4	2	0	0	0	2	4	\N	90	t	f	60.00	\N
53	CSE211	Web Programming	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	core	3	5	2	3	0	0	5	6	\N	150	t	f	60.00	\N
54	CSE233	Operating Systems	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	core	3	5	2	3	0	0	5	6	\N	150	t	f	60.00	\N
55	CSE241	Security of Information Systems	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	core	3	5	2	3	0	0	5	6	\N	150	t	f	60.00	\N
56	CSE261	Computer Networks	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	core	3	5	2	3	0	0	5	6	\N	150	t	f	60.00	\N
57	AIE111	Artificial Intelligence	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	core	3	5	2	3	0	0	5	6	\N	150	t	f	60.00	\N
58	UC5	University Requirement (5)	\N	2	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	university_req	3	5	2	0	0	0	2	4	\N	90	t	f	60.00	\N
59	CSE212	Theory of Computation & Compilers	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	core	3	6	2	3	0	0	5	6	\N	150	t	f	60.00	\N
60	CSE292	Field Training 2 In Computer Science	\N	2	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	field_training	3	6	2	0	0	0	2	4	\N	90	t	t	60.00	\N
61	CSE323	Advanced Database Systems	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	core	3	6	2	3	0	0	5	6	\N	150	t	f	60.00	\N
62	CSE352	Systems Analysis & Design	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	core	3	6	2	3	0	0	5	6	\N	150	t	f	60.00	\N
63	AIE121	Machine Learning	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	core	3	6	2	3	0	0	5	6	\N	150	t	f	60.00	\N
64	UC6	University Requirement (6)	\N	2	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	university_req	3	6	2	0	0	0	2	4	\N	90	t	f	60.00	\N
65	UE3	Elective University (3)	\N	2	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	university_elective	3	6	2	0	0	0	2	4	\N	90	t	f	60.00	\N
66	CSE454	Advanced Software Engineering	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	core	4	7	2	3	0	0	5	6	\N	150	t	f	60.00	\N
67	CSE475	Distributed Information Systems	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	core	4	7	2	3	0	0	5	6	\N	150	t	f	60.00	\N
68	CSE493	Graduation Project 1	\N	2	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	core	4	7	2	0	0	0	2	4	\N	90	t	t	60.00	\N
69	CSE313	Mobile Development	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	core	4	7	2	3	0	0	5	6	\N	150	t	f	60.00	\N
70	UC7	University Requirement (7)	\N	2	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	university_req	4	7	2	0	0	0	2	4	\N	90	t	f	60.00	\N
71	CSE363	Cloud Computing	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	core	4	8	2	3	0	0	5	6	\N	150	t	f	60.00	\N
72	CSE494	Graduation Project 2	\N	2	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	core	4	8	2	0	0	0	2	4	\N	90	t	t	60.00	\N
73	AIE323	Data Mining	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	core	4	8	2	3	0	0	5	6	\N	150	t	f	60.00	\N
74	CSE312	Advanced Web Programming	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	core	4	8	2	3	0	0	5	6	\N	150	t	f	60.00	\N
75	ELE432	Digital Signal Processing	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	elective	\N	\N	2	0	0	0	2	4	E1:E3	90	t	f	60.00	\N
76	CSE271	Introduction to Parallel Computing	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	elective	\N	\N	2	0	0	0	2	4	E1:E3	90	t	f	60.00	\N
77	CSE272	Embedded Systems	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	elective	\N	\N	2	0	0	0	2	4	E1:E3	90	t	f	60.00	\N
78	CSE281	Image Processing	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	elective	\N	\N	2	0	0	0	2	4	E1:E3	90	t	f	60.00	\N
79	CSE322	Big Data Analytics 1	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	elective	\N	\N	2	0	0	0	2	4	E1:E3	90	t	f	60.00	\N
80	CSE344	Introduction to Cyber Security	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	elective	\N	\N	2	0	0	0	2	4	E1:E3	90	t	f	60.00	\N
81	CSE424	Data Warehousing	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	elective	\N	\N	2	0	0	0	2	4	E1:E3	90	t	f	60.00	\N
82	CSE426	Selected Topics in Data Science	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	elective	\N	\N	2	0	0	0	2	4	E1:E3	90	t	f	60.00	\N
83	CSE453	Software Testing	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	elective	\N	\N	2	0	0	0	2	4	E1:E3	90	t	f	60.00	\N
84	CSE455	Selected Topics in Software Engineering	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	elective	\N	\N	2	0	0	0	2	4	E1:E3	90	t	f	60.00	\N
85	CSE464	Internet of Things	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	elective	\N	\N	2	0	0	0	2	4	E1:E3	90	t	f	60.00	\N
86	CSE478	High Performance Computing	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	elective	\N	\N	2	0	0	0	2	4	E1:E3	90	t	f	60.00	\N
87	AIE231	Neural Networks	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	elective	\N	\N	2	0	0	0	2	4	E1:E3	90	t	f	60.00	\N
88	AIE241	Natural Language Processing	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	elective	\N	\N	2	0	0	0	2	4	E1:E3	90	t	f	60.00	\N
89	AIE314	Ai-Based Programming	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	elective	\N	\N	2	0	0	0	2	4	E1:E3	90	t	f	60.00	\N
90	AIE322	Advanced Machine Learning	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	elective	\N	\N	2	0	0	0	2	4	E1:E3	90	t	f	60.00	\N
91	AIE332	Deep Learning	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	elective	\N	\N	2	0	0	0	2	4	E1:E3	90	t	f	60.00	\N
92	AIE342	Advanced Methods for Data Analysis	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	elective	\N	\N	2	0	0	0	2	4	E1:E3	90	t	f	60.00	\N
93	AIE343	Machine Learning for Text Mining	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	elective	\N	\N	2	0	0	0	2	4	E1:E3	90	t	f	60.00	\N
94	AIE424	Intelligent Decision Support Systems	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	elective	\N	\N	2	0	0	0	2	4	E1:E3	90	t	f	60.00	\N
95	AIE425	Intelligent Recommender Systems	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	elective	\N	\N	2	0	0	0	2	4	E1:E3	90	t	f	60.00	\N
96	CSE467	Client/Server Technologies & Applications	\N	3	\N	\N	\N	\N	40	t	2026-06-24 04:24:27.430504+03	2026-06-24 04:24:27.430504+03	3	3	elective	\N	\N	2	0	0	0	2	4	E1:E3	90	t	f	60.00	\N
\.


--
-- Data for Name: degree_progress_snapshots; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.degree_progress_snapshots (id, student_id, term_id, version, required_credits, earned_credits, remaining_credits, completion_percentage, category_breakdown, missing_core_courses, missing_elective_slots, missing_categories, all_core_complete, all_electives_complete, field_training_complete, graduation_project_complete, computed_at, computed_by) FROM stdin;
\.


--
-- Data for Name: departments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.departments (id, name, code, head_professor_id, description, created_at, updated_at) FROM stdin;
1	Computer Science	CS	\N	Department of Computer Science and Software Engineering	2026-06-24 04:24:16.514358+03	2026-06-24 04:24:16.514358+03
2	Artificial Intelligence	AI	\N	Department of AI and Machine Learning	2026-06-24 04:24:16.514358+03	2026-06-24 04:24:16.514358+03
3	Information Systems	IS	\N	Department of Information Systems and Data Management	2026-06-24 04:24:16.514358+03	2026-06-24 04:24:16.514358+03
4	Computer Networks	NET	\N	Department of Computer Networks and Communications	2026-06-24 04:24:16.514358+03	2026-06-24 04:24:16.514358+03
5	Software Engineering	SE	\N	Department of Software Engineering and Quality	2026-06-24 04:24:16.514358+03	2026-06-24 04:24:16.514358+03
6	Cybersecurity	SEC	\N	Department of Cybersecurity and Digital Forensics	2026-06-24 04:24:16.514358+03	2026-06-24 04:24:16.514358+03
7	Data Science	DS	\N	Department of Data Science and Analytics	2026-06-24 04:24:16.514358+03	2026-06-24 04:24:16.514358+03
8	Human-Computer Interaction	HCI	\N	Department of HCI and UX Design	2026-06-24 04:24:16.514358+03	2026-06-24 04:24:16.514358+03
\.


--
-- Data for Name: elective_pool_courses; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.elective_pool_courses (id, pool_id, course_id, created_at) FROM stdin;
\.


--
-- Data for Name: elective_pools; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.elective_pools (id, program_id, track_id, pool_code, pool_name, min_selections, max_selections, required_selections, plan_semesters, notes, created_at) FROM stdin;
\.


--
-- Data for Name: enrollments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.enrollments (id, student_id, course_id, status, grade, letter_grade, enrolled_at, dropped_at, completed_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: gpa_explanations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.gpa_explanations (id, student_id, term_id, formula_description, repeat_policy, included_attempts, excluded_attempts, total_quality_points, total_hours_attempted, computed_cgpa, semester_quality_points, semester_hours_attempted, computed_semester_gpa, all_rules_sourced, policy_notes, generated_at, is_current) FROM stdin;
\.


--
-- Data for Name: gpa_projections; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.gpa_projections (id, student_id, term_id, projection_type, current_cgpa, current_credits, target_cgpa, remaining_credits, scenario_input, projection_result, projected_semester_gpa, projected_cgpa, is_achievable, computed_at) FROM stdin;
\.


--
-- Data for Name: gpa_versions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.gpa_versions (id, student_id, term_id, version_number, semester_gpa, cgpa, total_hours_attempted, total_hours_earned, total_quality_points, cgpa_delta, gpa_delta, trigger_event, trigger_details, repeat_policy_used, computed_by, recorded_at) FROM stdin;
\.


--
-- Data for Name: grade_records; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.grade_records (id, student_id, course_id, assessment_type, assessment_name, score, max_score, weight, graded_at, graded_by, notes, created_at) FROM stdin;
\.


--
-- Data for Name: grade_scale; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.grade_scale (id, program_id, letter_grade, min_percentage, max_percentage, grade_points, counts_in_cgpa, is_passing, description, failure_type) FROM stdin;
48	3	A+	97.00	100.00	4.00	t	t	Excellent Plus	\N
49	3	A	93.00	96.99	4.00	t	t	Excellent	\N
50	3	A-	90.00	92.99	3.70	t	t	Excellent Minus	\N
51	3	B+	87.00	89.99	3.30	t	t	Very Good Plus	\N
52	3	B	83.00	86.99	3.00	t	t	Very Good	\N
53	3	B-	80.00	82.99	2.70	t	t	Very Good Minus	\N
54	3	C+	77.00	79.99	2.30	t	t	Good Plus	\N
55	3	C	73.00	76.99	2.00	t	t	Good	\N
56	3	C-	70.00	72.99	1.70	t	t	Good Minus	\N
57	3	D+	67.00	69.99	1.30	t	t	Pass Plus	\N
58	3	D	60.00	66.99	1.00	t	t	Pass	\N
59	3	F	0.00	59.99	0.00	t	f	Fail	\N
60	3	FL	0.00	59.99	0.00	t	f	Fail + Absence Lock	\N
61	3	W	\N	\N	0.00	f	f	Withdrawn	\N
62	3	P	\N	\N	0.00	f	t	Pass (non-graded)	\N
77	\N	A+	97.00	100.00	4.00	t	t	Outstanding	\N
78	\N	A	93.00	96.00	4.00	t	t	Excellent	\N
79	\N	A-	90.00	92.00	3.70	t	t	Excellent Minus	\N
80	\N	B+	87.00	89.00	3.30	t	t	Very Good Plus	\N
81	\N	B	83.00	86.00	3.00	t	t	Very Good	\N
82	\N	B-	80.00	82.00	2.70	t	t	Very Good Minus	\N
83	\N	C+	77.00	79.00	2.30	t	t	Good Plus	\N
84	\N	C	73.00	76.00	2.00	t	t	Good	\N
85	\N	C-	70.00	72.00	1.70	t	t	Good Minus	\N
86	\N	D+	67.00	69.00	1.30	t	t	Acceptable Plus	\N
87	\N	D	60.00	66.00	1.00	t	t	Acceptable (Minimum Pass)	\N
88	\N	F	0.00	59.00	0.00	t	f	Fail	\N
89	\N	FL	0.00	0.00	0.00	t	f	Fail Late	\N
90	\N	W	0.00	0.00	0.00	f	f	Withdrawal	\N
91	\N	I	0.00	0.00	0.00	f	f	Incomplete	\N
92	\N	P	0.00	0.00	0.00	f	t	Pass (Pass/Fail)	\N
93	\N	IP	0.00	0.00	0.00	f	f	In Progress	\N
\.


--
-- Data for Name: graduation_audit_results; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.graduation_audit_results (id, student_id, audited_at, is_eligible, total_ch_required, total_ch_earned, core_courses_required, core_courses_completed, electives_required, electives_completed, field_training_done, graduation_project_done, univ_req_done, cgpa_at_audit, blocking_reasons, completed_requirements, missing_courses, audit_version, triggered_by, created_at) FROM stdin;
\.


--
-- Data for Name: graduation_eligibility_records; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.graduation_eligibility_records (id, student_id, term_id, eligibility_status, requirements_met, missing_requirements, cgpa_at_evaluation, credits_at_evaluation, evaluated_by, evaluated_at, notes, is_current) FROM stdin;
\.


--
-- Data for Name: graduation_requirements; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.graduation_requirements (id, program_id, track_id, category, label, required_credits, required_courses, min_cgpa, notes, created_at, updated_at) FROM stdin;
13	3	3	core	Program Core Courses	96	0	2.00	All core CS courses including field trainings and graduation project	2026-06-24 04:24:25.346005+03	2026-06-24 04:24:25.346005+03
14	3	3	elective	Program Elective Courses (E1â€“E3)	9	3	2.00	Three elective courses from the approved elective list	2026-06-24 04:24:25.346005+03	2026-06-24 04:24:25.346005+03
15	3	3	university_req	University Requirements (UC1â€“UC7)	14	7	2.00	Seven university mandatory requirement courses	2026-06-24 04:24:25.346005+03	2026-06-24 04:24:25.346005+03
16	3	3	university_elective	University Electives (UE1â€“UE3)	6	3	2.00	Three university elective courses	2026-06-24 04:24:25.346005+03	2026-06-24 04:24:25.346005+03
17	3	3	graduation_project	Graduation Project (GP1 + GP2)	4	2	2.00	CSE493 + CSE494 senior standing required for GP1	2026-06-24 04:24:25.346005+03	2026-06-24 04:24:25.346005+03
18	3	3	field_training	Field Training (FT1 + FT2)	4	2	2.00	CSE191 + CSE292	2026-06-24 04:24:25.346005+03	2026-06-24 04:24:25.346005+03
\.


--
-- Data for Name: honors_records; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.honors_records (id, student_id, term_id, honors_level, is_deans_list, term_gpa_used, cgpa_used, credits_used, qualification_data, awarded_at, awarded_by) FROM stdin;
\.


--
-- Data for Name: import_audit_events; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.import_audit_events (id, batch_id, event_type, actor_id, row_number, message, payload, created_at) FROM stdin;
\.


--
-- Data for Name: import_batches; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.import_batches (id, batch_ref, file_hash, file_name, file_size_bytes, file_format, import_type, source_system, status, total_rows, success_rows, failed_rows, skipped_rows, warning_count, imported_by, assigned_to, started_at, completed_at, duration_ms, retry_count, is_reprocess, mapping_version_id, notes, extra_meta, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: import_errors; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.import_errors (id, job_id, row_number, field_name, raw_value, error_message, created_at) FROM stdin;
\.


--
-- Data for Name: import_jobs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.import_jobs (id, job_type, status, file_name, file_size_bytes, total_rows, processed_rows, success_rows, error_rows, initiated_by, started_at, completed_at, error_summary, metadata_json, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: import_row_errors; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.import_row_errors (id, batch_id, row_number, field_name, raw_value, error_code, error_message, severity, category, extra_context, created_at) FROM stdin;
\.


--
-- Data for Name: intervention_actions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.intervention_actions (id, plan_id, description, completed, completed_at, due_date, order_index, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: intervention_plans; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.intervention_plans (id, student_id, advisor_id, title, description, status, priority, deadline, completed_at, notes, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: mapping_template_versions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.mapping_template_versions (id, template_id, version_number, field_mappings, transformations, is_current, published_by, published_at, notes) FROM stdin;
\.


--
-- Data for Name: mapping_templates; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.mapping_templates (id, name, description, import_type, source_system, is_active, created_by, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: notification_delivery_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notification_delivery_log (id, notification_id, channel, event_type, sent_at, delivered, error_message, metadata_json) FROM stdin;
\.


--
-- Data for Name: notification_preferences; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notification_preferences (id, user_id, event_type, in_app, email, sms, updated_at) FROM stdin;
\.


--
-- Data for Name: notification_templates; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notification_templates (id, event_type, channel, subject_template, body_template, priority, is_active, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notifications (id, user_id, title, message, type, priority, read, read_at, metadata, created_at) FROM stdin;
\.


--
-- Data for Name: pdf_transcript_jobs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pdf_transcript_jobs (id, student_id, transcript_version_id, transcript_type, status, page_count, file_size_bytes, result_key, error_message, options, requested_by, queued_at, started_at, completed_at, expires_at) FROM stdin;
\.


--
-- Data for Name: personal_access_tokens; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.personal_access_tokens (id, tokenable_type, tokenable_id, name, token, abilities, last_used_at, expires_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: prerequisite_exceptions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.prerequisite_exceptions (id, student_id, course_id, waived_prereq_id, granted_by, reason, approved_at, expires_at, is_active, created_at) FROM stdin;
\.


--
-- Data for Name: prerequisite_validation_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.prerequisite_validation_log (id, student_id, course_id, term_id, check_result, missing_prereqs, rule_triggered, explanation, decision_reason, checked_at, checked_by) FROM stdin;
\.


--
-- Data for Name: prerequisite_validations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.prerequisite_validations (id, student_id, term_id, course_id, course_code, is_eligible, missing_prereqs, satisfied_prereqs, policy_source, override_applied, override_by, override_reason, validated_at) FROM stdin;
\.


--
-- Data for Name: professors; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.professors (id, user_id, department_id, department, title, specialization, office_location, office_hours, created_at, updated_at) FROM stdin;
17	3	1	Computer Science	Associate Professor	Algorithms & Data Structures	CS Building, Room 305	Mon/Wed 2â€“4 PM	2026-06-24 04:24:16.530916+03	2026-06-24 04:24:16.530916+03
18	4	2	Artificial Intelligence	Professor	Machine Learning & Deep Learning	CS Building, Room 210	Tue/Thu 10â€“12 PM	2026-06-24 04:24:16.530916+03	2026-06-24 04:24:16.530916+03
19	5	3	Information Systems	Assistant Professor	Database Systems & Analytics	IS Building, Room 102	Mon/Fri 1â€“3 PM	2026-06-24 04:24:16.530916+03	2026-06-24 04:24:16.530916+03
20	6	4	Computer Networks	Professor	Network Protocols & Security	NET Lab, Room 401	Wed/Thu 3â€“5 PM	2026-06-24 04:24:16.530916+03	2026-06-24 04:24:16.530916+03
21	7	5	Software Engineering	Associate Professor	Software Architecture & DevOps	SE Building, Room 215	Tue/Thu 2â€“4 PM	2026-06-24 04:24:16.530916+03	2026-06-24 04:24:16.530916+03
22	8	6	Cybersecurity	Assistant Professor	Ethical Hacking & Forensics	SEC Lab, Room 118	Mon/Wed/Fri 11â€“12 PM	2026-06-24 04:24:16.530916+03	2026-06-24 04:24:16.530916+03
23	9	7	Data Science	Associate Professor	Statistical Learning & Viz	DS Building, Room 330	Mon/Wed 3â€“5 PM	2026-06-24 04:24:16.530916+03	2026-06-24 04:24:16.530916+03
\.


--
-- Data for Name: questions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.questions (id, quiz_id, type, text, options_json, correct_answer, explanation, points, order_index, created_at) FROM stdin;
\.


--
-- Data for Name: quiz_sessions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.quiz_sessions (id, quiz_id, student_id, started_at, ended_at, violation_count, fullscreen_exits, focus_losses, tab_switches, copy_attempts, paste_attempts, right_clicks, devtools_attempts, status, final_reason, browser_info, ip_address) FROM stdin;
\.


--
-- Data for Name: quiz_submissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.quiz_submissions (id, quiz_id, student_id, answers_json, score, max_score, percentage, passed, attempt_number, time_taken_minutes, submitted_at, graded_at, graded_by, feedback) FROM stdin;
\.


--
-- Data for Name: quiz_violations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.quiz_violations (id, quiz_id, student_id, submission_id, violation_type, severity, violation_count, metadata_json, created_at) FROM stdin;
\.


--
-- Data for Name: quizzes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.quizzes (id, title, description, course_id, created_by, duration_minutes, attempts_limit, start_time, end_time, shuffle_questions, randomize_options, show_results, passing_score, status, total_points, created_at, updated_at, secure_mode, require_fullscreen, detect_focus_loss, detect_tab_switch, block_copy_paste, block_right_click, block_shortcuts, detect_devtools, max_violations, auto_submit_on_limit, warning_message) FROM stdin;
\.


--
-- Data for Name: rbac_permissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.rbac_permissions (id, role, resource, action, conditions, is_active, created_at) FROM stdin;
\.


--
-- Data for Name: reconciliation_items; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.reconciliation_items (id, report_id, recon_type, entity_type, entity_key, incoming_value, existing_value, conflict_fields, status, resolved_by, resolved_at, resolution_note, created_at) FROM stdin;
\.


--
-- Data for Name: reconciliation_reports; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.reconciliation_reports (id, batch_id, import_type, total_checked, duplicates_found, conflicts_found, mismatches_found, summary, generated_at) FROM stdin;
\.


--
-- Data for Name: registrar_notes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.registrar_notes (id, student_id, term_id, note_type, title, content, tags, is_private, version, previous_version_id, created_by, updated_by, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: registrar_task_assignments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.registrar_task_assignments (id, task_id, assigned_to, assigned_by, assigned_at, unassigned_at, notes) FROM stdin;
\.


--
-- Data for Name: registrar_tasks; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.registrar_tasks (id, task_number, task_type, status, priority, student_id, term_id, case_id, transfer_id, exemption_id, pdf_job_id, title, description, due_date, assigned_to, assigned_at, completed_by, completed_at, resolution_notes, created_by, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: registration_events; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.registration_events (id, student_id, term_id, course_id, attempt_id, event_type, event_detail, payload, requires_approval, approved_by, approved_at, rejection_reason, actor_id, actor_role, ip_address, occurred_at) FROM stdin;
\.


--
-- Data for Name: risk_assessments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.risk_assessments (id, student_id, risk_level, probability, grades_impact, attendance_impact, activity_impact, dropout_probability, graduation_delay_likelihood, scholarship_eligibility, trend, explanation, recommendations, features_snapshot, assessed_at, assessed_by, model_version, created_at) FROM stdin;
\.


--
-- Data for Name: scholarship_evaluations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.scholarship_evaluations (id, student_id, term_id, status, cgpa_at_evaluation, credits_at_evaluation, term_gpa_at_evaluation, rules_applied, criteria_met, unmet_criteria, policy_gaps, notes, evaluated_by, evaluated_at, is_current) FROM stdin;
\.


--
-- Data for Name: semester_snapshots; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.semester_snapshots (id, student_id, term_id, version, term_gpa, cgpa_after_term, credits_attempted, credits_earned, credits_failed, credits_withdrawn, cumulative_attempted, cumulative_earned, academic_standing, honors_level, dean_list_eligible, risk_flags, snapshot_hash, generated_by, generated_at, is_final) FROM stdin;
\.


--
-- Data for Name: student_cohorts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.student_cohorts (id, program_id, track_id, cohort_code, cohort_name, intake_year, intake_semester, intake_term_id, expected_grad_term_id, expected_grad_year, total_semesters_planned, status, total_enrolled, total_graduated, total_delayed, total_withdrawn, avg_cgpa, notes, created_by, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: student_course_attempts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.student_course_attempts (id, student_id, course_id, term_id, attempt_number, numeric_grade, letter_grade, grade_points, credit_hours, result, is_improvement_attempt, counts_in_cgpa, registered_at, grade_posted_at, withdrawn_at, graded_by, notes, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: student_documents; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.student_documents (id, student_id, document_type, document_number, title, description, storage_key, file_name, file_size_bytes, mime_type, status, verification_status, verified_by, verified_at, rejection_reason, issue_date, expiry_date, upload_date, uploaded_by, revision_history, version, is_active, metadata) FROM stdin;
\.


--
-- Data for Name: student_elective_selections; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.student_elective_selections (id, student_id, pool_id, course_id, term_id, selected_at) FROM stdin;
\.


--
-- Data for Name: student_grade_aggregates; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.student_grade_aggregates (id, student_id, course_id, total_sessions, attended_sessions, attendance_rate, quiz_scores_json, quiz_avg, quiz_total, practical_scores_json, practical_score_total, weighted_score, last_computed_at) FROM stdin;
\.


--
-- Data for Name: student_grade_versions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.student_grade_versions (id, student_id, course_id, stage, version_number, attendance_rate, quiz_avg, practical_total, weighted_score, bonus_marks, coursework_marks, professor_notes, final_grade, submitted_by_ta, reviewed_by_prof, approved_by_admin, submitted_at, reviewed_at, approved_at, snapshot_json, created_at) FROM stdin;
\.


--
-- Data for Name: student_graduation_progress; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.student_graduation_progress (id, student_id, requirement_id, credits_completed, credits_remaining, courses_completed, courses_remaining, completion_pct, last_computed_at) FROM stdin;
\.


--
-- Data for Name: student_term_gpa; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.student_term_gpa (id, student_id, term_id, term_credit_hours_attempted, term_credit_hours_earned, term_quality_points, term_gpa, cumulative_hours_attempted, cumulative_hours_earned, cumulative_quality_points, cgpa, academic_standing, is_summer, finalized, finalized_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: students; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.students (id, user_id, student_number, department_id, major, year, gpa, enrollment_date, phone, address, emergency_contact, advisor_id, is_scholarship, created_at, updated_at, program_id, track_id, admission_term_id, expected_grad_term_id, academic_level, cgpa, total_credit_hours_attempted, total_credit_hours_earned, total_quality_points, academic_standing, is_eligible_for_graduation) FROM stdin;
\.


--
-- Data for Name: ta_grade_events; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ta_grade_events (id, ta_user_id, student_id, course_id, event_type, event_date, attendance_status, quiz_label, quiz_score, quiz_max, practical_label, practical_score, practical_max, notes, created_at) FROM stdin;
\.


--
-- Data for Name: teaching_assistants; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.teaching_assistants (id, user_id, professor_id, department_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: transcript_verifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.transcript_verifications (id, transcript_id, verification_code, verification_token, qr_identifier, is_valid, expires_at, verified_count, last_verified_at, invalidated_at, invalidated_reason, created_at) FROM stdin;
\.


--
-- Data for Name: transcript_versions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.transcript_versions (id, student_id, version_number, transcript_type, transcript_data, snapshot_hash, generated_by, generated_at, reason, is_current) FROM stdin;
\.


--
-- Data for Name: transfer_credits; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.transfer_credits (id, student_id, term_id, source_institution, source_institution_country, source_course_code, source_course_name, source_credit_hours, source_grade, source_grade_points, source_grade_scale, target_course_id, target_course_code, target_credit_hours, target_grade_points, counts_in_cgpa, counts_toward_degree, status, evaluation_notes, supporting_document_ids, evaluated_by, evaluated_at, approved_by, approved_at, rejection_reason, approval_history, submitted_by, submitted_at, applied_to_record_at) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, name, email, email_verified_at, hashed_password, role, is_active, avatar_url, remember_token, last_login, created_at, updated_at) FROM stdin;
2	System Administrator	sysadmin@eduguard.edu	\N	$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi	admin	t	\N	\N	\N	2026-06-24 04:24:16.517373+03	2026-06-24 04:24:16.517373+03
4	Prof. Emily Chen	e.chen@eduguard.edu	\N	$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi	professor	t	\N	\N	\N	2026-06-24 04:24:16.526891+03	2026-06-24 04:24:16.526891+03
5	Prof. Robert Davis	r.davis@eduguard.edu	\N	$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi	professor	t	\N	\N	\N	2026-06-24 04:24:16.526891+03	2026-06-24 04:24:16.526891+03
6	Prof. Lisa Thompson	l.thompson@eduguard.edu	\N	$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi	professor	t	\N	\N	\N	2026-06-24 04:24:16.526891+03	2026-06-24 04:24:16.526891+03
7	Prof. Michael Wong	m.wong@eduguard.edu	\N	$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi	professor	t	\N	\N	\N	2026-06-24 04:24:16.526891+03	2026-06-24 04:24:16.526891+03
8	Prof. Anna Martinez	a.martinez@eduguard.edu	\N	$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi	professor	t	\N	\N	\N	2026-06-24 04:24:16.526891+03	2026-06-24 04:24:16.526891+03
9	Prof. David Nguyen	d.nguyen@eduguard.edu	\N	$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi	professor	t	\N	\N	\N	2026-06-24 04:24:16.526891+03	2026-06-24 04:24:16.526891+03
10	Dr. Kevin Park	k.park@eduguard.edu	\N	$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi	advisor	t	\N	\N	\N	2026-06-24 04:24:16.527878+03	2026-06-24 04:24:16.527878+03
11	Dr. Rachel Green	r.green@eduguard.edu	\N	$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi	advisor	t	\N	\N	\N	2026-06-24 04:24:16.527878+03	2026-06-24 04:24:16.527878+03
13	Sofia Rodriguez	ta.sofia@eduguard.edu	\N	$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi	ta	t	\N	\N	\N	2026-06-24 04:24:16.528458+03	2026-06-24 04:24:16.528458+03
15	Bob Smith	bob@student.eduguard.edu	\N	$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi	student	t	\N	\N	\N	2026-06-24 04:24:16.529185+03	2026-06-24 04:24:16.529185+03
16	Carol White	carol@student.eduguard.edu	\N	$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi	student	t	\N	\N	\N	2026-06-24 04:24:16.529185+03	2026-06-24 04:24:16.529185+03
17	David Brown	david@student.eduguard.edu	\N	$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi	student	t	\N	\N	\N	2026-06-24 04:24:16.529185+03	2026-06-24 04:24:16.529185+03
18	Eva Martinez	eva@student.eduguard.edu	\N	$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi	student	t	\N	\N	\N	2026-06-24 04:24:16.529185+03	2026-06-24 04:24:16.529185+03
19	Frank Lee	frank@student.eduguard.edu	\N	$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi	student	t	\N	\N	\N	2026-06-24 04:24:16.529185+03	2026-06-24 04:24:16.529185+03
20	Grace Kim	grace@student.eduguard.edu	\N	$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi	student	t	\N	\N	\N	2026-06-24 04:24:16.529185+03	2026-06-24 04:24:16.529185+03
21	Henry Wilson	henry@student.eduguard.edu	\N	$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi	student	t	\N	\N	\N	2026-06-24 04:24:16.529185+03	2026-06-24 04:24:16.529185+03
22	Iris Patel	iris@student.eduguard.edu	\N	$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi	student	t	\N	\N	\N	2026-06-24 04:24:16.529185+03	2026-06-24 04:24:16.529185+03
23	Jake Turner	jake@student.eduguard.edu	\N	$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi	student	t	\N	\N	\N	2026-06-24 04:24:16.529185+03	2026-06-24 04:24:16.529185+03
24	Karen Liu	karen@student.eduguard.edu	\N	$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi	student	t	\N	\N	\N	2026-06-24 04:24:16.529185+03	2026-06-24 04:24:16.529185+03
25	Leo Santos	leo@student.eduguard.edu	\N	$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi	student	t	\N	\N	\N	2026-06-24 04:24:16.529185+03	2026-06-24 04:24:16.529185+03
26	Mia Chen	mia@student.eduguard.edu	\N	$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi	student	t	\N	\N	\N	2026-06-24 04:24:16.529185+03	2026-06-24 04:24:16.529185+03
27	Noah Adams	noah@student.eduguard.edu	\N	$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi	student	t	\N	\N	\N	2026-06-24 04:24:16.529185+03	2026-06-24 04:24:16.529185+03
28	Olivia Clark	olivia@student.eduguard.edu	\N	$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi	student	t	\N	\N	\N	2026-06-24 04:24:16.529185+03	2026-06-24 04:24:16.529185+03
29	Peter Wright	peter@student.eduguard.edu	\N	$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi	student	t	\N	\N	\N	2026-06-24 04:24:16.529185+03	2026-06-24 04:24:16.529185+03
30	Quinn Harris	quinn@student.eduguard.edu	\N	$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi	student	t	\N	\N	\N	2026-06-24 04:24:16.529185+03	2026-06-24 04:24:16.529185+03
31	Rachel Scott	rachel@student.eduguard.edu	\N	$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi	student	t	\N	\N	\N	2026-06-24 04:24:16.529185+03	2026-06-24 04:24:16.529185+03
32	Sam Baker	sam@student.eduguard.edu	\N	$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi	student	t	\N	\N	\N	2026-06-24 04:24:16.529185+03	2026-06-24 04:24:16.529185+03
33	Tara Nelson	tara@student.eduguard.edu	\N	$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi	student	t	\N	\N	\N	2026-06-24 04:24:16.529185+03	2026-06-24 04:24:16.529185+03
34	Uma Patel	uma@student.eduguard.edu	\N	$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi	student	t	\N	\N	\N	2026-06-24 04:24:16.529185+03	2026-06-24 04:24:16.529185+03
1	Dr. Sarah Mitchell	admin@eduguard.edu	\N	$2b$12$wjx2p3/7UEWmn8CBZbjggeNup8OYvxLKAl1DJ12Fao77VE8JX9FZe	admin	t	\N	\N	\N	2026-06-24 04:24:16.517373+03	2026-06-24 04:24:23.112601+03
3	Prof. James Anderson	j.anderson@eduguard.edu	\N	$2b$12$Y5Kr.EeJ65ZCLXqyGWdomutnTRKW8BB9pmCI0fkV8gBAKA9LNGcYC	professor	t	\N	\N	\N	2026-06-24 04:24:16.526891+03	2026-06-24 04:24:23.124413+03
12	Marcus Johnson	ta.marcus@eduguard.edu	\N	$2b$12$zJDzhRUHdS6kCNevedO9Eu27AUuo36XseizgZ3cgU7Bp.CTHkyAJG	ta	t	\N	\N	\N	2026-06-24 04:24:16.528458+03	2026-06-24 04:24:23.125138+03
14	Alice Johnson	alice@student.eduguard.edu	\N	$2b$12$liMRI6nZ1G9DM.PwhB.qYOwwVqrC8Ri4GtuxrsnVzEVPLQo0D40VW	student	t	\N	\N	\N	2026-06-24 04:24:16.529185+03	2026-06-24 04:24:23.126086+03
\.


--
-- Data for Name: validation_results; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.validation_results (id, batch_id, row_number, rule_code, field_name, raw_value, passed, severity, message, created_at) FROM stdin;
\.


--
-- Data for Name: validation_rules; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.validation_rules (id, rule_code, rule_name, description, category, import_type, severity, is_active, rule_config, created_at, updated_at) FROM stdin;
1	REQ_STUDENT_CODE	Student Code Required	student_code field must be present and non-empty	integrity	students	error	\N	\N	2026-06-24 04:24:33.386986+03	2026-06-24 04:24:33.386986+03
2	REQ_FULL_NAME	Full Name Required	full_name field must be present and non-empty	integrity	students	error	\N	\N	2026-06-24 04:24:33.386986+03	2026-06-24 04:24:33.386986+03
3	REQ_COURSE_CODE	Course Code Required	course_code field must be present and non-empty	integrity	transcripts	error	\N	\N	2026-06-24 04:24:33.386986+03	2026-06-24 04:24:33.386986+03
4	REQ_COURSE_NAME	Course Name Required	course_name required for curriculum import	integrity	curriculum	error	\N	\N	2026-06-24 04:24:33.386986+03	2026-06-24 04:24:33.386986+03
5	REF_STUDENT_EXISTS	Student Exists Check	Imported student_code must exist in the DB	referential	transcripts	error	\N	\N	2026-06-24 04:24:33.386986+03	2026-06-24 04:24:33.386986+03
6	REF_COURSE_EXISTS	Course Exists Check	Imported course_code must exist in the catalog	referential	transcripts	error	\N	\N	2026-06-24 04:24:33.386986+03	2026-06-24 04:24:33.386986+03
7	REF_TERM_EXISTS	Term Exists Check	Imported term_name must exist in academic_terms	referential	transcripts	warning	\N	\N	2026-06-24 04:24:33.386986+03	2026-06-24 04:24:33.386986+03
8	ACAD_INVALID_GRADE	Grade Validity Check	grade must be a recognised letter grade	academic	transcripts	error	\N	\N	2026-06-24 04:24:33.386986+03	2026-06-24 04:24:33.386986+03
9	ACAD_INVALID_CREDITS	Credit Hours Range Check	credit_hours must be numeric and 0â€“6	academic	\N	warning	\N	\N	2026-06-24 04:24:33.386986+03	2026-06-24 04:24:33.386986+03
10	ACAD_GPA_OUT_OF_RANGE	GPA Range Check	GPA values must be in range 0.0â€“4.0	academic	\N	warning	\N	\N	2026-06-24 04:24:33.386986+03	2026-06-24 04:24:33.386986+03
11	BIZ_INVALID_EMAIL	Email Format Check	university_email must contain @	business	students	warning	\N	\N	2026-06-24 04:24:33.386986+03	2026-06-24 04:24:33.386986+03
12	BIZ_INVALID_ENROLL_YEAR	Enrollment Year Range Check	enrollment_year must be 2000â€“2030	business	students	warning	\N	\N	2026-06-24 04:24:33.386986+03	2026-06-24 04:24:33.386986+03
13	INT_DUPLICATE_IN_BATCH	Intra-Batch Duplicate Check	Same student_code must not appear twice in file	integrity	students	error	\N	\N	2026-06-24 04:24:33.386986+03	2026-06-24 04:24:33.386986+03
14	INT_DUPLICATE_ATTEMPT	Duplicate Attempt in Batch	Same student+course+attempt key in one file	integrity	transcripts	error	\N	\N	2026-06-24 04:24:33.386986+03	2026-06-24 04:24:33.386986+03
15	CURR_INVALID_CATEGORY	Curriculum Category Check	category must be a valid curriculum category	curriculum	curriculum	warning	\N	\N	2026-06-24 04:24:33.386986+03	2026-06-24 04:24:33.386986+03
16	CURR_INVALID_YEAR	Curriculum Year Range Check	curriculum_year must be 2010â€“2030	curriculum	curriculum	warning	\N	\N	2026-06-24 04:24:33.386986+03	2026-06-24 04:24:33.386986+03
\.


--
-- Name: academic_achievements_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.academic_achievements_id_seq', 1, false);


--
-- Name: academic_audit_entries_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.academic_audit_entries_id_seq', 1, false);


--
-- Name: academic_calendar_periods_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.academic_calendar_periods_id_seq', 7, true);


--
-- Name: academic_case_decisions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.academic_case_decisions_id_seq', 1, false);


--
-- Name: academic_cases_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.academic_cases_id_seq', 1, false);


--
-- Name: academic_decision_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.academic_decision_log_id_seq', 1, false);


--
-- Name: academic_exemptions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.academic_exemptions_id_seq', 1, false);


--
-- Name: academic_override_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.academic_override_history_id_seq', 1, false);


--
-- Name: academic_overrides_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.academic_overrides_id_seq', 1, false);


--
-- Name: academic_programs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.academic_programs_id_seq', 4, true);


--
-- Name: academic_record_versions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.academic_record_versions_id_seq', 1, false);


--
-- Name: academic_risk_records_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.academic_risk_records_id_seq', 1, false);


--
-- Name: academic_rules_config_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.academic_rules_config_id_seq', 104, true);


--
-- Name: academic_status_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.academic_status_history_id_seq', 1, false);


--
-- Name: academic_terms_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.academic_terms_id_seq', 1, true);


--
-- Name: academic_timeline_events_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.academic_timeline_events_id_seq', 1, false);


--
-- Name: academic_tracks_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.academic_tracks_id_seq', 4, true);


--
-- Name: activity_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.activity_logs_id_seq', 36, true);


--
-- Name: advising_plan_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.advising_plan_items_id_seq', 1, false);


--
-- Name: advising_plans_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.advising_plans_id_seq', 1, false);


--
-- Name: advisors_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.advisors_id_seq', 4, true);


--
-- Name: announcements_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.announcements_id_seq', 9, true);


--
-- Name: assignment_submissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.assignment_submissions_id_seq', 1, false);


--
-- Name: assignments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.assignments_id_seq', 1, false);


--
-- Name: attendance_scan_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.attendance_scan_log_id_seq', 1, false);


--
-- Name: attendance_sessions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.attendance_sessions_id_seq', 1, false);


--
-- Name: attendances_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.attendances_id_seq', 392, true);


--
-- Name: audit_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.audit_logs_id_seq', 2004, true);


--
-- Name: cohort_memberships_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.cohort_memberships_id_seq', 1, false);


--
-- Name: course_eligibility_rules_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.course_eligibility_rules_id_seq', 6, true);


--
-- Name: course_grade_weights_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.course_grade_weights_id_seq', 15, true);


--
-- Name: course_offerings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.course_offerings_id_seq', 1, false);


--
-- Name: course_postrequisites_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.course_postrequisites_id_seq', 99, true);


--
-- Name: course_prerequisites_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.course_prerequisites_id_seq', 99, true);


--
-- Name: course_sections_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.course_sections_id_seq', 1, false);


--
-- Name: courses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.courses_id_seq', 96, true);


--
-- Name: degree_progress_snapshots_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.degree_progress_snapshots_id_seq', 1, false);


--
-- Name: departments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.departments_id_seq', 9, true);


--
-- Name: elective_pool_courses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.elective_pool_courses_id_seq', 1, false);


--
-- Name: elective_pools_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.elective_pools_id_seq', 1, false);


--
-- Name: enrollments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.enrollments_id_seq', 342, true);


--
-- Name: gpa_explanations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.gpa_explanations_id_seq', 1, false);


--
-- Name: gpa_projections_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.gpa_projections_id_seq', 1, false);


--
-- Name: gpa_versions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.gpa_versions_id_seq', 1, false);


--
-- Name: grade_records_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.grade_records_id_seq', 1, false);


--
-- Name: grade_scale_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.grade_scale_id_seq', 93, true);


--
-- Name: graduation_audit_results_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.graduation_audit_results_id_seq', 1, false);


--
-- Name: graduation_eligibility_records_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.graduation_eligibility_records_id_seq', 1, false);


--
-- Name: graduation_requirements_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.graduation_requirements_id_seq', 18, true);


--
-- Name: honors_records_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.honors_records_id_seq', 1, false);


--
-- Name: import_audit_events_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.import_audit_events_id_seq', 1, false);


--
-- Name: import_batches_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.import_batches_id_seq', 1, false);


--
-- Name: import_errors_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.import_errors_id_seq', 1, false);


--
-- Name: import_jobs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.import_jobs_id_seq', 1, false);


--
-- Name: import_row_errors_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.import_row_errors_id_seq', 1, false);


--
-- Name: intervention_actions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.intervention_actions_id_seq', 21, true);


--
-- Name: intervention_plans_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.intervention_plans_id_seq', 8, true);


--
-- Name: mapping_template_versions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.mapping_template_versions_id_seq', 1, false);


--
-- Name: mapping_templates_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.mapping_templates_id_seq', 1, false);


--
-- Name: notification_delivery_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.notification_delivery_log_id_seq', 1, false);


--
-- Name: notification_preferences_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.notification_preferences_id_seq', 1, false);


--
-- Name: notification_templates_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.notification_templates_id_seq', 1, false);


--
-- Name: notifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.notifications_id_seq', 14, true);


--
-- Name: pdf_transcript_jobs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pdf_transcript_jobs_id_seq', 1, false);


--
-- Name: personal_access_tokens_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.personal_access_tokens_id_seq', 1, false);


--
-- Name: prerequisite_exceptions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.prerequisite_exceptions_id_seq', 1, false);


--
-- Name: prerequisite_validation_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.prerequisite_validation_log_id_seq', 1, false);


--
-- Name: prerequisite_validations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.prerequisite_validations_id_seq', 1, false);


--
-- Name: professors_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.professors_id_seq', 23, true);


--
-- Name: questions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.questions_id_seq', 20, true);


--
-- Name: quiz_sessions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.quiz_sessions_id_seq', 1, false);


--
-- Name: quiz_submissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.quiz_submissions_id_seq', 55, true);


--
-- Name: quiz_violations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.quiz_violations_id_seq', 1, false);


--
-- Name: quizzes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.quizzes_id_seq', 8, true);


--
-- Name: rbac_permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.rbac_permissions_id_seq', 1, false);


--
-- Name: reconciliation_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.reconciliation_items_id_seq', 1, false);


--
-- Name: reconciliation_reports_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.reconciliation_reports_id_seq', 1, false);


--
-- Name: registrar_notes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.registrar_notes_id_seq', 1, false);


--
-- Name: registrar_task_assignments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.registrar_task_assignments_id_seq', 1, false);


--
-- Name: registrar_tasks_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.registrar_tasks_id_seq', 1, false);


--
-- Name: registration_events_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.registration_events_id_seq', 1, false);


--
-- Name: risk_assessments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.risk_assessments_id_seq', 127, true);


--
-- Name: scholarship_evaluations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.scholarship_evaluations_id_seq', 1, false);


--
-- Name: semester_snapshots_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.semester_snapshots_id_seq', 1, false);


--
-- Name: student_cohorts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.student_cohorts_id_seq', 1, false);


--
-- Name: student_course_attempts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.student_course_attempts_id_seq', 1, false);


--
-- Name: student_documents_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.student_documents_id_seq', 1, false);


--
-- Name: student_elective_selections_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.student_elective_selections_id_seq', 1, false);


--
-- Name: student_grade_aggregates_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.student_grade_aggregates_id_seq', 1, false);


--
-- Name: student_grade_versions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.student_grade_versions_id_seq', 1, false);


--
-- Name: student_graduation_progress_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.student_graduation_progress_id_seq', 1, false);


--
-- Name: student_term_gpa_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.student_term_gpa_id_seq', 1, false);


--
-- Name: students_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.students_id_seq', 122, true);


--
-- Name: ta_grade_events_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ta_grade_events_id_seq', 1, false);


--
-- Name: teaching_assistants_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.teaching_assistants_id_seq', 6, true);


--
-- Name: transcript_verifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.transcript_verifications_id_seq', 1, false);


--
-- Name: transcript_versions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.transcript_versions_id_seq', 1, false);


--
-- Name: transfer_credits_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.transfer_credits_id_seq', 1, false);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 34, true);


--
-- Name: validation_results_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.validation_results_id_seq', 1, false);


--
-- Name: validation_rules_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.validation_rules_id_seq', 16, true);


--
-- Name: academic_achievements academic_achievements_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_achievements
    ADD CONSTRAINT academic_achievements_pkey PRIMARY KEY (id);


--
-- Name: academic_audit_entries academic_audit_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_audit_entries
    ADD CONSTRAINT academic_audit_entries_pkey PRIMARY KEY (id);


--
-- Name: academic_calendar_periods academic_calendar_periods_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_calendar_periods
    ADD CONSTRAINT academic_calendar_periods_pkey PRIMARY KEY (id);


--
-- Name: academic_case_decisions academic_case_decisions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_case_decisions
    ADD CONSTRAINT academic_case_decisions_pkey PRIMARY KEY (id);


--
-- Name: academic_cases academic_cases_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_cases
    ADD CONSTRAINT academic_cases_pkey PRIMARY KEY (id);


--
-- Name: academic_decision_log academic_decision_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_decision_log
    ADD CONSTRAINT academic_decision_log_pkey PRIMARY KEY (id);


--
-- Name: academic_exemptions academic_exemptions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_exemptions
    ADD CONSTRAINT academic_exemptions_pkey PRIMARY KEY (id);


--
-- Name: academic_override_history academic_override_history_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_override_history
    ADD CONSTRAINT academic_override_history_pkey PRIMARY KEY (id);


--
-- Name: academic_overrides academic_overrides_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_overrides
    ADD CONSTRAINT academic_overrides_pkey PRIMARY KEY (id);


--
-- Name: academic_programs academic_programs_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_programs
    ADD CONSTRAINT academic_programs_code_key UNIQUE (code);


--
-- Name: academic_programs academic_programs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_programs
    ADD CONSTRAINT academic_programs_pkey PRIMARY KEY (id);


--
-- Name: academic_record_versions academic_record_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_record_versions
    ADD CONSTRAINT academic_record_versions_pkey PRIMARY KEY (id);


--
-- Name: academic_risk_records academic_risk_records_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_risk_records
    ADD CONSTRAINT academic_risk_records_pkey PRIMARY KEY (id);


--
-- Name: academic_rules_config academic_rules_config_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_rules_config
    ADD CONSTRAINT academic_rules_config_pkey PRIMARY KEY (id);


--
-- Name: academic_rules_config academic_rules_config_program_id_rule_key_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_rules_config
    ADD CONSTRAINT academic_rules_config_program_id_rule_key_key UNIQUE (program_id, rule_key);


--
-- Name: academic_status_history academic_status_history_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_status_history
    ADD CONSTRAINT academic_status_history_pkey PRIMARY KEY (id);


--
-- Name: academic_terms academic_terms_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_terms
    ADD CONSTRAINT academic_terms_code_key UNIQUE (code);


--
-- Name: academic_terms academic_terms_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_terms
    ADD CONSTRAINT academic_terms_pkey PRIMARY KEY (id);


--
-- Name: academic_timeline_events academic_timeline_events_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_timeline_events
    ADD CONSTRAINT academic_timeline_events_pkey PRIMARY KEY (id);


--
-- Name: academic_tracks academic_tracks_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_tracks
    ADD CONSTRAINT academic_tracks_code_key UNIQUE (code);


--
-- Name: academic_tracks academic_tracks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_tracks
    ADD CONSTRAINT academic_tracks_pkey PRIMARY KEY (id);


--
-- Name: activity_logs activity_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity_logs
    ADD CONSTRAINT activity_logs_pkey PRIMARY KEY (id);


--
-- Name: advising_plan_items advising_plan_items_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advising_plan_items
    ADD CONSTRAINT advising_plan_items_pkey PRIMARY KEY (id);


--
-- Name: advising_plans advising_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advising_plans
    ADD CONSTRAINT advising_plans_pkey PRIMARY KEY (id);


--
-- Name: advisors advisors_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advisors
    ADD CONSTRAINT advisors_pkey PRIMARY KEY (id);


--
-- Name: advisors advisors_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advisors
    ADD CONSTRAINT advisors_user_id_key UNIQUE (user_id);


--
-- Name: announcements announcements_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT announcements_pkey PRIMARY KEY (id);


--
-- Name: assignment_submissions assignment_submissions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assignment_submissions
    ADD CONSTRAINT assignment_submissions_pkey PRIMARY KEY (id);


--
-- Name: assignments assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT assignments_pkey PRIMARY KEY (id);


--
-- Name: attendance_scan_log attendance_scan_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance_scan_log
    ADD CONSTRAINT attendance_scan_log_pkey PRIMARY KEY (id);


--
-- Name: attendance_sessions attendance_sessions_current_qr_token_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance_sessions
    ADD CONSTRAINT attendance_sessions_current_qr_token_key UNIQUE (current_qr_token);


--
-- Name: attendance_sessions attendance_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance_sessions
    ADD CONSTRAINT attendance_sessions_pkey PRIMARY KEY (id);


--
-- Name: attendances attendances_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendances
    ADD CONSTRAINT attendances_pkey PRIMARY KEY (id);


--
-- Name: attendances attendances_student_id_course_id_date_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendances
    ADD CONSTRAINT attendances_student_id_course_id_date_key UNIQUE (student_id, course_id, date);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: cohort_memberships cohort_memberships_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cohort_memberships
    ADD CONSTRAINT cohort_memberships_pkey PRIMARY KEY (id);


--
-- Name: cohort_memberships cohort_memberships_student_id_cohort_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cohort_memberships
    ADD CONSTRAINT cohort_memberships_student_id_cohort_id_key UNIQUE (student_id, cohort_id);


--
-- Name: course_eligibility_rules course_eligibility_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_eligibility_rules
    ADD CONSTRAINT course_eligibility_rules_pkey PRIMARY KEY (id);


--
-- Name: course_grade_weights course_grade_weights_course_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_grade_weights
    ADD CONSTRAINT course_grade_weights_course_id_key UNIQUE (course_id);


--
-- Name: course_grade_weights course_grade_weights_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_grade_weights
    ADD CONSTRAINT course_grade_weights_pkey PRIMARY KEY (id);


--
-- Name: course_offerings course_offerings_course_id_term_id_section_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_offerings
    ADD CONSTRAINT course_offerings_course_id_term_id_section_key UNIQUE (course_id, term_id, section);


--
-- Name: course_offerings course_offerings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_offerings
    ADD CONSTRAINT course_offerings_pkey PRIMARY KEY (id);


--
-- Name: course_postrequisites course_postrequisites_course_id_postreq_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_postrequisites
    ADD CONSTRAINT course_postrequisites_course_id_postreq_id_key UNIQUE (course_id, postreq_id);


--
-- Name: course_postrequisites course_postrequisites_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_postrequisites
    ADD CONSTRAINT course_postrequisites_pkey PRIMARY KEY (id);


--
-- Name: course_prerequisites course_prerequisites_course_id_prerequisite_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_prerequisites
    ADD CONSTRAINT course_prerequisites_course_id_prerequisite_id_key UNIQUE (course_id, prerequisite_id);


--
-- Name: course_prerequisites course_prerequisites_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_prerequisites
    ADD CONSTRAINT course_prerequisites_pkey PRIMARY KEY (id);


--
-- Name: course_sections course_sections_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_sections
    ADD CONSTRAINT course_sections_pkey PRIMARY KEY (id);


--
-- Name: courses courses_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT courses_code_key UNIQUE (code);


--
-- Name: courses courses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT courses_pkey PRIMARY KEY (id);


--
-- Name: degree_progress_snapshots degree_progress_snapshots_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.degree_progress_snapshots
    ADD CONSTRAINT degree_progress_snapshots_pkey PRIMARY KEY (id);


--
-- Name: departments departments_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_code_key UNIQUE (code);


--
-- Name: departments departments_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_name_key UNIQUE (name);


--
-- Name: departments departments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_pkey PRIMARY KEY (id);


--
-- Name: elective_pool_courses elective_pool_courses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.elective_pool_courses
    ADD CONSTRAINT elective_pool_courses_pkey PRIMARY KEY (id);


--
-- Name: elective_pool_courses elective_pool_courses_pool_id_course_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.elective_pool_courses
    ADD CONSTRAINT elective_pool_courses_pool_id_course_id_key UNIQUE (pool_id, course_id);


--
-- Name: elective_pools elective_pools_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.elective_pools
    ADD CONSTRAINT elective_pools_pkey PRIMARY KEY (id);


--
-- Name: elective_pools elective_pools_program_id_pool_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.elective_pools
    ADD CONSTRAINT elective_pools_program_id_pool_code_key UNIQUE (program_id, pool_code);


--
-- Name: enrollments enrollments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.enrollments
    ADD CONSTRAINT enrollments_pkey PRIMARY KEY (id);


--
-- Name: enrollments enrollments_student_id_course_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.enrollments
    ADD CONSTRAINT enrollments_student_id_course_id_key UNIQUE (student_id, course_id);


--
-- Name: gpa_explanations gpa_explanations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gpa_explanations
    ADD CONSTRAINT gpa_explanations_pkey PRIMARY KEY (id);


--
-- Name: gpa_projections gpa_projections_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gpa_projections
    ADD CONSTRAINT gpa_projections_pkey PRIMARY KEY (id);


--
-- Name: gpa_versions gpa_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gpa_versions
    ADD CONSTRAINT gpa_versions_pkey PRIMARY KEY (id);


--
-- Name: grade_records grade_records_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grade_records
    ADD CONSTRAINT grade_records_pkey PRIMARY KEY (id);


--
-- Name: grade_scale grade_scale_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grade_scale
    ADD CONSTRAINT grade_scale_pkey PRIMARY KEY (id);


--
-- Name: grade_scale grade_scale_program_id_letter_grade_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grade_scale
    ADD CONSTRAINT grade_scale_program_id_letter_grade_key UNIQUE (program_id, letter_grade);


--
-- Name: graduation_audit_results graduation_audit_results_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.graduation_audit_results
    ADD CONSTRAINT graduation_audit_results_pkey PRIMARY KEY (id);


--
-- Name: graduation_eligibility_records graduation_eligibility_records_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.graduation_eligibility_records
    ADD CONSTRAINT graduation_eligibility_records_pkey PRIMARY KEY (id);


--
-- Name: graduation_requirements graduation_requirements_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.graduation_requirements
    ADD CONSTRAINT graduation_requirements_pkey PRIMARY KEY (id);


--
-- Name: honors_records honors_records_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.honors_records
    ADD CONSTRAINT honors_records_pkey PRIMARY KEY (id);


--
-- Name: import_audit_events import_audit_events_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.import_audit_events
    ADD CONSTRAINT import_audit_events_pkey PRIMARY KEY (id);


--
-- Name: import_batches import_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.import_batches
    ADD CONSTRAINT import_batches_pkey PRIMARY KEY (id);


--
-- Name: import_errors import_errors_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.import_errors
    ADD CONSTRAINT import_errors_pkey PRIMARY KEY (id);


--
-- Name: import_jobs import_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.import_jobs
    ADD CONSTRAINT import_jobs_pkey PRIMARY KEY (id);


--
-- Name: import_row_errors import_row_errors_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.import_row_errors
    ADD CONSTRAINT import_row_errors_pkey PRIMARY KEY (id);


--
-- Name: intervention_actions intervention_actions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.intervention_actions
    ADD CONSTRAINT intervention_actions_pkey PRIMARY KEY (id);


--
-- Name: intervention_plans intervention_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.intervention_plans
    ADD CONSTRAINT intervention_plans_pkey PRIMARY KEY (id);


--
-- Name: mapping_template_versions mapping_template_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mapping_template_versions
    ADD CONSTRAINT mapping_template_versions_pkey PRIMARY KEY (id);


--
-- Name: mapping_templates mapping_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mapping_templates
    ADD CONSTRAINT mapping_templates_pkey PRIMARY KEY (id);


--
-- Name: notification_delivery_log notification_delivery_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification_delivery_log
    ADD CONSTRAINT notification_delivery_log_pkey PRIMARY KEY (id);


--
-- Name: notification_preferences notification_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification_preferences
    ADD CONSTRAINT notification_preferences_pkey PRIMARY KEY (id);


--
-- Name: notification_preferences notification_preferences_user_id_event_type_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification_preferences
    ADD CONSTRAINT notification_preferences_user_id_event_type_key UNIQUE (user_id, event_type);


--
-- Name: notification_templates notification_templates_event_type_channel_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification_templates
    ADD CONSTRAINT notification_templates_event_type_channel_key UNIQUE (event_type, channel);


--
-- Name: notification_templates notification_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification_templates
    ADD CONSTRAINT notification_templates_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: pdf_transcript_jobs pdf_transcript_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pdf_transcript_jobs
    ADD CONSTRAINT pdf_transcript_jobs_pkey PRIMARY KEY (id);


--
-- Name: personal_access_tokens personal_access_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personal_access_tokens
    ADD CONSTRAINT personal_access_tokens_pkey PRIMARY KEY (id);


--
-- Name: personal_access_tokens personal_access_tokens_token_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personal_access_tokens
    ADD CONSTRAINT personal_access_tokens_token_key UNIQUE (token);


--
-- Name: prerequisite_exceptions prerequisite_exceptions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prerequisite_exceptions
    ADD CONSTRAINT prerequisite_exceptions_pkey PRIMARY KEY (id);


--
-- Name: prerequisite_validation_log prerequisite_validation_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prerequisite_validation_log
    ADD CONSTRAINT prerequisite_validation_log_pkey PRIMARY KEY (id);


--
-- Name: prerequisite_validations prerequisite_validations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prerequisite_validations
    ADD CONSTRAINT prerequisite_validations_pkey PRIMARY KEY (id);


--
-- Name: professors professors_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.professors
    ADD CONSTRAINT professors_pkey PRIMARY KEY (id);


--
-- Name: professors professors_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.professors
    ADD CONSTRAINT professors_user_id_key UNIQUE (user_id);


--
-- Name: questions questions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.questions
    ADD CONSTRAINT questions_pkey PRIMARY KEY (id);


--
-- Name: quiz_sessions quiz_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quiz_sessions
    ADD CONSTRAINT quiz_sessions_pkey PRIMARY KEY (id);


--
-- Name: quiz_sessions quiz_sessions_quiz_id_student_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quiz_sessions
    ADD CONSTRAINT quiz_sessions_quiz_id_student_id_key UNIQUE (quiz_id, student_id);


--
-- Name: quiz_submissions quiz_submissions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quiz_submissions
    ADD CONSTRAINT quiz_submissions_pkey PRIMARY KEY (id);


--
-- Name: quiz_submissions quiz_submissions_quiz_id_student_id_attempt_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quiz_submissions
    ADD CONSTRAINT quiz_submissions_quiz_id_student_id_attempt_number_key UNIQUE (quiz_id, student_id, attempt_number);


--
-- Name: quiz_violations quiz_violations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quiz_violations
    ADD CONSTRAINT quiz_violations_pkey PRIMARY KEY (id);


--
-- Name: quizzes quizzes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quizzes
    ADD CONSTRAINT quizzes_pkey PRIMARY KEY (id);


--
-- Name: rbac_permissions rbac_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rbac_permissions
    ADD CONSTRAINT rbac_permissions_pkey PRIMARY KEY (id);


--
-- Name: rbac_permissions rbac_permissions_role_resource_action_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rbac_permissions
    ADD CONSTRAINT rbac_permissions_role_resource_action_key UNIQUE (role, resource, action);


--
-- Name: reconciliation_items reconciliation_items_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reconciliation_items
    ADD CONSTRAINT reconciliation_items_pkey PRIMARY KEY (id);


--
-- Name: reconciliation_reports reconciliation_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reconciliation_reports
    ADD CONSTRAINT reconciliation_reports_pkey PRIMARY KEY (id);


--
-- Name: registrar_notes registrar_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.registrar_notes
    ADD CONSTRAINT registrar_notes_pkey PRIMARY KEY (id);


--
-- Name: registrar_task_assignments registrar_task_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.registrar_task_assignments
    ADD CONSTRAINT registrar_task_assignments_pkey PRIMARY KEY (id);


--
-- Name: registrar_tasks registrar_tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.registrar_tasks
    ADD CONSTRAINT registrar_tasks_pkey PRIMARY KEY (id);


--
-- Name: registration_events registration_events_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.registration_events
    ADD CONSTRAINT registration_events_pkey PRIMARY KEY (id);


--
-- Name: risk_assessments risk_assessments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.risk_assessments
    ADD CONSTRAINT risk_assessments_pkey PRIMARY KEY (id);


--
-- Name: scholarship_evaluations scholarship_evaluations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scholarship_evaluations
    ADD CONSTRAINT scholarship_evaluations_pkey PRIMARY KEY (id);


--
-- Name: semester_snapshots semester_snapshots_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.semester_snapshots
    ADD CONSTRAINT semester_snapshots_pkey PRIMARY KEY (id);


--
-- Name: student_cohorts student_cohorts_cohort_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_cohorts
    ADD CONSTRAINT student_cohorts_cohort_code_key UNIQUE (cohort_code);


--
-- Name: student_cohorts student_cohorts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_cohorts
    ADD CONSTRAINT student_cohorts_pkey PRIMARY KEY (id);


--
-- Name: student_cohorts student_cohorts_program_id_intake_year_intake_semester_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_cohorts
    ADD CONSTRAINT student_cohorts_program_id_intake_year_intake_semester_key UNIQUE (program_id, intake_year, intake_semester);


--
-- Name: student_course_attempts student_course_attempts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_course_attempts
    ADD CONSTRAINT student_course_attempts_pkey PRIMARY KEY (id);


--
-- Name: student_course_attempts student_course_attempts_student_id_course_id_attempt_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_course_attempts
    ADD CONSTRAINT student_course_attempts_student_id_course_id_attempt_number_key UNIQUE (student_id, course_id, attempt_number);


--
-- Name: student_documents student_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_documents
    ADD CONSTRAINT student_documents_pkey PRIMARY KEY (id);


--
-- Name: student_elective_selections student_elective_selections_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_elective_selections
    ADD CONSTRAINT student_elective_selections_pkey PRIMARY KEY (id);


--
-- Name: student_elective_selections student_elective_selections_student_id_pool_id_course_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_elective_selections
    ADD CONSTRAINT student_elective_selections_student_id_pool_id_course_id_key UNIQUE (student_id, pool_id, course_id);


--
-- Name: student_grade_aggregates student_grade_aggregates_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_grade_aggregates
    ADD CONSTRAINT student_grade_aggregates_pkey PRIMARY KEY (id);


--
-- Name: student_grade_versions student_grade_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_grade_versions
    ADD CONSTRAINT student_grade_versions_pkey PRIMARY KEY (id);


--
-- Name: student_graduation_progress student_graduation_progress_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_graduation_progress
    ADD CONSTRAINT student_graduation_progress_pkey PRIMARY KEY (id);


--
-- Name: student_graduation_progress student_graduation_progress_student_id_requirement_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_graduation_progress
    ADD CONSTRAINT student_graduation_progress_student_id_requirement_id_key UNIQUE (student_id, requirement_id);


--
-- Name: student_term_gpa student_term_gpa_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_term_gpa
    ADD CONSTRAINT student_term_gpa_pkey PRIMARY KEY (id);


--
-- Name: student_term_gpa student_term_gpa_student_id_term_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_term_gpa
    ADD CONSTRAINT student_term_gpa_student_id_term_id_key UNIQUE (student_id, term_id);


--
-- Name: students students_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_pkey PRIMARY KEY (id);


--
-- Name: students students_student_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_student_number_key UNIQUE (student_number);


--
-- Name: students students_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_user_id_key UNIQUE (user_id);


--
-- Name: ta_grade_events ta_grade_events_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ta_grade_events
    ADD CONSTRAINT ta_grade_events_pkey PRIMARY KEY (id);


--
-- Name: teaching_assistants teaching_assistants_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teaching_assistants
    ADD CONSTRAINT teaching_assistants_pkey PRIMARY KEY (id);


--
-- Name: teaching_assistants teaching_assistants_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teaching_assistants
    ADD CONSTRAINT teaching_assistants_user_id_key UNIQUE (user_id);


--
-- Name: transcript_verifications transcript_verifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transcript_verifications
    ADD CONSTRAINT transcript_verifications_pkey PRIMARY KEY (id);


--
-- Name: transcript_verifications transcript_verifications_qr_identifier_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transcript_verifications
    ADD CONSTRAINT transcript_verifications_qr_identifier_key UNIQUE (qr_identifier);


--
-- Name: transcript_verifications transcript_verifications_transcript_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transcript_verifications
    ADD CONSTRAINT transcript_verifications_transcript_id_key UNIQUE (transcript_id);


--
-- Name: transcript_verifications transcript_verifications_verification_token_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transcript_verifications
    ADD CONSTRAINT transcript_verifications_verification_token_key UNIQUE (verification_token);


--
-- Name: transcript_versions transcript_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transcript_versions
    ADD CONSTRAINT transcript_versions_pkey PRIMARY KEY (id);


--
-- Name: transfer_credits transfer_credits_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transfer_credits
    ADD CONSTRAINT transfer_credits_pkey PRIMARY KEY (id);


--
-- Name: student_grade_aggregates uq_aggregate; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_grade_aggregates
    ADD CONSTRAINT uq_aggregate UNIQUE (student_id, course_id);


--
-- Name: import_batches uq_import_batches_file_hash; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.import_batches
    ADD CONSTRAINT uq_import_batches_file_hash UNIQUE (file_hash);


--
-- Name: mapping_templates uq_mapping_templates_name_type; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mapping_templates
    ADD CONSTRAINT uq_mapping_templates_name_type UNIQUE (name, import_type);


--
-- Name: mapping_template_versions uq_mtv_template_version; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mapping_template_versions
    ADD CONSTRAINT uq_mtv_template_version UNIQUE (template_id, version_number);


--
-- Name: assignment_submissions uq_submission; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assignment_submissions
    ADD CONSTRAINT uq_submission UNIQUE (assignment_id, student_id);


--
-- Name: ta_grade_events uq_ta_event; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ta_grade_events
    ADD CONSTRAINT uq_ta_event UNIQUE (student_id, course_id, event_type, event_date, quiz_label, practical_label);


--
-- Name: validation_rules uq_validation_rules_code; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.validation_rules
    ADD CONSTRAINT uq_validation_rules_code UNIQUE (rule_code);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: validation_results validation_results_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.validation_results
    ADD CONSTRAINT validation_results_pkey PRIMARY KEY (id);


--
-- Name: validation_rules validation_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.validation_rules
    ADD CONSTRAINT validation_rules_pkey PRIMARY KEY (id);


--
-- Name: idx_achievement_category; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_achievement_category ON public.academic_achievements USING btree (student_id, category);


--
-- Name: idx_achievement_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_achievement_student ON public.academic_achievements USING btree (student_id);


--
-- Name: idx_activity_logs_action; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_activity_logs_action ON public.activity_logs USING btree (action);


--
-- Name: idx_activity_logs_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_activity_logs_student ON public.activity_logs USING btree (student_id);


--
-- Name: idx_activity_logs_timestamp; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_activity_logs_timestamp ON public.activity_logs USING btree ("timestamp");


--
-- Name: idx_advisors_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_advisors_user ON public.advisors USING btree (user_id);


--
-- Name: idx_announcements_course; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_announcements_course ON public.announcements USING btree (course_id);


--
-- Name: idx_announcements_created; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_announcements_created ON public.announcements USING btree (created_at DESC);


--
-- Name: idx_announcements_global; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_announcements_global ON public.announcements USING btree (is_global);


--
-- Name: idx_ap_advisor; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ap_advisor ON public.advising_plans USING btree (advisor_id);


--
-- Name: idx_ap_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ap_status ON public.advising_plans USING btree (status);


--
-- Name: idx_ap_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ap_student ON public.advising_plans USING btree (student_id);


--
-- Name: idx_ap_term; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ap_term ON public.advising_plans USING btree (term_id);


--
-- Name: idx_api_course; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_api_course ON public.advising_plan_items USING btree (course_id);


--
-- Name: idx_api_plan; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_api_plan ON public.advising_plan_items USING btree (plan_id);


--
-- Name: idx_arv_current; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_arv_current ON public.academic_record_versions USING btree (student_id, is_current);


--
-- Name: idx_arv_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_arv_student ON public.academic_record_versions USING btree (student_id);


--
-- Name: idx_attendance_course; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_attendance_course ON public.attendances USING btree (course_id);


--
-- Name: idx_attendance_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_attendance_date ON public.attendances USING btree (date);


--
-- Name: idx_attendance_student_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_attendance_student_date ON public.attendances USING btree (student_id, date);


--
-- Name: idx_audit_actor_ts; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_actor_ts ON public.academic_audit_entries USING btree (actor_id, occurred_at);


--
-- Name: idx_audit_logs_entity; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_logs_entity ON public.audit_logs USING btree (entity_type, entity_id);


--
-- Name: idx_audit_logs_timestamp; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_logs_timestamp ON public.audit_logs USING btree ("timestamp" DESC);


--
-- Name: idx_audit_logs_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_logs_user ON public.audit_logs USING btree (user_id);


--
-- Name: idx_audit_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_student ON public.academic_audit_entries USING btree (student_id);


--
-- Name: idx_case_decision; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_case_decision ON public.academic_case_decisions USING btree (case_id);


--
-- Name: idx_case_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_case_status ON public.academic_cases USING btree (status);


--
-- Name: idx_case_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_case_student ON public.academic_cases USING btree (student_id);


--
-- Name: idx_cer_course; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cer_course ON public.course_eligibility_rules USING btree (course_id);


--
-- Name: idx_cohort_member; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cohort_member ON public.cohort_memberships USING btree (cohort_id, student_id);


--
-- Name: idx_courses_category; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_courses_category ON public.courses USING btree (category);


--
-- Name: idx_courses_department; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_courses_department ON public.courses USING btree (department_id);


--
-- Name: idx_courses_plan_sem; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_courses_plan_sem ON public.courses USING btree (plan_semester);


--
-- Name: idx_courses_professor; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_courses_professor ON public.courses USING btree (professor_id);


--
-- Name: idx_courses_program; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_courses_program ON public.courses USING btree (program_id);


--
-- Name: idx_courses_semester; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_courses_semester ON public.courses USING btree (semester, year);


--
-- Name: idx_courses_track; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_courses_track ON public.courses USING btree (track_id);


--
-- Name: idx_doc_student_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_doc_student_type ON public.student_documents USING btree (student_id, document_type);


--
-- Name: idx_enrollments_course; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_enrollments_course ON public.enrollments USING btree (course_id);


--
-- Name: idx_enrollments_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_enrollments_status ON public.enrollments USING btree (status);


--
-- Name: idx_enrollments_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_enrollments_student ON public.enrollments USING btree (student_id);


--
-- Name: idx_exemption_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_exemption_student ON public.academic_exemptions USING btree (student_id);


--
-- Name: idx_gpa_expl_current; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_gpa_expl_current ON public.gpa_explanations USING btree (student_id, is_current);


--
-- Name: idx_gpa_expl_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_gpa_expl_student ON public.gpa_explanations USING btree (student_id);


--
-- Name: idx_gpa_version_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_gpa_version_student ON public.gpa_versions USING btree (student_id);


--
-- Name: idx_gpa_version_ts; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_gpa_version_ts ON public.gpa_versions USING btree (student_id, recorded_at DESC);


--
-- Name: idx_grad_elig_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_grad_elig_student ON public.graduation_eligibility_records USING btree (student_id);


--
-- Name: idx_grad_prog_req; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_grad_prog_req ON public.student_graduation_progress USING btree (requirement_id);


--
-- Name: idx_grad_prog_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_grad_prog_student ON public.student_graduation_progress USING btree (student_id);


--
-- Name: idx_grad_req_program; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_grad_req_program ON public.graduation_requirements USING btree (program_id);


--
-- Name: idx_grad_req_track; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_grad_req_track ON public.graduation_requirements USING btree (track_id);


--
-- Name: idx_grade_scale_prog; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_grade_scale_prog ON public.grade_scale USING btree (program_id);


--
-- Name: idx_grade_versions_stage; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_grade_versions_stage ON public.student_grade_versions USING btree (stage);


--
-- Name: idx_grade_versions_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_grade_versions_student ON public.student_grade_versions USING btree (student_id, course_id);


--
-- Name: idx_grades_course; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_grades_course ON public.grade_records USING btree (course_id);


--
-- Name: idx_grades_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_grades_student ON public.grade_records USING btree (student_id);


--
-- Name: idx_honors_student_term; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_honors_student_term ON public.honors_records USING btree (student_id, term_id);


--
-- Name: idx_ia_plan; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ia_plan ON public.intervention_actions USING btree (plan_id);


--
-- Name: idx_import_errors_job; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_import_errors_job ON public.import_errors USING btree (job_id);


--
-- Name: idx_import_jobs_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_import_jobs_status ON public.import_jobs USING btree (status);


--
-- Name: idx_interventions_advisor; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_interventions_advisor ON public.intervention_plans USING btree (advisor_id);


--
-- Name: idx_interventions_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_interventions_status ON public.intervention_plans USING btree (status);


--
-- Name: idx_interventions_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_interventions_student ON public.intervention_plans USING btree (student_id);


--
-- Name: idx_mv_dept_analytics; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_mv_dept_analytics ON public.mv_department_analytics USING btree (department);


--
-- Name: idx_mv_quiz_performance; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_mv_quiz_performance ON public.mv_quiz_performance USING btree (quiz_id);


--
-- Name: idx_note_search; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_note_search ON public.registrar_notes USING btree (student_id, note_type);


--
-- Name: idx_note_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_note_student ON public.registrar_notes USING btree (student_id);


--
-- Name: idx_notifications_created; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notifications_created ON public.notifications USING btree (created_at DESC);


--
-- Name: idx_notifications_unread; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notifications_unread ON public.notifications USING btree (user_id, read) WHERE (read = false);


--
-- Name: idx_notifications_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notifications_user ON public.notifications USING btree (user_id);


--
-- Name: idx_offering_course; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_offering_course ON public.course_offerings USING btree (course_id);


--
-- Name: idx_offering_prof; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_offering_prof ON public.course_offerings USING btree (professor_id);


--
-- Name: idx_offering_term; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_offering_term ON public.course_offerings USING btree (term_id);


--
-- Name: idx_pat_tokenable; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pat_tokenable ON public.personal_access_tokens USING btree (tokenable_type, tokenable_id);


--
-- Name: idx_pdf_job_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pdf_job_student ON public.pdf_transcript_jobs USING btree (student_id);


--
-- Name: idx_postreq_course; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_postreq_course ON public.course_postrequisites USING btree (course_id);


--
-- Name: idx_postreq_unlock; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_postreq_unlock ON public.course_postrequisites USING btree (postreq_id);


--
-- Name: idx_prereq_course; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_prereq_course ON public.course_prerequisites USING btree (course_id);


--
-- Name: idx_prereq_prereq; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_prereq_prereq ON public.course_prerequisites USING btree (prerequisite_id);


--
-- Name: idx_prereq_val_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_prereq_val_student ON public.prerequisite_validations USING btree (student_id);


--
-- Name: idx_professors_department; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_professors_department ON public.professors USING btree (department_id);


--
-- Name: idx_professors_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_professors_user ON public.professors USING btree (user_id);


--
-- Name: idx_prog_code; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_prog_code ON public.academic_programs USING btree (code);


--
-- Name: idx_prog_dept; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_prog_dept ON public.academic_programs USING btree (department_id);


--
-- Name: idx_progress_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_progress_student ON public.degree_progress_snapshots USING btree (student_id);


--
-- Name: idx_proj_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_proj_student ON public.gpa_projections USING btree (student_id);


--
-- Name: idx_questions_quiz; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_questions_quiz ON public.questions USING btree (quiz_id);


--
-- Name: idx_quiz_sessions_quiz; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_quiz_sessions_quiz ON public.quiz_sessions USING btree (quiz_id);


--
-- Name: idx_quiz_sessions_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_quiz_sessions_status ON public.quiz_sessions USING btree (status);


--
-- Name: idx_quiz_sessions_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_quiz_sessions_student ON public.quiz_sessions USING btree (student_id);


--
-- Name: idx_quiz_submissions_quiz; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_quiz_submissions_quiz ON public.quiz_submissions USING btree (quiz_id);


--
-- Name: idx_quiz_submissions_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_quiz_submissions_student ON public.quiz_submissions USING btree (student_id);


--
-- Name: idx_quiz_violations_quiz; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_quiz_violations_quiz ON public.quiz_violations USING btree (quiz_id);


--
-- Name: idx_quiz_violations_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_quiz_violations_student ON public.quiz_violations USING btree (student_id);


--
-- Name: idx_quiz_violations_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_quiz_violations_type ON public.quiz_violations USING btree (violation_type);


--
-- Name: idx_quizzes_course; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_quizzes_course ON public.quizzes USING btree (course_id);


--
-- Name: idx_quizzes_creator; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_quizzes_creator ON public.quizzes USING btree (created_by);


--
-- Name: idx_quizzes_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_quizzes_status ON public.quizzes USING btree (status);


--
-- Name: idx_reg_event_student_term; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reg_event_student_term ON public.registration_events USING btree (student_id, term_id);


--
-- Name: idx_reg_task_assignee; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reg_task_assignee ON public.registrar_tasks USING btree (assigned_to, status);


--
-- Name: idx_reg_task_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reg_task_student ON public.registrar_tasks USING btree (student_id);


--
-- Name: idx_risk_assessments_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_risk_assessments_date ON public.risk_assessments USING btree (assessed_at DESC);


--
-- Name: idx_risk_assessments_level; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_risk_assessments_level ON public.risk_assessments USING btree (risk_level);


--
-- Name: idx_risk_assessments_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_risk_assessments_student ON public.risk_assessments USING btree (student_id);


--
-- Name: idx_risk_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_risk_student ON public.academic_risk_records USING btree (student_id);


--
-- Name: idx_rta_task; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_rta_task ON public.registrar_task_assignments USING btree (task_id);


--
-- Name: idx_sca_course; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sca_course ON public.student_course_attempts USING btree (course_id);


--
-- Name: idx_sca_result; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sca_result ON public.student_course_attempts USING btree (result);


--
-- Name: idx_sca_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sca_student ON public.student_course_attempts USING btree (student_id);


--
-- Name: idx_sca_student_term; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sca_student_term ON public.student_course_attempts USING btree (student_id, term_id);


--
-- Name: idx_sca_term; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sca_term ON public.student_course_attempts USING btree (term_id);


--
-- Name: idx_scholarship_current; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_scholarship_current ON public.scholarship_evaluations USING btree (student_id, is_current);


--
-- Name: idx_scholarship_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_scholarship_student ON public.scholarship_evaluations USING btree (student_id);


--
-- Name: idx_sections_course; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sections_course ON public.course_sections USING btree (course_id);


--
-- Name: idx_sections_ta; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sections_ta ON public.course_sections USING btree (ta_id);


--
-- Name: idx_snapshot_student_term; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_snapshot_student_term ON public.semester_snapshots USING btree (student_id, term_id);


--
-- Name: idx_status_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_status_student ON public.academic_status_history USING btree (student_id);


--
-- Name: idx_students_cgpa; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_students_cgpa ON public.students USING btree (cgpa);


--
-- Name: idx_students_department; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_students_department ON public.students USING btree (department_id);


--
-- Name: idx_students_gpa; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_students_gpa ON public.students USING btree (gpa);


--
-- Name: idx_students_major; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_students_major ON public.students USING btree (major);


--
-- Name: idx_students_program; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_students_program ON public.students USING btree (program_id);


--
-- Name: idx_students_standing; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_students_standing ON public.students USING btree (academic_standing);


--
-- Name: idx_students_track; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_students_track ON public.students USING btree (track_id);


--
-- Name: idx_students_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_students_user_id ON public.students USING btree (user_id);


--
-- Name: idx_students_year; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_students_year ON public.students USING btree (year);


--
-- Name: idx_ta_events_created; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ta_events_created ON public.ta_grade_events USING btree (created_at);


--
-- Name: idx_ta_events_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ta_events_student ON public.ta_grade_events USING btree (student_id, course_id);


--
-- Name: idx_ta_professor; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ta_professor ON public.teaching_assistants USING btree (professor_id);


--
-- Name: idx_ta_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ta_user ON public.teaching_assistants USING btree (user_id);


--
-- Name: idx_term_gpa_cgpa; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_term_gpa_cgpa ON public.student_term_gpa USING btree (cgpa);


--
-- Name: idx_term_gpa_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_term_gpa_student ON public.student_term_gpa USING btree (student_id);


--
-- Name: idx_term_gpa_term; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_term_gpa_term ON public.student_term_gpa USING btree (term_id);


--
-- Name: idx_terms_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_terms_active ON public.academic_terms USING btree (is_active) WHERE (is_active = true);


--
-- Name: idx_terms_year; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_terms_year ON public.academic_terms USING btree (academic_year, term_type);


--
-- Name: idx_timeline_student_ts; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_timeline_student_ts ON public.academic_timeline_events USING btree (student_id, occurred_at);


--
-- Name: idx_track_program; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_track_program ON public.academic_tracks USING btree (program_id);


--
-- Name: idx_transcript_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_transcript_student ON public.transcript_versions USING btree (student_id);


--
-- Name: idx_transfer_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_transfer_student ON public.transfer_credits USING btree (student_id);


--
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_email ON public.users USING btree (email);


--
-- Name: idx_users_role; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_role ON public.users USING btree (role);


--
-- Name: idx_verif_code; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_verif_code ON public.transcript_verifications USING btree (verification_code);


--
-- Name: ix_academic_achievements_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_academic_achievements_id ON public.academic_achievements USING btree (id);


--
-- Name: ix_academic_audit_entries_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_academic_audit_entries_id ON public.academic_audit_entries USING btree (id);


--
-- Name: ix_academic_calendar_periods_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_academic_calendar_periods_id ON public.academic_calendar_periods USING btree (id);


--
-- Name: ix_academic_case_decisions_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_academic_case_decisions_id ON public.academic_case_decisions USING btree (id);


--
-- Name: ix_academic_cases_case_number; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_academic_cases_case_number ON public.academic_cases USING btree (case_number);


--
-- Name: ix_academic_cases_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_academic_cases_id ON public.academic_cases USING btree (id);


--
-- Name: ix_academic_decision_log_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_academic_decision_log_id ON public.academic_decision_log USING btree (id);


--
-- Name: ix_academic_exemptions_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_academic_exemptions_id ON public.academic_exemptions USING btree (id);


--
-- Name: ix_academic_override_history_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_academic_override_history_id ON public.academic_override_history USING btree (id);


--
-- Name: ix_academic_overrides_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_academic_overrides_id ON public.academic_overrides USING btree (id);


--
-- Name: ix_academic_record_versions_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_academic_record_versions_id ON public.academic_record_versions USING btree (id);


--
-- Name: ix_academic_risk_records_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_academic_risk_records_id ON public.academic_risk_records USING btree (id);


--
-- Name: ix_academic_rules_config_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_academic_rules_config_id ON public.academic_rules_config USING btree (id);


--
-- Name: ix_academic_status_history_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_academic_status_history_id ON public.academic_status_history USING btree (id);


--
-- Name: ix_academic_timeline_events_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_academic_timeline_events_id ON public.academic_timeline_events USING btree (id);


--
-- Name: ix_assignment_submissions_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_assignment_submissions_id ON public.assignment_submissions USING btree (id);


--
-- Name: ix_assignments_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_assignments_id ON public.assignments USING btree (id);


--
-- Name: ix_attendance_scan_log_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_attendance_scan_log_id ON public.attendance_scan_log USING btree (id);


--
-- Name: ix_attendance_sessions_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_attendance_sessions_id ON public.attendance_sessions USING btree (id);


--
-- Name: ix_cohort_memberships_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_cohort_memberships_id ON public.cohort_memberships USING btree (id);


--
-- Name: ix_course_grade_weights_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_course_grade_weights_id ON public.course_grade_weights USING btree (id);


--
-- Name: ix_degree_progress_snapshots_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_degree_progress_snapshots_id ON public.degree_progress_snapshots USING btree (id);


--
-- Name: ix_elective_pool_courses_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_elective_pool_courses_id ON public.elective_pool_courses USING btree (id);


--
-- Name: ix_elective_pools_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_elective_pools_id ON public.elective_pools USING btree (id);


--
-- Name: ix_gpa_explanations_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_gpa_explanations_id ON public.gpa_explanations USING btree (id);


--
-- Name: ix_gpa_projections_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_gpa_projections_id ON public.gpa_projections USING btree (id);


--
-- Name: ix_gpa_versions_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_gpa_versions_id ON public.gpa_versions USING btree (id);


--
-- Name: ix_graduation_audit_results_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_graduation_audit_results_id ON public.graduation_audit_results USING btree (id);


--
-- Name: ix_graduation_eligibility_records_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_graduation_eligibility_records_id ON public.graduation_eligibility_records USING btree (id);


--
-- Name: ix_honors_records_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_honors_records_id ON public.honors_records USING btree (id);


--
-- Name: ix_import_audit_batch_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_import_audit_batch_id ON public.import_audit_events USING btree (batch_id);


--
-- Name: ix_import_audit_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_import_audit_created_at ON public.import_audit_events USING btree (created_at);


--
-- Name: ix_import_audit_event_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_import_audit_event_type ON public.import_audit_events USING btree (event_type);


--
-- Name: ix_import_audit_events_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_import_audit_events_id ON public.import_audit_events USING btree (id);


--
-- Name: ix_import_batches_batch_ref; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_import_batches_batch_ref ON public.import_batches USING btree (batch_ref);


--
-- Name: ix_import_batches_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_import_batches_created_at ON public.import_batches USING btree (created_at);


--
-- Name: ix_import_batches_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_import_batches_id ON public.import_batches USING btree (id);


--
-- Name: ix_import_batches_import_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_import_batches_import_type ON public.import_batches USING btree (import_type);


--
-- Name: ix_import_batches_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_import_batches_status ON public.import_batches USING btree (status);


--
-- Name: ix_import_row_errors_batch_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_import_row_errors_batch_id ON public.import_row_errors USING btree (batch_id);


--
-- Name: ix_import_row_errors_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_import_row_errors_id ON public.import_row_errors USING btree (id);


--
-- Name: ix_import_row_errors_severity; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_import_row_errors_severity ON public.import_row_errors USING btree (severity);


--
-- Name: ix_mapping_template_versions_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_mapping_template_versions_id ON public.mapping_template_versions USING btree (id);


--
-- Name: ix_mapping_templates_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_mapping_templates_id ON public.mapping_templates USING btree (id);


--
-- Name: ix_mtv_is_current; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_mtv_is_current ON public.mapping_template_versions USING btree (template_id, is_current);


--
-- Name: ix_mtv_template_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_mtv_template_id ON public.mapping_template_versions USING btree (template_id);


--
-- Name: ix_notification_delivery_log_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_notification_delivery_log_id ON public.notification_delivery_log USING btree (id);


--
-- Name: ix_notification_preferences_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_notification_preferences_id ON public.notification_preferences USING btree (id);


--
-- Name: ix_notification_templates_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_notification_templates_id ON public.notification_templates USING btree (id);


--
-- Name: ix_pdf_transcript_jobs_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_pdf_transcript_jobs_id ON public.pdf_transcript_jobs USING btree (id);


--
-- Name: ix_prereq_exceptions_student_course; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_prereq_exceptions_student_course ON public.prerequisite_exceptions USING btree (student_id, course_id);


--
-- Name: ix_prerequisite_exceptions_course_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_prerequisite_exceptions_course_id ON public.prerequisite_exceptions USING btree (course_id);


--
-- Name: ix_prerequisite_exceptions_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_prerequisite_exceptions_id ON public.prerequisite_exceptions USING btree (id);


--
-- Name: ix_prerequisite_exceptions_student_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_prerequisite_exceptions_student_id ON public.prerequisite_exceptions USING btree (student_id);


--
-- Name: ix_prerequisite_validation_log_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_prerequisite_validation_log_id ON public.prerequisite_validation_log USING btree (id);


--
-- Name: ix_prerequisite_validations_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_prerequisite_validations_id ON public.prerequisite_validations USING btree (id);


--
-- Name: ix_rbac_permissions_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_rbac_permissions_id ON public.rbac_permissions USING btree (id);


--
-- Name: ix_recon_items_report_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_recon_items_report_id ON public.reconciliation_items USING btree (report_id);


--
-- Name: ix_recon_items_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_recon_items_status ON public.reconciliation_items USING btree (status);


--
-- Name: ix_recon_reports_batch_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_recon_reports_batch_id ON public.reconciliation_reports USING btree (batch_id);


--
-- Name: ix_recon_reports_import_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_recon_reports_import_type ON public.reconciliation_reports USING btree (import_type);


--
-- Name: ix_reconciliation_items_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_reconciliation_items_id ON public.reconciliation_items USING btree (id);


--
-- Name: ix_reconciliation_reports_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_reconciliation_reports_id ON public.reconciliation_reports USING btree (id);


--
-- Name: ix_registrar_notes_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_registrar_notes_id ON public.registrar_notes USING btree (id);


--
-- Name: ix_registrar_task_assignments_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_registrar_task_assignments_id ON public.registrar_task_assignments USING btree (id);


--
-- Name: ix_registrar_tasks_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_registrar_tasks_id ON public.registrar_tasks USING btree (id);


--
-- Name: ix_registrar_tasks_task_number; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_registrar_tasks_task_number ON public.registrar_tasks USING btree (task_number);


--
-- Name: ix_registration_events_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_registration_events_id ON public.registration_events USING btree (id);


--
-- Name: ix_scholarship_evaluations_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_scholarship_evaluations_id ON public.scholarship_evaluations USING btree (id);


--
-- Name: ix_semester_snapshots_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_semester_snapshots_id ON public.semester_snapshots USING btree (id);


--
-- Name: ix_student_cohorts_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_student_cohorts_id ON public.student_cohorts USING btree (id);


--
-- Name: ix_student_documents_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_student_documents_id ON public.student_documents USING btree (id);


--
-- Name: ix_student_elective_selections_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_student_elective_selections_id ON public.student_elective_selections USING btree (id);


--
-- Name: ix_student_grade_aggregates_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_student_grade_aggregates_id ON public.student_grade_aggregates USING btree (id);


--
-- Name: ix_student_grade_versions_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_student_grade_versions_id ON public.student_grade_versions USING btree (id);


--
-- Name: ix_ta_grade_events_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ta_grade_events_id ON public.ta_grade_events USING btree (id);


--
-- Name: ix_transcript_verifications_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_transcript_verifications_id ON public.transcript_verifications USING btree (id);


--
-- Name: ix_transcript_verifications_verification_code; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_transcript_verifications_verification_code ON public.transcript_verifications USING btree (verification_code);


--
-- Name: ix_transcript_versions_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_transcript_versions_id ON public.transcript_versions USING btree (id);


--
-- Name: ix_transfer_credits_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_transfer_credits_id ON public.transfer_credits USING btree (id);


--
-- Name: ix_validation_results_batch_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_validation_results_batch_id ON public.validation_results USING btree (batch_id);


--
-- Name: ix_validation_results_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_validation_results_id ON public.validation_results USING btree (id);


--
-- Name: ix_validation_results_passed; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_validation_results_passed ON public.validation_results USING btree (passed);


--
-- Name: ix_validation_rules_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_validation_rules_id ON public.validation_rules USING btree (id);


--
-- Name: academic_programs set_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.academic_programs FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();


--
-- Name: academic_terms set_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.academic_terms FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();


--
-- Name: academic_tracks set_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.academic_tracks FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();


--
-- Name: advising_plans set_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.advising_plans FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();


--
-- Name: advisors set_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.advisors FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();


--
-- Name: announcements set_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.announcements FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();


--
-- Name: attendances set_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.attendances FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();


--
-- Name: course_offerings set_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.course_offerings FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();


--
-- Name: course_sections set_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.course_sections FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();


--
-- Name: courses set_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.courses FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();


--
-- Name: departments set_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.departments FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();


--
-- Name: enrollments set_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.enrollments FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();


--
-- Name: graduation_requirements set_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.graduation_requirements FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();


--
-- Name: import_jobs set_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.import_jobs FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();


--
-- Name: intervention_actions set_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.intervention_actions FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();


--
-- Name: intervention_plans set_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.intervention_plans FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();


--
-- Name: professors set_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.professors FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();


--
-- Name: quizzes set_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.quizzes FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();


--
-- Name: student_course_attempts set_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.student_course_attempts FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();


--
-- Name: student_graduation_progress set_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.student_graduation_progress FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();


--
-- Name: student_term_gpa set_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.student_term_gpa FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();


--
-- Name: students set_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.students FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();


--
-- Name: teaching_assistants set_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.teaching_assistants FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();


--
-- Name: users set_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();


--
-- Name: advising_plans trg_audit; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_audit AFTER INSERT OR DELETE OR UPDATE ON public.advising_plans FOR EACH ROW EXECUTE FUNCTION public.audit_user_changes();


--
-- Name: courses trg_audit; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_audit AFTER INSERT OR DELETE OR UPDATE ON public.courses FOR EACH ROW EXECUTE FUNCTION public.audit_user_changes();


--
-- Name: enrollments trg_audit; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_audit AFTER INSERT OR DELETE OR UPDATE ON public.enrollments FOR EACH ROW EXECUTE FUNCTION public.audit_user_changes();


--
-- Name: intervention_plans trg_audit; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_audit AFTER INSERT OR DELETE OR UPDATE ON public.intervention_plans FOR EACH ROW EXECUTE FUNCTION public.audit_user_changes();


--
-- Name: risk_assessments trg_audit; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_audit AFTER INSERT OR DELETE OR UPDATE ON public.risk_assessments FOR EACH ROW EXECUTE FUNCTION public.audit_user_changes();


--
-- Name: student_course_attempts trg_audit; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_audit AFTER INSERT OR DELETE OR UPDATE ON public.student_course_attempts FOR EACH ROW EXECUTE FUNCTION public.audit_user_changes();


--
-- Name: student_term_gpa trg_audit; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_audit AFTER INSERT OR DELETE OR UPDATE ON public.student_term_gpa FOR EACH ROW EXECUTE FUNCTION public.audit_user_changes();


--
-- Name: students trg_audit; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_audit AFTER INSERT OR DELETE OR UPDATE ON public.students FOR EACH ROW EXECUTE FUNCTION public.audit_user_changes();


--
-- Name: users trg_audit; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_audit AFTER INSERT OR DELETE OR UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.audit_user_changes();


--
-- Name: enrollments trg_update_gpa; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_update_gpa AFTER INSERT OR DELETE OR UPDATE OF grade ON public.enrollments FOR EACH ROW EXECUTE FUNCTION public.update_student_gpa();


--
-- Name: academic_achievements academic_achievements_awarded_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_achievements
    ADD CONSTRAINT academic_achievements_awarded_by_fkey FOREIGN KEY (awarded_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: academic_achievements academic_achievements_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_achievements
    ADD CONSTRAINT academic_achievements_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: academic_achievements academic_achievements_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_achievements
    ADD CONSTRAINT academic_achievements_term_id_fkey FOREIGN KEY (term_id) REFERENCES public.academic_terms(id) ON DELETE SET NULL;


--
-- Name: academic_audit_entries academic_audit_entries_actor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_audit_entries
    ADD CONSTRAINT academic_audit_entries_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: academic_audit_entries academic_audit_entries_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_audit_entries
    ADD CONSTRAINT academic_audit_entries_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: academic_audit_entries academic_audit_entries_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_audit_entries
    ADD CONSTRAINT academic_audit_entries_term_id_fkey FOREIGN KEY (term_id) REFERENCES public.academic_terms(id) ON DELETE SET NULL;


--
-- Name: academic_calendar_periods academic_calendar_periods_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_calendar_periods
    ADD CONSTRAINT academic_calendar_periods_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: academic_calendar_periods academic_calendar_periods_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_calendar_periods
    ADD CONSTRAINT academic_calendar_periods_term_id_fkey FOREIGN KEY (term_id) REFERENCES public.academic_terms(id) ON DELETE CASCADE;


--
-- Name: academic_case_decisions academic_case_decisions_case_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_case_decisions
    ADD CONSTRAINT academic_case_decisions_case_id_fkey FOREIGN KEY (case_id) REFERENCES public.academic_cases(id) ON DELETE CASCADE;


--
-- Name: academic_case_decisions academic_case_decisions_decided_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_case_decisions
    ADD CONSTRAINT academic_case_decisions_decided_by_fkey FOREIGN KEY (decided_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: academic_cases academic_cases_assigned_to_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_cases
    ADD CONSTRAINT academic_cases_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: academic_cases academic_cases_attempt_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_cases
    ADD CONSTRAINT academic_cases_attempt_id_fkey FOREIGN KEY (attempt_id) REFERENCES public.student_course_attempts(id) ON DELETE SET NULL;


--
-- Name: academic_cases academic_cases_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_cases
    ADD CONSTRAINT academic_cases_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id) ON DELETE SET NULL;


--
-- Name: academic_cases academic_cases_resolved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_cases
    ADD CONSTRAINT academic_cases_resolved_by_fkey FOREIGN KEY (resolved_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: academic_cases academic_cases_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_cases
    ADD CONSTRAINT academic_cases_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: academic_cases academic_cases_submitted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_cases
    ADD CONSTRAINT academic_cases_submitted_by_fkey FOREIGN KEY (submitted_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: academic_cases academic_cases_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_cases
    ADD CONSTRAINT academic_cases_term_id_fkey FOREIGN KEY (term_id) REFERENCES public.academic_terms(id) ON DELETE SET NULL;


--
-- Name: academic_decision_log academic_decision_log_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_decision_log
    ADD CONSTRAINT academic_decision_log_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id) ON DELETE SET NULL;


--
-- Name: academic_decision_log academic_decision_log_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_decision_log
    ADD CONSTRAINT academic_decision_log_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: academic_decision_log academic_decision_log_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_decision_log
    ADD CONSTRAINT academic_decision_log_term_id_fkey FOREIGN KEY (term_id) REFERENCES public.academic_terms(id) ON DELETE SET NULL;


--
-- Name: academic_exemptions academic_exemptions_approved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_exemptions
    ADD CONSTRAINT academic_exemptions_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: academic_exemptions academic_exemptions_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_exemptions
    ADD CONSTRAINT academic_exemptions_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id) ON DELETE SET NULL;


--
-- Name: academic_exemptions academic_exemptions_requested_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_exemptions
    ADD CONSTRAINT academic_exemptions_requested_by_fkey FOREIGN KEY (requested_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: academic_exemptions academic_exemptions_reviewed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_exemptions
    ADD CONSTRAINT academic_exemptions_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: academic_exemptions academic_exemptions_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_exemptions
    ADD CONSTRAINT academic_exemptions_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: academic_override_history academic_override_history_override_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_override_history
    ADD CONSTRAINT academic_override_history_override_id_fkey FOREIGN KEY (override_id) REFERENCES public.academic_overrides(id) ON DELETE CASCADE;


--
-- Name: academic_override_history academic_override_history_performed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_override_history
    ADD CONSTRAINT academic_override_history_performed_by_fkey FOREIGN KEY (performed_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: academic_overrides academic_overrides_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_overrides
    ADD CONSTRAINT academic_overrides_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id) ON DELETE SET NULL;


--
-- Name: academic_overrides academic_overrides_requested_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_overrides
    ADD CONSTRAINT academic_overrides_requested_by_fkey FOREIGN KEY (requested_by) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: academic_overrides academic_overrides_reviewed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_overrides
    ADD CONSTRAINT academic_overrides_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: academic_overrides academic_overrides_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_overrides
    ADD CONSTRAINT academic_overrides_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: academic_overrides academic_overrides_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_overrides
    ADD CONSTRAINT academic_overrides_term_id_fkey FOREIGN KEY (term_id) REFERENCES public.academic_terms(id) ON DELETE SET NULL;


--
-- Name: academic_programs academic_programs_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_programs
    ADD CONSTRAINT academic_programs_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id) ON DELETE SET NULL;


--
-- Name: academic_record_versions academic_record_versions_authored_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_record_versions
    ADD CONSTRAINT academic_record_versions_authored_by_fkey FOREIGN KEY (authored_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: academic_record_versions academic_record_versions_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_record_versions
    ADD CONSTRAINT academic_record_versions_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: academic_risk_records academic_risk_records_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_risk_records
    ADD CONSTRAINT academic_risk_records_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: academic_risk_records academic_risk_records_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_risk_records
    ADD CONSTRAINT academic_risk_records_term_id_fkey FOREIGN KEY (term_id) REFERENCES public.academic_terms(id) ON DELETE SET NULL;


--
-- Name: academic_rules_config academic_rules_config_program_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_rules_config
    ADD CONSTRAINT academic_rules_config_program_id_fkey FOREIGN KEY (program_id) REFERENCES public.academic_programs(id) ON DELETE CASCADE;


--
-- Name: academic_rules_config academic_rules_config_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_rules_config
    ADD CONSTRAINT academic_rules_config_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: academic_status_history academic_status_history_actor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_status_history
    ADD CONSTRAINT academic_status_history_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: academic_status_history academic_status_history_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_status_history
    ADD CONSTRAINT academic_status_history_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: academic_status_history academic_status_history_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_status_history
    ADD CONSTRAINT academic_status_history_term_id_fkey FOREIGN KEY (term_id) REFERENCES public.academic_terms(id) ON DELETE SET NULL;


--
-- Name: academic_timeline_events academic_timeline_events_actor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_timeline_events
    ADD CONSTRAINT academic_timeline_events_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: academic_timeline_events academic_timeline_events_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_timeline_events
    ADD CONSTRAINT academic_timeline_events_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: academic_timeline_events academic_timeline_events_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_timeline_events
    ADD CONSTRAINT academic_timeline_events_term_id_fkey FOREIGN KEY (term_id) REFERENCES public.academic_terms(id) ON DELETE SET NULL;


--
-- Name: academic_tracks academic_tracks_program_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_tracks
    ADD CONSTRAINT academic_tracks_program_id_fkey FOREIGN KEY (program_id) REFERENCES public.academic_programs(id) ON DELETE CASCADE;


--
-- Name: activity_logs activity_logs_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity_logs
    ADD CONSTRAINT activity_logs_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: advising_plan_items advising_plan_items_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advising_plan_items
    ADD CONSTRAINT advising_plan_items_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id) ON DELETE CASCADE;


--
-- Name: advising_plan_items advising_plan_items_offering_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advising_plan_items
    ADD CONSTRAINT advising_plan_items_offering_id_fkey FOREIGN KEY (offering_id) REFERENCES public.course_offerings(id) ON DELETE SET NULL;


--
-- Name: advising_plan_items advising_plan_items_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advising_plan_items
    ADD CONSTRAINT advising_plan_items_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES public.advising_plans(id) ON DELETE CASCADE;


--
-- Name: advising_plans advising_plans_advisor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advising_plans
    ADD CONSTRAINT advising_plans_advisor_id_fkey FOREIGN KEY (advisor_id) REFERENCES public.advisors(id) ON DELETE SET NULL;


--
-- Name: advising_plans advising_plans_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advising_plans
    ADD CONSTRAINT advising_plans_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: advising_plans advising_plans_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advising_plans
    ADD CONSTRAINT advising_plans_term_id_fkey FOREIGN KEY (term_id) REFERENCES public.academic_terms(id) ON DELETE RESTRICT;


--
-- Name: advisors advisors_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advisors
    ADD CONSTRAINT advisors_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id) ON DELETE SET NULL;


--
-- Name: advisors advisors_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advisors
    ADD CONSTRAINT advisors_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: announcements announcements_author_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT announcements_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: announcements announcements_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT announcements_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id) ON DELETE CASCADE;


--
-- Name: announcements announcements_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT announcements_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id) ON DELETE CASCADE;


--
-- Name: assignment_submissions assignment_submissions_assignment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assignment_submissions
    ADD CONSTRAINT assignment_submissions_assignment_id_fkey FOREIGN KEY (assignment_id) REFERENCES public.assignments(id) ON DELETE CASCADE;


--
-- Name: assignment_submissions assignment_submissions_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assignment_submissions
    ADD CONSTRAINT assignment_submissions_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: assignments assignments_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT assignments_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: assignments assignments_uploaded_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT assignments_uploaded_by_fkey FOREIGN KEY (uploaded_by) REFERENCES public.users(id);


--
-- Name: attendance_scan_log attendance_scan_log_attendance_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance_scan_log
    ADD CONSTRAINT attendance_scan_log_attendance_id_fkey FOREIGN KEY (attendance_id) REFERENCES public.attendances(id);


--
-- Name: attendance_scan_log attendance_scan_log_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance_scan_log
    ADD CONSTRAINT attendance_scan_log_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.attendance_sessions(id);


--
-- Name: attendance_scan_log attendance_scan_log_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance_scan_log
    ADD CONSTRAINT attendance_scan_log_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id);


--
-- Name: attendance_sessions attendance_sessions_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance_sessions
    ADD CONSTRAINT attendance_sessions_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: attendance_sessions attendance_sessions_professor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance_sessions
    ADD CONSTRAINT attendance_sessions_professor_id_fkey FOREIGN KEY (professor_id) REFERENCES public.professors(id);


--
-- Name: attendances attendances_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendances
    ADD CONSTRAINT attendances_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id) ON DELETE CASCADE;


--
-- Name: attendances attendances_recorded_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendances
    ADD CONSTRAINT attendances_recorded_by_fkey FOREIGN KEY (recorded_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: attendances attendances_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendances
    ADD CONSTRAINT attendances_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: audit_logs audit_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: cohort_memberships cohort_memberships_cohort_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cohort_memberships
    ADD CONSTRAINT cohort_memberships_cohort_id_fkey FOREIGN KEY (cohort_id) REFERENCES public.student_cohorts(id) ON DELETE CASCADE;


--
-- Name: cohort_memberships cohort_memberships_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cohort_memberships
    ADD CONSTRAINT cohort_memberships_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: course_eligibility_rules course_eligibility_rules_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_eligibility_rules
    ADD CONSTRAINT course_eligibility_rules_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id) ON DELETE CASCADE;


--
-- Name: course_grade_weights course_grade_weights_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_grade_weights
    ADD CONSTRAINT course_grade_weights_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: course_grade_weights course_grade_weights_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_grade_weights
    ADD CONSTRAINT course_grade_weights_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- Name: course_offerings course_offerings_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_offerings
    ADD CONSTRAINT course_offerings_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id) ON DELETE CASCADE;


--
-- Name: course_offerings course_offerings_professor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_offerings
    ADD CONSTRAINT course_offerings_professor_id_fkey FOREIGN KEY (professor_id) REFERENCES public.professors(id) ON DELETE SET NULL;


--
-- Name: course_offerings course_offerings_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_offerings
    ADD CONSTRAINT course_offerings_term_id_fkey FOREIGN KEY (term_id) REFERENCES public.academic_terms(id) ON DELETE CASCADE;


--
-- Name: course_postrequisites course_postrequisites_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_postrequisites
    ADD CONSTRAINT course_postrequisites_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id) ON DELETE CASCADE;


--
-- Name: course_postrequisites course_postrequisites_postreq_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_postrequisites
    ADD CONSTRAINT course_postrequisites_postreq_id_fkey FOREIGN KEY (postreq_id) REFERENCES public.courses(id) ON DELETE CASCADE;


--
-- Name: course_prerequisites course_prerequisites_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_prerequisites
    ADD CONSTRAINT course_prerequisites_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id) ON DELETE CASCADE;


--
-- Name: course_prerequisites course_prerequisites_prerequisite_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_prerequisites
    ADD CONSTRAINT course_prerequisites_prerequisite_id_fkey FOREIGN KEY (prerequisite_id) REFERENCES public.courses(id) ON DELETE CASCADE;


--
-- Name: course_sections course_sections_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_sections
    ADD CONSTRAINT course_sections_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id) ON DELETE CASCADE;


--
-- Name: course_sections course_sections_ta_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_sections
    ADD CONSTRAINT course_sections_ta_id_fkey FOREIGN KEY (ta_id) REFERENCES public.teaching_assistants(id) ON DELETE SET NULL;


--
-- Name: courses courses_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT courses_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id) ON DELETE SET NULL;


--
-- Name: courses courses_professor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT courses_professor_id_fkey FOREIGN KEY (professor_id) REFERENCES public.professors(id) ON DELETE SET NULL;


--
-- Name: courses courses_program_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT courses_program_id_fkey FOREIGN KEY (program_id) REFERENCES public.academic_programs(id) ON DELETE SET NULL;


--
-- Name: courses courses_track_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT courses_track_id_fkey FOREIGN KEY (track_id) REFERENCES public.academic_tracks(id) ON DELETE SET NULL;


--
-- Name: degree_progress_snapshots degree_progress_snapshots_computed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.degree_progress_snapshots
    ADD CONSTRAINT degree_progress_snapshots_computed_by_fkey FOREIGN KEY (computed_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: degree_progress_snapshots degree_progress_snapshots_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.degree_progress_snapshots
    ADD CONSTRAINT degree_progress_snapshots_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: degree_progress_snapshots degree_progress_snapshots_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.degree_progress_snapshots
    ADD CONSTRAINT degree_progress_snapshots_term_id_fkey FOREIGN KEY (term_id) REFERENCES public.academic_terms(id) ON DELETE SET NULL;


--
-- Name: elective_pool_courses elective_pool_courses_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.elective_pool_courses
    ADD CONSTRAINT elective_pool_courses_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id) ON DELETE CASCADE;


--
-- Name: elective_pool_courses elective_pool_courses_pool_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.elective_pool_courses
    ADD CONSTRAINT elective_pool_courses_pool_id_fkey FOREIGN KEY (pool_id) REFERENCES public.elective_pools(id) ON DELETE CASCADE;


--
-- Name: elective_pools elective_pools_program_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.elective_pools
    ADD CONSTRAINT elective_pools_program_id_fkey FOREIGN KEY (program_id) REFERENCES public.academic_programs(id) ON DELETE CASCADE;


--
-- Name: elective_pools elective_pools_track_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.elective_pools
    ADD CONSTRAINT elective_pools_track_id_fkey FOREIGN KEY (track_id) REFERENCES public.academic_tracks(id) ON DELETE CASCADE;


--
-- Name: enrollments enrollments_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.enrollments
    ADD CONSTRAINT enrollments_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id) ON DELETE CASCADE;


--
-- Name: enrollments enrollments_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.enrollments
    ADD CONSTRAINT enrollments_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: departments fk_dept_head; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT fk_dept_head FOREIGN KEY (head_professor_id) REFERENCES public.professors(id) ON DELETE SET NULL;


--
-- Name: students fk_student_advisor; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT fk_student_advisor FOREIGN KEY (advisor_id) REFERENCES public.advisors(id) ON DELETE SET NULL;


--
-- Name: gpa_explanations gpa_explanations_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gpa_explanations
    ADD CONSTRAINT gpa_explanations_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: gpa_explanations gpa_explanations_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gpa_explanations
    ADD CONSTRAINT gpa_explanations_term_id_fkey FOREIGN KEY (term_id) REFERENCES public.academic_terms(id) ON DELETE SET NULL;


--
-- Name: gpa_projections gpa_projections_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gpa_projections
    ADD CONSTRAINT gpa_projections_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: gpa_projections gpa_projections_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gpa_projections
    ADD CONSTRAINT gpa_projections_term_id_fkey FOREIGN KEY (term_id) REFERENCES public.academic_terms(id) ON DELETE SET NULL;


--
-- Name: gpa_versions gpa_versions_computed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gpa_versions
    ADD CONSTRAINT gpa_versions_computed_by_fkey FOREIGN KEY (computed_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: gpa_versions gpa_versions_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gpa_versions
    ADD CONSTRAINT gpa_versions_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: gpa_versions gpa_versions_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gpa_versions
    ADD CONSTRAINT gpa_versions_term_id_fkey FOREIGN KEY (term_id) REFERENCES public.academic_terms(id) ON DELETE SET NULL;


--
-- Name: grade_records grade_records_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grade_records
    ADD CONSTRAINT grade_records_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id) ON DELETE CASCADE;


--
-- Name: grade_records grade_records_graded_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grade_records
    ADD CONSTRAINT grade_records_graded_by_fkey FOREIGN KEY (graded_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: grade_records grade_records_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grade_records
    ADD CONSTRAINT grade_records_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: grade_scale grade_scale_program_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grade_scale
    ADD CONSTRAINT grade_scale_program_id_fkey FOREIGN KEY (program_id) REFERENCES public.academic_programs(id) ON DELETE CASCADE;


--
-- Name: graduation_audit_results graduation_audit_results_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.graduation_audit_results
    ADD CONSTRAINT graduation_audit_results_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: graduation_eligibility_records graduation_eligibility_records_evaluated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.graduation_eligibility_records
    ADD CONSTRAINT graduation_eligibility_records_evaluated_by_fkey FOREIGN KEY (evaluated_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: graduation_eligibility_records graduation_eligibility_records_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.graduation_eligibility_records
    ADD CONSTRAINT graduation_eligibility_records_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: graduation_eligibility_records graduation_eligibility_records_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.graduation_eligibility_records
    ADD CONSTRAINT graduation_eligibility_records_term_id_fkey FOREIGN KEY (term_id) REFERENCES public.academic_terms(id) ON DELETE SET NULL;


--
-- Name: graduation_requirements graduation_requirements_program_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.graduation_requirements
    ADD CONSTRAINT graduation_requirements_program_id_fkey FOREIGN KEY (program_id) REFERENCES public.academic_programs(id) ON DELETE CASCADE;


--
-- Name: graduation_requirements graduation_requirements_track_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.graduation_requirements
    ADD CONSTRAINT graduation_requirements_track_id_fkey FOREIGN KEY (track_id) REFERENCES public.academic_tracks(id) ON DELETE CASCADE;


--
-- Name: honors_records honors_records_awarded_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.honors_records
    ADD CONSTRAINT honors_records_awarded_by_fkey FOREIGN KEY (awarded_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: honors_records honors_records_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.honors_records
    ADD CONSTRAINT honors_records_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: honors_records honors_records_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.honors_records
    ADD CONSTRAINT honors_records_term_id_fkey FOREIGN KEY (term_id) REFERENCES public.academic_terms(id) ON DELETE SET NULL;


--
-- Name: import_audit_events import_audit_events_actor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.import_audit_events
    ADD CONSTRAINT import_audit_events_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: import_audit_events import_audit_events_batch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.import_audit_events
    ADD CONSTRAINT import_audit_events_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES public.import_batches(id) ON DELETE CASCADE;


--
-- Name: import_batches import_batches_assigned_to_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.import_batches
    ADD CONSTRAINT import_batches_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: import_batches import_batches_imported_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.import_batches
    ADD CONSTRAINT import_batches_imported_by_fkey FOREIGN KEY (imported_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: import_batches import_batches_mapping_version_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.import_batches
    ADD CONSTRAINT import_batches_mapping_version_id_fkey FOREIGN KEY (mapping_version_id) REFERENCES public.mapping_template_versions(id) ON DELETE SET NULL;


--
-- Name: import_errors import_errors_job_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.import_errors
    ADD CONSTRAINT import_errors_job_id_fkey FOREIGN KEY (job_id) REFERENCES public.import_jobs(id) ON DELETE CASCADE;


--
-- Name: import_jobs import_jobs_initiated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.import_jobs
    ADD CONSTRAINT import_jobs_initiated_by_fkey FOREIGN KEY (initiated_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: import_row_errors import_row_errors_batch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.import_row_errors
    ADD CONSTRAINT import_row_errors_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES public.import_batches(id) ON DELETE CASCADE;


--
-- Name: intervention_actions intervention_actions_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.intervention_actions
    ADD CONSTRAINT intervention_actions_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES public.intervention_plans(id) ON DELETE CASCADE;


--
-- Name: intervention_plans intervention_plans_advisor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.intervention_plans
    ADD CONSTRAINT intervention_plans_advisor_id_fkey FOREIGN KEY (advisor_id) REFERENCES public.advisors(id) ON DELETE SET NULL;


--
-- Name: intervention_plans intervention_plans_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.intervention_plans
    ADD CONSTRAINT intervention_plans_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: mapping_template_versions mapping_template_versions_published_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mapping_template_versions
    ADD CONSTRAINT mapping_template_versions_published_by_fkey FOREIGN KEY (published_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: mapping_template_versions mapping_template_versions_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mapping_template_versions
    ADD CONSTRAINT mapping_template_versions_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.mapping_templates(id) ON DELETE CASCADE;


--
-- Name: mapping_templates mapping_templates_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mapping_templates
    ADD CONSTRAINT mapping_templates_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: notification_delivery_log notification_delivery_log_notification_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification_delivery_log
    ADD CONSTRAINT notification_delivery_log_notification_id_fkey FOREIGN KEY (notification_id) REFERENCES public.notifications(id) ON DELETE CASCADE;


--
-- Name: notification_preferences notification_preferences_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification_preferences
    ADD CONSTRAINT notification_preferences_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: notifications notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: pdf_transcript_jobs pdf_transcript_jobs_requested_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pdf_transcript_jobs
    ADD CONSTRAINT pdf_transcript_jobs_requested_by_fkey FOREIGN KEY (requested_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: pdf_transcript_jobs pdf_transcript_jobs_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pdf_transcript_jobs
    ADD CONSTRAINT pdf_transcript_jobs_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: pdf_transcript_jobs pdf_transcript_jobs_transcript_version_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pdf_transcript_jobs
    ADD CONSTRAINT pdf_transcript_jobs_transcript_version_id_fkey FOREIGN KEY (transcript_version_id) REFERENCES public.transcript_versions(id) ON DELETE SET NULL;


--
-- Name: prerequisite_exceptions prerequisite_exceptions_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prerequisite_exceptions
    ADD CONSTRAINT prerequisite_exceptions_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id) ON DELETE CASCADE;


--
-- Name: prerequisite_exceptions prerequisite_exceptions_granted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prerequisite_exceptions
    ADD CONSTRAINT prerequisite_exceptions_granted_by_fkey FOREIGN KEY (granted_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: prerequisite_exceptions prerequisite_exceptions_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prerequisite_exceptions
    ADD CONSTRAINT prerequisite_exceptions_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: prerequisite_exceptions prerequisite_exceptions_waived_prereq_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prerequisite_exceptions
    ADD CONSTRAINT prerequisite_exceptions_waived_prereq_id_fkey FOREIGN KEY (waived_prereq_id) REFERENCES public.courses(id) ON DELETE CASCADE;


--
-- Name: prerequisite_validation_log prerequisite_validation_log_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prerequisite_validation_log
    ADD CONSTRAINT prerequisite_validation_log_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id) ON DELETE CASCADE;


--
-- Name: prerequisite_validation_log prerequisite_validation_log_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prerequisite_validation_log
    ADD CONSTRAINT prerequisite_validation_log_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: prerequisite_validation_log prerequisite_validation_log_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prerequisite_validation_log
    ADD CONSTRAINT prerequisite_validation_log_term_id_fkey FOREIGN KEY (term_id) REFERENCES public.academic_terms(id) ON DELETE SET NULL;


--
-- Name: prerequisite_validations prerequisite_validations_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prerequisite_validations
    ADD CONSTRAINT prerequisite_validations_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id) ON DELETE CASCADE;


--
-- Name: prerequisite_validations prerequisite_validations_override_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prerequisite_validations
    ADD CONSTRAINT prerequisite_validations_override_by_fkey FOREIGN KEY (override_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: prerequisite_validations prerequisite_validations_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prerequisite_validations
    ADD CONSTRAINT prerequisite_validations_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: prerequisite_validations prerequisite_validations_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prerequisite_validations
    ADD CONSTRAINT prerequisite_validations_term_id_fkey FOREIGN KEY (term_id) REFERENCES public.academic_terms(id) ON DELETE SET NULL;


--
-- Name: professors professors_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.professors
    ADD CONSTRAINT professors_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id) ON DELETE SET NULL;


--
-- Name: professors professors_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.professors
    ADD CONSTRAINT professors_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: questions questions_quiz_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.questions
    ADD CONSTRAINT questions_quiz_id_fkey FOREIGN KEY (quiz_id) REFERENCES public.quizzes(id) ON DELETE CASCADE;


--
-- Name: quiz_sessions quiz_sessions_quiz_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quiz_sessions
    ADD CONSTRAINT quiz_sessions_quiz_id_fkey FOREIGN KEY (quiz_id) REFERENCES public.quizzes(id) ON DELETE CASCADE;


--
-- Name: quiz_sessions quiz_sessions_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quiz_sessions
    ADD CONSTRAINT quiz_sessions_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: quiz_submissions quiz_submissions_graded_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quiz_submissions
    ADD CONSTRAINT quiz_submissions_graded_by_fkey FOREIGN KEY (graded_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: quiz_submissions quiz_submissions_quiz_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quiz_submissions
    ADD CONSTRAINT quiz_submissions_quiz_id_fkey FOREIGN KEY (quiz_id) REFERENCES public.quizzes(id) ON DELETE CASCADE;


--
-- Name: quiz_submissions quiz_submissions_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quiz_submissions
    ADD CONSTRAINT quiz_submissions_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: quiz_violations quiz_violations_quiz_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quiz_violations
    ADD CONSTRAINT quiz_violations_quiz_id_fkey FOREIGN KEY (quiz_id) REFERENCES public.quizzes(id) ON DELETE CASCADE;


--
-- Name: quiz_violations quiz_violations_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quiz_violations
    ADD CONSTRAINT quiz_violations_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: quiz_violations quiz_violations_submission_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quiz_violations
    ADD CONSTRAINT quiz_violations_submission_id_fkey FOREIGN KEY (submission_id) REFERENCES public.quiz_submissions(id) ON DELETE SET NULL;


--
-- Name: quizzes quizzes_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quizzes
    ADD CONSTRAINT quizzes_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id) ON DELETE CASCADE;


--
-- Name: quizzes quizzes_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quizzes
    ADD CONSTRAINT quizzes_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: reconciliation_items reconciliation_items_report_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reconciliation_items
    ADD CONSTRAINT reconciliation_items_report_id_fkey FOREIGN KEY (report_id) REFERENCES public.reconciliation_reports(id) ON DELETE CASCADE;


--
-- Name: reconciliation_items reconciliation_items_resolved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reconciliation_items
    ADD CONSTRAINT reconciliation_items_resolved_by_fkey FOREIGN KEY (resolved_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: reconciliation_reports reconciliation_reports_batch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reconciliation_reports
    ADD CONSTRAINT reconciliation_reports_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES public.import_batches(id) ON DELETE CASCADE;


--
-- Name: registrar_notes registrar_notes_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.registrar_notes
    ADD CONSTRAINT registrar_notes_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: registrar_notes registrar_notes_previous_version_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.registrar_notes
    ADD CONSTRAINT registrar_notes_previous_version_id_fkey FOREIGN KEY (previous_version_id) REFERENCES public.registrar_notes(id) ON DELETE SET NULL;


--
-- Name: registrar_notes registrar_notes_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.registrar_notes
    ADD CONSTRAINT registrar_notes_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: registrar_notes registrar_notes_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.registrar_notes
    ADD CONSTRAINT registrar_notes_term_id_fkey FOREIGN KEY (term_id) REFERENCES public.academic_terms(id) ON DELETE SET NULL;


--
-- Name: registrar_notes registrar_notes_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.registrar_notes
    ADD CONSTRAINT registrar_notes_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: registrar_task_assignments registrar_task_assignments_assigned_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.registrar_task_assignments
    ADD CONSTRAINT registrar_task_assignments_assigned_by_fkey FOREIGN KEY (assigned_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: registrar_task_assignments registrar_task_assignments_assigned_to_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.registrar_task_assignments
    ADD CONSTRAINT registrar_task_assignments_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: registrar_task_assignments registrar_task_assignments_task_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.registrar_task_assignments
    ADD CONSTRAINT registrar_task_assignments_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.registrar_tasks(id) ON DELETE CASCADE;


--
-- Name: registrar_tasks registrar_tasks_assigned_to_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.registrar_tasks
    ADD CONSTRAINT registrar_tasks_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: registrar_tasks registrar_tasks_case_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.registrar_tasks
    ADD CONSTRAINT registrar_tasks_case_id_fkey FOREIGN KEY (case_id) REFERENCES public.academic_cases(id) ON DELETE SET NULL;


--
-- Name: registrar_tasks registrar_tasks_completed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.registrar_tasks
    ADD CONSTRAINT registrar_tasks_completed_by_fkey FOREIGN KEY (completed_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: registrar_tasks registrar_tasks_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.registrar_tasks
    ADD CONSTRAINT registrar_tasks_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: registrar_tasks registrar_tasks_exemption_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.registrar_tasks
    ADD CONSTRAINT registrar_tasks_exemption_id_fkey FOREIGN KEY (exemption_id) REFERENCES public.academic_exemptions(id) ON DELETE SET NULL;


--
-- Name: registrar_tasks registrar_tasks_pdf_job_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.registrar_tasks
    ADD CONSTRAINT registrar_tasks_pdf_job_id_fkey FOREIGN KEY (pdf_job_id) REFERENCES public.pdf_transcript_jobs(id) ON DELETE SET NULL;


--
-- Name: registrar_tasks registrar_tasks_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.registrar_tasks
    ADD CONSTRAINT registrar_tasks_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE SET NULL;


--
-- Name: registrar_tasks registrar_tasks_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.registrar_tasks
    ADD CONSTRAINT registrar_tasks_term_id_fkey FOREIGN KEY (term_id) REFERENCES public.academic_terms(id) ON DELETE SET NULL;


--
-- Name: registrar_tasks registrar_tasks_transfer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.registrar_tasks
    ADD CONSTRAINT registrar_tasks_transfer_id_fkey FOREIGN KEY (transfer_id) REFERENCES public.transfer_credits(id) ON DELETE SET NULL;


--
-- Name: registration_events registration_events_actor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.registration_events
    ADD CONSTRAINT registration_events_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: registration_events registration_events_approved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.registration_events
    ADD CONSTRAINT registration_events_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: registration_events registration_events_attempt_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.registration_events
    ADD CONSTRAINT registration_events_attempt_id_fkey FOREIGN KEY (attempt_id) REFERENCES public.student_course_attempts(id) ON DELETE SET NULL;


--
-- Name: registration_events registration_events_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.registration_events
    ADD CONSTRAINT registration_events_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id) ON DELETE SET NULL;


--
-- Name: registration_events registration_events_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.registration_events
    ADD CONSTRAINT registration_events_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: registration_events registration_events_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.registration_events
    ADD CONSTRAINT registration_events_term_id_fkey FOREIGN KEY (term_id) REFERENCES public.academic_terms(id) ON DELETE RESTRICT;


--
-- Name: risk_assessments risk_assessments_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.risk_assessments
    ADD CONSTRAINT risk_assessments_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: scholarship_evaluations scholarship_evaluations_evaluated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scholarship_evaluations
    ADD CONSTRAINT scholarship_evaluations_evaluated_by_fkey FOREIGN KEY (evaluated_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: scholarship_evaluations scholarship_evaluations_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scholarship_evaluations
    ADD CONSTRAINT scholarship_evaluations_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: scholarship_evaluations scholarship_evaluations_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scholarship_evaluations
    ADD CONSTRAINT scholarship_evaluations_term_id_fkey FOREIGN KEY (term_id) REFERENCES public.academic_terms(id) ON DELETE SET NULL;


--
-- Name: semester_snapshots semester_snapshots_generated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.semester_snapshots
    ADD CONSTRAINT semester_snapshots_generated_by_fkey FOREIGN KEY (generated_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: semester_snapshots semester_snapshots_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.semester_snapshots
    ADD CONSTRAINT semester_snapshots_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: semester_snapshots semester_snapshots_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.semester_snapshots
    ADD CONSTRAINT semester_snapshots_term_id_fkey FOREIGN KEY (term_id) REFERENCES public.academic_terms(id) ON DELETE RESTRICT;


--
-- Name: student_cohorts student_cohorts_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_cohorts
    ADD CONSTRAINT student_cohorts_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: student_cohorts student_cohorts_expected_grad_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_cohorts
    ADD CONSTRAINT student_cohorts_expected_grad_term_id_fkey FOREIGN KEY (expected_grad_term_id) REFERENCES public.academic_terms(id) ON DELETE SET NULL;


--
-- Name: student_cohorts student_cohorts_intake_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_cohorts
    ADD CONSTRAINT student_cohorts_intake_term_id_fkey FOREIGN KEY (intake_term_id) REFERENCES public.academic_terms(id) ON DELETE SET NULL;


--
-- Name: student_cohorts student_cohorts_program_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_cohorts
    ADD CONSTRAINT student_cohorts_program_id_fkey FOREIGN KEY (program_id) REFERENCES public.academic_programs(id) ON DELETE SET NULL;


--
-- Name: student_cohorts student_cohorts_track_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_cohorts
    ADD CONSTRAINT student_cohorts_track_id_fkey FOREIGN KEY (track_id) REFERENCES public.academic_tracks(id) ON DELETE SET NULL;


--
-- Name: student_course_attempts student_course_attempts_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_course_attempts
    ADD CONSTRAINT student_course_attempts_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id) ON DELETE CASCADE;


--
-- Name: student_course_attempts student_course_attempts_graded_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_course_attempts
    ADD CONSTRAINT student_course_attempts_graded_by_fkey FOREIGN KEY (graded_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: student_course_attempts student_course_attempts_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_course_attempts
    ADD CONSTRAINT student_course_attempts_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: student_course_attempts student_course_attempts_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_course_attempts
    ADD CONSTRAINT student_course_attempts_term_id_fkey FOREIGN KEY (term_id) REFERENCES public.academic_terms(id) ON DELETE RESTRICT;


--
-- Name: student_documents student_documents_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_documents
    ADD CONSTRAINT student_documents_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: student_documents student_documents_uploaded_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_documents
    ADD CONSTRAINT student_documents_uploaded_by_fkey FOREIGN KEY (uploaded_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: student_documents student_documents_verified_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_documents
    ADD CONSTRAINT student_documents_verified_by_fkey FOREIGN KEY (verified_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: student_elective_selections student_elective_selections_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_elective_selections
    ADD CONSTRAINT student_elective_selections_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id) ON DELETE CASCADE;


--
-- Name: student_elective_selections student_elective_selections_pool_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_elective_selections
    ADD CONSTRAINT student_elective_selections_pool_id_fkey FOREIGN KEY (pool_id) REFERENCES public.elective_pools(id) ON DELETE CASCADE;


--
-- Name: student_elective_selections student_elective_selections_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_elective_selections
    ADD CONSTRAINT student_elective_selections_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: student_elective_selections student_elective_selections_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_elective_selections
    ADD CONSTRAINT student_elective_selections_term_id_fkey FOREIGN KEY (term_id) REFERENCES public.academic_terms(id) ON DELETE SET NULL;


--
-- Name: student_grade_aggregates student_grade_aggregates_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_grade_aggregates
    ADD CONSTRAINT student_grade_aggregates_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: student_grade_aggregates student_grade_aggregates_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_grade_aggregates
    ADD CONSTRAINT student_grade_aggregates_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id);


--
-- Name: student_grade_versions student_grade_versions_approved_by_admin_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_grade_versions
    ADD CONSTRAINT student_grade_versions_approved_by_admin_fkey FOREIGN KEY (approved_by_admin) REFERENCES public.users(id);


--
-- Name: student_grade_versions student_grade_versions_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_grade_versions
    ADD CONSTRAINT student_grade_versions_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: student_grade_versions student_grade_versions_reviewed_by_prof_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_grade_versions
    ADD CONSTRAINT student_grade_versions_reviewed_by_prof_fkey FOREIGN KEY (reviewed_by_prof) REFERENCES public.users(id);


--
-- Name: student_grade_versions student_grade_versions_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_grade_versions
    ADD CONSTRAINT student_grade_versions_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id);


--
-- Name: student_grade_versions student_grade_versions_submitted_by_ta_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_grade_versions
    ADD CONSTRAINT student_grade_versions_submitted_by_ta_fkey FOREIGN KEY (submitted_by_ta) REFERENCES public.users(id);


--
-- Name: student_graduation_progress student_graduation_progress_requirement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_graduation_progress
    ADD CONSTRAINT student_graduation_progress_requirement_id_fkey FOREIGN KEY (requirement_id) REFERENCES public.graduation_requirements(id) ON DELETE CASCADE;


--
-- Name: student_graduation_progress student_graduation_progress_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_graduation_progress
    ADD CONSTRAINT student_graduation_progress_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: student_term_gpa student_term_gpa_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_term_gpa
    ADD CONSTRAINT student_term_gpa_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: student_term_gpa student_term_gpa_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_term_gpa
    ADD CONSTRAINT student_term_gpa_term_id_fkey FOREIGN KEY (term_id) REFERENCES public.academic_terms(id) ON DELETE CASCADE;


--
-- Name: students students_admission_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_admission_term_id_fkey FOREIGN KEY (admission_term_id) REFERENCES public.academic_terms(id) ON DELETE SET NULL;


--
-- Name: students students_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id) ON DELETE SET NULL;


--
-- Name: students students_expected_grad_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_expected_grad_term_id_fkey FOREIGN KEY (expected_grad_term_id) REFERENCES public.academic_terms(id) ON DELETE SET NULL;


--
-- Name: students students_program_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_program_id_fkey FOREIGN KEY (program_id) REFERENCES public.academic_programs(id) ON DELETE SET NULL;


--
-- Name: students students_track_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_track_id_fkey FOREIGN KEY (track_id) REFERENCES public.academic_tracks(id) ON DELETE SET NULL;


--
-- Name: students students_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: ta_grade_events ta_grade_events_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ta_grade_events
    ADD CONSTRAINT ta_grade_events_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: ta_grade_events ta_grade_events_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ta_grade_events
    ADD CONSTRAINT ta_grade_events_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id);


--
-- Name: ta_grade_events ta_grade_events_ta_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ta_grade_events
    ADD CONSTRAINT ta_grade_events_ta_user_id_fkey FOREIGN KEY (ta_user_id) REFERENCES public.users(id);


--
-- Name: teaching_assistants teaching_assistants_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teaching_assistants
    ADD CONSTRAINT teaching_assistants_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id) ON DELETE SET NULL;


--
-- Name: teaching_assistants teaching_assistants_professor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teaching_assistants
    ADD CONSTRAINT teaching_assistants_professor_id_fkey FOREIGN KEY (professor_id) REFERENCES public.professors(id) ON DELETE SET NULL;


--
-- Name: teaching_assistants teaching_assistants_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teaching_assistants
    ADD CONSTRAINT teaching_assistants_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: transcript_verifications transcript_verifications_transcript_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transcript_verifications
    ADD CONSTRAINT transcript_verifications_transcript_id_fkey FOREIGN KEY (transcript_id) REFERENCES public.transcript_versions(id) ON DELETE CASCADE;


--
-- Name: transcript_versions transcript_versions_generated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transcript_versions
    ADD CONSTRAINT transcript_versions_generated_by_fkey FOREIGN KEY (generated_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: transcript_versions transcript_versions_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transcript_versions
    ADD CONSTRAINT transcript_versions_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: transfer_credits transfer_credits_approved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transfer_credits
    ADD CONSTRAINT transfer_credits_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: transfer_credits transfer_credits_evaluated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transfer_credits
    ADD CONSTRAINT transfer_credits_evaluated_by_fkey FOREIGN KEY (evaluated_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: transfer_credits transfer_credits_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transfer_credits
    ADD CONSTRAINT transfer_credits_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: transfer_credits transfer_credits_submitted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transfer_credits
    ADD CONSTRAINT transfer_credits_submitted_by_fkey FOREIGN KEY (submitted_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: transfer_credits transfer_credits_target_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transfer_credits
    ADD CONSTRAINT transfer_credits_target_course_id_fkey FOREIGN KEY (target_course_id) REFERENCES public.courses(id) ON DELETE SET NULL;


--
-- Name: transfer_credits transfer_credits_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transfer_credits
    ADD CONSTRAINT transfer_credits_term_id_fkey FOREIGN KEY (term_id) REFERENCES public.academic_terms(id) ON DELETE SET NULL;


--
-- Name: validation_results validation_results_batch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.validation_results
    ADD CONSTRAINT validation_results_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES public.import_batches(id) ON DELETE CASCADE;


--
-- Name: mv_department_analytics; Type: MATERIALIZED VIEW DATA; Schema: public; Owner: postgres
--

REFRESH MATERIALIZED VIEW public.mv_department_analytics;


--
-- Name: mv_quiz_performance; Type: MATERIALIZED VIEW DATA; Schema: public; Owner: postgres
--

REFRESH MATERIALIZED VIEW public.mv_quiz_performance;


--
-- PostgreSQL database dump complete
--

\unrestrict KLRDScjCEl7MqvciU7LblMAAFYPBGarcVaauC5J63yoqOc2xaSdbJjYDI7bXbob

