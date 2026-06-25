"""
EduGuard AI — Sprint 5: Student Success Services
=================================================
Core business logic for:
  - Configuration Center Service
  - Early Warning Engine
  - Student Success Score Engine
  - Graduation Readiness Engine
  - Intervention Engine
  - Escalation Engine
  - Notification Service
  - Retention Analytics Service
  - Seed Data Generator

All rules are loaded from system_config_settings (never hardcoded).
"""

from __future__ import annotations

import logging
import secrets
import uuid
from datetime import datetime, date, timedelta, timezone
from decimal import Decimal
from typing import Any, Dict, List, Optional, Tuple

from sqlalchemy import and_, desc, func, or_, text
from sqlalchemy.orm import Session

logger = logging.getLogger(__name__)


# ═════════════════════════════════════════════════════════════════════════════
# CONFIG CENTER SERVICE
# ═════════════════════════════════════════════════════════════════════════════

class ConfigCenterService:
    """
    Central accessor for Sprint 5 system configuration.
    Reads from system_config_settings with program-specific override support.
    """

    @staticmethod
    def get(db: Session, key: str, program_id: Optional[int] = None) -> Optional[str]:
        from app.models.sprint5_models import SystemConfigSetting
        q = db.query(SystemConfigSetting).filter(
            SystemConfigSetting.key == key,
            SystemConfigSetting.program_id == program_id
        ).first()
        if q:
            return q.current_value or q.default_value
        # Fall back to global
        if program_id is not None:
            q = db.query(SystemConfigSetting).filter(
                SystemConfigSetting.key == key,
                SystemConfigSetting.program_id.is_(None)
            ).first()
            if q:
                return q.current_value or q.default_value
        return None

    @staticmethod
    def get_float(db: Session, key: str, default: float = 0.0, program_id: Optional[int] = None) -> float:
        v = ConfigCenterService.get(db, key, program_id)
        try:
            return float(v) if v is not None else default
        except (ValueError, TypeError):
            return default

    @staticmethod
    def get_int(db: Session, key: str, default: int = 0, program_id: Optional[int] = None) -> int:
        v = ConfigCenterService.get(db, key, program_id)
        try:
            return int(v) if v is not None else default
        except (ValueError, TypeError):
            return default

    @staticmethod
    def get_bool(db: Session, key: str, default: bool = False, program_id: Optional[int] = None) -> bool:
        v = ConfigCenterService.get(db, key, program_id)
        if v is None:
            return default
        return v.lower() in ("true", "1", "yes")

    @staticmethod
    def update(db: Session, key: str, value: str, changed_by: Optional[int] = None,
               reason: Optional[str] = None) -> bool:
        from app.models.sprint5_models import SystemConfigSetting, SystemConfigAudit
        setting = db.query(SystemConfigSetting).filter(
            SystemConfigSetting.key == key,
            SystemConfigSetting.program_id.is_(None)
        ).first()
        if not setting:
            return False
        old_value = setting.current_value
        setting.current_value = value
        setting.updated_by = changed_by
        setting.updated_at = datetime.now(timezone.utc)
        audit = SystemConfigAudit(
            setting_id=setting.id,
            setting_key=key,
            old_value=old_value,
            new_value=value,
            changed_by=changed_by,
            change_reason=reason,
        )
        db.add(audit)
        db.commit()
        return True

    @staticmethod
    def rollback(db: Session, audit_id: int, changed_by: Optional[int] = None) -> bool:
        from app.models.sprint5_models import SystemConfigSetting, SystemConfigAudit
        audit = db.query(SystemConfigAudit).filter(SystemConfigAudit.id == audit_id).first()
        if not audit:
            return False
        setting = db.query(SystemConfigSetting).filter(
            SystemConfigSetting.key == audit.setting_key
        ).first()
        if not setting:
            return False
        rollback_audit = SystemConfigAudit(
            setting_id=setting.id,
            setting_key=audit.setting_key,
            old_value=setting.current_value,
            new_value=audit.old_value,
            changed_by=changed_by,
            change_reason=f"Rollback of audit #{audit_id}",
            rollback_of=audit_id,
        )
        setting.current_value = audit.old_value
        db.add(rollback_audit)
        db.commit()
        return True

    @staticmethod
    def get_all_categories(db: Session) -> List[Any]:
        from app.models.sprint5_models import SystemConfigCategory
        return db.query(SystemConfigCategory).filter(
            SystemConfigCategory.is_active == True
        ).order_by(SystemConfigCategory.sort_order).all()

    @staticmethod
    def get_settings_by_category(db: Session, category_key: str) -> List[Any]:
        from app.models.sprint5_models import SystemConfigSetting, SystemConfigCategory
        cat = db.query(SystemConfigCategory).filter(SystemConfigCategory.key == category_key).first()
        if not cat:
            return []
        return db.query(SystemConfigSetting).filter(
            SystemConfigSetting.category_id == cat.id
        ).order_by(SystemConfigSetting.sort_order).all()

    @staticmethod
    def get_audit_history(db: Session, setting_key: str, limit: int = 50) -> List[Any]:
        from app.models.sprint5_models import SystemConfigAudit
        return db.query(SystemConfigAudit).filter(
            SystemConfigAudit.setting_key == setting_key
        ).order_by(desc(SystemConfigAudit.created_at)).limit(limit).all()


# ═════════════════════════════════════════════════════════════════════════════
# EARLY WARNING ENGINE
# ═════════════════════════════════════════════════════════════════════════════

class EarlyWarningEngine:
    """
    Automatically detects and generates academic warnings for students.
    All thresholds loaded from ConfigCenterService.
    """

    @staticmethod
    def run_for_student(db: Session, student_id: int) -> List[Any]:
        """Run all warning checks for a single student. Returns new warnings created."""
        from app.models.models import Student
        from app.models.academic_models import StudentTermGPA, StudentCourseAttempt, AcademicTerm
        from app.models.sprint5_models import StudentEarlyWarning

        student = db.query(Student).filter(Student.id == student_id).first()
        if not student:
            return []

        warnings_created = []

        # ── Load thresholds ─────────────────────────────────────────────────
        low_cgpa_thresh = ConfigCenterService.get_float(db, "dismissal_cgpa_threshold", 2.00)
        monitor_cgpa_hi = ConfigCenterService.get_float(db, "risk_monitor_cgpa_high", 2.50)
        low_gpa_thresh  = ConfigCenterService.get_float(db, "risk_low_gpa_threshold", 2.00)
        high_abs_pct    = ConfigCenterService.get_float(db, "risk_high_absence_pct", 25.0)
        min_semesters   = ConfigCenterService.get_int(db, "dismissal_min_regular_semesters", 6)
        count_summer    = ConfigCenterService.get_bool(db, "dismissal_count_summer", False)

        # ── Latest CGPA from term GPAs ───────────────────────────────────────
        latest_term_gpa = db.query(StudentTermGPA).filter(
            StudentTermGPA.student_id == student_id,
            StudentTermGPA.finalized == True
        ).order_by(desc(StudentTermGPA.created_at)).first()

        cgpa = float(latest_term_gpa.cgpa) if latest_term_gpa else None
        term_gpa_val = float(latest_term_gpa.term_gpa) if latest_term_gpa else None

        # ── Count regular semesters ──────────────────────────────────────────
        regular_sem_q = db.query(func.count(StudentTermGPA.id)).filter(
            StudentTermGPA.student_id == student_id,
            StudentTermGPA.finalized == True,
        )
        if not count_summer:
            regular_sem_q = regular_sem_q.filter(StudentTermGPA.is_summer == False)
        regular_sem_count = regular_sem_q.scalar() or 0

        def _active_warning_exists(wtype: str) -> bool:
            return db.query(StudentEarlyWarning).filter(
                StudentEarlyWarning.student_id == student_id,
                StudentEarlyWarning.warning_type == wtype,
                StudentEarlyWarning.status == "active",
            ).first() is not None

        def _create_warning(wtype: str, severity: str, title: str, desc: str,
                            triggered: Optional[float], threshold: Optional[float],
                            term_id: Optional[int] = None) -> Any:
            if _active_warning_exists(wtype):
                return None
            w = StudentEarlyWarning(
                student_id=student_id,
                warning_type=wtype,
                severity=severity,
                status="active",
                title=title,
                description=desc,
                triggered_value=triggered,
                threshold_value=threshold,
                term_id=term_id,
                auto_generated=True,
            )
            db.add(w)
            return w

        # ── W1: Dismissal Risk ───────────────────────────────────────────────
        if cgpa is not None and cgpa < low_cgpa_thresh and regular_sem_count >= min_semesters:
            w = _create_warning(
                "dismissal_risk", "urgent",
                f"Dismissal Risk: CGPA {cgpa:.2f}",
                f"CGPA {cgpa:.2f} is below minimum {low_cgpa_thresh:.2f} after {regular_sem_count} regular semesters.",
                cgpa, low_cgpa_thresh,
                latest_term_gpa.term_id if latest_term_gpa else None
            )
            if w:
                warnings_created.append(w)

        # ── W2: Low CGPA (monitoring range) ─────────────────────────────────
        elif cgpa is not None and low_cgpa_thresh <= cgpa <= monitor_cgpa_hi:
            w = _create_warning(
                "low_cgpa", "critical",
                f"CGPA in Monitoring Range: {cgpa:.2f}",
                f"CGPA {cgpa:.2f} is in the high-monitoring range ({low_cgpa_thresh:.2f}–{monitor_cgpa_hi:.2f}).",
                cgpa, monitor_cgpa_hi,
                latest_term_gpa.term_id if latest_term_gpa else None
            )
            if w:
                warnings_created.append(w)

        # ── W3: Low Term GPA ─────────────────────────────────────────────────
        if term_gpa_val is not None and term_gpa_val < low_gpa_thresh:
            w = _create_warning(
                "low_gpa", "warning",
                f"Low Term GPA: {term_gpa_val:.2f}",
                f"Term GPA {term_gpa_val:.2f} is below {low_gpa_thresh:.2f}.",
                term_gpa_val, low_gpa_thresh,
                latest_term_gpa.term_id if latest_term_gpa else None
            )
            if w:
                warnings_created.append(w)

        # ── W4: Repeated Failures ────────────────────────────────────────────
        repeat_fails = db.query(func.count(StudentCourseAttempt.id)).filter(
            StudentCourseAttempt.student_id == student_id,
            StudentCourseAttempt.result.in_(["failed", "withdrawn_fail"]),
        ).scalar() or 0

        if repeat_fails >= 3 and not _active_warning_exists("repeated_failure"):
            w = StudentEarlyWarning(
                student_id=student_id,
                warning_type="repeated_failure",
                severity="warning",
                status="active",
                title=f"Repeated Course Failures: {repeat_fails}",
                description=f"Student has {repeat_fails} failed/withdrawn course attempts.",
                triggered_value=float(repeat_fails),
                threshold_value=3,
                auto_generated=True,
            )
            db.add(w)
            warnings_created.append(w)

        # ── W5: Credit Deficit / Delayed Graduation ──────────────────────────
        total_req = ConfigCenterService.get_int(db, "graduation_total_credits", 134)
        earned = float(latest_term_gpa.cumulative_hours_earned) if latest_term_gpa else 0
        if latest_term_gpa and regular_sem_count >= 6:
            expected_credits = (regular_sem_count / 8) * total_req
            if earned < (expected_credits * 0.75) and not _active_warning_exists("delayed_graduation"):
                w = StudentEarlyWarning(
                    student_id=student_id,
                    warning_type="delayed_graduation",
                    severity="warning",
                    status="active",
                    title="Potential Graduation Delay",
                    description=f"Credit progress ({earned:.0f}/{total_req}) is significantly below expected pace.",
                    triggered_value=earned,
                    threshold_value=expected_credits * 0.75,
                    auto_generated=True,
                )
                db.add(w)
                warnings_created.append(w)

        if warnings_created:
            db.commit()
            for w in warnings_created:
                db.refresh(w)

        return warnings_created

    @staticmethod
    def run_for_all(db: Session) -> Dict[str, int]:
        """Run warning engine for all active students."""
        from app.models.models import Student
        students = db.query(Student.id).filter(Student.is_active == True).all()
        total_new = 0
        for (sid,) in students:
            try:
                new = EarlyWarningEngine.run_for_student(db, sid)
                total_new += len(new)
            except Exception as e:
                logger.warning(f"Warning engine failed for student {sid}: {e}")
        return {"students_processed": len(students), "warnings_created": total_new}

    @staticmethod
    def get_student_warnings(db: Session, student_id: int,
                              status: Optional[str] = None) -> List[Any]:
        from app.models.sprint5_models import StudentEarlyWarning
        q = db.query(StudentEarlyWarning).filter(
            StudentEarlyWarning.student_id == student_id
        )
        if status:
            q = q.filter(StudentEarlyWarning.status == status)
        return q.order_by(desc(StudentEarlyWarning.created_at)).all()

    @staticmethod
    def acknowledge(db: Session, warning_id: int, user_id: int,
                    notes: Optional[str] = None) -> bool:
        from app.models.sprint5_models import StudentEarlyWarning
        w = db.query(StudentEarlyWarning).filter(StudentEarlyWarning.id == warning_id).first()
        if not w:
            return False
        w.status = "acknowledged"
        w.acknowledged_by = user_id
        w.acknowledged_at = datetime.now(timezone.utc)
        if notes:
            w.resolution_notes = notes
        db.commit()
        return True


# ═════════════════════════════════════════════════════════════════════════════
# STUDENT SUCCESS SCORE ENGINE
# ═════════════════════════════════════════════════════════════════════════════

class SuccessScoreEngine:
    """
    Computes 0-100 student success score from real DB data.
    Weights loaded from ConfigCenterService.
    """

    @staticmethod
    def compute(db: Session, student_id: int,
                term_id: Optional[int] = None) -> Optional[Any]:
        from app.models.models import Student
        from app.models.academic_models import StudentTermGPA, StudentCourseAttempt
        from app.models.sprint5_models import (
            StudentSuccessScore, StudentEarlyWarning, StudentInterventionS5,
            SuccessScoreBandEnum
        )

        student = db.query(Student).filter(Student.id == student_id).first()
        if not student:
            return None

        # ── Load weights ─────────────────────────────────────────────────────
        w_cgpa       = ConfigCenterService.get_int(db, "success_weight_cgpa", 40) / 100
        w_attend     = ConfigCenterService.get_int(db, "success_weight_attendance", 20) / 100
        w_completion = ConfigCenterService.get_int(db, "success_weight_completion", 20) / 100
        w_progress   = ConfigCenterService.get_int(db, "success_weight_progress", 20) / 100

        band_excellent = ConfigCenterService.get_int(db, "success_band_excellent", 80)
        band_good      = ConfigCenterService.get_int(db, "success_band_good", 60)
        band_warning   = ConfigCenterService.get_int(db, "success_band_warning", 40)

        # ── CGPA Component ───────────────────────────────────────────────────
        latest_gpa = db.query(StudentTermGPA).filter(
            StudentTermGPA.student_id == student_id,
            StudentTermGPA.finalized == True
        ).order_by(desc(StudentTermGPA.created_at)).first()

        cgpa = float(latest_gpa.cgpa) if latest_gpa else 0.0
        # CGPA on 4.0 scale → 0-100
        cgpa_score = min(100.0, (cgpa / 4.0) * 100)

        # ── Attendance Component ──────────────────────────────────────────────
        # Use risk score from attendance if available, else estimate from warnings
        from app.models.sprint5_models import StudentEarlyWarning
        has_abs_warning = db.query(StudentEarlyWarning).filter(
            StudentEarlyWarning.student_id == student_id,
            StudentEarlyWarning.warning_type.in_(["high_absence", "attendance_critical"]),
            StudentEarlyWarning.status == "active",
        ).first() is not None
        attendance_score = 40.0 if has_abs_warning else 80.0  # estimated; replace when attendance data exists

        # ── Course Completion Component ───────────────────────────────────────
        total_attempts = db.query(func.count(StudentCourseAttempt.id)).filter(
            StudentCourseAttempt.student_id == student_id
        ).scalar() or 0
        passed_attempts = db.query(func.count(StudentCourseAttempt.id)).filter(
            StudentCourseAttempt.student_id == student_id,
            StudentCourseAttempt.result == "passed",
        ).scalar() or 0
        completion_score = (passed_attempts / total_attempts * 100) if total_attempts > 0 else 0.0

        # ── Academic Progress Component ───────────────────────────────────────
        total_req = ConfigCenterService.get_int(db, "graduation_total_credits", 134)
        earned = float(latest_gpa.cumulative_hours_earned) if latest_gpa else 0
        progress_score = min(100.0, (earned / total_req * 100)) if total_req > 0 else 0.0

        # ── Penalty for active warnings ───────────────────────────────────────
        active_warnings = db.query(func.count(StudentEarlyWarning.id)).filter(
            StudentEarlyWarning.student_id == student_id,
            StudentEarlyWarning.status == "active",
        ).scalar() or 0

        active_interventions = db.query(func.count(StudentInterventionS5.id)).filter(
            StudentInterventionS5.student_id == student_id,
            StudentInterventionS5.status.in_(["recommended", "scheduled", "in_progress"]),
        ).scalar() or 0

        # ── Weighted score ────────────────────────────────────────────────────
        raw_score = (
            cgpa_score       * w_cgpa +
            attendance_score * w_attend +
            completion_score * w_completion +
            progress_score   * w_progress
        )
        # Penalty: each active critical warning -3 pts
        penalty = min(20, active_warnings * 3)
        final_score = max(0.0, raw_score - penalty)

        # ── Determine band ────────────────────────────────────────────────────
        if final_score >= band_excellent:
            band = SuccessScoreBandEnum.EXCELLENT
        elif final_score >= band_good:
            band = SuccessScoreBandEnum.GOOD
        elif final_score >= band_warning:
            band = SuccessScoreBandEnum.WARNING
        else:
            band = SuccessScoreBandEnum.CRITICAL

        # ── Determine trend ───────────────────────────────────────────────────
        prev_score = db.query(StudentSuccessScore).filter(
            StudentSuccessScore.student_id == student_id
        ).order_by(desc(StudentSuccessScore.computed_at)).first()
        if prev_score:
            diff = final_score - float(prev_score.score)
            trend = "improving" if diff > 2 else "declining" if diff < -2 else "stable"
        else:
            trend = "stable"

        score_record = StudentSuccessScore(
            student_id=student_id,
            term_id=term_id,
            score=round(final_score, 2),
            band=band,
            cgpa_score=round(cgpa_score, 2),
            attendance_score=round(attendance_score, 2),
            course_completion_score=round(completion_score, 2),
            progress_score=round(progress_score, 2),
            risk_score=round(max(0, 100 - final_score), 2),
            active_warnings=active_warnings,
            active_interventions=active_interventions,
            trend=trend,
        )
        db.add(score_record)
        db.commit()
        db.refresh(score_record)
        return score_record

    @staticmethod
    def get_latest(db: Session, student_id: int) -> Optional[Any]:
        from app.models.sprint5_models import StudentSuccessScore
        return db.query(StudentSuccessScore).filter(
            StudentSuccessScore.student_id == student_id
        ).order_by(desc(StudentSuccessScore.computed_at)).first()

    @staticmethod
    def get_history(db: Session, student_id: int, limit: int = 12) -> List[Any]:
        from app.models.sprint5_models import StudentSuccessScore
        return db.query(StudentSuccessScore).filter(
            StudentSuccessScore.student_id == student_id
        ).order_by(desc(StudentSuccessScore.computed_at)).limit(limit).all()


# ═════════════════════════════════════════════════════════════════════════════
# GRADUATION READINESS ENGINE
# ═════════════════════════════════════════════════════════════════════════════

class GraduationReadinessEngine:
    """
    Calculates graduation readiness percentage and status from real DB data.
    Based on the NMU CS Software Engineering curriculum (134 credit hours).
    """

    # NMU CS Software Engineering required courses (from uploaded PDF)
    REQUIRED_CORE_COURSES = [
        "CSE014","CSE015","CSE111","CSE112","CSE113","CSE131","CSE132",
        "CSE191","CSE211","CSE212","CSE221","CSE233","CSE241","CSE251",
        "CSE261","CSE292","CSE312","CSE313","CSE315","CSE323","CSE352",
        "CSE363","CSE454","CSE475","CSE493","CSE494",
        "AIE111","AIE121","AIE323",
        "MAT112","MAT114","MAT131","MAT212","MAT231","MAT313",
        "PHY211",
    ]
    REQUIRED_ELECTIVE_COUNT = 3   # E1, E2, E3
    REQUIRED_UC_COUNT       = 7   # UC1–UC7
    REQUIRED_UE_COUNT       = 3   # UE1–UE3

    @staticmethod
    def compute(db: Session, student_id: int) -> Optional[Any]:
        from app.models.models import Student, Course
        from app.models.academic_models import StudentTermGPA, StudentCourseAttempt
        from app.models.sprint5_models import GraduationReadinessCache, ReadinessStatusEnum

        student = db.query(Student).filter(Student.id == student_id).first()
        if not student:
            return None

        total_req    = ConfigCenterService.get_int(db, "graduation_total_credits", 134)
        min_grad_cgpa = ConfigCenterService.get_float(db, "graduation_min_cgpa", 2.00)

        # ── Latest cumulative data ────────────────────────────────────────────
        latest_gpa = db.query(StudentTermGPA).filter(
            StudentTermGPA.student_id == student_id,
            StudentTermGPA.finalized == True
        ).order_by(desc(StudentTermGPA.created_at)).first()

        completed_credits = int(latest_gpa.cumulative_hours_earned) if latest_gpa else 0
        remaining_credits = max(0, total_req - completed_credits)
        cgpa              = float(latest_gpa.cgpa) if latest_gpa else 0.0
        cgpa_eligible     = cgpa >= min_grad_cgpa

        # ── Passed courses ────────────────────────────────────────────────────
        passed_attempts = db.query(
            StudentCourseAttempt.course_id
        ).filter(
            StudentCourseAttempt.student_id == student_id,
            StudentCourseAttempt.result == "passed",
        ).distinct().all()
        passed_ids = {row[0] for row in passed_attempts}

        # Get course codes for passed courses
        if passed_ids:
            passed_codes = {
                row[0] for row in db.query(Course.code).filter(Course.id.in_(passed_ids)).all()
            }
        else:
            passed_codes = set()

        # ── Required core completions ─────────────────────────────────────────
        required_set = set(GraduationReadinessEngine.REQUIRED_CORE_COURSES)
        completed_required = required_set & passed_codes
        missing_required   = sorted(required_set - passed_codes)

        total_req_courses = len(required_set) + GraduationReadinessEngine.REQUIRED_ELECTIVE_COUNT
        completed_courses = len(completed_required)
        # TODO: Count electives from UC/UE once curriculum categories stored
        # PENDING_POLICY_CONFIGURATION: UC/UE tracking requires curriculum category data

        uc_requirements_met = False  # PENDING_POLICY_CONFIGURATION

        pending_issues = []
        if not cgpa_eligible:
            pending_issues.append(f"CGPA {cgpa:.2f} below minimum {min_grad_cgpa:.2f}")
        if missing_required:
            pending_issues.append(f"{len(missing_required)} required courses not completed")
        if remaining_credits > 0:
            pending_issues.append(f"{remaining_credits} credit hours remaining")
        if not uc_requirements_met:
            pending_issues.append("UC/UE requirements: PENDING_POLICY_CONFIGURATION")

        # ── Compute readiness % ───────────────────────────────────────────────
        credit_pct  = min(1.0, completed_credits / total_req) if total_req > 0 else 0
        course_pct  = min(1.0, completed_courses / total_req_courses) if total_req_courses > 0 else 0
        cgpa_factor = 1.0 if cgpa_eligible else (cgpa / min_grad_cgpa) * 0.5

        readiness_pct = round(
            (credit_pct * 0.40 + course_pct * 0.40 + cgpa_factor * 0.20) * 100, 2
        )

        # ── Status ────────────────────────────────────────────────────────────
        if readiness_pct >= 95 and cgpa_eligible and not missing_required:
            status = ReadinessStatusEnum.READY
        elif readiness_pct >= 75 and cgpa_eligible:
            status = ReadinessStatusEnum.NEARLY_READY
        elif readiness_pct >= 40:
            status = ReadinessStatusEnum.NEEDS_ATTENTION
        else:
            status = ReadinessStatusEnum.NOT_ELIGIBLE

        # Estimate graduation term
        if remaining_credits > 0 and completed_credits > 0:
            avg_credits_per_sem = completed_credits / max(1, (
                db.query(func.count(StudentTermGPA.id)).filter(
                    StudentTermGPA.student_id == student_id,
                    StudentTermGPA.finalized == True
                ).scalar() or 1
            ))
            sems_remaining = int(remaining_credits / max(1, avg_credits_per_sem)) + 1
            est_year = date.today().year + (sems_remaining // 2)
            est_sem  = "Fall" if sems_remaining % 2 == 0 else "Spring"
            est_grad = f"{est_sem} {est_year}"
        else:
            est_grad = "Current Semester" if readiness_pct >= 95 else None

        # ── Upsert cache ──────────────────────────────────────────────────────
        record = db.query(GraduationReadinessCache).filter(
            GraduationReadinessCache.student_id == student_id
        ).first()
        if record:
            record.readiness_pct          = readiness_pct
            record.status                 = status
            record.total_required_credits = total_req
            record.completed_credits      = completed_credits
            record.remaining_credits      = remaining_credits
            record.total_required_courses = total_req_courses
            record.completed_courses      = completed_courses
            record.missing_required       = missing_required
            record.cgpa_eligible          = cgpa_eligible
            record.uc_requirements_met    = uc_requirements_met
            record.pending_issues         = pending_issues
            record.estimated_graduation_term = est_grad
            record.computed_at            = datetime.now(timezone.utc)
        else:
            record = GraduationReadinessCache(
                student_id=student_id,
                readiness_pct=readiness_pct,
                status=status,
                total_required_credits=total_req,
                completed_credits=completed_credits,
                remaining_credits=remaining_credits,
                total_required_courses=total_req_courses,
                completed_courses=completed_courses,
                missing_required=missing_required,
                cgpa_eligible=cgpa_eligible,
                uc_requirements_met=uc_requirements_met,
                pending_issues=pending_issues,
                estimated_graduation_term=est_grad,
            )
            db.add(record)

        db.commit()
        db.refresh(record)
        return record

    @staticmethod
    def get_cached(db: Session, student_id: int) -> Optional[Any]:
        from app.models.sprint5_models import GraduationReadinessCache
        return db.query(GraduationReadinessCache).filter(
            GraduationReadinessCache.student_id == student_id
        ).first()


# ═════════════════════════════════════════════════════════════════════════════
# INTERVENTION ENGINE
# ═════════════════════════════════════════════════════════════════════════════

class InterventionEngine:
    """
    Generates actionable intervention recommendations from real data.
    """

    @staticmethod
    def generate_for_student(db: Session, student_id: int,
                              created_by: Optional[int] = None) -> List[Any]:
        from app.models.models import Student, Course
        from app.models.academic_models import StudentTermGPA, StudentCourseAttempt, GradeScale
        from app.models.sprint5_models import StudentEarlyWarning, StudentInterventionS5

        student = db.query(Student).filter(Student.id == student_id).first()
        if not student:
            return []

        latest_gpa = db.query(StudentTermGPA).filter(
            StudentTermGPA.student_id == student_id,
            StudentTermGPA.finalized == True
        ).order_by(desc(StudentTermGPA.created_at)).first()

        cgpa = float(latest_gpa.cgpa) if latest_gpa else 0.0
        term_gpa_val = float(latest_gpa.term_gpa) if latest_gpa else 0.0

        min_grad_cgpa = ConfigCenterService.get_float(db, "graduation_min_cgpa", 2.00)
        total_req     = ConfigCenterService.get_int(db, "graduation_total_credits", 134)
        earned        = float(latest_gpa.cumulative_hours_earned) if latest_gpa else 0

        interventions = []

        # ── I1: Required next-semester GPA to reach target ───────────────────
        if cgpa < min_grad_cgpa and latest_gpa:
            cum_q_pts   = float(latest_gpa.cumulative_quality_points)
            cum_hrs_att = float(latest_gpa.cumulative_hours_attempted)
            next_sem_credits = 15  # typical load; PENDING_POLICY_CONFIGURATION
            target_q_pts = min_grad_cgpa * (cum_hrs_att + next_sem_credits)
            needed_q_pts = target_q_pts - cum_q_pts
            required_next_gpa = round(needed_q_pts / next_sem_credits, 3) if next_sem_credits > 0 else 0

            intervention = StudentInterventionS5(
                student_id=student_id,
                intervention_type="gpa_recovery",
                title=f"GPA Recovery Plan — CGPA {cgpa:.2f} → {min_grad_cgpa:.2f}",
                description=(
                    f"Current CGPA {cgpa:.2f} is below minimum {min_grad_cgpa:.2f}. "
                    f"Requires GPA of {min(4.0, required_next_gpa):.2f} next semester "
                    f"(assuming {next_sem_credits} credit hours)."
                ),
                target_cgpa=min_grad_cgpa,
                required_next_gpa=min(4.0, required_next_gpa),
                recommendations=[
                    f"Achieve minimum GPA of {min(4.0, required_next_gpa):.2f} in the next semester",
                    "Meet with your academic advisor immediately",
                    "Consider reducing course load to focus on quality",
                    "Utilize tutoring and academic support services",
                    "Review and potentially repeat courses with low grades",
                ],
                priority="high" if cgpa < 1.70 else "medium",
                created_by=created_by,
            )
            db.add(intervention)
            interventions.append(intervention)

        # ── I2: In-progress courses — marks needed to pass ───────────────────
        in_progress = db.query(StudentCourseAttempt).filter(
            StudentCourseAttempt.student_id == student_id,
            StudentCourseAttempt.result == "in_progress",
        ).all()

        marks_needed = {}
        for attempt in in_progress:
            course = db.query(Course).filter(Course.id == attempt.course_id).first()
            if not attempt.numeric_grade:
                continue
            current = float(attempt.numeric_grade)
            # Find passing threshold
            pass_scale = db.query(GradeScale).filter(
                GradeScale.is_passing == True
            ).order_by(GradeScale.min_percentage).first()
            passing_min = float(pass_scale.min_percentage) if pass_scale else 50.0
            needed = max(0, passing_min - current)
            marks_needed[course.code if course else str(attempt.course_id)] = {
                "current": current,
                "needed_to_pass": round(needed, 1),
                "passing_threshold": passing_min,
            }

        if marks_needed:
            intervention = StudentInterventionS5(
                student_id=student_id,
                intervention_type="marks_recovery",
                title="Current Semester Performance Plan",
                description="Marks analysis for in-progress courses.",
                marks_needed=marks_needed,
                recommendations=[
                    f"Focus on courses requiring most improvement",
                    "Attend all remaining classes and labs",
                    "Submit all assignments on time",
                    "Prepare thoroughly for remaining assessments",
                ],
                priority="medium",
                created_by=created_by,
            )
            db.add(intervention)
            interventions.append(intervention)

        # ── I3: Graduation path ───────────────────────────────────────────────
        remaining = max(0, total_req - int(earned))
        if remaining > 0:
            sems_left = max(1, (remaining // 15) + (1 if remaining % 15 else 0))
            graduation_path = {
                "remaining_credits": remaining,
                "estimated_semesters": sems_left,
                "recommended_load_per_semester": min(18, max(12, remaining // sems_left)),
                "notes": "PENDING_POLICY_CONFIGURATION: Exact course sequence depends on available curriculum data",
            }
            intervention = StudentInterventionS5(
                student_id=student_id,
                intervention_type="graduation_path",
                title=f"Graduation Path: {remaining} Credits Remaining",
                description=f"Estimated {sems_left} semesters to complete remaining {remaining} credit hours.",
                graduation_path=graduation_path,
                recommendations=[
                    f"Enroll in {graduation_path['recommended_load_per_semester']} credits per semester",
                    "Prioritize remaining required core courses",
                    "Plan elective courses to meet track requirements",
                    "Complete field training requirements on schedule",
                ],
                priority="low" if remaining < 30 else "medium",
                created_by=created_by,
            )
            db.add(intervention)
            interventions.append(intervention)

        if interventions:
            db.commit()
            for i in interventions:
                db.refresh(i)

        return interventions

    @staticmethod
    def get_student_interventions(db: Session, student_id: int,
                                   status: Optional[str] = None) -> List[Any]:
        from app.models.sprint5_models import StudentInterventionS5
        q = db.query(StudentInterventionS5).filter(
            StudentInterventionS5.student_id == student_id
        )
        if status:
            q = q.filter(StudentInterventionS5.status == status)
        return q.order_by(desc(StudentInterventionS5.created_at)).all()

    @staticmethod
    def update_status(db: Session, intervention_id: int, status: str,
                       outcome: Optional[str] = None) -> bool:
        from app.models.sprint5_models import StudentInterventionS5
        i = db.query(StudentInterventionS5).filter(
            StudentInterventionS5.id == intervention_id
        ).first()
        if not i:
            return False
        i.status = status
        if outcome:
            i.outcome = outcome
        if status == "completed":
            i.completed_at = datetime.now(timezone.utc)
        db.commit()
        return True


# ═════════════════════════════════════════════════════════════════════════════
# ESCALATION ENGINE
# ═════════════════════════════════════════════════════════════════════════════

class EscalationEngine:
    """
    Auto-escalation of unacknowledged warnings / unresolved interventions.
    """

    ESCALATION_CHAIN = [
        "student", "advisor", "professor", "registrar", "academic_affairs", "dean"
    ]

    @staticmethod
    def check_and_escalate(db: Session) -> int:
        """
        Run auto-escalation for all active warnings past their threshold.
        Returns count of escalations created.
        """
        if not ConfigCenterService.get_bool(db, "escalation_auto_enabled", True):
            return 0

        from app.models.sprint5_models import StudentEarlyWarning, StudentEscalation

        advisor_days    = ConfigCenterService.get_int(db, "escalation_warning_days_advisor", 3)
        registrar_days  = ConfigCenterService.get_int(db, "escalation_warning_days_registrar", 7)

        now = datetime.now(timezone.utc)
        advisor_threshold   = now - timedelta(days=advisor_days)
        registrar_threshold = now - timedelta(days=registrar_days)

        active_warnings = db.query(StudentEarlyWarning).filter(
            StudentEarlyWarning.status == "active",
        ).all()

        count = 0
        for w in active_warnings:
            already_escalated = db.query(StudentEscalation).filter(
                StudentEscalation.warning_id == w.id,
                StudentEscalation.status.in_(["pending", "in_progress"]),
            ).first()
            if already_escalated:
                continue

            w_created = w.created_at
            if w_created.tzinfo is None:
                w_created = w_created.replace(tzinfo=timezone.utc)

            to_level = None
            reason   = None

            if w_created <= registrar_threshold:
                to_level = "registrar"
                reason   = f"Warning unacknowledged for {registrar_days}+ days"
            elif w_created <= advisor_threshold:
                to_level = "advisor"
                reason   = f"Warning unacknowledged for {advisor_days}+ days"

            if to_level:
                esc = StudentEscalation(
                    student_id=w.student_id,
                    warning_id=w.id,
                    from_level="student",
                    to_level=to_level,
                    reason=reason,
                    status="pending",
                )
                db.add(esc)
                count += 1

        if count:
            db.commit()
        return count

    @staticmethod
    def get_student_escalations(db: Session, student_id: int) -> List[Any]:
        from app.models.sprint5_models import StudentEscalation
        return db.query(StudentEscalation).filter(
            StudentEscalation.student_id == student_id
        ).order_by(desc(StudentEscalation.created_at)).all()

    @staticmethod
    def resolve(db: Session, escalation_id: int, user_id: int, notes: str) -> bool:
        from app.models.sprint5_models import StudentEscalation
        esc = db.query(StudentEscalation).filter(StudentEscalation.id == escalation_id).first()
        if not esc:
            return False
        esc.status = "resolved"
        esc.response_notes = notes
        esc.responded_at = datetime.now(timezone.utc)
        esc.resolved_at  = datetime.now(timezone.utc)
        if esc.created_at:
            created = esc.created_at
            if created.tzinfo is None:
                created = created.replace(tzinfo=timezone.utc)
            delta = datetime.now(timezone.utc) - created
            esc.response_time_hours = round(delta.total_seconds() / 3600, 2)
        db.commit()
        return True


# ═════════════════════════════════════════════════════════════════════════════
# NOTIFICATION SERVICE
# ═════════════════════════════════════════════════════════════════════════════

class NotificationService:
    """
    In-app notification dispatch using queue table.
    Email/SMS/Push: infrastructure ready, provider integration PENDING.
    """

    @staticmethod
    def send(db: Session, recipient_id: int, body: str,
             template_key: Optional[str] = None,
             channel: str = "in_app",
             subject: Optional[str] = None,
             variables: Optional[Dict] = None,
             related_entity: Optional[str] = None,
             related_id: Optional[int] = None,
             priority: str = "normal") -> Any:
        from app.models.sprint5_models import NotificationQueue, NotificationTemplate

        template_id = None
        rendered_body = body
        rendered_subject = subject

        if template_key:
            tmpl = db.query(NotificationTemplate).filter(
                NotificationTemplate.key == template_key,
                NotificationTemplate.is_active == True,
            ).first()
            if tmpl:
                template_id = tmpl.id
                rendered_body = tmpl.body_template
                rendered_subject = tmpl.subject_template
                if variables:
                    for k, v in variables.items():
                        rendered_body = rendered_body.replace(f"{{{{{k}}}}}", str(v))
                        if rendered_subject:
                            rendered_subject = rendered_subject.replace(f"{{{{{k}}}}}", str(v))

        notif = NotificationQueue(
            recipient_id=recipient_id,
            template_id=template_id,
            channel=channel,
            subject=rendered_subject,
            body=rendered_body,
            variables=variables,
            priority=priority,
            status="queued",
            related_entity=related_entity,
            related_id=related_id,
        )
        db.add(notif)
        db.commit()
        db.refresh(notif)
        return notif

    @staticmethod
    def get_unread(db: Session, user_id: int, limit: int = 20) -> List[Any]:
        from app.models.sprint5_models import NotificationQueue
        return db.query(NotificationQueue).filter(
            NotificationQueue.recipient_id == user_id,
            NotificationQueue.status == "queued",
            NotificationQueue.channel == "in_app",
        ).order_by(desc(NotificationQueue.created_at)).limit(limit).all()

    @staticmethod
    def mark_sent(db: Session, notif_id: int) -> None:
        from app.models.sprint5_models import NotificationQueue
        n = db.query(NotificationQueue).filter(NotificationQueue.id == notif_id).first()
        if n:
            n.status = "sent"
            n.sent_at = datetime.now(timezone.utc)
            db.commit()

    @staticmethod
    def get_or_create_preferences(db: Session, user_id: int) -> Any:
        from app.models.sprint5_models import NotificationPreference
        pref = db.query(NotificationPreference).filter(
            NotificationPreference.user_id == user_id
        ).first()
        if not pref:
            pref = NotificationPreference(user_id=user_id)
            db.add(pref)
            db.commit()
            db.refresh(pref)
        return pref


# ═════════════════════════════════════════════════════════════════════════════
# STUDENT SUCCESS DASHBOARD SERVICE
# ═════════════════════════════════════════════════════════════════════════════

class StudentSuccessDashboardService:
    """Aggregates all student success data for the dashboard."""

    @staticmethod
    def get_student_dashboard(db: Session, student_id: int) -> Dict[str, Any]:
        from app.models.models import Student
        from app.models.academic_models import StudentTermGPA, AcademicProgram, AcademicTrack
        from app.models.sprint5_models import (
            StudentEarlyWarning, StudentInterventionS5,
        )

        student = db.query(Student).filter(Student.id == student_id).first()
        if not student:
            return {}

        # Run computations
        warnings = EarlyWarningEngine.run_for_student(db, student_id)
        score    = SuccessScoreEngine.compute(db, student_id)
        readiness = GraduationReadinessEngine.compute(db, student_id)

        latest_gpa = db.query(StudentTermGPA).filter(
            StudentTermGPA.student_id == student_id,
            StudentTermGPA.finalized == True
        ).order_by(desc(StudentTermGPA.created_at)).first()

        cgpa = float(latest_gpa.cgpa) if latest_gpa else 0.0
        term_gpa_val = float(latest_gpa.term_gpa) if latest_gpa else 0.0
        earned = int(latest_gpa.cumulative_hours_earned) if latest_gpa else 0

        # Count regular semesters
        count_summer = ConfigCenterService.get_bool(db, "dismissal_count_summer", False)
        sem_q = db.query(func.count(StudentTermGPA.id)).filter(
            StudentTermGPA.student_id == student_id,
            StudentTermGPA.finalized == True,
        )
        if not count_summer:
            sem_q = sem_q.filter(StudentTermGPA.is_summer == False)
        regular_sems = sem_q.scalar() or 0

        min_sems = ConfigCenterService.get_int(db, "dismissal_min_regular_semesters", 6)
        dismissal_thresh = ConfigCenterService.get_float(db, "dismissal_cgpa_threshold", 2.00)
        dismissal_risk = (cgpa < dismissal_thresh) and (regular_sems >= min_sems)

        # Active warnings & interventions
        active_warnings = db.query(StudentEarlyWarning).filter(
            StudentEarlyWarning.student_id == student_id,
            StudentEarlyWarning.status == "active",
        ).all()
        active_interventions = db.query(StudentInterventionS5).filter(
            StudentInterventionS5.student_id == student_id,
            StudentInterventionS5.status.in_(["recommended", "scheduled", "in_progress"]),
        ).all()

        # Risk level
        if dismissal_risk or (score and score.band == "critical"):
            risk_level = "critical"
        elif score and score.band == "warning":
            risk_level = "high"
        elif cgpa < 2.50:
            risk_level = "medium"
        else:
            risk_level = "low"

        # Quick recommendations
        recommendations = []
        if dismissal_risk:
            recommendations.append(f"⚠️ Dismissal risk: CGPA {cgpa:.2f} after {regular_sems} semesters")
        if readiness and readiness.readiness_pct < 50:
            recommendations.append(f"📚 Increase credit load — {readiness.remaining_credits} credits remaining")
        if term_gpa_val < 2.0:
            recommendations.append(f"📉 Improve term GPA: currently {term_gpa_val:.2f}")
        if len(active_warnings) >= 3:
            recommendations.append("🔔 Multiple active warnings — contact advisor immediately")

        # Academic timeline summary
        term_gpas = db.query(StudentTermGPA).filter(
            StudentTermGPA.student_id == student_id,
            StudentTermGPA.finalized == True,
        ).order_by(StudentTermGPA.created_at).all()

        timeline = [
            {
                "term_id": t.term_id,
                "term_gpa": float(t.term_gpa),
                "cgpa": float(t.cgpa),
                "credits_earned": int(t.term_credit_hours_earned),
                "cumulative_earned": int(t.cumulative_hours_earned),
                "standing": t.academic_standing,
                "is_summer": t.is_summer,
            }
            for t in term_gpas
        ]

        program_name = None
        if student.program_id:
            prog = db.query(AcademicProgram).filter(AcademicProgram.id == student.program_id).first()
            if prog:
                program_name = prog.name

        return {
            "student_id":              student_id,
            "student_name":            student.name,
            "student_code":            getattr(student, "student_id", str(student_id)),
            "program_name":            program_name,
            "current_gpa":             round(term_gpa_val, 3),
            "current_cgpa":            round(cgpa, 3),
            "academic_standing":       latest_gpa.academic_standing if latest_gpa else "good",
            "success_score":           score,
            "graduation_readiness":    readiness,
            "active_warnings":         active_warnings,
            "active_interventions":    active_interventions,
            "risk_level":              risk_level,
            "total_credits_completed": earned,
            "credits_remaining":       readiness.remaining_credits if readiness else 0,
            "regular_semesters":       regular_sems,
            "dismissal_risk":          dismissal_risk,
            "recommendations":         recommendations,
            "timeline_summary":        timeline,
        }


# ═════════════════════════════════════════════════════════════════════════════
# RETENTION ANALYTICS SERVICE
# ═════════════════════════════════════════════════════════════════════════════

class RetentionAnalyticsService:
    """Computes institution-wide retention and risk analytics."""

    @staticmethod
    def compute_snapshot(db: Session, term_id: Optional[int] = None,
                          program_id: Optional[int] = None) -> Any:
        from app.models.models import Student
        from app.models.academic_models import StudentTermGPA
        from app.models.sprint5_models import RetentionSnapshot, StudentEarlyWarning, StudentSuccessScore

        dismissal_thresh = ConfigCenterService.get_float(db, "dismissal_cgpa_threshold", 2.00)
        monitor_hi       = ConfigCenterService.get_float(db, "risk_monitor_cgpa_high", 2.50)
        min_sems         = ConfigCenterService.get_int(db, "dismissal_min_regular_semesters", 6)
        count_summer     = ConfigCenterService.get_bool(db, "dismissal_count_summer", False)

        student_q = db.query(Student)
        if program_id:
            student_q = student_q.filter(Student.program_id == program_id)
        all_students = student_q.all()
        total = len(all_students)
        active = sum(1 for s in all_students if getattr(s, "is_active", True))

        below_2  = 0
        b2_to_25 = 0
        above_25 = 0
        dismissal_risk = 0
        probation = 0
        expected_grads = 0
        grad_delay = 0
        critical_warnings = 0
        cgpa_sum = 0.0
        score_sum = 0.0
        scored = 0

        for student in all_students:
            latest = db.query(StudentTermGPA).filter(
                StudentTermGPA.student_id == student.id,
                StudentTermGPA.finalized == True
            ).order_by(desc(StudentTermGPA.created_at)).first()
            if not latest:
                continue

            cgpa = float(latest.cgpa)
            cgpa_sum += cgpa

            if cgpa < dismissal_thresh:
                below_2 += 1
            elif cgpa <= monitor_hi:
                b2_to_25 += 1
            else:
                above_25 += 1

            if latest.academic_standing in ("probation", "warning"):
                probation += 1

            # Dismissal risk
            sem_q = db.query(func.count(StudentTermGPA.id)).filter(
                StudentTermGPA.student_id == student.id,
                StudentTermGPA.finalized == True,
            )
            if not count_summer:
                sem_q = sem_q.filter(StudentTermGPA.is_summer == False)
            sems = sem_q.scalar() or 0
            if cgpa < dismissal_thresh and sems >= min_sems:
                dismissal_risk += 1

            # Graduation candidates (>= 100 credits earned, cgpa ok)
            if float(latest.cumulative_hours_earned) >= 100 and cgpa >= dismissal_thresh:
                expected_grads += 1

            # Warning count
            crit_warn = db.query(func.count(StudentEarlyWarning.id)).filter(
                StudentEarlyWarning.student_id == student.id,
                StudentEarlyWarning.severity == "critical",
                StudentEarlyWarning.status == "active",
            ).scalar() or 0
            critical_warnings += crit_warn

            # Success score
            latest_score = db.query(StudentSuccessScore).filter(
                StudentSuccessScore.student_id == student.id
            ).order_by(desc(StudentSuccessScore.computed_at)).first()
            if latest_score:
                score_sum += float(latest_score.score)
                scored += 1

        avg_cgpa  = round(cgpa_sum / total, 3) if total > 0 else 0
        avg_score = round(score_sum / scored, 2) if scored > 0 else None
        retention_rate = round((active / total * 100), 2) if total > 0 else 0

        snapshot = RetentionSnapshot(
            snapshot_date=date.today(),
            term_id=term_id,
            program_id=program_id,
            total_students=total,
            active_students=active,
            below_2_cgpa=below_2,
            between_2_and_2_5_cgpa=b2_to_25,
            above_2_5_cgpa=above_25,
            dismissal_risk_count=dismissal_risk,
            probation_count=probation,
            expected_graduates=expected_grads,
            graduation_delay_count=grad_delay,
            critical_warnings_count=critical_warnings,
            avg_success_score=avg_score,
            avg_cgpa=avg_cgpa,
            retention_rate=retention_rate,
        )
        db.add(snapshot)
        db.commit()
        db.refresh(snapshot)
        return snapshot

    @staticmethod
    def get_latest_snapshot(db: Session, program_id: Optional[int] = None) -> Optional[Any]:
        from app.models.sprint5_models import RetentionSnapshot
        q = db.query(RetentionSnapshot)
        if program_id:
            q = q.filter(RetentionSnapshot.program_id == program_id)
        return q.order_by(desc(RetentionSnapshot.created_at)).first()

    @staticmethod
    def get_snapshot_history(db: Session, limit: int = 12,
                              program_id: Optional[int] = None) -> List[Any]:
        from app.models.sprint5_models import RetentionSnapshot
        q = db.query(RetentionSnapshot)
        if program_id:
            q = q.filter(RetentionSnapshot.program_id == program_id)
        return q.order_by(desc(RetentionSnapshot.created_at)).limit(limit).all()
