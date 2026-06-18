"""
EduGuard AI — Sprint 2: Academic Rules Engine Router
Mount in main.py:
    from app.routers.sprint2_router import sprint2_router
    app.include_router(sprint2_router, prefix="/api/v2", tags=["Sprint 2 Academic Rules"])

All endpoints are JWT-protected (reuse existing auth dependency).
"""

from __future__ import annotations

from datetime import datetime
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session, joinedload

from app.db.database import get_db
from app.models.models import Course, Student, User
from app.models.academic_models import (
    AcademicTerm, AcademicProgram, AcademicTrack,
    CoursePrerequisite, StudentCourseAttempt, GradeScale,
    StudentTermGPA,
)
from app.models.sprint2_models import (
    ElectivePool, ElectivePoolCourse, StudentElectiveSelection,
    PrerequisiteException, PrerequisiteValidationLog,
    GraduationAuditResult, AcademicCalendarPeriod,
    AcademicOverride, AcademicOverrideHistory,
    NotificationTemplate, NotificationPreference,
    AcademicDecisionLog, RbacPermission,
)
from app.schemas.sprint2_schemas import (
    CGPADetailResponse, CGPARecalcResponse,
    PrerequisiteCheckRequest, PrerequisiteCheckResponse,
    PrerequisiteChainResponse, PrerequisiteChainNode,
    PrerequisiteExceptionCreate, PrerequisiteExceptionRead,
    GraduationAuditResponse, GraduationAuditHistoryRead,
    CalendarPeriodCreate, CalendarPeriodRead, CalendarPeriodStatusResponse,
    AcademicOverrideCreate, AcademicOverrideDecision, AcademicOverrideRead,
    AcademicOverrideHistoryRead,
    ElectivePoolRead, ElectivePoolWithCoursesRead, StudentElectiveStatusResponse,
    ElectivePoolCourseRead,
    NotificationTemplateRead, NotificationPreferenceRead, NotificationPreferenceUpdate,
    AcademicNotificationCreate,
    DecisionLogRead,
    RbacPermissionRead, RolePermissionsResponse,
    StudentTranscriptResponse, TranscriptRow,
    CGPAVerificationRow, GradeScaleEntryRead,
)
from app.services.sprint2_services import (
    CGPAService, PrerequisiteService, GraduationAuditService,
    AcademicOverrideService, AcademicCalendarService,
    NotificationService, AcademicDecisionLogService, RbacService,
)

sprint2_router = APIRouter()


# ─────────────────────────────────────────────────────────────────────────────
# AUTH STUB — reuse existing auth or adapt to project's pattern
# ─────────────────────────────────────────────────────────────────────────────
try:
    from app.api.auth import get_current_user
except ImportError:
    async def get_current_user(db: Session = Depends(get_db)) -> User:
        raise HTTPException(status_code=401, detail="Auth not configured")


# ═════════════════════════════════════════════════════════════════════════════
# CGPA ENGINE
# ═════════════════════════════════════════════════════════════════════════════

@sprint2_router.get("/students/{student_id}/cgpa", response_model=CGPADetailResponse)
def get_student_cgpa(student_id: int, db: Session = Depends(get_db)):
    """
    Return the NMU-correct CGPA for a student.
    Formula: SUM(credits × grade_points) / SUM(credits) — ALL attempts included.
    Source: CGPA_Calculator.xlsx.
    """
    student = db.query(Student).filter(Student.id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")

    user = db.query(User).filter(User.id == student.user_id).first()

    grade_scale = db.query(GradeScale).filter(
        GradeScale.program_id == student.program_id
    ).order_by(GradeScale.grade_points.desc()).all()

    return CGPADetailResponse(
        student_id                   = student_id,
        student_name                 = user.name if user else "Unknown",
        student_number               = student.student_number or "",
        cgpa                         = float(student.cgpa or 0),
        total_credit_hours_attempted = student.total_credit_hours_attempted or 0,
        total_credit_hours_earned    = student.total_credit_hours_earned or 0,
        total_quality_points         = float(student.total_quality_points or 0),
        academic_standing            = student.academic_standing or "good",
        is_eligible_for_graduation   = student.is_eligible_for_graduation or False,
        grade_scale                  = [
            GradeScaleEntryRead(
                id             = gs.id,
                program_id     = gs.program_id,
                letter_grade   = gs.letter_grade,
                grade_points   = float(gs.grade_points),
                counts_in_cgpa = gs.counts_in_cgpa,
                is_passing     = gs.is_passing,
                description    = gs.description,
                failure_type   = gs.failure_type if hasattr(gs, "failure_type") else None,
            ) for gs in grade_scale
        ],
    )


@sprint2_router.post("/students/{student_id}/cgpa/recalculate", response_model=CGPARecalcResponse)
def recalculate_cgpa(student_id: int, db: Session = Depends(get_db)):
    """
    Force-recompute and persist NMU CGPA for a student.
    Use after importing historical grades or correcting grade entries.
    """
    try:
        old, new = CGPAService.sync_student_cgpa(db, student_id)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))

    return CGPARecalcResponse(
        student_id    = student_id,
        old_cgpa      = old,
        new_cgpa      = new,
        delta         = round(new - old, 3),
        recomputed_at = datetime.utcnow(),
    )


@sprint2_router.get("/cgpa/verify", response_model=List[CGPAVerificationRow])
def verify_all_cgpas(db: Session = Depends(get_db)):
    """
    Audit endpoint: compare stored CGPA vs freshly computed CGPA for all students.
    Returns rows where cgpa_delta > 0.001 (potential sync issues).
    """
    students = db.query(Student).all()
    results  = []
    for s in students:
        user    = db.query(User).filter(User.id == s.user_id).first()
        computed = CGPAService.compute_cgpa(db, s.id)["cgpa"]
        stored   = float(s.cgpa or 0)
        delta    = abs(stored - computed)
        results.append(CGPAVerificationRow(
            student_id               = s.id,
            student_name             = user.name if user else "Unknown",
            student_number           = s.student_number or "",
            stored_cgpa              = stored,
            computed_cgpa            = computed,
            cgpa_delta               = round(delta, 4),
            total_credit_hours_earned = s.total_credit_hours_earned or 0,
            academic_standing        = s.academic_standing or "good",
            has_discrepancy          = delta > 0.001,
        ))
    return results


# ═════════════════════════════════════════════════════════════════════════════
# PREREQUISITE ENGINE
# ═════════════════════════════════════════════════════════════════════════════

@sprint2_router.post("/prerequisites/check", response_model=PrerequisiteCheckResponse)
def check_prerequisite(data: PrerequisiteCheckRequest, db: Session = Depends(get_db)):
    """
    Check if a student meets prerequisites for a course.
    Returns explainable decision with missing prerequisites listed.
    """
    course = db.query(Course).filter(Course.id == data.course_id).first()
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")

    result = PrerequisiteService.check_eligibility(
        db, data.student_id, data.course_id, data.term_id
    )
    return PrerequisiteCheckResponse(
        student_id      = data.student_id,
        course_id       = data.course_id,
        course_code     = course.code,
        course_name     = course.name,
        eligible        = result["eligible"],
        missing_prereqs = result["missing_prereqs"],
        reasons         = result["reasons"],
        rule_triggered  = result["rule_triggered"],
        explanation     = result["explanation"],
        checked_at      = datetime.utcnow(),
        waiver_applied  = result["waiver_applied"],
    )


@sprint2_router.get("/students/{student_id}/eligible-courses-v2")
def get_eligible_courses_v2(
    student_id:     int,
    term_id:        int,
    eligible_only:  bool = True,
    db: Session = Depends(get_db),
):
    """
    Return all courses with eligibility status for a student in a term.
    When eligible_only=True (default), returns only courses the student can register.
    """
    results = PrerequisiteService.get_eligible_courses(db, student_id, term_id)
    if eligible_only:
        results = [r for r in results if r["is_eligible"]]
    return {"student_id": student_id, "term_id": term_id,
            "courses": results, "total": len(results), "computed_at": datetime.utcnow()}


@sprint2_router.get("/courses/{course_id}/prerequisite-chain",
                    response_model=PrerequisiteChainResponse)
def get_prerequisite_chain(course_id: int, db: Session = Depends(get_db)):
    """Return the full prerequisite dependency chain for a course."""
    course = db.query(Course).filter(Course.id == course_id).first()
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")

    chain = PrerequisiteService.get_course_chain(db, course_id)
    return PrerequisiteChainResponse(
        course_code   = course.code,
        course_name   = course.name,
        plan_semester = course.plan_semester,
        prerequisites = [PrerequisiteChainNode(**node) for node in chain],
    )


@sprint2_router.post("/prerequisites/exceptions",
                     response_model=PrerequisiteExceptionRead, status_code=201)
def grant_prereq_exception(data: PrerequisiteExceptionCreate,
                            current_user: User = Depends(get_current_user),
                            db: Session = Depends(get_db)):
    """
    Grant a prerequisite waiver for a student.
    Requires advisor or admin role. Stored in prerequisite_exceptions.
    All waivers are auditable.
    """
    exc = PrerequisiteService.grant_exception(
        db,
        student_id       = data.student_id,
        course_id        = data.course_id,
        waived_prereq_id = data.waived_prereq_id,
        granted_by       = current_user.id,
        reason           = data.reason,
        expires_at       = data.expires_at,
    )
    return PrerequisiteExceptionRead(
        id               = exc.id,
        student_id       = exc.student_id,
        course_id        = exc.course_id,
        waived_prereq_id = exc.waived_prereq_id,
        granted_by       = exc.granted_by,
        reason           = exc.reason,
        approved_at      = exc.approved_at,
        expires_at       = exc.expires_at,
        is_active        = exc.is_active,
    )


@sprint2_router.get("/students/{student_id}/prerequisite-exceptions",
                    response_model=List[PrerequisiteExceptionRead])
def list_prereq_exceptions(student_id: int, db: Session = Depends(get_db)):
    excs = db.query(PrerequisiteException).filter(
        PrerequisiteException.student_id == student_id,
        PrerequisiteException.is_active  == True,
    ).all()
    return [PrerequisiteExceptionRead(
        id=e.id, student_id=e.student_id, course_id=e.course_id,
        waived_prereq_id=e.waived_prereq_id, granted_by=e.granted_by,
        reason=e.reason, approved_at=e.approved_at,
        expires_at=e.expires_at, is_active=e.is_active,
    ) for e in excs]


# ═════════════════════════════════════════════════════════════════════════════
# GRADUATION AUDIT ENGINE
# ═════════════════════════════════════════════════════════════════════════════

@sprint2_router.post("/students/{student_id}/graduation-audit",
                     response_model=GraduationAuditResponse)
def run_graduation_audit(student_id: int, db: Session = Depends(get_db)):
    """
    Run NMU graduation eligibility audit for a student.
    Checks all 7 NMU SE Track requirements.
    Stores result in graduation_audit_results.
    Updates students.is_eligible_for_graduation.
    """
    try:
        result = GraduationAuditService.run_audit(db, student_id)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    return GraduationAuditResponse(**result)


@sprint2_router.get("/students/{student_id}/graduation-audit/history",
                    response_model=List[GraduationAuditHistoryRead])
def get_graduation_audit_history(student_id: int, db: Session = Depends(get_db)):
    """Return all previous graduation audit snapshots for a student."""
    return db.query(GraduationAuditResult).filter(
        GraduationAuditResult.student_id == student_id
    ).order_by(GraduationAuditResult.audited_at.desc()).all()


@sprint2_router.get("/graduation-readiness")
def get_graduation_readiness_dashboard(
    program_id: Optional[int] = None,
    db: Session = Depends(get_db),
):
    """
    Graduation readiness dashboard: all students with their eligibility status.
    Filters by program_id if provided.
    """
    q = db.query(Student)
    if program_id:
        q = q.filter(Student.program_id == program_id)
    students = q.all()

    result = []
    for s in students:
        user = db.query(User).filter(User.id == s.user_id).first()
        result.append({
            "student_id":             s.id,
            "student_name":           user.name if user else "Unknown",
            "student_number":         s.student_number,
            "cgpa":                   float(s.cgpa or 0),
            "ch_earned":              s.total_credit_hours_earned or 0,
            "ch_remaining":           max(0, 134 - (s.total_credit_hours_earned or 0)),
            "academic_standing":      s.academic_standing or "good",
            "is_eligible":            s.is_eligible_for_graduation or False,
        })
    return {"students": result, "total": len(result)}


# ═════════════════════════════════════════════════════════════════════════════
# ACADEMIC CALENDAR
# ═════════════════════════════════════════════════════════════════════════════

@sprint2_router.post("/calendar/periods",
                     response_model=CalendarPeriodRead, status_code=201)
def create_calendar_period(data: CalendarPeriodCreate, db: Session = Depends(get_db)):
    """Create a calendar period for a term. All academic dates are data-driven."""
    period = AcademicCalendarPeriod(**data.model_dump())
    db.add(period)
    db.commit()
    db.refresh(period)
    return period


@sprint2_router.get("/calendar/terms/{term_id}/periods",
                    response_model=List[CalendarPeriodRead])
def get_term_calendar(term_id: int, db: Session = Depends(get_db)):
    """Return all calendar periods for a term."""
    return AcademicCalendarService.get_term_periods(db, term_id)


@sprint2_router.get("/calendar/terms/{term_id}/periods/{period_type}/status",
                    response_model=CalendarPeriodStatusResponse)
def check_period_status(term_id: int, period_type: str, db: Session = Depends(get_db)):
    """Check if a calendar period type is currently active."""
    is_active = AcademicCalendarService.is_period_active(db, term_id, period_type)
    period    = db.query(AcademicCalendarPeriod).filter(
        AcademicCalendarPeriod.term_id     == term_id,
        AcademicCalendarPeriod.period_type == period_type,
    ).first()
    return CalendarPeriodStatusResponse(
        term_id     = term_id,
        period_type = period_type,
        is_active   = is_active,
        start_date  = period.start_date if period else None,
        end_date    = period.end_date   if period else None,
        checked_at  = datetime.utcnow(),
    )


# ═════════════════════════════════════════════════════════════════════════════
# ACADEMIC OVERRIDES
# ═════════════════════════════════════════════════════════════════════════════

@sprint2_router.post("/overrides",
                     response_model=AcademicOverrideRead, status_code=201)
def create_override(
    data:         AcademicOverrideCreate,
    current_user: User = Depends(get_current_user),
    db:           Session = Depends(get_db),
):
    """Request an academic override (prerequisite waiver, registration override, etc.)."""
    override = AcademicOverrideService.create_override(
        db            = db,
        override_type = data.override_type,
        student_id    = data.student_id,
        requested_by  = current_user.id,
        reason        = data.reason,
        course_id     = data.course_id,
        term_id       = data.term_id,
        metadata_json = data.metadata_json,
    )
    return AcademicOverrideRead.model_validate(override)


@sprint2_router.patch("/overrides/{override_id}/decide",
                      response_model=AcademicOverrideRead)
def decide_override(
    override_id:  int,
    data:         AcademicOverrideDecision,
    current_user: User = Depends(get_current_user),
    db:           Session = Depends(get_db),
):
    """Approve or reject an academic override. Requires advisor/admin/registrar role."""
    try:
        override = AcademicOverrideService.decide_override(
            db              = db,
            override_id     = override_id,
            reviewed_by     = current_user.id,
            action          = data.action,
            decision_reason = data.decision_reason,
            reviewer_notes  = data.reviewer_notes,
            expires_at      = data.expires_at,
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    return AcademicOverrideRead.model_validate(override)


@sprint2_router.get("/overrides/{override_id}", response_model=AcademicOverrideRead)
def get_override(override_id: int, db: Session = Depends(get_db)):
    override = db.query(AcademicOverride).filter(AcademicOverride.id == override_id).first()
    if not override:
        raise HTTPException(status_code=404, detail="Override not found")
    return AcademicOverrideRead.model_validate(override)


@sprint2_router.get("/overrides/{override_id}/history",
                    response_model=List[AcademicOverrideHistoryRead])
def get_override_history(override_id: int, db: Session = Depends(get_db)):
    """Full immutable audit trail for an override."""
    return (
        db.query(AcademicOverrideHistory)
        .filter(AcademicOverrideHistory.override_id == override_id)
        .order_by(AcademicOverrideHistory.performed_at)
        .all()
    )


@sprint2_router.get("/students/{student_id}/overrides",
                    response_model=List[AcademicOverrideRead])
def list_student_overrides(
    student_id: int,
    status:     Optional[str] = None,
    db: Session = Depends(get_db),
):
    q = db.query(AcademicOverride).filter(AcademicOverride.student_id == student_id)
    if status:
        q = q.filter(AcademicOverride.status == status)
    return [AcademicOverrideRead.model_validate(o) for o in q.order_by(AcademicOverride.created_at.desc()).all()]


# ═════════════════════════════════════════════════════════════════════════════
# ELECTIVE MANAGEMENT
# ═════════════════════════════════════════════════════════════════════════════

@sprint2_router.get("/programs/{program_id}/elective-pools",
                    response_model=List[ElectivePoolWithCoursesRead])
def get_elective_pools(program_id: int, db: Session = Depends(get_db)):
    """Return elective pools with all courses for a program."""
    pools = (
        db.query(ElectivePool)
        .filter(ElectivePool.program_id == program_id)
        .options(joinedload(ElectivePool.courses))
        .all()
    )
    result = []
    for pool in pools:
        courses_out = []
        for epc in pool.courses:
            c = db.query(Course).filter(Course.id == epc.course_id).first()
            if c:
                courses_out.append(ElectivePoolCourseRead(
                    id=epc.id, pool_id=pool.id, course_id=c.id,
                    course_code=c.code, course_name=c.name,
                    credits=c.credits, plan_semester=c.plan_semester,
                ))
        result.append(ElectivePoolWithCoursesRead(
            id=pool.id, program_id=pool.program_id, track_id=pool.track_id,
            pool_code=pool.pool_code, pool_name=pool.pool_name,
            min_selections=pool.min_selections, max_selections=pool.max_selections,
            required_selections=pool.required_selections,
            plan_semesters=pool.plan_semesters, notes=pool.notes,
            courses=courses_out,
        ))
    return result


@sprint2_router.get("/students/{student_id}/elective-status",
                    response_model=StudentElectiveStatusResponse)
def get_student_elective_status(student_id: int, db: Session = Depends(get_db)):
    """Return elective completion status for a student."""
    student = db.query(Student).filter(Student.id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")

    pool = db.query(ElectivePool).filter(ElectivePool.program_id == student.program_id).first()
    if not pool:
        raise HTTPException(status_code=404, detail="No elective pool found for student's program")

    pool_course_ids = {
        epc.course_id for epc in
        db.query(ElectivePoolCourse).filter(ElectivePoolCourse.pool_id == pool.id).all()
    }
    passed_ids = {
        a.course_id for a in
        db.query(StudentCourseAttempt)
        .filter(StudentCourseAttempt.student_id == student_id, StudentCourseAttempt.result == "passed")
        .all()
    }

    selected_ids  = passed_ids & pool_course_ids
    available_ids = pool_course_ids - passed_ids

    def make_course_read(course_id: int, pool_id: int) -> ElectivePoolCourseRead:
        c = db.query(Course).filter(Course.id == course_id).first()
        return ElectivePoolCourseRead(
            id=0, pool_id=pool_id, course_id=course_id,
            course_code=c.code if c else "", course_name=c.name if c else "",
            credits=c.credits if c else 3, plan_semester=c.plan_semester if c else None,
        )

    return StudentElectiveStatusResponse(
        student_id       = student_id,
        pool_id          = pool.id,
        pool_name        = pool.pool_name,
        required         = pool.required_selections,
        selected_count   = len(selected_ids),
        remaining        = max(0, pool.required_selections - len(selected_ids)),
        is_complete      = len(selected_ids) >= pool.required_selections,
        selected_courses = [make_course_read(cid, pool.id) for cid in selected_ids],
        available_courses = [make_course_read(cid, pool.id) for cid in available_ids],
    )


# ═════════════════════════════════════════════════════════════════════════════
# NOTIFICATION FRAMEWORK
# ═════════════════════════════════════════════════════════════════════════════

@sprint2_router.get("/notification-templates",
                    response_model=List[NotificationTemplateRead])
def list_notification_templates(db: Session = Depends(get_db)):
    return db.query(NotificationTemplate).filter(NotificationTemplate.is_active == True).all()


@sprint2_router.post("/notifications/send", status_code=202)
def send_academic_notification(
    data: AcademicNotificationCreate,
    db:   Session = Depends(get_db),
):
    """Trigger an academic notification for a student using the template engine."""
    notif_id = NotificationService.send_academic_notification(
        db, data.event_type, data.student_id, data.context
    )
    if notif_id is None:
        raise HTTPException(status_code=404,
                            detail=f"No active template for event_type={data.event_type}")
    return {"notification_id": notif_id, "status": "sent"}


@sprint2_router.get("/users/{user_id}/notification-preferences",
                    response_model=List[NotificationPreferenceRead])
def get_notification_prefs(user_id: int, db: Session = Depends(get_db)):
    return db.query(NotificationPreference).filter(
        NotificationPreference.user_id == user_id
    ).all()


@sprint2_router.put("/users/{user_id}/notification-preferences/{event_type}",
                    response_model=NotificationPreferenceRead)
def update_notification_pref(
    user_id:    int,
    event_type: str,
    data:       NotificationPreferenceUpdate,
    db:         Session = Depends(get_db),
):
    pref = db.query(NotificationPreference).filter(
        NotificationPreference.user_id    == user_id,
        NotificationPreference.event_type == event_type,
    ).first()
    if not pref:
        pref = NotificationPreference(user_id=user_id, event_type=event_type)
        db.add(pref)
    pref.in_app = data.in_app
    pref.email  = data.email
    pref.sms    = data.sms
    db.commit()
    db.refresh(pref)
    return pref


# ═════════════════════════════════════════════════════════════════════════════
# EXPLAINABILITY — DECISION LOG
# ═════════════════════════════════════════════════════════════════════════════

@sprint2_router.get("/students/{student_id}/decisions",
                    response_model=List[DecisionLogRead])
def get_student_decisions(
    student_id:    int,
    decision_type: Optional[str] = None,
    limit:         int = Query(50, le=200),
    db: Session = Depends(get_db),
):
    """
    Return academic decision history for a student with full explanations.
    Answers: "Why was this course rejected?", "Why is graduation blocked?"
    """
    q = db.query(AcademicDecisionLog).filter(AcademicDecisionLog.student_id == student_id)
    if decision_type:
        q = q.filter(AcademicDecisionLog.decision_type == decision_type)
    return q.order_by(AcademicDecisionLog.decided_at.desc()).limit(limit).all()


# ═════════════════════════════════════════════════════════════════════════════
# RBAC
# ═════════════════════════════════════════════════════════════════════════════

@sprint2_router.get("/rbac/roles/{role}/permissions",
                    response_model=RolePermissionsResponse)
def get_role_permissions(role: str, db: Session = Depends(get_db)):
    perms = RbacService.get_role_permissions(db, role)
    return RolePermissionsResponse(
        role        = role,
        permissions = [RbacPermissionRead.model_validate(p) for p in perms],
    )


@sprint2_router.get("/rbac/check")
def check_permission(
    role:     str = Query(...),
    resource: str = Query(...),
    action:   str = Query(...),
    db: Session = Depends(get_db),
):
    """Quick permission check: does this role have this action on this resource?"""
    allowed = RbacService.has_permission(db, role, resource, action)
    return {"role": role, "resource": resource, "action": action, "allowed": allowed}


# ═════════════════════════════════════════════════════════════════════════════
# REPORTING FOUNDATION
# ═════════════════════════════════════════════════════════════════════════════

@sprint2_router.get("/students/{student_id}/transcript",
                    response_model=StudentTranscriptResponse)
def get_student_transcript(student_id: int, db: Session = Depends(get_db)):
    """
    Full academic transcript for a student.
    Includes ALL attempts (NMU rule: all attempts are part of CGPA calculation).
    """
    from app.models.academic_models import AcademicProgram, AcademicTrack

    student = db.query(Student).filter(Student.id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")

    user    = db.query(User).filter(User.id == student.user_id).first()
    program = db.query(AcademicProgram).filter(AcademicProgram.id == student.program_id).first()
    track   = db.query(AcademicTrack).filter(AcademicTrack.id == student.track_id).first()

    attempts = (
        db.query(StudentCourseAttempt)
        .options(joinedload(StudentCourseAttempt.course), joinedload(StudentCourseAttempt.term))
        .filter(StudentCourseAttempt.student_id == student_id)
        .order_by(StudentCourseAttempt.term_id, StudentCourseAttempt.course_id,
                  StudentCourseAttempt.attempt_number)
        .all()
    )

    rows = []
    for a in attempts:
        if not a.course or not a.term:
            continue
        rows.append(TranscriptRow(
            attempt_id            = a.id,
            course_code           = a.course.code,
            course_name           = a.course.name,
            credit_hours          = a.credit_hours,
            category              = a.course.category or "core",
            attempt_number        = a.attempt_number,
            numeric_grade         = float(a.numeric_grade) if a.numeric_grade else None,
            letter_grade          = a.letter_grade,
            grade_points          = float(a.grade_points) if a.grade_points else None,
            result                = a.result,
            counts_in_cgpa        = a.counts_in_cgpa,
            term_code             = a.term.code,
            academic_year         = a.term.academic_year,
            term_type             = a.term.term_type,
            is_improvement_attempt = a.is_improvement_attempt,
        ))

    return StudentTranscriptResponse(
        student_id         = student_id,
        student_name       = user.name if user else "Unknown",
        student_number     = student.student_number or "",
        program            = program.name if program else None,
        track              = track.name if track else None,
        cgpa               = float(student.cgpa or 0),
        total_ch_attempted = student.total_credit_hours_attempted or 0,
        total_ch_earned    = student.total_credit_hours_earned or 0,
        academic_standing  = student.academic_standing or "good",
        attempts           = rows,
        generated_at       = datetime.utcnow(),
    )


@sprint2_router.get("/grade-scale/{program_id}",
                    response_model=List[GradeScaleEntryRead])
def get_nmu_grade_scale(program_id: int, db: Session = Depends(get_db)):
    """Return the NMU grade scale (14 symbols) for a program."""
    entries = (
        db.query(GradeScale)
        .filter(GradeScale.program_id == program_id)
        .order_by(GradeScale.grade_points.desc())
        .all()
    )
    if not entries:
        raise HTTPException(status_code=404,
                            detail="Grade scale not found. Run 003_sprint2_seed.sql first.")
    return [GradeScaleEntryRead(
        id             = e.id,
        program_id     = e.program_id,
        letter_grade   = e.letter_grade,
        grade_points   = float(e.grade_points),
        counts_in_cgpa = e.counts_in_cgpa,
        is_passing     = e.is_passing,
        description    = e.description,
        failure_type   = getattr(e, "failure_type", None),
    ) for e in entries]
