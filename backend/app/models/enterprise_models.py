"""
EduGuard AI — Enterprise Models
=================================
Additive extension on top of Sprint 4. No existing tables modified.

New tables:
  student_cohorts            — Cohort Tracking
  cohort_memberships         — Student-to-Cohort mapping
  registration_events        — Registration History
  student_documents          — Document Registry
  academic_cases             — Case Management
  academic_case_decisions    — Case decision history
  transfer_credits           — Transfer Credit Engine
  academic_exemptions        — Exemptions Engine
  academic_record_versions   — Full Record Versioning
  pdf_transcript_jobs        — PDF Transcript Export
  registrar_tasks            — Registrar Workflow
  registrar_task_assignments — Task assignments
  prerequisite_validations   — Prerequisite check log
"""

from __future__ import annotations
import enum

from sqlalchemy import (
    Column, Integer, SmallInteger, BigInteger, String, Text, Boolean,
    Numeric, DateTime, Date, ForeignKey, Enum, Index, UniqueConstraint,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.db.database import Base


def _v(e):
    return [m.value for m in e]


# ─────────────────────────────────────────────────────────────────────────────
# ENUMS
# ─────────────────────────────────────────────────────────────────────────────

class CohortStatusEnum(str, enum.Enum):
    ACTIVE     = "active"
    GRADUATED  = "graduated"
    DELAYED    = "delayed"
    INACTIVE   = "inactive"


class RegistrationEventTypeEnum(str, enum.Enum):
    REGISTRATION_CREATED   = "registration_created"
    COURSE_ADDED           = "course_added"
    COURSE_DROPPED         = "course_dropped"
    WITHDRAWAL             = "withdrawal"
    RE_REGISTRATION        = "re_registration"
    OVERRIDE               = "override"
    APPROVAL               = "approval"
    REGISTRAR_INTERVENTION = "registrar_intervention"
    LOCK                   = "lock"
    UNLOCK                 = "unlock"


class DocumentTypeEnum(str, enum.Enum):
    NATIONAL_ID          = "national_id"
    PASSPORT             = "passport"
    BIRTH_CERTIFICATE    = "birth_certificate"
    HIGH_SCHOOL_CERT     = "high_school_cert"
    TRANSCRIPT           = "transcript"
    TRANSFER_DOCUMENT    = "transfer_document"
    GRADUATION_DOCUMENT  = "graduation_document"
    PHOTO                = "photo"
    OTHER                = "other"


class DocumentStatusEnum(str, enum.Enum):
    PENDING   = "pending"
    VERIFIED  = "verified"
    REJECTED  = "rejected"
    EXPIRED   = "expired"


class CaseTypeEnum(str, enum.Enum):
    GRADE_APPEAL         = "grade_appeal"
    ACADEMIC_PETITION    = "academic_petition"
    EXCEPTION_REQUEST    = "exception_request"
    COURSE_WAIVER        = "course_waiver"
    GRADUATION_EXCEPTION = "graduation_exception"
    REGISTRATION_EXCEPTION = "registration_exception"
    TRANSFER_CREDIT_APPEAL = "transfer_credit_appeal"


class CaseStatusEnum(str, enum.Enum):
    SUBMITTED    = "submitted"
    UNDER_REVIEW = "under_review"
    APPROVED     = "approved"
    REJECTED     = "rejected"
    CLOSED       = "closed"


class TransferCreditStatusEnum(str, enum.Enum):
    PENDING   = "pending"
    APPROVED  = "approved"
    REJECTED  = "rejected"
    PARTIAL   = "partial"


class ExemptionTypeEnum(str, enum.Enum):
    COURSE_EXEMPTION      = "course_exemption"
    REQUIREMENT_EXEMPTION = "requirement_exemption"
    CURRICULUM_EXEMPTION  = "curriculum_exemption"


class ExemptionStatusEnum(str, enum.Enum):
    PENDING   = "pending"
    APPROVED  = "approved"
    REJECTED  = "rejected"
    REVOKED   = "revoked"


class RecordVersionTriggerEnum(str, enum.Enum):
    GRADE_CHANGE       = "grade_change"
    GPA_RECALCULATION  = "gpa_recalculation"
    STATUS_CHANGE      = "status_change"
    PROGRESS_UPDATE    = "progress_update"
    TRANSCRIPT_ISSUE   = "transcript_issue"
    GRADUATION_DECISION = "graduation_decision"
    TRANSFER_APPLIED   = "transfer_applied"
    EXEMPTION_APPLIED  = "exemption_applied"
    REGISTRAR_OVERRIDE = "registrar_override"


class PDFJobStatusEnum(str, enum.Enum):
    QUEUED     = "queued"
    PROCESSING = "processing"
    COMPLETE   = "complete"
    FAILED     = "failed"


class RegistrarTaskTypeEnum(str, enum.Enum):
    REVIEW_APPEAL        = "review_appeal"
    APPROVE_TRANSFER     = "approve_transfer"
    REVIEW_EXEMPTION     = "review_exemption"
    APPROVE_TRANSCRIPT   = "approve_transcript"
    REVIEW_EXCEPTION     = "review_exception"
    PENDING_OVERRIDE     = "pending_override"
    GRADUATION_REVIEW    = "graduation_review"
    GENERAL              = "general"


class TaskStatusEnum(str, enum.Enum):
    OPEN       = "open"
    IN_PROGRESS = "in_progress"
    COMPLETE   = "complete"
    CANCELLED  = "cancelled"


class TaskPriorityEnum(str, enum.Enum):
    LOW    = "low"
    MEDIUM = "medium"
    HIGH   = "high"
    URGENT = "urgent"


# ═════════════════════════════════════════════════════════════════════════════
# 1. COHORT TRACKING
# ═════════════════════════════════════════════════════════════════════════════

class StudentCohort(Base):
    """Defines an academic intake cohort (e.g. 2022-Fall-CS)."""
    __tablename__  = "student_cohorts"
    __table_args__ = (
        UniqueConstraint("program_id", "intake_year", "intake_semester"),
        {"extend_existing": True},
    )

    id                      = Column(BigInteger, primary_key=True, index=True)
    program_id              = Column(BigInteger, ForeignKey("academic_programs.id", ondelete="SET NULL"))
    track_id                = Column(BigInteger, ForeignKey("academic_tracks.id",   ondelete="SET NULL"))
    cohort_code             = Column(String(40), unique=True, nullable=False)  # e.g. "CS-SE-2022-F"
    cohort_name             = Column(String(120))
    intake_year             = Column(SmallInteger, nullable=False)
    intake_semester         = Column(String(10), nullable=False)  # "Fall" | "Spring" | "Summer"
    intake_term_id          = Column(BigInteger, ForeignKey("academic_terms.id", ondelete="SET NULL"))
    expected_grad_term_id   = Column(BigInteger, ForeignKey("academic_terms.id", ondelete="SET NULL"))
    expected_grad_year      = Column(SmallInteger)
    total_semesters_planned = Column(SmallInteger, default=8)

    status              = Column(Enum(CohortStatusEnum, values_callable=_v, name="cohort_status"),
                                 default=CohortStatusEnum.ACTIVE)
    # Cohort-level statistics (denormalized for fast queries)
    total_enrolled      = Column(Integer, default=0)
    total_graduated     = Column(Integer, default=0)
    total_delayed       = Column(Integer, default=0)
    total_withdrawn     = Column(Integer, default=0)
    avg_cgpa            = Column(Numeric(4, 3))

    notes               = Column(Text)
    created_by          = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    created_at          = Column(DateTime(timezone=True), server_default=func.now())
    updated_at          = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    members = relationship("CohortMembership", back_populates="cohort")


class CohortMembership(Base):
    """Maps a student to a cohort with status tracking."""
    __tablename__  = "cohort_memberships"
    __table_args__ = (
        UniqueConstraint("student_id", "cohort_id"),
        Index("idx_cohort_member", "cohort_id", "student_id"),
        {"extend_existing": True},
    )

    id                     = Column(BigInteger, primary_key=True, index=True)
    student_id             = Column(Integer,    ForeignKey("students.id", ondelete="CASCADE"), nullable=False)
    cohort_id              = Column(BigInteger, ForeignKey("student_cohorts.id", ondelete="CASCADE"), nullable=False)
    join_date              = Column(Date)
    expected_grad_date     = Column(Date)
    actual_grad_date       = Column(Date)
    is_delayed             = Column(Boolean, default=False)
    delay_reason           = Column(Text)
    semesters_completed    = Column(SmallInteger, default=0)
    status                 = Column(Enum(CohortStatusEnum, values_callable=_v, name="cohort_member_status"),
                                    default=CohortStatusEnum.ACTIVE)
    notes                  = Column(Text)
    created_at             = Column(DateTime(timezone=True), server_default=func.now())
    updated_at             = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    cohort  = relationship("StudentCohort", back_populates="members")


# ═════════════════════════════════════════════════════════════════════════════
# 2. REGISTRATION EVENT HISTORY
# ═════════════════════════════════════════════════════════════════════════════

class RegistrationEvent(Base):
    """
    Append-only registration event log.
    No hard deletes — every add/drop/withdrawal is preserved as an event.
    """
    __tablename__  = "registration_events"
    __table_args__ = (
        Index("idx_reg_event_student_term", "student_id", "term_id"),
        {"extend_existing": True},
    )

    id              = Column(BigInteger, primary_key=True, index=True)
    student_id      = Column(Integer,    ForeignKey("students.id", ondelete="CASCADE"), nullable=False)
    term_id         = Column(BigInteger, ForeignKey("academic_terms.id", ondelete="RESTRICT"), nullable=False)
    course_id       = Column(BigInteger, ForeignKey("courses.id", ondelete="SET NULL"))
    attempt_id      = Column(BigInteger, ForeignKey("student_course_attempts.id", ondelete="SET NULL"))

    event_type      = Column(Enum(RegistrationEventTypeEnum, values_callable=_v, name="reg_event_type"),
                             nullable=False)
    event_detail    = Column(Text)
    payload         = Column(JSONB, default=dict)
    # {"section": "A", "override_reason": "...", "approved_by": 42}

    # Override/approval tracking
    requires_approval = Column(Boolean, default=False)
    approved_by      = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    approved_at      = Column(DateTime(timezone=True))
    rejection_reason = Column(Text)

    actor_id        = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    actor_role      = Column(String(30))
    ip_address      = Column(String(45))
    occurred_at     = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)


# ═════════════════════════════════════════════════════════════════════════════
# 3. STUDENT DOCUMENTS REGISTRY
# ═════════════════════════════════════════════════════════════════════════════

class StudentDocument(Base):
    """Enterprise document management for student records."""
    __tablename__  = "student_documents"
    __table_args__ = (
        Index("idx_doc_student_type", "student_id", "document_type"),
        {"extend_existing": True},
    )

    id              = Column(BigInteger, primary_key=True, index=True)
    student_id      = Column(Integer, ForeignKey("students.id", ondelete="CASCADE"), nullable=False)
    document_type   = Column(Enum(DocumentTypeEnum, values_callable=_v, name="doc_type"), nullable=False)
    document_number = Column(String(100))  # e.g. national ID number, passport number
    title           = Column(String(200), nullable=False)
    description     = Column(Text)

    # Storage reference (file path, S3 key, or URL — implementation-agnostic)
    storage_key     = Column(String(500))
    file_name       = Column(String(255))
    file_size_bytes = Column(Integer)
    mime_type       = Column(String(100))

    # Status tracking
    status          = Column(Enum(DocumentStatusEnum, values_callable=_v, name="doc_status"),
                             default=DocumentStatusEnum.PENDING)
    verification_status = Column(String(20), default="unverified")
    verified_by     = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    verified_at     = Column(DateTime(timezone=True))
    rejection_reason = Column(Text)

    # Dates
    issue_date      = Column(Date)
    expiry_date     = Column(Date)
    upload_date     = Column(DateTime(timezone=True), server_default=func.now())
    uploaded_by     = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))

    # Revision history (JSONB list of {version, storage_key, uploaded_at, uploaded_by})
    revision_history = Column(JSONB, default=list)
    version          = Column(SmallInteger, default=1)
    is_active        = Column(Boolean, default=True)
    metadata_        = Column("metadata", JSONB, default=dict)


# ═════════════════════════════════════════════════════════════════════════════
# 4. ACADEMIC CASE MANAGEMENT
# ═════════════════════════════════════════════════════════════════════════════

class AcademicCase(Base):
    """
    Academic case workflow: Grade Appeal, Petition, Exception, Waiver, etc.
    Full state machine: Submitted → Under Review → Approved/Rejected → Closed
    """
    __tablename__  = "academic_cases"
    __table_args__ = (
        Index("idx_case_student", "student_id"),
        Index("idx_case_status",  "status"),
        {"extend_existing": True},
    )

    id              = Column(BigInteger, primary_key=True, index=True)
    case_number     = Column(String(30), unique=True, nullable=False, index=True)
    # Format: CASE-{YYYY}-{NNNNN}  e.g. CASE-2024-00123

    student_id      = Column(Integer,    ForeignKey("students.id",       ondelete="CASCADE"), nullable=False)
    term_id         = Column(BigInteger, ForeignKey("academic_terms.id", ondelete="SET NULL"))
    course_id       = Column(BigInteger, ForeignKey("courses.id",        ondelete="SET NULL"))
    attempt_id      = Column(BigInteger, ForeignKey("student_course_attempts.id", ondelete="SET NULL"))

    case_type       = Column(Enum(CaseTypeEnum,   values_callable=_v, name="case_type"),   nullable=False)
    status          = Column(Enum(CaseStatusEnum, values_callable=_v, name="case_status"), nullable=False,
                             default=CaseStatusEnum.SUBMITTED)

    title           = Column(String(300), nullable=False)
    description     = Column(Text,        nullable=False)
    supporting_docs = Column(JSONB, default=list)  # list of document IDs

    # Assignment
    assigned_to     = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    assigned_at     = Column(DateTime(timezone=True))

    # Resolution
    resolution      = Column(Text)
    resolved_by     = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    resolved_at     = Column(DateTime(timezone=True))

    # Metadata
    priority        = Column(String(10), default="medium")
    submitted_by    = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    submitted_at    = Column(DateTime(timezone=True), server_default=func.now())
    due_date        = Column(DateTime(timezone=True))
    closed_at       = Column(DateTime(timezone=True))

    decisions   = relationship("AcademicCaseDecision", back_populates="case",
                               order_by="AcademicCaseDecision.decided_at")


class AcademicCaseDecision(Base):
    """Immutable decision history for each case status transition."""
    __tablename__  = "academic_case_decisions"
    __table_args__ = (
        Index("idx_case_decision", "case_id"),
        {"extend_existing": True},
    )

    id          = Column(BigInteger, primary_key=True, index=True)
    case_id     = Column(BigInteger, ForeignKey("academic_cases.id", ondelete="CASCADE"), nullable=False)
    from_status = Column(Enum(CaseStatusEnum, values_callable=_v, name="case_decision_from"), nullable=True)
    to_status   = Column(Enum(CaseStatusEnum, values_callable=_v, name="case_decision_to"),   nullable=False)
    decision    = Column(Text)
    notes       = Column(Text)
    decided_by  = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    decided_at  = Column(DateTime(timezone=True), server_default=func.now())
    payload     = Column(JSONB, default=dict)

    case = relationship("AcademicCase", back_populates="decisions")


# ═════════════════════════════════════════════════════════════════════════════
# 5. TRANSFER CREDITS ENGINE
# ═════════════════════════════════════════════════════════════════════════════

class TransferCredit(Base):
    """
    Production-grade transfer credit evaluation and approval.
    Integrates with degree progress and graduation eligibility.
    """
    __tablename__  = "transfer_credits"
    __table_args__ = (
        Index("idx_transfer_student", "student_id"),
        {"extend_existing": True},
    )

    id                      = Column(BigInteger, primary_key=True, index=True)
    student_id              = Column(Integer,    ForeignKey("students.id", ondelete="CASCADE"), nullable=False)
    term_id                 = Column(BigInteger, ForeignKey("academic_terms.id", ondelete="SET NULL"))

    # Source institution
    source_institution      = Column(String(200), nullable=False)
    source_institution_country = Column(String(80))
    source_course_code      = Column(String(30),  nullable=False)
    source_course_name      = Column(String(200), nullable=False)
    source_credit_hours     = Column(SmallInteger, nullable=False)
    source_grade            = Column(String(5))
    source_grade_points     = Column(Numeric(4, 3))
    source_grade_scale      = Column(String(20))  # e.g. "4.0" or "100"

    # Target mapping (our institution)
    target_course_id        = Column(BigInteger, ForeignKey("courses.id", ondelete="SET NULL"))
    target_course_code      = Column(String(30))  # if no direct mapping, store as free text
    target_credit_hours     = Column(SmallInteger)
    target_grade_points     = Column(Numeric(4, 3))  # mapped grade points

    # Policy: transfer credits excluded from CGPA by default
    counts_in_cgpa          = Column(Boolean, default=False)
    counts_toward_degree    = Column(Boolean, default=True)

    # Approval workflow
    status                  = Column(Enum(TransferCreditStatusEnum, values_callable=_v,
                                         name="transfer_credit_status"), default=TransferCreditStatusEnum.PENDING)
    evaluation_notes        = Column(Text)
    supporting_document_ids = Column(JSONB, default=list)
    evaluated_by            = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    evaluated_at            = Column(DateTime(timezone=True))
    approved_by             = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    approved_at             = Column(DateTime(timezone=True))
    rejection_reason        = Column(Text)

    # History (JSONB list of status changes)
    approval_history        = Column(JSONB, default=list)

    submitted_by            = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    submitted_at            = Column(DateTime(timezone=True), server_default=func.now())
    applied_to_record_at    = Column(DateTime(timezone=True))  # when applied to degree progress


# ═════════════════════════════════════════════════════════════════════════════
# 6. ACADEMIC EXEMPTIONS ENGINE
# ═════════════════════════════════════════════════════════════════════════════

class AcademicExemption(Base):
    """
    Course, requirement, and curriculum exemptions.
    Applied to degree progress and graduation eligibility after approval.
    """
    __tablename__  = "academic_exemptions"
    __table_args__ = (
        Index("idx_exemption_student", "student_id"),
        {"extend_existing": True},
    )

    id               = Column(BigInteger, primary_key=True, index=True)
    student_id       = Column(Integer,    ForeignKey("students.id", ondelete="CASCADE"), nullable=False)
    exemption_type   = Column(Enum(ExemptionTypeEnum, values_callable=_v, name="exemption_type"), nullable=False)
    status           = Column(Enum(ExemptionStatusEnum, values_callable=_v, name="exemption_status"),
                              default=ExemptionStatusEnum.PENDING)

    # What is being exempted
    course_id        = Column(BigInteger, ForeignKey("courses.id", ondelete="SET NULL"))
    course_code      = Column(String(20))  # free-text if no course record
    requirement_desc = Column(Text)         # description of requirement being exempted

    reason           = Column(Text, nullable=False)
    decision_notes   = Column(Text)
    supporting_doc_ids = Column(JSONB, default=list)

    # Approval history (JSONB list of {actor, status, notes, timestamp})
    approval_history = Column(JSONB, default=list)
    version          = Column(SmallInteger, default=1)

    requested_by     = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    requested_at     = Column(DateTime(timezone=True), server_default=func.now())
    reviewed_by      = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    reviewed_at      = Column(DateTime(timezone=True))
    approved_by      = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    approved_at      = Column(DateTime(timezone=True))
    revoked_at       = Column(DateTime(timezone=True))
    revoke_reason    = Column(Text)
    applied_at       = Column(DateTime(timezone=True))  # when applied to degree progress


# ═════════════════════════════════════════════════════════════════════════════
# 7. ACADEMIC RECORD VERSIONING
# ═════════════════════════════════════════════════════════════════════════════

class AcademicRecordVersion(Base):
    """
    Immutable versioned snapshot of the complete student academic record.
    Every mutation that affects GPA, CGPA, standing, progress, or
    graduation status must create a new version.
    Supports historical restoration and comparison.
    """
    __tablename__  = "academic_record_versions"
    __table_args__ = (
        Index("idx_arv_student", "student_id"),
        {"extend_existing": True},
    )

    id               = Column(BigInteger, primary_key=True, index=True)
    student_id       = Column(Integer, ForeignKey("students.id", ondelete="CASCADE"), nullable=False)
    version_number   = Column(Integer, nullable=False)
    trigger          = Column(Enum(RecordVersionTriggerEnum, values_callable=_v,
                                   name="arv_trigger"), nullable=False)
    trigger_detail   = Column(Text)

    # Complete record snapshot at this version
    cgpa             = Column(Numeric(4, 3))
    semester_gpa     = Column(Numeric(4, 3))
    hours_attempted  = Column(SmallInteger, default=0)
    hours_earned     = Column(SmallInteger, default=0)
    quality_points   = Column(Numeric(8, 3), default=0)
    academic_standing = Column(String(20))
    graduation_status = Column(String(30))
    degree_completion_pct = Column(Numeric(5, 2))

    # Full snapshot of courses, GPA, progress at this point in time
    record_snapshot  = Column(JSONB, nullable=False)
    # Includes: all course attempts, term GPAs, degree progress, standing history

    snapshot_hash    = Column(String(64), nullable=False)
    is_current       = Column(Boolean, default=True)

    authored_by      = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    authored_at      = Column(DateTime(timezone=True), server_default=func.now())
    notes            = Column(Text)


# ═════════════════════════════════════════════════════════════════════════════
# 8. PDF TRANSCRIPT EXPORT
# ═════════════════════════════════════════════════════════════════════════════

class PDFTranscriptJob(Base):
    """
    Tracks PDF transcript generation jobs.
    Async-capable: queued → processing → complete/failed.
    Storage-agnostic: result_key holds path/S3-key/URL.
    """
    __tablename__  = "pdf_transcript_jobs"
    __table_args__ = (
        Index("idx_pdf_job_student", "student_id"),
        {"extend_existing": True},
    )

    id                  = Column(BigInteger, primary_key=True, index=True)
    student_id          = Column(Integer,    ForeignKey("students.id", ondelete="CASCADE"), nullable=False)
    transcript_version_id = Column(BigInteger, ForeignKey("transcript_versions.id", ondelete="SET NULL"))

    transcript_type     = Column(String(20), default="unofficial")
    status              = Column(Enum(PDFJobStatusEnum, values_callable=_v, name="pdf_job_status"),
                                 default=PDFJobStatusEnum.QUEUED)

    # PDF metadata
    page_count          = Column(SmallInteger)
    file_size_bytes     = Column(Integer)
    result_key          = Column(String(500))  # storage path/key when complete
    error_message       = Column(Text)

    # Generation options (JSONB — extensible)
    options             = Column(JSONB, default=dict)
    # {"include_qr": true, "watermark": "UNOFFICIAL", "language": "en"}

    requested_by        = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    queued_at           = Column(DateTime(timezone=True), server_default=func.now())
    started_at          = Column(DateTime(timezone=True))
    completed_at        = Column(DateTime(timezone=True))
    expires_at          = Column(DateTime(timezone=True))  # after which file is purged


# ═════════════════════════════════════════════════════════════════════════════
# 9. REGISTRAR WORKFLOW SYSTEM
# ═════════════════════════════════════════════════════════════════════════════

class RegistrarTask(Base):
    """
    Registrar workspace task queue.
    Covers: pending appeals, exceptions, transfers, transcript approvals, overrides.
    Integrates with AcademicCase, TransferCredit, AcademicExemption, PDFTranscriptJob.
    """
    __tablename__  = "registrar_tasks"
    __table_args__ = (
        Index("idx_reg_task_assignee", "assigned_to", "status"),
        Index("idx_reg_task_student",  "student_id"),
        {"extend_existing": True},
    )

    id              = Column(BigInteger, primary_key=True, index=True)
    task_number     = Column(String(30), unique=True, nullable=False, index=True)
    # Format: TASK-{YYYY}-{NNNNN}

    task_type       = Column(Enum(RegistrarTaskTypeEnum, values_callable=_v, name="reg_task_type"), nullable=False)
    status          = Column(Enum(TaskStatusEnum,        values_callable=_v, name="task_status"),   nullable=False,
                             default=TaskStatusEnum.OPEN)
    priority        = Column(Enum(TaskPriorityEnum,      values_callable=_v, name="task_priority"), default=TaskPriorityEnum.MEDIUM)

    student_id      = Column(Integer,    ForeignKey("students.id",     ondelete="SET NULL"))
    term_id         = Column(BigInteger, ForeignKey("academic_terms.id", ondelete="SET NULL"))

    # Linked entity (one of these will be set)
    case_id         = Column(BigInteger, ForeignKey("academic_cases.id",    ondelete="SET NULL"))
    transfer_id     = Column(BigInteger, ForeignKey("transfer_credits.id",  ondelete="SET NULL"))
    exemption_id    = Column(BigInteger, ForeignKey("academic_exemptions.id", ondelete="SET NULL"))
    pdf_job_id      = Column(BigInteger, ForeignKey("pdf_transcript_jobs.id", ondelete="SET NULL"))

    title           = Column(String(300), nullable=False)
    description     = Column(Text)
    due_date        = Column(DateTime(timezone=True))

    assigned_to     = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    assigned_at     = Column(DateTime(timezone=True))
    completed_by    = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    completed_at    = Column(DateTime(timezone=True))
    resolution_notes = Column(Text)

    created_by      = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    created_at      = Column(DateTime(timezone=True), server_default=func.now())
    updated_at      = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    assignments = relationship("RegistrarTaskAssignment", back_populates="task")


class RegistrarTaskAssignment(Base):
    """History of task assignments (supports reassignment tracking)."""
    __tablename__  = "registrar_task_assignments"
    __table_args__ = (
        Index("idx_rta_task", "task_id"),
        {"extend_existing": True},
    )

    id           = Column(BigInteger, primary_key=True, index=True)
    task_id      = Column(BigInteger, ForeignKey("registrar_tasks.id", ondelete="CASCADE"), nullable=False)
    assigned_to  = Column(Integer,    ForeignKey("users.id", ondelete="SET NULL"))
    assigned_by  = Column(Integer,    ForeignKey("users.id", ondelete="SET NULL"))
    assigned_at  = Column(DateTime(timezone=True), server_default=func.now())
    unassigned_at = Column(DateTime(timezone=True))
    notes        = Column(Text)

    task = relationship("RegistrarTask", back_populates="assignments")


# ═════════════════════════════════════════════════════════════════════════════
# PREREQUISITE VALIDATION LOG
# ═════════════════════════════════════════════════════════════════════════════

class PrerequisiteValidation(Base):
    """
    Logs prerequisite checks performed during registration.
    Documents source of prerequisite rules (PDFs).
    """
    __tablename__  = "prerequisite_validations"
    __table_args__ = (
        Index("idx_prereq_val_student", "student_id"),
        {"extend_existing": True},
    )

    id              = Column(BigInteger, primary_key=True, index=True)
    student_id      = Column(Integer,    ForeignKey("students.id",     ondelete="CASCADE"), nullable=False)
    term_id         = Column(BigInteger, ForeignKey("academic_terms.id", ondelete="SET NULL"))
    course_id       = Column(BigInteger, ForeignKey("courses.id",      ondelete="CASCADE"), nullable=False)
    course_code     = Column(String(20), nullable=False)

    is_eligible     = Column(Boolean, nullable=False)
    missing_prereqs = Column(JSONB, default=list)
    satisfied_prereqs = Column(JSONB, default=list)

    # Policy source (which document defines this prerequisite)
    policy_source   = Column(String(200))
    # e.g. "Courses_Pre-requisites_Core_Elective.pdf"

    override_applied   = Column(Boolean, default=False)
    override_by        = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    override_reason    = Column(Text)
    validated_at       = Column(DateTime(timezone=True), server_default=func.now())
