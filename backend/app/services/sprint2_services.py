"""
EduGuard AI — Sprint 2: Academic Rules Services
Business logic layer. All NMU-specific rules are implemented here.
Services are pure functions — no FastAPI dependencies, fully testable.

CRITICAL: All academic rules derived exclusively from NMU official documents:
  - Grade scale: CGPA_Calculator.xlsx
  - Prerequisites: Courses_Pre-requisites PDF
  - Graduation: Track_Courses_List PDF (134 CH, 8 semesters)
  - CGPA formula: SUM(credits × grade_points) / SUM(credits), ALL attempts
"""

from __future__ import annotations

import logging
from datetime import datetime
from typing import List, Optional, Dict, Any, Tuple

from sqlalchemy import text, func
from sqlalchemy.orm import Session

from app.models.models import Course, Student, User, Enrollment
from app.models.academic_models import (
    AcademicTerm, AcademicProgram, CoursePrerequisite,
    StudentCourseAttempt, GradeScale, StudentTermGPA,
    GraduationRequirement, StudentGraduationProgress,
)
from app.models.sprint2_models import (
    ElectivePool, ElectivePoolCourse, StudentElectiveSelection,
    PrerequisiteException, PrerequisiteValidationLog,
    GraduationAuditResult, AcademicCalendarPeriod,
    AcademicOverride, AcademicOverrideHistory,
    NotificationTemplate, NotificationDeliveryLog,
    AcademicDecisionLog, RbacPermission,
)

logger = logging.getLogger(__name__)


# ═════════════════════════════════════════════════════════════════════════════
# CGPA ENGINE SERVICE
# NMU formula (source: CGPA_Calculator.xlsx):
#   CGPA = SUM(credit_hours × grade_points) / SUM(credit_hours)
#   - ALL attempts included (retakes do NOT replace prior attempts)
#   - F (0.0) included   — penalizes CGPA
#   - FL (0.0) included  — penalizes CGPA
#   - P (non-credit, 0 CH) excluded via counts_in_cgpa=FALSE
# ═════════════════════════════════════════════════════════════════════════════

class CGPAService:

    @staticmethod
    def compute_cgpa(db: Session, student_id: int) -> Dict[str, Any]:
        """
        Compute NMU CGPA for a student from student_course_attempts.
        Returns dict with cgpa, hours_attempted, hours_earned, quality_points.
        """
        rows = (
            db.query(
                StudentCourseAttempt.credit_hours,
                StudentCourseAttempt.grade_points,
                StudentCourseAttempt.result,
                StudentCourseAttempt.counts_in_cgpa,
            )
            .filter(
                StudentCourseAttempt.student_id  == student_id,
                StudentCourseAttempt.counts_in_cgpa == True,
                StudentCourseAttempt.result.notin_(["in_progress", "withdrawn"]),
            )
            .all()
        )

        total_weighted = 0.0
        total_credits  = 0
        earned_credits = 0

        for row in rows:
            ch  = row.credit_hours or 0
            gp  = float(row.grade_points or 0)
            total_weighted += ch * gp
            total_credits  += ch
            if row.result == "passed":
                earned_credits += ch

        cgpa = round(total_weighted / total_credits, 3) if total_credits > 0 else 0.0
        cgpa = min(4.0, max(0.0, cgpa))

        return {
            "cgpa":                          cgpa,
            "total_credit_hours_attempted":  total_credits,
            "total_credit_hours_earned":     earned_credits,
            "total_quality_points":          round(total_weighted, 3),
            "academic_standing":             CGPAService.determine_standing(cgpa),
        }

    @staticmethod
    def determine_standing(cgpa: float) -> str:
        """
        NMU academic standing thresholds.
        No external policy assumed — derived from standard NMU 4.0 scale usage.
        """
        if cgpa >= 2.00:
            return "good"
        elif cgpa >= 1.70:
            return "warning"
        elif cgpa >= 1.00:
            return "probation"
        else:
            return "suspension"

    @staticmethod
    def sync_student_cgpa(db: Session, student_id: int) -> Tuple[float, float]:
        """
        Recompute and persist CGPA for a student.
        Returns (old_cgpa, new_cgpa).
        """
        student = db.query(Student).filter(Student.id == student_id).first()
        if not student:
            raise ValueError(f"Student {student_id} not found")

        old_cgpa = float(student.cgpa or 0)
        result   = CGPAService.compute_cgpa(db, student_id)

        student.cgpa                         = result["cgpa"]
        student.total_credit_hours_attempted = result["total_credit_hours_attempted"]
        student.total_credit_hours_earned    = result["total_credit_hours_earned"]
        student.total_quality_points         = result["total_quality_points"]
        student.academic_standing            = result["academic_standing"]
        # Sync legacy gpa field for backward compat with monitoring system
        student.gpa = round(min(4.0, max(0.0, result["cgpa"])), 2)
        db.commit()

        logger.info(
            "CGPA synced for student %s: %.3f → %.3f (standing: %s)",
            student_id, old_cgpa, result["cgpa"], result["academic_standing"]
        )
        return old_cgpa, result["cgpa"]

    @staticmethod
    def compute_term_gpa(db: Session, student_id: int, term_id: int) -> Dict[str, Any]:
        """
        Compute Semester GPA for a specific term.
        Uses same formula but restricted to attempts within term_id.
        """
        rows = (
            db.query(
                StudentCourseAttempt.credit_hours,
                StudentCourseAttempt.grade_points,
                StudentCourseAttempt.result,
            )
            .filter(
                StudentCourseAttempt.student_id    == student_id,
                StudentCourseAttempt.term_id       == term_id,
                StudentCourseAttempt.counts_in_cgpa == True,
                StudentCourseAttempt.result.notin_(["in_progress", "withdrawn"]),
            )
            .all()
        )

        weighted = sum((r.credit_hours or 0) * float(r.grade_points or 0) for r in rows)
        credits  = sum(r.credit_hours or 0 for r in rows)
        earned   = sum(r.credit_hours or 0 for r in rows if r.result == "passed")
        term_gpa = round(weighted / credits, 3) if credits > 0 else 0.0

        return {
            "term_gpa":                     term_gpa,
            "term_credit_hours_attempted":  credits,
            "term_credit_hours_earned":     earned,
            "term_quality_points":          round(weighted, 3),
        }

    @staticmethod
    def get_grade_points(db: Session, letter_grade: str, program_id: Optional[int] = None) -> float:
        """Look up grade points for a letter grade from the NMU grade scale table."""
        q = db.query(GradeScale).filter(GradeScale.letter_grade == letter_grade)
        if program_id:
            q = q.filter(GradeScale.program_id == program_id)
        entry = q.first()
        if not entry:
            logger.warning("Grade symbol '%s' not found in grade_scale — defaulting to 0.0", letter_grade)
            return 0.0
        return float(entry.grade_points)

    @staticmethod
    def is_passing_grade(db: Session, letter_grade: str, program_id: Optional[int] = None) -> bool:
        """Check if a letter grade is passing per NMU grade scale."""
        q = db.query(GradeScale).filter(GradeScale.letter_grade == letter_grade)
        if program_id:
            q = q.filter(GradeScale.program_id == program_id)
        entry = q.first()
        return bool(entry.is_passing) if entry else False


# ═════════════════════════════════════════════════════════════════════════════
# PREREQUISITE ENGINE SERVICE
# Source: Courses_Pre-requisites_Core_and_Elective.pdf
# AND logic: all prereqs in same logic_group must be satisfied.
# OR logic: any group being fully satisfied = course is eligible.
# ═════════════════════════════════════════════════════════════════════════════

class PrerequisiteService:

    @staticmethod
    def check_eligibility(
        db: Session,
        student_id: int,
        course_id:  int,
        term_id:    Optional[int] = None,
    ) -> Dict[str, Any]:
        """
        Check if a student meets all prerequisites for a course.
        Returns explainable result dict.
        """
        course = db.query(Course).filter(Course.id == course_id).first()
        if not course:
            return {
                "eligible": False, "missing_prereqs": [], "rule_triggered": "COURSE_NOT_FOUND",
                "explanation": "Course not found", "reasons": ["Course not found"],
                "waiver_applied": False,
            }

        # Build set of courses this student has passed (best result across all attempts)
        passed_ids = {
            a.course_id for a in
            db.query(StudentCourseAttempt)
            .filter(
                StudentCourseAttempt.student_id == student_id,
                StudentCourseAttempt.result     == "passed",
            ).all()
        }

        # Get prerequisite edges
        prereq_edges = (
            db.query(CoursePrerequisite)
            .filter(
                CoursePrerequisite.course_id   == course_id,
                CoursePrerequisite.prereq_type == "hard",
            )
            .all()
        )

        # No prerequisites → immediately eligible
        if not prereq_edges:
            result = {
                "eligible": True, "missing_prereqs": [],
                "rule_triggered": "NO_PREREQS",
                "explanation": f"{course.code} has no prerequisites.",
                "reasons": ["No prerequisites required"],
                "waiver_applied": False,
            }
            PrerequisiteService._log(db, student_id, course_id, term_id, result)
            return result

        # Group edges by logic_group
        groups: Dict[int, List[CoursePrerequisite]] = {}
        for edge in prereq_edges:
            gid = edge.logic_group or 1
            groups.setdefault(gid, []).append(edge)

        # At least one group must be fully satisfied (OR between groups)
        all_missing: List[str] = []
        eligible = False

        for gid, edges in groups.items():
            group_missing = []
            for edge in edges:
                prereq_course = db.query(Course).filter(Course.id == edge.prerequisite_id).first()
                if edge.prerequisite_id not in passed_ids:
                    if prereq_course:
                        group_missing.append(prereq_course.code)
            if not group_missing:
                eligible = True
                all_missing = []
                break
            all_missing.extend(group_missing)

        # Check advisor waiver if not eligible
        waiver_applied = False
        if not eligible:
            waiver = (
                db.query(PrerequisiteException)
                .filter(
                    PrerequisiteException.student_id == student_id,
                    PrerequisiteException.course_id  == course_id,
                    PrerequisiteException.is_active  == True,
                )
                .filter(
                    (PrerequisiteException.expires_at == None) |
                    (PrerequisiteException.expires_at > datetime.utcnow())
                )
                .first()
            )
            if waiver:
                eligible      = True
                all_missing   = []
                waiver_applied = True

        reasons = (
            ["All prerequisites satisfied"] if eligible and not waiver_applied
            else ["Advisor waiver applied"] if waiver_applied
            else [f"Missing prerequisites: {', '.join(all_missing)}"]
        )

        result = {
            "eligible":       eligible,
            "missing_prereqs": all_missing,
            "rule_triggered": "PREREQ_SATISFIED" if eligible else "PREREQ_MISSING",
            "explanation": (
                f"{course.code}: all prerequisite groups satisfied."
                if eligible else
                f"{course.code}: missing {', '.join(all_missing)}."
            ),
            "reasons":        reasons,
            "waiver_applied": waiver_applied,
        }

        # Log every check
        PrerequisiteService._log(db, student_id, course_id, term_id, result)
        return result

    @staticmethod
    def _log(db: Session, student_id: int, course_id: int, term_id: Optional[int], result: dict):
        try:
            log = PrerequisiteValidationLog(
                student_id      = student_id,
                course_id       = course_id,
                term_id         = term_id,
                check_result    = result["eligible"],
                missing_prereqs = result.get("missing_prereqs"),
                rule_triggered  = result.get("rule_triggered"),
                explanation     = result.get("explanation"),
                decision_reason = result["reasons"][0] if result.get("reasons") else None,
            )
            db.add(log)
            db.commit()
        except Exception:
            logger.warning("Failed to write prerequisite validation log", exc_info=True)

    @staticmethod
    def get_eligible_courses(
        db: Session, student_id: int, term_id: int
    ) -> List[Dict[str, Any]]:
        """
        Return all courses the student is eligible to register for in term_id.
        Checks: not already passed, all prerequisites met, eligibility rules.
        """
        student = db.query(Student).filter(Student.id == student_id).first()
        if not student:
            return []

        passed_ids     = {
            a.course_id for a in
            db.query(StudentCourseAttempt)
            .filter(StudentCourseAttempt.student_id == student_id, StudentCourseAttempt.result == "passed")
            .all()
        }
        in_progress_ids = {
            a.course_id for a in
            db.query(StudentCourseAttempt)
            .filter(
                StudentCourseAttempt.student_id == student_id,
                StudentCourseAttempt.term_id    == term_id,
                StudentCourseAttempt.result     == "in_progress",
            ).all()
        }

        all_courses = (
            db.query(Course)
            .filter(Course.program_id == student.program_id, Course.is_active == True)
            .all()
        )

        results = []
        for course in all_courses:
            if course.id in passed_ids:
                continue
            if course.id in in_progress_ids:
                continue
            check = PrerequisiteService.check_eligibility(db, student_id, course.id, term_id)
            results.append({
                "course_id":      course.id,
                "course_code":    course.code,
                "course_name":    course.name,
                "credits":        course.credits,
                "plan_semester":  course.plan_semester,
                "category":       course.category,
                "is_eligible":    check["eligible"],
                "missing_prereqs": check["missing_prereqs"],
                "reasons":        check["reasons"],
                "rule_triggered": check["rule_triggered"],
            })

        return results

    @staticmethod
    def get_course_chain(db: Session, course_id: int) -> List[Dict[str, Any]]:
        """Return the full prerequisite chain for a course (recursive)."""
        visited = set()
        chain   = []

        def traverse(cid: int):
            if cid in visited:
                return
            visited.add(cid)
            edges = (
                db.query(CoursePrerequisite)
                .filter(CoursePrerequisite.course_id == cid)
                .all()
            )
            for edge in edges:
                pc = db.query(Course).filter(Course.id == edge.prerequisite_id).first()
                if pc:
                    chain.append({
                        "code":          pc.code,
                        "name":          pc.name,
                        "plan_semester": pc.plan_semester,
                        "prereq_type":   edge.prereq_type,
                        "logic_group":   edge.logic_group or 1,
                        "logic_type":    edge.logic_type or "AND",
                    })
                    traverse(edge.prerequisite_id)

        traverse(course_id)
        return chain

    @staticmethod
    def detect_cycles(db: Session, new_course_id: int, new_prereq_id: int) -> bool:
        """
        DFS cycle detection before inserting a new prerequisite edge.
        Returns True if adding this edge would create a cycle.
        """
        visited = set()

        def has_path(from_id: int, to_id: int) -> bool:
            if from_id == to_id:
                return True
            if from_id in visited:
                return False
            visited.add(from_id)
            successors = [
                e.prerequisite_id for e in
                db.query(CoursePrerequisite)
                .filter(CoursePrerequisite.course_id == from_id)
                .all()
            ]
            return any(has_path(s, to_id) for s in successors)

        # Adding (new_course_id → new_prereq_id): check if new_prereq_id already
        # reaches new_course_id (which would complete a cycle)
        return has_path(new_prereq_id, new_course_id)

    @staticmethod
    def grant_exception(
        db: Session,
        student_id:       int,
        course_id:        int,
        waived_prereq_id: int,
        granted_by:       int,
        reason:           str,
        expires_at:       Optional[datetime] = None,
    ) -> PrerequisiteException:
        exc = PrerequisiteException(
            student_id       = student_id,
            course_id        = course_id,
            waived_prereq_id = waived_prereq_id,
            granted_by       = granted_by,
            reason           = reason,
            expires_at       = expires_at,
            is_active        = True,
        )
        db.add(exc)
        db.commit()
        db.refresh(exc)
        logger.info("Prerequisite exception granted: student=%s course=%s waived=%s by=%s",
                    student_id, course_id, waived_prereq_id, granted_by)
        return exc


# ═════════════════════════════════════════════════════════════════════════════
# GRADUATION AUDIT SERVICE
# NMU SE Track requirements (source: Track_Courses_List PDF):
#   1. 134 total CH
#   2. All core courses passed (D or above)
#   3. CSE191 Field Training 1
#   4. CSE292 Field Training 2
#   5. CSE493 Graduation Project 1
#   6. CSE494 Graduation Project 2
#   7. 3 track electives from E1/E2/E3 pool
# ═════════════════════════════════════════════════════════════════════════════

class GraduationAuditService:

    NMU_REQUIRED_CH    = 134
    NMU_REQUIRED_ELEC  = 3

    @staticmethod
    def run_audit(db: Session, student_id: int, triggered_by: str = "system") -> Dict[str, Any]:
        """
        Run full NMU graduation audit. Stores result. Updates student flag.
        Returns complete audit result dict.
        """
        student = db.query(Student).filter(Student.id == student_id).first()
        if not student:
            raise ValueError(f"Student {student_id} not found")

        user = db.query(User).filter(User.id == student.user_id).first()
        name = user.name if user else "Unknown"

        # Build passed course set
        passed_attempts = (
            db.query(StudentCourseAttempt)
            .filter(StudentCourseAttempt.student_id == student_id, StudentCourseAttempt.result == "passed")
            .all()
        )
        passed_ids   = {a.course_id for a in passed_attempts}
        passed_codes = {
            a.course_id: db.query(Course).filter(Course.id == a.course_id).first().code
            for a in passed_attempts
            if db.query(Course).filter(Course.id == a.course_id).first()
        }

        blocking:   List[str] = []
        completed:  List[str] = []
        missing_courses: List[dict] = []

        # ── CHECK 1: Total credit hours ────────────────────────────────────
        ch_earned = student.total_credit_hours_earned or 0
        if ch_earned < GraduationAuditService.NMU_REQUIRED_CH:
            gap = GraduationAuditService.NMU_REQUIRED_CH - ch_earned
            blocking.append(
                f"Insufficient credit hours: {ch_earned} earned, "
                f"{GraduationAuditService.NMU_REQUIRED_CH} required (gap: {gap} CH)"
            )
        else:
            completed.append(f"✓ {GraduationAuditService.NMU_REQUIRED_CH} credit hours earned")

        # ── CHECK 2: All core courses ─────────────────────────────────────
        core_courses = (
            db.query(Course)
            .filter(
                Course.program_id == student.program_id,
                Course.category   == "core",
                Course.is_active  == True,
            )
            .all()
        )
        core_required  = len(core_courses)
        core_completed = sum(1 for c in core_courses if c.id in passed_ids)

        for c in core_courses:
            if c.id not in passed_ids:
                missing_courses.append({"code": c.code, "name": c.name, "category": "core"})

        if core_completed < core_required:
            blocking.append(
                f"Incomplete core courses: {core_completed}/{core_required} completed"
            )
        else:
            completed.append(f"✓ All {core_required} core courses completed")

        # ── CHECK 3: Field Training 1 (CSE191) ───────────────────────────
        ft1_ids  = {a.course_id for a in passed_attempts}
        ft1_done = any(
            db.query(Course).filter(Course.id == cid).first().code == "CSE191"
            for cid in ft1_ids
            if db.query(Course).filter(Course.id == cid).first()
        )
        if not ft1_done:
            blocking.append("CSE191 (Field Training 1 in CS) not completed")
            missing_courses.append({"code": "CSE191", "name": "Field Training 1 in CS", "category": "field_training"})
        else:
            completed.append("✓ CSE191 Field Training 1 completed")

        # ── CHECK 4: Field Training 2 (CSE292) ───────────────────────────
        ft2_done = any(
            db.query(Course).filter(Course.id == cid).first().code == "CSE292"
            for cid in ft1_ids
            if db.query(Course).filter(Course.id == cid).first()
        )
        if not ft2_done:
            blocking.append("CSE292 (Field Training 2 in CS) not completed")
            missing_courses.append({"code": "CSE292", "name": "Field Training 2 in CS", "category": "field_training"})
        else:
            completed.append("✓ CSE292 Field Training 2 completed")

        # ── CHECK 5: Graduation Project 1 (CSE493) ───────────────────────
        gp1_done = any(
            db.query(Course).filter(Course.id == cid).first().code == "CSE493"
            for cid in passed_ids
            if db.query(Course).filter(Course.id == cid).first()
        )
        if not gp1_done:
            blocking.append("CSE493 (Graduation Project 1) not completed")
            missing_courses.append({"code": "CSE493", "name": "Graduation Project 1", "category": "graduation_project"})
        else:
            completed.append("✓ CSE493 Graduation Project 1 completed")

        # ── CHECK 6: Graduation Project 2 (CSE494) ───────────────────────
        gp2_done = any(
            db.query(Course).filter(Course.id == cid).first().code == "CSE494"
            for cid in passed_ids
            if db.query(Course).filter(Course.id == cid).first()
        )
        if not gp2_done:
            blocking.append("CSE494 (Graduation Project 2) not completed")
            missing_courses.append({"code": "CSE494", "name": "Graduation Project 2", "category": "graduation_project"})
        else:
            completed.append("✓ CSE494 Graduation Project 2 completed")

        # ── CHECK 7: Track electives (3 from pool) ────────────────────────
        pool = db.query(ElectivePool).filter(ElectivePool.program_id == student.program_id).first()
        elec_done = 0
        if pool:
            pool_course_ids = {
                epc.course_id for epc in
                db.query(ElectivePoolCourse).filter(ElectivePoolCourse.pool_id == pool.id).all()
            }
            elec_done = len(passed_ids & pool_course_ids)

        if elec_done < GraduationAuditService.NMU_REQUIRED_ELEC:
            blocking.append(
                f"Track electives: {elec_done}/{GraduationAuditService.NMU_REQUIRED_ELEC} completed"
            )
        else:
            completed.append(f"✓ {elec_done} track electives completed")

        is_eligible = len(blocking) == 0

        # Store audit result
        audit = GraduationAuditResult(
            student_id              = student_id,
            is_eligible             = is_eligible,
            total_ch_earned         = ch_earned,
            core_courses_required   = core_required,
            core_courses_completed  = core_completed,
            electives_completed     = elec_done,
            field_training_done     = ft1_done and ft2_done,
            graduation_project_done = gp1_done and gp2_done,
            cgpa_at_audit           = float(student.cgpa or 0),
            blocking_reasons        = blocking,
            completed_requirements  = completed,
            missing_courses         = missing_courses,
            triggered_by            = triggered_by,
        )
        db.add(audit)

        # Update student flag
        student.is_eligible_for_graduation = is_eligible
        db.commit()
        db.refresh(audit)

        result = {
            "audit_id":               audit.id,
            "student_id":             student_id,
            "student_name":           name,
            "is_eligible":            is_eligible,
            "cgpa":                   float(student.cgpa or 0),
            "credits_earned":         ch_earned,
            "credits_required":       GraduationAuditService.NMU_REQUIRED_CH,
            "credits_remaining":      max(0, GraduationAuditService.NMU_REQUIRED_CH - ch_earned),
            "core_courses_required":  core_required,
            "core_courses_completed": core_completed,
            "electives_required":     GraduationAuditService.NMU_REQUIRED_ELEC,
            "electives_completed":    elec_done,
            "ft1_done":               ft1_done,
            "ft2_done":               ft2_done,
            "gp1_done":               gp1_done,
            "gp2_done":               gp2_done,
            "blocking_reasons":       blocking,
            "completed_requirements": completed,
            "missing_courses":        missing_courses,
            "audited_at":             audit.audited_at,
            "audit_version":          "v2.0",
            "explanation": (
                "Graduation requirements fully satisfied per NMU SE Track study plan."
                if is_eligible else
                f"Graduation blocked: {'; '.join(blocking[:2])}{'...' if len(blocking) > 2 else ''}."
            ),
        }

        # Log decision
        AcademicDecisionLogService.log(
            db,
            decision_type   = "graduation_audit",
            student_id      = student_id,
            outcome         = is_eligible,
            decision_reason = result["explanation"],
            rule_triggered  = "GRADUATION_AUDIT_NMU",
            input_snapshot  = {"cgpa": float(student.cgpa or 0), "ch_earned": ch_earned},
            output_snapshot = {"is_eligible": is_eligible, "blocking_count": len(blocking)},
        )

        return result


# ═════════════════════════════════════════════════════════════════════════════
# ACADEMIC OVERRIDE SERVICE
# ═════════════════════════════════════════════════════════════════════════════

class AcademicOverrideService:

    @staticmethod
    def create_override(
        db:            Session,
        override_type: str,
        student_id:    int,
        requested_by:  int,
        reason:        str,
        course_id:     Optional[int]      = None,
        term_id:       Optional[int]      = None,
        metadata_json: Optional[dict]     = None,
    ) -> AcademicOverride:
        override = AcademicOverride(
            override_type = override_type,
            student_id    = student_id,
            course_id     = course_id,
            term_id       = term_id,
            requested_by  = requested_by,
            reason        = reason,
            metadata_json = metadata_json,
            status        = "pending",
        )
        db.add(override)
        db.flush()

        history = AcademicOverrideHistory(
            override_id  = override.id,
            action       = "created",
            performed_by = requested_by,
            old_status   = None,
            new_status   = "pending",
            notes        = f"Override request created: {override_type}",
        )
        db.add(history)
        db.commit()
        db.refresh(override)
        return override

    @staticmethod
    def decide_override(
        db:             Session,
        override_id:    int,
        reviewed_by:    int,
        action:         str,           # "approve" | "reject"
        decision_reason: str,
        reviewer_notes: Optional[str] = None,
        expires_at:     Optional[datetime] = None,
    ) -> AcademicOverride:
        override = db.query(AcademicOverride).filter(AcademicOverride.id == override_id).first()
        if not override:
            raise ValueError(f"Override {override_id} not found")
        if override.status != "pending":
            raise ValueError(f"Override {override_id} is not pending (status: {override.status})")

        old_status = override.status
        new_status = "approved" if action == "approve" else "rejected"

        override.status          = new_status
        override.reviewed_by     = reviewed_by
        override.reviewed_at     = datetime.utcnow()
        override.decision_reason = decision_reason
        override.reviewer_notes  = reviewer_notes
        override.expires_at      = expires_at
        override.explanation     = f"Override {new_status} by reviewer {reviewed_by}: {decision_reason}"

        history = AcademicOverrideHistory(
            override_id  = override.id,
            action       = action,
            performed_by = reviewed_by,
            old_status   = old_status,
            new_status   = new_status,
            notes        = decision_reason,
        )
        db.add(history)

        # If prereq_waiver approved → create exception record
        if action == "approve" and override.override_type == "prerequisite_waiver" and override.course_id:
            # Find the specific waived prereq from metadata
            prereq_id = (override.metadata_json or {}).get("waived_prereq_id")
            if prereq_id:
                exc = PrerequisiteException(
                    student_id       = override.student_id,
                    course_id        = override.course_id,
                    waived_prereq_id = prereq_id,
                    granted_by       = reviewed_by,
                    reason           = decision_reason,
                    expires_at       = expires_at,
                    is_active        = True,
                )
                db.add(exc)

        db.commit()
        db.refresh(override)
        logger.info("Override %s: %s → %s by %s", override_id, old_status, new_status, reviewed_by)
        return override


# ═════════════════════════════════════════════════════════════════════════════
# ACADEMIC CALENDAR SERVICE
# ═════════════════════════════════════════════════════════════════════════════

class AcademicCalendarService:

    @staticmethod
    def is_period_active(db: Session, term_id: int, period_type: str) -> bool:
        """Check if a calendar period is currently active for a given term."""
        today = datetime.utcnow().date()
        return db.query(AcademicCalendarPeriod).filter(
            AcademicCalendarPeriod.term_id      == term_id,
            AcademicCalendarPeriod.period_type  == period_type,
            AcademicCalendarPeriod.is_active    == True,
            AcademicCalendarPeriod.start_date  <= today,
            AcademicCalendarPeriod.end_date    >= today,
        ).first() is not None

    @staticmethod
    def get_current_term(db: Session) -> Optional[AcademicTerm]:
        return db.query(AcademicTerm).filter(AcademicTerm.is_active == True).first()

    @staticmethod
    def get_term_periods(db: Session, term_id: int) -> List[AcademicCalendarPeriod]:
        return (
            db.query(AcademicCalendarPeriod)
            .filter(AcademicCalendarPeriod.term_id == term_id)
            .order_by(AcademicCalendarPeriod.start_date)
            .all()
        )


# ═════════════════════════════════════════════════════════════════════════════
# NOTIFICATION SERVICE
# ═════════════════════════════════════════════════════════════════════════════

class NotificationService:

    @staticmethod
    def render_template(template_body: str, context: Dict[str, Any]) -> str:
        """Replace {{variable}} placeholders with context values."""
        result = template_body
        for key, value in context.items():
            result = result.replace("{{" + key + "}}", str(value))
        return result

    @staticmethod
    def send_academic_notification(
        db:         Session,
        event_type: str,
        student_id: int,
        context:    Dict[str, Any],
    ) -> Optional[int]:
        """
        Resolve notification template, render with context, create notification.
        Returns notification id or None if template not found.
        """
        from app.models.models import Notification, Student, User
        from app.models.models import NotificationType, Priority

        student = db.query(Student).filter(Student.id == student_id).first()
        if not student:
            logger.warning("Notification skipped: student %s not found", student_id)
            return None

        user = db.query(User).filter(User.id == student.user_id).first()
        if not user:
            return None

        template = db.query(NotificationTemplate).filter(
            NotificationTemplate.event_type == event_type,
            NotificationTemplate.channel    == "in_app",
            NotificationTemplate.is_active  == True,
        ).first()

        if not template:
            logger.warning("No notification template for event_type=%s", event_type)
            return None

        ctx = {"student_name": user.name, **context}
        title   = NotificationService.render_template(template.subject_template, ctx)
        message = NotificationService.render_template(template.body_template, ctx)

        notif = Notification(
            user_id  = user.id,
            title    = title,
            message  = message,
            type     = "system",
            priority = template.priority or "medium",
            read     = False,
        )
        db.add(notif)
        db.flush()

        delivery = NotificationDeliveryLog(
            notification_id = notif.id,
            channel         = "in_app",
            event_type      = event_type,
            delivered       = True,
        )
        db.add(delivery)
        db.commit()

        logger.info("Notification sent: student=%s event=%s", student_id, event_type)
        return notif.id


# ═════════════════════════════════════════════════════════════════════════════
# DECISION LOG SERVICE (Explainability)
# ═════════════════════════════════════════════════════════════════════════════

class AcademicDecisionLogService:

    @staticmethod
    def log(
        db:              Session,
        decision_type:   str,
        student_id:      int,
        outcome:         bool,
        decision_reason: str,
        course_id:       Optional[int]  = None,
        term_id:         Optional[int]  = None,
        rule_triggered:  Optional[str]  = None,
        explanation:     Optional[str]  = None,
        input_snapshot:  Optional[dict] = None,
        output_snapshot: Optional[dict] = None,
        decided_by:      str            = "system",
    ) -> None:
        try:
            entry = AcademicDecisionLog(
                decision_type   = decision_type,
                student_id      = student_id,
                course_id       = course_id,
                term_id         = term_id,
                outcome         = outcome,
                decision_reason = decision_reason,
                rule_triggered  = rule_triggered,
                explanation     = explanation,
                input_snapshot  = input_snapshot,
                output_snapshot = output_snapshot,
                decided_by      = decided_by,
            )
            db.add(entry)
            db.commit()
        except Exception:
            logger.warning("Failed to write academic decision log", exc_info=True)


# ═════════════════════════════════════════════════════════════════════════════
# RBAC SERVICE
# ═════════════════════════════════════════════════════════════════════════════

class RbacService:

    @staticmethod
    def has_permission(db: Session, role: str, resource: str, action: str) -> bool:
        return db.query(RbacPermission).filter(
            RbacPermission.role      == role,
            RbacPermission.resource  == resource,
            RbacPermission.action    == action,
            RbacPermission.is_active == True,
        ).first() is not None

    @staticmethod
    def get_role_permissions(db: Session, role: str) -> List[RbacPermission]:
        return db.query(RbacPermission).filter(
            RbacPermission.role      == role,
            RbacPermission.is_active == True,
        ).all()
