"""
EduGuard AI — Sprint 3: Reconciliation Engine
File: backend/app/services/sprint3_reconciliation.py

Detects:
  - Duplicate entities: same natural key already exists in the DB
  - Conflicts: same natural key but differing field values
  - Mismatches: related entity references don't align

Generates a ReconciliationReport with granular ReconciliationItems.
"""

from __future__ import annotations

import logging
from typing import Any, Dict, List, Optional, Tuple

from sqlalchemy.orm import Session

from app.models.models import Course, Student
from app.models.sprint3_models import (
    ImportBatch,
    ReconciliationItem,
    ReconciliationReport,
    ReconciliationStatusEnum,
    ReconciliationTypeEnum,
    ImportTypeEnum,
)

logger = logging.getLogger(__name__)


# ── Helpers ───────────────────────────────────────────────────────────────────

def _diff_fields(incoming: Dict, existing: Dict, fields: List[str]) -> List[str]:
    """Return list of field names where incoming and existing values differ."""
    diffs = []
    for f in fields:
        iv = str(incoming.get(f, "") or "").strip().lower()
        ev = str(existing.get(f, "") or "").strip().lower()
        if iv and ev and iv != ev:
            diffs.append(f)
    return diffs


def _student_to_dict(s: Student) -> Dict[str, Any]:
    return {
        "student_code":     s.student_id or "",
        "full_name":        getattr(s, "full_name", "") or "",
        "university_email": s.email or "",
        "academic_status":  str(getattr(s, "academic_status", "") or ""),
    }


def _course_to_dict(c: Course) -> Dict[str, Any]:
    return {
        "course_code":  c.code or "",
        "course_name":  c.name or "",
        "credit_hours": str(c.credit_hours or ""),
    }


# ── Per-import-type reconciliation ────────────────────────────────────────────

def reconcile_students(
    db: Session,
    rows: List[Dict[str, Any]],
    report: ReconciliationReport,
) -> None:
    checked = 0
    duplicates = 0
    conflicts = 0

    for row in rows:
        code = str(row.get("student_code", "")).strip()
        if not code:
            continue
        checked += 1

        existing_student = (
            db.query(Student)
            .filter(Student.student_id == code)
            .first()
        )

        if existing_student is None:
            # New student — no reconciliation needed
            continue

        # Exists — check for conflicts
        existing_dict = _student_to_dict(existing_student)
        compare_fields = ["full_name", "university_email", "academic_status"]
        diff = _diff_fields(row, existing_dict, compare_fields)

        if diff:
            conflicts += 1
            item = ReconciliationItem(
                report_id=report.id,
                recon_type=ReconciliationTypeEnum.CONFLICT,
                entity_type="student",
                entity_key=code,
                incoming_value={f: row.get(f) for f in compare_fields},
                existing_value={f: existing_dict.get(f) for f in compare_fields},
                conflict_fields=diff,
                status=ReconciliationStatusEnum.OPEN,
            )
            db.add(item)
        else:
            duplicates += 1
            item = ReconciliationItem(
                report_id=report.id,
                recon_type=ReconciliationTypeEnum.DUPLICATE,
                entity_type="student",
                entity_key=code,
                incoming_value={"student_code": code},
                existing_value={"student_code": code},
                conflict_fields=[],
                status=ReconciliationStatusEnum.OPEN,
            )
            db.add(item)

    report.total_checked    = checked
    report.duplicates_found = duplicates
    report.conflicts_found  = conflicts


def reconcile_transcripts(
    db: Session,
    rows: List[Dict[str, Any]],
    report: ReconciliationReport,
) -> None:
    from app.models.academic_models import StudentCourseAttempt, AcademicTerm

    checked = 0
    duplicates = 0
    conflicts = 0

    for row in rows:
        s_code  = str(row.get("student_code", "")).strip()
        c_code  = str(row.get("course_code",  "")).strip().upper()
        attempt = str(row.get("attempt_number", "1")).strip()
        if not (s_code and c_code):
            continue
        checked += 1

        # Look up student + course IDs
        student = db.query(Student).filter(Student.student_id == s_code).first()
        course  = db.query(Course).filter(Course.code == c_code).first()
        if not (student and course):
            continue

        try:
            attempt_num = int(attempt)
        except ValueError:
            attempt_num = 1

        existing_attempt = (
            db.query(StudentCourseAttempt)
            .filter(
                StudentCourseAttempt.student_id == student.id,
                StudentCourseAttempt.course_id  == course.id,
                StudentCourseAttempt.attempt_number == attempt_num,
            )
            .first()
        )

        if existing_attempt is None:
            continue

        # Conflict: same attempt, different grade
        incoming_grade = str(row.get("grade", "") or "").upper()
        existing_grade = str(existing_attempt.grade or "").upper()
        if incoming_grade and existing_grade and incoming_grade != existing_grade:
            conflicts += 1
            item = ReconciliationItem(
                report_id=report.id,
                recon_type=ReconciliationTypeEnum.CONFLICT,
                entity_type="course_attempt",
                entity_key=f"{s_code}|{c_code}|{attempt}",
                incoming_value={"grade": incoming_grade},
                existing_value={"grade": existing_grade},
                conflict_fields=["grade"],
                status=ReconciliationStatusEnum.OPEN,
            )
            db.add(item)
        else:
            duplicates += 1
            item = ReconciliationItem(
                report_id=report.id,
                recon_type=ReconciliationTypeEnum.DUPLICATE,
                entity_type="course_attempt",
                entity_key=f"{s_code}|{c_code}|{attempt}",
                incoming_value={},
                existing_value={},
                conflict_fields=[],
                status=ReconciliationStatusEnum.OPEN,
            )
            db.add(item)

    report.total_checked    = checked
    report.duplicates_found = duplicates
    report.conflicts_found  = conflicts


def reconcile_curriculum(
    db: Session,
    rows: List[Dict[str, Any]],
    report: ReconciliationReport,
) -> None:
    checked = 0
    duplicates = 0
    conflicts = 0
    mismatches = 0

    for row in rows:
        code = str(row.get("course_code", "")).strip().upper()
        if not code:
            continue
        checked += 1

        existing_course = db.query(Course).filter(Course.code == code).first()
        if existing_course is None:
            continue

        existing_dict = _course_to_dict(existing_course)
        compare_fields = ["course_name", "credit_hours"]
        diff = _diff_fields(row, existing_dict, compare_fields)

        if diff:
            conflicts += 1
            item = ReconciliationItem(
                report_id=report.id,
                recon_type=ReconciliationTypeEnum.CONFLICT,
                entity_type="course",
                entity_key=code,
                incoming_value={f: row.get(f) for f in compare_fields},
                existing_value={f: existing_dict.get(f) for f in compare_fields},
                conflict_fields=diff,
                status=ReconciliationStatusEnum.OPEN,
            )
            db.add(item)
        else:
            duplicates += 1
            item = ReconciliationItem(
                report_id=report.id,
                recon_type=ReconciliationTypeEnum.DUPLICATE,
                entity_type="course",
                entity_key=code,
                incoming_value={"course_code": code},
                existing_value={"course_code": code},
                conflict_fields=[],
                status=ReconciliationStatusEnum.OPEN,
            )
            db.add(item)

    report.total_checked    = checked
    report.duplicates_found = duplicates
    report.conflicts_found  = conflicts
    report.mismatches_found = mismatches


# ── Main reconciliation entry point ──────────────────────────────────────────

def run_reconciliation(
    db: Session,
    batch: ImportBatch,
    rows: List[Dict[str, Any]],
    import_type: str,
) -> ReconciliationReport:
    """
    Run reconciliation for the batch.  Creates and persists the report + items.
    Returns the persisted ReconciliationReport.
    """
    report = ReconciliationReport(
        batch_id=batch.id,
        import_type=ImportTypeEnum(import_type),
        total_checked=0,
        duplicates_found=0,
        conflicts_found=0,
        mismatches_found=0,
    )
    db.add(report)
    db.flush()  # get report.id

    if import_type == "students":
        reconcile_students(db, rows, report)
    elif import_type == "transcripts":
        reconcile_transcripts(db, rows, report)
    elif import_type == "curriculum":
        reconcile_curriculum(db, rows, report)

    report.summary = {
        "total_checked":    report.total_checked,
        "duplicates_found": report.duplicates_found,
        "conflicts_found":  report.conflicts_found,
        "mismatches_found": report.mismatches_found,
        "action_required":  report.conflicts_found > 0,
    }

    db.commit()
    db.refresh(report)

    logger.info(
        "Reconciliation complete for batch %s: %d checked, %d duplicates, %d conflicts",
        batch.batch_ref,
        report.total_checked,
        report.duplicates_found,
        report.conflicts_found,
    )

    return report
