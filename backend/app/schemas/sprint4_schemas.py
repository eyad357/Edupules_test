"""
EduGuard AI — Sprint 4 Pydantic Schemas
========================================
Request/response models for all Sprint 4 endpoints.
"""

from __future__ import annotations
from typing import Any, Dict, List, Optional
from datetime import datetime
from decimal import Decimal
from pydantic import BaseModel, Field, ConfigDict


# ── Shared config ─────────────────────────────────────────────────────────────
class _Base(BaseModel):
    model_config = ConfigDict(from_attributes=True)


# ═════════════════════════════════════════════════════════════════════════════
# ACADEMIC RULES CONFIG
# ═════════════════════════════════════════════════════════════════════════════

class AcademicRuleRead(_Base):
    id: int
    program_id: Optional[int]
    rule_key: str
    rule_value: str
    description: Optional[str]
    updated_at: Optional[datetime]


class AcademicRuleCreate(BaseModel):
    program_id: Optional[int] = None
    rule_key: str
    rule_value: str
    description: Optional[str] = None


class AcademicRuleUpdate(BaseModel):
    rule_value: str
    description: Optional[str] = None


# ═════════════════════════════════════════════════════════════════════════════
# GRADE PROCESSING
# ═════════════════════════════════════════════════════════════════════════════

class GradeInfo(_Base):
    letter_grade: str
    grade_points: Decimal
    is_passing: bool
    counts_in_cgpa: bool
    description: Optional[str]


class GradeScaleResponse(_Base):
    program_id: Optional[int]
    grades: List[GradeInfo]


# ═════════════════════════════════════════════════════════════════════════════
# SEMESTER SNAPSHOT
# ═════════════════════════════════════════════════════════════════════════════

class SemesterSnapshotRead(_Base):
    id: int
    student_id: int
    term_id: int
    version: int
    term_gpa: Decimal
    cgpa_after_term: Decimal
    credits_attempted: int
    credits_earned: int
    credits_failed: int
    credits_withdrawn: int
    cumulative_attempted: int
    cumulative_earned: int
    academic_standing: str
    honors_level: str
    dean_list_eligible: bool
    risk_flags: List[Any]
    snapshot_hash: Optional[str]
    generated_at: datetime
    is_final: bool


# ═════════════════════════════════════════════════════════════════════════════
# TRANSCRIPT
# ═════════════════════════════════════════════════════════════════════════════

class TranscriptCourseEntry(BaseModel):
    term_code: str
    term_name: str
    course_code: str
    course_name: str
    credit_hours: int
    letter_grade: str
    grade_points: Decimal
    result: str
    attempt_number: int
    counts_in_cgpa: bool


class TranscriptSemesterSummary(BaseModel):
    term_code: str
    term_name: str
    credits_attempted: int
    credits_earned: int
    term_gpa: Decimal
    cgpa_after_term: Decimal
    academic_standing: str
    courses: List[TranscriptCourseEntry]


class TranscriptStudentInfo(BaseModel):
    student_number: str
    name: str
    program: str
    track: Optional[str]
    department: Optional[str]
    admission_term: Optional[str]
    expected_grad_term: Optional[str]


class TranscriptPayload(BaseModel):
    student_info: TranscriptStudentInfo
    semesters: List[TranscriptSemesterSummary]
    total_credits_attempted: int
    total_credits_earned: int
    cumulative_gpa: Decimal
    academic_standing: str
    graduation_status: Optional[str]
    honors_level: Optional[str]
    generated_at: str
    transcript_type: str


class TranscriptVersionRead(_Base):
    id: int
    student_id: int
    version_number: int
    transcript_type: str
    snapshot_hash: str
    generated_at: datetime
    reason: Optional[str]
    is_current: bool
    verification_code: Optional[str] = None


class TranscriptGenerateRequest(BaseModel):
    transcript_type: str = Field(default="unofficial", pattern="^(official|unofficial|semester|graduation)$")
    term_id: Optional[int] = None
    reason: Optional[str] = None


class TranscriptFullResponse(BaseModel):
    version_id: int
    version_number: int
    transcript_type: str
    data: TranscriptPayload
    verification_code: Optional[str]
    generated_at: datetime


# ═════════════════════════════════════════════════════════════════════════════
# TRANSCRIPT VERIFICATION
# ═════════════════════════════════════════════════════════════════════════════

class TranscriptVerificationRead(_Base):
    id: int
    transcript_id: int
    verification_code: str
    qr_identifier: str
    is_valid: bool
    expires_at: Optional[datetime]
    verified_count: int
    last_verified_at: Optional[datetime]
    created_at: datetime


class TranscriptVerifyResponse(BaseModel):
    is_valid: bool
    student_name: Optional[str]
    student_number: Optional[str]
    program: Optional[str]
    transcript_type: Optional[str]
    generated_at: Optional[datetime]
    cgpa: Optional[Decimal]
    message: str


# ═════════════════════════════════════════════════════════════════════════════
# ACADEMIC TIMELINE
# ═════════════════════════════════════════════════════════════════════════════

class TimelineEventRead(_Base):
    id: int
    student_id: int
    term_id: Optional[int]
    event_type: str
    title: str
    description: Optional[str]
    payload: Dict[str, Any]
    actor_id: Optional[int]
    occurred_at: datetime


class TimelineResponse(BaseModel):
    student_id: int
    total_events: int
    events: List[TimelineEventRead]


# ═════════════════════════════════════════════════════════════════════════════
# ACADEMIC STATUS
# ═════════════════════════════════════════════════════════════════════════════

class StatusHistoryRead(_Base):
    id: int
    student_id: int
    term_id: Optional[int]
    old_status: Optional[str]
    new_status: str
    cgpa_at_change: Optional[Decimal]
    term_gpa_at_change: Optional[Decimal]
    reason: Optional[str]
    occurred_at: datetime


# ═════════════════════════════════════════════════════════════════════════════
# DEGREE PROGRESS
# ═════════════════════════════════════════════════════════════════════════════

class CategoryProgress(BaseModel):
    category: str
    required_credits: int
    earned_credits: int
    remaining_credits: int
    completion_pct: float


class DegreeProgressRead(_Base):
    id: int
    student_id: int
    term_id: Optional[int]
    version: int
    required_credits: int
    earned_credits: int
    remaining_credits: int
    completion_percentage: Decimal
    category_breakdown: Dict[str, Any]
    missing_core_courses: List[str]
    missing_elective_slots: int
    missing_categories: List[str]
    all_core_complete: bool
    all_electives_complete: bool
    field_training_complete: bool
    graduation_project_complete: bool
    computed_at: datetime


class DegreeProgressResponse(BaseModel):
    current: DegreeProgressRead
    summary: Dict[str, Any]


# ═════════════════════════════════════════════════════════════════════════════
# GRADUATION ELIGIBILITY
# ═════════════════════════════════════════════════════════════════════════════

class GraduationEligibilityRead(_Base):
    id: int
    student_id: int
    term_id: Optional[int]
    eligibility_status: str
    requirements_met: Dict[str, Any]
    missing_requirements: List[str]
    cgpa_at_evaluation: Optional[Decimal]
    credits_at_evaluation: Optional[int]
    evaluated_at: datetime
    notes: Optional[str]
    is_current: bool


# ═════════════════════════════════════════════════════════════════════════════
# HONORS
# ═════════════════════════════════════════════════════════════════════════════

class HonorsRecordRead(_Base):
    id: int
    student_id: int
    term_id: Optional[int]
    honors_level: str
    is_deans_list: bool
    term_gpa_used: Optional[Decimal]
    cgpa_used: Optional[Decimal]
    credits_used: Optional[int]
    qualification_data: Dict[str, Any]
    awarded_at: datetime


# ═════════════════════════════════════════════════════════════════════════════
# GPA PROJECTION
# ═════════════════════════════════════════════════════════════════════════════

class ProjectionRequest(BaseModel):
    target_cgpa: Optional[float] = Field(None, ge=0.0, le=4.0)
    remaining_credits: Optional[int] = Field(None, ge=0)
    registered_courses: Optional[List[Dict[str, Any]]] = None
    # e.g. [{"code": "CSE112", "credits": 3, "expected_grade": "B+"}]
    projection_type: str = Field(
        default="graduation_target",
        pattern="^(graduation_target|term_target|course_grade_needed|raise_cgpa)$"
    )


class GPAProjectionRead(_Base):
    id: int
    student_id: int
    projection_type: str
    current_cgpa: Optional[Decimal]
    current_credits: Optional[int]
    target_cgpa: Optional[Decimal]
    remaining_credits: Optional[int]
    scenario_input: Dict[str, Any]
    projection_result: Dict[str, Any]
    projected_semester_gpa: Optional[Decimal]
    projected_cgpa: Optional[Decimal]
    is_achievable: Optional[bool]
    computed_at: datetime


# ═════════════════════════════════════════════════════════════════════════════
# ACADEMIC RISK
# ═════════════════════════════════════════════════════════════════════════════

class AcademicRiskRead(_Base):
    id: int
    student_id: int
    term_id: Optional[int]
    risk_level: str
    risk_score: Optional[Decimal]
    gpa_trend: Optional[Decimal]
    cgpa_trend: Optional[Decimal]
    failed_courses_count: int
    repeated_courses_count: int
    withdrawal_count: int
    degree_completion_pct: Optional[Decimal]
    risk_factors: List[str]
    recommendations: List[str]
    assessed_at: datetime
    is_current: bool


# ═════════════════════════════════════════════════════════════════════════════
# REGISTRAR NOTES
# ═════════════════════════════════════════════════════════════════════════════

class RegistrarNoteCreate(BaseModel):
    student_id: int
    term_id: Optional[int] = None
    note_type: str = Field(default="registrar", pattern="^(registrar|advisor|academic|flag|decision)$")
    title: str = Field(min_length=1, max_length=200)
    content: str = Field(min_length=1)
    tags: List[str] = Field(default_factory=list)
    is_private: bool = False


class RegistrarNoteUpdate(BaseModel):
    title: Optional[str] = None
    content: Optional[str] = None
    tags: Optional[List[str]] = None
    is_private: Optional[bool] = None


class RegistrarNoteRead(_Base):
    id: int
    student_id: int
    term_id: Optional[int]
    note_type: str
    title: str
    content: str
    tags: List[str]
    is_private: bool
    version: int
    created_by: Optional[int]
    created_at: datetime
    updated_at: datetime


# ═════════════════════════════════════════════════════════════════════════════
# AUDIT TRAIL
# ═════════════════════════════════════════════════════════════════════════════

class AuditEntryRead(_Base):
    id: int
    student_id: int
    term_id: Optional[int]
    action: str
    entity_type: Optional[str]
    entity_id: Optional[int]
    old_value: Optional[Dict[str, Any]]
    new_value: Optional[Dict[str, Any]]
    reason: Optional[str]
    actor_id: Optional[int]
    actor_role: Optional[str]
    occurred_at: datetime


# ═════════════════════════════════════════════════════════════════════════════
# MODULE 17: DASHBOARD AGGREGATION
# ═════════════════════════════════════════════════════════════════════════════

class CurrentSemesterSummary(BaseModel):
    term_id: Optional[int]
    term_name: Optional[str]
    courses_registered: int
    credits_registered: int
    in_progress_courses: List[Dict[str, Any]]


class DashboardResponse(BaseModel):
    student_id: int
    student_number: str
    name: str
    program: Optional[str]
    track: Optional[str]

    # Academic standing
    current_gpa: Optional[Decimal]
    current_cgpa: Optional[Decimal]
    academic_standing: str

    # Credits
    earned_credits: int
    remaining_credits: int
    required_credits: int

    # Progress
    degree_completion_pct: Decimal
    all_core_complete: bool

    # Graduation
    graduation_eligibility: str
    graduation_eligibility_id: Optional[int]

    # Risk
    risk_level: str
    risk_score: Optional[Decimal]

    # Honors
    honors_level: str
    is_deans_list: bool

    # Semester
    current_semester: Optional[CurrentSemesterSummary]

    # Transcript
    latest_transcript_id: Optional[int]
    latest_transcript_type: Optional[str]
    latest_transcript_generated: Optional[datetime]

    computed_at: datetime


# ═════════════════════════════════════════════════════════════════════════════
# ACADEMIC RECORD (Module 1)
# ═════════════════════════════════════════════════════════════════════════════

class CourseAttemptSummary(BaseModel):
    course_code: str
    course_name: str
    credit_hours: int
    attempt_number: int
    term_code: str
    letter_grade: Optional[str]
    grade_points: Optional[Decimal]
    result: str
    counts_in_cgpa: bool


class SemesterRecord(BaseModel):
    term_id: int
    term_code: str
    term_name: str
    term_gpa: Decimal
    cgpa_after_term: Decimal
    credits_attempted: int
    credits_earned: int
    academic_standing: str
    courses: List[CourseAttemptSummary]


class AcademicRecordResponse(BaseModel):
    student_id: int
    student_number: str
    name: str
    program: Optional[str]
    track: Optional[str]
    department: Optional[str]
    current_cgpa: Decimal
    total_credits_attempted: int
    total_credits_earned: int
    academic_standing: str
    semesters: List[SemesterRecord]
    total_semesters: int


class AcademicHistoryResponse(BaseModel):
    student_id: int
    enrollment_date: Optional[datetime]
    program: Optional[str]
    track: Optional[str]
    status_history: List[StatusHistoryRead]
    gpa_history: List[Dict[str, Any]]
    cgpa_history: List[Dict[str, Any]]
