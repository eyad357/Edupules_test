"""
EduGuard AI — Sprint 5 Schemas
================================
Pydantic v2 schemas for all Sprint 5 modules.
"""

from __future__ import annotations
from datetime import date, datetime, time
from typing import Any, Dict, List, Optional, Union
from decimal import Decimal

from pydantic import BaseModel, Field, field_validator, ConfigDict


# ─────────────────────────────────────────────────────────────────────────────
# BASE
# ─────────────────────────────────────────────────────────────────────────────

class S5Base(BaseModel):
    model_config = ConfigDict(from_attributes=True)


# ─────────────────────────────────────────────────────────────────────────────
# MODULE A: CONFIGURATION CENTER
# ─────────────────────────────────────────────────────────────────────────────

class ConfigCategoryOut(S5Base):
    id:          int
    key:         str
    label:       str
    description: Optional[str] = None
    icon:        Optional[str] = None
    sort_order:  int = 0
    is_active:   bool = True


class ConfigSettingOut(S5Base):
    id:               int
    category_id:      Optional[int] = None
    key:              str
    label:            str
    description:      Optional[str] = None
    data_type:        str
    current_value:    Optional[str] = None
    default_value:    Optional[str] = None
    min_value:        Optional[str] = None
    max_value:        Optional[str] = None
    allowed_values:   Optional[Any] = None
    is_required:      bool = False
    is_sensitive:     bool = False
    requires_restart: bool = False
    program_id:       Optional[int] = None
    sort_order:       int = 0
    updated_at:       Optional[datetime] = None


class ConfigSettingUpdate(BaseModel):
    value:  str
    reason: Optional[str] = None


class ConfigSettingBulkUpdate(BaseModel):
    updates: List[Dict[str, str]]  # [{key, value, reason?}]


class ConfigAuditOut(S5Base):
    id:           int
    setting_key:  str
    old_value:    Optional[str] = None
    new_value:    Optional[str] = None
    changed_by:   Optional[int] = None
    change_reason: Optional[str] = None
    created_at:   datetime


class ConfigCategoryWithSettings(ConfigCategoryOut):
    settings: List[ConfigSettingOut] = []


# ─────────────────────────────────────────────────────────────────────────────
# MODULE B: WORKFLOW ENGINE
# ─────────────────────────────────────────────────────────────────────────────

class WorkflowTemplateCreate(BaseModel):
    name:          str
    description:   Optional[str] = None
    case_type:     Optional[str] = None
    max_days_sla:  Optional[int] = None
    auto_escalate: bool = False


class WorkflowTemplateOut(S5Base):
    id:            int
    name:          str
    description:   Optional[str] = None
    case_type:     Optional[str] = None
    is_active:     bool
    max_days_sla:  Optional[int] = None
    auto_escalate: bool
    version:       int
    created_at:    datetime


class WorkflowStepCreate(BaseModel):
    template_id:   int
    step_number:   int
    name:          str
    step_type:     str
    assigned_role: Optional[str] = None
    sla_hours:     Optional[int] = None
    is_optional:   bool = False
    conditions:    Optional[Dict] = None
    actions:       Optional[Dict] = None


class WorkflowStepOut(S5Base):
    id:            int
    template_id:   int
    step_number:   int
    name:          str
    step_type:     str
    assigned_role: Optional[str] = None
    sla_hours:     Optional[int] = None
    is_optional:   bool


class WorkflowInstanceOut(S5Base):
    id:           int
    template_id:  Optional[int] = None
    case_id:      Optional[int] = None
    student_id:   Optional[int] = None
    current_step: int
    status:       str
    started_at:   datetime
    due_at:       Optional[datetime] = None
    completed_at: Optional[datetime] = None


class WorkflowStepAction(BaseModel):
    decision: str
    notes:    Optional[str] = None


class WorkflowDashboardOut(BaseModel):
    total_active:    int
    total_completed: int
    sla_breached:    int
    pending_my_action: int
    recent_instances: List[WorkflowInstanceOut]


# ─────────────────────────────────────────────────────────────────────────────
# MODULE C: ACADEMIC CALENDAR
# ─────────────────────────────────────────────────────────────────────────────

class AcademicYearCreate(BaseModel):
    label:      str
    start_date: date
    end_date:   date
    is_current: bool = False
    notes:      Optional[str] = None


class AcademicYearOut(S5Base):
    id:         int
    label:      str
    start_date: date
    end_date:   date
    is_current: bool
    is_active:  bool
    notes:      Optional[str] = None


class CalendarEventCreate(BaseModel):
    academic_year_id:     int
    term_id:              Optional[int] = None
    event_type:           str
    label:                str
    description:          Optional[str] = None
    start_date:           date
    end_date:             Optional[date] = None
    affects_all_programs: bool = True
    program_id:           Optional[int] = None
    metadata:             Optional[Dict] = None


class CalendarEventOut(S5Base):
    id:                   int
    academic_year_id:     Optional[int] = None
    term_id:              Optional[int] = None
    event_type:           str
    label:                str
    description:          Optional[str] = None
    start_date:           date
    end_date:             Optional[date] = None
    affects_all_programs: bool
    program_id:           Optional[int] = None
    is_active:            bool
    created_at:           datetime


class CalendarDashboardOut(BaseModel):
    current_year:     Optional[AcademicYearOut] = None
    upcoming_events:  List[CalendarEventOut]
    registration_open: bool
    add_drop_open:    bool
    exam_period:      bool
    days_to_next_event: Optional[int] = None
    next_event:       Optional[CalendarEventOut] = None


# ─────────────────────────────────────────────────────────────────────────────
# MODULE D: STUDENT SUCCESS
# ─────────────────────────────────────────────────────────────────────────────

class EarlyWarningOut(S5Base):
    id:              int
    student_id:      int
    warning_type:    str
    severity:        str
    status:          str
    title:           str
    description:     Optional[str] = None
    triggered_value: Optional[float] = None
    threshold_value: Optional[float] = None
    term_id:         Optional[int] = None
    course_id:       Optional[int] = None
    auto_generated:  bool
    created_at:      datetime


class EarlyWarningAcknowledge(BaseModel):
    notes: Optional[str] = None


class SuccessScoreOut(S5Base):
    id:                      int
    student_id:              int
    score:                   float
    band:                    str
    cgpa_score:              float
    attendance_score:        float
    course_completion_score: float
    progress_score:          float
    risk_score:              float
    active_warnings:         int
    active_interventions:    int
    trend:                   str
    computed_at:             datetime


class GraduationReadinessOut(S5Base):
    student_id:              int
    readiness_pct:           float
    status:                  str
    total_required_credits:  int
    completed_credits:       int
    remaining_credits:       int
    total_required_courses:  int
    completed_courses:       int
    missing_required:        Optional[List[str]] = None
    cgpa_eligible:           bool
    uc_requirements_met:     bool
    pending_issues:          Optional[List[str]] = None
    estimated_graduation_term: Optional[str] = None
    computed_at:             datetime


class InterventionS5Create(BaseModel):
    student_id:        int
    warning_id:        Optional[int] = None
    assigned_to:       Optional[int] = None
    intervention_type: str
    title:             str
    description:       Optional[str] = None
    priority:          str = "medium"
    due_date:          Optional[date] = None


class InterventionS5Out(S5Base):
    id:                 int
    student_id:         int
    warning_id:         Optional[int] = None
    assigned_to:        Optional[int] = None
    status:             str
    intervention_type:  str
    title:              str
    description:        Optional[str] = None
    recommendations:    Optional[Any] = None
    target_gpa:         Optional[float] = None
    target_cgpa:        Optional[float] = None
    marks_needed:       Optional[Any] = None
    required_next_gpa:  Optional[float] = None
    graduation_path:    Optional[Any] = None
    priority:           str
    due_date:           Optional[date] = None
    completed_at:       Optional[datetime] = None
    outcome:            Optional[str] = None
    created_at:         datetime


class EscalationCreate(BaseModel):
    student_id:      int
    warning_id:      Optional[int] = None
    intervention_id: Optional[int] = None
    from_level:      str
    to_level:        str
    reason:          str
    assigned_to:     Optional[int] = None


class EscalationOut(S5Base):
    id:                  int
    student_id:          int
    from_level:          str
    to_level:            str
    reason:              str
    status:              str
    escalated_by:        Optional[int] = None
    assigned_to:         Optional[int] = None
    response_notes:      Optional[str] = None
    responded_at:        Optional[datetime] = None
    resolved_at:         Optional[datetime] = None
    response_time_hours: Optional[float] = None
    created_at:          datetime


class AdvisorNoteCreate(BaseModel):
    student_id:      int
    intervention_id: Optional[int] = None
    note_type:       str = "general"
    content:         str
    is_private:      bool = False


class AdvisorNoteOut(S5Base):
    id:              int
    intervention_id: Optional[int] = None
    student_id:      int
    author_id:       Optional[int] = None
    note_type:       str
    content:         str
    is_private:      bool
    created_at:      datetime


class AdvisorMeetingCreate(BaseModel):
    student_id:       int
    intervention_id:  Optional[int] = None
    meeting_type:     str = "in_person"
    scheduled_at:     datetime
    duration_minutes: Optional[int] = None
    notes:            Optional[str] = None
    follow_up_date:   Optional[date] = None


class AdvisorMeetingOut(S5Base):
    id:               int
    student_id:       int
    advisor_id:       Optional[int] = None
    intervention_id:  Optional[int] = None
    meeting_type:     str
    scheduled_at:     datetime
    duration_minutes: Optional[int] = None
    status:           str
    notes:            Optional[str] = None
    outcomes:         Optional[Any] = None
    follow_up_date:   Optional[date] = None
    created_at:       datetime


# Full Student Success Dashboard
class StudentSuccessDashboardOut(BaseModel):
    student_id:          int
    student_name:        str
    student_code:        str
    program_name:        Optional[str] = None
    current_gpa:         Optional[float] = None
    current_cgpa:        Optional[float] = None
    academic_standing:   str
    success_score:       Optional[SuccessScoreOut] = None
    graduation_readiness: Optional[GraduationReadinessOut] = None
    active_warnings:     List[EarlyWarningOut]
    active_interventions: List[InterventionS5Out]
    risk_level:          str
    total_credits_completed: int
    credits_remaining:   int
    regular_semesters:   int
    dismissal_risk:      bool
    recommendations:     List[str]
    timeline_summary:    List[Dict[str, Any]]


# Advisor Dashboard
class AdvisorDashboardOut(BaseModel):
    advisor_id:          int
    total_assigned:      int
    at_risk_count:       int
    critical_count:      int
    active_interventions: int
    meetings_this_week:  int
    pending_escalations: int
    recent_warnings:     List[EarlyWarningOut]
    my_interventions:    List[InterventionS5Out]


# Retention Dashboard
class RetentionDashboardOut(BaseModel):
    total_students:         int
    active_students:        int
    below_2_cgpa:           int
    between_2_and_2_5_cgpa: int
    above_2_5_cgpa:         int
    dismissal_risk_count:   int
    probation_count:        int
    expected_graduates:     int
    graduation_delay_count: int
    critical_warnings_count: int
    avg_success_score:      Optional[float] = None
    avg_cgpa:               Optional[float] = None
    retention_rate:         Optional[float] = None
    cgpa_distribution:      List[Dict[str, Any]]
    risk_trend:             List[Dict[str, Any]]
    success_trend:          List[Dict[str, Any]]


# ─────────────────────────────────────────────────────────────────────────────
# MODULE E: NOTIFICATIONS
# ─────────────────────────────────────────────────────────────────────────────

class NotificationTemplateOut(S5Base):
    id:               int
    key:              str
    name:             str
    channel:          str
    subject_template: Optional[str] = None
    body_template:    str
    variables:        Optional[Any] = None
    is_active:        bool


class NotificationQueueCreate(BaseModel):
    recipient_id:   int
    template_key:   Optional[str] = None
    channel:        str = "in_app"
    subject:        Optional[str] = None
    body:           str
    variables:      Optional[Dict] = None
    priority:       str = "normal"
    related_entity: Optional[str] = None
    related_id:     Optional[int] = None


class NotificationOut(S5Base):
    id:             int
    recipient_id:   int
    channel:        str
    subject:        Optional[str] = None
    body:           str
    priority:       str
    status:         str
    scheduled_at:   datetime
    sent_at:        Optional[datetime] = None
    retry_count:    int
    related_entity: Optional[str] = None
    related_id:     Optional[int] = None
    created_at:     datetime


class NotificationPreferenceOut(S5Base):
    user_id:             int
    in_app_enabled:      bool
    email_enabled:       bool
    sms_enabled:         bool
    push_enabled:        bool
    warning_alerts:      bool
    intervention_alerts: bool
    grade_alerts:        bool
    calendar_alerts:     bool
    digest_frequency:    str


class NotificationPreferenceUpdate(BaseModel):
    in_app_enabled:      Optional[bool] = None
    email_enabled:       Optional[bool] = None
    sms_enabled:         Optional[bool] = None
    push_enabled:        Optional[bool] = None
    warning_alerts:      Optional[bool] = None
    intervention_alerts: Optional[bool] = None
    grade_alerts:        Optional[bool] = None
    calendar_alerts:     Optional[bool] = None
    digest_frequency:    Optional[str] = None


# ─────────────────────────────────────────────────────────────────────────────
# MODULE F: SEED DATA
# ─────────────────────────────────────────────────────────────────────────────

class SeedBatchCreate(BaseModel):
    label:         Optional[str] = None
    description:   Optional[str] = None
    student_count: int = Field(default=500, ge=1, le=500)


class SeedBatchOut(S5Base):
    id:            int
    batch_key:     str
    label:         Optional[str] = None
    description:   Optional[str] = None
    student_count: int
    status:        str
    created_at:    datetime
    deleted_at:    Optional[datetime] = None


class SeedBatchProgress(BaseModel):
    batch_key:      str
    students_seeded: int
    status:         str
    message:        str


# ─────────────────────────────────────────────────────────────────────────────
# MODULE G/H: REPORTS & ANALYTICS
# ─────────────────────────────────────────────────────────────────────────────

class ReportDefinitionOut(S5Base):
    id:             int
    key:            str
    name:           str
    description:    Optional[str] = None
    report_type:    str
    default_format: str
    is_active:      bool


class ReportRunCreate(BaseModel):
    report_key:  str
    parameters:  Optional[Dict[str, Any]] = None
    format:      str = "json"


class ReportRunOut(S5Base):
    id:           int
    report_key:   Optional[str] = None
    parameters:   Optional[Any] = None
    format:       str
    status:       str
    row_count:    Optional[int] = None
    started_at:   datetime
    completed_at: Optional[datetime] = None
    error_message: Optional[str] = None


class RetentionSnapshotOut(S5Base):
    id:                      int
    snapshot_date:           date
    term_id:                 Optional[int] = None
    program_id:              Optional[int] = None
    total_students:          int
    active_students:         int
    below_2_cgpa:            int
    between_2_and_2_5_cgpa:  int
    above_2_5_cgpa:          int
    dismissal_risk_count:    int
    probation_count:         int
    expected_graduates:      int
    graduation_delay_count:  int
    critical_warnings_count: int
    avg_success_score:       Optional[float] = None
    avg_cgpa:                Optional[float] = None
    retention_rate:          Optional[float] = None
    created_at:              datetime


# Pagination wrapper
class PaginatedResponse(BaseModel):
    items:   List[Any]
    total:   int
    page:    int
    size:    int
    pages:   int
