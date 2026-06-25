"""
EduGuard AI — models.py (Production-Grade Audit Pass)

Changes from previous version:
  - Added every column that exists in 001_schema.sql but was missing from
    the ORM (created_at/updated_at on all core tables, notes, recorded_by,
    letter_grade, dropped_at/completed_at, resource_type/resource_id,
    explanation/recommendations/features_snapshot/assessed_by/model_version,
    metadata on notifications, ip_address/user_agent on audit_logs, quiz
    scheduling/scoring fields, question explanation, quiz_submission
    grading fields). Admin panel and any future code can now read/write
    these columns instead of them being silently invisible to the ORM.
  - Added explicit ondelete= on every ForeignKey to match the actual
    PostgreSQL constraint action (RESTRICT / CASCADE / SET NULL), so the
    ORM's understanding of delete behavior matches the database's.
  - Added passive_deletes=True on every relationship whose FK is RESTRICT
    or CASCADE at the DB level, so SQLAlchemy defers entirely to
    PostgreSQL's own enforcement on delete instead of eagerly loading
    child rows first (which previously had no effect on correctness but
    wasted queries, and could mask RESTRICT errors behind a confusing
    ORM-level load step).
  - All Sprint 1 (academic_programs/tracks/terms) columns and
    relationships on Student/Course/Professor/Advisor are preserved
    unchanged from the previous version.
"""

from sqlalchemy import (
    Column, Integer, SmallInteger, BigInteger, String, Float, Boolean,
    DateTime, Text, ForeignKey, Enum, Numeric, Index
)
from sqlalchemy.dialects.postgresql import JSONB, INET
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

class AttendanceStatus(str, enum.Enum):
    PRESENT = "present"
    ABSENT  = "absent"
    LATE    = "late"
    EXCUSED = "excused"

class QuizStatus(str, enum.Enum):
    DRAFT     = "draft"
    PUBLISHED = "published"
    CLOSED    = "closed"
    ARCHIVED  = "archived"


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

def _attendance_status_col(**kw):
    return Column(Enum(AttendanceStatus, values_callable=_vals, name="attendance_status"), **kw)

def _quiz_status_col(**kw):
    return Column(Enum(QuizStatus, values_callable=_vals, name="quiz_status"), **kw)


# ═════════════════════════════════════════════════════════════════════════════
# DEPARTMENT
# ═════════════════════════════════════════════════════════════════════════════
class Department(Base):
    __tablename__  = "departments"
    __table_args__ = {"extend_existing": True}

    id                = Column(BigInteger, primary_key=True, index=True)
    name              = Column(String(150), unique=True, nullable=False)
    code              = Column(String(20), unique=True, nullable=False)
    head_professor_id = Column(BigInteger)
    description       = Column(Text)
    created_at        = Column(DateTime(timezone=True), server_default=func.now())
    updated_at        = Column(DateTime(timezone=True), server_default=func.now())


# ═════════════════════════════════════════════════════════════════════════════
# USER
# ═════════════════════════════════════════════════════════════════════════════
class User(Base):
    __tablename__  = "users"
    __table_args__ = {"extend_existing": True}

    id                = Column(Integer, primary_key=True, index=True)
    email             = Column(String(255), unique=True, index=True, nullable=False)
    email_verified_at = Column(DateTime(timezone=True))
    hashed_password   = Column(String(255), nullable=False)
    name              = Column(String(255), nullable=False)
    role              = _role_col(nullable=False)
    is_active         = Column(Boolean, default=True)
    avatar_url        = Column(Text)
    remember_token     = Column(String(100))
    created_at        = Column(DateTime(timezone=True), server_default=func.now())
    updated_at        = Column(DateTime(timezone=True), server_default=func.now())
    last_login        = Column(DateTime(timezone=True))

    # NOTE on cascade behavior: students/professors/advisors/teaching_assistants
    # all have user_id -> users(id) ON DELETE CASCADE at the DB level (1:1
    # identity record — deleting the user IS deleting the role). notifications
    # is also CASCADE (personal data, no archival value). quizzes.created_by
    # and announcements.author_id are ON DELETE RESTRICT (protected academic
    # records) and are intentionally NOT modeled as relationships here to
    # avoid implying ORM-manageable cascade on protected data; the DB enforces
    # the RESTRICT regardless of how the row is deleted (raw SQL or ORM).
    student       = relationship("Student",      back_populates="user",    uselist=False, passive_deletes=True)
    professor     = relationship("Professor",    back_populates="user",    uselist=False, passive_deletes=True)
    advisor       = relationship("Advisor",      back_populates="user",    uselist=False, passive_deletes=True)
    notifications = relationship("Notification", back_populates="user",    passive_deletes=True)
    audit_logs    = relationship("AuditLog",     back_populates="user",    passive_deletes=True)


# ═════════════════════════════════════════════════════════════════════════════
# STUDENT  (extended with Sprint 1 academic profile columns)
# ═════════════════════════════════════════════════════════════════════════════
class Student(Base):
    __tablename__  = "students"
    __table_args__ = (
        Index("idx_student_semester", "id", "enrollment_date"),
        {"extend_existing": True},
    )

    id                = Column(Integer, primary_key=True, index=True)
    user_id           = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), unique=True)
    student_number    = Column(String(50), unique=True, index=True)
    department_id     = Column(BigInteger, ForeignKey("departments.id", ondelete="SET NULL"))
    major             = Column(String(100))
    year              = Column(SmallInteger)
    gpa               = Column(Numeric(3, 2), default=0.00)          # legacy column, kept for monitoring system
    enrollment_date   = Column(DateTime(timezone=True))
    phone             = Column(String(30))
    address           = Column(Text)
    emergency_contact = Column(String(255))
    advisor_id        = Column(BigInteger, ForeignKey("advisors.id", ondelete="SET NULL"))
    is_scholarship    = Column(Boolean, default=False)
    created_at        = Column(DateTime(timezone=True), server_default=func.now())
    updated_at        = Column(DateTime(timezone=True), server_default=func.now())

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
    # NOTE: enrollments/attendances/activity_logs/risk_assessments/
    # intervention_plans/quiz_submissions are ON DELETE RESTRICT at the DB
    # level (protected academic records — see 012_fix_academic_record_
    # protection.sql). passive_deletes=True tells SQLAlchemy not to try to
    # manage these children on delete (no SET NULL / no implicit load),
    # deferring entirely to PostgreSQL, which will raise IntegrityError if
    # any such row exists — exactly the protection this is meant to enforce.
    user               = relationship("User",               back_populates="student")
    department         = relationship("Department",         foreign_keys=[department_id])
    advisor            = relationship("Advisor",             back_populates="advisees", foreign_keys=[advisor_id])
    enrollments        = relationship("Enrollment",         back_populates="student", passive_deletes=True)
    attendances        = relationship("Attendance",         back_populates="student", passive_deletes=True)
    activity_logs      = relationship("ActivityLog",        back_populates="student", passive_deletes=True)
    risk_assessments   = relationship("RiskAssessment",     back_populates="student", passive_deletes=True)
    intervention_plans = relationship("InterventionPlan",   back_populates="student", passive_deletes=True)
    quiz_submissions   = relationship("QuizSubmission",     back_populates="student", passive_deletes=True)

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

    id              = Column(Integer, primary_key=True, index=True)
    user_id         = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), unique=True)
    department_id   = Column(BigInteger, ForeignKey("departments.id", ondelete="SET NULL"))
    department      = Column(String(100))
    title           = Column(String(50))
    specialization  = Column(String(150))
    office_location = Column(String(100))
    office_hours    = Column(Text)
    created_at      = Column(DateTime(timezone=True), server_default=func.now())
    updated_at      = Column(DateTime(timezone=True), server_default=func.now())

    # NOTE: no FK columns on `professors` are RESTRICT-protected at the DB
    # level — its remaining children (teaching_assistants.professor_id,
    # students.advisor_id-equivalent paths) are all ON DELETE SET NULL.
    # courses.professor_id is also ON DELETE SET NULL. A professor can
    # therefore always be deleted safely; passive_deletes is unnecessary
    # here but harmless, so it is omitted to keep the default (eager) load
    # behavior, which is fine given there is no protected data underneath.
    user      = relationship("User",            back_populates="professor")
    courses   = relationship("Course",          back_populates="professor")
    offerings = relationship("CourseOffering",  back_populates="professor")


# ═════════════════════════════════════════════════════════════════════════════
# ADVISOR  (extended with advising_plans relationship)
# ═════════════════════════════════════════════════════════════════════════════
class Advisor(Base):
    __tablename__  = "advisors"
    __table_args__ = {"extend_existing": True}

    id             = Column(Integer, primary_key=True, index=True)
    user_id        = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), unique=True)
    department_id  = Column(BigInteger, ForeignKey("departments.id", ondelete="SET NULL"))
    specialization = Column(String(100))
    max_students   = Column(SmallInteger, default=30)
    created_at     = Column(DateTime(timezone=True), server_default=func.now())
    updated_at     = Column(DateTime(timezone=True), server_default=func.now())

    # NOTE: same as Professor — advisors' only children (students.advisor_id,
    # intervention_plans.advisor_id) are both ON DELETE SET NULL at the DB
    # level, so deleting an advisor is always safe. passive_deletes omitted
    # intentionally for the same reason as Professor above.
    user                = relationship("User",              back_populates="advisor")
    advisees            = relationship("Student",           back_populates="advisor", foreign_keys="Student.advisor_id")
    intervention_plans  = relationship("InterventionPlan",  back_populates="advisor")
    advising_plans      = relationship("AdvisingPlan",      back_populates="advisor")  # Sprint 1


# ═════════════════════════════════════════════════════════════════════════════
# COURSE  (extended with Sprint 1 curriculum columns + relationships)
# ═════════════════════════════════════════════════════════════════════════════
class Course(Base):
    __tablename__  = "courses"
    __table_args__ = {"extend_existing": True}

    id            = Column(Integer,    primary_key=True, index=True)
    code          = Column(String(20), unique=True, index=True)
    name          = Column(String(255), nullable=False)
    description   = Column(Text)
    credits       = Column(SmallInteger, default=3)
    semester      = Column(String(20))   # legacy field kept for monitoring
    year          = Column(SmallInteger)      # legacy field kept for monitoring
    professor_id  = Column(Integer, ForeignKey("professors.id", ondelete="SET NULL"))
    department_id = Column(BigInteger, ForeignKey("departments.id", ondelete="SET NULL"))
    max_students  = Column(SmallInteger, default=40)

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
    created_at        = Column(DateTime(timezone=True), server_default=func.now())
    updated_at        = Column(DateTime(timezone=True), server_default=func.now())

    # ── Existing relationships ──────────────────────────────────────────────
    # NOTE: enrollments/attendances are ON DELETE RESTRICT (protected academic
    # records). quizzes.course_id is intentionally ON DELETE CASCADE at the DB
    # level (deleting a course intentionally removes its own quiz content —
    # the student-facing protected records are quiz_submissions/grade_records/
    # attendances/enrollments, which remain RESTRICT-protected independently).
    professor   = relationship("Professor",  back_populates="courses")
    department  = relationship("Department", foreign_keys=[department_id])
    enrollments = relationship("Enrollment", back_populates="course", passive_deletes=True)
    attendances = relationship("Attendance", back_populates="course", passive_deletes=True)
    quizzes     = relationship("Quiz",       back_populates="course", passive_deletes=True)

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
# ENROLLMENT  — protected academic record (ON DELETE RESTRICT on both FKs)
# ═════════════════════════════════════════════════════════════════════════════
class Enrollment(Base):
    __tablename__  = "enrollments"
    __table_args__ = {"extend_existing": True}

    id           = Column(Integer, primary_key=True, index=True)
    student_id   = Column(Integer, ForeignKey("students.id", ondelete="RESTRICT"))
    course_id    = Column(Integer, ForeignKey("courses.id",  ondelete="RESTRICT"))
    status       = Column(String(20), default="active")
    grade        = Column(Numeric(4, 2))
    letter_grade = Column(String(5))
    enrolled_at  = Column(DateTime(timezone=True), server_default=func.now())
    dropped_at   = Column(DateTime(timezone=True))
    completed_at = Column(DateTime(timezone=True))
    created_at   = Column(DateTime(timezone=True), server_default=func.now())
    updated_at   = Column(DateTime(timezone=True), server_default=func.now())

    student = relationship("Student", back_populates="enrollments")
    course  = relationship("Course",  back_populates="enrollments")


# ═════════════════════════════════════════════════════════════════════════════
# ATTENDANCE  — protected academic record (ON DELETE RESTRICT on both FKs)
# ═════════════════════════════════════════════════════════════════════════════
class Attendance(Base):
    __tablename__  = "attendances"
    __table_args__ = {"extend_existing": True}

    id          = Column(Integer, primary_key=True, index=True)
    student_id  = Column(Integer, ForeignKey("students.id", ondelete="RESTRICT"))
    course_id   = Column(Integer, ForeignKey("courses.id",  ondelete="RESTRICT"))
    date        = Column(DateTime(timezone=True))
    status      = _attendance_status_col(default="absent")
    notes       = Column(Text)
    recorded_by = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    created_at  = Column(DateTime(timezone=True), server_default=func.now())
    updated_at  = Column(DateTime(timezone=True), server_default=func.now())

    student  = relationship("Student", back_populates="attendances")
    course   = relationship("Course",  back_populates="attendances")
    recorder = relationship("User",    foreign_keys=[recorded_by])


# ═════════════════════════════════════════════════════════════════════════════
# ACTIVITY LOG  — protected academic record (ON DELETE RESTRICT on student_id)
# ═════════════════════════════════════════════════════════════════════════════
class ActivityLog(Base):
    __tablename__  = "activity_logs"
    __table_args__ = {"extend_existing": True}

    id               = Column(Integer, primary_key=True, index=True)
    student_id       = Column(Integer, ForeignKey("students.id", ondelete="RESTRICT"))
    action           = Column(String(100))
    duration_minutes = Column(Integer)
    resource_type    = Column(String(50))
    resource_id      = Column(BigInteger)  # polymorphic, no FK by design (see schema comment)
    metadata_json    = Column(JSONB)
    timestamp        = Column(DateTime(timezone=True), server_default=func.now())

    student = relationship("Student", back_populates="activity_logs")


# ═════════════════════════════════════════════════════════════════════════════
# RISK ASSESSMENT  — protected academic record (ON DELETE RESTRICT on student_id)
# ═════════════════════════════════════════════════════════════════════════════
class RiskAssessment(Base):
    __tablename__  = "risk_assessments"
    __table_args__ = {"extend_existing": True}

    id                          = Column(Integer, primary_key=True, index=True)
    student_id                  = Column(Integer, ForeignKey("students.id", ondelete="RESTRICT"))
    risk_level                  = _risk_col()
    probability                 = Column(Numeric(5, 2))
    grades_impact               = Column(Numeric(5, 2))
    attendance_impact           = Column(Numeric(5, 2))
    activity_impact             = Column(Numeric(5, 2))
    dropout_probability         = Column(Numeric(5, 2))
    graduation_delay_likelihood = Column(Numeric(5, 2))
    scholarship_eligibility     = Column(Numeric(5, 2))
    trend                       = Column(String(20))
    explanation                 = Column(Text)
    recommendations             = Column(JSONB)
    features_snapshot           = Column(JSONB)
    assessed_at                 = Column(DateTime(timezone=True), server_default=func.now())
    assessed_by                 = Column(String(50))
    model_version               = Column(String(20))
    created_at                  = Column(DateTime(timezone=True), server_default=func.now())

    student = relationship("Student", back_populates="risk_assessments")


# ═════════════════════════════════════════════════════════════════════════════
# INTERVENTION PLAN  — protected academic record (ON DELETE RESTRICT on student_id)
# ═════════════════════════════════════════════════════════════════════════════
class InterventionPlan(Base):
    __tablename__  = "intervention_plans"
    __table_args__ = {"extend_existing": True}

    id           = Column(Integer, primary_key=True, index=True)
    student_id   = Column(Integer, ForeignKey("students.id", ondelete="RESTRICT"))
    advisor_id   = Column(Integer, ForeignKey("advisors.id", ondelete="SET NULL"))
    title        = Column(String(255))
    description  = Column(Text)
    status       = _istatus_col(default="pending")
    priority     = _priority_col(default="medium")
    deadline     = Column(DateTime(timezone=True))
    completed_at = Column(DateTime(timezone=True))
    notes        = Column(Text)
    created_at   = Column(DateTime(timezone=True), server_default=func.now())
    updated_at   = Column(DateTime(timezone=True), server_default=func.now())

    # NOTE: intervention_actions.plan_id is ON DELETE CASCADE at the DB level
    # (an action with no plan has no meaning), so passive_deletes=True here
    # correctly defers that cascade to PostgreSQL instead of ORM-level cascade.
    student = relationship("Student", back_populates="intervention_plans")
    advisor = relationship("Advisor", back_populates="intervention_plans")
    actions = relationship("InterventionAction", back_populates="plan", passive_deletes=True)


# ═════════════════════════════════════════════════════════════════════════════
# INTERVENTION ACTION  — child of intervention_plans (ON DELETE CASCADE)
# ═════════════════════════════════════════════════════════════════════════════
class InterventionAction(Base):
    __tablename__  = "intervention_actions"
    __table_args__ = {"extend_existing": True}

    id           = Column(Integer, primary_key=True, index=True)
    plan_id      = Column(Integer, ForeignKey("intervention_plans.id", ondelete="CASCADE"))
    description  = Column(Text)
    completed    = Column(Boolean, default=False)
    completed_at = Column(DateTime(timezone=True))
    due_date     = Column(DateTime(timezone=True))
    order_index  = Column(SmallInteger, default=0)
    created_at   = Column(DateTime(timezone=True), server_default=func.now())
    updated_at   = Column(DateTime(timezone=True), server_default=func.now())

    plan = relationship("InterventionPlan", back_populates="actions")


# ═════════════════════════════════════════════════════════════════════════════
# NOTIFICATION  — personal data, ON DELETE CASCADE on user_id
# ═════════════════════════════════════════════════════════════════════════════
class Notification(Base):
    __tablename__  = "notifications"
    __table_args__ = {"extend_existing": True}

    id           = Column(Integer, primary_key=True, index=True)
    user_id      = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"))
    title        = Column(String(255))
    message      = Column(Text)
    type         = _notif_col(default="system")
    priority     = _priority_col(default="low")
    read         = Column(Boolean, default=False)
    read_at      = Column(DateTime(timezone=True))
    metadata_json = Column("metadata", JSONB, key="metadata_json")
    created_at   = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="notifications")


# ═════════════════════════════════════════════════════════════════════════════
# AUDIT LOG  — ON DELETE SET NULL on user_id (the audit event survives the user)
# ═════════════════════════════════════════════════════════════════════════════
class AuditLog(Base):
    __tablename__  = "audit_logs"
    __table_args__ = {"extend_existing": True}

    id          = Column(Integer, primary_key=True, index=True)
    user_id     = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    action      = Column(String(100))
    entity_type = Column(String(50))
    entity_id   = Column(BigInteger)  # polymorphic, no FK by design (see schema comment)
    old_value   = Column(JSONB)
    new_value   = Column(JSONB)
    ip_address  = Column(INET)
    user_agent  = Column(Text)
    timestamp   = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="audit_logs")


# ═════════════════════════════════════════════════════════════════════════════
# QUIZ  — course_id is ON DELETE CASCADE, created_by is ON DELETE RESTRICT
# ═════════════════════════════════════════════════════════════════════════════
class Quiz(Base):
    __tablename__  = "quizzes"
    __table_args__ = {"extend_existing": True}

    id                = Column(Integer, primary_key=True, index=True)
    title             = Column(String(255))
    description       = Column(Text)
    course_id         = Column(Integer, ForeignKey("courses.id", ondelete="CASCADE"))
    created_by        = Column(Integer, ForeignKey("users.id",   ondelete="RESTRICT"))
    duration_minutes  = Column(Integer)
    attempts_limit    = Column(SmallInteger, default=1)
    status            = _quiz_status_col(default="draft")
    start_time        = Column(DateTime(timezone=True))
    end_time          = Column(DateTime(timezone=True))
    shuffle_questions = Column(Boolean, default=False)
    randomize_options = Column(Boolean, default=False)
    show_results      = Column(Boolean, default=True)
    passing_score     = Column(Numeric(5, 2), default=60.00)
    total_points      = Column(Integer, default=0)
    created_at        = Column(DateTime(timezone=True), server_default=func.now())
    updated_at        = Column(DateTime(timezone=True), server_default=func.now())

    # NOTE: created_by is intentionally NOT modeled with a back_populates
    # relationship on User (a creator should not be deletable-cascaded into
    # losing their quizzes — see RESTRICT note on User above). questions and
    # quiz_submissions are ON DELETE CASCADE on quiz_id (a quiz's own content
    # has no independent existence), so passive_deletes=True is correct here.
    course      = relationship("Course",          back_populates="quizzes")
    creator     = relationship("User",             foreign_keys=[created_by])
    questions   = relationship("Question",        back_populates="quiz", passive_deletes=True)
    submissions = relationship("QuizSubmission",  back_populates="quiz", passive_deletes=True)


# ═════════════════════════════════════════════════════════════════════════════
# QUESTION  — child of quizzes (ON DELETE CASCADE)
# ═════════════════════════════════════════════════════════════════════════════
class Question(Base):
    __tablename__  = "questions"
    __table_args__ = {"extend_existing": True}

    id             = Column(Integer, primary_key=True, index=True)
    quiz_id        = Column(Integer, ForeignKey("quizzes.id", ondelete="CASCADE"))
    type           = Column(String(30))
    text           = Column(Text)
    options_json   = Column(JSONB)
    correct_answer = Column(String(500))
    explanation    = Column(Text)
    points         = Column(SmallInteger, default=1)
    order_index    = Column(SmallInteger, default=0)
    created_at     = Column(DateTime(timezone=True), server_default=func.now())

    quiz = relationship("Quiz", back_populates="questions")


# ═════════════════════════════════════════════════════════════════════════════
# QUIZ SUBMISSION  — quiz_id is ON DELETE CASCADE, student_id is ON DELETE RESTRICT
# ═════════════════════════════════════════════════════════════════════════════
class QuizSubmission(Base):
    __tablename__  = "quiz_submissions"
    __table_args__ = {"extend_existing": True}

    id                 = Column(Integer, primary_key=True, index=True)
    quiz_id            = Column(Integer, ForeignKey("quizzes.id",  ondelete="CASCADE"))
    student_id         = Column(Integer, ForeignKey("students.id", ondelete="RESTRICT"))
    answers_json       = Column(JSONB)
    score              = Column(Numeric(5, 2))
    max_score          = Column(Numeric(5, 2))
    percentage         = Column(Numeric(5, 2))
    passed             = Column(Boolean)
    attempt_number     = Column(SmallInteger, default=1)
    time_taken_minutes = Column(Integer)
    submitted_at       = Column(DateTime(timezone=True), server_default=func.now())
    graded_at          = Column(DateTime(timezone=True))
    graded_by          = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    feedback           = Column(Text)

    quiz    = relationship("Quiz",    back_populates="submissions")
    student = relationship("Student", back_populates="quiz_submissions")
    grader  = relationship("User",    foreign_keys=[graded_by])


# ═════════════════════════════════════════════════════════════════════════════
# GRADE RECORD  — protected academic record (ON DELETE RESTRICT on both FKs)
# Not previously modeled in the ORM at all; added here so the admin panel
# and any future code can manage it like every other table.
# ═════════════════════════════════════════════════════════════════════════════
class GradeRecord(Base):
    __tablename__  = "grade_records"
    __table_args__ = {"extend_existing": True}

    id              = Column(BigInteger, primary_key=True, index=True)
    student_id      = Column(Integer, ForeignKey("students.id", ondelete="RESTRICT"))
    course_id       = Column(Integer, ForeignKey("courses.id",  ondelete="RESTRICT"))
    assessment_type = Column(String(50))
    assessment_name = Column(String(255))
    score           = Column(Numeric(5, 2))
    max_score       = Column(Numeric(5, 2))
    weight          = Column(Numeric(5, 2), default=1.00)
    graded_at       = Column(DateTime(timezone=True), server_default=func.now())
    graded_by       = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    notes           = Column(Text)
    created_at      = Column(DateTime(timezone=True), server_default=func.now())

    student = relationship("Student", foreign_keys=[student_id])
    course  = relationship("Course",  foreign_keys=[course_id])
    grader  = relationship("User",    foreign_keys=[graded_by])