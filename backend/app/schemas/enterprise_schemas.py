"""
EduGuard AI — Enterprise Pydantic Schemas
==========================================
Request/response models for all 9 enterprise modules.
"""

from __future__ import annotations
from typing import Any, Dict, List, Optional
from datetime import datetime, date
from decimal import Decimal
from pydantic import BaseModel, Field, ConfigDict


class _Base(BaseModel):
    model_config = ConfigDict(from_attributes=True)


# ── Cohort ────────────────────────────────────────────────────────────────────

class CohortCreate(BaseModel):
    program_id: Optional[int] = None
    track_id: Optional[int] = None
    cohort_code: str = Field(min_length=3, max_length=40)
    cohort_name: Optional[str] = None
    intake_year: int
    intake_semester: str = Field(pattern="^(Fall|Spring|Summer)$")
    intake_term_id: Optional[int] = None
    expected_grad_year: Optional[int] = None
    total_semesters_planned: int = 8
    notes: Optional[str] = None


class CohortRead(_Base):
    id: int
    cohort_code: str
    cohort_name: Optional[str]
    intake_year: int
    intake_semester: str
    expected_grad_year: Optional[int]
    total_semesters_planned: int
    status: str
    total_enrolled: int
    total_graduated: int
    total_delayed: int
    avg_cgpa: Optional[Decimal]
    created_at: datetime


class CohortEnrollRequest(BaseModel):
    student_id: int
    cohort_id: int
    join_date: Optional[date] = None
    expected_grad_date: Optional[date] = None


class CohortMemberRead(_Base):
    id: int
    student_id: int
    cohort_id: int
    status: str
    is_delayed: bool
    semesters_completed: int
    join_date: Optional[date]
    expected_grad_date: Optional[date]
    actual_grad_date: Optional[date]


# ── Registration Events ───────────────────────────────────────────────────────

class RegistrationEventCreate(BaseModel):
    student_id: int
    term_id: int
    course_id: Optional[int] = None
    attempt_id: Optional[int] = None
    event_type: str
    event_detail: Optional[str] = None
    payload: Dict[str, Any] = Field(default_factory=dict)
    requires_approval: bool = False


class RegistrationEventRead(_Base):
    id: int
    student_id: int
    term_id: int
    course_id: Optional[int]
    event_type: str
    event_detail: Optional[str]
    payload: Dict[str, Any]
    requires_approval: bool
    approved_by: Optional[int]
    approved_at: Optional[datetime]
    actor_id: Optional[int]
    occurred_at: datetime


# ── Documents ─────────────────────────────────────────────────────────────────

class DocumentUploadRequest(BaseModel):
    document_type: str
    title: str = Field(min_length=1, max_length=200)
    description: Optional[str] = None
    document_number: Optional[str] = None
    storage_key: Optional[str] = None
    file_name: Optional[str] = None
    file_size_bytes: Optional[int] = None
    mime_type: Optional[str] = None
    issue_date: Optional[date] = None
    expiry_date: Optional[date] = None
    metadata_: Optional[Dict[str, Any]] = None


class DocumentRead(_Base):
    id: int
    student_id: int
    document_type: str
    title: str
    document_number: Optional[str]
    status: str
    verification_status: Optional[str]
    version: int
    upload_date: Optional[datetime]
    expiry_date: Optional[date]
    is_active: bool


class DocumentRegistryResponse(BaseModel):
    student_id: int
    total: int
    by_type: Dict[str, List[Dict[str, Any]]]


# ── Academic Cases ────────────────────────────────────────────────────────────

class CaseSubmitRequest(BaseModel):
    case_type: str = Field(pattern="^(grade_appeal|academic_petition|exception_request|course_waiver|graduation_exception|registration_exception|transfer_credit_appeal)$")
    title: str = Field(min_length=5, max_length=300)
    description: str = Field(min_length=10)
    term_id: Optional[int] = None
    course_id: Optional[int] = None
    attempt_id: Optional[int] = None
    supporting_docs: List[int] = Field(default_factory=list)
    priority: str = Field(default="medium", pattern="^(low|medium|high|urgent)$")


class CaseTransitionRequest(BaseModel):
    new_status: str = Field(pattern="^(under_review|approved|rejected|closed)$")
    decision: str = Field(min_length=5)
    notes: Optional[str] = None


class CaseDecisionRead(_Base):
    id: int
    case_id: int
    from_status: Optional[str]
    to_status: str
    decision: Optional[str]
    notes: Optional[str]
    decided_by: Optional[int]
    decided_at: datetime


class CaseRead(_Base):
    id: int
    case_number: str
    student_id: int
    term_id: Optional[int]
    course_id: Optional[int]
    case_type: str
    status: str
    title: str
    description: str
    priority: Optional[str]
    assigned_to: Optional[int]
    resolution: Optional[str]
    submitted_at: datetime
    resolved_at: Optional[datetime]
    decisions: List[CaseDecisionRead] = Field(default_factory=list)


# ── Transfer Credits ──────────────────────────────────────────────────────────

class TransferCreditSubmitRequest(BaseModel):
    source_institution: str = Field(min_length=3, max_length=200)
    source_institution_country: Optional[str] = None
    source_course_code: str = Field(min_length=2, max_length=30)
    source_course_name: str = Field(min_length=2, max_length=200)
    source_credit_hours: int = Field(ge=1, le=20)
    source_grade: Optional[str] = None
    source_grade_points: Optional[float] = None
    source_grade_scale: Optional[str] = None
    target_course_id: Optional[int] = None
    target_course_code: Optional[str] = None
    target_credit_hours: Optional[int] = None
    counts_toward_degree: bool = True
    evaluation_notes: Optional[str] = None
    term_id: Optional[int] = None


class TransferCreditApproveRequest(BaseModel):
    notes: Optional[str] = None
    target_grade_points: Optional[float] = None
    target_credit_hours: Optional[int] = None


class TransferCreditRejectRequest(BaseModel):
    reason: str = Field(min_length=5)


class TransferCreditRead(_Base):
    id: int
    student_id: int
    source_institution: str
    source_course_code: str
    source_course_name: str
    source_credit_hours: int
    source_grade: Optional[str]
    target_course_code: Optional[str]
    target_credit_hours: Optional[int]
    target_grade_points: Optional[Decimal]
    counts_in_cgpa: bool
    counts_toward_degree: bool
    status: str
    evaluation_notes: Optional[str]
    submitted_at: datetime
    approved_at: Optional[datetime]
    rejection_reason: Optional[str]


# ── Exemptions ────────────────────────────────────────────────────────────────

class ExemptionRequestBody(BaseModel):
    exemption_type: str = Field(pattern="^(course_exemption|requirement_exemption|curriculum_exemption)$")
    course_id: Optional[int] = None
    course_code: Optional[str] = None
    requirement_desc: Optional[str] = None
    reason: str = Field(min_length=10)
    supporting_doc_ids: List[int] = Field(default_factory=list)


class ExemptionApproveRequest(BaseModel):
    notes: str = Field(min_length=5)


class ExemptionRejectRequest(BaseModel):
    reason: str = Field(min_length=5)


class ExemptionRead(_Base):
    id: int
    student_id: int
    exemption_type: str
    status: str
    course_id: Optional[int]
    course_code: Optional[str]
    requirement_desc: Optional[str]
    reason: str
    decision_notes: Optional[str]
    version: int
    requested_at: datetime
    approved_at: Optional[datetime]


# ── Record Versions ───────────────────────────────────────────────────────────

class RecordVersionRead(_Base):
    id: int
    student_id: int
    version_number: int
    trigger: str
    trigger_detail: Optional[str]
    cgpa: Optional[Decimal]
    hours_attempted: Optional[int]
    hours_earned: Optional[int]
    academic_standing: Optional[str]
    graduation_status: Optional[str]
    degree_completion_pct: Optional[Decimal]
    snapshot_hash: str
    is_current: bool
    authored_by: Optional[int]
    authored_at: datetime


class RecordVersionCompareResponse(BaseModel):
    version_1: Dict[str, Any]
    version_2: Dict[str, Any]
    cgpa_delta: float
    standing_changed: bool
    completion_delta: float


# ── PDF Jobs ──────────────────────────────────────────────────────────────────

class PDFJobRequest(BaseModel):
    transcript_type: str = Field(default="unofficial", pattern="^(official|unofficial|semester|graduation)$")
    transcript_version_id: Optional[int] = None
    options: Optional[Dict[str, Any]] = None


class PDFJobRead(_Base):
    id: int
    student_id: int
    transcript_type: str
    status: str
    page_count: Optional[int]
    file_size_bytes: Optional[int]
    result_key: Optional[str]
    error_message: Optional[str]
    options: Optional[Dict[str, Any]]
    queued_at: datetime
    started_at: Optional[datetime]
    completed_at: Optional[datetime]
    expires_at: Optional[datetime]


# ── Registrar Tasks ───────────────────────────────────────────────────────────

class TaskCreateRequest(BaseModel):
    task_type: str
    student_id: Optional[int] = None
    term_id: Optional[int] = None
    title: str = Field(min_length=5, max_length=300)
    description: Optional[str] = None
    priority: str = Field(default="medium", pattern="^(low|medium|high|urgent)$")
    due_date: Optional[datetime] = None
    case_id: Optional[int] = None
    transfer_id: Optional[int] = None
    exemption_id: Optional[int] = None


class TaskAssignRequest(BaseModel):
    assigned_to: int
    notes: Optional[str] = None


class TaskCompleteRequest(BaseModel):
    notes: str = Field(min_length=3)


class TaskRead(_Base):
    id: int
    task_number: str
    task_type: str
    status: str
    priority: str
    student_id: Optional[int]
    title: str
    description: Optional[str]
    assigned_to: Optional[int]
    due_date: Optional[datetime]
    completed_at: Optional[datetime]
    resolution_notes: Optional[str]
    created_at: datetime


class WorkspaceSummary(BaseModel):
    summary: Dict[str, int]
    open_tasks: List[Dict[str, Any]]


# ── Prerequisite Validation ───────────────────────────────────────────────────

class PrerequisiteCheckRequest(BaseModel):
    course_id: int
    term_id: int


class PrerequisiteValidationRead(_Base):
    id: int
    student_id: int
    course_id: int
    course_code: str
    is_eligible: bool
    missing_prereqs: List[Dict[str, Any]]
    satisfied_prereqs: List[Dict[str, Any]]
    override_applied: bool
    policy_source: Optional[str]
    validated_at: datetime


# ── Full Student Enterprise Profile ──────────────────────────────────────────

class StudentEnterpriseProfile(BaseModel):
    """Aggregated enterprise view of a student — all history combined."""
    student_id: int
    student_number: str
    name: str
    program: Optional[str]
    track: Optional[str]
    current_cgpa: float
    academic_standing: str
    cohort: Optional[Dict[str, Any]]
    open_cases: int
    pending_transfers: int
    pending_exemptions: int
    document_count: int
    unverified_documents: int
    record_version: Optional[int]
    open_tasks: int
    computed_at: datetime
