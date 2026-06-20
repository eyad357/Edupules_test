"""
EduGuard AI — Sprint 4: Academic Intelligence Router
=====================================================
All 17 Sprint 4 module endpoints in a single production-grade router.
Mount in main.py: app.include_router(sprint4_router, prefix="/api/v1/academic")
"""

from __future__ import annotations

import logging
from typing import Any, Dict, List, Optional
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Query, status, Request
from sqlalchemy.orm import Session
from sqlalchemy import desc

from app.db.database import get_db
from app.models.models import Student, User
from app.models.academic_models import (
    AcademicTerm, StudentCourseAttempt, StudentTermGPA,
    GradeScale, GraduationRequirement,
)
from app.models.sprint4_models import (
    AcademicRulesConfig, SemesterSnapshot, TranscriptVersion,
    TranscriptVerification, AcademicTimelineEvent, AcademicStatusHistory,
    DegreeProgressSnapshot, GraduationEligibilityRecord, HonorsRecord,
    GPAProjection, AcademicRiskRecord, RegistrarNote, AcademicAuditEntry,
)
from app.schemas.sprint4_schemas import (
    AcademicRuleRead, AcademicRuleCreate, AcademicRuleUpdate,
    SemesterSnapshotRead, TranscriptVersionRead, TranscriptFullResponse,
    TranscriptGenerateRequest, TranscriptVerifyResponse,
    TimelineResponse, TimelineEventRead, StatusHistoryRead,
    DegreeProgressRead, DegreeProgressResponse, GraduationEligibilityRead,
    HonorsRecordRead, GPAProjectionRead, ProjectionRequest,
    AcademicRiskRead, RegistrarNoteCreate, RegistrarNoteUpdate, RegistrarNoteRead,
    AuditEntryRead, DashboardResponse, AcademicRecordResponse, AcademicHistoryResponse,
)
from app.services.sprint4_services import (
    RulesConfigService, GradeProcessingService, GPAEngine, SnapshotService,
    TranscriptService, VerificationService, AcademicStandingService,
    DegreeProgressService, GraduationEligibilityService, HonorsService,
    GPAProjectionService, AcademicRiskService, TimelineService, AuditService,
    RegistrarNoteService, DashboardService,
)

logger = logging.getLogger(__name__)

sprint4_router = APIRouter(tags=["Sprint 4 — Academic Intelligence"])


# ─────────────────────────────────────────────────────────────────────────────
# HELPER
# ─────────────────────────────────────────────────────────────────────────────

def _get_student_or_404(db: Session, student_id: int) -> Student:
    s = db.query(Student).filter(Student.id == student_id).first()
    if not s:
        raise HTTPException(status_code=404, detail=f"Student {student_id} not found")
    return s


# ═════════════════════════════════════════════════════════════════════════════
# ACADEMIC RULES CONFIG
# ═════════════════════════════════════════════════════════════════════════════

@sprint4_router.get("/rules", response_model=List[AcademicRuleRead], summary="List all academic rules")
def list_rules(
    program_id: Optional[int] = Query(None),
    db: Session = Depends(get_db),
):
    """Return all configurable academic rules, optionally filtered by program."""
    q = db.query(AcademicRulesConfig)
    if program_id:
        q = q.filter(AcademicRulesConfig.program_id == program_id)
    return q.order_by(AcademicRulesConfig.rule_key).all()


@sprint4_router.post("/rules", response_model=AcademicRuleRead, status_code=201, summary="Create academic rule")
def create_rule(data: AcademicRuleCreate, db: Session = Depends(get_db)):
    rule = AcademicRulesConfig(**data.model_dump())
    db.add(rule)
    db.commit()
    db.refresh(rule)
    return rule


@sprint4_router.put("/rules/{rule_id}", response_model=AcademicRuleRead, summary="Update academic rule")
def update_rule(rule_id: int, data: AcademicRuleUpdate, db: Session = Depends(get_db)):
    rule = db.query(AcademicRulesConfig).filter(AcademicRulesConfig.id == rule_id).first()
    if not rule:
        raise HTTPException(404, "Rule not found")
    rule.rule_value  = data.rule_value
    if data.description:
        rule.description = data.description
    db.commit()
    db.refresh(rule)
    return rule


@sprint4_router.post("/rules/seed", summary="Seed default academic rules")
def seed_rules(db: Session = Depends(get_db)):
    RulesConfigService.seed_defaults(db)
    return {"message": "Default rules seeded successfully"}


# ═════════════════════════════════════════════════════════════════════════════
# MODULE 1: ACADEMIC RECORD ENGINE
# ═════════════════════════════════════════════════════════════════════════════

@sprint4_router.get(
    "/students/{student_id}/academic-record",
    response_model=AcademicRecordResponse,
    summary="Get complete academic record",
)
def get_academic_record(student_id: int, db: Session = Depends(get_db)):
    """Complete academic history: all semesters, all courses, all grades."""
    student = _get_student_or_404(db, student_id)
    user    = db.query(User).filter(User.id == student.user_id).first()

    from app.models.academic_models import AcademicProgram, AcademicTrack
    from app.models.models import Course

    program_name = track_name = dept_name = None
    if student.program_id:
        prog = db.query(AcademicProgram).filter(AcademicProgram.id == student.program_id).first()
        if prog:
            program_name = prog.name
    if student.track_id:
        t = db.query(AcademicTrack).filter(AcademicTrack.id == student.track_id).first()
        if t:
            track_name = t.name

    # All terms with attempts
    term_ids = [r[0] for r in db.query(StudentCourseAttempt.term_id).filter(
        StudentCourseAttempt.student_id == student_id
    ).distinct().all()]

    terms = db.query(AcademicTerm).filter(
        AcademicTerm.id.in_(term_ids)
    ).order_by(AcademicTerm.academic_year, AcademicTerm.term_type).all()

    semesters = []
    for term in terms:
        term_rec = db.query(StudentTermGPA).filter(
            StudentTermGPA.student_id == student_id,
            StudentTermGPA.term_id == term.id,
        ).first()

        attempts = db.query(StudentCourseAttempt).filter(
            StudentCourseAttempt.student_id == student_id,
            StudentCourseAttempt.term_id == term.id,
        ).all()

        courses = []
        for a in attempts:
            c = db.query(Course).filter(Course.id == a.course_id).first()
            if c:
                courses.append({
                    "course_code": c.code,
                    "course_name": c.name,
                    "credit_hours": a.credit_hours,
                    "attempt_number": a.attempt_number,
                    "term_code": term.code,
                    "letter_grade": a.letter_grade or "",
                    "grade_points": float(a.grade_points or 0),
                    "result": a.result,
                    "counts_in_cgpa": a.counts_in_cgpa,
                })

        semesters.append({
            "term_id": term.id,
            "term_code": term.code,
            "term_name": term.name,
            "term_gpa": float(term_rec.term_gpa or 0) if term_rec else 0.0,
            "cgpa_after_term": float(term_rec.cgpa or 0) if term_rec else 0.0,
            "credits_attempted": int(term_rec.term_credit_hours_attempted or 0) if term_rec else 0,
            "credits_earned": int(term_rec.term_credit_hours_earned or 0) if term_rec else 0,
            "academic_standing": term_rec.academic_standing if term_rec else "active",
            "courses": courses,
        })

    return {
        "student_id": student_id,
        "student_number": student.student_number or "",
        "name": user.name if user else "",
        "program": program_name,
        "track": track_name,
        "department": dept_name,
        "current_cgpa": float(student.cgpa or 0),
        "total_credits_attempted": int(student.total_credit_hours_attempted or 0),
        "total_credits_earned": int(student.total_credit_hours_earned or 0),
        "academic_standing": student.academic_standing or "active",
        "semesters": semesters,
        "total_semesters": len(semesters),
    }


@sprint4_router.get("/students/{student_id}/academic-history", response_model=AcademicHistoryResponse)
def get_academic_history(student_id: int, db: Session = Depends(get_db)):
    """Status history, GPA trend, CGPA trend."""
    student = _get_student_or_404(db, student_id)

    status_history = db.query(AcademicStatusHistory).filter(
        AcademicStatusHistory.student_id == student_id,
    ).order_by(AcademicStatusHistory.occurred_at).all()

    term_gpas = db.query(StudentTermGPA).filter(
        StudentTermGPA.student_id == student_id,
        StudentTermGPA.finalized == True,
    ).order_by(StudentTermGPA.term_id).all()

    gpa_history  = [{"term_id": r.term_id, "gpa": float(r.term_gpa or 0)} for r in term_gpas]
    cgpa_history = [{"term_id": r.term_id, "cgpa": float(r.cgpa or 0)} for r in term_gpas]

    from app.models.academic_models import AcademicProgram, AcademicTrack
    program_name = track_name = None
    if student.program_id:
        p = db.query(AcademicProgram).filter(AcademicProgram.id == student.program_id).first()
        if p:
            program_name = p.name
    if student.track_id:
        t = db.query(AcademicTrack).filter(AcademicTrack.id == student.track_id).first()
        if t:
            track_name = t.name

    return {
        "student_id": student_id,
        "enrollment_date": student.enrollment_date,
        "program": program_name,
        "track": track_name,
        "status_history": status_history,
        "gpa_history": gpa_history,
        "cgpa_history": cgpa_history,
    }


@sprint4_router.get("/students/{student_id}/course-history")
def get_course_history(student_id: int, db: Session = Depends(get_db)):
    """All course attempts for a student."""
    _get_student_or_404(db, student_id)
    from app.models.models import Course
    attempts = db.query(StudentCourseAttempt).filter(
        StudentCourseAttempt.student_id == student_id,
    ).order_by(StudentCourseAttempt.term_id, StudentCourseAttempt.attempt_number).all()

    result = []
    for a in attempts:
        c = db.query(Course).filter(Course.id == a.course_id).first()
        result.append({
            "id": a.id,
            "course_code": c.code if c else None,
            "course_name": c.name if c else None,
            "term_id": a.term_id,
            "attempt_number": a.attempt_number,
            "letter_grade": a.letter_grade,
            "grade_points": float(a.grade_points or 0),
            "credit_hours": a.credit_hours,
            "result": a.result,
            "counts_in_cgpa": a.counts_in_cgpa,
            "is_improvement_attempt": a.is_improvement_attempt,
        })
    return {"student_id": student_id, "course_attempts": result, "total": len(result)}


@sprint4_router.get("/students/{student_id}/semester-history")
def get_semester_history(student_id: int, db: Session = Depends(get_db)):
    """All term GPA records."""
    _get_student_or_404(db, student_id)
    records = db.query(StudentTermGPA).filter(
        StudentTermGPA.student_id == student_id,
    ).order_by(StudentTermGPA.term_id).all()

    result = []
    for r in records:
        term = db.query(AcademicTerm).filter(AcademicTerm.id == r.term_id).first()
        result.append({
            "term_id": r.term_id,
            "term_code": term.code if term else None,
            "term_name": term.name if term else None,
            "term_gpa": float(r.term_gpa or 0),
            "cgpa": float(r.cgpa or 0),
            "credits_attempted": r.term_credit_hours_attempted,
            "credits_earned": r.term_credit_hours_earned,
            "academic_standing": r.academic_standing,
            "finalized": r.finalized,
        })
    return {"student_id": student_id, "semesters": result}


# ═════════════════════════════════════════════════════════════════════════════
# MODULE 2 & 3: GRADE PROCESSING + GPA ENGINE
# ═════════════════════════════════════════════════════════════════════════════

@sprint4_router.post("/students/{student_id}/grades/finalize-term")
def finalize_term(
    student_id: int,
    term_id: int = Query(..., description="Term ID to finalize"),
    db: Session = Depends(get_db),
):
    """Finalize a term: compute GPA, CGPA, snapshot, honors, status, audit."""
    _get_student_or_404(db, student_id)
    student = db.query(Student).filter(Student.id == student_id).first()
    record  = GPAEngine.finalize_term(
        db, student_id, term_id, program_id=student.program_id
    )
    return {
        "student_id": student_id,
        "term_id": term_id,
        "term_gpa": float(record.term_gpa or 0),
        "cgpa": float(record.cgpa or 0),
        "academic_standing": record.academic_standing,
        "message": "Term finalized successfully.",
    }


@sprint4_router.get("/grade-scale", summary="Get grade scale for a program")
def get_grade_scale(
    program_id: Optional[int] = Query(None),
    db: Session = Depends(get_db),
):
    q = db.query(GradeScale)
    if program_id:
        grades = q.filter(GradeScale.program_id == program_id).all()
        if not grades:
            grades = q.filter(GradeScale.program_id.is_(None)).all()
    else:
        grades = q.filter(GradeScale.program_id.is_(None)).all()
    return {"grades": [
        {
            "letter_grade": g.letter_grade,
            "grade_points": float(g.grade_points),
            "min_percentage": float(g.min_percentage) if g.min_percentage else None,
            "max_percentage": float(g.max_percentage) if g.max_percentage else None,
            "is_passing": g.is_passing,
            "counts_in_cgpa": g.counts_in_cgpa,
        }
        for g in grades
    ]}


@sprint4_router.post("/students/{student_id}/grades/recalculate-cgpa")
def recalculate_cgpa(student_id: int, db: Session = Depends(get_db)):
    """Force CGPA recalculation for a student."""
    student = _get_student_or_404(db, student_id)
    cgpa, hours, points = GPAEngine.calculate_cgpa(db, student_id, program_id=student.program_id)
    student.cgpa = float(cgpa)
    student.total_credit_hours_attempted = int(hours)
    student.total_quality_points = float(points)
    db.commit()
    return {"student_id": student_id, "cgpa": float(cgpa), "hours_attempted": int(hours)}


# ═════════════════════════════════════════════════════════════════════════════
# MODULE 4: SEMESTER SNAPSHOTS
# ═════════════════════════════════════════════════════════════════════════════

@sprint4_router.get("/students/{student_id}/snapshots", response_model=List[SemesterSnapshotRead])
def get_snapshots(
    student_id: int,
    term_id: Optional[int] = Query(None),
    db: Session = Depends(get_db),
):
    _get_student_or_404(db, student_id)
    q = db.query(SemesterSnapshot).filter(SemesterSnapshot.student_id == student_id)
    if term_id:
        q = q.filter(SemesterSnapshot.term_id == term_id)
    return q.order_by(SemesterSnapshot.term_id, SemesterSnapshot.version).all()


# ═════════════════════════════════════════════════════════════════════════════
# MODULES 5 & 6: TRANSCRIPT ENGINE + VERSIONING
# ═════════════════════════════════════════════════════════════════════════════

@sprint4_router.post(
    "/students/{student_id}/transcripts/generate",
    response_model=TranscriptFullResponse,
    status_code=201,
    summary="Generate a transcript",
)
def generate_transcript(
    student_id: int,
    request: TranscriptGenerateRequest,
    db: Session = Depends(get_db),
):
    _get_student_or_404(db, student_id)
    try:
        tv = TranscriptService.generate_transcript(
            db=db,
            student_id=student_id,
            transcript_type=request.transcript_type,
            term_id=request.term_id,
            reason=request.reason,
        )
    except Exception as e:
        logger.exception("Transcript generation failed")
        raise HTTPException(500, f"Transcript generation failed: {str(e)}")

    verification = db.query(TranscriptVerification).filter(
        TranscriptVerification.transcript_id == tv.id
    ).first()

    return {
        "version_id": tv.id,
        "version_number": tv.version_number,
        "transcript_type": tv.transcript_type,
        "data": tv.transcript_data,
        "verification_code": verification.verification_code if verification else None,
        "generated_at": tv.generated_at,
    }


@sprint4_router.get("/students/{student_id}/transcripts", response_model=List[TranscriptVersionRead])
def list_transcripts(
    student_id: int,
    transcript_type: Optional[str] = Query(None),
    db: Session = Depends(get_db),
):
    _get_student_or_404(db, student_id)
    q = db.query(TranscriptVersion).filter(TranscriptVersion.student_id == student_id)
    if transcript_type:
        q = q.filter(TranscriptVersion.transcript_type == transcript_type)
    versions = q.order_by(desc(TranscriptVersion.generated_at)).all()

    result = []
    for v in versions:
        ver = db.query(TranscriptVerification).filter(TranscriptVerification.transcript_id == v.id).first()
        result.append({
            "id": v.id,
            "student_id": v.student_id,
            "version_number": v.version_number,
            "transcript_type": v.transcript_type,
            "snapshot_hash": v.snapshot_hash,
            "generated_at": v.generated_at,
            "reason": v.reason,
            "is_current": v.is_current,
            "verification_code": ver.verification_code if ver else None,
        })
    return result


@sprint4_router.get("/students/{student_id}/transcripts/{version_id}", response_model=TranscriptFullResponse)
def get_transcript(student_id: int, version_id: int, db: Session = Depends(get_db)):
    _get_student_or_404(db, student_id)
    tv = db.query(TranscriptVersion).filter(
        TranscriptVersion.id == version_id,
        TranscriptVersion.student_id == student_id,
    ).first()
    if not tv:
        raise HTTPException(404, "Transcript version not found")
    ver = db.query(TranscriptVerification).filter(TranscriptVerification.transcript_id == tv.id).first()
    return {
        "version_id": tv.id,
        "version_number": tv.version_number,
        "transcript_type": tv.transcript_type,
        "data": tv.transcript_data,
        "verification_code": ver.verification_code if ver else None,
        "generated_at": tv.generated_at,
    }


# ═════════════════════════════════════════════════════════════════════════════
# MODULE 7: TRANSCRIPT VERIFICATION
# ═════════════════════════════════════════════════════════════════════════════

@sprint4_router.get(
    "/transcripts/verify/{code}",
    response_model=TranscriptVerifyResponse,
    summary="Externally verify a transcript by code",
)
def verify_transcript(code: str, db: Session = Depends(get_db)):
    result = VerificationService.verify_transcript(db, code)
    return result


# ═════════════════════════════════════════════════════════════════════════════
# MODULE 8: ACADEMIC TIMELINE
# ═════════════════════════════════════════════════════════════════════════════

@sprint4_router.get(
    "/students/{student_id}/timeline",
    response_model=TimelineResponse,
    summary="Get complete academic timeline",
)
def get_timeline(
    student_id: int,
    event_type: Optional[str] = Query(None),
    limit: int = Query(100, ge=1, le=500),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
):
    _get_student_or_404(db, student_id)
    q = db.query(AcademicTimelineEvent).filter(
        AcademicTimelineEvent.student_id == student_id
    )
    if event_type:
        q = q.filter(AcademicTimelineEvent.event_type == event_type)

    total = q.count()
    events = q.order_by(desc(AcademicTimelineEvent.occurred_at)).offset(offset).limit(limit).all()

    return {
        "student_id": student_id,
        "total_events": total,
        "events": events,
    }


# ═════════════════════════════════════════════════════════════════════════════
# MODULE 9: ACADEMIC STATUS
# ═════════════════════════════════════════════════════════════════════════════

@sprint4_router.get("/students/{student_id}/status-history", response_model=List[StatusHistoryRead])
def get_status_history(student_id: int, db: Session = Depends(get_db)):
    _get_student_or_404(db, student_id)
    return db.query(AcademicStatusHistory).filter(
        AcademicStatusHistory.student_id == student_id
    ).order_by(AcademicStatusHistory.occurred_at).all()


@sprint4_router.post("/students/{student_id}/status")
def update_student_status(
    student_id: int,
    new_status: str = Query(...),
    reason: Optional[str] = Query(None),
    db: Session = Depends(get_db),
):
    student = _get_student_or_404(db, student_id)
    AcademicStandingService.record_status_change(
        db, student_id, None,
        new_status,
        cgpa=student.cgpa or 0,
        term_gpa=0,
        reason=reason,
    )
    student.academic_standing = new_status
    db.commit()
    return {"student_id": student_id, "new_status": new_status}


# ═════════════════════════════════════════════════════════════════════════════
# MODULE 10: DEGREE PROGRESS
# ═════════════════════════════════════════════════════════════════════════════

@sprint4_router.get("/students/{student_id}/degree-progress", response_model=DegreeProgressResponse)
def get_degree_progress(student_id: int, db: Session = Depends(get_db)):
    _get_student_or_404(db, student_id)
    snap = db.query(DegreeProgressSnapshot).filter(
        DegreeProgressSnapshot.student_id == student_id
    ).order_by(desc(DegreeProgressSnapshot.version)).first()

    if not snap:
        snap = DegreeProgressService.compute_progress(db, student_id)

    summary = {
        "completion_pct": float(snap.completion_percentage or 0),
        "earned_credits": snap.earned_credits,
        "remaining_credits": snap.remaining_credits,
        "all_requirements_complete": (
            snap.all_core_complete
            and snap.all_electives_complete
            and snap.field_training_complete
            and snap.graduation_project_complete
        ),
    }
    return {"current": snap, "summary": summary}


@sprint4_router.post("/students/{student_id}/degree-progress/recompute")
def recompute_degree_progress(student_id: int, db: Session = Depends(get_db)):
    _get_student_or_404(db, student_id)
    snap = DegreeProgressService.compute_progress(db, student_id)
    return {
        "student_id": student_id,
        "earned_credits": snap.earned_credits,
        "completion_pct": float(snap.completion_percentage or 0),
        "version": snap.version,
    }


# ═════════════════════════════════════════════════════════════════════════════
# MODULE 11: GRADUATION ELIGIBILITY
# ═════════════════════════════════════════════════════════════════════════════

@sprint4_router.get("/students/{student_id}/graduation-eligibility", response_model=GraduationEligibilityRead)
def get_graduation_eligibility(student_id: int, db: Session = Depends(get_db)):
    _get_student_or_404(db, student_id)
    rec = db.query(GraduationEligibilityRecord).filter(
        GraduationEligibilityRecord.student_id == student_id,
        GraduationEligibilityRecord.is_current == True,
    ).first()

    if not rec:
        rec = GraduationEligibilityService.evaluate(db, student_id)
    return rec


@sprint4_router.post("/students/{student_id}/graduation-eligibility/evaluate")
def evaluate_graduation_eligibility(
    student_id: int,
    term_id: Optional[int] = Query(None),
    db: Session = Depends(get_db),
):
    _get_student_or_404(db, student_id)
    rec = GraduationEligibilityService.evaluate(db, student_id, term_id=term_id)
    return {
        "student_id": student_id,
        "eligibility_status": rec.eligibility_status,
        "missing_requirements": rec.missing_requirements,
        "cgpa": float(rec.cgpa_at_evaluation or 0),
    }


# ═════════════════════════════════════════════════════════════════════════════
# MODULE 12: HONORS ENGINE
# ═════════════════════════════════════════════════════════════════════════════

@sprint4_router.get("/students/{student_id}/honors", response_model=List[HonorsRecordRead])
def get_honors_history(student_id: int, db: Session = Depends(get_db)):
    _get_student_or_404(db, student_id)
    return db.query(HonorsRecord).filter(
        HonorsRecord.student_id == student_id
    ).order_by(desc(HonorsRecord.awarded_at)).all()


@sprint4_router.post("/students/{student_id}/honors/evaluate/{term_id}")
def evaluate_honors(student_id: int, term_id: int, db: Session = Depends(get_db)):
    student = _get_student_or_404(db, student_id)
    rec = HonorsService.evaluate_term_honors(db, student_id, term_id, student.program_id)
    if not rec:
        raise HTTPException(400, "Term GPA record not found — finalize term first")
    return {
        "student_id": student_id,
        "term_id": term_id,
        "honors_level": rec.honors_level,
        "is_deans_list": rec.is_deans_list,
    }


# ═════════════════════════════════════════════════════════════════════════════
# MODULE 13: GPA PROJECTION ENGINE
# ═════════════════════════════════════════════════════════════════════════════

@sprint4_router.post("/students/{student_id}/gpa-projection", response_model=GPAProjectionRead)
def project_gpa(
    student_id: int,
    request: ProjectionRequest,
    db: Session = Depends(get_db),
):
    student = _get_student_or_404(db, student_id)
    rec = GPAProjectionService.project(
        db=db,
        student_id=student_id,
        projection_type=request.projection_type,
        target_cgpa=request.target_cgpa,
        remaining_credits=request.remaining_credits,
        registered_courses=request.registered_courses,
        program_id=student.program_id,
    )
    return rec


@sprint4_router.get("/students/{student_id}/gpa-projection/history", response_model=List[GPAProjectionRead])
def get_projection_history(student_id: int, db: Session = Depends(get_db)):
    _get_student_or_404(db, student_id)
    return db.query(GPAProjection).filter(
        GPAProjection.student_id == student_id
    ).order_by(desc(GPAProjection.computed_at)).limit(20).all()


# ═════════════════════════════════════════════════════════════════════════════
# MODULE 14: ACADEMIC RISK ENGINE
# ═════════════════════════════════════════════════════════════════════════════

@sprint4_router.get("/students/{student_id}/academic-risk", response_model=AcademicRiskRead)
def get_academic_risk(student_id: int, db: Session = Depends(get_db)):
    _get_student_or_404(db, student_id)
    rec = db.query(AcademicRiskRecord).filter(
        AcademicRiskRecord.student_id == student_id,
        AcademicRiskRecord.is_current == True,
    ).first()
    if not rec:
        rec = AcademicRiskService.assess_risk(db, student_id)
    return rec


@sprint4_router.post("/students/{student_id}/academic-risk/assess")
def assess_risk(
    student_id: int,
    term_id: Optional[int] = Query(None),
    db: Session = Depends(get_db),
):
    _get_student_or_404(db, student_id)
    rec = AcademicRiskService.assess_risk(db, student_id, term_id=term_id)
    return {
        "student_id": student_id,
        "risk_level": rec.risk_level,
        "risk_score": float(rec.risk_score or 0),
        "risk_factors": rec.risk_factors,
        "recommendations": rec.recommendations,
    }


@sprint4_router.get("/students/{student_id}/academic-risk/history", response_model=List[AcademicRiskRead])
def get_risk_history(student_id: int, db: Session = Depends(get_db)):
    _get_student_or_404(db, student_id)
    return db.query(AcademicRiskRecord).filter(
        AcademicRiskRecord.student_id == student_id
    ).order_by(desc(AcademicRiskRecord.assessed_at)).all()


# ═════════════════════════════════════════════════════════════════════════════
# MODULE 15: REGISTRAR NOTES ENGINE
# ═════════════════════════════════════════════════════════════════════════════

@sprint4_router.post("/registrar/notes", response_model=RegistrarNoteRead, status_code=201)
def create_note(data: RegistrarNoteCreate, db: Session = Depends(get_db)):
    note = RegistrarNoteService.create(db, data.model_dump())
    return note


@sprint4_router.get("/students/{student_id}/registrar/notes", response_model=List[RegistrarNoteRead])
def get_notes(
    student_id: int,
    note_type: Optional[str] = Query(None),
    tag: Optional[str] = Query(None),
    include_private: bool = Query(False),
    db: Session = Depends(get_db),
):
    _get_student_or_404(db, student_id)
    return RegistrarNoteService.search(db, student_id, note_type, tag, include_private)


@sprint4_router.put("/registrar/notes/{note_id}", response_model=RegistrarNoteRead)
def update_note(note_id: int, data: RegistrarNoteUpdate, db: Session = Depends(get_db)):
    try:
        return RegistrarNoteService.update(db, note_id, data.model_dump(exclude_none=True))
    except ValueError as e:
        raise HTTPException(404, str(e))


# ═════════════════════════════════════════════════════════════════════════════
# MODULE 16: ACADEMIC AUDIT TRAIL
# ═════════════════════════════════════════════════════════════════════════════

@sprint4_router.get("/students/{student_id}/audit-trail", response_model=List[AuditEntryRead])
def get_audit_trail(
    student_id: int,
    action: Optional[str] = Query(None),
    limit: int = Query(50, ge=1, le=500),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
):
    _get_student_or_404(db, student_id)
    q = db.query(AcademicAuditEntry).filter(AcademicAuditEntry.student_id == student_id)
    if action:
        q = q.filter(AcademicAuditEntry.action == action)
    return q.order_by(desc(AcademicAuditEntry.occurred_at)).offset(offset).limit(limit).all()


# ═════════════════════════════════════════════════════════════════════════════
# MODULE 17: STUDENT DASHBOARD
# ═════════════════════════════════════════════════════════════════════════════

@sprint4_router.get(
    "/students/{student_id}/dashboard",
    response_model=DashboardResponse,
    summary="Unified academic dashboard for student",
)
def get_student_dashboard(student_id: int, db: Session = Depends(get_db)):
    _get_student_or_404(db, student_id)
    try:
        data = DashboardService.get_dashboard(db, student_id)
        return data
    except Exception as e:
        logger.exception("Dashboard aggregation failed")
        raise HTTPException(500, f"Dashboard computation failed: {str(e)}")
