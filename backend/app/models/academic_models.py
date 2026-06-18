"""
EduGuard AI — Sprint 1: Academic Foundation Models
SQLAlchemy ORM models for the academic structure layer.
These models extend the existing models.py — import both files.
"""

from sqlalchemy import (
    Column, Integer, SmallInteger, BigInteger, String, Text, Boolean,
    Numeric, Date, DateTime, ForeignKey, Enum, UniqueConstraint,
    CheckConstraint, Index
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.database import Base
import enum


# ── Enums ─────────────────────────────────────────────────────────────────────

class CourseCategoryEnum(str, enum.Enum):
    CORE                 = "core"
    ELECTIVE             = "elective"
    UNIVERSITY_REQ       = "university_req"
    UNIVERSITY_ELECTIVE  = "university_elective"
    FIELD_TRAINING       = "field_training"


class TermTypeEnum(str, enum.Enum):
    FALL   = "fall"
    SPRING = "spring"
    SUMMER = "summer"


class AttemptResultEnum(str, enum.Enum):
    PASSED      = "passed"
    FAILED      = "failed"
    WITHDRAWN   = "withdrawn"
    INCOMPLETE  = "incomplete"
    IN_PROGRESS = "in_progress"


class AdvisingPlanStatusEnum(str, enum.Enum):
    DRAFT            = "draft"
    SUBMITTED        = "submitted"
    ADVISOR_APPROVED = "advisor_approved"
    ADVISOR_REJECTED = "advisor_rejected"
    REGISTERED       = "registered"
    ARCHIVED         = "archived"


class ReqCategoryEnum(str, enum.Enum):
    CORE                 = "core"
    ELECTIVE             = "elective"
    UNIVERSITY_REQ       = "university_req"
    UNIVERSITY_ELECTIVE  = "university_elective"
    FIELD_TRAINING       = "field_training"
    GRADUATION_PROJECT   = "graduation_project"


class ImportStatusEnum(str, enum.Enum):
    PENDING    = "pending"
    PROCESSING = "processing"
    COMPLETED  = "completed"
    FAILED     = "failed"
    PARTIAL    = "partial"


# ── Helper ────────────────────────────────────────────────────────────────────
def _vals(e):
    return [m.value for m in e]


# ═════════════════════════════════════════════════════════════════════════════
# ACADEMIC PROGRAMS
# ═════════════════════════════════════════════════════════════════════════════

class AcademicProgram(Base):
    __tablename__  = "academic_programs"
    __table_args__ = {"extend_existing": True}

    id                  = Column(BigInteger, primary_key=True, index=True)
    department_id       = Column(BigInteger, ForeignKey("departments.id", ondelete="SET NULL"), nullable=True)
    code                = Column(String(20),  unique=True, nullable=False)
    name                = Column(String(150), nullable=False)
    name_ar             = Column(String(150))
    total_credit_hours  = Column(SmallInteger, default=134)
    min_cgpa_grad       = Column(Numeric(3, 2), default=2.00)
    duration_years      = Column(SmallInteger, default=4)
    is_active           = Column(Boolean, default=True)
    description         = Column(Text)
    created_at          = Column(DateTime(timezone=True), server_default=func.now())
    updated_at          = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    # Relationships
    tracks               = relationship("AcademicTrack",            back_populates="program")
    graduation_requirements = relationship("GraduationRequirement", back_populates="program")
    grade_scale          = relationship("GradeScale",               back_populates="program")


# ═════════════════════════════════════════════════════════════════════════════
# ACADEMIC TRACKS
# ═════════════════════════════════════════════════════════════════════════════

class AcademicTrack(Base):
    __tablename__  = "academic_tracks"
    __table_args__ = {"extend_existing": True}

    id          = Column(BigInteger, primary_key=True, index=True)
    program_id  = Column(BigInteger, ForeignKey("academic_programs.id", ondelete="CASCADE"), nullable=False)
    code        = Column(String(30),  unique=True, nullable=False)
    name        = Column(String(150), nullable=False)
    name_ar     = Column(String(150))
    is_active   = Column(Boolean, default=True)
    description = Column(Text)
    created_at  = Column(DateTime(timezone=True), server_default=func.now())
    updated_at  = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    program = relationship("AcademicProgram", back_populates="tracks")


# ═════════════════════════════════════════════════════════════════════════════
# ACADEMIC TERMS
# ═════════════════════════════════════════════════════════════════════════════

class AcademicTerm(Base):
    __tablename__  = "academic_terms"
    __table_args__ = {"extend_existing": True}

    id                  = Column(BigInteger, primary_key=True, index=True)
    code                = Column(String(20),  unique=True, nullable=False)
    name                = Column(String(80),  nullable=False)
    term_type           = Column(Enum(TermTypeEnum, values_callable=_vals, name="term_type"), nullable=False)
    academic_year       = Column(SmallInteger, nullable=False)
    start_date          = Column(Date)
    end_date            = Column(Date)
    registration_start  = Column(Date)
    registration_end    = Column(Date)
    is_active           = Column(Boolean, default=False)
    is_summer           = Column(Boolean, default=False)
    created_at          = Column(DateTime(timezone=True), server_default=func.now())
    updated_at          = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    # Relationships
    course_attempts  = relationship("StudentCourseAttempt", back_populates="term")
    course_offerings = relationship("CourseOffering",       back_populates="term")
    advising_plans   = relationship("AdvisingPlan",         back_populates="term")
    term_gpas        = relationship("StudentTermGPA",       back_populates="term")


# ═════════════════════════════════════════════════════════════════════════════
# COURSE PREREQUISITES
# ═════════════════════════════════════════════════════════════════════════════

class CoursePrerequisite(Base):
    __tablename__  = "course_prerequisites"
    __table_args__ = (
        UniqueConstraint("course_id", "prerequisite_id"),
        {"extend_existing": True},
    )

    id              = Column(BigInteger, primary_key=True, index=True)
    course_id       = Column(Integer, ForeignKey("courses.id", ondelete="CASCADE"), nullable=False)
    prerequisite_id = Column(Integer, ForeignKey("courses.id", ondelete="CASCADE"), nullable=False)
    prereq_type     = Column(String(10), default="hard")
    min_grade       = Column(Numeric(5, 2), default=60.00)
    # Logic grouping: prerequisites sharing the same logic_group are combined
    # using logic_type ("AND"/"OR"). Default group 1 + AND preserves the
    # original "all prerequisites required" behavior for existing rows.
    logic_group     = Column(SmallInteger, default=1)
    logic_type      = Column(String(5), default="AND")
    notes           = Column(Text)
    created_at      = Column(DateTime(timezone=True), server_default=func.now())

    course       = relationship("Course", foreign_keys=[course_id],       back_populates="prerequisites")
    prerequisite = relationship("Course", foreign_keys=[prerequisite_id], back_populates="is_prerequisite_for")


# ═════════════════════════════════════════════════════════════════════════════
# COURSE POST-REQUISITES
# ═════════════════════════════════════════════════════════════════════════════

class CoursePostrequisite(Base):
    __tablename__  = "course_postrequisites"
    __table_args__ = (
        UniqueConstraint("course_id", "postreq_id"),
        {"extend_existing": True},
    )

    id          = Column(BigInteger, primary_key=True, index=True)
    course_id   = Column(Integer, ForeignKey("courses.id", ondelete="CASCADE"), nullable=False)
    postreq_id  = Column(Integer, ForeignKey("courses.id", ondelete="CASCADE"), nullable=False)
    unlock_type = Column(String(5), default="C")
    notes       = Column(Text)
    created_at  = Column(DateTime(timezone=True), server_default=func.now())

    course     = relationship("Course", foreign_keys=[course_id],  back_populates="postrequisites")
    postreq    = relationship("Course", foreign_keys=[postreq_id], back_populates="is_postreq_for")


# ═════════════════════════════════════════════════════════════════════════════
# COURSE ELIGIBILITY RULES
# ═════════════════════════════════════════════════════════════════════════════

class CourseEligibilityRule(Base):
    __tablename__  = "course_eligibility_rules"
    __table_args__ = {"extend_existing": True}

    id           = Column(BigInteger, primary_key=True, index=True)
    course_id    = Column(Integer, ForeignKey("courses.id", ondelete="CASCADE"), nullable=False)
    rule_type    = Column(String(30), nullable=False)
    rule_value   = Column(Numeric(6, 2))
    rule_text    = Column(Text)
    is_mandatory = Column(Boolean, default=True)
    notes        = Column(Text)
    created_at   = Column(DateTime(timezone=True), server_default=func.now())

    course = relationship("Course", back_populates="eligibility_rules")


# ═════════════════════════════════════════════════════════════════════════════
# COURSE OFFERINGS
# ═════════════════════════════════════════════════════════════════════════════

class CourseOffering(Base):
    __tablename__  = "course_offerings"
    __table_args__ = (
        UniqueConstraint("course_id", "term_id", "section"),
        {"extend_existing": True},
    )

    id               = Column(BigInteger, primary_key=True, index=True)
    course_id        = Column(Integer,    ForeignKey("courses.id",      ondelete="CASCADE"),   nullable=False)
    term_id          = Column(BigInteger, ForeignKey("academic_terms.id", ondelete="CASCADE"), nullable=False)
    professor_id     = Column(Integer,    ForeignKey("professors.id",   ondelete="SET NULL"))
    section          = Column(String(20), default="A")
    max_capacity     = Column(SmallInteger, default=40)
    current_enrolled = Column(SmallInteger, default=0)
    room             = Column(String(50))
    schedule_json    = Column(JSONB)
    is_open          = Column(Boolean, default=True)
    notes            = Column(Text)
    created_at       = Column(DateTime(timezone=True), server_default=func.now())
    updated_at       = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    course    = relationship("Course",       back_populates="offerings")
    term      = relationship("AcademicTerm", back_populates="course_offerings")
    plan_items = relationship("AdvisingPlanItem", back_populates="offering")
    professor = relationship("Professor",back_populates="offerings"
)
# ═════════════════════════════════════════════════════════════════════════════
# STUDENT COURSE ATTEMPTS  (transcript layer)
# ═════════════════════════════════════════════════════════════════════════════

class StudentCourseAttempt(Base):
    __tablename__  = "student_course_attempts"
    __table_args__ = (
        UniqueConstraint("student_id", "course_id", "attempt_number"),
        {"extend_existing": True},
    )

    id                      = Column(BigInteger, primary_key=True, index=True)
    student_id              = Column(Integer,    ForeignKey("students.id",       ondelete="CASCADE"),  nullable=False)
    course_id               = Column(Integer,    ForeignKey("courses.id",        ondelete="CASCADE"),  nullable=False)
    term_id                 = Column(BigInteger, ForeignKey("academic_terms.id", ondelete="RESTRICT"), nullable=False)
    attempt_number          = Column(SmallInteger, nullable=False, default=1)
    numeric_grade           = Column(Numeric(5, 2))
    letter_grade            = Column(String(5))
    grade_points            = Column(Numeric(3, 2))
    credit_hours            = Column(SmallInteger, nullable=False, default=3)
    result                  = Column(
        Enum(AttemptResultEnum, values_callable=_vals, name="attempt_result"),
        nullable=False, default=AttemptResultEnum.IN_PROGRESS
    )
    is_improvement_attempt  = Column(Boolean, default=False)
    counts_in_cgpa          = Column(Boolean, default=True)
    registered_at           = Column(DateTime(timezone=True), server_default=func.now())
    grade_posted_at         = Column(DateTime(timezone=True))
    withdrawn_at            = Column(DateTime(timezone=True))
    graded_by               = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    notes                   = Column(Text)
    created_at              = Column(DateTime(timezone=True), server_default=func.now())
    updated_at              = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    student = relationship("Student", back_populates="course_attempts")
    course  = relationship("Course",  back_populates="student_attempts")
    term    = relationship("AcademicTerm", back_populates="course_attempts")


# ═════════════════════════════════════════════════════════════════════════════
# GRADE SCALE
# ═════════════════════════════════════════════════════════════════════════════

class GradeScale(Base):
    __tablename__  = "grade_scale"
    __table_args__ = (
        UniqueConstraint("program_id", "letter_grade"),
        {"extend_existing": True},
    )

    id             = Column(Integer, primary_key=True, index=True)
    program_id     = Column(BigInteger, ForeignKey("academic_programs.id", ondelete="CASCADE"))
    letter_grade   = Column(String(5),   nullable=False)
    min_percentage = Column(Numeric(5, 2))
    max_percentage = Column(Numeric(5, 2))
    grade_points   = Column(Numeric(3, 2), nullable=False)
    counts_in_cgpa = Column(Boolean, default=True)
    is_passing     = Column(Boolean, default=True)
    description    = Column(String(50))
    failure_type   = Column(String(20))

    program = relationship("AcademicProgram", back_populates="grade_scale")


# ═════════════════════════════════════════════════════════════════════════════
# STUDENT TERM GPA
# ═════════════════════════════════════════════════════════════════════════════

class StudentTermGPA(Base):
    __tablename__  = "student_term_gpa"
    __table_args__ = (
        UniqueConstraint("student_id", "term_id"),
        {"extend_existing": True},
    )

    id                          = Column(BigInteger, primary_key=True, index=True)
    student_id                  = Column(Integer,    ForeignKey("students.id",       ondelete="CASCADE"), nullable=False)
    term_id                     = Column(BigInteger, ForeignKey("academic_terms.id", ondelete="CASCADE"), nullable=False)
    term_credit_hours_attempted = Column(SmallInteger, default=0)
    term_credit_hours_earned    = Column(SmallInteger, default=0)
    term_quality_points         = Column(Numeric(8, 3), default=0)
    term_gpa                    = Column(Numeric(4, 3), default=0)
    cumulative_hours_attempted  = Column(SmallInteger, default=0)
    cumulative_hours_earned     = Column(SmallInteger, default=0)
    cumulative_quality_points   = Column(Numeric(8, 3), default=0)
    cgpa                        = Column(Numeric(4, 3), default=0)
    academic_standing           = Column(String(20), default="good")
    is_summer                   = Column(Boolean, default=False)
    finalized                   = Column(Boolean, default=False)
    finalized_at                = Column(DateTime(timezone=True))
    created_at                  = Column(DateTime(timezone=True), server_default=func.now())
    updated_at                  = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    student = relationship("Student",      back_populates="term_gpas")
    term    = relationship("AcademicTerm", back_populates="term_gpas")


# ═════════════════════════════════════════════════════════════════════════════
# GRADUATION REQUIREMENTS
# ═════════════════════════════════════════════════════════════════════════════

class GraduationRequirement(Base):
    __tablename__  = "graduation_requirements"
    __table_args__ = {"extend_existing": True}

    id               = Column(BigInteger, primary_key=True, index=True)
    program_id       = Column(BigInteger, ForeignKey("academic_programs.id", ondelete="CASCADE"), nullable=False)
    track_id         = Column(BigInteger, ForeignKey("academic_tracks.id",   ondelete="CASCADE"))
    category         = Column(Enum(ReqCategoryEnum, values_callable=_vals, name="req_category"), nullable=False)
    label            = Column(String(80),  nullable=False)
    required_credits = Column(SmallInteger, nullable=False)
    required_courses = Column(SmallInteger, default=0)
    min_cgpa         = Column(Numeric(3, 2), default=2.00)
    notes            = Column(Text)
    created_at       = Column(DateTime(timezone=True), server_default=func.now())
    updated_at       = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    program   = relationship("AcademicProgram", back_populates="graduation_requirements")
    progress  = relationship("StudentGraduationProgress", back_populates="requirement")


# ═════════════════════════════════════════════════════════════════════════════
# STUDENT GRADUATION PROGRESS
# ═════════════════════════════════════════════════════════════════════════════

class StudentGraduationProgress(Base):
    __tablename__  = "student_graduation_progress"
    __table_args__ = (
        UniqueConstraint("student_id", "requirement_id"),
        {"extend_existing": True},
    )

    id                 = Column(BigInteger, primary_key=True, index=True)
    student_id         = Column(Integer,    ForeignKey("students.id",               ondelete="CASCADE"), nullable=False)
    requirement_id     = Column(BigInteger, ForeignKey("graduation_requirements.id", ondelete="CASCADE"), nullable=False)
    credits_completed  = Column(SmallInteger, default=0)
    credits_remaining  = Column(SmallInteger, default=0)
    courses_completed  = Column(SmallInteger, default=0)
    courses_remaining  = Column(SmallInteger, default=0)
    completion_pct     = Column(Numeric(5, 2), default=0.00)
    last_computed_at   = Column(DateTime(timezone=True), server_default=func.now())

    student     = relationship("Student",               back_populates="graduation_progress")
    requirement = relationship("GraduationRequirement", back_populates="progress")


# ═════════════════════════════════════════════════════════════════════════════
# ADVISING PLANS
# ═════════════════════════════════════════════════════════════════════════════

class AdvisingPlan(Base):
    __tablename__  = "advising_plans"
    __table_args__ = {"extend_existing": True}

    id               = Column(BigInteger, primary_key=True, index=True)
    student_id       = Column(Integer,    ForeignKey("students.id",       ondelete="CASCADE"),  nullable=False)
    advisor_id       = Column(Integer,    ForeignKey("advisors.id",       ondelete="SET NULL"))
    term_id          = Column(BigInteger, ForeignKey("academic_terms.id", ondelete="RESTRICT"), nullable=False)
    status           = Column(
        Enum(AdvisingPlanStatusEnum, values_callable=_vals, name="advising_plan_status"),
        nullable=False, default=AdvisingPlanStatusEnum.DRAFT
    )
    total_credits    = Column(SmallInteger, default=0)
    max_credits      = Column(SmallInteger, default=18)
    is_ai_generated  = Column(Boolean, default=False)
    ai_model_version = Column(String(20))
    student_notes    = Column(Text)
    advisor_notes    = Column(Text)
    rejection_reason = Column(Text)
    submitted_at     = Column(DateTime(timezone=True))
    reviewed_at      = Column(DateTime(timezone=True))
    approved_at      = Column(DateTime(timezone=True))
    created_at       = Column(DateTime(timezone=True), server_default=func.now())
    updated_at       = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    student = relationship("Student",      back_populates="advising_plans")
    advisor = relationship("Advisor",      back_populates="advising_plans")
    term    = relationship("AcademicTerm", back_populates="advising_plans")
    items   = relationship("AdvisingPlanItem", back_populates="plan", cascade="all, delete-orphan")


# ═════════════════════════════════════════════════════════════════════════════
# ADVISING PLAN ITEMS
# ═════════════════════════════════════════════════════════════════════════════

class AdvisingPlanItem(Base):
    __tablename__  = "advising_plan_items"
    __table_args__ = {"extend_existing": True}

    id            = Column(BigInteger, primary_key=True, index=True)
    plan_id       = Column(BigInteger, ForeignKey("advising_plans.id",    ondelete="CASCADE"),  nullable=False)
    course_id     = Column(Integer,    ForeignKey("courses.id",           ondelete="CASCADE"),  nullable=False)
    offering_id   = Column(BigInteger, ForeignKey("course_offerings.id",  ondelete="SET NULL"))
    priority_rank = Column(SmallInteger, default=1)
    reason        = Column(String(50))
    is_mandatory  = Column(Boolean, default=False)
    notes         = Column(Text)
    created_at    = Column(DateTime(timezone=True), server_default=func.now())

    plan     = relationship("AdvisingPlan",   back_populates="items")
    course   = relationship("Course",         back_populates="plan_items")
    offering = relationship("CourseOffering", back_populates="plan_items")


# ═════════════════════════════════════════════════════════════════════════════
# IMPORT JOBS
# ═════════════════════════════════════════════════════════════════════════════

class ImportJob(Base):
    __tablename__  = "import_jobs"
    __table_args__ = {"extend_existing": True}

    id              = Column(BigInteger, primary_key=True, index=True)
    job_type        = Column(String(50),  nullable=False)
    status          = Column(
        Enum(ImportStatusEnum, values_callable=_vals, name="import_status"),
        nullable=False, default=ImportStatusEnum.PENDING
    )
    file_name       = Column(String(255))
    file_size_bytes = Column(BigInteger)
    total_rows      = Column(Integer, default=0)
    processed_rows  = Column(Integer, default=0)
    success_rows    = Column(Integer, default=0)
    error_rows      = Column(Integer, default=0)
    initiated_by    = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    started_at      = Column(DateTime(timezone=True))
    completed_at    = Column(DateTime(timezone=True))
    error_summary   = Column(Text)
    metadata_json   = Column(JSONB)
    created_at      = Column(DateTime(timezone=True), server_default=func.now())
    updated_at      = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    errors = relationship("ImportError", back_populates="job", cascade="all, delete-orphan")


class ImportError(Base):
    __tablename__  = "import_errors"
    __table_args__ = {"extend_existing": True}

    id            = Column(BigInteger, primary_key=True, index=True)
    job_id        = Column(BigInteger, ForeignKey("import_jobs.id", ondelete="CASCADE"), nullable=False)
    row_number    = Column(Integer)
    field_name    = Column(String(100))
    raw_value     = Column(Text)
    error_message = Column(Text)
    created_at    = Column(DateTime(timezone=True), server_default=func.now())

    job = relationship("ImportJob", back_populates="errors")
