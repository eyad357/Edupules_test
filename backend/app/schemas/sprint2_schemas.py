"""
EduGuard AI — Sprint 2: Pydantic v2 Schemas
File: backend/app/schemas/sprint2_schemas.py
"""

from __future__ import annotations

from datetime import date, datetime
from typing import Any, Dict, List, Optional

from pydantic import BaseModel, ConfigDict, Field


class _Base(BaseModel):
    model_config = ConfigDict(from_attributes=True)


# ═════════════════════════════════════════════════════════════════════════════
# GRADE SCALE
# ═════════════════════════════════════════════════════════════════════════════

class GradeScaleEntryRead(_Base):
    id:             int
    program_id:     Optional[int]  = None
    letter_grade:   str
    grade_points:   float
    counts_in_cgpa: bool
    is_passing:     bool
    description:    Optional[str]  = None
    failure_type:   Optional[str]  = None


# ═════════════════════════════════════════════════════════════════════════════
# CGPA ENGINE
# ═════════════════════════════════════════════════════════════════════════════

class CGPADetailResponse(_Base):
    student_id:                   int
    student_name:                 str
    student_number:               str
    cgpa:                         float
    total_credit_hours_attempted: int
    total_credit_hours_earned:    int
    total_quality_points:         float
    academic_standing:            str
    is_eligible_for_graduation:   bool
    grade_scale:                  List[GradeScaleEntryRead] = []
    formula_note: str = (
        "CGPA = SUM(credits × grade_points) / SUM(credits). "
        "ALL attempts included. F(0.0) and FL(0.0) count. "
        "P (non-credit) excluded. Source: NMU CGPA_Calculator.xlsx."
    )


class CGPARecalcResponse(_Base):
    student_id:    int
    old_cgpa:      float
    new_cgpa:      float
    delta:         float
    recomputed_at: datetime


class CGPAVerificationRow(_Base):
    student_id:                int
    student_name:              str
    student_number:            str
    stored_cgpa:               float
    computed_cgpa:             float
    cgpa_delta:                float
    total_credit_hours_earned: int
    academic_standing:         str
    has_discrepancy:           bool


# ═════════════════════════════════════════════════════════════════════════════
# PREREQUISITE ENGINE
# ═════════════════════════════════════════════════════════════════════════════

class PrerequisiteCheckRequest(_Base):
    student_id: int
    course_id:  int
    term_id:    Optional[int] = None


class PrerequisiteCheckResponse(_Base):
    student_id:      int
    course_id:       int
    course_code:     str
    course_name:     str
    eligible:        bool
    missing_prereqs: List[str] = []
    reasons:         List[str] = []
    rule_triggered:  str
    explanation:     str
    checked_at:      datetime
    waiver_applied:  bool = False


class PrerequisiteNodeRead(_Base):
    code:          str
    name:          str
    plan_semester: Optional[int] = None
    prereq_type:   str
    logic_group:   int
    logic_type:    str


class PrerequisiteChainResponse(_Base):
    course_code:   str
    course_name:   str
    plan_semester: Optional[int] = None
    prerequisites: List[PrerequisiteNodeRead] = []


class PrerequisiteExceptionCreate(_Base):
    student_id:       int
    course_id:        int
    waived_prereq_id: int
    reason:           str = Field(..., min_length=10)
    expires_at:       Optional[datetime] = None


class PrerequisiteExceptionRead(_Base):
    id:               int
    student_id:       int
    course_id:        int
    waived_prereq_id: int
    granted_by:       Optional[int]      = None
    reason:           str
    approved_at:      datetime
    expires_at:       Optional[datetime] = None
    is_active:        bool


# ═════════════════════════════════════════════════════════════════════════════
# GRADUATION AUDIT
# ═════════════════════════════════════════════════════════════════════════════

class GraduationAuditResponse(_Base):
    audit_id:               int
    student_id:             int
    student_name:           str
    is_eligible:            bool
    cgpa:                   float
    credits_earned:         int
    credits_required:       int = 134
    credits_remaining:      int
    core_courses_required:  int
    core_courses_completed: int
    electives_required:     int = 3
    electives_completed:    int
    ft1_done:               bool
    ft2_done:               bool
    gp1_done:               bool
    gp2_done:               bool
    blocking_reasons:       List[str] = []
    completed_requirements: List[str] = []
    missing_courses:        List[Dict[str, str]] = []
    audited_at:             datetime
    audit_version:          str = "v2.0"
    explanation:            str = ""


class GraduationAuditHistoryRead(_Base):
    id:                     int
    student_id:             int
    audited_at:             datetime
    is_eligible:            bool
    cgpa_at_audit:          float
    total_ch_earned:        int
    blocking_reasons:       Optional[Any] = None
    completed_requirements: Optional[Any] = None


# ═════════════════════════════════════════════════════════════════════════════
# ACADEMIC CALENDAR
# ═════════════════════════════════════════════════════════════════════════════

class CalendarPeriodCreate(_Base):
    term_id:     int
    period_type: str
    label:       str
    start_date:  date
    end_date:    date
    is_active:   bool           = True
    notes:       Optional[str]  = None


class CalendarPeriodRead(_Base):
    id:          int
    term_id:     int
    period_type: str
    label:       str
    start_date:  date
    end_date:    date
    is_active:   bool
    notes:       Optional[str]  = None
    created_at:  datetime
    updated_at:  datetime


class CalendarPeriodStatusResponse(_Base):
    term_id:     int
    period_type: str
    is_active:   bool
    start_date:  Optional[date]     = None
    end_date:    Optional[date]     = None
    checked_at:  datetime


# ═════════════════════════════════════════════════════════════════════════════
# ACADEMIC OVERRIDES
# ═════════════════════════════════════════════════════════════════════════════

class AcademicOverrideCreate(_Base):
    override_type: str
    student_id:    int
    course_id:     Optional[int]   = None
    term_id:       Optional[int]   = None
    reason:        str             = Field(..., min_length=10)
    metadata_json: Optional[dict]  = None


class AcademicOverrideDecision(_Base):
    action:          str            # "approve" | "reject"
    decision_reason: str            = Field(..., min_length=5)
    reviewer_notes:  Optional[str]  = None
    expires_at:      Optional[datetime] = None


class AcademicOverrideRead(_Base):
    id:              int
    override_type:   str
    student_id:      int
    course_id:       Optional[int]      = None
    term_id:         Optional[int]      = None
    requested_by:    int
    reviewed_by:     Optional[int]      = None
    status:          str
    reason:          str
    reviewer_notes:  Optional[str]      = None
    decision_reason: Optional[str]      = None
    rule_triggered:  Optional[str]      = None
    explanation:     Optional[str]      = None
    requested_at:    datetime
    reviewed_at:     Optional[datetime] = None
    expires_at:      Optional[datetime] = None
    created_at:      datetime
    updated_at:      datetime


class AcademicOverrideHistoryRead(_Base):
    id:           int
    override_id:  int
    action:       str
    old_status:   Optional[str]    = None
    new_status:   Optional[str]    = None
    notes:        Optional[str]    = None
    performed_at: datetime


# ═════════════════════════════════════════════════════════════════════════════
# ELECTIVE MANAGEMENT
# ═════════════════════════════════════════════════════════════════════════════

class ElectivePoolRead(_Base):
    id:                  int
    program_id:          Optional[int] = None
    track_id:            Optional[int] = None
    pool_code:           str
    pool_name:           str
    min_selections:      int
    max_selections:      int
    required_selections: int
    plan_semesters:      Optional[str] = None
    notes:               Optional[str] = None


class ElectivePoolCourseRead(_Base):
    id:            int
    pool_id:       int
    course_id:     int
    course_code:   Optional[str] = None
    course_name:   Optional[str] = None
    credits:       Optional[int] = None
    plan_semester: Optional[int] = None


class ElectivePoolWithCoursesRead(ElectivePoolRead):
    courses: List[ElectivePoolCourseRead] = []


class StudentElectiveStatusResponse(_Base):
    student_id:        int
    pool_id:           int
    pool_name:         str
    required:          int
    selected_count:    int
    remaining:         int
    is_complete:       bool
    selected_courses:  List[ElectivePoolCourseRead] = []
    available_courses: List[ElectivePoolCourseRead] = []


# ═════════════════════════════════════════════════════════════════════════════
# NOTIFICATIONS
# ═════════════════════════════════════════════════════════════════════════════

class NotificationTemplateRead(_Base):
    id:               int
    event_type:       str
    channel:          str
    subject_template: str
    body_template:    str
    priority:         str
    is_active:        bool


class NotificationPreferenceRead(_Base):
    id:         int
    user_id:    int
    event_type: str
    in_app:     bool
    email:      bool
    sms:        bool


class NotificationPreferenceUpdate(_Base):
    in_app: bool = True
    email:  bool = False
    sms:    bool = False


class AcademicNotificationCreate(_Base):
    event_type: str
    student_id: int
    context:    Dict[str, Any] = {}


# ═════════════════════════════════════════════════════════════════════════════
# DECISION LOG (Explainability)
# ═════════════════════════════════════════════════════════════════════════════

class DecisionLogRead(_Base):
    id:              int
    decision_type:   str
    student_id:      int
    course_id:       Optional[int]      = None
    term_id:         Optional[int]      = None
    outcome:         bool
    decision_reason: str
    rule_triggered:  Optional[str]      = None
    explanation:     Optional[str]      = None
    decided_by:      str
    decided_at:      datetime


# ═════════════════════════════════════════════════════════════════════════════
# RBAC
# ═════════════════════════════════════════════════════════════════════════════

class RbacPermissionRead(_Base):
    id:         int
    role:       str
    resource:   str
    action:     str
    conditions: Optional[Dict[str, Any]] = None
    is_active:  bool


class RolePermissionsResponse(_Base):
    role:        str
    permissions: List[RbacPermissionRead] = []


# ═════════════════════════════════════════════════════════════════════════════
# TRANSCRIPT & REPORTING
# ═════════════════════════════════════════════════════════════════════════════

class TranscriptAttemptRow(_Base):
    attempt_id:             int
    course_code:            str
    course_name:            str
    credit_hours:           int
    category:               str
    attempt_number:         int
    numeric_grade:          Optional[float] = None
    letter_grade:           Optional[str]   = None
    grade_points:           Optional[float] = None
    result:                 str
    counts_in_cgpa:         bool
    term_code:              str
    academic_year:          int
    term_type:              str
    is_improvement_attempt: bool


class StudentTranscriptResponse(_Base):
    student_id:         int
    student_name:       str
    student_number:     str
    program:            Optional[str] = None
    track:              Optional[str] = None
    cgpa:               float
    total_ch_attempted: int
    total_ch_earned:    int
    academic_standing:  str
    attempts:           List[TranscriptAttemptRow] = []
    generated_at:       datetime


class StudentAnalyticsResponse(_Base):
    student_id:               int
    student_name:             str
    student_number:           Optional[str]  = None
    cgpa:                     float
    academic_standing:        str
    is_at_risk:               bool
    is_eligible_for_grad:     bool
    ch_earned:                int
    ch_required:              int = 134
    ch_remaining:             int
    pct_complete:             float
    estimated_sems_remaining: float
    total_attempts:           int
    unique_courses_passed:    int
    unique_courses_failed:    int
    retake_count:             int
    pass_rate_pct:            float
    grade_distribution:       Dict[str, int] = {}
    gpa_trend:                List[Dict[str, Any]] = []
    computed_at:              str


class CourseRecommendationItem(_Base):
    course_id:      int
    course_code:    str
    course_name:    str
    credits:        int
    category:       str
    plan_semester:  Optional[int] = None
    priority:       str           # "required" | "remediation" | "elective"
    reason:         str
    rule_triggered: str


class CourseRecommendationsResponse(_Base):
    student_id:              int
    term_id:                 int
    current_plan_sem:        int
    recommended_count:       int
    total_recommended_ch:    int
    recommendations:         List[CourseRecommendationItem] = []
    generated_at:            str