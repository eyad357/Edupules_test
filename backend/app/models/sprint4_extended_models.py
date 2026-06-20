"""
EduGuard AI — Sprint 4 Extended Models
=======================================
Additional tables for:
  - ScholarshipEvaluation   (Scholarship Eligibility Engine)
  - GPAVersion              (GPA Versioning Engine)
  - AcademicAchievement     (Academic Achievement Registry)
  - GPAExplanation          (GPA Audit Explainability Engine)

Append to sprint4_models.py imports and Base.
"""

from sqlalchemy import (
    Column, Integer, SmallInteger, BigInteger, String, Text, Boolean,
    Numeric, DateTime, ForeignKey, Enum, Index,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.database import Base
import enum


def _vals(e):
    return [m.value for m in e]


# ═════════════════════════════════════════════════════════════════════════════
# SCHOLARSHIP EVALUATIONS
# ═════════════════════════════════════════════════════════════════════════════

class ScholarshipStatusEnum(str, enum.Enum):
    ELIGIBLE     = "eligible"
    NOT_ELIGIBLE = "not_eligible"
    PENDING_RULES = "pending_policy_configuration"


class ScholarshipEvaluation(Base):
    """
    Scholarship eligibility evaluations.

    POLICY NOTE: All scholarship thresholds (min CGPA, min credits,
    no-fail requirement, etc.) are sourced from AcademicRulesConfig.
    Until the university uploads scholarship regulations, evaluations
    will return status='pending_policy_configuration'.
    """
    __tablename__  = "scholarship_evaluations"
    __table_args__ = (
        Index("idx_scholarship_student", "student_id"),
        {"extend_existing": True},
    )

    id                   = Column(BigInteger, primary_key=True, index=True)
    student_id           = Column(Integer, ForeignKey("students.id", ondelete="CASCADE"), nullable=False)
    term_id              = Column(BigInteger, ForeignKey("academic_terms.id", ondelete="SET NULL"), nullable=True)

    status               = Column(
        Enum(ScholarshipStatusEnum, values_callable=_vals, name="scholarship_status"),
        nullable=False, default=ScholarshipStatusEnum.PENDING_RULES
    )

    # Captured values at evaluation time
    cgpa_at_evaluation       = Column(Numeric(4, 3))
    credits_at_evaluation    = Column(SmallInteger)
    term_gpa_at_evaluation   = Column(Numeric(4, 3))

    # What rules were checked (JSONB — preserves the exact thresholds used)
    rules_applied        = Column(JSONB, default=dict)
    # Example: {"min_cgpa": "PENDING_POLICY_CONFIGURATION", "min_credits": "PENDING_POLICY_CONFIGURATION"}

    criteria_met         = Column(JSONB, default=dict)
    # Example: {"cgpa_requirement": false, "no_fail_requirement": true}

    unmet_criteria       = Column(JSONB, default=list)
    # Example: ["CGPA requirement: policy not yet configured"]

    policy_gaps          = Column(JSONB, default=list)
    # Rules that returned PENDING — list of rule_key strings

    notes                = Column(Text)
    evaluated_by         = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    evaluated_at         = Column(DateTime(timezone=True), server_default=func.now())
    is_current           = Column(Boolean, default=True)

    student = relationship("Student", foreign_keys=[student_id])


# ═════════════════════════════════════════════════════════════════════════════
# GPA VERSIONS
# ═════════════════════════════════════════════════════════════════════════════

class GPAVersion(Base):
    """
    Immutable GPA version record created every time a GPA value changes.
    Supports: historical GPA lookup, audit, "what changed my GPA" queries.
    """
    __tablename__  = "gpa_versions"
    __table_args__ = (
        Index("idx_gpa_version_student", "student_id"),
        {"extend_existing": True},
    )

    id                  = Column(BigInteger, primary_key=True, index=True)
    student_id          = Column(Integer, ForeignKey("students.id", ondelete="CASCADE"), nullable=False)
    term_id             = Column(BigInteger, ForeignKey("academic_terms.id", ondelete="SET NULL"), nullable=True)
    version_number      = Column(Integer, nullable=False, default=1)

    # The GPA values at this version
    semester_gpa        = Column(Numeric(4, 3))
    cgpa                = Column(Numeric(4, 3))
    total_hours_attempted = Column(SmallInteger, default=0)
    total_hours_earned  = Column(SmallInteger, default=0)
    total_quality_points = Column(Numeric(8, 3), default=0)

    # Delta from previous version
    cgpa_delta          = Column(Numeric(5, 4))      # positive = improved, negative = dropped
    gpa_delta           = Column(Numeric(5, 4))

    # What triggered this version
    trigger_event       = Column(String(100))
    # e.g. "grade_posted:CSE112", "grade_changed:MAT131", "term_finalized:2024-S1"

    trigger_details     = Column(JSONB, default=dict)
    repeat_policy_used  = Column(String(30), default="all_attempts")

    # Audit
    computed_by         = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    recorded_at         = Column(DateTime(timezone=True), server_default=func.now())

    student = relationship("Student", foreign_keys=[student_id])


# ═════════════════════════════════════════════════════════════════════════════
# ACADEMIC ACHIEVEMENTS
# ═════════════════════════════════════════════════════════════════════════════

class AchievementCategoryEnum(str, enum.Enum):
    ACADEMIC_STANDING   = "academic_standing"
    COURSE_COMPLETION   = "course_completion"
    GPA_MILESTONE       = "gpa_milestone"
    DEGREE_PROGRESS     = "degree_progress"
    TRANSCRIPT          = "transcript"
    SYSTEM              = "system"
    # Honors/Dean's List categories kept separate from PENDING thresholds
    # — these are triggered only when the relevant rule is NOT pending


class AcademicAchievement(Base):
    """
    Academic Achievement Registry.
    Records concrete, observable academic milestones.

    POLICY NOTE: Achievements that depend on configurable thresholds
    (Dean's List, Honors, Scholarship) are only recorded once the
    corresponding AcademicRulesConfig entries are configured
    (i.e., not PENDING_POLICY_CONFIGURATION).
    """
    __tablename__  = "academic_achievements"
    __table_args__ = (
        Index("idx_achievement_student", "student_id"),
        {"extend_existing": True},
    )

    id              = Column(BigInteger, primary_key=True, index=True)
    student_id      = Column(Integer, ForeignKey("students.id", ondelete="CASCADE"), nullable=False)
    term_id         = Column(BigInteger, ForeignKey("academic_terms.id", ondelete="SET NULL"), nullable=True)

    category        = Column(
        Enum(AchievementCategoryEnum, values_callable=_vals, name="achievement_category"),
        nullable=False
    )
    title           = Column(String(200), nullable=False)
    description     = Column(Text)

    # Achievement data snapshot (what metric triggered it)
    metric_key      = Column(String(80))    # e.g. "cgpa", "term_gpa", "credits_earned"
    metric_value    = Column(String(50))    # e.g. "3.50", "134"
    threshold_used  = Column(String(50))    # the exact threshold rule_value used
    rule_key_used   = Column(String(80))    # the AcademicRulesConfig key that fired
    policy_sourced  = Column(Boolean, default=True)  # False if threshold was PENDING

    achieved_at     = Column(DateTime(timezone=True), server_default=func.now())
    awarded_by      = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))

    student = relationship("Student", foreign_keys=[student_id])


# ═════════════════════════════════════════════════════════════════════════════
# GPA EXPLANATIONS
# ═════════════════════════════════════════════════════════════════════════════

class GPAExplanation(Base):
    """
    GPA Audit Explainability Engine.
    Provides a full, human-readable breakdown of exactly how the CGPA was computed.
    Every line item is traceable to a specific course attempt row.
    """
    __tablename__  = "gpa_explanations"
    __table_args__ = (
        Index("idx_gpa_expl_student", "student_id"),
        {"extend_existing": True},
    )

    id                  = Column(BigInteger, primary_key=True, index=True)
    student_id          = Column(Integer, ForeignKey("students.id", ondelete="CASCADE"), nullable=False)
    term_id             = Column(BigInteger, ForeignKey("academic_terms.id", ondelete="SET NULL"), nullable=True)

    # Formula used (from AcademicRulesConfig)
    formula_description = Column(Text, nullable=False)
    # e.g. "CGPA = Σ(grade_points × credit_hours) / Σ(credit_hours attempted)"

    repeat_policy       = Column(String(30), nullable=False)
    # Sourced from: repeat_policy rule in AcademicRulesConfig

    # Line-item breakdown (JSONB — one entry per course attempt included in CGPA)
    included_attempts   = Column(JSONB, default=list)
    # [{"course_code":"CSE132","term":"2023-S1","grade":"B-","pts":2.7,"ch":3,"contribution":8.1}, ...]

    # Excluded attempts with reason
    excluded_attempts   = Column(JSONB, default=list)
    # [{"course_code":"LAN021","grade":"P","ch":0,"reason":"Pass/Fail excluded from CGPA"}, ...]

    # Totals
    total_quality_points = Column(Numeric(8, 3))
    total_hours_attempted = Column(SmallInteger)
    computed_cgpa        = Column(Numeric(4, 3))

    # Semester-specific (if term_id provided)
    semester_quality_points  = Column(Numeric(8, 3))
    semester_hours_attempted = Column(SmallInteger)
    computed_semester_gpa    = Column(Numeric(4, 3))

    # Policy sourcing flags
    all_rules_sourced    = Column(Boolean, default=True)
    # False if any rule used was PENDING_POLICY_CONFIGURATION

    policy_notes         = Column(JSONB, default=list)
    # Any PENDING rules that affected this calculation

    generated_at         = Column(DateTime(timezone=True), server_default=func.now())
    is_current           = Column(Boolean, default=True)

    student = relationship("Student", foreign_keys=[student_id])
