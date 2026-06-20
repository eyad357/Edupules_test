"""
EduGuard AI — Sprint 4 Extended Router
=======================================
New endpoints:
  GET  /students/{id}/gpa-explanation
  GET  /students/{id}/gpa-versions
  GET  /students/{id}/achievements
  GET  /students/{id}/scholarship-status
  POST /students/{id}/scholarship-status/evaluate
  POST /students/{id}/gpa-explanation/generate
  GET  /academic/rules (with PENDING flags)
  GET  /academic/policy-gaps (shows all unconfigured rules)
"""

from __future__ import annotations

import logging
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.models.models import Student
from app.repositories.sprint4_repositories import (
    RulesConfigRepository,
    GPAVersionRepository,
    GPAExplanationRepository,
    ScholarshipRepository,
    AchievementRepository,
    StudentRepository,
)
from app.services.sprint4_services_v2 import (
    GPAVersioningService,
    GPAExplainabilityService,
    ScholarshipService,
    AcademicAchievementService,
    DashboardService,
    DegreeProgressService,
    GraduationEligibilityService,
    AcademicRiskService,
    GPAProjectionService,
    HonorsService,
    TranscriptService,
    VerificationService,
    GradeProcessingService,
    GPAEngine,
    AcademicStandingService,
    RegistrarNoteService,
    TimelineService,
    SnapshotService,
)
from app.models.sprint4_models import (
    SemesterSnapshot, TranscriptVersion, TranscriptVerification,
    AcademicTimelineEvent, AcademicStatusHistory, DegreeProgressSnapshot,
    GraduationEligibilityRecord, HonorsRecord, GPAProjection,
    AcademicRiskRecord, RegistrarNote, AcademicAuditEntry,
    AcademicRulesConfig,
)
from app.models.sprint4_extended_models import (
    ScholarshipEvaluation, GPAVersion, AcademicAchievement, GPAExplanation,
)
from app.schemas.sprint4_schemas import (
    RegistrarNoteCreate, RegistrarNoteUpdate, ProjectionRequest,
    TranscriptGenerateRequest,
)

logger = logging.getLogger(__name__)

sprint4_ext_router = APIRouter(tags=["Sprint 4 — Extended Academic Intelligence"])

PENDING = RulesConfigRepository.PENDING


# ─────────────────────────────────────────────────────────────────────────────
# HELPER
# ─────────────────────────────────────────────────────────────────────────────

def _student_or_404(db: Session, student_id: int) -> Student:
    s = db.query(Student).filter(Student.id == student_id).first()
    if not s:
        raise HTTPException(status_code=404, detail=f"Student {student_id} not found")
    return s


# ═════════════════════════════════════════════════════════════════════════════
# POLICY GAPS — show all PENDING rules
# ═════════════════════════════════════════════════════════════════════════════

@sprint4_ext_router.get(
    "/academic/policy-gaps",
    summary="List all rules with PENDING_POLICY_CONFIGURATION status",
)
def get_policy_gaps(
    program_id: Optional[int] = Query(None),
    db: Session = Depends(get_db),
):
    """
    Returns every AcademicRulesConfig entry whose value is
    PENDING_POLICY_CONFIGURATION. Used to drive the admin configuration
    workflow — shows exactly which university regulations are still needed.
    """
    rules_repo = RulesConfigRepository(db)
    all_rules  = rules_repo.get_all_with_status(program_id)
    pending    = [r for r in all_rules if r["is_pending"]]
    configured = [r for r in all_rules if not r["is_pending"]]

    return {
        "total_rules":      len(all_rules),
        "configured_count": len(configured),
        "pending_count":    len(pending),
        "pending_rules":    pending,
        "configured_rules": configured,
        "message": (
            "All rules configured. System is fully operational."
            if not pending else
            f"{len(pending)} rule(s) require university regulation documents to be uploaded "
            f"and configured before dependent features become active."
        ),
    }


@sprint4_ext_router.get(
    "/academic/rules/full",
    summary="List all rules with PENDING status clearly flagged",
)
def list_rules_full(
    program_id: Optional[int] = Query(None),
    db: Session = Depends(get_db),
):
    return RulesConfigRepository(db).get_all_with_status(program_id)


# ═════════════════════════════════════════════════════════════════════════════
# GPA VERSIONING ENGINE
# GET /students/{id}/gpa-versions
# ═════════════════════════════════════════════════════════════════════════════

@sprint4_ext_router.get(
    "/students/{student_id}/gpa-versions",
    summary="GPA version history — every GPA change recorded immutably",
)
def get_gpa_versions(
    student_id: int,
    limit: int = Query(50, ge=1, le=200),
    db: Session = Depends(get_db),
):
    _student_or_404(db, student_id)
    versions = GPAVersionRepository(db).get_for_student(student_id, limit=limit)
    return {
        "student_id": student_id,
        "total":      len(versions),
        "versions": [
            {
                "id":             v.id,
                "version_number": v.version_number,
                "term_id":        v.term_id,
                "semester_gpa":   float(v.semester_gpa or 0),
                "cgpa":           float(v.cgpa or 0),
                "cgpa_delta":     float(v.cgpa_delta) if v.cgpa_delta else None,
                "gpa_delta":      float(v.gpa_delta)  if v.gpa_delta  else None,
                "hours_attempted": v.total_hours_attempted,
                "quality_points": float(v.total_quality_points or 0),
                "trigger_event":  v.trigger_event,
                "repeat_policy":  v.repeat_policy_used,
                "recorded_at":    v.recorded_at,
            }
            for v in versions
        ],
    }


# ═════════════════════════════════════════════════════════════════════════════
# GPA AUDIT EXPLAINABILITY ENGINE
# GET  /students/{id}/gpa-explanation
# POST /students/{id}/gpa-explanation/generate
# ═════════════════════════════════════════════════════════════════════════════

@sprint4_ext_router.get(
    "/students/{student_id}/gpa-explanation",
    summary="GPA audit explainability — full line-item breakdown of CGPA calculation",
)
def get_gpa_explanation(
    student_id: int,
    term_id: Optional[int] = Query(None, description="Filter explanation to a specific term"),
    db: Session = Depends(get_db),
):
    """
    Returns the most recent GPA explanation for the student.
    If none exists, generates one on demand.
    Includes:
      - Formula used (document-sourced from CGPA_Calculator.xlsx)
      - Repeat policy applied
      - Every included course attempt with its exact grade-point contribution
      - Every excluded attempt with the documented reason for exclusion
      - Policy gaps (PENDING rules that affect the calculation)
    """
    _student_or_404(db, student_id)
    expl_repo = GPAExplanationRepository(db)

    if term_id:
        expl = expl_repo.get_for_term(student_id, term_id)
    else:
        expl = expl_repo.get_latest(student_id)

    if not expl:
        expl = GPAExplainabilityService.generate_explanation(db, student_id, term_id)

    return _format_explanation(expl)


@sprint4_ext_router.post(
    "/students/{student_id}/gpa-explanation/generate",
    status_code=201,
    summary="Regenerate GPA explanation (creates new current version)",
)
def generate_gpa_explanation(
    student_id: int,
    term_id: Optional[int] = Query(None),
    db: Session = Depends(get_db),
):
    _student_or_404(db, student_id)
    try:
        expl = GPAExplainabilityService.generate_explanation(db, student_id, term_id)
        return _format_explanation(expl)
    except Exception as e:
        logger.exception("GPA explanation generation failed")
        raise HTTPException(500, f"GPA explanation failed: {e}")


def _format_explanation(expl) -> Dict:
    return {
        "id":                    expl.id,
        "student_id":            expl.student_id,
        "term_id":               expl.term_id,
        "formula":               expl.formula_description,
        "repeat_policy":         expl.repeat_policy,
        "computed_cgpa":         float(expl.computed_cgpa or 0),
        "total_quality_points":  float(expl.total_quality_points or 0),
        "total_hours_attempted": expl.total_hours_attempted,
        "computed_semester_gpa": float(expl.computed_semester_gpa) if expl.computed_semester_gpa else None,
        "included_count":        len(expl.included_attempts or []),
        "excluded_count":        len(expl.excluded_attempts or []),
        "included_attempts":     expl.included_attempts,
        "excluded_attempts":     expl.excluded_attempts,
        "all_rules_sourced":     expl.all_rules_sourced,
        "policy_notes":          expl.policy_notes,
        "generated_at":          expl.generated_at,
        "policy_sourcing_notice": (
            "All rules sourced from uploaded university documents."
            if expl.all_rules_sourced else
            "⚠ Some rules are PENDING_POLICY_CONFIGURATION. "
            "Upload university regulations to enable full calculation validation."
        ),
    }


# ═════════════════════════════════════════════════════════════════════════════
# SCHOLARSHIP ELIGIBILITY ENGINE
# GET  /students/{id}/scholarship-status
# POST /students/{id}/scholarship-status/evaluate
# ═════════════════════════════════════════════════════════════════════════════

@sprint4_ext_router.get(
    "/students/{student_id}/scholarship-status",
    summary="Current scholarship eligibility status",
)
def get_scholarship_status(
    student_id: int,
    db: Session = Depends(get_db),
):
    """
    Returns the current scholarship evaluation.

    NOTE: If scholarship policy rules have not been configured
    (status = PENDING_POLICY_CONFIGURATION), the response will include
    a policy_gaps list identifying which regulation documents need to
    be uploaded and which rule keys need to be configured.
    """
    _student_or_404(db, student_id)
    rec = ScholarshipRepository(db).get_current(student_id)
    if not rec:
        rec = ScholarshipService.evaluate(db, student_id)
    return _format_scholarship(rec)


@sprint4_ext_router.post(
    "/students/{student_id}/scholarship-status/evaluate",
    status_code=201,
    summary="Run scholarship eligibility evaluation",
)
def evaluate_scholarship(
    student_id: int,
    term_id: Optional[int] = Query(None),
    db: Session = Depends(get_db),
):
    _student_or_404(db, student_id)
    try:
        rec = ScholarshipService.evaluate(db, student_id, term_id=term_id)
        return _format_scholarship(rec)
    except Exception as e:
        logger.exception("Scholarship evaluation failed")
        raise HTTPException(500, f"Scholarship evaluation failed: {e}")


@sprint4_ext_router.get(
    "/students/{student_id}/scholarship-status/history",
    summary="Historical scholarship evaluations",
)
def get_scholarship_history(student_id: int, db: Session = Depends(get_db)):
    _student_or_404(db, student_id)
    records = ScholarshipRepository(db).get_all_for_student(student_id)
    return {"student_id": student_id, "total": len(records),
            "evaluations": [_format_scholarship(r) for r in records]}


def _format_scholarship(rec) -> Dict:
    is_pending = (rec.status == "pending_policy_configuration"
                  or str(rec.status) == "pending_policy_configuration")
    return {
        "id":                    rec.id,
        "student_id":            rec.student_id,
        "term_id":               rec.term_id,
        "status":                rec.status if isinstance(rec.status, str) else rec.status.value,
        "is_pending":            is_pending,
        "cgpa_at_evaluation":    float(rec.cgpa_at_evaluation or 0),
        "credits_at_evaluation": rec.credits_at_evaluation,
        "term_gpa_at_evaluation": float(rec.term_gpa_at_evaluation or 0),
        "rules_applied":         rec.rules_applied,
        "criteria_met":          rec.criteria_met,
        "unmet_criteria":        rec.unmet_criteria,
        "policy_gaps":           rec.policy_gaps,
        "notes":                 rec.notes,
        "evaluated_at":          rec.evaluated_at,
        "is_current":            rec.is_current,
        "action_required": (
            None if not is_pending else
            f"Configure {len(rec.policy_gaps or [])} missing rule(s) in /api/v1/academic/rules "
            "after uploading university scholarship regulations."
        ),
    }


# ═════════════════════════════════════════════════════════════════════════════
# ACADEMIC ACHIEVEMENT REGISTRY
# GET /students/{id}/achievements
# ═════════════════════════════════════════════════════════════════════════════

@sprint4_ext_router.get(
    "/students/{student_id}/achievements",
    summary="Academic Achievement Registry — all recorded milestones",
)
def get_achievements(
    student_id: int,
    category: Optional[str] = Query(None, description="Filter by category"),
    db: Session = Depends(get_db),
):
    """
    Returns all recorded academic achievements.

    POLICY NOTE: Achievements that depend on PENDING thresholds
    (e.g. Dean's List, Honors) will not appear here until the
    corresponding AcademicRulesConfig entries are configured.
    Only document-sourced achievements (degree progress milestones,
    field training completion, graduation project completion) are
    recorded unconditionally.
    """
    _student_or_404(db, student_id)
    achievements = AcademicAchievementService.get_for_student(db, student_id, category)
    pending_count = sum(1 for a in achievements if not a.policy_sourced)

    return {
        "student_id":    student_id,
        "total":         len(achievements),
        "pending_count": pending_count,
        "achievements": [
            {
                "id":             a.id,
                "category":       a.category if isinstance(a.category, str) else a.category.value,
                "title":          a.title,
                "description":    a.description,
                "metric_key":     a.metric_key,
                "metric_value":   a.metric_value,
                "threshold_used": a.threshold_used,
                "rule_key_used":  a.rule_key_used,
                "policy_sourced": a.policy_sourced,
                "term_id":        a.term_id,
                "achieved_at":    a.achieved_at,
            }
            for a in achievements
        ],
        "policy_note": (
            f"{pending_count} achievement(s) marked as policy_sourced=False "
            "were recorded before all thresholds were configured."
            if pending_count > 0 else
            "All achievements are backed by document-sourced policy rules."
        ),
    }


# ═════════════════════════════════════════════════════════════════════════════
# RE-EXPORT ALL ORIGINAL MODULE ENDPOINTS (Modules 1–17)
# These are unchanged from sprint4_router.py but now use services_v2
# ═════════════════════════════════════════════════════════════════════════════

@sprint4_ext_router.get("/students/{student_id}/dashboard")
def get_dashboard(student_id: int, db: Session = Depends(get_db)):
    _student_or_404(db, student_id)
    try:
        return DashboardService.get(db, student_id)
    except Exception as e:
        logger.exception("Dashboard failed")
        raise HTTPException(500, str(e))


@sprint4_ext_router.get("/students/{student_id}/academic-risk")
def get_risk(student_id: int, db: Session = Depends(get_db)):
    _student_or_404(db, student_id)
    from app.repositories.sprint4_repositories import RiskRepository
    rec = RiskRepository(db).get_current(student_id)
    if not rec:
        rec = AcademicRiskService.assess(db, student_id)
    return {
        "id": rec.id, "student_id": rec.student_id, "risk_level": rec.risk_level,
        "risk_score": float(rec.risk_score or 0),
        "risk_factors": rec.risk_factors, "recommendations": rec.recommendations,
        "failed_courses_count": rec.failed_courses_count,
        "withdrawal_count": rec.withdrawal_count,
        "degree_completion_pct": float(rec.degree_completion_pct or 0),
        "assessed_at": rec.assessed_at,
    }


@sprint4_ext_router.post("/students/{student_id}/academic-risk/assess")
def assess_risk(
    student_id: int,
    term_id: Optional[int] = Query(None),
    db: Session = Depends(get_db),
):
    _student_or_404(db, student_id)
    rec = AcademicRiskService.assess(db, student_id, term_id=term_id)
    return {"student_id": student_id, "risk_level": rec.risk_level,
            "risk_score": float(rec.risk_score or 0), "risk_factors": rec.risk_factors,
            "recommendations": rec.recommendations}


@sprint4_ext_router.post("/students/{student_id}/gpa-projection")
def project_gpa(
    student_id: int,
    request: ProjectionRequest,
    db: Session = Depends(get_db),
):
    student = _student_or_404(db, student_id)
    rec = GPAProjectionService.project(
        db=db, student_id=student_id,
        projection_type=request.projection_type,
        target_cgpa=request.target_cgpa,
        remaining_credits=request.remaining_credits,
        registered_courses=request.registered_courses,
        program_id=student.program_id,
    )
    return {
        "id": rec.id, "projection_type": rec.projection_type,
        "current_cgpa": float(rec.current_cgpa or 0),
        "target_cgpa": float(rec.target_cgpa) if rec.target_cgpa else None,
        "projection_result": rec.projection_result,
        "projected_cgpa": float(rec.projected_cgpa) if rec.projected_cgpa else None,
        "is_achievable": rec.is_achievable,
    }


@sprint4_ext_router.post("/students/{student_id}/grades/finalize-term")
def finalize_term(
    student_id: int,
    term_id: int = Query(...),
    db: Session = Depends(get_db),
):
    student = _student_or_404(db, student_id)
    record  = GPAEngine.finalize_term(db, student_id, term_id, program_id=student.program_id)
    return {
        "student_id": student_id, "term_id": term_id,
        "term_gpa": float(record.term_gpa or 0),
        "cgpa": float(record.cgpa or 0),
        "academic_standing": record.academic_standing,
    }


@sprint4_ext_router.get("/students/{student_id}/degree-progress")
def get_degree_progress(student_id: int, db: Session = Depends(get_db)):
    _student_or_404(db, student_id)
    from app.repositories.sprint4_repositories import DegreeProgressRepository
    snap = DegreeProgressRepository(db).get_latest(student_id)
    if not snap:
        snap = DegreeProgressService.compute(db, student_id)
    return {
        "id": snap.id, "version": snap.version,
        "required_credits": snap.required_credits,
        "earned_credits": snap.earned_credits,
        "remaining_credits": snap.remaining_credits,
        "completion_percentage": float(snap.completion_percentage or 0),
        "category_breakdown": snap.category_breakdown,
        "missing_core_courses": snap.missing_core_courses,
        "missing_categories": snap.missing_categories,
        "all_core_complete": snap.all_core_complete,
        "all_electives_complete": snap.all_electives_complete,
        "field_training_complete": snap.field_training_complete,
        "graduation_project_complete": snap.graduation_project_complete,
        "computed_at": snap.computed_at,
    }


@sprint4_ext_router.post("/students/{student_id}/degree-progress/recompute")
def recompute_progress(student_id: int, db: Session = Depends(get_db)):
    _student_or_404(db, student_id)
    snap = DegreeProgressService.compute(db, student_id)
    return {"version": snap.version, "earned_credits": snap.earned_credits,
            "completion_pct": float(snap.completion_percentage or 0)}


@sprint4_ext_router.get("/students/{student_id}/graduation-eligibility")
def get_grad_elig(student_id: int, db: Session = Depends(get_db)):
    _student_or_404(db, student_id)
    from app.repositories.sprint4_repositories import GraduationEligibilityRepository
    rec = GraduationEligibilityRepository(db).get_current(student_id)
    if not rec:
        rec = GraduationEligibilityService.evaluate(db, student_id)
    return {
        "id": rec.id, "eligibility_status": rec.eligibility_status,
        "requirements_met": rec.requirements_met,
        "missing_requirements": rec.missing_requirements,
        "cgpa_at_evaluation": float(rec.cgpa_at_evaluation or 0),
        "credits_at_evaluation": rec.credits_at_evaluation,
        "evaluated_at": rec.evaluated_at,
        "pending_policy_note": (
            "One or more graduation requirement thresholds are PENDING_POLICY_CONFIGURATION. "
            "Upload university graduation regulations to enable full eligibility determination."
            if "PENDING_POLICY_CONFIGURATION" in str(rec.requirements_met) else None
        ),
    }


@sprint4_ext_router.post("/students/{student_id}/graduation-eligibility/evaluate")
def evaluate_grad_elig(
    student_id: int,
    term_id: Optional[int] = Query(None),
    db: Session = Depends(get_db),
):
    _student_or_404(db, student_id)
    rec = GraduationEligibilityService.evaluate(db, student_id, term_id=term_id)
    return {"eligibility_status": rec.eligibility_status,
            "missing_requirements": rec.missing_requirements}


@sprint4_ext_router.post("/students/{student_id}/transcripts/generate")
def generate_transcript(
    student_id: int,
    request: TranscriptGenerateRequest,
    db: Session = Depends(get_db),
):
    _student_or_404(db, student_id)
    try:
        tv  = TranscriptService.generate(
            db=db, student_id=student_id,
            transcript_type=request.transcript_type,
            term_id=request.term_id, reason=request.reason,
        )
        from app.repositories.sprint4_repositories import TranscriptRepository
        ver = TranscriptRepository(db).get_verification(tv.id)
        return {
            "version_id": tv.id, "version_number": tv.version_number,
            "transcript_type": tv.transcript_type,
            "verification_code": ver.verification_code if ver else None,
            "generated_at": tv.generated_at,
            "data": tv.transcript_data,
        }
    except Exception as e:
        logger.exception("Transcript generation failed")
        raise HTTPException(500, str(e))


@sprint4_ext_router.get("/transcripts/verify/{code}")
def verify_transcript(code: str, db: Session = Depends(get_db)):
    return VerificationService.verify(db, code)


@sprint4_ext_router.get("/students/{student_id}/timeline")
def get_timeline(
    student_id: int,
    event_type: Optional[str] = Query(None),
    limit: int = Query(100, ge=1, le=500),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
):
    _student_or_404(db, student_id)
    from app.repositories.sprint4_repositories import TimelineRepository
    total, events = TimelineRepository(db).get_for_student(student_id, event_type, limit, offset)
    return {
        "student_id": student_id, "total_events": total,
        "events": [
            {"id": e.id, "event_type": e.event_type, "title": e.title,
             "payload": e.payload, "occurred_at": e.occurred_at}
            for e in events
        ],
    }


@sprint4_ext_router.get("/students/{student_id}/audit-trail")
def get_audit(
    student_id: int,
    action: Optional[str] = Query(None),
    limit: int = Query(50, ge=1, le=500),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
):
    _student_or_404(db, student_id)
    from app.repositories.sprint4_repositories import AuditRepository
    entries = AuditRepository(db).get_for_student(student_id, action, limit, offset)
    return {
        "student_id": student_id, "entries": [
            {"id": e.id, "action": e.action, "entity_type": e.entity_type,
             "old_value": e.old_value, "new_value": e.new_value,
             "occurred_at": e.occurred_at}
            for e in entries
        ],
    }


@sprint4_ext_router.get("/students/{student_id}/honors")
def get_honors(student_id: int, db: Session = Depends(get_db)):
    _student_or_404(db, student_id)
    from app.repositories.sprint4_repositories import HonorsRepository
    records = HonorsRepository(db).get_all_for_student(student_id)
    has_pending = any(
        r.qualification_data.get("thresholds_pending", False) for r in records
    )
    return {
        "student_id": student_id, "total": len(records),
        "thresholds_pending": has_pending,
        "pending_note": (
            "Dean's List and Honors thresholds are PENDING_POLICY_CONFIGURATION. "
            "Configure deans_list_term_gpa and related rules to enable honors determination."
            if has_pending else None
        ),
        "records": [
            {"id": r.id, "honors_level": r.honors_level, "is_deans_list": r.is_deans_list,
             "term_gpa_used": float(r.term_gpa_used or 0), "cgpa_used": float(r.cgpa_used or 0),
             "qualification_data": r.qualification_data, "awarded_at": r.awarded_at}
            for r in records
        ],
    }


@sprint4_ext_router.post("/students/{student_id}/registrar/notes")
def create_note(
    data: RegistrarNoteCreate,
    db: Session = Depends(get_db),
):
    note = RegistrarNoteService.create(db, data.model_dump())
    return {"id": note.id, "title": note.title, "note_type": note.note_type,
            "created_at": note.created_at}


@sprint4_ext_router.get("/students/{student_id}/registrar/notes")
def get_notes(
    student_id: int,
    note_type: Optional[str] = Query(None),
    tag: Optional[str] = Query(None),
    include_private: bool = Query(False),
    db: Session = Depends(get_db),
):
    _student_or_404(db, student_id)
    notes = RegistrarNoteService.search(db, student_id, note_type, tag, include_private)
    return {"student_id": student_id, "total": len(notes),
            "notes": [{"id": n.id, "note_type": n.note_type, "title": n.title,
                        "content": n.content, "tags": n.tags, "version": n.version,
                        "created_at": n.created_at} for n in notes]}


@sprint4_ext_router.get("/students/{student_id}/snapshots")
def get_snapshots(
    student_id: int,
    term_id: Optional[int] = Query(None),
    db: Session = Depends(get_db),
):
    _student_or_404(db, student_id)
    from app.repositories.sprint4_repositories import SnapshotRepository
    snaps = SnapshotRepository(db).get_for_student(student_id, term_id)
    return {
        "student_id": student_id, "total": len(snaps),
        "snapshots": [
            {"id": s.id, "term_id": s.term_id, "version": s.version,
             "term_gpa": float(s.term_gpa or 0), "cgpa_after_term": float(s.cgpa_after_term or 0),
             "credits_attempted": s.credits_attempted, "credits_earned": s.credits_earned,
             "academic_standing": s.academic_standing, "snapshot_hash": s.snapshot_hash,
             "generated_at": s.generated_at}
            for s in snaps
        ],
    }
