"""
EduGuard AI — Sprint 1: Academic Foundation API Router
FastAPI router exposing the academic foundation endpoints.
Mount this in main.py: app.include_router(academic_router, prefix="/api/academic")
"""

from datetime import datetime
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import and_, or_

from app.db.database import get_db
from app.models.models import (
    Course, Student, Advisor, Professor, User,
    Enrollment,
)
from app.models.academic_models import (
    AcademicProgram, AcademicTrack, AcademicTerm,
    CoursePrerequisite, CoursePostrequisite, CourseEligibilityRule,
    CourseOffering, StudentCourseAttempt, GradeScale,
    StudentTermGPA, GraduationRequirement, StudentGraduationProgress,
    AdvisingPlan, AdvisingPlanItem, ImportJob,
)
from app.schemas.academic_schemas import (
    AcademicProgramRead, AcademicProgramCreate,
    AcademicTrackRead, AcademicTrackCreate,
    AcademicTermRead, AcademicTermCreate,
    CourseRead, CourseCreate, CourseWithDependencies,
    PrerequisiteRead, PrerequisiteCreate,
    PostrequisiteRead,
    EligibilityRuleRead,
    CourseOfferingRead, CourseOfferingCreate,
    StudentCourseAttemptRead, StudentCourseAttemptCreate, GradePostRequest,
    GradeScaleRead,
    StudentTermGPARead,
    GraduationRequirementRead, StudentGraduationProgressRead, GraduationStatusRead,
    AdvisingPlanRead, AdvisingPlanCreate, AdvisingPlanReviewRequest,
    StudentEligibleCoursesResponse, CourseEligibilityResult,
    StudentAcademicProfileRead,
    ImportJobRead,
)
# Auth dependency (reuse existing)
try:
    from app.auth.auth import get_current_user
except ImportError:
    # Fallback stub if auth module path differs
    async def get_current_user(db: Session = Depends(get_db)) -> User:  # type: ignore
        raise HTTPException(status_code=401, detail="Auth not configured")

academic_router = APIRouter(tags=["Academic Foundation"])


# ═════════════════════════════════════════════════════════════════════════════
# PROGRAMS
# ═════════════════════════════════════════════════════════════════════════════

@academic_router.get("/programs", response_model=List[AcademicProgramRead])
def list_programs(db: Session = Depends(get_db)):
    return db.query(AcademicProgram).options(
        joinedload(AcademicProgram.tracks)
    ).all()


@academic_router.get("/programs/{program_id}", response_model=AcademicProgramRead)
def get_program(program_id: int, db: Session = Depends(get_db)):
    prog = db.query(AcademicProgram).options(
        joinedload(AcademicProgram.tracks)
    ).filter(AcademicProgram.id == program_id).first()
    if not prog:
        raise HTTPException(status_code=404, detail="Program not found")
    return prog


@academic_router.post("/programs", response_model=AcademicProgramRead, status_code=201)
def create_program(data: AcademicProgramCreate, db: Session = Depends(get_db)):
    prog = AcademicProgram(**data.model_dump())
    db.add(prog)
    db.commit()
    db.refresh(prog)
    return prog


# ═════════════════════════════════════════════════════════════════════════════
# TRACKS
# ═════════════════════════════════════════════════════════════════════════════

@academic_router.get("/programs/{program_id}/tracks", response_model=List[AcademicTrackRead])
def list_tracks(program_id: int, db: Session = Depends(get_db)):
    return db.query(AcademicTrack).filter(AcademicTrack.program_id == program_id).all()


@academic_router.post("/tracks", response_model=AcademicTrackRead, status_code=201)
def create_track(data: AcademicTrackCreate, db: Session = Depends(get_db)):
    track = AcademicTrack(**data.model_dump())
    db.add(track)
    db.commit()
    db.refresh(track)
    return track


# ═════════════════════════════════════════════════════════════════════════════
# TERMS
# ═════════════════════════════════════════════════════════════════════════════

@academic_router.get("/terms", response_model=List[AcademicTermRead])
def list_terms(
    active_only: bool = False,
    db: Session = Depends(get_db)
):
    q = db.query(AcademicTerm)
    if active_only:
        q = q.filter(AcademicTerm.is_active == True)
    return q.order_by(AcademicTerm.academic_year.desc(), AcademicTerm.term_type).all()


@academic_router.get("/terms/current", response_model=Optional[AcademicTermRead])
def get_current_term(db: Session = Depends(get_db)):
    term = db.query(AcademicTerm).filter(AcademicTerm.is_active == True).first()
    if not term:
        raise HTTPException(status_code=404, detail="No active term configured")
    return term


@academic_router.post("/terms", response_model=AcademicTermRead, status_code=201)
def create_term(data: AcademicTermCreate, db: Session = Depends(get_db)):
    term = AcademicTerm(**data.model_dump())
    db.add(term)
    db.commit()
    db.refresh(term)
    return term


# ═════════════════════════════════════════════════════════════════════════════
# COURSES
# ═════════════════════════════════════════════════════════════════════════════

@academic_router.get("/courses", response_model=List[CourseRead])
def list_courses(
    program_id: Optional[int]  = None,
    track_id:   Optional[int]  = None,
    category:   Optional[str]  = None,
    plan_semester: Optional[int] = None,
    db: Session = Depends(get_db)
):
    q = db.query(Course).filter(Course.is_active == True)
    if program_id:
        q = q.filter(Course.program_id == program_id)
    if track_id:
        q = q.filter(Course.track_id == track_id)
    if category:
        q = q.filter(Course.category == category)
    if plan_semester:
        q = q.filter(Course.plan_semester == plan_semester)
    return q.order_by(Course.plan_semester.asc().nullslast(), Course.code).all()


@academic_router.get("/courses/{course_id}", response_model=CourseWithDependencies)
def get_course(course_id: int, db: Session = Depends(get_db)):
    course = db.query(Course).options(
        joinedload(Course.prerequisites),
        joinedload(Course.postrequisites),
        joinedload(Course.eligibility_rules),
    ).filter(Course.id == course_id).first()
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    return course


@academic_router.get("/courses/code/{code}", response_model=CourseWithDependencies)
def get_course_by_code(code: str, db: Session = Depends(get_db)):
    course = db.query(Course).options(
        joinedload(Course.prerequisites),
        joinedload(Course.postrequisites),
        joinedload(Course.eligibility_rules),
    ).filter(Course.code == code.upper()).first()
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    return course


@academic_router.post("/courses", response_model=CourseRead, status_code=201)
def create_course(data: CourseCreate, db: Session = Depends(get_db)):
    course = Course(**data.model_dump())
    db.add(course)
    db.commit()
    db.refresh(course)
    return course


# ═════════════════════════════════════════════════════════════════════════════
# GRADE SCALE
# ═════════════════════════════════════════════════════════════════════════════

@academic_router.get("/grade-scale/{program_id}", response_model=List[GradeScaleRead])
def get_grade_scale(program_id: int, db: Session = Depends(get_db)):
    return db.query(GradeScale).filter(
        GradeScale.program_id == program_id
    ).order_by(GradeScale.grade_points.desc()).all()


# ═════════════════════════════════════════════════════════════════════════════
# COURSE OFFERINGS
# ═════════════════════════════════════════════════════════════════════════════

@academic_router.get("/offerings", response_model=List[CourseOfferingRead])
def list_offerings(
    term_id:    Optional[int] = None,
    course_id:  Optional[int] = None,
    is_open:    bool          = True,
    db: Session = Depends(get_db)
):
    q = db.query(CourseOffering).options(
        joinedload(CourseOffering.course),
        joinedload(CourseOffering.term),
    )
    if term_id:
        q = q.filter(CourseOffering.term_id == term_id)
    if course_id:
        q = q.filter(CourseOffering.course_id == course_id)
    if is_open:
        q = q.filter(CourseOffering.is_open == True)
    return q.all()


@academic_router.post("/offerings", response_model=CourseOfferingRead, status_code=201)
def create_offering(data: CourseOfferingCreate, db: Session = Depends(get_db)):
    offering = CourseOffering(**data.model_dump())
    db.add(offering)
    db.commit()
    db.refresh(offering)
    return offering


# ═════════════════════════════════════════════════════════════════════════════
# STUDENT COURSE ATTEMPTS (TRANSCRIPT)
# ═════════════════════════════════════════════════════════════════════════════

@academic_router.get("/students/{student_id}/attempts", response_model=List[StudentCourseAttemptRead])
def get_student_attempts(
    student_id: int,
    term_id:    Optional[int] = None,
    db: Session = Depends(get_db)
):
    q = db.query(StudentCourseAttempt).options(
        joinedload(StudentCourseAttempt.course),
        joinedload(StudentCourseAttempt.term),
    ).filter(StudentCourseAttempt.student_id == student_id)
    if term_id:
        q = q.filter(StudentCourseAttempt.term_id == term_id)
    return q.order_by(StudentCourseAttempt.term_id, StudentCourseAttempt.course_id).all()


@academic_router.post("/students/{student_id}/attempts", response_model=StudentCourseAttemptRead, status_code=201)
def register_course_attempt(
    student_id: int,
    data: StudentCourseAttemptCreate,
    db: Session = Depends(get_db)
):
    # Determine attempt number
    existing = db.query(StudentCourseAttempt).filter(
        StudentCourseAttempt.student_id == student_id,
        StudentCourseAttempt.course_id  == data.course_id,
    ).count()

    attempt = StudentCourseAttempt(
        **data.model_dump(),
        student_id     = student_id,
        attempt_number = existing + 1,
    )
    db.add(attempt)
    db.commit()
    db.refresh(attempt)
    return attempt


@academic_router.patch("/attempts/{attempt_id}/grade", response_model=StudentCourseAttemptRead)
def post_grade(attempt_id: int, data: GradePostRequest, db: Session = Depends(get_db)):
    attempt = db.query(StudentCourseAttempt).filter(
        StudentCourseAttempt.id == attempt_id
    ).first()
    if not attempt:
        raise HTTPException(status_code=404, detail="Attempt not found")

    attempt.numeric_grade  = data.numeric_grade
    attempt.letter_grade   = data.letter_grade
    attempt.grade_points   = data.grade_points
    attempt.result         = data.result
    attempt.grade_posted_at = datetime.utcnow()
    db.commit()
    db.refresh(attempt)
    return attempt


# ═════════════════════════════════════════════════════════════════════════════
# STUDENT TERM GPA
# ═════════════════════════════════════════════════════════════════════════════

@academic_router.get("/students/{student_id}/term-gpa", response_model=List[StudentTermGPARead])
def get_student_term_gpa(student_id: int, db: Session = Depends(get_db)):
    return db.query(StudentTermGPA).options(
        joinedload(StudentTermGPA.term)
    ).filter(StudentTermGPA.student_id == student_id).order_by(
        StudentTermGPA.term_id
    ).all()


# ═════════════════════════════════════════════════════════════════════════════
# STUDENT ACADEMIC PROFILE
# ═════════════════════════════════════════════════════════════════════════════

@academic_router.get("/students/{student_id}/profile", response_model=StudentAcademicProfileRead)
def get_student_academic_profile(student_id: int, db: Session = Depends(get_db)):
    student = db.query(Student).filter(Student.id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    return student


# ═════════════════════════════════════════════════════════════════════════════
# COURSE ELIGIBILITY CHECK
# ═════════════════════════════════════════════════════════════════════════════

@academic_router.get("/students/{student_id}/eligible-courses", response_model=StudentEligibleCoursesResponse)
def get_eligible_courses(
    student_id: int,
    term_id:    int,
    db: Session = Depends(get_db)
):
    """
    Returns all courses the student is eligible to register for in a given term.
    Checks:
      1. Has not already passed the course (unless improvement attempt)
      2. All hard prerequisites are satisfied (passed)
      3. Eligibility rules (min credits, min CGPA, etc.)
    """
    student = db.query(Student).filter(Student.id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")

    # Build set of passed course IDs
    passed_attempts = db.query(StudentCourseAttempt).filter(
        StudentCourseAttempt.student_id == student_id,
        StudentCourseAttempt.result == "passed",
    ).all()
    passed_ids = {a.course_id for a in passed_attempts}

    # Build set of courses currently in progress this term
    in_progress_ids = {
        a.course_id for a in db.query(StudentCourseAttempt).filter(
            StudentCourseAttempt.student_id == student_id,
            StudentCourseAttempt.term_id    == term_id,
            StudentCourseAttempt.result     == "in_progress",
        ).all()
    }

    # Get all active courses in the student's program
    all_courses = db.query(Course).filter(
        Course.program_id == student.program_id,
        Course.is_active  == True,
        Course.category.in_(["core", "elective", "field_training"]),
    ).all()

    results: List[CourseEligibilityResult] = []

    for course in all_courses:
        reasons: List[str]       = []
        missing: List[str]       = []
        eligible: bool           = True

        # Already passed?
        if course.id in passed_ids:
            eligible = False
            reasons.append("Already passed")
            results.append(CourseEligibilityResult(
                course_id=course.id, course_code=course.code,
                course_name=course.name, is_eligible=eligible,
                reasons=reasons, missing_prereqs=missing
            ))
            continue

        # Already enrolled this term?
        if course.id in in_progress_ids:
            eligible = False
            reasons.append("Already registered this term")
            results.append(CourseEligibilityResult(
                course_id=course.id, course_code=course.code,
                course_name=course.name, is_eligible=eligible,
                reasons=reasons, missing_prereqs=missing
            ))
            continue

        # Check prerequisites
        prereqs = db.query(CoursePrerequisite).filter(
            CoursePrerequisite.course_id   == course.id,
            CoursePrerequisite.prereq_type == "hard",
        ).all()

        for pr in prereqs:
            prereq_course = db.query(Course).filter(Course.id == pr.prerequisite_id).first()
            if pr.prerequisite_id not in passed_ids:
                eligible = False
                if prereq_course:
                    missing.append(prereq_course.code)

        # Check eligibility rules
        rules = db.query(CourseEligibilityRule).filter(
            CourseEligibilityRule.course_id    == course.id,
            CourseEligibilityRule.is_mandatory == True,
        ).all()

        for rule in rules:
            if rule.rule_type == "min_credits_earned":
                if (student.total_credit_hours_earned or 0) < (rule.rule_value or 0):
                    eligible = False
                    reasons.append(f"Need {int(rule.rule_value)} earned credits (have {student.total_credit_hours_earned})")
            elif rule.rule_type == "min_cgpa":
                if float(student.cgpa or 0) < float(rule.rule_value or 0):
                    eligible = False
                    reasons.append(f"Need CGPA ≥ {rule.rule_value} (have {student.cgpa})")
            elif rule.rule_type == "min_level":
                if (student.academic_level or 1) < int(rule.rule_value or 1):
                    eligible = False
                    reasons.append(f"Need academic level {int(rule.rule_value)}")

        if eligible:
            reasons.append("All requirements satisfied")

        results.append(CourseEligibilityResult(
            course_id=course.id, course_code=course.code,
            course_name=course.name, is_eligible=eligible,
            reasons=reasons, missing_prereqs=missing
        ))

    eligible_results = [r for r in results if r.is_eligible]

    return StudentEligibleCoursesResponse(
        student_id=student_id,
        term_id=term_id,
        eligible_courses=eligible_results,
        total_eligible=len(eligible_results),
        computed_at=datetime.utcnow(),
    )


# ═════════════════════════════════════════════════════════════════════════════
# GRADUATION PROGRESS
# ═════════════════════════════════════════════════════════════════════════════

@academic_router.get("/students/{student_id}/graduation-status", response_model=GraduationStatusRead)
def get_graduation_status(student_id: int, db: Session = Depends(get_db)):
    student = db.query(Student).filter(Student.id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")

    progress = db.query(StudentGraduationProgress).options(
        joinedload(StudentGraduationProgress.requirement)
    ).filter(StudentGraduationProgress.student_id == student_id).all()

    total_req = sum(p.requirement.required_credits for p in progress if p.requirement)
    total_done = sum(p.credits_completed for p in progress)
    overall_pct = round((total_done / total_req * 100) if total_req > 0 else 0, 2)

    return GraduationStatusRead(
        student_id=student_id,
        cgpa=float(student.cgpa or 0),
        total_credits_earned=student.total_credit_hours_earned or 0,
        is_eligible_for_graduation=student.is_eligible_for_graduation or False,
        overall_completion_pct=overall_pct,
        requirements=progress,
    )


# ═════════════════════════════════════════════════════════════════════════════
# ADVISING PLANS
# ═════════════════════════════════════════════════════════════════════════════

@academic_router.get("/students/{student_id}/advising-plans", response_model=List[AdvisingPlanRead])
def list_student_plans(student_id: int, db: Session = Depends(get_db)):
    return db.query(AdvisingPlan).options(
        joinedload(AdvisingPlan.items).joinedload(AdvisingPlanItem.course),
        joinedload(AdvisingPlan.term),
    ).filter(AdvisingPlan.student_id == student_id).order_by(
        AdvisingPlan.created_at.desc()
    ).all()


@academic_router.post("/advising-plans", response_model=AdvisingPlanRead, status_code=201)
def create_advising_plan(data: AdvisingPlanCreate, db: Session = Depends(get_db)):
    items_data = data.model_dump().pop("items", [])
    plan = AdvisingPlan(**{k: v for k, v in data.model_dump().items() if k != "items"})
    db.add(plan)
    db.flush()

    total_credits = 0
    for item_data in items_data:
        course = db.query(Course).filter(Course.id == item_data["course_id"]).first()
        item = AdvisingPlanItem(plan_id=plan.id, **item_data)
        db.add(item)
        if course:
            total_credits += course.credits

    plan.total_credits = total_credits
    db.commit()
    db.refresh(plan)
    return plan


@academic_router.patch("/advising-plans/{plan_id}/submit", response_model=AdvisingPlanRead)
def submit_plan(plan_id: int, db: Session = Depends(get_db)):
    plan = db.query(AdvisingPlan).filter(AdvisingPlan.id == plan_id).first()
    if not plan:
        raise HTTPException(status_code=404, detail="Plan not found")
    if plan.status != "draft":
        raise HTTPException(status_code=400, detail="Only draft plans can be submitted")
    plan.status       = "submitted"
    plan.submitted_at = datetime.utcnow()
    db.commit()
    db.refresh(plan)
    return plan


@academic_router.patch("/advising-plans/{plan_id}/review", response_model=AdvisingPlanRead)
def review_plan(plan_id: int, data: AdvisingPlanReviewRequest, db: Session = Depends(get_db)):
    plan = db.query(AdvisingPlan).filter(AdvisingPlan.id == plan_id).first()
    if not plan:
        raise HTTPException(status_code=404, detail="Plan not found")
    if plan.status != "submitted":
        raise HTTPException(status_code=400, detail="Only submitted plans can be reviewed")

    plan.reviewed_at   = datetime.utcnow()
    plan.advisor_notes = data.advisor_notes

    if data.action == "approve":
        plan.status      = "advisor_approved"
        plan.approved_at = datetime.utcnow()
    elif data.action == "reject":
        plan.status           = "advisor_rejected"
        plan.rejection_reason = data.rejection_reason
    else:
        raise HTTPException(status_code=400, detail="action must be 'approve' or 'reject'")

    db.commit()
    db.refresh(plan)
    return plan


@academic_router.get("/advising-plans/{plan_id}", response_model=AdvisingPlanRead)
def get_plan(plan_id: int, db: Session = Depends(get_db)):
    plan = db.query(AdvisingPlan).options(
        joinedload(AdvisingPlan.items).joinedload(AdvisingPlanItem.course),
        joinedload(AdvisingPlan.term),
    ).filter(AdvisingPlan.id == plan_id).first()
    if not plan:
        raise HTTPException(status_code=404, detail="Plan not found")
    return plan


# ═════════════════════════════════════════════════════════════════════════════
# IMPORT JOBS
# ═════════════════════════════════════════════════════════════════════════════

@academic_router.get("/import-jobs", response_model=List[ImportJobRead])
def list_import_jobs(db: Session = Depends(get_db)):
    return db.query(ImportJob).order_by(ImportJob.created_at.desc()).limit(50).all()
