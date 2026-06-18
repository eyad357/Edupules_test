"""
EduGuard AI — Sprint 2: Advising Plan Engine & Academic Analytics Service
These two services are separate concerns bundled in one file for delivery.

AdvisingPlanService  — course recommendation, plan approval workflow
AcademicAnalyticsService — student-level and program-level analytics
"""

from __future__ import annotations

import logging
from datetime import datetime
from typing import List, Dict, Any, Optional, Tuple

from sqlalchemy.orm import Session
from sqlalchemy import func, case

from app.models.models import Course, Student, User
from app.models.academic_models import (
    AcademicTerm, AcademicProgram, AcademicTrack,
    StudentCourseAttempt, CoursePrerequisite,
    AdvisingSession, StudyPlan, StudyPlanCourse,
)
from app.models.sprint2_models import (
    ElectivePool, ElectivePoolCourse,
    GraduationAuditResult, AcademicDecisionLog,
    NotificationTemplate,
)
from app.services.sprint2_services import (
    CGPAService, PrerequisiteService,
    GraduationAuditService, NotificationService,
    AcademicDecisionLogService,
)

logger = logging.getLogger(__name__)


# ═════════════════════════════════════════════════════════════════════════════
# ADVISING PLAN ENGINE
# Builds recommended course plans, validates them, tracks approval workflow.
# Future: feeds recommendation engine (architecture already foundation-ready).
# ═════════════════════════════════════════════════════════════════════════════

class AdvisingPlanService:

    # NMU SE Track: 8 semesters, 134 CH, prescribed sequence
    # These are the ordered plan semesters — used for recommendation baseline.
    NMU_PLAN_SEQUENCE = {
        1: ["CSE014", "PHY211", "MAT114", "UC1", "UE1", "UC2"],
        2: ["CSE015", "CSE113", "MAT131", "MAT112", "UC3", "UE2"],
        3: ["CSE111", "CSE131", "CSE191", "MAT313", "MAT231", "MAT212"],
        4: ["CSE112", "CSE132", "CSE221", "CSE251", "CSE315", "UC4"],
        5: ["CSE211", "CSE233", "CSE241", "CSE261", "AIE111", "UC5"],
        6: ["CSE212", "CSE292", "CSE323", "CSE352", "AIE121", "UC6", "UE3"],
        7: ["CSE454", "CSE475", "CSE493", "CSE313", "E1_ELECTIVE", "UC7"],
        8: ["CSE363", "CSE494", "AIE323", "CSE312", "E2_ELECTIVE", "E3_ELECTIVE"],
    }

    @staticmethod
    def recommend_next_semester(
        db:         Session,
        student_id: int,
        term_id:    int,
    ) -> Dict[str, Any]:
        """
        Build a recommended course list for the student's next semester.
        Strategy:
          1. Find which plan semester the student is on.
          2. Filter to only courses they haven't passed and are eligible for.
          3. Include courses from their current plan semester first.
          4. Fill remaining slots with eligible prerequisite-clear courses from
             future semesters (for students on accelerated paths).
        Returns a list of recommended courses with explanation for each.
        """
        student = db.query(Student).filter(Student.id == student_id).first()
        if not student:
            raise ValueError(f"Student {student_id} not found")

        # Courses passed so far
        passed_ids = {
            a.course_id for a in
            db.query(StudentCourseAttempt)
            .filter(StudentCourseAttempt.student_id == student_id,
                    StudentCourseAttempt.result == "passed")
            .all()
        }

        # Determine current plan semester (the lowest plan_semester with unpassed courses)
        all_plan_courses = (
            db.query(Course)
            .filter(
                Course.program_id == student.program_id,
                Course.is_active  == True,
                Course.category.in_(["core", "field_training"]),
            )
            .order_by(Course.plan_semester)
            .all()
        )

        semesters_with_pending = sorted(set(
            c.plan_semester for c in all_plan_courses
            if c.id not in passed_ids and c.plan_semester is not None
        ))
        current_plan_sem = semesters_with_pending[0] if semesters_with_pending else 8

        # Get eligible courses using prerequisite engine
        eligible_results = PrerequisiteService.get_eligible_courses(db, student_id, term_id)
        eligible_map = {r["course_code"]: r for r in eligible_results if r["is_eligible"]}

        recommendations = []
        seen_codes = set()

        # Priority 1: Current plan semester courses
        target_sem_codes = AdvisingPlanService.NMU_PLAN_SEQUENCE.get(current_plan_sem, [])
        for code in target_sem_codes:
            if code.endswith("_ELECTIVE"):
                # Recommend from elective pool
                pool_recs = AdvisingPlanService._recommend_electives(
                    db, student_id, student.program_id, passed_ids, eligible_map
                )
                for rec in pool_recs[:1]:  # one elective per pass
                    if rec["course_code"] not in seen_codes:
                        recommendations.append(rec)
                        seen_codes.add(rec["course_code"])
                continue

            if code not in seen_codes and code in eligible_map:
                c_data = eligible_map[code]
                recommendations.append({
                    "course_id":     c_data["course_id"],
                    "course_code":   code,
                    "course_name":   c_data["course_name"],
                    "credits":       c_data["credits"],
                    "category":      c_data["category"],
                    "plan_semester": c_data["plan_semester"],
                    "priority":      "required",
                    "reason":        f"Prescribed for Semester {current_plan_sem} of NMU SE Track study plan.",
                    "rule_triggered": "PLAN_SEQUENCE",
                })
                seen_codes.add(code)

        # Priority 2: Failed courses from previous semesters (remediation)
        failed_courses = (
            db.query(StudentCourseAttempt)
            .join(Course, Course.id == StudentCourseAttempt.course_id)
            .filter(
                StudentCourseAttempt.student_id == student_id,
                StudentCourseAttempt.result     == "failed",
            )
            .all()
        )
        for attempt in failed_courses:
            c = db.query(Course).filter(Course.id == attempt.course_id).first()
            if c and c.code not in seen_codes and c.code in eligible_map:
                recommendations.append({
                    "course_id":     c.id,
                    "course_code":   c.code,
                    "course_name":   c.name,
                    "credits":       c.credits,
                    "category":      c.category,
                    "plan_semester": c.plan_semester,
                    "priority":      "remediation",
                    "reason":        f"Previously failed. Retake recommended to improve CGPA.",
                    "rule_triggered": "REMEDIATION",
                })
                seen_codes.add(c.code)

        return {
            "student_id":        student_id,
            "term_id":           term_id,
            "current_plan_sem":  current_plan_sem,
            "recommended_count": len(recommendations),
            "total_recommended_ch": sum(r.get("credits", 3) for r in recommendations),
            "recommendations":   recommendations,
            "generated_at":      datetime.utcnow().isoformat(),
        }

    @staticmethod
    def _recommend_electives(
        db:         Session,
        student_id: int,
        program_id: int,
        passed_ids: set,
        eligible_map: dict,
    ) -> List[dict]:
        """Recommend elective courses from the E1/E2/E3 pool."""
        pool = db.query(ElectivePool).filter(ElectivePool.program_id == program_id).first()
        if not pool:
            return []

        pool_course_ids = {
            epc.course_id for epc in
            db.query(ElectivePoolCourse).filter(ElectivePoolCourse.pool_id == pool.id).all()
        }
        already_taken = passed_ids & pool_course_ids
        remaining_needed = pool.required_selections - len(already_taken)
        if remaining_needed <= 0:
            return []

        recs = []
        for pool_cid in pool_course_ids - already_taken:
            c = db.query(Course).filter(Course.id == pool_cid).first()
            if c and c.code in eligible_map:
                recs.append({
                    "course_id":     c.id,
                    "course_code":   c.code,
                    "course_name":   c.name,
                    "credits":       c.credits,
                    "category":      "elective",
                    "plan_semester": c.plan_semester,
                    "priority":      "elective",
                    "reason":        f"Elective from NMU SE Track pool (E1/E2/E3). {remaining_needed} selection(s) still required.",
                    "rule_triggered": "ELECTIVE_POOL",
                })
        return recs

    @staticmethod
    def validate_study_plan(
        db:         Session,
        plan_id:    int,
        student_id: int,
    ) -> Dict[str, Any]:
        """
        Validate a submitted study plan against NMU rules.
        Checks: prerequisite eligibility, credit load, duplicate entries.
        Returns validation result with per-course status.
        """
        plan = db.query(StudyPlan).filter(
            StudyPlan.id         == plan_id,
            StudyPlan.student_id == student_id,
        ).first()
        if not plan:
            raise ValueError(f"Study plan {plan_id} not found for student {student_id}")

        plan_courses = (
            db.query(StudyPlanCourse)
            .filter(StudyPlanCourse.plan_id == plan_id)
            .all()
        )

        validation_results = []
        total_ch      = 0
        all_valid     = True
        seen_course_ids: set = set()

        for pc in plan_courses:
            course = db.query(Course).filter(Course.id == pc.course_id).first()
            if not course:
                validation_results.append({
                    "course_id": pc.course_id,
                    "valid":     False,
                    "issues":    ["Course not found in catalog"],
                })
                all_valid = False
                continue

            issues = []

            # Duplicate check
            if pc.course_id in seen_course_ids:
                issues.append("Duplicate course in plan")
                all_valid = False
            seen_course_ids.add(pc.course_id)

            # Prerequisite check
            prereq_result = PrerequisiteService.check_eligibility(
                db, student_id, pc.course_id, plan.term_id
            )
            if not prereq_result["eligible"]:
                issues.append(
                    f"Prerequisites not met: {', '.join(prereq_result['missing_prereqs'])}"
                )
                all_valid = False

            total_ch += course.credits or 0
            validation_results.append({
                "course_id":     course.id,
                "course_code":   course.code,
                "course_name":   course.name,
                "credits":       course.credits,
                "valid":         len(issues) == 0,
                "issues":        issues,
                "prereq_check":  prereq_result,
            })

        result = {
            "plan_id":            plan_id,
            "student_id":         student_id,
            "is_valid":           all_valid,
            "total_ch":           total_ch,
            "course_count":       len(plan_courses),
            "validation_results": validation_results,
            "validated_at":       datetime.utcnow().isoformat(),
        }

        # Log decision
        AcademicDecisionLogService.log(
            db,
            decision_type   = "plan_validation",
            student_id      = student_id,
            outcome         = all_valid,
            decision_reason = "Plan valid — all prerequisites met." if all_valid
                              else f"Plan invalid — {sum(1 for r in validation_results if not r['valid'])} course(s) with issues.",
            rule_triggered  = "STUDY_PLAN_VALIDATION",
            input_snapshot  = {"plan_id": plan_id, "course_count": len(plan_courses)},
            output_snapshot = {"is_valid": all_valid, "total_ch": total_ch},
        )
        return result


# ═════════════════════════════════════════════════════════════════════════════
# ACADEMIC ANALYTICS SERVICE
# Provides student-level and program-level KPIs.
# Architecture is reporting-foundation-ready — all queries are view-ready.
# ═════════════════════════════════════════════════════════════════════════════

class AcademicAnalyticsService:

    # NMU CGPA thresholds
    AT_RISK_CGPA_THRESHOLD   = 2.00   # Below this → at risk
    PROBATION_THRESHOLD      = 1.70
    SUSPENSION_THRESHOLD     = 1.00

    @staticmethod
    def get_student_analytics(db: Session, student_id: int) -> Dict[str, Any]:
        """
        Full academic analytics snapshot for a single student.
        Used by advisor dashboard and student progress view.
        """
        student = db.query(Student).filter(Student.id == student_id).first()
        if not student:
            raise ValueError(f"Student {student_id} not found")

        user = db.query(User).filter(User.id == student.user_id).first()

        # All attempts for this student
        attempts = (
            db.query(StudentCourseAttempt)
            .filter(StudentCourseAttempt.student_id == student_id)
            .all()
        )

        total_attempts    = len(attempts)
        passed_attempts   = [a for a in attempts if a.result == "passed"]
        failed_attempts   = [a for a in attempts if a.result == "failed"]
        retake_attempts   = [a for a in attempts if a.is_improvement_attempt]

        unique_passed_ids = {a.course_id for a in passed_attempts}
        unique_failed_ids = {a.course_id for a in failed_attempts} - unique_passed_ids

        # Grade distribution
        grade_dist: Dict[str, int] = {}
        for a in attempts:
            if a.letter_grade:
                grade_dist[a.letter_grade] = grade_dist.get(a.letter_grade, 0) + 1

        # Per-semester GPA trend
        sem_gpas = (
            db.query(
                StudentCourseAttempt.term_id,
                func.sum(StudentCourseAttempt.credit_hours * StudentCourseAttempt.grade_points)
                    .label("weighted_sum"),
                func.sum(StudentCourseAttempt.credit_hours).label("total_ch"),
            )
            .filter(
                StudentCourseAttempt.student_id     == student_id,
                StudentCourseAttempt.counts_in_cgpa == True,
                StudentCourseAttempt.result.notin_(["in_progress", "withdrawn"]),
            )
            .group_by(StudentCourseAttempt.term_id)
            .all()
        )

        gpa_trend = []
        for row in sem_gpas:
            term = db.query(AcademicTerm).filter(AcademicTerm.id == row.term_id).first()
            if term:
                sem_gpa = round(float(row.weighted_sum or 0) / float(row.total_ch or 1), 3)
                gpa_trend.append({
                    "term_id":       row.term_id,
                    "term_code":     term.code,
                    "academic_year": term.academic_year,
                    "term_type":     term.term_type,
                    "semester_gpa":  sem_gpa,
                    "ch_attempted":  int(row.total_ch or 0),
                })

        # Progress toward graduation
        ch_earned   = student.total_credit_hours_earned or 0
        ch_required = 134
        pct_complete = round((ch_earned / ch_required) * 100, 1)

        # Estimate remaining semesters (rough: ~17 CH/sem average from NMU plan)
        ch_remaining      = max(0, ch_required - ch_earned)
        avg_ch_per_sem    = 17
        estimated_sems    = round(ch_remaining / avg_ch_per_sem, 1) if ch_remaining > 0 else 0

        is_at_risk = float(student.cgpa or 0) < AcademicAnalyticsService.AT_RISK_CGPA_THRESHOLD

        return {
            "student_id":           student_id,
            "student_name":         user.name if user else "Unknown",
            "student_number":       student.student_number,
            "cgpa":                 float(student.cgpa or 0),
            "academic_standing":    student.academic_standing or "good",
            "is_at_risk":           is_at_risk,
            "is_eligible_for_grad": student.is_eligible_for_graduation or False,
            # Credit progress
            "ch_earned":            ch_earned,
            "ch_required":          ch_required,
            "ch_remaining":         ch_remaining,
            "pct_complete":         pct_complete,
            "estimated_sems_remaining": estimated_sems,
            # Attempt stats
            "total_attempts":       total_attempts,
            "unique_courses_passed": len(unique_passed_ids),
            "unique_courses_failed": len(unique_failed_ids),
            "retake_count":         len(retake_attempts),
            "pass_rate_pct":        round(
                (len(passed_attempts) / total_attempts * 100) if total_attempts > 0 else 0, 1
            ),
            # Grade distribution
            "grade_distribution":   grade_dist,
            # GPA trend per semester
            "gpa_trend":            sorted(gpa_trend, key=lambda x: (x["academic_year"], x["term_type"])),
            "computed_at":          datetime.utcnow().isoformat(),
        }

    @staticmethod
    def get_program_analytics(db: Session, program_id: int) -> Dict[str, Any]:
        """
        Program-level academic analytics.
        Returns KPIs suitable for department coordinator / dean dashboards.
        """
        students = db.query(Student).filter(Student.program_id == program_id).all()
        if not students:
            return {"program_id": program_id, "total_students": 0}

        cgpas    = [float(s.cgpa or 0) for s in students]
        ch_list  = [s.total_credit_hours_earned or 0 for s in students]

        at_risk_count    = sum(1 for c in cgpas if c < AcademicAnalyticsService.AT_RISK_CGPA_THRESHOLD)
        probation_count  = sum(1 for c in cgpas if c < AcademicAnalyticsService.PROBATION_THRESHOLD)
        suspension_count = sum(1 for c in cgpas if c < AcademicAnalyticsService.SUSPENSION_THRESHOLD)
        eligible_count   = sum(1 for s in students if s.is_eligible_for_graduation)

        # Standing distribution
        standing_dist = {}
        for s in students:
            st = s.academic_standing or "good"
            standing_dist[st] = standing_dist.get(st, 0) + 1

        # Grade distribution across all attempts
        all_attempts = (
            db.query(StudentCourseAttempt.letter_grade,
                     func.count().label("cnt"))
            .join(Student, Student.id == StudentCourseAttempt.student_id)
            .filter(
                Student.program_id == program_id,
                StudentCourseAttempt.letter_grade != None,
            )
            .group_by(StudentCourseAttempt.letter_grade)
            .all()
        )
        grade_dist = {row.letter_grade: row.cnt for row in all_attempts}

        avg_cgpa = round(sum(cgpas) / len(cgpas), 3) if cgpas else 0.0
        avg_ch   = round(sum(ch_list) / len(ch_list), 1) if ch_list else 0.0

        return {
            "program_id":         program_id,
            "total_students":     len(students),
            "avg_cgpa":           avg_cgpa,
            "max_cgpa":           round(max(cgpas), 3) if cgpas else 0,
            "min_cgpa":           round(min(cgpas), 3) if cgpas else 0,
            "avg_ch_earned":      avg_ch,
            "at_risk_count":      at_risk_count,
            "at_risk_pct":        round(at_risk_count / len(students) * 100, 1),
            "probation_count":    probation_count,
            "suspension_count":   suspension_count,
            "eligible_for_grad":  eligible_count,
            "graduation_rate_pct": round(eligible_count / len(students) * 100, 1),
            "standing_distribution": standing_dist,
            "grade_distribution": grade_dist,
            "cgpa_buckets": {
                "4.0 - 3.5":    sum(1 for c in cgpas if c >= 3.5),
                "3.5 - 3.0":    sum(1 for c in cgpas if 3.0 <= c < 3.5),
                "3.0 - 2.5":    sum(1 for c in cgpas if 2.5 <= c < 3.0),
                "2.5 - 2.0":    sum(1 for c in cgpas if 2.0 <= c < 2.5),
                "2.0 - 1.5":    sum(1 for c in cgpas if 1.5 <= c < 2.0),
                "below 1.5":    sum(1 for c in cgpas if c < 1.5),
            },
            "computed_at": datetime.utcnow().isoformat(),
        }

    @staticmethod
    def get_course_analytics(db: Session, course_id: int) -> Dict[str, Any]:
        """
        Course-level analytics: pass rates, grade distribution, retake frequency.
        Useful for academic quality monitoring.
        """
        course = db.query(Course).filter(Course.id == course_id).first()
        if not course:
            raise ValueError(f"Course {course_id} not found")

        attempts = (
            db.query(StudentCourseAttempt)
            .filter(StudentCourseAttempt.course_id == course_id)
            .all()
        )

        if not attempts:
            return {
                "course_id":   course_id,
                "course_code": course.code,
                "course_name": course.name,
                "total_attempts": 0,
            }

        total      = len(attempts)
        passed     = sum(1 for a in attempts if a.result == "passed")
        failed     = sum(1 for a in attempts if a.result == "failed")
        retakes    = sum(1 for a in attempts if a.is_improvement_attempt)
        avg_grade  = sum(float(a.grade_points or 0) for a in attempts) / total

        grade_dist = {}
        for a in attempts:
            if a.letter_grade:
                grade_dist[a.letter_grade] = grade_dist.get(a.letter_grade, 0) + 1

        # Term-by-term pass rate
        term_trend: Dict[int, Dict[str, int]] = {}
        for a in attempts:
            if a.term_id not in term_trend:
                term_trend[a.term_id] = {"passed": 0, "failed": 0, "total": 0}
            term_trend[a.term_id]["total"] += 1
            if a.result == "passed":
                term_trend[a.term_id]["passed"] += 1
            elif a.result == "failed":
                term_trend[a.term_id]["failed"] += 1

        term_pass_rates = []
        for term_id, data in term_trend.items():
            term = db.query(AcademicTerm).filter(AcademicTerm.id == term_id).first()
            pr   = round(data["passed"] / data["total"] * 100, 1) if data["total"] > 0 else 0
            term_pass_rates.append({
                "term_id":        term_id,
                "term_code":      term.code if term else str(term_id),
                "academic_year":  term.academic_year if term else None,
                "total":          data["total"],
                "passed":         data["passed"],
                "failed":         data["failed"],
                "pass_rate_pct":  pr,
            })

        return {
            "course_id":            course_id,
            "course_code":          course.code,
            "course_name":          course.name,
            "credits":              course.credits,
            "plan_semester":        course.plan_semester,
            "total_attempts":       total,
            "total_passed":         passed,
            "total_failed":         failed,
            "total_retakes":        retakes,
            "overall_pass_rate_pct": round(passed / total * 100, 1) if total > 0 else 0,
            "avg_grade_points":     round(avg_grade, 2),
            "grade_distribution":   grade_dist,
            "term_trend":           sorted(term_pass_rates,
                                         key=lambda x: (x.get("academic_year") or 0, x["term_code"])),
            "computed_at":          datetime.utcnow().isoformat(),
        }

    @staticmethod
    def get_at_risk_students(
        db:         Session,
        program_id: Optional[int] = None,
        cgpa_below: float = 2.00,
    ) -> List[Dict[str, Any]]:
        """
        Return students below the academic risk CGPA threshold.
        Primary use: advisor alert dashboard, intervention assignment.
        """
        q = db.query(Student).filter(
            Student.cgpa < cgpa_below,
        )
        if program_id:
            q = q.filter(Student.program_id == program_id)

        at_risk = q.order_by(Student.cgpa).all()
        results = []
        for s in at_risk:
            user = db.query(User).filter(User.id == s.user_id).first()
            results.append({
                "student_id":        s.id,
                "student_name":      user.name if user else "Unknown",
                "student_number":    s.student_number,
                "cgpa":              float(s.cgpa or 0),
                "academic_standing": s.academic_standing or "good",
                "ch_earned":         s.total_credit_hours_earned or 0,
                "risk_level": (
                    "critical" if float(s.cgpa or 0) < 1.00 else
                    "high"     if float(s.cgpa or 0) < 1.70 else
                    "medium"
                ),
            })
        return results
