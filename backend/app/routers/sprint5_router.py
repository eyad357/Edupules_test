"""
EduGuard AI — Sprint 5: All API Routers
========================================
Mounts at /api/v2/sprint5/ with sub-routers for each module.

Module A: /config
Module B: /workflow
Module C: /calendar
Module D: /student-success
Module E: /notifications
Module F: /seed-data
Module G: /reports
Module H: /retention
"""

from __future__ import annotations

import math
from typing import Any, List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, BackgroundTasks
from sqlalchemy import desc, func
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.core.security import get_current_user

from app.services.sprint5_services import (
    ConfigCenterService,
    EarlyWarningEngine,
    SuccessScoreEngine,
    GraduationReadinessEngine,
    InterventionEngine,
    EscalationEngine,
    NotificationService,
    StudentSuccessDashboardService,
    RetentionAnalyticsService,
)
from app.services.sprint5_seed_generator import SeedDataGenerator

from app.schemas.sprint5_schemas import (
    # Config
    ConfigCategoryOut, ConfigSettingOut, ConfigSettingUpdate,
    ConfigSettingBulkUpdate, ConfigAuditOut, ConfigCategoryWithSettings,
    # Workflow
    WorkflowTemplateCreate, WorkflowTemplateOut, WorkflowStepCreate,
    WorkflowStepOut, WorkflowInstanceOut, WorkflowStepAction, WorkflowDashboardOut,
    # Calendar
    AcademicYearCreate, AcademicYearOut, CalendarEventCreate,
    CalendarEventOut, CalendarDashboardOut,
    # Student Success
    EarlyWarningOut, EarlyWarningAcknowledge, SuccessScoreOut,
    GraduationReadinessOut, InterventionS5Create, InterventionS5Out,
    EscalationCreate, EscalationOut, AdvisorNoteCreate, AdvisorNoteOut,
    AdvisorMeetingCreate, AdvisorMeetingOut, StudentSuccessDashboardOut,
    AdvisorDashboardOut,
    # Notifications
    NotificationTemplateOut, NotificationQueueCreate, NotificationOut,
    NotificationPreferenceOut, NotificationPreferenceUpdate,
    # Seed
    SeedBatchCreate, SeedBatchOut, SeedBatchProgress,
    # Reports
    ReportDefinitionOut, ReportRunCreate, ReportRunOut,
    RetentionSnapshotOut, RetentionDashboardOut,
    PaginatedResponse,
)

router = APIRouter(prefix="/api/v2/sprint5", tags=["Sprint 5 — Student Success & Academic Operations"])


# ═════════════════════════════════════════════════════════════════════════════
# MODULE A: CONFIGURATION CENTER
# ═════════════════════════════════════════════════════════════════════════════

config_router = APIRouter(prefix="/config", tags=["A — Configuration Center"])


@config_router.get("/categories", response_model=List[ConfigCategoryOut])
def list_categories(db: Session = Depends(get_db), _=Depends(get_current_user)):
    """List all configuration categories."""
    return ConfigCenterService.get_all_categories(db)


@config_router.get("/categories/{category_key}", response_model=ConfigCategoryWithSettings)
def get_category_with_settings(
    category_key: str,
    db: Session = Depends(get_db),
    _=Depends(get_current_user)
):
    """Get a category with all its settings."""
    from app.models.sprint5_models import SystemConfigCategory
    cat = db.query(SystemConfigCategory).filter(
        SystemConfigCategory.key == category_key
    ).first()
    if not cat:
        raise HTTPException(404, f"Category '{category_key}' not found")
    settings = ConfigCenterService.get_settings_by_category(db, category_key)
    return {**vars(cat), "settings": settings}


@config_router.get("/settings", response_model=List[ConfigSettingOut])
def list_all_settings(
    category: Optional[str] = None,
    db: Session = Depends(get_db),
    _=Depends(get_current_user)
):
    """List all settings, optionally filtered by category."""
    from app.models.sprint5_models import SystemConfigSetting, SystemConfigCategory
    q = db.query(SystemConfigSetting)
    if category:
        cat = db.query(SystemConfigCategory).filter(SystemConfigCategory.key == category).first()
        if cat:
            q = q.filter(SystemConfigSetting.category_id == cat.id)
    return q.order_by(SystemConfigSetting.sort_order).all()


@config_router.get("/settings/{key}", response_model=ConfigSettingOut)
def get_setting(key: str, db: Session = Depends(get_db), _=Depends(get_current_user)):
    """Get a single setting by key."""
    from app.models.sprint5_models import SystemConfigSetting
    s = db.query(SystemConfigSetting).filter(SystemConfigSetting.key == key).first()
    if not s:
        raise HTTPException(404, f"Setting '{key}' not found")
    return s


@config_router.put("/settings/{key}", response_model=ConfigSettingOut)
def update_setting(
    key: str,
    payload: ConfigSettingUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    """Update a configuration setting value."""
    ok = ConfigCenterService.update(db, key, payload.value, current_user.id, payload.reason)
    if not ok:
        raise HTTPException(404, f"Setting '{key}' not found")
    from app.models.sprint5_models import SystemConfigSetting
    return db.query(SystemConfigSetting).filter(SystemConfigSetting.key == key).first()


@config_router.put("/settings", response_model=List[ConfigSettingOut])
def bulk_update_settings(
    payload: ConfigSettingBulkUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    """Bulk update multiple settings."""
    results = []
    for upd in payload.updates:
        key   = upd.get("key")
        value = upd.get("value")
        reason = upd.get("reason")
        if key and value is not None:
            ConfigCenterService.update(db, key, value, current_user.id, reason)
    from app.models.sprint5_models import SystemConfigSetting
    return db.query(SystemConfigSetting).all()


@config_router.get("/settings/{key}/audit", response_model=List[ConfigAuditOut])
def get_setting_audit(
    key: str,
    limit: int = 50,
    db: Session = Depends(get_db),
    _=Depends(get_current_user)
):
    """Get audit history for a setting."""
    return ConfigCenterService.get_audit_history(db, key, limit)


@config_router.post("/settings/{key}/rollback/{audit_id}")
def rollback_setting(
    key: str,
    audit_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    """Rollback a setting to a previous value."""
    ok = ConfigCenterService.rollback(db, audit_id, current_user.id)
    if not ok:
        raise HTTPException(404, "Audit record not found")
    return {"message": "Setting rolled back successfully", "audit_id": audit_id}


# ═════════════════════════════════════════════════════════════════════════════
# MODULE B: WORKFLOW ENGINE
# ═════════════════════════════════════════════════════════════════════════════

workflow_router = APIRouter(prefix="/workflow", tags=["B — Workflow Engine"])


@workflow_router.get("/dashboard", response_model=WorkflowDashboardOut)
def workflow_dashboard(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    """Workflow engine dashboard with statistics."""
    from app.models.sprint5_models import WorkflowInstance, WorkflowStepInstance
    from datetime import datetime, timezone

    total_active    = db.query(func.count(WorkflowInstance.id)).filter(WorkflowInstance.status == "active").scalar() or 0
    total_completed = db.query(func.count(WorkflowInstance.id)).filter(WorkflowInstance.status == "completed").scalar() or 0

    now = datetime.now(timezone.utc)
    sla_breached = db.query(func.count(WorkflowInstance.id)).filter(
        WorkflowInstance.status == "active",
        WorkflowInstance.due_at < now,
    ).scalar() or 0

    pending_my_action = db.query(func.count(WorkflowStepInstance.id)).filter(
        WorkflowStepInstance.assigned_to == current_user.id,
        WorkflowStepInstance.status == "active",
    ).scalar() or 0

    recent = db.query(WorkflowInstance).order_by(desc(WorkflowInstance.created_at)).limit(10).all()
    return {
        "total_active": total_active,
        "total_completed": total_completed,
        "sla_breached": sla_breached,
        "pending_my_action": pending_my_action,
        "recent_instances": recent,
    }


@workflow_router.get("/templates", response_model=List[WorkflowTemplateOut])
def list_templates(db: Session = Depends(get_db), _=Depends(get_current_user)):
    from app.models.sprint5_models import WorkflowTemplate
    return db.query(WorkflowTemplate).filter(WorkflowTemplate.is_active == True).all()


@workflow_router.post("/templates", response_model=WorkflowTemplateOut)
def create_template(
    payload: WorkflowTemplateCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    from app.models.sprint5_models import WorkflowTemplate
    tmpl = WorkflowTemplate(**payload.model_dump(), created_by=current_user.id)
    db.add(tmpl)
    db.commit()
    db.refresh(tmpl)
    return tmpl


@workflow_router.post("/templates/{template_id}/steps", response_model=WorkflowStepOut)
def add_step(
    template_id: int,
    payload: WorkflowStepCreate,
    db: Session = Depends(get_db),
    _=Depends(get_current_user)
):
    from app.models.sprint5_models import WorkflowStep
    step = WorkflowStep(**payload.model_dump())
    db.add(step)
    db.commit()
    db.refresh(step)
    return step


@workflow_router.get("/instances", response_model=List[WorkflowInstanceOut])
def list_instances(
    status: Optional[str] = None,
    student_id: Optional[int] = None,
    skip: int = 0, limit: int = 20,
    db: Session = Depends(get_db),
    _=Depends(get_current_user)
):
    from app.models.sprint5_models import WorkflowInstance
    q = db.query(WorkflowInstance)
    if status:
        q = q.filter(WorkflowInstance.status == status)
    if student_id:
        q = q.filter(WorkflowInstance.student_id == student_id)
    return q.order_by(desc(WorkflowInstance.created_at)).offset(skip).limit(limit).all()


@workflow_router.get("/instances/{instance_id}", response_model=WorkflowInstanceOut)
def get_instance(instance_id: int, db: Session = Depends(get_db), _=Depends(get_current_user)):
    from app.models.sprint5_models import WorkflowInstance
    inst = db.query(WorkflowInstance).filter(WorkflowInstance.id == instance_id).first()
    if not inst:
        raise HTTPException(404, "Workflow instance not found")
    return inst


@workflow_router.post("/instances/{instance_id}/steps/{step_id}/action")
def action_on_step(
    instance_id: int,
    step_id: int,
    payload: WorkflowStepAction,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    """Record a decision on a workflow step (approve/reject/escalate)."""
    from app.models.sprint5_models import WorkflowStepInstance, WorkflowInstance
    from datetime import datetime, timezone

    step_inst = db.query(WorkflowStepInstance).filter(
        WorkflowStepInstance.instance_id == instance_id,
        WorkflowStepInstance.id == step_id,
    ).first()
    if not step_inst:
        raise HTTPException(404, "Step instance not found")

    now = datetime.now(timezone.utc)
    step_inst.decision = payload.decision
    step_inst.notes = payload.notes
    step_inst.completed_at = now
    step_inst.status = "completed"

    if step_inst.started_at:
        started = step_inst.started_at
        if started.tzinfo is None:
            started = started.replace(tzinfo=timezone.utc)
        step_inst.response_time_hours = round((now - started).total_seconds() / 3600, 2)

    # Advance or close the workflow instance
    instance = db.query(WorkflowInstance).filter(WorkflowInstance.id == instance_id).first()
    if instance:
        if payload.decision == "rejected":
            instance.status = "rejected"
            instance.completed_at = now
        elif payload.decision == "approved":
            instance.current_step += 1
            # Check if all steps done — simplified
            from app.models.sprint5_models import WorkflowTemplate, WorkflowStep
            if instance.template_id:
                max_step = db.query(func.max(WorkflowStep.step_number)).filter(
                    WorkflowStep.template_id == instance.template_id
                ).scalar() or 1
                if instance.current_step > max_step:
                    instance.status = "completed"
                    instance.completed_at = now

    db.commit()
    return {"message": "Step action recorded", "decision": payload.decision}


@workflow_router.get("/sla-rules")
def list_sla_rules(db: Session = Depends(get_db), _=Depends(get_current_user)):
    from app.models.sprint5_models import WorkflowSLARule
    return db.query(WorkflowSLARule).filter(WorkflowSLARule.is_active == True).all()


@workflow_router.get("/analytics")
def workflow_analytics(db: Session = Depends(get_db), _=Depends(get_current_user)):
    """Workflow analytics — completion rates, avg response times."""
    from app.models.sprint5_models import WorkflowInstance, WorkflowStepInstance

    statuses = db.query(
        WorkflowInstance.status,
        func.count(WorkflowInstance.id).label("count")
    ).group_by(WorkflowInstance.status).all()

    avg_response = db.query(
        func.avg(WorkflowStepInstance.response_time_hours)
    ).filter(WorkflowStepInstance.response_time_hours.isnot(None)).scalar()

    return {
        "by_status":           [{"status": s, "count": c} for s, c in statuses],
        "avg_response_hours":  round(float(avg_response), 2) if avg_response else 0,
    }


# ═════════════════════════════════════════════════════════════════════════════
# MODULE C: ACADEMIC CALENDAR
# ═════════════════════════════════════════════════════════════════════════════

calendar_router = APIRouter(prefix="/calendar", tags=["C — Academic Calendar"])


@calendar_router.get("/dashboard", response_model=CalendarDashboardOut)
def calendar_dashboard(db: Session = Depends(get_db), _=Depends(get_current_user)):
    """Calendar dashboard with current state and upcoming events."""
    from app.models.sprint5_models import AcademicYear, CalendarEvent, CalendarEventTypeEnum
    from datetime import date, timedelta

    today = date.today()
    current_year = db.query(AcademicYear).filter(AcademicYear.is_current == True).first()

    upcoming = db.query(CalendarEvent).filter(
        CalendarEvent.start_date >= today,
        CalendarEvent.is_active == True,
    ).order_by(CalendarEvent.start_date).limit(10).all()

    def _is_active(event_type: str) -> bool:
        return db.query(CalendarEvent).filter(
            CalendarEvent.event_type == event_type,
            CalendarEvent.start_date <= today,
            CalendarEvent.end_date >= today,
            CalendarEvent.is_active == True,
        ).first() is not None

    reg_open   = _is_active("registration_open")
    add_drop   = _is_active("add_drop_open")
    exam       = _is_active("exam_period_start")
    next_event = upcoming[0] if upcoming else None
    days_to_next = (next_event.start_date - today).days if next_event else None

    return {
        "current_year":      current_year,
        "upcoming_events":   upcoming,
        "registration_open": reg_open,
        "add_drop_open":     add_drop,
        "exam_period":       exam,
        "days_to_next_event": days_to_next,
        "next_event":        next_event,
    }


@calendar_router.get("/years", response_model=List[AcademicYearOut])
def list_years(db: Session = Depends(get_db), _=Depends(get_current_user)):
    from app.models.sprint5_models import AcademicYear
    return db.query(AcademicYear).order_by(desc(AcademicYear.start_date)).all()


@calendar_router.post("/years", response_model=AcademicYearOut)
def create_year(
    payload: AcademicYearCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    from app.models.sprint5_models import AcademicYear
    if payload.is_current:
        db.query(AcademicYear).update({"is_current": False})
    year = AcademicYear(**payload.model_dump(), created_by=current_user.id)
    db.add(year)
    db.commit()
    db.refresh(year)
    return year


@calendar_router.get("/events", response_model=List[CalendarEventOut])
def list_events(
    year_id: Optional[int] = None,
    event_type: Optional[str] = None,
    from_date: Optional[str] = None,
    to_date: Optional[str] = None,
    db: Session = Depends(get_db),
    _=Depends(get_current_user)
):
    from app.models.sprint5_models import CalendarEvent
    from datetime import date as dt
    q = db.query(CalendarEvent).filter(CalendarEvent.is_active == True)
    if year_id:
        q = q.filter(CalendarEvent.academic_year_id == year_id)
    if event_type:
        q = q.filter(CalendarEvent.event_type == event_type)
    if from_date:
        q = q.filter(CalendarEvent.start_date >= from_date)
    if to_date:
        q = q.filter(CalendarEvent.start_date <= to_date)
    return q.order_by(CalendarEvent.start_date).all()


@calendar_router.post("/events", response_model=CalendarEventOut)
def create_event(
    payload: CalendarEventCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    from app.models.sprint5_models import CalendarEvent, CalendarAudit
    event = CalendarEvent(**payload.model_dump(), created_by=current_user.id)
    db.add(event)
    db.flush()
    audit = CalendarAudit(event_id=event.id, action="created",
                          new_data=payload.model_dump(mode="json"),
                          changed_by=current_user.id)
    db.add(audit)
    db.commit()
    db.refresh(event)
    return event


@calendar_router.put("/events/{event_id}", response_model=CalendarEventOut)
def update_event(
    event_id: int,
    payload: CalendarEventCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    from app.models.sprint5_models import CalendarEvent, CalendarAudit
    event = db.query(CalendarEvent).filter(CalendarEvent.id == event_id).first()
    if not event:
        raise HTTPException(404, "Event not found")
    old_data = {c.name: str(getattr(event, c.name)) for c in event.__table__.columns}
    for k, v in payload.model_dump().items():
        setattr(event, k, v)
    audit = CalendarAudit(event_id=event.id, action="updated",
                          old_data=old_data, new_data=payload.model_dump(mode="json"),
                          changed_by=current_user.id)
    db.add(audit)
    db.commit()
    db.refresh(event)
    return event


@calendar_router.delete("/events/{event_id}")
def delete_event(
    event_id: int,
    db: Session = Depends(get_db),
    _=Depends(get_current_user)
):
    from app.models.sprint5_models import CalendarEvent
    event = db.query(CalendarEvent).filter(CalendarEvent.id == event_id).first()
    if not event:
        raise HTTPException(404, "Event not found")
    event.is_active = False
    db.commit()
    return {"message": "Event deactivated"}


@calendar_router.post("/years/{year_id}/snapshot")
def snapshot_calendar(
    year_id: int,
    notes: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    """Create a versioned snapshot of all calendar events for a year."""
    from app.models.sprint5_models import CalendarEvent, CalendarVersion, AcademicYear
    year = db.query(AcademicYear).filter(AcademicYear.id == year_id).first()
    if not year:
        raise HTTPException(404, "Academic year not found")
    events = db.query(CalendarEvent).filter(
        CalendarEvent.academic_year_id == year_id,
        CalendarEvent.is_active == True
    ).all()
    last_ver = db.query(func.max(CalendarVersion.version_number)).filter(
        CalendarVersion.academic_year_id == year_id
    ).scalar() or 0
    snap = CalendarVersion(
        academic_year_id=year_id,
        version_number=last_ver + 1,
        snapshot={"events": [
            {c.name: str(getattr(e, c.name)) for c in e.__table__.columns}
            for e in events
        ]},
        notes=notes,
        created_by=current_user.id,
    )
    db.add(snap)
    db.commit()
    db.refresh(snap)
    return {"version": snap.version_number, "event_count": len(events)}


# ═════════════════════════════════════════════════════════════════════════════
# MODULE D: STUDENT SUCCESS PLATFORM
# ═════════════════════════════════════════════════════════════════════════════

success_router = APIRouter(prefix="/student-success", tags=["D — Student Success Platform"])


# ── D3: Student Success Dashboard ────────────────────────────────────────────

@success_router.get("/dashboard/{student_id}")
def student_success_dashboard(
    student_id: int,
    db: Session = Depends(get_db),
    _=Depends(get_current_user)
):
    """Full student success dashboard (D3) with all real-data computations."""
    data = StudentSuccessDashboardService.get_student_dashboard(db, student_id)
    if not data:
        raise HTTPException(404, "Student not found")
    return data


# ── D1: Early Warning System ─────────────────────────────────────────────────

@success_router.get("/warnings", response_model=List[EarlyWarningOut])
def list_warnings(
    student_id: Optional[int] = None,
    severity: Optional[str] = None,
    status: Optional[str] = "active",
    warning_type: Optional[str] = None,
    skip: int = 0, limit: int = 50,
    db: Session = Depends(get_db),
    _=Depends(get_current_user)
):
    """List warnings filtered by student, severity, status, type."""
    from app.models.sprint5_models import StudentEarlyWarning
    q = db.query(StudentEarlyWarning)
    if student_id:
        q = q.filter(StudentEarlyWarning.student_id == student_id)
    if severity:
        q = q.filter(StudentEarlyWarning.severity == severity)
    if status:
        q = q.filter(StudentEarlyWarning.status == status)
    if warning_type:
        q = q.filter(StudentEarlyWarning.warning_type == warning_type)
    return q.order_by(desc(StudentEarlyWarning.created_at)).offset(skip).limit(limit).all()


@success_router.get("/warnings/{student_id}", response_model=List[EarlyWarningOut])
def student_warnings(
    student_id: int,
    status: Optional[str] = None,
    db: Session = Depends(get_db),
    _=Depends(get_current_user)
):
    return EarlyWarningEngine.get_student_warnings(db, student_id, status)


@success_router.post("/warnings/run")
def run_warning_engine(
    student_id: Optional[int] = None,
    background_tasks: BackgroundTasks = BackgroundTasks(),
    db: Session = Depends(get_db),
    _=Depends(get_current_user)
):
    """Trigger the early warning engine for one or all students."""
    if student_id:
        new = EarlyWarningEngine.run_for_student(db, student_id)
        return {"student_id": student_id, "warnings_created": len(new)}
    else:
        result = EarlyWarningEngine.run_for_all(db)
        return result


@success_router.post("/warnings/{warning_id}/acknowledge")
def acknowledge_warning(
    warning_id: int,
    payload: EarlyWarningAcknowledge,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    ok = EarlyWarningEngine.acknowledge(db, warning_id, current_user.id, payload.notes)
    if not ok:
        raise HTTPException(404, "Warning not found")
    return {"message": "Warning acknowledged"}


# ── D2: Student Success Score ─────────────────────────────────────────────────

@success_router.post("/scores/compute/{student_id}", response_model=SuccessScoreOut)
def compute_success_score(
    student_id: int,
    term_id: Optional[int] = None,
    db: Session = Depends(get_db),
    _=Depends(get_current_user)
):
    """Compute and store a student success score."""
    score = SuccessScoreEngine.compute(db, student_id, term_id)
    if not score:
        raise HTTPException(404, "Student not found")
    return score


@success_router.get("/scores/{student_id}", response_model=SuccessScoreOut)
def get_latest_score(
    student_id: int,
    db: Session = Depends(get_db),
    _=Depends(get_current_user)
):
    """Get the latest success score for a student."""
    score = SuccessScoreEngine.get_latest(db, student_id)
    if not score:
        # Compute on-demand
        score = SuccessScoreEngine.compute(db, student_id)
    if not score:
        raise HTTPException(404, "Student not found or no data")
    return score


@success_router.get("/scores/{student_id}/history", response_model=List[SuccessScoreOut])
def get_score_history(
    student_id: int,
    limit: int = 12,
    db: Session = Depends(get_db),
    _=Depends(get_current_user)
):
    return SuccessScoreEngine.get_history(db, student_id, limit)


@success_router.get("/scores")
def scores_distribution(
    band: Optional[str] = None,
    program_id: Optional[int] = None,
    db: Session = Depends(get_db),
    _=Depends(get_current_user)
):
    """Distribution of success scores across all students."""
    from app.models.sprint5_models import StudentSuccessScore
    from sqlalchemy import func
    dist = db.query(
        StudentSuccessScore.band,
        func.count(StudentSuccessScore.id).label("count"),
        func.avg(StudentSuccessScore.score).label("avg_score"),
    ).group_by(StudentSuccessScore.band).all()
    return [{"band": r[0], "count": r[1], "avg_score": round(float(r[2]), 2)} for r in dist]


# ── D4: Graduation Readiness ──────────────────────────────────────────────────

@success_router.get("/graduation-readiness/{student_id}", response_model=GraduationReadinessOut)
def graduation_readiness(
    student_id: int,
    recompute: bool = False,
    db: Session = Depends(get_db),
    _=Depends(get_current_user)
):
    """Get graduation readiness for a student."""
    if recompute:
        rec = GraduationReadinessEngine.compute(db, student_id)
    else:
        rec = GraduationReadinessEngine.get_cached(db, student_id)
        if not rec:
            rec = GraduationReadinessEngine.compute(db, student_id)
    if not rec:
        raise HTTPException(404, "Student not found")
    return rec


@success_router.get("/graduation-readiness")
def list_graduation_readiness(
    status: Optional[str] = None,
    program_id: Optional[int] = None,
    skip: int = 0, limit: int = 50,
    db: Session = Depends(get_db),
    _=Depends(get_current_user)
):
    """List all students' graduation readiness."""
    from app.models.sprint5_models import GraduationReadinessCache
    q = db.query(GraduationReadinessCache)
    if status:
        q = q.filter(GraduationReadinessCache.status == status)
    total = q.count()
    items = q.order_by(desc(GraduationReadinessCache.readiness_pct)).offset(skip).limit(limit).all()
    return {"items": items, "total": total, "page": skip // limit + 1,
            "size": limit, "pages": math.ceil(total / limit)}


# ── D5: Intervention Engine ───────────────────────────────────────────────────

@success_router.post("/interventions/generate/{student_id}")
def generate_interventions(
    student_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    """Auto-generate intervention recommendations for a student."""
    ivs = InterventionEngine.generate_for_student(db, student_id, current_user.id)
    return {"student_id": student_id, "interventions_created": len(ivs)}


@success_router.get("/interventions/{student_id}", response_model=List[InterventionS5Out])
def get_interventions(
    student_id: int,
    status: Optional[str] = None,
    db: Session = Depends(get_db),
    _=Depends(get_current_user)
):
    return InterventionEngine.get_student_interventions(db, student_id, status)


@success_router.post("/interventions", response_model=InterventionS5Out)
def create_intervention(
    payload: InterventionS5Create,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    from app.models.sprint5_models import StudentInterventionS5
    iv = StudentInterventionS5(**payload.model_dump(), created_by=current_user.id)
    db.add(iv)
    db.commit()
    db.refresh(iv)
    return iv


@success_router.put("/interventions/{intervention_id}/status")
def update_intervention_status(
    intervention_id: int,
    status: str,
    outcome: Optional[str] = None,
    db: Session = Depends(get_db),
    _=Depends(get_current_user)
):
    ok = InterventionEngine.update_status(db, intervention_id, status, outcome)
    if not ok:
        raise HTTPException(404, "Intervention not found")
    return {"message": "Intervention status updated", "status": status}


@success_router.get("/interventions")
def list_all_interventions(
    status: Optional[str] = None,
    assigned_to: Optional[int] = None,
    priority: Optional[str] = None,
    skip: int = 0, limit: int = 50,
    db: Session = Depends(get_db),
    _=Depends(get_current_user)
):
    from app.models.sprint5_models import StudentInterventionS5
    q = db.query(StudentInterventionS5)
    if status:
        q = q.filter(StudentInterventionS5.status == status)
    if assigned_to:
        q = q.filter(StudentInterventionS5.assigned_to == assigned_to)
    if priority:
        q = q.filter(StudentInterventionS5.priority == priority)
    total = q.count()
    items = q.order_by(desc(StudentInterventionS5.created_at)).offset(skip).limit(limit).all()
    return {"items": items, "total": total, "page": skip // limit + 1,
            "size": limit, "pages": math.ceil(total / limit)}


# ── D6: Academic Health Timeline ──────────────────────────────────────────────

@success_router.get("/timeline/{student_id}")
def academic_health_timeline(
    student_id: int,
    db: Session = Depends(get_db),
    _=Depends(get_current_user)
):
    """Academic health timeline: GPA, CGPA, warnings, interventions, cases."""
    from app.models.models import Student
    from app.models.academic_models import StudentTermGPA, AcademicTerm
    from app.models.sprint5_models import StudentEarlyWarning, StudentInterventionS5, StudentSuccessScore

    student = db.query(Student).filter(Student.id == student_id).first()
    if not student:
        raise HTTPException(404, "Student not found")

    term_gpas = db.query(StudentTermGPA, AcademicTerm).join(
        AcademicTerm, StudentTermGPA.term_id == AcademicTerm.id, isouter=True
    ).filter(
        StudentTermGPA.student_id == student_id,
        StudentTermGPA.finalized == True,
    ).order_by(StudentTermGPA.created_at).all()

    gpa_history = [
        {
            "period": t.name if t else f"Term {tg.term_id}",
            "term_gpa": float(tg.term_gpa),
            "cgpa": float(tg.cgpa),
            "standing": tg.academic_standing,
            "credits_earned": int(tg.term_credit_hours_earned),
            "cumulative_earned": int(tg.cumulative_hours_earned),
            "is_summer": tg.is_summer,
        }
        for tg, t in term_gpas
    ]

    warnings = db.query(StudentEarlyWarning).filter(
        StudentEarlyWarning.student_id == student_id
    ).order_by(StudentEarlyWarning.created_at).all()

    interventions = db.query(StudentInterventionS5).filter(
        StudentInterventionS5.student_id == student_id
    ).order_by(StudentInterventionS5.created_at).all()

    scores = db.query(StudentSuccessScore).filter(
        StudentSuccessScore.student_id == student_id
    ).order_by(StudentSuccessScore.computed_at).all()

    # Try to get academic cases from existing Sprint 4 tables
    try:
        from app.models.enterprise_models import AcademicCase
        cases = db.query(AcademicCase).filter(
            AcademicCase.student_id == student_id
        ).order_by(AcademicCase.created_at).all()
        cases_data = [{"id": c.id, "type": c.case_type, "status": c.status,
                       "date": str(c.created_at)} for c in cases]
    except Exception:
        cases_data = []

    return {
        "student_id":    student_id,
        "student_name":  student.name,
        "gpa_history":   gpa_history,
        "warnings":      [{"id": w.id, "type": w.warning_type, "severity": w.severity,
                           "status": w.status, "title": w.title,
                           "date": str(w.created_at)} for w in warnings],
        "interventions": [{"id": i.id, "type": i.intervention_type, "title": i.title,
                           "status": i.status, "priority": i.priority,
                           "date": str(i.created_at)} for i in interventions],
        "success_scores": [{"score": float(s.score), "band": s.band, "trend": s.trend,
                            "date": str(s.computed_at)} for s in scores],
        "academic_cases": cases_data,
    }


# ── D7: Escalation Engine ─────────────────────────────────────────────────────

@success_router.post("/escalations/run")
def run_escalation_engine(
    db: Session = Depends(get_db),
    _=Depends(get_current_user)
):
    """Run auto-escalation for all unacknowledged warnings."""
    count = EscalationEngine.check_and_escalate(db)
    return {"escalations_created": count}


@success_router.post("/escalations", response_model=EscalationOut)
def create_escalation(
    payload: EscalationCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    from app.models.sprint5_models import StudentEscalation
    esc = StudentEscalation(**payload.model_dump(), escalated_by=current_user.id)
    db.add(esc)
    db.commit()
    db.refresh(esc)
    return esc


@success_router.get("/escalations/{student_id}", response_model=List[EscalationOut])
def get_student_escalations(
    student_id: int,
    db: Session = Depends(get_db),
    _=Depends(get_current_user)
):
    return EscalationEngine.get_student_escalations(db, student_id)


@success_router.get("/escalations")
def list_all_escalations(
    status: Optional[str] = None,
    level: Optional[str] = None,
    skip: int = 0, limit: int = 50,
    db: Session = Depends(get_db),
    _=Depends(get_current_user)
):
    from app.models.sprint5_models import StudentEscalation
    q = db.query(StudentEscalation)
    if status:
        q = q.filter(StudentEscalation.status == status)
    if level:
        q = q.filter(StudentEscalation.to_level == level)
    total = q.count()
    items = q.order_by(desc(StudentEscalation.created_at)).offset(skip).limit(limit).all()
    return {"items": items, "total": total}


@success_router.put("/escalations/{escalation_id}/resolve")
def resolve_escalation(
    escalation_id: int,
    notes: str,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    ok = EscalationEngine.resolve(db, escalation_id, current_user.id, notes)
    if not ok:
        raise HTTPException(404, "Escalation not found")
    return {"message": "Escalation resolved"}


# ── D8: Advisor / TA Platform ─────────────────────────────────────────────────

@success_router.get("/advisor/dashboard")
def advisor_dashboard(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    """TA/Advisor dashboard with assigned at-risk students and workload."""
    from app.models.sprint5_models import (
        StudentInterventionS5, StudentEarlyWarning, StudentEscalation
    )
    from datetime import datetime, timezone, timedelta

    now = datetime.now(timezone.utc)
    week_start = now - timedelta(days=7)

    my_interventions = db.query(StudentInterventionS5).filter(
        StudentInterventionS5.assigned_to == current_user.id,
        StudentInterventionS5.status.in_(["recommended", "scheduled", "in_progress"])
    ).all()

    active_count = len(my_interventions)
    student_ids = list({iv.student_id for iv in my_interventions})

    # Count at-risk among my students (CGPA in monitoring range)
    from app.models.academic_models import StudentTermGPA
    from sqlalchemy import desc
    monitor_lo = ConfigCenterService.get_float(db, "risk_monitor_cgpa_low", 2.00)
    monitor_hi = ConfigCenterService.get_float(db, "risk_monitor_cgpa_high", 2.50)

    at_risk = 0
    critical = 0
    for sid in student_ids:
        lg = db.query(StudentTermGPA).filter(
            StudentTermGPA.student_id == sid,
            StudentTermGPA.finalized == True
        ).order_by(desc(StudentTermGPA.created_at)).first()
        if lg:
            c = float(lg.cgpa)
            if c < monitor_lo:
                critical += 1
            elif c <= monitor_hi:
                at_risk += 1

    pending_esc = db.query(func.count(StudentEscalation.id)).filter(
        StudentEscalation.assigned_to == current_user.id,
        StudentEscalation.status == "pending",
    ).scalar() or 0

    recent_warnings = db.query(StudentEarlyWarning).filter(
        StudentEarlyWarning.student_id.in_(student_ids),
        StudentEarlyWarning.status == "active",
    ).order_by(desc(StudentEarlyWarning.created_at)).limit(10).all()

    from app.models.sprint5_models import AdvisorMeeting
    meetings_this_week = db.query(func.count(AdvisorMeeting.id)).filter(
        AdvisorMeeting.advisor_id == current_user.id,
        AdvisorMeeting.scheduled_at >= week_start,
    ).scalar() or 0

    return {
        "advisor_id":          current_user.id,
        "total_assigned":      len(student_ids),
        "at_risk_count":       at_risk,
        "critical_count":      critical,
        "active_interventions": active_count,
        "meetings_this_week":  meetings_this_week,
        "pending_escalations": pending_esc,
        "recent_warnings":     recent_warnings,
        "my_interventions":    my_interventions,
    }


@success_router.post("/advisor/notes", response_model=AdvisorNoteOut)
def add_advisor_note(
    payload: AdvisorNoteCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    from app.models.sprint5_models import AdvisorInterventionNote
    note = AdvisorInterventionNote(**payload.model_dump(), author_id=current_user.id)
    db.add(note)
    db.commit()
    db.refresh(note)
    return note


@success_router.get("/advisor/notes/{student_id}", response_model=List[AdvisorNoteOut])
def get_advisor_notes(
    student_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    from app.models.sprint5_models import AdvisorInterventionNote
    q = db.query(AdvisorInterventionNote).filter(
        AdvisorInterventionNote.student_id == student_id,
        # Return own notes + public notes
        (AdvisorInterventionNote.is_private == False) |
        (AdvisorInterventionNote.author_id == current_user.id)
    )
    return q.order_by(desc(AdvisorInterventionNote.created_at)).all()


@success_router.post("/advisor/meetings", response_model=AdvisorMeetingOut)
def schedule_meeting(
    payload: AdvisorMeetingCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    from app.models.sprint5_models import AdvisorMeeting
    meeting = AdvisorMeeting(**payload.model_dump(), advisor_id=current_user.id)
    db.add(meeting)
    db.commit()
    db.refresh(meeting)
    return meeting


@success_router.get("/advisor/meetings")
def list_advisor_meetings(
    status: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    from app.models.sprint5_models import AdvisorMeeting
    q = db.query(AdvisorMeeting).filter(AdvisorMeeting.advisor_id == current_user.id)
    if status:
        q = q.filter(AdvisorMeeting.status == status)
    return q.order_by(AdvisorMeeting.scheduled_at).all()


# ═════════════════════════════════════════════════════════════════════════════
# MODULE E: NOTIFICATIONS
# ═════════════════════════════════════════════════════════════════════════════

notif_router = APIRouter(prefix="/notifications", tags=["E — Notification Infrastructure"])


@notif_router.get("/inbox", response_model=List[NotificationOut])
def get_inbox(
    limit: int = 20,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    """Get unread in-app notifications for current user."""
    return NotificationService.get_unread(db, current_user.id, limit)


@notif_router.post("/send")
def send_notification(
    payload: NotificationQueueCreate,
    db: Session = Depends(get_db),
    _=Depends(get_current_user)
):
    notif = NotificationService.send(
        db, payload.recipient_id, payload.body,
        template_key=payload.template_key,
        channel=payload.channel,
        subject=payload.subject,
        variables=payload.variables,
        related_entity=payload.related_entity,
        related_id=payload.related_id,
        priority=payload.priority,
    )
    return {"id": notif.id, "status": notif.status}


@notif_router.put("/mark-sent/{notif_id}")
def mark_notification_sent(
    notif_id: int,
    db: Session = Depends(get_db),
    _=Depends(get_current_user)
):
    NotificationService.mark_sent(db, notif_id)
    return {"message": "Marked as sent"}


@notif_router.get("/templates", response_model=List[NotificationTemplateOut])
def list_templates(db: Session = Depends(get_db), _=Depends(get_current_user)):
    from app.models.sprint5_models import NotificationTemplate
    return db.query(NotificationTemplate).filter(NotificationTemplate.is_active == True).all()


@notif_router.get("/preferences", response_model=NotificationPreferenceOut)
def get_preferences(db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    return NotificationService.get_or_create_preferences(db, current_user.id)


@notif_router.put("/preferences", response_model=NotificationPreferenceOut)
def update_preferences(
    payload: NotificationPreferenceUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    pref = NotificationService.get_or_create_preferences(db, current_user.id)
    for k, v in payload.model_dump(exclude_none=True).items():
        setattr(pref, k, v)
    db.commit()
    db.refresh(pref)
    return pref


@notif_router.get("/queue")
def get_queue(
    status: Optional[str] = None,
    channel: Optional[str] = None,
    skip: int = 0, limit: int = 50,
    db: Session = Depends(get_db),
    _=Depends(get_current_user)
):
    from app.models.sprint5_models import NotificationQueue
    q = db.query(NotificationQueue)
    if status:
        q = q.filter(NotificationQueue.status == status)
    if channel:
        q = q.filter(NotificationQueue.channel == channel)
    total = q.count()
    items = q.order_by(desc(NotificationQueue.created_at)).offset(skip).limit(limit).all()
    return {"items": items, "total": total}


@notif_router.get("/stats")
def notification_stats(db: Session = Depends(get_db), _=Depends(get_current_user)):
    from app.models.sprint5_models import NotificationQueue
    by_status = db.query(
        NotificationQueue.status, func.count(NotificationQueue.id)
    ).group_by(NotificationQueue.status).all()
    by_channel = db.query(
        NotificationQueue.channel, func.count(NotificationQueue.id)
    ).group_by(NotificationQueue.channel).all()
    return {
        "by_status":  [{"status": s, "count": c} for s, c in by_status],
        "by_channel": [{"channel": ch, "count": c} for ch, c in by_channel],
    }


# ═════════════════════════════════════════════════════════════════════════════
# MODULE F: SEED DATA GENERATOR
# ═════════════════════════════════════════════════════════════════════════════

seed_router = APIRouter(prefix="/seed-data", tags=["F — Seed Data Generator"])


@seed_router.get("/batches", response_model=List[SeedBatchOut])
def list_batches(db: Session = Depends(get_db), _=Depends(get_current_user)):
    return SeedDataGenerator.list_batches(db)


@seed_router.post("/batches", response_model=SeedBatchOut)
def create_batch(
    payload: SeedBatchCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    """
    Generate a batch of realistic students.
    ⚠️ This may take 1-2 minutes for 500 students.
    """
    batch = SeedDataGenerator.generate_batch(
        db,
        count=payload.student_count,
        label=payload.label,
        created_by=current_user.id,
    )
    return batch


@seed_router.get("/batches/{batch_id}", response_model=SeedBatchOut)
def get_batch(batch_id: int, db: Session = Depends(get_db), _=Depends(get_current_user)):
    batch = SeedDataGenerator.get_batch(db, batch_id)
    if not batch:
        raise HTTPException(404, "Batch not found")
    return batch


@seed_router.delete("/batches/{batch_id}")
def delete_batch(
    batch_id: int,
    db: Session = Depends(get_db),
    _=Depends(get_current_user)
):
    """
    Delete all data generated in a batch (students, users, attempts, term GPAs).
    Safe cleanup before importing real university data.
    """
    result = SeedDataGenerator.delete_batch(db, batch_id)
    if "error" in result:
        raise HTTPException(404, result["error"])
    return result


# ═════════════════════════════════════════════════════════════════════════════
# MODULE G: REPORTING FOUNDATION
# ═════════════════════════════════════════════════════════════════════════════

reports_router = APIRouter(prefix="/reports", tags=["G — Reporting Foundation"])


@reports_router.get("/definitions", response_model=List[ReportDefinitionOut])
def list_report_definitions(db: Session = Depends(get_db), _=Depends(get_current_user)):
    from app.models.sprint5_models import ReportDefinition
    return db.query(ReportDefinition).filter(ReportDefinition.is_active == True).all()


@reports_router.post("/run", response_model=ReportRunOut)
def run_report(
    payload: ReportRunCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    """Run a report and return the result."""
    from app.models.sprint5_models import ReportDefinition, ReportRun
    from datetime import datetime, timezone

    defn = db.query(ReportDefinition).filter(ReportDefinition.key == payload.report_key).first()
    run = ReportRun(
        definition_id=defn.id if defn else None,
        report_key=payload.report_key,
        parameters=payload.parameters,
        format=payload.format,
        status="running",
        requested_by=current_user.id,
    )
    db.add(run)
    db.commit()
    db.refresh(run)

    try:
        data, row_count = _execute_report(db, payload.report_key, payload.parameters or {})
        run.result_data = data
        run.row_count = row_count
        run.status = "completed"
        run.completed_at = datetime.now(timezone.utc)
    except Exception as e:
        run.status = "failed"
        run.error_message = str(e)
        run.completed_at = datetime.now(timezone.utc)

    db.commit()
    db.refresh(run)
    return run


@reports_router.get("/runs", response_model=List[ReportRunOut])
def list_report_runs(
    skip: int = 0, limit: int = 20,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    from app.models.sprint5_models import ReportRun
    return db.query(ReportRun).filter(
        ReportRun.requested_by == current_user.id
    ).order_by(desc(ReportRun.created_at)).offset(skip).limit(limit).all()


@reports_router.get("/runs/{run_id}")
def get_report_run(run_id: int, db: Session = Depends(get_db), _=Depends(get_current_user)):
    from app.models.sprint5_models import ReportRun
    run = db.query(ReportRun).filter(ReportRun.id == run_id).first()
    if not run:
        raise HTTPException(404, "Report run not found")
    return run


def _execute_report(db: Session, report_key: str, params: dict) -> tuple:
    """Execute a named report and return (data_dict, row_count)."""
    from app.models.models import Student
    from app.models.academic_models import StudentTermGPA
    from app.models.sprint5_models import (
        StudentEarlyWarning, StudentInterventionS5, StudentSuccessScore,
        GraduationReadinessCache, RetentionSnapshot
    )

    if report_key == "student_progress_report":
        rows = db.query(Student, StudentTermGPA).join(
            StudentTermGPA, StudentTermGPA.student_id == Student.id, isouter=True
        ).filter(StudentTermGPA.finalized == True).order_by(
            Student.id, desc(StudentTermGPA.created_at)
        ).limit(params.get("limit", 500)).all()
        data = [{"student": s.name, "code": getattr(s, "student_id", ""),
                 "cgpa": float(t.cgpa), "standing": t.academic_standing,
                 "credits": int(t.cumulative_hours_earned)} for s, t in rows]
        return {"rows": data}, len(data)

    elif report_key == "academic_risk_report":
        thresh = ConfigCenterService.get_float(db, "dismissal_cgpa_threshold", 2.00)
        rows = db.query(Student, StudentTermGPA).join(
            StudentTermGPA, StudentTermGPA.student_id == Student.id
        ).filter(
            StudentTermGPA.finalized == True,
            StudentTermGPA.cgpa < thresh,
        ).all()
        data = [{"student": s.name, "cgpa": float(t.cgpa),
                 "standing": t.academic_standing} for s, t in rows]
        return {"rows": data, "threshold": thresh}, len(data)

    elif report_key == "graduation_readiness_report":
        rows = db.query(GraduationReadinessCache).all()
        data = [{"student_id": r.student_id, "readiness_pct": float(r.readiness_pct),
                 "status": r.status, "remaining_credits": r.remaining_credits,
                 "cgpa_eligible": r.cgpa_eligible} for r in rows]
        return {"rows": data}, len(data)

    elif report_key == "retention_report":
        snap = db.query(RetentionSnapshot).order_by(desc(RetentionSnapshot.created_at)).first()
        return {"snapshot": snap.__dict__ if snap else {}}, 1

    elif report_key == "success_score_report":
        dist = db.query(
            StudentSuccessScore.band, func.count(StudentSuccessScore.id),
            func.avg(StudentSuccessScore.score)
        ).group_by(StudentSuccessScore.band).all()
        data = [{"band": b, "count": c, "avg": round(float(a), 2)} for b, c, a in dist]
        return {"distribution": data}, len(data)

    elif report_key == "advisor_workload_report":
        from sqlalchemy import func
        data = db.query(
            StudentInterventionS5.assigned_to,
            func.count(StudentInterventionS5.id).label("intervention_count"),
        ).filter(
            StudentInterventionS5.status.in_(["recommended", "in_progress"])
        ).group_by(StudentInterventionS5.assigned_to).all()
        rows = [{"advisor_id": r[0], "active_interventions": r[1]} for r in data]
        return {"rows": rows}, len(rows)

    elif report_key == "intervention_report":
        rows = db.query(StudentInterventionS5).order_by(
            desc(StudentInterventionS5.created_at)
        ).limit(params.get("limit", 200)).all()
        data = [{"id": r.id, "student_id": r.student_id, "type": r.intervention_type,
                 "status": r.status, "priority": r.priority} for r in rows]
        return {"rows": data}, len(data)

    elif report_key == "dismissal_risk_report":
        thresh = ConfigCenterService.get_float(db, "dismissal_cgpa_threshold", 2.00)
        min_s  = ConfigCenterService.get_int(db, "dismissal_min_regular_semesters", 6)
        # Use sub-query to get latest CGPA
        rows = db.query(Student).join(
            StudentTermGPA, StudentTermGPA.student_id == Student.id
        ).filter(
            StudentTermGPA.cgpa < thresh,
            StudentTermGPA.finalized == True,
        ).all()
        data = [{"student_id": s.id, "name": s.name, "code": getattr(s, "student_id", "")} for s in rows]
        return {"rows": data, "threshold": thresh}, len(data)

    else:
        return {"message": f"Unknown report '{report_key}'"}, 0


# ═════════════════════════════════════════════════════════════════════════════
# MODULE H: RETENTION ANALYTICS
# ═════════════════════════════════════════════════════════════════════════════

retention_router = APIRouter(prefix="/retention", tags=["H — Retention Analytics"])


@retention_router.post("/snapshot")
def compute_retention_snapshot(
    term_id: Optional[int] = None,
    program_id: Optional[int] = None,
    db: Session = Depends(get_db),
    _=Depends(get_current_user)
):
    """Compute and store a retention analytics snapshot."""
    snap = RetentionAnalyticsService.compute_snapshot(db, term_id, program_id)
    return snap


@retention_router.get("/dashboard")
def retention_dashboard(
    program_id: Optional[int] = None,
    db: Session = Depends(get_db),
    _=Depends(get_current_user)
):
    """Dean/Registrar/Academic Affairs retention dashboard."""
    snap = RetentionAnalyticsService.get_latest_snapshot(db, program_id)
    if not snap:
        # Compute on demand
        snap = RetentionAnalyticsService.compute_snapshot(db, program_id=program_id)

    history = RetentionAnalyticsService.get_snapshot_history(db, 12, program_id)

    cgpa_dist = [
        {"label": "Below 2.0", "count": snap.below_2_cgpa,
         "pct": round(snap.below_2_cgpa / max(1, snap.total_students) * 100, 1)},
        {"label": "2.0 – 2.5", "count": snap.between_2_and_2_5_cgpa,
         "pct": round(snap.between_2_and_2_5_cgpa / max(1, snap.total_students) * 100, 1)},
        {"label": "Above 2.5", "count": snap.above_2_5_cgpa,
         "pct": round(snap.above_2_5_cgpa / max(1, snap.total_students) * 100, 1)},
    ]

    risk_trend = [
        {"date": str(s.snapshot_date), "dismissal_risk": s.dismissal_risk_count,
         "probation": s.probation_count, "critical_warnings": s.critical_warnings_count}
        for s in history
    ]

    success_trend = [
        {"date": str(s.snapshot_date), "avg_score": float(s.avg_success_score or 0),
         "avg_cgpa": float(s.avg_cgpa or 0), "retention_rate": float(s.retention_rate or 0)}
        for s in history
    ]

    return {
        "total_students":          snap.total_students,
        "active_students":         snap.active_students,
        "below_2_cgpa":            snap.below_2_cgpa,
        "between_2_and_2_5_cgpa":  snap.between_2_and_2_5_cgpa,
        "above_2_5_cgpa":          snap.above_2_5_cgpa,
        "dismissal_risk_count":    snap.dismissal_risk_count,
        "probation_count":         snap.probation_count,
        "expected_graduates":      snap.expected_graduates,
        "graduation_delay_count":  snap.graduation_delay_count,
        "critical_warnings_count": snap.critical_warnings_count,
        "avg_success_score":       float(snap.avg_success_score or 0),
        "avg_cgpa":                float(snap.avg_cgpa or 0),
        "retention_rate":          float(snap.retention_rate or 0),
        "cgpa_distribution":       cgpa_dist,
        "risk_trend":              risk_trend,
        "success_trend":           success_trend,
    }


@retention_router.get("/snapshots", response_model=List[RetentionSnapshotOut])
def list_snapshots(
    program_id: Optional[int] = None,
    limit: int = 24,
    db: Session = Depends(get_db),
    _=Depends(get_current_user)
):
    return RetentionAnalyticsService.get_snapshot_history(db, limit, program_id)


@retention_router.get("/at-risk")
def at_risk_students(
    risk_type: str = "below_2",
    skip: int = 0, limit: int = 50,
    db: Session = Depends(get_db),
    _=Depends(get_current_user)
):
    """List students by risk category."""
    from app.models.models import Student
    from app.models.academic_models import StudentTermGPA

    thresh_lo = ConfigCenterService.get_float(db, "dismissal_cgpa_threshold", 2.00)
    thresh_hi = ConfigCenterService.get_float(db, "risk_monitor_cgpa_high", 2.50)

    # Sub-query: latest finalized term GPA per student
    subq = db.query(
        StudentTermGPA.student_id,
        func.max(StudentTermGPA.id).label("max_id")
    ).filter(StudentTermGPA.finalized == True).group_by(StudentTermGPA.student_id).subquery()

    q = db.query(Student, StudentTermGPA).join(
        subq, Student.id == subq.c.student_id
    ).join(StudentTermGPA, StudentTermGPA.id == subq.c.max_id)

    if risk_type == "below_2":
        q = q.filter(StudentTermGPA.cgpa < thresh_lo)
    elif risk_type == "monitoring":
        q = q.filter(StudentTermGPA.cgpa >= thresh_lo, StudentTermGPA.cgpa <= thresh_hi)
    elif risk_type == "dismissal_risk":
        min_s = ConfigCenterService.get_int(db, "dismissal_min_regular_semesters", 6)
        # Simplified: filter by CGPA only
        q = q.filter(StudentTermGPA.cgpa < thresh_lo)
    elif risk_type == "probation":
        q = q.filter(StudentTermGPA.academic_standing.in_(["probation", "warning"]))

    total = q.count()
    rows = q.order_by(StudentTermGPA.cgpa).offset(skip).limit(limit).all()
    data = [{"student_id": s.id, "name": s.name, "cgpa": float(t.cgpa),
             "standing": t.academic_standing, "credits": int(t.cumulative_hours_earned)}
            for s, t in rows]

    return {"items": data, "total": total, "risk_type": risk_type}


# ═════════════════════════════════════════════════════════════════════════════
# REGISTER ALL SUB-ROUTERS
# ═════════════════════════════════════════════════════════════════════════════

router.include_router(config_router)
router.include_router(workflow_router)
router.include_router(calendar_router)
router.include_router(success_router)
router.include_router(notif_router)
router.include_router(seed_router)
router.include_router(reports_router)
router.include_router(retention_router)
