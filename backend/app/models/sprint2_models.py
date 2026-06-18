"""
EduGuard AI — Sprint 2: Academic Rules Engine Models
File: backend/app/models/sprint2_models.py

SQLAlchemy ORM models for all Sprint 2 tables.
All FK targets use EXACT table names from Sprint 1 models.py:
  users, students, courses, academic_programs, academic_tracks,
  academic_terms, notifications, course_prerequisites

Import in backend/app/models/__init__.py (see updated __init__.py).
No existing models are modified.
"""

from __future__ import annotations

from sqlalchemy import (
    Column, Integer, SmallInteger, BigInteger, String, Text, Boolean,
    DateTime, Date, Numeric, ForeignKey, Enum, UniqueConstraint, CheckConstraint,
    Index,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.database import Base
import enum


# ── Enums ─────────────────────────────────────────────────────────────────────

class OverrideStatusEnum(str, enum.Enum):
    PENDING  = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"
    EXPIRED  = "expired"


class OverrideTypeEnum(str, enum.Enum):
    PREREQUISITE_WAIVER   = "prerequisite_waiver"
    REGISTRATION_OVERRIDE = "registration_override"
    GRADUATION_OVERRIDE   = "graduation_override"
    CREDIT_LOAD_OVERRIDE  = "credit_load_override"
    GRADE_EXCEPTION       = "grade_exception"


class CalendarPeriodTypeEnum(str, enum.Enum):
    REGISTRATION      = "registration"
    ADD_DROP          = "add_drop"
    WITHDRAWAL        = "withdrawal"
    MIDTERM           = "midterm"
    FINAL_EXAM        = "final_exam"
    GRADE_SUBMISSION  = "grade_submission"
    GRADUATION_REVIEW = "graduation_review"
    BREAK             = "break"


class NotifChannelEnum(str, enum.Enum):
    IN_APP = "in_app"
    EMAIL  = "email"
    SMS    = "sms"


class NotifEventTypeEnum(str, enum.Enum):
    REGISTRATION_ELIGIBLE    = "registration_eligible"
    ACADEMIC_RISK            = "academic_risk"
    GRADUATION_APPROACHING   = "graduation_approaching"
    MISSING_REQUIREMENT      = "missing_requirement"
    REGISTRATION_OPENING     = "registration_opening"
    REGISTRATION_CLOSING     = "registration_closing"
    GRADE_POSTED             = "grade_posted"
    PREREQUISITE_CLEARED     = "prerequisite_cleared"
    PLAN_APPROVED            = "plan_approved"
    PLAN_REJECTED            = "plan_rejected"
    INTERVENTION_ASSIGNED    = "intervention_assigned"
    CGPA_THRESHOLD_CROSSED   = "cgpa_threshold_crossed"
    ACADEMIC_STANDING_CHANGE = "academic_standing_change"
    OVERRIDE_DECISION        = "override_decision"


def _vals(e):
    return [m.value for m in e]


# ═════════════════════════════════════════════════════════════════════════════
# PREREQUISITE EXCEPTIONS
# Advisor-approved waivers. Immutable once created.
# ═════════════════════════════════════════════════════════════════════════════

class PrerequisiteException(Base):
    __tablename__  = "prerequisite_exceptions"
    __table_args__ = (
        Index("ix_prereq_exceptions_student_course", "student_id", "course_id"),
        {"extend_existing": True},
    )

    id               = Column(BigInteger, primary_key=True, index=True)
    # FK targets: exact table names from models.py
    student_id       = Column(Integer, ForeignKey("students.id", ondelete="CASCADE"),  nullable=False, index=True)
    course_id        = Column(Integer, ForeignKey("courses.id",  ondelete="CASCADE"),  nullable=False, index=True)
    waived_prereq_id = Column(Integer, ForeignKey("courses.id",  ondelete="CASCADE"),  nullable=False)
    granted_by       = Column(Integer, ForeignKey("users.id",    ondelete="SET NULL"))
    reason           = Column(Text, nullable=False)
    approved_at      = Column(DateTime(timezone=True), server_default=func.now())
    expires_at       = Column(DateTime(timezone=True))
    is_active        = Column(Boolean, default=True)
    created_at       = Column(DateTime(timezone=True), server_default=func.now())

    student         = relationship("Student", foreign_keys=[student_id])
    course          = relationship("Course",  foreign_keys=[course_id])
    waived_prereq   = relationship("Course",  foreign_keys=[waived_prereq_id])
    granted_by_user = relationship("User",    foreign_keys=[granted_by])


# ═════════════════════════════════════════════════════════════════════════════
# PREREQUISITE VALIDATION LOG
# ═════════════════════════════════════════════════════════════════════════════

class PrerequisiteValidationLog(Base):
    __tablename__  = "prerequisite_validation_log"
    __table_args__ = {"extend_existing": True}

    id              = Column(BigInteger, primary_key=True, index=True)
    student_id      = Column(Integer,    ForeignKey("students.id",      ondelete="CASCADE"),   nullable=False)
    course_id       = Column(Integer,    ForeignKey("courses.id",       ondelete="CASCADE"),   nullable=False)
    term_id         = Column(BigInteger, ForeignKey("academic_terms.id", ondelete="SET NULL"))
    check_result    = Column(Boolean, nullable=False)
    missing_prereqs = Column(JSONB)
    rule_triggered  = Column(String(100))
    explanation     = Column(Text)
    decision_reason = Column(Text)
    checked_at      = Column(DateTime(timezone=True), server_default=func.now())
    checked_by      = Column(String(50), default="system")

    student = relationship("Student")
    course  = relationship("Course")


# ═════════════════════════════════════════════════════════════════════════════
# ELECTIVE POOLS
# ═════════════════════════════════════════════════════════════════════════════

class ElectivePool(Base):
    __tablename__  = "elective_pools"
    __table_args__ = (
        UniqueConstraint("program_id", "pool_code"),
        {"extend_existing": True},
    )

    id                  = Column(BigInteger, primary_key=True, index=True)
    program_id          = Column(BigInteger, ForeignKey("academic_programs.id", ondelete="CASCADE"))
    track_id            = Column(BigInteger, ForeignKey("academic_tracks.id",   ondelete="CASCADE"))
    pool_code           = Column(String(20),  nullable=False)
    pool_name           = Column(String(150), nullable=False)
    min_selections      = Column(SmallInteger, nullable=False, default=1)
    max_selections      = Column(SmallInteger, nullable=False, default=3)
    required_selections = Column(SmallInteger, nullable=False, default=3)
    plan_semesters      = Column(String(50))
    notes               = Column(Text)
    created_at          = Column(DateTime(timezone=True), server_default=func.now())

    courses    = relationship("ElectivePoolCourse", back_populates="pool",
                              cascade="all, delete-orphan")
    selections = relationship("StudentElectiveSelection", back_populates="pool")


class ElectivePoolCourse(Base):
    __tablename__  = "elective_pool_courses"
    __table_args__ = (
        UniqueConstraint("pool_id", "course_id"),
        {"extend_existing": True},
    )

    id         = Column(BigInteger, primary_key=True, index=True)
    pool_id    = Column(BigInteger, ForeignKey("elective_pools.id", ondelete="CASCADE"), nullable=False)
    course_id  = Column(Integer,    ForeignKey("courses.id",        ondelete="CASCADE"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    pool   = relationship("ElectivePool", back_populates="courses")
    course = relationship("Course")


class StudentElectiveSelection(Base):
    __tablename__  = "student_elective_selections"
    __table_args__ = (
        UniqueConstraint("student_id", "pool_id", "course_id"),
        {"extend_existing": True},
    )

    id          = Column(BigInteger, primary_key=True, index=True)
    student_id  = Column(Integer,    ForeignKey("students.id",      ondelete="CASCADE"), nullable=False)
    pool_id     = Column(BigInteger, ForeignKey("elective_pools.id", ondelete="CASCADE"), nullable=False)
    course_id   = Column(Integer,    ForeignKey("courses.id",        ondelete="CASCADE"), nullable=False)
    term_id     = Column(BigInteger, ForeignKey("academic_terms.id", ondelete="SET NULL"))
    selected_at = Column(DateTime(timezone=True), server_default=func.now())

    pool   = relationship("ElectivePool",  back_populates="selections")
    course = relationship("Course")


# ═════════════════════════════════════════════════════════════════════════════
# GRADUATION AUDIT RESULTS
# ═════════════════════════════════════════════════════════════════════════════

class GraduationAuditResult(Base):
    __tablename__  = "graduation_audit_results"
    __table_args__ = {"extend_existing": True}

    id                      = Column(BigInteger, primary_key=True, index=True)
    student_id              = Column(Integer, ForeignKey("students.id", ondelete="CASCADE"), nullable=False)
    audited_at              = Column(DateTime(timezone=True), server_default=func.now())
    is_eligible             = Column(Boolean, nullable=False, default=False)
    total_ch_required       = Column(SmallInteger, nullable=False, default=134)
    total_ch_earned         = Column(SmallInteger, nullable=False, default=0)
    core_courses_required   = Column(SmallInteger, default=0)
    core_courses_completed  = Column(SmallInteger, default=0)
    electives_required      = Column(SmallInteger, default=3)
    electives_completed     = Column(SmallInteger, default=0)
    field_training_done     = Column(Boolean, default=False)
    graduation_project_done = Column(Boolean, default=False)
    univ_req_done           = Column(Boolean, default=False)
    cgpa_at_audit           = Column(Numeric(4, 3), default=0.000)
    blocking_reasons        = Column(JSONB)
    completed_requirements  = Column(JSONB)
    missing_courses         = Column(JSONB)
    audit_version           = Column(String(20), default="v2.0")
    triggered_by            = Column(String(50), default="system")
    created_at              = Column(DateTime(timezone=True), server_default=func.now())

    student = relationship("Student")


# ═════════════════════════════════════════════════════════════════════════════
# ACADEMIC CALENDAR PERIODS
# ═════════════════════════════════════════════════════════════════════════════

class AcademicCalendarPeriod(Base):
    __tablename__  = "academic_calendar_periods"
    __table_args__ = {"extend_existing": True}

    id          = Column(BigInteger, primary_key=True, index=True)
    term_id     = Column(BigInteger, ForeignKey("academic_terms.id", ondelete="CASCADE"), nullable=False)
    period_type = Column(
        Enum(CalendarPeriodTypeEnum, values_callable=_vals, name="s2_calendar_period"),
        nullable=False,
    )
    label      = Column(String(100), nullable=False)
    start_date = Column(Date, nullable=False)
    end_date   = Column(Date, nullable=False)
    is_active  = Column(Boolean, default=True)
    notes      = Column(Text)
    created_by = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    term = relationship("AcademicTerm")


# ═════════════════════════════════════════════════════════════════════════════
# ACADEMIC OVERRIDES
# ═════════════════════════════════════════════════════════════════════════════

class AcademicOverride(Base):
    __tablename__  = "academic_overrides"
    __table_args__ = {"extend_existing": True}

    id             = Column(BigInteger, primary_key=True, index=True)
    override_type  = Column(
        Enum(OverrideTypeEnum, values_callable=_vals, name="s2_override_type"),
        nullable=False,
    )
    student_id    = Column(Integer,    ForeignKey("students.id",      ondelete="CASCADE"),  nullable=False)
    course_id     = Column(Integer,    ForeignKey("courses.id",       ondelete="SET NULL"))
    term_id       = Column(BigInteger, ForeignKey("academic_terms.id", ondelete="SET NULL"))
    requested_by  = Column(Integer,    ForeignKey("users.id",          ondelete="CASCADE"),  nullable=False)
    reviewed_by   = Column(Integer,    ForeignKey("users.id",          ondelete="SET NULL"))
    status        = Column(
        Enum(OverrideStatusEnum, values_callable=_vals, name="s2_override_status"),
        nullable=False, default=OverrideStatusEnum.PENDING,
    )
    reason          = Column(Text, nullable=False)
    reviewer_notes  = Column(Text)
    decision_reason = Column(Text)
    rule_triggered  = Column(String(100))
    explanation     = Column(Text)
    metadata_json   = Column(JSONB)
    requested_at    = Column(DateTime(timezone=True), server_default=func.now())
    reviewed_at     = Column(DateTime(timezone=True))
    expires_at      = Column(DateTime(timezone=True))
    created_at      = Column(DateTime(timezone=True), server_default=func.now())
    updated_at      = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    student   = relationship("Student")
    course    = relationship("Course")
    requester = relationship("User", foreign_keys=[requested_by])
    reviewer  = relationship("User", foreign_keys=[reviewed_by])
    history   = relationship("AcademicOverrideHistory", back_populates="override",
                             cascade="all, delete-orphan")


class AcademicOverrideHistory(Base):
    """Immutable audit trail — INSERT only, never UPDATE or DELETE."""
    __tablename__  = "academic_override_history"
    __table_args__ = {"extend_existing": True}

    id           = Column(BigInteger, primary_key=True, index=True)
    override_id  = Column(BigInteger, ForeignKey("academic_overrides.id", ondelete="CASCADE"), nullable=False)
    action       = Column(String(50), nullable=False)
    performed_by = Column(Integer,    ForeignKey("users.id", ondelete="SET NULL"))
    old_status   = Column(String(30))
    new_status   = Column(String(30))
    notes        = Column(Text)
    performed_at = Column(DateTime(timezone=True), server_default=func.now())

    override = relationship("AcademicOverride", back_populates="history")


# ═════════════════════════════════════════════════════════════════════════════
# NOTIFICATION FRAMEWORK EXTENSIONS
# Sprint 1 has notifications table — we add templates, delivery log, prefs.
# ═════════════════════════════════════════════════════════════════════════════

class NotificationTemplate(Base):
    __tablename__  = "notification_templates"
    __table_args__ = (
        UniqueConstraint("event_type", "channel"),
        {"extend_existing": True},
    )

    id               = Column(Integer, primary_key=True, index=True)
    event_type       = Column(
        Enum(NotifEventTypeEnum, values_callable=_vals, name="s2_notif_event"),
        nullable=False,
    )
    channel          = Column(
        Enum(NotifChannelEnum, values_callable=_vals, name="s2_notif_channel"),
        nullable=False, default=NotifChannelEnum.IN_APP,
    )
    subject_template = Column(Text, nullable=False)
    body_template    = Column(Text, nullable=False)
    priority         = Column(String(10), default="medium")
    is_active        = Column(Boolean, default=True)
    created_at       = Column(DateTime(timezone=True), server_default=func.now())
    updated_at       = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())


class NotificationDeliveryLog(Base):
    __tablename__  = "notification_delivery_log"
    __table_args__ = {"extend_existing": True}

    id              = Column(BigInteger, primary_key=True, index=True)
    # FK → Sprint 1 notifications table
    notification_id = Column(Integer, ForeignKey("notifications.id", ondelete="CASCADE"), nullable=False)
    channel         = Column(
        Enum(NotifChannelEnum, values_callable=_vals, name="s2_notif_channel"),
        nullable=False,
    )
    event_type      = Column(
        Enum(NotifEventTypeEnum, values_callable=_vals, name="s2_notif_event"),
    )
    sent_at       = Column(DateTime(timezone=True), server_default=func.now())
    delivered     = Column(Boolean, default=False)
    error_message = Column(Text)
    metadata_json = Column(JSONB)


class NotificationPreference(Base):
    __tablename__  = "notification_preferences"
    __table_args__ = (
        UniqueConstraint("user_id", "event_type"),
        {"extend_existing": True},
    )

    id         = Column(Integer, primary_key=True, index=True)
    user_id    = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    event_type = Column(
        Enum(NotifEventTypeEnum, values_callable=_vals, name="s2_notif_event"),
        nullable=False,
    )
    in_app     = Column(Boolean, default=True)
    email      = Column(Boolean, default=False)
    sms        = Column(Boolean, default=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    user = relationship("User")


# ═════════════════════════════════════════════════════════════════════════════
# RBAC PERMISSIONS
# ═════════════════════════════════════════════════════════════════════════════

class RbacPermission(Base):
    __tablename__  = "rbac_permissions"
    __table_args__ = (
        UniqueConstraint("role", "resource", "action"),
        {"extend_existing": True},
    )

    id         = Column(Integer, primary_key=True, index=True)
    role       = Column(String(30),  nullable=False)
    resource   = Column(String(100), nullable=False)
    action     = Column(String(50),  nullable=False)
    conditions = Column(JSONB)
    is_active  = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())


# ═════════════════════════════════════════════════════════════════════════════
# ACADEMIC DECISION LOG  (Explainability)
# ═════════════════════════════════════════════════════════════════════════════

class AcademicDecisionLog(Base):
    __tablename__  = "academic_decision_log"
    __table_args__ = {"extend_existing": True}

    id              = Column(BigInteger, primary_key=True, index=True)
    decision_type   = Column(String(50), nullable=False)
    student_id      = Column(Integer,    ForeignKey("students.id", ondelete="CASCADE"), nullable=False)
    course_id       = Column(Integer,    ForeignKey("courses.id",  ondelete="SET NULL"))
    term_id         = Column(BigInteger, ForeignKey("academic_terms.id", ondelete="SET NULL"))
    outcome         = Column(Boolean, nullable=False)
    decision_reason = Column(Text, nullable=False)
    rule_triggered  = Column(String(100))
    explanation     = Column(Text)
    input_snapshot  = Column(JSONB)
    output_snapshot = Column(JSONB)
    decided_by      = Column(String(50), default="system")
    decided_at      = Column(DateTime(timezone=True), server_default=func.now())

    student = relationship("Student")
    course  = relationship("Course")