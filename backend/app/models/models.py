"""
EduGuard AI — models.py (Sprint 1 updated)

Changes from original:
  - Course: added program_id, track_id, category, plan_semester, and all
    Sprint 1 curriculum columns; wired new relationships (prerequisites,
    postrequisites, offerings, student_attempts, plan_items,
    eligibility_rules).
  - Student: added program_id, track_id, cgpa tracking columns; wired
    course_attempts, term_gpas, advising_plans, graduation_progress.
  - Advisor: wired advising_plans relationship.
  - All existing relationships preserved unchanged.
"""

from sqlalchemy import (
    Column, Integer, SmallInteger, BigInteger, String, Float, Boolean,
    DateTime, Text, ForeignKey, Enum, Numeric, Index
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.database import Base
import enum


# ── Helper ────────────────────────────────────────────────────────────────────
def _vals(e):
    """Return enum member VALUES (lowercase strings) for SQLAlchemy Enum()."""
    return [m.value for m in e]


# ── Python Enums ──────────────────────────────────────────────────────────────
class UserRole(str, enum.Enum):
    STUDENT   = "student"
    PROFESSOR = "professor"
    ADVISOR   = "advisor"
    ADMIN     = "admin"
    TA        = "ta"

class RiskLevel(str, enum.Enum):
    NORMAL   = "Normal"
    LOW      = "Low"
    HIGH     = "High"
    CRITICAL = "Critical"

class InterventionStatus(str, enum.Enum):
    PENDING   = "pending"
    ACTIVE    = "active"
    COMPLETED = "completed"
    CANCELLED = "cancelled"

class Priority(str, enum.Enum):
    LOW    = "low"
    MEDIUM = "medium"
    HIGH   = "high"

class NotificationType(str, enum.Enum):
    RISK_ALERT   = "risk_alert"
    INTERVENTION = "intervention"
    QUIZ         = "quiz"
    GRADE        = "grade"
    SYSTEM       = "system"
    ATTENDANCE   = "attendance"


# ── Enum column factories ──────────────────────────────────────────────────────
def _role_col(**kw):
    return Column(Enum(UserRole, values_callable=_vals, name="user_role"), **kw)

def _risk_col(**kw):
    return Column(Enum(RiskLevel, values_callable=_vals, name="risk_level"), **kw)

def _istatus_col(**kw):
    return Column(Enum(InterventionStatus, values_callable=_vals, name="intervention_status"), **kw)

def _priority_col(**kw):
    return Column(Enum(Priority, values_callable=_vals, name="priority_level"), **kw)

def _notif_col(**kw):
    return Column(Enum(NotificationType, values_callable=_vals, name="notification_type"), **kw)


# ═════════════════════════════════════════════════════════════════════════════
# USER
# ═════════════════════════════════════════════════════════════════════════════
class User(Base):
    __tablename__  = "users"
    __table_args__ = {"extend_existing": True}

    id              = Column(Integer, primary_key=True, index=True)
    email           = Column(String(255), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    name            = Column(String(255), nullable=False)
    role            = _role_col(nullable=False)
    is_active       = Column(Boolean, default=True)
    created_at      = Column(DateTime(timezone=True), server_default=func.now())
    last_login      = Column(DateTime(timezone=True))

    student       = relationship("Student",      back_populates="user",    uselist=False)
    professor     = relationship("Professor",    back_populates="user",    uselist=False)
    advisor       = relationship("Advisor",      back_populates="user",    uselist=False)
    notifications = relationship("Notification", back_populates="user")
    audit_logs    = relationship("AuditLog",     back_populates="user")


# ═════════════════════════════════════════════════════════════════════════════
# STUDENT  (extended with Sprint 1 academic profile columns)
# ═════════════════════════════════════════════════════════════════════════════
class Student(Base):
    __tablename__  = "students"
    __table_args__ = (
        Index("idx_student_semester", "id", "enrollment_date"),
        {"extend_existing": True},
    )

    id              = Column(Integer, primary_key=True, index=True)
    user_id         = Column(Integer, ForeignKey("users.id"), unique=True)
    student_number  = Column(String(50), unique=True, index=True)
    major           = Column(String(100))
    year            = Column(Integer)
    gpa             = Column(Float, default=0.0)          # legacy column, kept for monitoring system
    enrollment_date = Column(DateTime(timezone=True))

    # ── Sprint 1: Academic profile ──────────────────────────────────────────
    program_id              = Column(BigInteger, ForeignKey("academic_programs.id", ondelete="SET NULL"))
    track_id                = Column(BigInteger, ForeignKey("academic_tracks.id",   ondelete="SET NULL"))
    admission_term_id       = Column(BigInteger, ForeignKey("academic_terms.id",    ondelete="SET NULL"))
    expected_grad_term_id   = Column(BigInteger, ForeignKey("academic_terms.id",    ondelete="SET NULL"))
    academic_level          = Column(SmallInteger)

    # CGPA tracking (4.0 scale, calculated from student_course_attempts)
    cgpa                            = Column(Numeric(4, 3), default=0.000)
    total_credit_hours_attempted    = Column(SmallInteger, default=0)
    total_credit_hours_earned       = Column(SmallInteger, default=0)
    total_quality_points            = Column(Numeric(8, 3), default=0.000)
    academic_standing               = Column(String(20), default="good")
    is_eligible_for_graduation      = Column(Boolean, default=False)

    # ── Existing relationships ──────────────────────────────────────────────
    user               = relationship("User",               back_populates="student")
    enrollments        = relationship("Enrollment",         back_populates="student")
    attendances        = relationship("Attendance",         back_populates="student")
    activity_logs      = relationship("ActivityLog",        back_populates="student")
    risk_assessments   = relationship("RiskAssessment",     back_populates="student")
    intervention_plans = relationship("InterventionPlan",   back_populates="student")
    quiz_submissions   = relationship("QuizSubmission",     back_populates="student")

    # ── Sprint 1: new relationships ────────────────────────────────────────
    course_attempts     = relationship("StudentCourseAttempt",     back_populates="student")
    term_gpas           = relationship("StudentTermGPA",           back_populates="student")
    advising_plans      = relationship("AdvisingPlan",             back_populates="student")
    graduation_progress = relationship("StudentGraduationProgress",back_populates="student")


# ═════════════════════════════════════════════════════════════════════════════
# PROFESSOR
# ═════════════════════════════════════════════════════════════════════════════
class Professor(Base):
    __tablename__  = "professors"
    __table_args__ = {"extend_existing": True}

    id         = Column(Integer, primary_key=True, index=True)
    user_id    = Column(Integer, ForeignKey("users.id"), unique=True)
    department = Column(String(100))
    title      = Column(String(50))

    user     = relationship("User",           back_populates="professor")
    courses  = relationship("Course",         back_populates="professor")
    offerings = relationship("CourseOffering", back_populates="professor")


# ═════════════════════════════════════════════════════════════════════════════
# ADVISOR  (extended with advising_plans relationship)
# ═════════════════════════════════════════════════════════════════════════════
class Advisor(Base):
    __tablename__  = "advisors"
    __table_args__ = {"extend_existing": True}

    id             = Column(Integer, primary_key=True, index=True)
    user_id        = Column(Integer, ForeignKey("users.id"), unique=True)
    specialization = Column(String(100))
    max_students   = Column(Integer, default=30)

    user               = relationship("User",               back_populates="advisor")
    intervention_plans = relationship("InterventionPlan",   back_populates="advisor")
    advising_plans     = relationship("AdvisingPlan",       back_populates="advisor")  # Sprint 1


# ═════════════════════════════════════════════════════════════════════════════
# COURSE  (extended with Sprint 1 curriculum columns + relationships)
# ═════════════════════════════════════════════════════════════════════════════
class Course(Base):
    __tablename__  = "courses"
    __table_args__ = {"extend_existing": True}

    id           = Column(Integer,    primary_key=True, index=True)
    code         = Column(String(20), unique=True, index=True)
    name         = Column(String(255), nullable=False)
    description  = Column(Text)
    credits      = Column(Integer, default=3)
    semester     = Column(String(20))   # legacy field kept for monitoring
    year         = Column(Integer)      # legacy field kept for monitoring
    professor_id = Column(Integer, ForeignKey("professors.id"))

    # ── Sprint 1: curriculum metadata ──────────────────────────────────────
    program_id        = Column(BigInteger, ForeignKey("academic_programs.id", ondelete="SET NULL"))
    track_id          = Column(BigInteger, ForeignKey("academic_tracks.id",   ondelete="SET NULL"))
    category          = Column(String(30), default="core")
    curriculum_level  = Column(SmallInteger)
    plan_semester     = Column(SmallInteger)
    lct_hours         = Column(SmallInteger, default=2)
    lab_hours         = Column(SmallInteger, default=0)
    tut_hours         = Column(SmallInteger, default=0)
    oth_hours         = Column(SmallInteger, default=0)
    contact_hours     = Column(SmallInteger, default=2)
    ects_credits      = Column(SmallInteger, default=4)
    slot_label        = Column(String(10))
    swl_hours         = Column(SmallInteger, default=90)
    counts_in_cgpa    = Column(Boolean, default=True)
    is_pass_fail      = Column(Boolean, default=False)
    pass_threshold    = Column(Numeric(5, 2), default=60.00)
    name_ar           = Column(String(255))
    is_active         = Column(Boolean, default=True)

    # ── Existing relationships ──────────────────────────────────────────────
    professor   = relationship("Professor",  back_populates="courses")
    enrollments = relationship("Enrollment", back_populates="course")
    attendances = relationship("Attendance", back_populates="course")
    quizzes     = relationship("Quiz",       back_populates="course")

    # ── Sprint 1: new relationships ────────────────────────────────────────
    prerequisites     = relationship(
        "CoursePrerequisite",
        foreign_keys="CoursePrerequisite.course_id",
        back_populates="course"
    )
    is_prerequisite_for = relationship(
        "CoursePrerequisite",
        foreign_keys="CoursePrerequisite.prerequisite_id",
        back_populates="prerequisite"
    )
    postrequisites    = relationship(
        "CoursePostrequisite",
        foreign_keys="CoursePostrequisite.course_id",
        back_populates="course"
    )
    is_postreq_for    = relationship(
        "CoursePostrequisite",
        foreign_keys="CoursePostrequisite.postreq_id",
        back_populates="postreq"
    )
    eligibility_rules = relationship("CourseEligibilityRule", back_populates="course")
    offerings         = relationship("CourseOffering",        back_populates="course")
    student_attempts  = relationship("StudentCourseAttempt",  back_populates="course")
    plan_items        = relationship("AdvisingPlanItem",      back_populates="course")


# ═════════════════════════════════════════════════════════════════════════════
# ENROLLMENT  (unchanged — kept for monitoring / attendance system)
# ═════════════════════════════════════════════════════════════════════════════
class Enrollment(Base):
    __tablename__  = "enrollments"
    __table_args__ = {"extend_existing": True}

    id          = Column(Integer, primary_key=True, index=True)
    student_id  = Column(Integer, ForeignKey("students.id"))
    course_id   = Column(Integer, ForeignKey("courses.id"))
    grade       = Column(Float)
    status      = Column(String(20), default="active")
    enrolled_at = Column(DateTime(timezone=True), server_default=func.now())

    student = relationship("Student", back_populates="enrollments")
    course  = relationship("Course",  back_populates="enrollments")


# ═════════════════════════════════════════════════════════════════════════════
# ATTENDANCE  (unchanged)
# ═════════════════════════════════════════════════════════════════════════════
class Attendance(Base):
    __tablename__  = "attendances"
    __table_args__ = {"extend_existing": True}

    id         = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("students.id"))
    course_id  = Column(Integer, ForeignKey("courses.id"))
    date       = Column(DateTime(timezone=True))
    status     = Column(String(20))

    student = relationship("Student", back_populates="attendances")
    course  = relationship("Course",  back_populates="attendances")


# ═════════════════════════════════════════════════════════════════════════════
# ACTIVITY LOG  (unchanged)
# ═════════════════════════════════════════════════════════════════════════════
class ActivityLog(Base):
    __tablename__  = "activity_logs"
    __table_args__ = {"extend_existing": True}

    id               = Column(Integer, primary_key=True, index=True)
    student_id       = Column(Integer, ForeignKey("students.id"))
    action           = Column(String(100))
    duration_minutes = Column(Integer)
    metadata_json    = Column(Text)
    timestamp        = Column(DateTime(timezone=True), server_default=func.now())

    student = relationship("Student", back_populates="activity_logs")


# ═════════════════════════════════════════════════════════════════════════════
# RISK ASSESSMENT  (unchanged)
# ═════════════════════════════════════════════════════════════════════════════
class RiskAssessment(Base):
    __tablename__  = "risk_assessments"
    __table_args__ = {"extend_existing": True}

    id                          = Column(Integer, primary_key=True, index=True)
    student_id                  = Column(Integer, ForeignKey("students.id"))
    risk_level                  = _risk_col()
    probability                 = Column(Float)
    grades_impact               = Column(Float)
    attendance_impact           = Column(Float)
    activity_impact             = Column(Float)
    dropout_probability         = Column(Float)
    graduation_delay_likelihood = Column(Float)
    scholarship_eligibility     = Column(Float)
    trend                       = Column(String(20))
    assessed_at                 = Column(DateTime(timezone=True), server_default=func.now())

    student = relationship("Student", back_populates="risk_assessments")


# ═════════════════════════════════════════════════════════════════════════════
# INTERVENTION PLAN  (unchanged)
# ═════════════════════════════════════════════════════════════════════════════
class InterventionPlan(Base):
    __tablename__  = "intervention_plans"
    __table_args__ = {"extend_existing": True}

    id          = Column(Integer, primary_key=True, index=True)
    student_id  = Column(Integer, ForeignKey("students.id"))
    advisor_id  = Column(Integer, ForeignKey("advisors.id"))
    title       = Column(String(255))
    description = Column(Text)
    status      = _istatus_col(default="pending")
    priority    = _priority_col(default="medium")
    deadline    = Column(DateTime(timezone=True))
    notes       = Column(Text)
    created_at  = Column(DateTime(timezone=True), server_default=func.now())

    student = relationship("Student", back_populates="intervention_plans")
    advisor = relationship("Advisor", back_populates="intervention_plans")
    actions = relationship("InterventionAction", back_populates="plan")


# ═════════════════════════════════════════════════════════════════════════════
# INTERVENTION ACTION  (unchanged)
# ═════════════════════════════════════════════════════════════════════════════
class InterventionAction(Base):
    __tablename__  = "intervention_actions"
    __table_args__ = {"extend_existing": True}

    id           = Column(Integer, primary_key=True, index=True)
    plan_id      = Column(Integer, ForeignKey("intervention_plans.id"))
    description  = Column(Text)
    completed    = Column(Boolean, default=False)
    completed_at = Column(DateTime(timezone=True))
    due_date     = Column(DateTime(timezone=True))
    order_index  = Column(Integer, default=0)

    plan = relationship("InterventionPlan", back_populates="actions")


# ═════════════════════════════════════════════════════════════════════════════
# NOTIFICATION  (unchanged)
# ═════════════════════════════════════════════════════════════════════════════
class Notification(Base):
    __tablename__  = "notifications"
    __table_args__ = {"extend_existing": True}

    id         = Column(Integer, primary_key=True, index=True)
    user_id    = Column(Integer, ForeignKey("users.id"))
    title      = Column(String(255))
    message    = Column(Text)
    type       = _notif_col(default="system")
    priority   = _priority_col(default="low")
    read       = Column(Boolean, default=False)
    read_at    = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="notifications")


# ═════════════════════════════════════════════════════════════════════════════
# AUDIT LOG  (unchanged)
# ═════════════════════════════════════════════════════════════════════════════
class AuditLog(Base):
    __tablename__  = "audit_logs"
    __table_args__ = {"extend_existing": True}

    id          = Column(Integer, primary_key=True, index=True)
    user_id     = Column(Integer, ForeignKey("users.id"))
    action      = Column(String(100))
    entity_type = Column(String(50))
    entity_id   = Column(Integer)
    old_value   = Column(JSONB)
    new_value   = Column(JSONB)
    timestamp   = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="audit_logs")


# ═════════════════════════════════════════════════════════════════════════════
# QUIZ  (unchanged)
# ═════════════════════════════════════════════════════════════════════════════
class Quiz(Base):
    __tablename__  = "quizzes"
    __table_args__ = {"extend_existing": True}

    id               = Column(Integer, primary_key=True, index=True)
    title            = Column(String(255))
    course_id        = Column(Integer, ForeignKey("courses.id"))
    created_by       = Column(Integer, ForeignKey("users.id"))
    duration_minutes = Column(Integer)
    status           = Column(String(20))
    start_time       = Column(DateTime(timezone=True))
    end_time         = Column(DateTime(timezone=True))
    created_at       = Column(DateTime(timezone=True), server_default=func.now())

    course      = relationship("Course",          back_populates="quizzes")
    questions   = relationship("Question",        back_populates="quiz")
    submissions = relationship("QuizSubmission",  back_populates="quiz")


# ═════════════════════════════════════════════════════════════════════════════
# QUESTION  (unchanged)
# ═════════════════════════════════════════════════════════════════════════════
class Question(Base):
    __tablename__  = "questions"
    __table_args__ = {"extend_existing": True}

    id             = Column(Integer, primary_key=True, index=True)
    quiz_id        = Column(Integer, ForeignKey("quizzes.id"))
    type           = Column(String(30))
    text           = Column(Text)
    options_json   = Column(JSONB)
    correct_answer = Column(String(500))
    points         = Column(Integer, default=1)
    order_index    = Column(Integer, default=0)

    quiz = relationship("Quiz", back_populates="questions")


# ═════════════════════════════════════════════════════════════════════════════
# QUIZ SUBMISSION  (unchanged)
# ═════════════════════════════════════════════════════════════════════════════
class QuizSubmission(Base):
    __tablename__  = "quiz_submissions"
    __table_args__ = {"extend_existing": True}

    id             = Column(Integer, primary_key=True, index=True)
    quiz_id        = Column(Integer, ForeignKey("quizzes.id"))
    student_id     = Column(Integer, ForeignKey("students.id"))
    answers_json   = Column(JSONB)
    score          = Column(Float)
    max_score      = Column(Float)
    attempt_number = Column(Integer, default=1)
    submitted_at   = Column(DateTime(timezone=True), server_default=func.now())

    quiz    = relationship("Quiz",    back_populates="submissions")
    student = relationship("Student", back_populates="quiz_submissions")
