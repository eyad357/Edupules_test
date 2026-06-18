"""
EduGuard AI — Sprint 2: Analytics & Advising Router
Mount in main.py alongside sprint2_router:
    from app.routers.sprint2_analytics_router import analytics_router
    app.include_router(analytics_router, prefix="/api/v2", tags=["Sprint 2 Analytics"])
"""

from __future__ import annotations

from datetime import datetime
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.models.models import Course, Student, User
from app.models.academic_models import AcademicTerm
from app.services.sprint2_analytics import (
    AdvisingPlanService,
    AcademicAnalyticsService,
)
from app.services.sprint2_services import NotificationService

analytics_router = APIRouter()


# ═════════════════════════════════════════════════════════════════════════════
# ADVISING PLAN ENGINE
# ═════════════════════════════════════════════════════════════════════════════

@analytics_router.get("/students/{student_id}/course-recommendations")
def get_course_recommendations(
    student_id: int,
    term_id:    int = Query(..., description="Target term for recommendations"),
    db: Session = Depends(get_db),
):
    """
    Generate a recommended course list for a student's next semester.
    Based on NMU SE Track study plan sequence + prerequisite eligibility.
    Each recommendation includes a plain-language explanation.
    """
    try:
        result = AdvisingPlanService.recommend_next_semester(db, student_id, term_id)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    return result


@analytics_router.post("/study-plans/{plan_id}/validate")
def validate_study_plan(
    plan_id:    int,
    student_id: int = Query(...),
    db: Session = Depends(get_db),
):
    """
    Validate a submitted study plan against NMU academic rules.
    Checks: prerequisite eligibility, duplicates, credit load.
    Returns per-course validation status with explanations.
    """
    try:
        result = AdvisingPlanService.validate_study_plan(db, plan_id, student_id)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    return result


# ═════════════════════════════════════════════════════════════════════════════
# STUDENT ANALYTICS
# ═════════════════════════════════════════════════════════════════════════════

@analytics_router.get("/students/{student_id}/analytics")
def get_student_analytics(student_id: int, db: Session = Depends(get_db)):
    """
    Full academic analytics snapshot for a student.
    Includes: CGPA, standing, credit progress, grade distribution,
    semester GPA trend, pass rate, retake count, graduation estimate.
    """
    try:
        return AcademicAnalyticsService.get_student_analytics(db, student_id)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))


@analytics_router.get("/programs/{program_id}/analytics")
def get_program_analytics(program_id: int, db: Session = Depends(get_db)):
    """
    Program-level academic KPIs.
    Includes: avg CGPA, at-risk count, standing distribution,
    graduation rate, CGPA bucket breakdown, grade distribution.
    """
    return AcademicAnalyticsService.get_program_analytics(db, program_id)


@analytics_router.get("/courses/{course_id}/analytics")
def get_course_analytics(course_id: int, db: Session = Depends(get_db)):
    """
    Course-level analytics: pass rates, grade distribution, retake frequency,
    per-term trend. Useful for academic quality monitoring.
    """
    try:
        return AcademicAnalyticsService.get_course_analytics(db, course_id)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))


@analytics_router.get("/programs/{program_id}/at-risk-students")
def get_at_risk_students(
    program_id:  int,
    cgpa_below:  float = Query(2.00, description="CGPA threshold for at-risk"),
    db: Session = Depends(get_db),
):
    """
    Return all students below the CGPA risk threshold.
    Results include risk_level: 'medium' | 'high' | 'critical'.
    Primary use: advisor alert dashboard.
    """
    results = AcademicAnalyticsService.get_at_risk_students(
        db, program_id=program_id, cgpa_below=cgpa_below
    )
    return {
        "program_id":       program_id,
        "cgpa_threshold":   cgpa_below,
        "total_at_risk":    len(results),
        "students":         results,
        "computed_at":      datetime.utcnow().isoformat(),
    }


@analytics_router.post("/programs/{program_id}/notify-at-risk")
def notify_at_risk_students(program_id: int, db: Session = Depends(get_db)):
    """
    Send 'academic_risk' notification to all at-risk students in a program.
    Uses the notification template engine — no hardcoded messages.
    """
    at_risk = AcademicAnalyticsService.get_at_risk_students(
        db, program_id=program_id, cgpa_below=2.00
    )
    sent_count = 0
    for s in at_risk:
        nid = NotificationService.send_academic_notification(
            db,
            event_type = "academic_risk",
            student_id = s["student_id"],
            context    = {
                "student_name":   s["student_name"],
                "cgpa":           s["cgpa"],
                "academic_standing": s["academic_standing"],
            },
        )
        if nid:
            sent_count += 1

    return {
        "program_id":    program_id,
        "at_risk_count": len(at_risk),
        "notifications_sent": sent_count,
        "sent_at":       datetime.utcnow().isoformat(),
    }


# ═════════════════════════════════════════════════════════════════════════════
# REPORTING FOUNDATION
# ═════════════════════════════════════════════════════════════════════════════

@analytics_router.get("/reports/program-summary/{program_id}")
def program_summary_report(program_id: int, db: Session = Depends(get_db)):
    """
    Institutional report: program-wide academic summary.
    Suitable for export to dean / department coordinator dashboards.
    All data is live — no caching or hardcoded values.
    """
    analytics   = AcademicAnalyticsService.get_program_analytics(db, program_id)
    at_risk     = AcademicAnalyticsService.get_at_risk_students(db, program_id)

    from app.models.models import Student
    students = db.query(Student).filter(Student.program_id == program_id).all()
    eligible = [s for s in students if s.is_eligible_for_graduation]

    return {
        "report_type":        "program_summary",
        "program_id":         program_id,
        "generated_at":       datetime.utcnow().isoformat(),
        "summary":            analytics,
        "at_risk_students":   at_risk[:20],  # top 20 most at-risk
        "graduation_eligible": len(eligible),
        "note": (
            "This report is derived from live academic data. "
            "All CGPA values use the NMU formula: SUM(credits×grade_points)/SUM(credits). "
            "Source: NMU CS SE Track official curriculum."
        ),
    }


@analytics_router.get("/reports/graduation-pipeline/{program_id}")
def graduation_pipeline_report(program_id: int, db: Session = Depends(get_db)):
    """
    Graduation pipeline: shows each student's progress toward 134 CH.
    Grouped by how many semesters they likely have remaining.
    """
    from app.models.models import Student

    students = db.query(Student).filter(Student.program_id == program_id).all()
    pipeline = {"finishing_this_year": [], "1_year_away": [],
                "2_years_away": [], "3plus_years": []}

    for s in students:
        user      = db.query(User).filter(User.id == s.user_id).first()
        ch_earned = s.total_credit_hours_earned or 0
        ch_left   = max(0, 134 - ch_earned)
        avg_sem   = 17
        sems_left = round(ch_left / avg_sem, 0) if ch_left > 0 else 0

        entry = {
            "student_id":   s.id,
            "student_name": user.name if user else "Unknown",
            "cgpa":         float(s.cgpa or 0),
            "ch_earned":    ch_earned,
            "ch_remaining": ch_left,
            "sems_remaining": sems_left,
            "is_eligible":  s.is_eligible_for_graduation or False,
        }

        if sems_left <= 2:
            pipeline["finishing_this_year"].append(entry)
        elif sems_left <= 4:
            pipeline["1_year_away"].append(entry)
        elif sems_left <= 6:
            pipeline["2_years_away"].append(entry)
        else:
            pipeline["3plus_years"].append(entry)

    return {
        "program_id":   program_id,
        "total":        len(students),
        "pipeline":     pipeline,
        "generated_at": datetime.utcnow().isoformat(),
    }
