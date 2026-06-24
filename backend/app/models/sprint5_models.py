"""
EduGuard AI — Sprint 5: Student Success & Academic Operations Models
====================================================================
New tables only. No existing models modified.

Modules:
  A - Configuration Center
  B - Workflow Engine Extensions
  C - Academic Calendar Engine
  D - Student Success Platform (warnings, scores, readiness, interventions, escalations)
  E - Notification Infrastructure
  F - Seed Batches
  G - Reporting Foundation
  H - Retention Analytics
"""

from __future__ import annotations
import enum

from sqlalchemy import (
    Column, Integer, SmallInteger, BigInteger, String, Text, Boolean,
    Numeric, DateTime, Date, Time, ForeignKey, Enum, Index, UniqueConstraint,
    CheckConstraint,
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

class ConfigDataTypeEnum(str, enum.Enum):
    STRING  = "string"
    INTEGER = "integer"
    DECIMAL = "decimal"
    BOOLEAN = "boolean"
    JSON    = "json"
    TEXT    = "text"


class WarningTypeEnum(str, enum.Enum):
    LOW_GPA              = "low_gpa"
    LOW_CGPA             = "low_cgpa"
    REPEATED_FAILURE     = "repeated_failure"
    HIGH_ABSENCE         = "high_absence"
    DELAYED_GRADUATION   = "delayed_graduation"
    PROBATION_RISK       = "probation_risk"
    DISMISSAL_RISK       = "dismissal_risk"
    GRADUATION_RISK      = "graduation_risk"
    MISSING_PREREQUISITE = "missing_prerequisite"
    CREDIT_DEFICIT       = "credit_deficit"
    ATTENDANCE_CRITICAL  = "attendance_critical"


class WarningSeverityEnum(str, enum.Enum):
    INFO     = "info"
    WARNING  = "warning"
    CRITICAL = "critical"
    URGENT   = "urgent"


class WarningStatusEnum(str, enum.Enum):
    ACTIVE       = "active"
    ACKNOWLEDGED = "acknowledged"
    RESOLVED     = "resolved"
    DISMISSED    = "dismissed"


class SuccessScoreBandEnum(str, enum.Enum):
    EXCELLENT = "excellent"
    GOOD      = "good"
    WARNING   = "warning"
    CRITICAL  = "critical"


class ReadinessStatusEnum(str, enum.Enum):
    READY          = "ready"
    NEARLY_READY   = "nearly_ready"
    NEEDS_ATTENTION = "needs_attention"
    NOT_ELIGIBLE   = "not_eligible"


class EscalationLevelEnum(str, enum.Enum):
    STUDENT          = "student"
    ADVISOR          = "advisor"
    PROFESSOR        = "professor"
    REGISTRAR        = "registrar"
    ACADEMIC_AFFAIRS = "academic_affairs"
    DEAN             = "dean"


class EscalationStatusEnum(str, enum.Enum):
    PENDING     = "pending"
    IN_PROGRESS = "in_progress"
    RESOLVED    = "resolved"
    CLOSED      = "closed"


class WorkflowStatusEnum(str, enum.Enum):
    DRAFT     = "draft"
    ACTIVE    = "active"
    PAUSED    = "paused"
    COMPLETED = "completed"
    CANCELLED = "cancelled"
    REJECTED  = "rejected"


class WorkflowStepTypeEnum(str, enum.Enum):
    REVIEW      = "review"
    APPROVAL    = "approval"
    NOTIFICATION = "notification"
    ESCALATION  = "escalation"
    AUTO_ACTION = "auto_action"
    DECISION    = "decision"


class CalendarEventTypeEnum(str, enum.Enum):
    ACADEMIC_YEAR_START      = "academic_year_start"
    ACADEMIC_YEAR_END        = "academic_year_end"
    SEMESTER_START           = "semester_start"
    SEMESTER_END             = "semester_end"
    REGISTRATION_OPEN        = "registration_open"
    REGISTRATION_CLOSE       = "registration_close"
    ADD_DROP_OPEN            = "add_drop_open"
    ADD_DROP_CLOSE           = "add_drop_close"
    WITHDRAWAL_DEADLINE      = "withdrawal_deadline"
    EXAM_PERIOD_START        = "exam_period_start"
    EXAM_PERIOD_END          = "exam_period_end"
    GRADUATION_DEADLINE      = "graduation_deadline"
    GRADE_SUBMISSION_DEADLINE = "grade_submission_deadline"
    HOLIDAY                  = "holiday"
    OTHER                    = "other"


class NotifChannelEnum(str, enum.Enum):
    IN_APP = "in_app"
    EMAIL  = "email"
    SMS    = "sms"
    PUSH   = "push"


class NotifDeliveryStatusEnum(str, enum.Enum):
    QUEUED    = "queued"
    SENT      = "sent"
    DELIVERED = "delivered"
    FAILED    = "failed"
    CANCELLED = "cancelled"


class InterventionS5StatusEnum(str, enum.Enum):
    RECOMMENDED = "recommended"
    SCHEDULED   = "scheduled"
    IN_PROGRESS = "in_progress"
    COMPLETED   = "completed"
    CANCELLED   = "cancelled"
    NO_RESPONSE = "no_response"


class ReportFormatEnum(str, enum.Enum):
    JSON  = "json"
    CSV   = "csv"
    PDF   = "pdf"
    EXCEL = "excel"


# ─────────────────────────────────────────────────────────────────────────────
# MODULE A: CONFIGURATION CENTER
# ─────────────────────────────────────────────────────────────────────────────

class SystemConfigCategory(Base):
    __tablename__  = "system_config_categories"
    __table_args__ = {"extend_existing": True}

    id          = Column(BigInteger, primary_key=True)
    key         = Column(String(80),  nullable=False, unique=True)
    label       = Column(String(150), nullable=False)
    description = Column(Text)
    icon        = Column(String(50))
    sort_order  = Column(SmallInteger, default=0)
    is_active   = Column(Boolean, default=True)
    created_at  = Column(DateTime(timezone=True), server_default=func.now())
    updated_at  = Column(DateTime(timezone=True), server_default=func.now())

    settings = relationship("SystemConfigSetting", back_populates="category", cascade="all, delete-orphan")


class SystemConfigSetting(Base):
    __tablename__  = "system_config_settings"
    __table_args__ = {"extend_existing": True}

    id               = Column(BigInteger, primary_key=True)
    category_id      = Column(BigInteger, ForeignKey("system_config_categories.id", ondelete="CASCADE"))
    key              = Column(String(120), nullable=False, unique=True)
    label            = Column(String(200), nullable=False)
    description      = Column(Text)
    data_type        = Column(
        Enum(ConfigDataTypeEnum, values_callable=_v, name="config_data_type"),
        nullable=False, default=ConfigDataTypeEnum.STRING
    )
    current_value    = Column(Text)
    default_value    = Column(Text)
    min_value        = Column(Text)
    max_value        = Column(Text)
    allowed_values   = Column(JSONB)
    is_required      = Column(Boolean, default=False)
    is_sensitive     = Column(Boolean, default=False)
    requires_restart = Column(Boolean, default=False)
    program_id       = Column(BigInteger, ForeignKey("academic_programs.id", ondelete="CASCADE"))
    sort_order       = Column(SmallInteger, default=0)
    created_at       = Column(DateTime(timezone=True), server_default=func.now())
    updated_at       = Column(DateTime(timezone=True), server_default=func.now())
    updated_by       = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))

    category = relationship("SystemConfigCategory", back_populates="settings")
    audit_log = relationship("SystemConfigAudit", back_populates="setting", cascade="all, delete-orphan")


class SystemConfigAudit(Base):
    __tablename__  = "system_config_audit"
    __table_args__ = {"extend_existing": True}

    id            = Column(BigInteger, primary_key=True)
    setting_id    = Column(BigInteger, ForeignKey("system_config_settings.id", ondelete="CASCADE"))
    setting_key   = Column(String(120), nullable=False)
    old_value     = Column(Text)
    new_value     = Column(Text)
    changed_by    = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    change_reason = Column(Text)
    rollback_of   = Column(BigInteger, ForeignKey("system_config_audit.id", ondelete="SET NULL"))
    created_at    = Column(DateTime(timezone=True), server_default=func.now())

    setting = relationship("SystemConfigSetting", back_populates="audit_log")


# ─────────────────────────────────────────────────────────────────────────────
# MODULE B: WORKFLOW ENGINE EXTENSIONS
# ─────────────────────────────────────────────────────────────────────────────

class WorkflowTemplate(Base):
    __tablename__  = "workflow_templates"
    __table_args__ = {"extend_existing": True}

    id             = Column(BigInteger, primary_key=True)
    name           = Column(String(150), nullable=False)
    description    = Column(Text)
    case_type      = Column(String(80))
    is_active      = Column(Boolean, default=True)
    max_days_sla   = Column(SmallInteger)
    auto_escalate  = Column(Boolean, default=False)
    version        = Column(SmallInteger, default=1)
    created_by     = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    created_at     = Column(DateTime(timezone=True), server_default=func.now())
    updated_at     = Column(DateTime(timezone=True), server_default=func.now())

    steps     = relationship("WorkflowStep",     back_populates="template", cascade="all, delete-orphan")
    instances = relationship("WorkflowInstance", back_populates="template")


class WorkflowStep(Base):
    __tablename__  = "workflow_steps"
    __table_args__ = {"extend_existing": True}

    id                       = Column(BigInteger, primary_key=True)
    template_id              = Column(BigInteger, ForeignKey("workflow_templates.id", ondelete="CASCADE"))
    step_number              = Column(SmallInteger, nullable=False)
    name                     = Column(String(150),  nullable=False)
    step_type                = Column(
        Enum(WorkflowStepTypeEnum, values_callable=_v, name="workflow_step_type"),
        nullable=False
    )
    assigned_role            = Column(String(50))
    sla_hours                = Column(SmallInteger)
    auto_approve_after_hours = Column(SmallInteger)
    notification_template_key = Column(String(80))
    conditions               = Column(JSONB)
    actions                  = Column(JSONB)
    is_optional              = Column(Boolean, default=False)
    created_at               = Column(DateTime(timezone=True), server_default=func.now())

    template = relationship("WorkflowTemplate", back_populates="steps")


class WorkflowInstance(Base):
    __tablename__  = "workflow_instances"
    __table_args__ = {"extend_existing": True}

    id           = Column(BigInteger, primary_key=True)
    template_id  = Column(BigInteger, ForeignKey("workflow_templates.id", ondelete="SET NULL"))
    case_id      = Column(BigInteger, ForeignKey("academic_cases.id",     ondelete="CASCADE"))
    student_id   = Column(Integer,    ForeignKey("students.id",           ondelete="CASCADE"))
    current_step = Column(SmallInteger, default=1)
    status       = Column(
        Enum(WorkflowStatusEnum, values_callable=_v, name="workflow_status"),
        default=WorkflowStatusEnum.ACTIVE
    )
    metadata     = Column(JSONB)
    started_at   = Column(DateTime(timezone=True), server_default=func.now())
    due_at       = Column(DateTime(timezone=True))
    completed_at = Column(DateTime(timezone=True))
    created_by   = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    created_at   = Column(DateTime(timezone=True), server_default=func.now())
    updated_at   = Column(DateTime(timezone=True), server_default=func.now())

    template      = relationship("WorkflowTemplate",   back_populates="instances")
    step_instances = relationship("WorkflowStepInstance", back_populates="instance", cascade="all, delete-orphan")


class WorkflowStepInstance(Base):
    __tablename__  = "workflow_step_instances"
    __table_args__ = {"extend_existing": True}

    id                  = Column(BigInteger, primary_key=True)
    instance_id         = Column(BigInteger, ForeignKey("workflow_instances.id", ondelete="CASCADE"))
    step_id             = Column(BigInteger, ForeignKey("workflow_steps.id",     ondelete="SET NULL"))
    step_number         = Column(SmallInteger, nullable=False)
    step_name           = Column(String(150))
    assigned_to         = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    assigned_role       = Column(String(50))
    status              = Column(
        Enum(WorkflowStatusEnum, values_callable=_v, name="workflow_status"),
        default=WorkflowStatusEnum.ACTIVE
    )
    decision            = Column(String(50))
    notes               = Column(Text)
    started_at          = Column(DateTime(timezone=True))
    due_at              = Column(DateTime(timezone=True))
    completed_at        = Column(DateTime(timezone=True))
    response_time_hours = Column(Numeric(8, 2))
    created_at          = Column(DateTime(timezone=True), server_default=func.now())

    instance = relationship("WorkflowInstance", back_populates="step_instances")


class WorkflowSLARule(Base):
    __tablename__  = "workflow_sla_rules"
    __table_args__ = {"extend_existing": True}

    id               = Column(BigInteger, primary_key=True)
    case_type        = Column(String(80))
    role             = Column(String(50))
    max_hours        = Column(SmallInteger, nullable=False)
    escalate_to_role = Column(String(50))
    is_active        = Column(Boolean, default=True)
    created_at       = Column(DateTime(timezone=True), server_default=func.now())


# ─────────────────────────────────────────────────────────────────────────────
# MODULE C: ACADEMIC CALENDAR ENGINE
# ─────────────────────────────────────────────────────────────────────────────

class AcademicYear(Base):
    __tablename__  = "academic_years"
    __table_args__ = {"extend_existing": True}

    id         = Column(BigInteger, primary_key=True)
    label      = Column(String(50), nullable=False, unique=True)
    start_date = Column(Date, nullable=False)
    end_date   = Column(Date, nullable=False)
    is_current = Column(Boolean, default=False)
    is_active  = Column(Boolean, default=True)
    notes      = Column(Text)
    created_by = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now())

    events   = relationship("CalendarEvent",   back_populates="academic_year", cascade="all, delete-orphan")
    versions = relationship("CalendarVersion", back_populates="academic_year", cascade="all, delete-orphan")


class CalendarEvent(Base):
    __tablename__  = "calendar_events"
    __table_args__ = {"extend_existing": True}

    id                   = Column(BigInteger, primary_key=True)
    academic_year_id     = Column(BigInteger, ForeignKey("academic_years.id",      ondelete="CASCADE"))
    term_id              = Column(BigInteger, ForeignKey("academic_terms.id",      ondelete="SET NULL"))
    event_type           = Column(
        Enum(CalendarEventTypeEnum, values_callable=_v, name="calendar_event_type"),
        nullable=False
    )
    label                = Column(String(200), nullable=False)
    description          = Column(Text)
    start_date           = Column(Date, nullable=False)
    end_date             = Column(Date)
    affects_all_programs = Column(Boolean, default=True)
    program_id           = Column(BigInteger, ForeignKey("academic_programs.id", ondelete="CASCADE"))
    is_active            = Column(Boolean, default=True)
    metadata             = Column(JSONB)
    created_by           = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    created_at           = Column(DateTime(timezone=True), server_default=func.now())
    updated_at           = Column(DateTime(timezone=True), server_default=func.now())

    academic_year = relationship("AcademicYear", back_populates="events")
    audit_log     = relationship("CalendarAudit", back_populates="event", cascade="all, delete-orphan")


class CalendarVersion(Base):
    __tablename__  = "calendar_versions"
    __table_args__ = {"extend_existing": True}

    id               = Column(BigInteger, primary_key=True)
    academic_year_id = Column(BigInteger, ForeignKey("academic_years.id", ondelete="CASCADE"))
    version_number   = Column(SmallInteger, nullable=False)
    snapshot         = Column(JSONB, nullable=False)
    notes            = Column(Text)
    created_by       = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    created_at       = Column(DateTime(timezone=True), server_default=func.now())

    academic_year = relationship("AcademicYear", back_populates="versions")


class CalendarAudit(Base):
    __tablename__  = "calendar_audit"
    __table_args__ = {"extend_existing": True}

    id         = Column(BigInteger, primary_key=True)
    event_id   = Column(BigInteger, ForeignKey("calendar_events.id", ondelete="CASCADE"))
    action     = Column(String(50), nullable=False)
    old_data   = Column(JSONB)
    new_data   = Column(JSONB)
    changed_by = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    event = relationship("CalendarEvent", back_populates="audit_log")


# ─────────────────────────────────────────────────────────────────────────────
# MODULE D: STUDENT SUCCESS PLATFORM
# ─────────────────────────────────────────────────────────────────────────────

class StudentEarlyWarning(Base):
    __tablename__  = "student_early_warnings"
    __table_args__ = {"extend_existing": True}

    id               = Column(BigInteger, primary_key=True)
    student_id       = Column(Integer, ForeignKey("students.id", ondelete="CASCADE"), nullable=False)
    warning_type     = Column(
        Enum(WarningTypeEnum, values_callable=_v, name="warning_type"), nullable=False
    )
    severity         = Column(
        Enum(WarningSeverityEnum, values_callable=_v, name="warning_severity"),
        nullable=False, default=WarningSeverityEnum.WARNING
    )
    status           = Column(
        Enum(WarningStatusEnum, values_callable=_v, name="warning_status"),
        nullable=False, default=WarningStatusEnum.ACTIVE
    )
    title            = Column(String(200), nullable=False)
    description      = Column(Text)
    triggered_value  = Column(Numeric(8, 3))
    threshold_value  = Column(Numeric(8, 3))
    term_id          = Column(BigInteger, ForeignKey("academic_terms.id",  ondelete="SET NULL"))
    course_id        = Column(Integer,    ForeignKey("courses.id",          ondelete="SET NULL"))
    auto_generated   = Column(Boolean, default=True)
    acknowledged_by  = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    acknowledged_at  = Column(DateTime(timezone=True))
    resolved_at      = Column(DateTime(timezone=True))
    resolution_notes = Column(Text)
    metadata         = Column(JSONB)
    created_at       = Column(DateTime(timezone=True), server_default=func.now())
    updated_at       = Column(DateTime(timezone=True), server_default=func.now())

    escalations   = relationship("StudentEscalation",    back_populates="warning")
    interventions = relationship("StudentInterventionS5", back_populates="warning")


class StudentSuccessScore(Base):
    __tablename__  = "student_success_scores"
    __table_args__ = {"extend_existing": True}

    id                      = Column(BigInteger, primary_key=True)
    student_id              = Column(Integer, ForeignKey("students.id", ondelete="CASCADE"), nullable=False)
    term_id                 = Column(BigInteger, ForeignKey("academic_terms.id", ondelete="SET NULL"))
    score                   = Column(Numeric(5, 2), nullable=False)
    band                    = Column(
        Enum(SuccessScoreBandEnum, values_callable=_v, name="success_score_band"), nullable=False
    )
    cgpa_score              = Column(Numeric(5, 2), default=0)
    attendance_score        = Column(Numeric(5, 2), default=0)
    course_completion_score = Column(Numeric(5, 2), default=0)
    progress_score          = Column(Numeric(5, 2), default=0)
    risk_score              = Column(Numeric(5, 2), default=0)
    active_warnings         = Column(SmallInteger, default=0)
    active_interventions    = Column(SmallInteger, default=0)
    trend                   = Column(String(20), default="stable")
    notes                   = Column(Text)
    computed_at             = Column(DateTime(timezone=True), server_default=func.now())
    created_at              = Column(DateTime(timezone=True), server_default=func.now())


class GraduationReadinessCache(Base):
    __tablename__  = "graduation_readiness_cache"
    __table_args__ = {"extend_existing": True}

    id                     = Column(BigInteger, primary_key=True)
    student_id             = Column(Integer, ForeignKey("students.id", ondelete="CASCADE"), unique=True)
    readiness_pct          = Column(Numeric(5, 2), default=0)
    status                 = Column(
        Enum(ReadinessStatusEnum, values_callable=_v, name="readiness_status"),
        default=ReadinessStatusEnum.NOT_ELIGIBLE
    )
    total_required_credits = Column(SmallInteger, default=0)
    completed_credits      = Column(SmallInteger, default=0)
    remaining_credits      = Column(SmallInteger, default=0)
    total_required_courses = Column(SmallInteger, default=0)
    completed_courses      = Column(SmallInteger, default=0)
    missing_required       = Column(JSONB)
    cgpa_eligible          = Column(Boolean, default=False)
    uc_requirements_met    = Column(Boolean, default=False)
    pending_issues         = Column(JSONB)
    estimated_graduation_term = Column(String(20))
    computed_at            = Column(DateTime(timezone=True), server_default=func.now())


class StudentInterventionS5(Base):
    __tablename__  = "student_interventions_s5"
    __table_args__ = {"extend_existing": True}

    id                  = Column(BigInteger, primary_key=True)
    student_id          = Column(Integer, ForeignKey("students.id",                 ondelete="CASCADE"))
    warning_id          = Column(BigInteger, ForeignKey("student_early_warnings.id", ondelete="SET NULL"))
    assigned_to         = Column(Integer, ForeignKey("users.id",                    ondelete="SET NULL"))
    status              = Column(
        Enum(InterventionS5StatusEnum, values_callable=_v, name="intervention_s5_status"),
        default=InterventionS5StatusEnum.RECOMMENDED
    )
    intervention_type   = Column(String(80), nullable=False)
    title               = Column(String(200), nullable=False)
    description         = Column(Text)
    recommendations     = Column(JSONB)
    target_gpa          = Column(Numeric(4, 3))
    target_cgpa         = Column(Numeric(4, 3))
    marks_needed        = Column(JSONB)
    required_next_gpa   = Column(Numeric(4, 3))
    graduation_path     = Column(JSONB)
    priority            = Column(String(20), default="medium")
    due_date            = Column(Date)
    completed_at        = Column(DateTime(timezone=True))
    outcome             = Column(Text)
    created_by          = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    created_at          = Column(DateTime(timezone=True), server_default=func.now())
    updated_at          = Column(DateTime(timezone=True), server_default=func.now())

    warning = relationship("StudentEarlyWarning", back_populates="interventions")
    notes   = relationship("AdvisorInterventionNote", back_populates="intervention", cascade="all, delete-orphan")
    escalations = relationship("StudentEscalation", back_populates="intervention")


class StudentEscalation(Base):
    __tablename__  = "student_escalations"
    __table_args__ = {"extend_existing": True}

    id                  = Column(BigInteger, primary_key=True)
    student_id          = Column(Integer, ForeignKey("students.id",                  ondelete="CASCADE"))
    warning_id          = Column(BigInteger, ForeignKey("student_early_warnings.id",  ondelete="SET NULL"))
    intervention_id     = Column(BigInteger, ForeignKey("student_interventions_s5.id", ondelete="SET NULL"))
    from_level          = Column(
        Enum(EscalationLevelEnum, values_callable=_v, name="escalation_level"), nullable=False
    )
    to_level            = Column(
        Enum(EscalationLevelEnum, values_callable=_v, name="escalation_level"), nullable=False
    )
    reason              = Column(Text, nullable=False)
    status              = Column(
        Enum(EscalationStatusEnum, values_callable=_v, name="escalation_status"),
        default=EscalationStatusEnum.PENDING
    )
    escalated_by        = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    assigned_to         = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    response_notes      = Column(Text)
    responded_at        = Column(DateTime(timezone=True))
    resolved_at         = Column(DateTime(timezone=True))
    response_time_hours = Column(Numeric(8, 2))
    metadata            = Column(JSONB)
    created_at          = Column(DateTime(timezone=True), server_default=func.now())
    updated_at          = Column(DateTime(timezone=True), server_default=func.now())

    warning      = relationship("StudentEarlyWarning",   back_populates="escalations")
    intervention = relationship("StudentInterventionS5", back_populates="escalations")


class AdvisorInterventionNote(Base):
    __tablename__  = "advisor_intervention_notes"
    __table_args__ = {"extend_existing": True}

    id              = Column(BigInteger, primary_key=True)
    intervention_id = Column(BigInteger, ForeignKey("student_interventions_s5.id", ondelete="CASCADE"))
    student_id      = Column(Integer,    ForeignKey("students.id",                 ondelete="CASCADE"))
    author_id       = Column(Integer,    ForeignKey("users.id",                    ondelete="SET NULL"))
    note_type       = Column(String(50), default="general")
    content         = Column(Text, nullable=False)
    is_private      = Column(Boolean, default=False)
    created_at      = Column(DateTime(timezone=True), server_default=func.now())
    updated_at      = Column(DateTime(timezone=True), server_default=func.now())

    intervention = relationship("StudentInterventionS5", back_populates="notes")


class AdvisorMeeting(Base):
    __tablename__  = "advisor_meetings"
    __table_args__ = {"extend_existing": True}

    id               = Column(BigInteger, primary_key=True)
    student_id       = Column(Integer, ForeignKey("students.id",                  ondelete="CASCADE"))
    advisor_id       = Column(Integer, ForeignKey("users.id",                     ondelete="SET NULL"))
    intervention_id  = Column(BigInteger, ForeignKey("student_interventions_s5.id", ondelete="SET NULL"))
    meeting_type     = Column(String(50), default="in_person")
    scheduled_at     = Column(DateTime(timezone=True), nullable=False)
    duration_minutes = Column(SmallInteger)
    status           = Column(String(30), default="scheduled")
    notes            = Column(Text)
    outcomes         = Column(JSONB)
    follow_up_date   = Column(Date)
    created_at       = Column(DateTime(timezone=True), server_default=func.now())
    updated_at       = Column(DateTime(timezone=True), server_default=func.now())


# ─────────────────────────────────────────────────────────────────────────────
# MODULE E: NOTIFICATION INFRASTRUCTURE
# ─────────────────────────────────────────────────────────────────────────────

class NotificationTemplate(Base):
    __tablename__  = "notification_templates"
    __table_args__ = {"extend_existing": True}

    id               = Column(BigInteger, primary_key=True)
    key              = Column(String(100), nullable=False, unique=True)
    name             = Column(String(200), nullable=False)
    channel          = Column(
        Enum(NotifChannelEnum, values_callable=_v, name="notif_channel"),
        nullable=False, default=NotifChannelEnum.IN_APP
    )
    subject_template = Column(Text)
    body_template    = Column(Text, nullable=False)
    variables        = Column(JSONB)
    is_active        = Column(Boolean, default=True)
    created_at       = Column(DateTime(timezone=True), server_default=func.now())
    updated_at       = Column(DateTime(timezone=True), server_default=func.now())


class NotificationQueue(Base):
    __tablename__  = "notification_queue"
    __table_args__ = {"extend_existing": True}

    id             = Column(BigInteger, primary_key=True)
    recipient_id   = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"))
    template_id    = Column(BigInteger, ForeignKey("notification_templates.id", ondelete="SET NULL"))
    channel        = Column(
        Enum(NotifChannelEnum, values_callable=_v, name="notif_channel"),
        nullable=False, default=NotifChannelEnum.IN_APP
    )
    subject        = Column(Text)
    body           = Column(Text, nullable=False)
    variables      = Column(JSONB)
    priority       = Column(String(20), default="normal")
    status         = Column(
        Enum(NotifDeliveryStatusEnum, values_callable=_v, name="notif_delivery_status"),
        default=NotifDeliveryStatusEnum.QUEUED
    )
    scheduled_at   = Column(DateTime(timezone=True), server_default=func.now())
    sent_at        = Column(DateTime(timezone=True))
    retry_count    = Column(SmallInteger, default=0)
    max_retries    = Column(SmallInteger, default=3)
    error_message  = Column(Text)
    related_entity = Column(String(50))
    related_id     = Column(BigInteger)
    created_at     = Column(DateTime(timezone=True), server_default=func.now())
    updated_at     = Column(DateTime(timezone=True), server_default=func.now())

    delivery_logs = relationship("NotificationDeliveryLog", back_populates="queue_item", cascade="all, delete-orphan")


class NotificationDeliveryLog(Base):
    __tablename__  = "notification_delivery_log"
    __table_args__ = {"extend_existing": True}

    id                  = Column(BigInteger, primary_key=True)
    queue_id            = Column(BigInteger, ForeignKey("notification_queue.id", ondelete="CASCADE"))
    channel             = Column(
        Enum(NotifChannelEnum, values_callable=_v, name="notif_channel"), nullable=False
    )
    status              = Column(
        Enum(NotifDeliveryStatusEnum, values_callable=_v, name="notif_delivery_status"), nullable=False
    )
    provider            = Column(String(50))
    provider_message_id = Column(String(200))
    error_details       = Column(Text)
    attempt_number      = Column(SmallInteger, default=1)
    attempted_at        = Column(DateTime(timezone=True), server_default=func.now())

    queue_item = relationship("NotificationQueue", back_populates="delivery_logs")


class NotificationPreference(Base):
    __tablename__  = "notification_preferences"
    __table_args__ = {"extend_existing": True}

    id                   = Column(BigInteger, primary_key=True)
    user_id              = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), unique=True)
    in_app_enabled       = Column(Boolean, default=True)
    email_enabled        = Column(Boolean, default=True)
    sms_enabled          = Column(Boolean, default=False)
    push_enabled         = Column(Boolean, default=False)
    warning_alerts       = Column(Boolean, default=True)
    intervention_alerts  = Column(Boolean, default=True)
    grade_alerts         = Column(Boolean, default=True)
    calendar_alerts      = Column(Boolean, default=True)
    digest_frequency     = Column(String(20), default="daily")
    quiet_hours_start    = Column(Time)
    quiet_hours_end      = Column(Time)
    created_at           = Column(DateTime(timezone=True), server_default=func.now())
    updated_at           = Column(DateTime(timezone=True), server_default=func.now())


# ─────────────────────────────────────────────────────────────────────────────
# MODULE F: SEED BATCHES
# ─────────────────────────────────────────────────────────────────────────────

class SeedBatch(Base):
    __tablename__  = "seed_batches"
    __table_args__ = {"extend_existing": True}

    id            = Column(BigInteger, primary_key=True)
    batch_key     = Column(String(80), nullable=False, unique=True)
    label         = Column(String(200))
    description   = Column(Text)
    student_count = Column(Integer, default=0)
    status        = Column(String(30), default="completed")
    metadata      = Column(JSONB)
    created_by    = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    created_at    = Column(DateTime(timezone=True), server_default=func.now())
    deleted_at    = Column(DateTime(timezone=True))

    members = relationship("SeedBatchMember", back_populates="batch", cascade="all, delete-orphan")


class SeedBatchMember(Base):
    __tablename__  = "seed_batch_members"
    __table_args__ = {"extend_existing": True}

    id          = Column(BigInteger, primary_key=True)
    batch_id    = Column(BigInteger, ForeignKey("seed_batches.id", ondelete="CASCADE"))
    entity_type = Column(String(30), nullable=False)
    entity_id   = Column(BigInteger, nullable=False)
    created_at  = Column(DateTime(timezone=True), server_default=func.now())

    batch = relationship("SeedBatch", back_populates="members")


# ─────────────────────────────────────────────────────────────────────────────
# MODULE G: REPORTING FOUNDATION
# ─────────────────────────────────────────────────────────────────────────────

class ReportDefinition(Base):
    __tablename__  = "report_definitions"
    __table_args__ = {"extend_existing": True}

    id           = Column(BigInteger, primary_key=True)
    key          = Column(String(100), nullable=False, unique=True)
    name         = Column(String(200), nullable=False)
    description  = Column(Text)
    report_type  = Column(String(80), nullable=False)
    query_config = Column(JSONB)
    default_format = Column(
        Enum(ReportFormatEnum, values_callable=_v, name="report_format"),
        default=ReportFormatEnum.JSON
    )
    is_active    = Column(Boolean, default=True)
    created_at   = Column(DateTime(timezone=True), server_default=func.now())
    updated_at   = Column(DateTime(timezone=True), server_default=func.now())

    runs = relationship("ReportRun", back_populates="definition")


class ReportRun(Base):
    __tablename__  = "report_runs"
    __table_args__ = {"extend_existing": True}

    id            = Column(BigInteger, primary_key=True)
    definition_id = Column(BigInteger, ForeignKey("report_definitions.id", ondelete="SET NULL"))
    report_key    = Column(String(100))
    parameters    = Column(JSONB)
    format        = Column(
        Enum(ReportFormatEnum, values_callable=_v, name="report_format"),
        default=ReportFormatEnum.JSON
    )
    status        = Column(String(30), default="running")
    result_data   = Column(JSONB)
    row_count     = Column(Integer)
    requested_by  = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    started_at    = Column(DateTime(timezone=True), server_default=func.now())
    completed_at  = Column(DateTime(timezone=True))
    error_message = Column(Text)
    created_at    = Column(DateTime(timezone=True), server_default=func.now())

    definition = relationship("ReportDefinition", back_populates="runs")


# ─────────────────────────────────────────────────────────────────────────────
# MODULE H: RETENTION ANALYTICS
# ─────────────────────────────────────────────────────────────────────────────

class RetentionSnapshot(Base):
    __tablename__  = "retention_snapshots"
    __table_args__ = {"extend_existing": True}

    id                      = Column(BigInteger, primary_key=True)
    snapshot_date           = Column(Date, nullable=False)
    term_id                 = Column(BigInteger, ForeignKey("academic_terms.id",      ondelete="SET NULL"))
    program_id              = Column(BigInteger, ForeignKey("academic_programs.id",   ondelete="SET NULL"))
    total_students          = Column(Integer, default=0)
    active_students         = Column(Integer, default=0)
    below_2_cgpa            = Column(Integer, default=0)
    between_2_and_2_5_cgpa  = Column(Integer, default=0)
    above_2_5_cgpa          = Column(Integer, default=0)
    dismissal_risk_count    = Column(Integer, default=0)
    probation_count         = Column(Integer, default=0)
    expected_graduates      = Column(Integer, default=0)
    graduation_delay_count  = Column(Integer, default=0)
    critical_warnings_count = Column(Integer, default=0)
    avg_success_score       = Column(Numeric(5, 2))
    avg_cgpa                = Column(Numeric(4, 3))
    retention_rate          = Column(Numeric(5, 2))
    metadata                = Column(JSONB)
    created_at              = Column(DateTime(timezone=True), server_default=func.now())
