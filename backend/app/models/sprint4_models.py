"""
EduGuard AI — Sprint 4: Academic Intelligence Models
=====================================================
Covers Modules 1–17:
  - AcademicRulesConfig     (configurable rules/thresholds)
  - SemesterSnapshot        (Module 4 — immutable snapshots)
  - TranscriptVersion       (Module 5/6)
  - TranscriptVerification  (Module 7)
  - AcademicTimelineEvent   (Module 8)
  - AcademicStatusHistory   (Module 9)
  - DegreeProgressSnapshot  (Module 10)
  - GraduationEligibilityRecord (Module 11)
  - HonorsRecord            (Module 12)
  - GPAProjection           (Module 13)
  - AcademicRiskRecord      (Module 14)
  - RegistrarNote           (Module 15)
  - AcademicAuditEntry      (Module 16)

All models use extend_existing=True to safely co-exist with Sprint 1–3 models.
"""

from sqlalchemy import (
    Column, Integer, SmallInteger, BigInteger, String, Text, Boolean,
    Numeric, DateTime, ForeignKey, Enum, UniqueConstraint, Index,
    CheckConstraint
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.database import Base
import enum


# ── Enums ─────────────────────────────────────────────────────────────────────

class AcademicStatusEnum(str, enum.Enum):
    ACTIVE     = "active"
    WARNING    = "warning"
    PROBATION  = "probation"
    SUSPENDED  = "suspended"
    DISMISSED  = "dismissed"
    GRADUATED  = "graduated"
    INACTIVE   = "inactive"
    LEAVE      = "leave"


class TranscriptTypeEnum(str, enum.Enum):
    OFFICIAL    = "official"
    UNOFFICIAL  = "unofficial"
    SEMESTER    = "semester"
    GRADUATION  = "graduation"


class GradEligibilityEnum(str, enum.Enum):
    ELIGIBLE             = "eligible"
    CONDITIONALLY        = "conditionally_eligible"
    NOT_ELIGIBLE         = "not_eligible"


class HonorsLevelEnum(str, enum.Enum):
    NONE        = "none"
    PASS        = "pass"
    GOOD        = "good"
    VERY_GOOD   = "very_good"
    EXCELLENT   = "excellent"
    DISTINCTION = "distinction"
    HONORS      = "honors"
    HIGH_HONORS = "high_honors"


class RiskLevelEnum(str, enum.Enum):
    LOW      = "low"
    MEDIUM   = "medium"
    HIGH     = "high"
    CRITICAL = "critical"


class TimelineEventTypeEnum(str, enum.Enum):
    ENROLLMENT         = "enrollment"
    REGISTRATION       = "registration"
    COURSE_ATTEMPT     = "course_attempt"
    GRADE_POSTED       = "grade_posted"
    GRADE_CHANGED      = "grade_changed"
    GPA_RECALCULATED   = "gpa_recalculated"
    CGPA_CHANGED       = "cgpa_changed"
    STATUS_CHANGED     = "status_changed"
    TRANSCRIPT_ISSUED  = "transcript_issued"
    ADVISOR_NOTE       = "advisor_note"
    REGISTRAR_ACTION   = "registrar_action"
    WITHDRAWAL         = "withdrawal"
    GRADUATION         = "graduation"
    HONORS_AWARDED     = "honors_awarded"


class NoteTypeEnum(str, enum.Enum):
    REGISTRAR  = "registrar"
    ADVISOR    = "advisor"
    ACADEMIC   = "academic"
    FLAG       = "flag"
    DECISION   = "decision"


class AuditActionEnum(str, enum.Enum):
    GRADE_CHANGED         = "grade_changed"
    TRANSCRIPT_GENERATED  = "transcript_generated"
    GPA_RECALCULATED      = "gpa_recalculated"
    STATUS_CHANGED        = "status_changed"
    PROGRESS_UPDATED      = "progress_updated"
    GRADUATION_DECISION   = "graduation_decision"
    OVERRIDE_APPLIED      = "override_applied"
    NOTE_ADDED            = "note_added"
    SNAPSHOT_CREATED      = "snapshot_created"


def _vals(e):
    return [m.value for m in e]


# ═════════════════════════════════════════════════════════════════════════════
# MODULE: CONFIGURABLE ACADEMIC RULES
# ═════════════════════════════════════════════════════════════════════════════

class AcademicRulesConfig(Base):
    """
    Single source of truth for all configurable academic thresholds.
    No hardcoded constants anywhere in the business logic layer.
    Scoped per program (nullable = global default).
    """
    __tablename__  = "academic_rules_config"
    __table_args__ = (
        UniqueConstraint("program_id", "rule_key"),
        {"extend_existing": True},
    )

    id          = Column(BigInteger, primary_key=True, index=True)
    program_id  = Column(BigInteger, ForeignKey("academic_programs.id", ondelete="CASCADE"), nullable=True)
    rule_key    = Column(String(80),  nullable=False)   # e.g. "min_cgpa_graduation"
    rule_value  = Column(String(50),  nullable=False)   # stored as string, cast at runtime
    description = Column(Text)
    updated_by  = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    updated_at  = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    created_at  = Column(DateTime(timezone=True), server_default=func.now())


# ═════════════════════════════════════════════════════════════════════════════
# MODULE 4: SEMESTER SNAPSHOT ENGINE
# ═════════════════════════════════════════════════════════════════════════════

class SemesterSnapshot(Base):
    """
    Immutable, versioned snapshot of a student's academic state at end of term.
    Never overwritten — new version appended on recalculation.
    """
    __tablename__  = "semester_snapshots"
    __table_args__ = (
        Index("idx_snapshot_student_term", "student_id", "term_id"),
        {"extend_existing": True},
    )

    id                       = Column(BigInteger, primary_key=True, index=True)
    student_id               = Column(Integer, ForeignKey("students.id", ondelete="CASCADE"), nullable=False)
    term_id                  = Column(BigInteger, ForeignKey("academic_terms.id", ondelete="RESTRICT"), nullable=False)
    version                  = Column(SmallInteger, nullable=False, default=1)

    # GPA snapshot
    term_gpa                 = Column(Numeric(4, 3), nullable=False, default=0)
    cgpa_after_term          = Column(Numeric(4, 3), nullable=False, default=0)

    # Credit summary
    credits_attempted        = Column(SmallInteger, default=0)
    credits_earned           = Column(SmallInteger, default=0)
    credits_failed           = Column(SmallInteger, default=0)
    credits_withdrawn        = Column(SmallInteger, default=0)
    cumulative_attempted     = Column(SmallInteger, default=0)
    cumulative_earned        = Column(SmallInteger, default=0)

    # Standing
    academic_standing        = Column(
        Enum(AcademicStatusEnum, values_callable=_vals, name="academic_status"),
        default=AcademicStatusEnum.ACTIVE
    )
    honors_level             = Column(
        Enum(HonorsLevelEnum, values_callable=_vals, name="honors_level_snap"),
        default=HonorsLevelEnum.NONE
    )
    dean_list_eligible       = Column(Boolean, default=False)

    # Risk flags (JSONB for extensibility)
    risk_flags               = Column(JSONB, default=list)

    # Audit
    snapshot_hash            = Column(String(64))   # SHA-256 of snapshot data for integrity
    generated_by             = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    generated_at             = Column(DateTime(timezone=True), server_default=func.now())
    is_final                 = Column(Boolean, default=False)

    # Relationships
    student = relationship("Student", foreign_keys=[student_id])


# ═════════════════════════════════════════════════════════════════════════════
# MODULES 5 & 6: TRANSCRIPT ENGINE + VERSIONING
# ═════════════════════════════════════════════════════════════════════════════

class TranscriptVersion(Base):
    """
    Every transcript generation creates an immutable version record.
    Supports history, comparison, and registrar audits.
    """
    __tablename__  = "transcript_versions"
    __table_args__ = (
        Index("idx_transcript_student", "student_id"),
        {"extend_existing": True},
    )

    id               = Column(BigInteger, primary_key=True, index=True)
    student_id       = Column(Integer, ForeignKey("students.id", ondelete="CASCADE"), nullable=False)
    version_number   = Column(Integer, nullable=False, default=1)
    transcript_type  = Column(
        Enum(TranscriptTypeEnum, values_callable=_vals, name="transcript_type"),
        nullable=False, default=TranscriptTypeEnum.UNOFFICIAL
    )

    # Snapshot of data at generation time (JSONB — complete transcript payload)
    transcript_data  = Column(JSONB, nullable=False)

    # Integrity & audit
    snapshot_hash    = Column(String(64), nullable=False)
    generated_by     = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    generated_at     = Column(DateTime(timezone=True), server_default=func.now())
    reason           = Column(Text)
    is_current       = Column(Boolean, default=True)

    # Verification (Module 7)
    verification     = relationship("TranscriptVerification", back_populates="transcript", uselist=False)
    student          = relationship("Student", foreign_keys=[student_id])


# ═════════════════════════════════════════════════════════════════════════════
# MODULE 7: TRANSCRIPT VERIFICATION
# ═════════════════════════════════════════════════════════════════════════════

class TranscriptVerification(Base):
    """
    Verification system — each transcript version receives a unique
    verification code and token. Designed for future QR implementation.
    """
    __tablename__  = "transcript_verifications"
    __table_args__ = {"extend_existing": True}

    id                  = Column(BigInteger, primary_key=True, index=True)
    transcript_id       = Column(BigInteger, ForeignKey("transcript_versions.id", ondelete="CASCADE"), unique=True, nullable=False)
    verification_code   = Column(String(20),  unique=True, nullable=False, index=True)  # Human-readable: TRX-XXXX-XXXX
    verification_token  = Column(String(128), unique=True, nullable=False)               # Cryptographic token
    qr_identifier       = Column(String(64),  unique=True, nullable=False)               # For future QR implementation

    is_valid            = Column(Boolean, default=True)
    expires_at          = Column(DateTime(timezone=True))
    verified_count      = Column(Integer, default=0)
    last_verified_at    = Column(DateTime(timezone=True))
    invalidated_at      = Column(DateTime(timezone=True))
    invalidated_reason  = Column(Text)

    created_at          = Column(DateTime(timezone=True), server_default=func.now())

    transcript = relationship("TranscriptVersion", back_populates="verification")


# ═════════════════════════════════════════════════════════════════════════════
# MODULE 8: ACADEMIC TIMELINE ENGINE
# ═════════════════════════════════════════════════════════════════════════════

class AcademicTimelineEvent(Base):
    """
    Complete academic timeline — every significant event is recorded here.
    Immutable append-only log.
    """
    __tablename__  = "academic_timeline_events"
    __table_args__ = (
        Index("idx_timeline_student_ts", "student_id", "occurred_at"),
        {"extend_existing": True},
    )

    id            = Column(BigInteger, primary_key=True, index=True)
    student_id    = Column(Integer, ForeignKey("students.id", ondelete="CASCADE"), nullable=False)
    term_id       = Column(BigInteger, ForeignKey("academic_terms.id", ondelete="SET NULL"), nullable=True)
    event_type    = Column(
        Enum(TimelineEventTypeEnum, values_callable=_vals, name="timeline_event_type"),
        nullable=False
    )
    title         = Column(String(200), nullable=False)
    description   = Column(Text)
    payload       = Column(JSONB, default=dict)   # event-specific data
    actor_id      = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    occurred_at   = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    student = relationship("Student", foreign_keys=[student_id])


# ═════════════════════════════════════════════════════════════════════════════
# MODULE 9: ACADEMIC STATUS TRACKING
# ═════════════════════════════════════════════════════════════════════════════

class AcademicStatusHistory(Base):
    """
    Tracks every status transition with full audit trail.
    """
    __tablename__  = "academic_status_history"
    __table_args__ = (
        Index("idx_status_student", "student_id"),
        {"extend_existing": True},
    )

    id          = Column(BigInteger, primary_key=True, index=True)
    student_id  = Column(Integer, ForeignKey("students.id", ondelete="CASCADE"), nullable=False)
    term_id     = Column(BigInteger, ForeignKey("academic_terms.id", ondelete="SET NULL"), nullable=True)
    old_status  = Column(Enum(AcademicStatusEnum, values_callable=_vals, name="acad_status_old"), nullable=True)
    new_status  = Column(Enum(AcademicStatusEnum, values_callable=_vals, name="acad_status_new"), nullable=False)
    cgpa_at_change   = Column(Numeric(4, 3))
    term_gpa_at_change = Column(Numeric(4, 3))
    reason      = Column(Text)
    actor_id    = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    occurred_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    student = relationship("Student", foreign_keys=[student_id])


# ═════════════════════════════════════════════════════════════════════════════
# MODULE 10: DEGREE PROGRESS SNAPSHOT
# ═════════════════════════════════════════════════════════════════════════════

class DegreeProgressSnapshot(Base):
    """
    Point-in-time snapshot of a student's degree progress.
    Versioned — new snapshot created on recalculation, old ones preserved.
    """
    __tablename__  = "degree_progress_snapshots"
    __table_args__ = (
        Index("idx_progress_student", "student_id"),
        {"extend_existing": True},
    )

    id                        = Column(BigInteger, primary_key=True, index=True)
    student_id                = Column(Integer, ForeignKey("students.id", ondelete="CASCADE"), nullable=False)
    term_id                   = Column(BigInteger, ForeignKey("academic_terms.id", ondelete="SET NULL"), nullable=True)
    version                   = Column(SmallInteger, default=1)

    # Credit progress
    required_credits          = Column(SmallInteger, nullable=False)
    earned_credits            = Column(SmallInteger, default=0)
    remaining_credits         = Column(SmallInteger, default=0)
    completion_percentage     = Column(Numeric(5, 2), default=0)

    # Category breakdown (JSONB for flexibility across programs/tracks)
    category_breakdown        = Column(JSONB, default=dict)
    # Example: {"core": {"required": 90, "earned": 45}, "elective": {...}, ...}

    # Missing items
    missing_core_courses      = Column(JSONB, default=list)   # list of course codes
    missing_elective_slots    = Column(SmallInteger, default=0)
    missing_categories        = Column(JSONB, default=list)

    # Flags
    all_core_complete         = Column(Boolean, default=False)
    all_electives_complete    = Column(Boolean, default=False)
    field_training_complete   = Column(Boolean, default=False)
    graduation_project_complete = Column(Boolean, default=False)

    computed_at               = Column(DateTime(timezone=True), server_default=func.now())
    computed_by               = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))

    student = relationship("Student", foreign_keys=[student_id])


# ═════════════════════════════════════════════════════════════════════════════
# MODULE 11: GRADUATION ELIGIBILITY RECORD
# ═════════════════════════════════════════════════════════════════════════════

class GraduationEligibilityRecord(Base):
    """
    Formal graduation eligibility determination — each evaluation creates a record.
    """
    __tablename__  = "graduation_eligibility_records"
    __table_args__ = (
        Index("idx_grad_elig_student", "student_id"),
        {"extend_existing": True},
    )

    id                   = Column(BigInteger, primary_key=True, index=True)
    student_id           = Column(Integer, ForeignKey("students.id", ondelete="CASCADE"), nullable=False)
    term_id              = Column(BigInteger, ForeignKey("academic_terms.id", ondelete="SET NULL"), nullable=True)

    eligibility_status   = Column(
        Enum(GradEligibilityEnum, values_callable=_vals, name="grad_eligibility"),
        nullable=False, default=GradEligibilityEnum.NOT_ELIGIBLE
    )

    # Detailed requirement checks (JSONB)
    requirements_met     = Column(JSONB, default=dict)
    # Example: {"credit_hours": true, "min_cgpa": false, "required_courses": true, ...}

    missing_requirements = Column(JSONB, default=list)
    # List of human-readable strings describing what is missing

    cgpa_at_evaluation   = Column(Numeric(4, 3))
    credits_at_evaluation = Column(SmallInteger)

    evaluated_by         = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    evaluated_at         = Column(DateTime(timezone=True), server_default=func.now())
    notes                = Column(Text)
    is_current           = Column(Boolean, default=True)

    student = relationship("Student", foreign_keys=[student_id])


# ═════════════════════════════════════════════════════════════════════════════
# MODULE 12: HONORS RECORD
# ═════════════════════════════════════════════════════════════════════════════

class HonorsRecord(Base):
    """
    Dean's List, Honors, High Honors, Distinction determinations.
    Driven entirely by AcademicRulesConfig — no hardcoded thresholds here.
    """
    __tablename__  = "honors_records"
    __table_args__ = (
        Index("idx_honors_student_term", "student_id", "term_id"),
        {"extend_existing": True},
    )

    id              = Column(BigInteger, primary_key=True, index=True)
    student_id      = Column(Integer, ForeignKey("students.id", ondelete="CASCADE"), nullable=False)
    term_id         = Column(BigInteger, ForeignKey("academic_terms.id", ondelete="SET NULL"), nullable=True)
    honors_level    = Column(
        Enum(HonorsLevelEnum, values_callable=_vals, name="honors_level_rec"),
        nullable=False
    )
    is_deans_list   = Column(Boolean, default=False)
    term_gpa_used   = Column(Numeric(4, 3))
    cgpa_used       = Column(Numeric(4, 3))
    credits_used    = Column(SmallInteger)
    qualification_data = Column(JSONB, default=dict)  # criteria that were met/unmet
    awarded_at      = Column(DateTime(timezone=True), server_default=func.now())
    awarded_by      = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))

    student = relationship("Student", foreign_keys=[student_id])


# ═════════════════════════════════════════════════════════════════════════════
# MODULE 13: GPA PROJECTION ENGINE
# ═════════════════════════════════════════════════════════════════════════════

class GPAProjection(Base):
    """
    Stored GPA projections — "what grade do I need to achieve target CGPA?"
    Each query creates a projection record for history and analytics.
    """
    __tablename__  = "gpa_projections"
    __table_args__ = (
        Index("idx_proj_student", "student_id"),
        {"extend_existing": True},
    )

    id                     = Column(BigInteger, primary_key=True, index=True)
    student_id             = Column(Integer, ForeignKey("students.id", ondelete="CASCADE"), nullable=False)
    term_id                = Column(BigInteger, ForeignKey("academic_terms.id", ondelete="SET NULL"), nullable=True)

    projection_type        = Column(String(50), nullable=False)
    # e.g. "graduation_target", "term_target", "course_grade_needed"

    current_cgpa           = Column(Numeric(4, 3))
    current_credits        = Column(SmallInteger)
    target_cgpa            = Column(Numeric(4, 3))
    remaining_credits      = Column(SmallInteger)

    # Scenario inputs (JSONB)
    scenario_input         = Column(JSONB, default=dict)
    # e.g. {"registered_courses": [{"code": "CSE112", "credits": 3}], "target_grade": "B+"}

    # Projection results (JSONB)
    projection_result      = Column(JSONB, default=dict)
    # e.g. {"required_avg_grade_points": 3.1, "projected_cgpa": 2.85, ...}

    projected_semester_gpa = Column(Numeric(4, 3))
    projected_cgpa         = Column(Numeric(4, 3))
    is_achievable          = Column(Boolean)

    computed_at            = Column(DateTime(timezone=True), server_default=func.now())

    student = relationship("Student", foreign_keys=[student_id])


# ═════════════════════════════════════════════════════════════════════════════
# MODULE 14: ACADEMIC RISK RECORD
# ═════════════════════════════════════════════════════════════════════════════

class AcademicRiskRecord(Base):
    """
    Academic risk assessments — integrates with Sprint 3 AI risk model.
    Stores risk history for trend analysis.
    """
    __tablename__  = "academic_risk_records"
    __table_args__ = (
        Index("idx_risk_student", "student_id"),
        {"extend_existing": True},
    )

    id                  = Column(BigInteger, primary_key=True, index=True)
    student_id          = Column(Integer, ForeignKey("students.id", ondelete="CASCADE"), nullable=False)
    term_id             = Column(BigInteger, ForeignKey("academic_terms.id", ondelete="SET NULL"), nullable=True)

    risk_level          = Column(
        Enum(RiskLevelEnum, values_callable=_vals, name="risk_level_s4"),
        nullable=False
    )
    risk_score          = Column(Numeric(5, 4))  # 0.0000 – 1.0000

    # Contributing factors
    gpa_trend           = Column(Numeric(5, 4))   # negative = declining
    cgpa_trend          = Column(Numeric(5, 4))
    failed_courses_count = Column(SmallInteger, default=0)
    repeated_courses_count = Column(SmallInteger, default=0)
    withdrawal_count    = Column(SmallInteger, default=0)
    degree_completion_pct = Column(Numeric(5, 2))

    risk_factors        = Column(JSONB, default=list)   # list of contributing factor strings
    recommendations     = Column(JSONB, default=list)   # list of recommended actions

    assessed_by         = Column(String(20), default="system")  # "system" or user id
    assessed_at         = Column(DateTime(timezone=True), server_default=func.now())
    is_current          = Column(Boolean, default=True)

    student = relationship("Student", foreign_keys=[student_id])


# ═════════════════════════════════════════════════════════════════════════════
# MODULE 15: REGISTRAR NOTES ENGINE
# ═════════════════════════════════════════════════════════════════════════════

class RegistrarNote(Base):
    """
    Registrar notes, academic decisions, advisor notes, student flags.
    Searchable, auditable, versioned.
    """
    __tablename__  = "registrar_notes"
    __table_args__ = (
        Index("idx_note_student", "student_id"),
        Index("idx_note_search", "student_id", "note_type"),
        {"extend_existing": True},
    )

    id            = Column(BigInteger, primary_key=True, index=True)
    student_id    = Column(Integer, ForeignKey("students.id", ondelete="CASCADE"), nullable=False)
    term_id       = Column(BigInteger, ForeignKey("academic_terms.id", ondelete="SET NULL"), nullable=True)
    note_type     = Column(
        Enum(NoteTypeEnum, values_callable=_vals, name="note_type"),
        nullable=False, default=NoteTypeEnum.REGISTRAR
    )
    title         = Column(String(200), nullable=False)
    content       = Column(Text, nullable=False)
    tags          = Column(JSONB, default=list)         # searchable tags
    is_private    = Column(Boolean, default=False)      # private = only registrar can see
    version       = Column(SmallInteger, default=1)
    previous_version_id = Column(BigInteger, ForeignKey("registrar_notes.id", ondelete="SET NULL"), nullable=True)

    created_by    = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    updated_by    = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    created_at    = Column(DateTime(timezone=True), server_default=func.now())
    updated_at    = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    student = relationship("Student", foreign_keys=[student_id])


# ═════════════════════════════════════════════════════════════════════════════
# MODULE 16: ACADEMIC AUDIT TRAIL
# ═════════════════════════════════════════════════════════════════════════════

class AcademicAuditEntry(Base):
    """
    Comprehensive audit trail for all academic record changes.
    Append-only — records are never updated or deleted.
    """
    __tablename__  = "academic_audit_entries"
    __table_args__ = (
        Index("idx_audit_student", "student_id"),
        Index("idx_audit_actor_ts", "actor_id", "occurred_at"),
        {"extend_existing": True},
    )

    id              = Column(BigInteger, primary_key=True, index=True)
    student_id      = Column(Integer, ForeignKey("students.id", ondelete="CASCADE"), nullable=False)
    term_id         = Column(BigInteger, ForeignKey("academic_terms.id", ondelete="SET NULL"), nullable=True)
    action          = Column(
        Enum(AuditActionEnum, values_callable=_vals, name="audit_action"),
        nullable=False
    )
    entity_type     = Column(String(50))    # "course_attempt", "transcript", "gpa", etc.
    entity_id       = Column(BigInteger)    # id of the affected record
    old_value       = Column(JSONB)
    new_value       = Column(JSONB)
    reason          = Column(Text)
    actor_id        = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    actor_role      = Column(String(20))
    ip_address      = Column(String(45))
    occurred_at     = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    student = relationship("Student", foreign_keys=[student_id])

# ── Import extended models so they register with Base ─────────────────────────
from app.models.sprint4_extended_models import (  # noqa: F401,E402
    ScholarshipEvaluation,
    ScholarshipStatusEnum,
    GPAVersion,
    AcademicAchievement,
    AchievementCategoryEnum,
    GPAExplanation,
)
