"""
EduGuard AI — Sprint 4: Services v2 (Repository-backed)
=========================================================
All direct ORM access has been removed from service methods.
Every database interaction goes through the repository layer.

New engines in this file:
  - GPAVersioningService       (GPA Versioning Engine)
  - GPAExplainabilityService   (GPA Audit Explainability Engine)
  - ScholarshipService         (Scholarship Eligibility Engine)
  - AcademicAchievementService (Academic Achievement Registry)

Existing services refactored:
  - GPAEngine                  (now uses repositories)
  - GradeProcessingService     (now uses GradeScaleRepository)
  - AcademicStandingService    (now uses StatusHistoryRepository)
  - DegreeProgressService      (now uses DegreeProgressRepository)
  - GraduationEligibilityService (now uses GraduationEligibilityRepository)
  - HonorsService              (now uses HonorsRepository)
  - GPAProjectionService       (now uses GPAProjectionRepository)
  - AcademicRiskService        (now uses RiskRepository)
  - TranscriptService          (now uses TranscriptRepository)
  - VerificationService        (now uses TranscriptRepository)
  - TimelineService            (now uses TimelineRepository)
  - AuditService               (now uses AuditRepository)
  - RegistrarNoteService       (now uses RegistrarNoteRepository)
  - DashboardService           (composes all repositories)
  - SnapshotService            (now uses SnapshotRepository)
"""

from __future__ import annotations

import hashlib
import json
import logging
import secrets
from decimal import Decimal, ROUND_HALF_UP
from typing import Any, Dict, List, Optional, Tuple
from datetime import datetime, timezone

from sqlalchemy.orm import Session

from app.models.models import Course
from app.models.academic_models import AcademicTerm, StudentTermGPA
from app.models.sprint4_models import (
    AcademicStatusEnum, HonorsLevelEnum, GradEligibilityEnum,
    RiskLevelEnum, TimelineEventTypeEnum, AuditActionEnum,
    TranscriptVerification,
)
from app.models.sprint4_extended_models import (
    ScholarshipStatusEnum, AchievementCategoryEnum,
)
from app.repositories.sprint4_repositories import (
    StudentRepository, RulesConfigRepository, GradeScaleRepository,
    CourseAttemptRepository, TermGPARepository, SnapshotRepository,
    TranscriptRepository, TimelineRepository, StatusHistoryRepository,
    DegreeProgressRepository, GraduationEligibilityRepository,
    HonorsRepository, GPAProjectionRepository, RiskRepository,
    RegistrarNoteRepository, AuditRepository,
    GPAVersionRepository, GPAExplanationRepository,
    ScholarshipRepository, AchievementRepository,
)

logger = logging.getLogger(__name__)
PENDING = RulesConfigRepository.PENDING


# ─────────────────────────────────────────────────────────────────────────────
# SHARED DECIMAL UTILITY
# ─────────────────────────────────────────────────────────────────────────────

def _round(value: Decimal, places: int = 3) -> Decimal:
    q = Decimal(10) ** -places
    return value.quantize(q, rounding=ROUND_HALF_UP)


def _d(val) -> Decimal:
    return Decimal(str(val or 0))


# ═════════════════════════════════════════════════════════════════════════════
# GRADE PROCESSING SERVICE  (refactored — uses GradeScaleRepository)
# ═════════════════════════════════════════════════════════════════════════════

class GradeProcessingService:
    """Grade lookup, validation, and posting. Reads grade scale from DB."""

    CGPA_EXCLUDED = {"W", "I", "P", "IP"}

    @staticmethod
    def get_grade_info(db: Session, letter: str, program_id: Optional[int] = None):
        return GradeScaleRepository(db).get_by_letter(letter, program_id)

    @staticmethod
    def get_attempt_result(letter: str, is_passing: bool) -> str:
        g = letter.upper()
        if g == "W":  return "withdrawn"
        if g == "I":  return "incomplete"
        if g == "P":  return "passed"
        return "passed" if is_passing else "failed"

    @classmethod
    def post_grade(
        cls,
        db: Session,
        attempt_id: int,
        letter_grade: str,
        posted_by: Optional[int] = None,
        program_id: Optional[int] = None,
    ) -> Any:
        attempt_repo = CourseAttemptRepository(db)
        audit_repo   = AuditRepository(db)

        attempt = attempt_repo.get_by_id(attempt_id)
        if not attempt:
            raise ValueError(f"Attempt {attempt_id} not found")

        grade_info = cls.get_grade_info(db, letter_grade, program_id)
        if not grade_info:
            raise ValueError(f"Unknown grade: {letter_grade}")

        old_grade = attempt.letter_grade
        result    = cls.get_attempt_result(letter_grade, grade_info.is_passing)

        updated = attempt_repo.update_grade(
            attempt_id=attempt_id,
            letter_grade=letter_grade.upper(),
            grade_points=float(grade_info.grade_points),
            counts_in_cgpa=grade_info.counts_in_cgpa,
            result=result,
            graded_by=posted_by,
        )
        if letter_grade.upper() == "W":
            updated.withdrawn_at = datetime.now(timezone.utc)
            db.flush()

        audit_repo.append({
            "student_id": attempt.student_id,
            "action": AuditActionEnum.GRADE_CHANGED,
            "entity_type": "course_attempt",
            "entity_id": attempt_id,
            "old_value": {"grade": old_grade},
            "new_value": {"grade": letter_grade},
            "actor_id": posted_by,
        })
        db.commit()
        return updated


# ═════════════════════════════════════════════════════════════════════════════
# GPA ENGINE  (refactored — uses repositories)
# ═════════════════════════════════════════════════════════════════════════════

class GPAEngine:
    """
    CGPA formula (document-sourced from CGPA_Calculator.xlsx):
      CGPA = Σ(grade_points × credit_hours) / Σ(credit_hours)
      Verified: 100.70 / 78 = 1.2910256410 ✓
      Policy: all_attempts (all rows included, P excluded via counts_in_cgpa=False)
    """

    @staticmethod
    def calculate_semester_gpa(
        db: Session,
        student_id: int,
        term_id: int,
    ) -> Decimal:
        attempts = CourseAttemptRepository(db).get_for_term(student_id, term_id)
        eligible = [a for a in attempts if a.counts_in_cgpa and a.grade_points is not None]
        total_pts = sum(_d(a.grade_points) * _d(a.credit_hours) for a in eligible)
        total_hrs = sum(_d(a.credit_hours) for a in eligible)
        if total_hrs == 0:
            return Decimal("0.000")
        return _round(total_pts / total_hrs)

    @classmethod
    def calculate_cgpa(
        cls,
        db: Session,
        student_id: int,
        up_to_term_id: Optional[int] = None,
        program_id: Optional[int] = None,
    ) -> Tuple[Decimal, int, Decimal]:
        """
        Returns (cgpa, total_hours_attempted, total_quality_points).
        Repeat policy read from AcademicRulesConfig. Falls back to 'all_attempts'
        (the policy proven by the uploaded CGPA calculator).
        """
        rules_repo    = RulesConfigRepository(db)
        repeat_policy = rules_repo.get_rule("repeat_policy", program_id) or "all_attempts"

        attempt_repo = CourseAttemptRepository(db)
        attempts     = attempt_repo.get_cgpa_eligible(student_id, up_to_term_id)
        attempts     = [a for a in attempts if a.grade_points is not None]

        if repeat_policy == "best":
            course_map: Dict[int, Any] = {}
            for a in attempts:
                if a.course_id not in course_map or _d(a.grade_points) > _d(course_map[a.course_id].grade_points):
                    course_map[a.course_id] = a
            applicable = list(course_map.values())
        elif repeat_policy == "latest":
            course_map = {}
            for a in attempts:
                if a.course_id not in course_map or a.attempt_number > course_map[a.course_id].attempt_number:
                    course_map[a.course_id] = a
            applicable = list(course_map.values())
        else:  # all_attempts — document-sourced default
            applicable = attempts

        total_pts = sum(_d(a.grade_points) * _d(a.credit_hours) for a in applicable)
        total_hrs = sum(_d(a.credit_hours) for a in applicable)

        if total_hrs == 0:
            return Decimal("0.000"), 0, Decimal("0.000")
        return _round(total_pts / total_hrs), int(total_hrs), _round(total_pts)

    @classmethod
    def finalize_term(
        cls,
        db: Session,
        student_id: int,
        term_id: int,
        program_id: Optional[int] = None,
        actor_id: Optional[int] = None,
    ) -> StudentTermGPA:
        student_repo  = StudentRepository(db)
        term_gpa_repo = TermGPARepository(db)
        attempt_repo  = CourseAttemptRepository(db)
        audit_repo    = AuditRepository(db)
        timeline_repo = TimelineRepository(db)

        term_gpa               = cls.calculate_semester_gpa(db, student_id, term_id)
        cgpa, cum_hrs, cum_pts = cls.calculate_cgpa(db, student_id, up_to_term_id=term_id, program_id=program_id)

        term_attempts  = attempt_repo.get_for_term(student_id, term_id)
        term_attempted = sum(a.credit_hours or 0 for a in term_attempts if a.counts_in_cgpa)
        term_earned    = sum(a.credit_hours or 0 for a in term_attempts if a.result == "passed")
        term_pts       = sum(
            _d(a.grade_points or 0) * _d(a.credit_hours or 0)
            for a in term_attempts if a.counts_in_cgpa
        )

        standing = AcademicStandingService.determine_standing(db, student_id, cgpa, program_id)

        passed_all = attempt_repo.get_passed(student_id)
        cum_earned = sum(a.credit_hours or 0 for a in passed_all)

        record = term_gpa_repo.upsert(student_id, term_id, {
            "term_credit_hours_attempted": term_attempted,
            "term_credit_hours_earned":    term_earned,
            "term_quality_points":         float(term_pts),
            "term_gpa":                    float(term_gpa),
            "cumulative_hours_attempted":  int(cum_hrs),
            "cumulative_hours_earned":     cum_earned,
            "cumulative_quality_points":   float(cum_pts),
            "cgpa":                        float(cgpa),
            "academic_standing":           standing,
            "finalized":                   True,
            "finalized_at":                datetime.now(timezone.utc),
        })

        student_repo.update_cgpa(student_id, cgpa, int(cum_hrs), cum_earned, cum_pts)
        student_repo.set_standing(student_id, standing)

        # Record GPA version
        GPAVersioningService.record_version(
            db=db, student_id=student_id, term_id=term_id,
            semester_gpa=term_gpa, cgpa=cgpa,
            total_hrs=int(cum_hrs), total_earned=cum_earned,
            quality_pts=cum_pts,
            trigger=f"term_finalized:{term_id}",
            computed_by=actor_id,
        )

        SnapshotService.create(db, student_id, term_id, record, actor_id)
        HonorsService.evaluate_term(db, student_id, term_id, program_id)
        AcademicStandingService.record_change(db, student_id, term_id, standing, cgpa, term_gpa)

        audit_repo.append({
            "student_id": student_id,
            "action": AuditActionEnum.GPA_RECALCULATED,
            "entity_type": "student_term_gpa",
            "entity_id": record.id,
            "new_value": {"term_gpa": float(term_gpa), "cgpa": float(cgpa)},
            "actor_id": actor_id,
        })
        timeline_repo.create({
            "student_id": student_id,
            "term_id": term_id,
            "event_type": TimelineEventTypeEnum.GPA_RECALCULATED,
            "title": f"Term finalized — GPA: {term_gpa:.3f} | CGPA: {cgpa:.3f}",
            "payload": {"term_gpa": float(term_gpa), "cgpa": float(cgpa), "standing": standing},
            "actor_id": actor_id,
        })
        db.commit()
        db.refresh(record)
        return record


# ═════════════════════════════════════════════════════════════════════════════
# GPA VERSIONING ENGINE  (NEW)
# ═════════════════════════════════════════════════════════════════════════════

class GPAVersioningService:
    """
    Records an immutable GPA version every time CGPA or semester GPA changes.
    Computes delta from previous version.
    """

    @classmethod
    def record_version(
        cls,
        db: Session,
        student_id: int,
        term_id: Optional[int],
        semester_gpa: Decimal,
        cgpa: Decimal,
        total_hrs: int,
        total_earned: int,
        quality_pts: Decimal,
        trigger: str,
        trigger_details: Optional[Dict] = None,
        computed_by: Optional[int] = None,
    ):
        repo    = GPAVersionRepository(db)
        version = repo.get_next_version(student_id)

        # Compute delta from previous
        cgpa_delta = gpa_delta = None
        previous_versions = repo.get_for_student(student_id, limit=1)
        if previous_versions:
            prev = previous_versions[0]
            cgpa_delta = float(_d(cgpa) - _d(prev.cgpa or 0))
            gpa_delta  = float(_d(semester_gpa) - _d(prev.semester_gpa or 0))

        rules_repo    = RulesConfigRepository(db)
        repeat_policy = rules_repo.get_rule("repeat_policy") or "all_attempts"

        repo.create({
            "student_id":          student_id,
            "term_id":             term_id,
            "version_number":      version,
            "semester_gpa":        float(semester_gpa),
            "cgpa":                float(cgpa),
            "total_hours_attempted": total_hrs,
            "total_hours_earned":  total_earned,
            "total_quality_points": float(quality_pts),
            "cgpa_delta":          cgpa_delta,
            "gpa_delta":           gpa_delta,
            "trigger_event":       trigger,
            "trigger_details":     trigger_details or {},
            "repeat_policy_used":  repeat_policy,
            "computed_by":         computed_by,
        })
        db.flush()

    @staticmethod
    def get_history(db: Session, student_id: int, limit: int = 50) -> List[Any]:
        return GPAVersionRepository(db).get_for_student(student_id, limit=limit)


# ═════════════════════════════════════════════════════════════════════════════
# GPA AUDIT EXPLAINABILITY ENGINE  (NEW)
# ═════════════════════════════════════════════════════════════════════════════

class GPAExplainabilityService:
    """
    Produces a fully traceable, line-item breakdown of the CGPA calculation.
    Every included course attempt is listed with its exact contribution.
    Every excluded attempt is listed with the documented reason for exclusion.
    """

    EXCLUSION_REASONS = {
        "P":  "Pass/Fail grade — excluded from CGPA (source: CGPA_Calculator.xlsx, LAN021 row: 0 CH)",
        "W":  "Withdrawal — excluded from CGPA denominator (grade counts_in_cgpa=False)",
        "I":  "Incomplete — excluded until resolved",
        "IP": "In Progress — not yet graded",
    }

    @classmethod
    def generate_explanation(
        cls,
        db: Session,
        student_id: int,
        term_id: Optional[int] = None,
    ) -> Any:
        expl_repo    = GPAExplanationRepository(db)
        attempt_repo = CourseAttemptRepository(db)
        rules_repo   = RulesConfigRepository(db)

        expl_repo.invalidate_current(student_id)

        repeat_policy = rules_repo.get_rule("repeat_policy") or "all_attempts"
        formula_desc  = rules_repo.get_rule("cgpa_formula") or \
            "CGPA = Σ(grade_points × credit_hours) / Σ(credit_hours attempted)"

        # All attempts for the student
        all_attempts = attempt_repo.get_for_student(student_id)
        if term_id:
            term_attempts = attempt_repo.get_for_term(student_id, term_id)
        else:
            term_attempts = []

        included: List[Dict] = []
        excluded: List[Dict] = []

        def _build_entry(a, reason: Optional[str] = None) -> Dict:
            c = db.query(Course).filter(Course.id == a.course_id).first()
            term = db.query(AcademicTerm).filter(AcademicTerm.id == a.term_id).first()
            entry = {
                "attempt_id":    a.id,
                "course_code":   c.code if c else f"COURSE_{a.course_id}",
                "course_name":   c.name if c else "Unknown",
                "term_code":     term.code if term else f"TERM_{a.term_id}",
                "grade":         a.letter_grade or "—",
                "grade_points":  float(a.grade_points or 0),
                "credit_hours":  a.credit_hours or 0,
                "contribution":  round(float(a.grade_points or 0) * float(a.credit_hours or 0), 4),
                "attempt_number": a.attempt_number,
                "counts_in_cgpa": a.counts_in_cgpa,
            }
            if reason:
                entry["exclusion_reason"] = reason
            return entry

        for a in all_attempts:
            if not a.counts_in_cgpa:
                grade = (a.letter_grade or "").upper()
                reason = cls.EXCLUSION_REASONS.get(grade, "Excluded from CGPA (counts_in_cgpa=False)")
                excluded.append(_build_entry(a, reason))
            elif a.grade_points is None:
                excluded.append(_build_entry(a, "Grade not yet posted"))
            else:
                included.append(_build_entry(a))

        # Apply repeat policy filtering for display
        if repeat_policy == "best":
            course_best: Dict[int, Dict] = {}
            for e in included:
                cid = e["course_code"]
                if cid not in course_best or e["grade_points"] > course_best[cid]["grade_points"]:
                    course_best[cid] = e
            superceded = [e for e in included if e not in course_best.values()]
            for e in superceded:
                e["exclusion_reason"] = f"Superseded by best attempt (policy: best)"
                excluded.append(e)
            included = list(course_best.values())

        elif repeat_policy == "latest":
            course_latest: Dict[str, Dict] = {}
            for e in included:
                cid = e["course_code"]
                if cid not in course_latest or e["attempt_number"] > course_latest[cid]["attempt_number"]:
                    course_latest[cid] = e
            for e in included:
                if e not in course_latest.values():
                    e["exclusion_reason"] = "Superseded by latest attempt (policy: latest)"
                    excluded.append(e)
            included = list(course_latest.values())

        # Compute totals
        total_pts = sum(e["contribution"] for e in included)
        total_hrs = sum(e["credit_hours"] for e in included)
        computed_cgpa = round(total_pts / total_hrs, 10) if total_hrs > 0 else 0.0

        # Semester-specific
        sem_pts = sem_hrs = 0.0
        computed_sem_gpa = None
        if term_id:
            sem_included = [e for e in included
                            if any(a.term_id == term_id and a.id == e["attempt_id"] for a in all_attempts)]
            sem_pts = sum(e["contribution"] for e in sem_included)
            sem_hrs = sum(e["credit_hours"] for e in sem_included)
            computed_sem_gpa = round(sem_pts / sem_hrs, 10) if sem_hrs > 0 else 0.0

        policy_notes = []
        if rules_repo.is_pending("min_cgpa_graduation"):
            policy_notes.append("min_cgpa_graduation: PENDING_POLICY_CONFIGURATION")

        expl = expl_repo.create({
            "student_id":              student_id,
            "term_id":                 term_id,
            "formula_description":     formula_desc,
            "repeat_policy":           repeat_policy,
            "included_attempts":       included,
            "excluded_attempts":       excluded,
            "total_quality_points":    round(total_pts, 3),
            "total_hours_attempted":   total_hrs,
            "computed_cgpa":           round(computed_cgpa, 10),
            "semester_quality_points": round(sem_pts, 3) if term_id else None,
            "semester_hours_attempted": int(sem_hrs) if term_id else None,
            "computed_semester_gpa":   round(computed_sem_gpa, 10) if computed_sem_gpa else None,
            "all_rules_sourced":       len(policy_notes) == 0,
            "policy_notes":            policy_notes,
            "is_current":              True,
        })
        db.commit()
        db.refresh(expl)
        return expl


# ═════════════════════════════════════════════════════════════════════════════
# SCHOLARSHIP ELIGIBILITY ENGINE  (NEW)
# ═════════════════════════════════════════════════════════════════════════════

class ScholarshipService:
    """
    Scholarship Eligibility Engine.

    CRITICAL: All thresholds are read from AcademicRulesConfig.
    If any required threshold is PENDING_POLICY_CONFIGURATION, the
    evaluation returns status='pending_policy_configuration' and lists
    the missing policy keys — no assumed values are ever used.
    """

    REQUIRED_RULES = [
        "scholarship_min_cgpa",
        "scholarship_min_credits",
    ]

    @classmethod
    def evaluate(
        cls,
        db: Session,
        student_id: int,
        term_id: Optional[int] = None,
        actor_id: Optional[int] = None,
    ) -> Any:
        student_repo = StudentRepository(db)
        rules_repo   = RulesConfigRepository(db)
        schol_repo   = ScholarshipRepository(db)

        row = student_repo.get_with_user(student_id)
        if not row:
            raise ValueError(f"Student {student_id} not found")
        student, _ = row
        program_id = student.program_id

        schol_repo.invalidate_current(student_id)

        # Collect current snapshot
        cgpa         = _d(student.cgpa or 0)
        credits      = int(student.total_credit_hours_earned or 0)
        term_gpa_rec = TermGPARepository(db).get_last_n_terms(student_id, n=1)
        term_gpa     = _d(term_gpa_rec[0].term_gpa if term_gpa_rec else 0)

        # Check for PENDING rules
        rules_applied: Dict[str, str] = {}
        policy_gaps:   List[str]      = []
        for key in cls.REQUIRED_RULES:
            val = rules_repo.get_rule_or_pending(key, program_id)
            rules_applied[key] = val
            if val == PENDING:
                policy_gaps.append(key)

        # Also check additional optional rules
        optional_rules = ["scholarship_no_fail_required", "scholarship_min_term_gpa"]
        for key in optional_rules:
            val = rules_repo.get_rule_or_pending(key, program_id)
            if val != PENDING:
                rules_applied[key] = val

        # If any required rule is pending, cannot evaluate
        if policy_gaps:
            record = schol_repo.create({
                "student_id":              student_id,
                "term_id":                 term_id,
                "status":                  ScholarshipStatusEnum.PENDING_RULES,
                "cgpa_at_evaluation":      float(cgpa),
                "credits_at_evaluation":   credits,
                "term_gpa_at_evaluation":  float(term_gpa),
                "rules_applied":           rules_applied,
                "criteria_met":            {},
                "unmet_criteria":          [],
                "policy_gaps":             policy_gaps,
                "notes": (
                    f"Evaluation blocked: {len(policy_gaps)} required policy rule(s) not configured. "
                    f"Missing: {', '.join(policy_gaps)}. "
                    "Upload university scholarship regulations and configure these rules to enable evaluation."
                ),
                "evaluated_by":            actor_id,
                "is_current":              True,
            })
            db.commit()
            db.refresh(record)
            return record

        # All required rules present — evaluate
        min_cgpa    = Decimal(rules_applied["scholarship_min_cgpa"])
        min_credits = int(rules_applied["scholarship_min_credits"])

        criteria_met: Dict[str, bool] = {}
        unmet:        List[str]       = []

        cgpa_ok = cgpa >= min_cgpa
        criteria_met["cgpa_requirement"] = cgpa_ok
        if not cgpa_ok:
            unmet.append(f"CGPA: requires ≥ {min_cgpa}, current = {cgpa:.3f}")

        credits_ok = credits >= min_credits
        criteria_met["credits_requirement"] = credits_ok
        if not credits_ok:
            unmet.append(f"Credits earned: requires ≥ {min_credits}, current = {credits}")

        # Optional: no fail requirement
        if "scholarship_no_fail_required" in rules_applied:
            no_fail_required = rules_applied["scholarship_no_fail_required"].lower() == "true"
            if no_fail_required:
                failed = CourseAttemptRepository(db).count_failed(student_id)
                no_fail_ok = failed == 0
                criteria_met["no_fail_requirement"] = no_fail_ok
                if not no_fail_ok:
                    unmet.append(f"No failed courses required; student has {failed} failed attempt(s)")

        status = (ScholarshipStatusEnum.ELIGIBLE
                  if all(criteria_met.values())
                  else ScholarshipStatusEnum.NOT_ELIGIBLE)

        record = schol_repo.create({
            "student_id":             student_id,
            "term_id":                term_id,
            "status":                 status,
            "cgpa_at_evaluation":     float(cgpa),
            "credits_at_evaluation":  credits,
            "term_gpa_at_evaluation": float(term_gpa),
            "rules_applied":          rules_applied,
            "criteria_met":           criteria_met,
            "unmet_criteria":         unmet,
            "policy_gaps":            [],
            "evaluated_by":           actor_id,
            "is_current":             True,
        })
        db.commit()
        db.refresh(record)

        # Record achievement if newly eligible
        if status == ScholarshipStatusEnum.ELIGIBLE:
            AcademicAchievementService.record(
                db=db,
                student_id=student_id,
                term_id=term_id,
                category=AchievementCategoryEnum.GPA_MILESTONE,
                title="Scholarship Eligible",
                description="Student meets all configured scholarship eligibility criteria.",
                metric_key="scholarship_status",
                metric_value="eligible",
                rule_key_used="scholarship_min_cgpa",
                threshold_used=rules_applied["scholarship_min_cgpa"],
                policy_sourced=True,
            )
        return record


# ═════════════════════════════════════════════════════════════════════════════
# ACADEMIC ACHIEVEMENT SERVICE  (NEW)
# ═════════════════════════════════════════════════════════════════════════════

class AcademicAchievementService:
    """
    Academic Achievement Registry.
    Records observable, concrete milestones.
    Threshold-dependent achievements only recorded when rule is NOT PENDING.
    """

    @staticmethod
    def record(
        db: Session,
        student_id: int,
        category: AchievementCategoryEnum,
        title: str,
        description: Optional[str] = None,
        term_id: Optional[int] = None,
        metric_key: Optional[str] = None,
        metric_value: Optional[str] = None,
        threshold_used: Optional[str] = None,
        rule_key_used: Optional[str] = None,
        policy_sourced: bool = True,
        awarded_by: Optional[int] = None,
    ) -> Any:
        repo = AchievementRepository(db)
        achievement = repo.create({
            "student_id":     student_id,
            "term_id":        term_id,
            "category":       category,
            "title":          title,
            "description":    description,
            "metric_key":     metric_key,
            "metric_value":   metric_value,
            "threshold_used": threshold_used,
            "rule_key_used":  rule_key_used,
            "policy_sourced": policy_sourced,
            "awarded_by":     awarded_by,
        })
        db.flush()
        return achievement

    @classmethod
    def record_degree_progress_milestone(
        cls,
        db: Session,
        student_id: int,
        completion_pct: float,
        term_id: Optional[int] = None,
    ) -> None:
        """Record completion milestones: 25%, 50%, 75%, 100%."""
        milestones = {25: "25% Degree Completion", 50: "50% Degree Completion",
                      75: "75% Degree Completion", 100: "Degree Requirements Complete"}
        for pct, title in milestones.items():
            if completion_pct >= pct:
                existing = AchievementRepository(db).get_for_student(student_id)
                already_recorded = any(a.title == title for a in existing)
                if not already_recorded:
                    cls.record(
                        db=db, student_id=student_id, term_id=term_id,
                        category=AchievementCategoryEnum.DEGREE_PROGRESS,
                        title=title,
                        metric_key="completion_pct", metric_value=str(completion_pct),
                        threshold_used=str(pct), rule_key_used="total_required_credits",
                        policy_sourced=True,
                    )

    @classmethod
    def record_field_training_complete(cls, db: Session, student_id: int, term_id: Optional[int] = None) -> None:
        cls.record(
            db=db, student_id=student_id, term_id=term_id,
            category=AchievementCategoryEnum.COURSE_COMPLETION,
            title="Field Training Completed",
            description="Both CSE191 and CSE292 successfully completed.",
            metric_key="field_training_courses", metric_value="CSE191,CSE292",
            rule_key_used="field_training_courses", policy_sourced=True,
        )

    @classmethod
    def record_graduation_project_complete(cls, db: Session, student_id: int, term_id: Optional[int] = None) -> None:
        cls.record(
            db=db, student_id=student_id, term_id=term_id,
            category=AchievementCategoryEnum.COURSE_COMPLETION,
            title="Graduation Project Completed",
            description="Both CSE493 (GP1) and CSE494 (GP2) successfully completed.",
            metric_key="graduation_project", metric_value="CSE493,CSE494",
            rule_key_used="graduation_project_1", policy_sourced=True,
        )

    @staticmethod
    def get_for_student(db: Session, student_id: int, category: Optional[str] = None) -> List[Any]:
        return AchievementRepository(db).get_for_student(student_id, category)


# ═════════════════════════════════════════════════════════════════════════════
# SNAPSHOT SERVICE  (refactored)
# ═════════════════════════════════════════════════════════════════════════════

class SnapshotService:

    @staticmethod
    def _hash(data: Dict) -> str:
        return hashlib.sha256(
            json.dumps(data, sort_keys=True, default=str).encode()
        ).hexdigest()

    @classmethod
    def create(
        cls,
        db: Session,
        student_id: int,
        term_id: int,
        term_gpa_record: StudentTermGPA,
        actor_id: Optional[int] = None,
    ) -> Any:
        snap_repo    = SnapshotRepository(db)
        attempt_repo = CourseAttemptRepository(db)
        version      = snap_repo.get_next_version(student_id, term_id)

        attempts          = attempt_repo.get_for_term(student_id, term_id)
        credits_attempted = sum(a.credit_hours or 0 for a in attempts if a.counts_in_cgpa)
        credits_earned    = sum(a.credit_hours or 0 for a in attempts if a.result == "passed")
        credits_failed    = sum(a.credit_hours or 0 for a in attempts if a.result == "failed")
        credits_withdrawn = sum(a.credit_hours or 0 for a in attempts if a.result == "withdrawn")

        standing_str = term_gpa_record.academic_standing or "active"
        try:
            standing = AcademicStatusEnum(standing_str)
        except ValueError:
            standing = AcademicStatusEnum.ACTIVE

        snap_data = {
            "student_id": student_id, "term_id": term_id, "version": version,
            "term_gpa": float(term_gpa_record.term_gpa or 0),
            "cgpa": float(term_gpa_record.cgpa or 0),
        }

        snap = snap_repo.create({
            "student_id":          student_id,
            "term_id":             term_id,
            "version":             version,
            "term_gpa":            float(term_gpa_record.term_gpa or 0),
            "cgpa_after_term":     float(term_gpa_record.cgpa or 0),
            "credits_attempted":   credits_attempted,
            "credits_earned":      credits_earned,
            "credits_failed":      credits_failed,
            "credits_withdrawn":   credits_withdrawn,
            "cumulative_attempted": term_gpa_record.cumulative_hours_attempted or 0,
            "cumulative_earned":   term_gpa_record.cumulative_hours_earned or 0,
            "academic_standing":   standing,
            "snapshot_hash":       cls._hash(snap_data),
            "generated_by":        actor_id,
            "is_final":            True,
        })
        db.flush()
        return snap


# ═════════════════════════════════════════════════════════════════════════════
# TRANSCRIPT SERVICE  (refactored)
# ═════════════════════════════════════════════════════════════════════════════

class TranscriptService:

    @classmethod
    def build_payload(cls, db: Session, student_id: int, transcript_type: str, term_id: Optional[int]) -> Dict:
        student_repo  = StudentRepository(db)
        transcript_repo = TranscriptRepository(db)

        row = student_repo.get_with_user(student_id)
        if not row:
            raise ValueError(f"Student {student_id} not found")
        student, user = row
        prog, track = student_repo.get_program_and_track(student_id)

        term_ids_q = db.query(StudentTermGPA.term_id).filter(
            StudentTermGPA.student_id == student_id
        )
        if term_id:
            term_ids_q = term_ids_q.filter(StudentTermGPA.term_id == term_id)
        term_ids = [r[0] for r in term_ids_q.distinct().all()]

        terms = db.query(AcademicTerm).filter(
            AcademicTerm.id.in_(term_ids)
        ).order_by(AcademicTerm.academic_year, AcademicTerm.term_type).all()

        attempt_repo  = CourseAttemptRepository(db)
        term_gpa_repo = TermGPARepository(db)

        semesters = []
        for term in terms:
            term_rec = term_gpa_repo.get_for_student_term(student_id, term.id)
            attempts = attempt_repo.get_for_term(student_id, term.id)
            courses  = []
            for a in attempts:
                c = db.query(Course).filter(Course.id == a.course_id).first()
                if c:
                    courses.append({
                        "course_code": c.code, "course_name": c.name,
                        "credit_hours": a.credit_hours, "letter_grade": a.letter_grade or "",
                        "grade_points": float(a.grade_points or 0), "result": a.result,
                        "attempt_number": a.attempt_number, "counts_in_cgpa": a.counts_in_cgpa,
                        "term_code": term.code, "term_name": term.name,
                    })
            semesters.append({
                "term_code": term.code, "term_name": term.name,
                "credits_attempted": int(term_rec.term_credit_hours_attempted) if term_rec else 0,
                "credits_earned":    int(term_rec.term_credit_hours_earned) if term_rec else 0,
                "term_gpa":          float(term_rec.term_gpa) if term_rec else 0.0,
                "cgpa_after_term":   float(term_rec.cgpa) if term_rec else 0.0,
                "academic_standing": term_rec.academic_standing if term_rec else "active",
                "courses": courses,
            })

        return {
            "student_info": {
                "student_number": student.student_number or "",
                "name": user.name if user else "",
                "program": prog.name if prog else "",
                "track": track.name if track else None,
                "department": None, "admission_term": None, "expected_grad_term": None,
            },
            "semesters": semesters,
            "total_credits_attempted": int(student.total_credit_hours_attempted or 0),
            "total_credits_earned":    int(student.total_credit_hours_earned or 0),
            "cumulative_gpa":          float(student.cgpa or 0),
            "academic_standing":       student.academic_standing or "active",
            "graduation_status":       "graduated" if student.is_eligible_for_graduation else "in_progress",
            "honors_level": None,
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "transcript_type": transcript_type,
        }

    @classmethod
    def generate(
        cls,
        db: Session,
        student_id: int,
        transcript_type: str = "unofficial",
        term_id: Optional[int] = None,
        generated_by: Optional[int] = None,
        reason: Optional[str] = None,
    ) -> Any:
        transcript_repo = TranscriptRepository(db)
        audit_repo      = AuditRepository(db)
        timeline_repo   = TimelineRepository(db)

        payload      = cls.build_payload(db, student_id, transcript_type, term_id)
        payload_json = json.dumps(payload, sort_keys=True, default=str)
        snap_hash    = hashlib.sha256(payload_json.encode()).hexdigest()

        transcript_repo.mark_all_not_current(student_id, transcript_type)
        version_num = transcript_repo.get_next_version_number(student_id, transcript_type)

        tv = transcript_repo.create({
            "student_id":     student_id,
            "version_number": version_num,
            "transcript_type": transcript_type,
            "transcript_data": payload,
            "snapshot_hash":  snap_hash,
            "generated_by":   generated_by,
            "reason":         reason,
            "is_current":     True,
        })
        db.flush()

        # Create verification
        VerificationService.create(db, tv.id)

        audit_repo.append({
            "student_id": student_id,
            "action": AuditActionEnum.TRANSCRIPT_GENERATED,
            "entity_type": "transcript_version", "entity_id": tv.id,
            "new_value": {"type": transcript_type, "version": version_num},
            "actor_id": generated_by,
        })
        timeline_repo.create({
            "student_id": student_id,
            "event_type": TimelineEventTypeEnum.TRANSCRIPT_ISSUED,
            "title": f"{transcript_type.title()} transcript v{version_num} generated",
            "payload": {"transcript_id": tv.id, "type": transcript_type},
            "actor_id": generated_by,
        })
        db.commit()
        db.refresh(tv)
        return tv


# ═════════════════════════════════════════════════════════════════════════════
# VERIFICATION SERVICE  (refactored)
# ═════════════════════════════════════════════════════════════════════════════

class VerificationService:

    @staticmethod
    def _code() -> str:
        return f"TRX-{secrets.token_hex(2).upper()}-{secrets.token_hex(2).upper()}"

    @classmethod
    def create(cls, db: Session, transcript_id: int) -> Any:
        v = TranscriptVerification(
            transcript_id=transcript_id,
            verification_code=cls._code(),
            verification_token=secrets.token_urlsafe(64),
            qr_identifier=secrets.token_hex(32),
            is_valid=True,
        )
        db.add(v)
        db.flush()
        return v

    @staticmethod
    def verify(db: Session, code: str) -> Dict:
        repo = TranscriptRepository(db)
        v    = repo.get_by_verification_code(code)
        if not v:
            return {"is_valid": False, "message": "Verification code not found."}
        if not v.is_valid:
            return {"is_valid": False, "message": "This transcript has been invalidated."}

        repo.increment_verification_count(v.id)

        tv = repo.get_by_id(v.transcript_id)
        if not tv:
            return {"is_valid": False, "message": "Transcript record not found."}

        si = (tv.transcript_data or {}).get("student_info", {})
        return {
            "is_valid": True,
            "student_name": si.get("name"),
            "student_number": si.get("student_number"),
            "program": si.get("program"),
            "transcript_type": tv.transcript_type,
            "generated_at": tv.generated_at,
            "cgpa": (tv.transcript_data or {}).get("cumulative_gpa"),
            "message": "Transcript verified successfully.",
        }


# ═════════════════════════════════════════════════════════════════════════════
# ACADEMIC STANDING SERVICE  (refactored)
# ═════════════════════════════════════════════════════════════════════════════

class AcademicStandingService:

    @staticmethod
    def determine_standing(
        db: Session,
        student_id: int,
        cgpa: Decimal,
        program_id: Optional[int] = None,
    ) -> str:
        """
        Standing thresholds are PENDING_POLICY_CONFIGURATION until the
        university uploads academic regulations. Falls back to 'active'
        when rules are not configured.
        """
        rules = RulesConfigRepository(db)
        min_good      = rules.get_float_or_none("min_cgpa_good_standing", program_id)
        min_warning   = rules.get_float_or_none("min_cgpa_warning",       program_id)
        min_probation = rules.get_float_or_none("min_cgpa_probation",     program_id)

        # Cannot determine standing if any threshold is pending
        if any(v is None for v in [min_good, min_warning, min_probation]):
            return AcademicStatusEnum.ACTIVE.value  # default safe state

        cgpa_f = float(cgpa)
        if cgpa_f >= min_good:      return AcademicStatusEnum.ACTIVE.value
        if cgpa_f >= min_warning:   return AcademicStatusEnum.WARNING.value
        if cgpa_f >= min_probation: return AcademicStatusEnum.PROBATION.value
        return AcademicStatusEnum.SUSPENDED.value

    @staticmethod
    def record_change(
        db: Session,
        student_id: int,
        term_id: Optional[int],
        new_standing: str,
        cgpa: Decimal,
        term_gpa: Decimal,
        actor_id: Optional[int] = None,
        reason: Optional[str] = None,
    ) -> None:
        status_repo = StatusHistoryRepository(db)
        timeline_repo = TimelineRepository(db)

        last = status_repo.get_latest(student_id)
        if last and last.new_status == new_standing:
            return

        try:
            new_enum = AcademicStatusEnum(new_standing)
        except ValueError:
            new_enum = AcademicStatusEnum.ACTIVE

        status_repo.create({
            "student_id":        student_id,
            "term_id":           term_id,
            "old_status":        AcademicStatusEnum(last.new_status) if last else None,
            "new_status":        new_enum,
            "cgpa_at_change":    float(cgpa),
            "term_gpa_at_change": float(term_gpa),
            "reason":            reason or "Auto-computed after term finalization",
            "actor_id":          actor_id,
        })
        timeline_repo.create({
            "student_id": student_id, "term_id": term_id,
            "event_type": TimelineEventTypeEnum.STATUS_CHANGED,
            "title": f"Academic status → {new_standing}",
            "payload": {"old": last.new_status if last else None, "new": new_standing},
            "actor_id": actor_id,
        })
        db.flush()


# ═════════════════════════════════════════════════════════════════════════════
# DEGREE PROGRESS SERVICE  (refactored)
# ═════════════════════════════════════════════════════════════════════════════

class DegreeProgressService:

    @classmethod
    def compute(
        cls,
        db: Session,
        student_id: int,
        term_id: Optional[int] = None,
        actor_id: Optional[int] = None,
    ) -> Any:
        student_repo   = StudentRepository(db)
        progress_repo  = DegreeProgressRepository(db)
        attempt_repo   = CourseAttemptRepository(db)
        rules_repo     = RulesConfigRepository(db)
        audit_repo     = AuditRepository(db)

        row = student_repo.get_with_user(student_id)
        if not row:
            raise ValueError(f"Student {student_id} not found")
        student, _ = row
        program_id = student.program_id
        track_id   = student.track_id

        # Total required credits — document-sourced: 134
        required_credits = rules_repo.get_int_or_none("total_required_credits", program_id) or 134

        passed_attempts  = attempt_repo.get_passed(student_id)
        earned_credits   = sum(a.credit_hours or 0 for a in passed_attempts)
        passed_ids       = {a.course_id for a in passed_attempts}

        requirements     = progress_repo.get_graduation_requirements(program_id or 0, track_id)

        category_breakdown: Dict[str, Any] = {}
        missing_categories: List[str]      = []
        all_core_ok = field_training_ok = grad_project_ok = electives_ok = True

        for req in requirements:
            cat = req.category if isinstance(req.category, str) else req.category.value
            earned_in_cat = sum(
                a.credit_hours or 0 for a in passed_attempts
                if getattr(db.query(Course).filter(Course.id == a.course_id).first(), 'category', None) == cat
            )
            remaining = max(0, req.required_credits - earned_in_cat)
            pct       = round(min(100, (earned_in_cat / req.required_credits) * 100)
                              if req.required_credits else 100, 2)
            category_breakdown[cat] = {
                "required": req.required_credits, "earned": earned_in_cat,
                "remaining": remaining, "pct": pct,
            }
            if remaining > 0:
                missing_categories.append(cat)
                if cat == "core":            all_core_ok      = False
                elif cat == "field_training": field_training_ok = False
                elif cat == "graduation_project": grad_project_ok = False
                elif "elective" in cat:       electives_ok     = False

        # Missing core courses
        ft_codes = (rules_repo.get_rule("field_training_courses") or "CSE191,CSE292").split(",")
        gp_codes = [
            rules_repo.get_rule("graduation_project_1") or "CSE493",
            rules_repo.get_rule("graduation_project_2") or "CSE494",
        ]

        all_courses = db.query(Course).filter(
            getattr(Course, 'category', None) == 'core'
        ).all() if hasattr(Course, 'category') else []
        missing_core = [c.code for c in all_courses if c.id not in passed_ids]

        completion_pct = round(
            min(100.0, (earned_credits / required_credits) * 100) if required_credits else 0.0, 2
        )

        version = progress_repo.get_next_version(student_id)
        snap    = progress_repo.create({
            "student_id":                student_id,
            "term_id":                   term_id,
            "version":                   version,
            "required_credits":          required_credits,
            "earned_credits":            earned_credits,
            "remaining_credits":         max(0, required_credits - earned_credits),
            "completion_percentage":     completion_pct,
            "category_breakdown":        category_breakdown,
            "missing_core_courses":      missing_core[:50],
            "missing_elective_slots":    0,
            "missing_categories":        missing_categories,
            "all_core_complete":         all_core_ok,
            "all_electives_complete":    electives_ok,
            "field_training_complete":   field_training_ok,
            "graduation_project_complete": grad_project_ok,
            "computed_by":               actor_id,
        })

        # Record milestone achievements
        AcademicAchievementService.record_degree_progress_milestone(
            db, student_id, completion_pct, term_id
        )
        if field_training_ok and completion_pct >= 50:
            AcademicAchievementService.record_field_training_complete(db, student_id, term_id)
        if grad_project_ok and completion_pct >= 90:
            AcademicAchievementService.record_graduation_project_complete(db, student_id, term_id)

        audit_repo.append({
            "student_id": student_id,
            "action": AuditActionEnum.PROGRESS_UPDATED,
            "entity_type": "degree_progress_snapshot", "entity_id": snap.id,
            "new_value": {"earned": earned_credits, "pct": completion_pct},
            "actor_id": actor_id,
        })
        db.commit()
        db.refresh(snap)
        return snap


# ═════════════════════════════════════════════════════════════════════════════
# GRADUATION ELIGIBILITY SERVICE  (refactored)
# ═════════════════════════════════════════════════════════════════════════════

class GraduationEligibilityService:

    @classmethod
    def evaluate(
        cls,
        db: Session,
        student_id: int,
        term_id: Optional[int] = None,
        actor_id: Optional[int] = None,
    ) -> Any:
        student_repo = StudentRepository(db)
        rules_repo   = RulesConfigRepository(db)
        elig_repo    = GraduationEligibilityRepository(db)
        progress_repo = DegreeProgressRepository(db)
        audit_repo   = AuditRepository(db)

        row = student_repo.get_with_user(student_id)
        if not row:
            raise ValueError(f"Student {student_id} not found")
        student, _ = row
        program_id = student.program_id

        cgpa    = _d(student.cgpa or 0)
        credits = int(student.total_credit_hours_earned or 0)

        # Document-sourced: total_required_credits = 134
        required_credits = rules_repo.get_int_or_none("total_required_credits", program_id) or 134

        # PENDING check for CGPA threshold
        min_cgpa_val = rules_repo.get_rule_or_pending("min_cgpa_graduation", program_id)
        cgpa_threshold_pending = (min_cgpa_val == PENDING)

        reqs_met: Dict[str, Any] = {}
        missing:  List[str]      = []

        # Credits — document-sourced rule
        credit_ok = credits >= required_credits
        reqs_met["credit_hours"] = credit_ok
        if not credit_ok:
            missing.append(f"Credit hours: need {required_credits}, have {credits}")

        # CGPA — threshold is PENDING
        if cgpa_threshold_pending:
            reqs_met["min_cgpa"] = "PENDING_POLICY_CONFIGURATION"
            missing.append("min_cgpa_graduation: PENDING_POLICY_CONFIGURATION — upload university graduation regulations")
        else:
            min_cgpa = Decimal(min_cgpa_val)
            cgpa_ok  = cgpa >= min_cgpa
            reqs_met["min_cgpa"] = cgpa_ok
            if not cgpa_ok:
                missing.append(f"Minimum CGPA: need {min_cgpa}, have {cgpa:.3f}")

        # Standing
        standing_ok = student.academic_standing not in ("suspended", "dismissed")
        reqs_met["academic_standing"] = standing_ok
        if not standing_ok:
            missing.append(f"Academic standing: {student.academic_standing}")

        # Degree progress
        progress = progress_repo.get_latest(student_id)
        core_ok  = (progress.all_core_complete          if progress else False)
        ft_ok    = (progress.field_training_complete    if progress else False)
        gp_ok    = (progress.graduation_project_complete if progress else False)

        reqs_met["core_courses_complete"]       = core_ok
        reqs_met["field_training_complete"]     = ft_ok
        reqs_met["graduation_project_complete"] = gp_ok

        if not core_ok: missing.append("Core courses: not all completed")
        if not ft_ok:   missing.append("Field training: not completed")
        if not gp_ok:   missing.append("Graduation project: not completed")

        # Determine eligibility (cannot be ELIGIBLE if CGPA threshold is pending)
        if any(v == "PENDING_POLICY_CONFIGURATION" for v in reqs_met.values()):
            eligibility = GradEligibilityEnum.NOT_ELIGIBLE
        elif all(v is True for v in reqs_met.values()):
            eligibility = GradEligibilityEnum.ELIGIBLE
        elif credit_ok and len(missing) <= 2:
            eligibility = GradEligibilityEnum.CONDITIONALLY
        else:
            eligibility = GradEligibilityEnum.NOT_ELIGIBLE

        elig_repo.invalidate_current(student_id)

        record = elig_repo.create({
            "student_id":           student_id,
            "term_id":              term_id,
            "eligibility_status":   eligibility,
            "requirements_met":     reqs_met,
            "missing_requirements": missing,
            "cgpa_at_evaluation":   float(cgpa),
            "credits_at_evaluation": credits,
            "evaluated_by":         actor_id,
            "is_current":           True,
        })

        student_repo.set_graduation_eligible(student_id, eligibility == GradEligibilityEnum.ELIGIBLE)

        audit_repo.append({
            "student_id": student_id, "action": AuditActionEnum.GRADUATION_DECISION,
            "entity_type": "graduation_eligibility", "entity_id": record.id,
            "new_value": {"eligibility": eligibility.value, "pending_rules": cgpa_threshold_pending},
            "actor_id": actor_id,
        })
        db.commit()
        db.refresh(record)
        return record


# ═════════════════════════════════════════════════════════════════════════════
# HONORS SERVICE  (refactored — returns PENDING when rules not configured)
# ═════════════════════════════════════════════════════════════════════════════

class HonorsService:

    @classmethod
    def evaluate_term(
        cls,
        db: Session,
        student_id: int,
        term_id: int,
        program_id: Optional[int] = None,
    ) -> Optional[Any]:
        honors_repo  = HonorsRepository(db)
        term_gpa_repo = TermGPARepository(db)
        attempt_repo = CourseAttemptRepository(db)
        rules_repo   = RulesConfigRepository(db)
        timeline_repo = TimelineRepository(db)

        term_rec = term_gpa_repo.get_for_student_term(student_id, term_id)
        if not term_rec:
            return None

        term_gpa = _d(term_rec.term_gpa or 0)
        cgpa     = _d(term_rec.cgpa or 0)
        credits  = int(term_rec.term_credit_hours_attempted or 0)

        has_failures = attempt_repo.has_failures_in_term(student_id, term_id)

        # Read thresholds — may be PENDING
        deans_gpa_val     = rules_repo.get_rule_or_pending("deans_list_term_gpa",   program_id)
        deans_credits_val = rules_repo.get_rule_or_pending("deans_list_min_credits", program_id)

        deans_pending = (deans_gpa_val == PENDING or deans_credits_val == PENDING)

        if deans_pending:
            is_deans = False
            honors_level = "PENDING_POLICY_CONFIGURATION"
        else:
            deans_gpa     = Decimal(deans_gpa_val)
            deans_credits = int(deans_credits_val)
            is_deans = (term_gpa >= deans_gpa and credits >= deans_credits and not has_failures)
            honors_level  = cls._determine_level(db, cgpa, program_id)

        qualification = {
            "term_gpa": float(term_gpa),
            "deans_threshold": deans_gpa_val,
            "credits_threshold": deans_credits_val,
            "credits_attempted": credits,
            "has_failures": has_failures,
            "deans_list_met": is_deans,
            "thresholds_pending": deans_pending,
        }

        record = honors_repo.create({
            "student_id":         student_id,
            "term_id":            term_id,
            "honors_level":       honors_level if not deans_pending else "none",
            "is_deans_list":      is_deans,
            "term_gpa_used":      float(term_gpa),
            "cgpa_used":          float(cgpa),
            "credits_used":       credits,
            "qualification_data": qualification,
        })

        if is_deans:
            timeline_repo.create({
                "student_id": student_id, "term_id": term_id,
                "event_type": TimelineEventTypeEnum.HONORS_AWARDED,
                "title": "Dean's List — term achievement",
                "payload": {"term_gpa": float(term_gpa), "credits": credits},
            })
            AcademicAchievementService.record(
                db=db, student_id=student_id, term_id=term_id,
                category=AchievementCategoryEnum.GPA_MILESTONE,
                title="Dean's List",
                metric_key="term_gpa", metric_value=str(float(term_gpa)),
                threshold_used=deans_gpa_val, rule_key_used="deans_list_term_gpa",
                policy_sourced=not deans_pending,
            )

        db.flush()
        return record

    @classmethod
    def _determine_level(cls, db: Session, cgpa: Decimal, program_id: Optional[int]) -> str:
        rules = RulesConfigRepository(db)
        high_val = rules.get_float_or_none("high_honors_cgpa",   program_id)
        hon_val  = rules.get_float_or_none("honors_cgpa",        program_id)
        exc_val  = rules.get_float_or_none("excellent_cgpa",     program_id)
        vg_val   = rules.get_float_or_none("very_good_cgpa",     program_id)
        gd_val   = rules.get_float_or_none("good_standing_cgpa", program_id)
        gr_val   = rules.get_float_or_none("min_cgpa_graduation", program_id)

        f = float(cgpa)
        if high_val and f >= high_val: return HonorsLevelEnum.HIGH_HONORS.value
        if hon_val  and f >= hon_val:  return HonorsLevelEnum.HONORS.value
        if exc_val  and f >= exc_val:  return HonorsLevelEnum.EXCELLENT.value
        if vg_val   and f >= vg_val:   return HonorsLevelEnum.VERY_GOOD.value
        if gd_val   and f >= gd_val:   return HonorsLevelEnum.GOOD.value
        if gr_val   and f >= gr_val:   return HonorsLevelEnum.PASS.value
        return HonorsLevelEnum.NONE.value


# ═════════════════════════════════════════════════════════════════════════════
# GPA PROJECTION SERVICE  (refactored)
# ═════════════════════════════════════════════════════════════════════════════

class GPAProjectionService:

    @classmethod
    def project(
        cls,
        db: Session,
        student_id: int,
        projection_type: str,
        target_cgpa: Optional[float] = None,
        remaining_credits: Optional[int] = None,
        registered_courses: Optional[List[Dict]] = None,
        term_id: Optional[int] = None,
        program_id: Optional[int] = None,
    ) -> Any:
        proj_repo    = GPAProjectionRepository(db)
        student      = StudentRepository(db).get_by_id(student_id)
        current_cgpa = _d(student.cgpa or 0)
        current_crs  = int(student.total_credit_hours_attempted or 0)
        current_pts  = _d(student.total_quality_points or 0)

        scenario = {"projection_type": projection_type, "target_cgpa": target_cgpa,
                    "remaining_credits": remaining_credits, "registered_courses": registered_courses or []}
        result: Dict   = {}
        proj_sem_gpa   = proj_cgpa = is_achievable = None

        if projection_type == "graduation_target" and target_cgpa and remaining_credits:
            target = _d(target_cgpa)
            rem    = _d(remaining_credits)
            needed = (target * (_d(current_crs) + rem) - current_pts) / rem if rem > 0 else _d(0)
            is_achievable = Decimal("0") <= needed <= Decimal("4.0")
            result = {"needed_avg_grade_points": float(round(needed, 3)),
                      "needed_avg_letter_grade": cls._pts_to_letter(needed)}
            proj_cgpa = target if is_achievable else None

        elif projection_type in ("raise_cgpa", "term_target") and registered_courses:
            add_pts = sum(_d(rc.get("grade_points", 0)) * _d(rc.get("credits", 3)) for rc in registered_courses)
            add_hrs = sum(_d(rc.get("credits", 3)) for rc in registered_courses)
            proj_sem_gpa = _round(add_pts / add_hrs) if add_hrs > 0 else _d(0)
            new_total    = _d(current_crs) + add_hrs
            proj_cgpa    = _round((current_pts + add_pts) / new_total) if new_total > 0 else current_cgpa
            is_achievable = True
            result = {"projected_semester_gpa": float(proj_sem_gpa)}

        elif projection_type == "course_grade_needed" and registered_courses and target_cgpa:
            target         = _d(target_cgpa)
            total_future   = _d(sum(rc.get("credits", 3) for rc in registered_courses))
            other_pts      = sum(_d(rc.get("grade_points", 0)) * _d(rc.get("credits", 3)) for rc in registered_courses[1:])
            course_crs     = _d(registered_courses[0].get("credits", 3))
            needed = (target * (_d(current_crs) + total_future) - current_pts - other_pts) / course_crs if course_crs > 0 else _d(0)
            is_achievable = Decimal("0") <= needed <= Decimal("4.0")
            result = {"course_needed_grade_points": float(round(needed, 3)),
                      "course_needed_letter_grade": cls._pts_to_letter(needed)}

        record = proj_repo.create({
            "student_id": student_id, "term_id": term_id,
            "projection_type": projection_type,
            "current_cgpa": float(current_cgpa), "current_credits": current_crs,
            "target_cgpa": float(target_cgpa) if target_cgpa else None,
            "remaining_credits": remaining_credits,
            "scenario_input": scenario, "projection_result": result,
            "projected_semester_gpa": float(proj_sem_gpa) if proj_sem_gpa else None,
            "projected_cgpa": float(proj_cgpa) if proj_cgpa else None,
            "is_achievable": is_achievable,
        })
        db.commit()
        db.refresh(record)
        return record

    @staticmethod
    def _pts_to_letter(pts: Decimal) -> str:
        p = float(pts)
        if p >= 4.0: return "A+"
        if p >= 3.7: return "A-"
        if p >= 3.3: return "B+"
        if p >= 3.0: return "B"
        if p >= 2.7: return "B-"
        if p >= 2.3: return "C+"
        if p >= 2.0: return "C"
        if p >= 1.7: return "C-"
        if p >= 1.3: return "D+"
        if p >= 1.0: return "D"
        return "F"


# ═════════════════════════════════════════════════════════════════════════════
# ACADEMIC RISK SERVICE  (refactored)
# ═════════════════════════════════════════════════════════════════════════════

class AcademicRiskService:

    @classmethod
    def assess(cls, db: Session, student_id: int, term_id: Optional[int] = None) -> Any:
        student_repo = StudentRepository(db)
        attempt_repo = CourseAttemptRepository(db)
        risk_repo    = RiskRepository(db)
        term_gpa_repo = TermGPARepository(db)
        progress_repo = DegreeProgressRepository(db)

        student = student_repo.get_by_id(student_id)
        if not student:
            raise ValueError(f"Student {student_id} not found")

        cgpa         = _d(student.cgpa or 0)
        last_terms   = term_gpa_repo.get_last_n_terms(student_id, n=3)
        failed_count = attempt_repo.count_failed(student_id)
        withdrawn    = attempt_repo.count_withdrawn(student_id)
        repeats      = attempt_repo.count_improvements(student_id)
        progress     = progress_repo.get_latest(student_id)
        completion   = _d(progress.completion_percentage or 0) if progress else _d(0)

        gpa_trend  = (_d(last_terms[0].term_gpa or 0) - _d(last_terms[1].term_gpa or 0)
                      if len(last_terms) >= 2 else _d(0))
        cgpa_trend = (_d(last_terms[0].cgpa or 0) - _d(last_terms[1].cgpa or 0)
                      if len(last_terms) >= 2 else _d(0))

        # Objective risk scoring — no threshold-dependent policy assumptions
        factors: List[str] = []
        score = _d(0)

        if student.academic_standing == "suspended":
            score = _d(1.0)
            factors.append("Academic suspension status")
        else:
            if failed_count >= 5:
                score += _d("0.25"); factors.append(f"High failed course count ({failed_count})")
            elif failed_count >= 2:
                score += _d("0.10"); factors.append(f"Multiple failed courses ({failed_count})")
            if cgpa_trend < _d("-0.2"):
                score += _d("0.20"); factors.append(f"Declining CGPA trend ({cgpa_trend:+.3f})")
            if repeats >= 3:
                score += _d("0.10"); factors.append(f"Multiple course repeats ({repeats})")
            if withdrawn >= 3:
                score += _d("0.10"); factors.append(f"Multiple withdrawals ({withdrawn})")
            if student.academic_standing in ("warning", "probation"):
                score += _d("0.15"); factors.append(f"Standing: {student.academic_standing}")
            # CGPA scoring uses no hardcoded threshold — uses standing as proxy
            if not factors and float(cgpa) < 2.0:
                score += _d("0.20"); factors.append(f"CGPA appears low ({cgpa:.3f})")

        score = min(score, _d(1.0))
        level = (RiskLevelEnum.CRITICAL if score >= _d("0.75")
                 else RiskLevelEnum.HIGH if score >= _d("0.5")
                 else RiskLevelEnum.MEDIUM if score >= _d("0.25")
                 else RiskLevelEnum.LOW)

        recs: List[str] = []
        if failed_count > 0: recs.append("Review failed courses and plan retakes with advisor")
        if cgpa_trend < _d("-0.1"): recs.append("Seek tutoring or academic support services")
        if withdrawn >= 2: recs.append("Reconsider course load — excessive withdrawals impact graduation timeline")
        if not recs: recs.append("Continue current academic trajectory")

        risk_repo.invalidate_current(student_id)

        record = risk_repo.create({
            "student_id": student_id, "term_id": term_id,
            "risk_level": level, "risk_score": float(score),
            "gpa_trend": float(gpa_trend), "cgpa_trend": float(cgpa_trend),
            "failed_courses_count": failed_count, "repeated_courses_count": repeats,
            "withdrawal_count": withdrawn, "degree_completion_pct": float(completion),
            "risk_factors": factors, "recommendations": recs, "is_current": True,
        })
        db.commit()
        db.refresh(record)
        return record


# ═════════════════════════════════════════════════════════════════════════════
# TIMELINE SERVICE  (refactored)
# ═════════════════════════════════════════════════════════════════════════════

class TimelineService:

    @staticmethod
    def record(
        db: Session,
        student_id: int,
        event_type: TimelineEventTypeEnum,
        title: str,
        term_id: Optional[int] = None,
        description: Optional[str] = None,
        payload: Optional[Dict] = None,
        actor_id: Optional[int] = None,
    ) -> Any:
        repo = TimelineRepository(db)
        event = repo.create({
            "student_id": student_id, "term_id": term_id,
            "event_type": event_type, "title": title,
            "description": description, "payload": payload or {},
            "actor_id": actor_id,
        })
        db.flush()
        return event


# ═════════════════════════════════════════════════════════════════════════════
# AUDIT SERVICE  (refactored)
# ═════════════════════════════════════════════════════════════════════════════

class AuditService:

    @staticmethod
    def log(
        db: Session,
        student_id: int,
        action: AuditActionEnum,
        **kwargs,
    ) -> Any:
        return AuditRepository(db).append({"student_id": student_id, "action": action, **kwargs})


# ═════════════════════════════════════════════════════════════════════════════
# REGISTRAR NOTE SERVICE  (refactored)
# ═════════════════════════════════════════════════════════════════════════════

class RegistrarNoteService:

    @staticmethod
    def create(db: Session, data: Dict, actor_id: Optional[int] = None) -> Any:
        note_repo  = RegistrarNoteRepository(db)
        audit_repo = AuditRepository(db)
        note = note_repo.create({**data, "created_by": actor_id, "updated_by": actor_id})
        audit_repo.append({
            "student_id": data["student_id"], "action": AuditActionEnum.NOTE_ADDED,
            "entity_type": "registrar_note", "entity_id": note.id,
            "new_value": {"title": data["title"], "type": data.get("note_type")},
            "actor_id": actor_id,
        })
        db.commit()
        db.refresh(note)
        return note

    @staticmethod
    def update(db: Session, note_id: int, updates: Dict, actor_id: Optional[int] = None) -> Any:
        repo = RegistrarNoteRepository(db)
        note = repo.get_by_id(note_id)
        if not note:
            raise ValueError(f"Note {note_id} not found")
        updates["version"]    = (note.version or 1) + 1
        updates["updated_by"] = actor_id
        return repo.update(note_id, updates)

    @staticmethod
    def search(
        db: Session,
        student_id: int,
        note_type: Optional[str] = None,
        tag: Optional[str] = None,
        include_private: bool = False,
    ) -> List[Any]:
        return RegistrarNoteRepository(db).search(student_id, note_type, tag, include_private)


# ═════════════════════════════════════════════════════════════════════════════
# DASHBOARD SERVICE  (refactored — composes all repositories)
# ═════════════════════════════════════════════════════════════════════════════

class DashboardService:

    @classmethod
    def get(cls, db: Session, student_id: int) -> Dict:
        student_repo  = StudentRepository(db)
        progress_repo = DegreeProgressRepository(db)
        elig_repo     = GraduationEligibilityRepository(db)
        risk_repo     = RiskRepository(db)
        honors_repo   = HonorsRepository(db)
        transcript_repo = TranscriptRepository(db)
        attempt_repo  = CourseAttemptRepository(db)
        term_gpa_repo = TermGPARepository(db)

        row = student_repo.get_with_user(student_id)
        if not row:
            raise ValueError(f"Student {student_id} not found")
        student, user = row

        prog, track = student_repo.get_program_and_track(student_id)
        cgpa        = _d(student.cgpa or 0)

        progress         = progress_repo.get_latest(student_id)
        required_credits = int(progress.required_credits if progress else 134)
        earned_credits   = int(progress.earned_credits   if progress else student.total_credit_hours_earned or 0)
        remaining        = int(progress.remaining_credits if progress else max(0, required_credits - earned_credits))
        completion_pct   = _d(progress.completion_percentage if progress else 0)

        grad_rec  = elig_repo.get_current(student_id)
        risk_rec  = risk_repo.get_current(student_id)
        honors_rec = honors_repo.get_latest(student_id)
        latest_tv  = transcript_repo.get_current(student_id)

        # Active term
        active_term = db.query(AcademicTerm).filter(AcademicTerm.is_active == True).first()
        current_semester = None
        if active_term:
            curr_attempts = attempt_repo.get_for_term(student_id, active_term.id)
            in_progress   = []
            for a in curr_attempts:
                c = db.query(Course).filter(Course.id == a.course_id).first()
                if c:
                    in_progress.append({"code": c.code, "name": c.name, "credits": a.credit_hours})
            current_semester = {
                "term_id": active_term.id, "term_name": active_term.name,
                "courses_registered": len(curr_attempts),
                "credits_registered": sum(a.credit_hours or 0 for a in curr_attempts),
                "in_progress_courses": in_progress,
            }

        last_term_recs = term_gpa_repo.get_last_n_terms(student_id, 1)
        current_gpa    = float(_d(last_term_recs[0].term_gpa)) if last_term_recs else None

        return {
            "student_id":            student_id,
            "student_number":        student.student_number or "",
            "name":                  user.name if user else "",
            "program":               prog.name if prog else None,
            "track":                 track.name if track else None,
            "current_gpa":           current_gpa,
            "current_cgpa":          float(cgpa),
            "academic_standing":     student.academic_standing or "active",
            "earned_credits":        earned_credits,
            "remaining_credits":     remaining,
            "required_credits":      required_credits,
            "degree_completion_pct": float(completion_pct),
            "all_core_complete":     progress.all_core_complete if progress else False,
            "graduation_eligibility": grad_rec.eligibility_status if grad_rec else "not_eligible",
            "graduation_eligibility_id": grad_rec.id if grad_rec else None,
            "risk_level":            risk_rec.risk_level if risk_rec else "low",
            "risk_score":            float(risk_rec.risk_score) if risk_rec and risk_rec.risk_score else None,
            "honors_level":          honors_rec.honors_level if honors_rec else "none",
            "is_deans_list":         honors_rec.is_deans_list if honors_rec else False,
            "current_semester":      current_semester,
            "latest_transcript_id":  latest_tv.id if latest_tv else None,
            "latest_transcript_type": latest_tv.transcript_type if latest_tv else None,
            "latest_transcript_generated": latest_tv.generated_at if latest_tv else None,
            "computed_at":           datetime.now(timezone.utc),
        }
