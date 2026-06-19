"""
EduGuard AI — Sprint 3: Import Engine
File: backend/app/services/sprint3_import_engine.py

Responsibilities:
  - Parse uploaded files (CSV / XLSX / JSON) into row dicts
  - Detect file format from content + extension
  - Hash files for idempotency
  - Coordinate the full import pipeline:
      parse → apply mapping → validate → reconcile → persist → audit
  - Support partial failure: commit good rows, record bad rows
  - Bulk insert for performance (no N+1 writes)

Schema alignment (exact column names from models.py / academic_models.py):
  Student:              student_number, user_id(nullable via import), major, year
  Course:               code, name, credits, category, program_id
  StudentCourseAttempt: student_id(FK students.id), course_id, term_id,
                        attempt_number, letter_grade, grade_points, credit_hours, result
"""

from __future__ import annotations

import csv
import hashlib
import io
import json
import logging
import time
import uuid
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Set, Tuple

import openpyxl
from sqlalchemy.orm import Session

from app.models.models import Course, Student, User
from app.models.academic_models import (
    AcademicProgram,
    AcademicTerm,
    AcademicTrack,
    StudentCourseAttempt,
    AttemptResultEnum,
)
from app.models.sprint3_models import (
    AuditEventTypeEnum,
    BatchStatusEnum,
    FileFormatEnum,
    ImportAuditEvent,
    ImportBatch,
    ImportRowError,
    ImportTypeEnum,
    SourceSystemEnum,
    ValidationSeverityEnum,
)
from app.services.sprint3_mapping import apply_mapping, get_current_version
from app.services.sprint3_validation import run_validation
from app.services.sprint3_reconciliation import run_reconciliation

logger = logging.getLogger(__name__)


# ── File parsing ──────────────────────────────────────────────────────────────

def compute_file_hash(content: bytes) -> str:
    return hashlib.sha256(content).hexdigest()


def detect_format(filename: str, content: bytes) -> FileFormatEnum:
    fname = filename.lower()
    if fname.endswith(".csv"):
        return FileFormatEnum.CSV
    if fname.endswith((".xlsx", ".xls")):
        return FileFormatEnum.XLSX
    if fname.endswith(".json"):
        return FileFormatEnum.JSON
    try:
        text = content[:512].decode("utf-8", errors="ignore").strip()
        if text.startswith("[") or text.startswith("{"):
            return FileFormatEnum.JSON
        if b"," in content[:512]:
            return FileFormatEnum.CSV
    except Exception:
        pass
    return FileFormatEnum.CSV


def parse_csv(content: bytes) -> List[Dict[str, Any]]:
    text = content.decode("utf-8-sig", errors="replace")
    reader = csv.DictReader(io.StringIO(text))
    return [dict(row) for row in reader]


def parse_xlsx(content: bytes) -> List[Dict[str, Any]]:
    wb = openpyxl.load_workbook(io.BytesIO(content), read_only=True, data_only=True)
    ws = wb.active
    rows = list(ws.iter_rows(values_only=True))
    if not rows:
        return []
    headers = [
        str(h).strip() if h is not None else f"col_{i}"
        for i, h in enumerate(rows[0])
    ]
    result = []
    for row in rows[1:]:
        if all(v is None for v in row):
            continue
        result.append({headers[i]: row[i] for i in range(len(headers))})
    return result


def parse_json(content: bytes) -> List[Dict[str, Any]]:
    text = content.decode("utf-8", errors="replace")
    data = json.loads(text)
    if isinstance(data, list):
        return data
    if isinstance(data, dict):
        for key in ("data", "records", "students", "transcripts", "courses"):
            if key in data and isinstance(data[key], list):
                return data[key]
        return [data]
    return []


def parse_file(filename: str, content: bytes, fmt: FileFormatEnum) -> List[Dict[str, Any]]:
    if fmt == FileFormatEnum.CSV:
        return parse_csv(content)
    elif fmt == FileFormatEnum.XLSX:
        return parse_xlsx(content)
    elif fmt == FileFormatEnum.JSON:
        return parse_json(content)
    return parse_csv(content)


# ── Audit helpers ─────────────────────────────────────────────────────────────

def _emit_audit(
    db: Session,
    batch_id: int,
    event_type: AuditEventTypeEnum,
    actor_id: Optional[int] = None,
    row_number: Optional[int] = None,
    message: Optional[str] = None,
    payload: Optional[Dict] = None,
    flush: bool = False,
) -> None:
    ev = ImportAuditEvent(
        batch_id=batch_id,
        event_type=event_type,
        actor_id=actor_id,
        row_number=row_number,
        message=message,
        payload=payload,
    )
    db.add(ev)
    if flush:
        db.flush()


# ── Per-type row persisters ────────────────────────────────────────────────────

def _upsert_student_rows(
    db: Session,
    rows: List[Dict],
    valid_row_numbers: Set[int],
) -> Tuple[int, int]:
    """
    Insert new Students.
    Student model: student_number (unique), major, year, program_id, track_id.
    No user_id required for import — creates Student without User link.
    Returns (inserted, skipped).
    """
    inserted = 0
    skipped  = 0

    existing = {
        r[0]
        for r in db.query(Student.student_number).all()
        if r[0]
    }

    program_map = {
        r[0].lower(): r[1]
        for r in db.query(AcademicProgram.name, AcademicProgram.id).all()
        if r[0]
    }
    track_map = {
        r[0].lower(): r[1]
        for r in db.query(AcademicTrack.name, AcademicTrack.id).all()
        if r[0]
    }

    new_students: List[Student] = []
    for idx, row in enumerate(rows, start=1):
        if idx not in valid_row_numbers:
            skipped += 1
            continue

        code = str(row.get("student_code", "") or "").strip()
        if not code or code in existing:
            skipped += 1
            continue
        existing.add(code)

        prog_name  = str(row.get("program_name", "") or "").strip().lower()
        track_name = str(row.get("track_name",   "") or "").strip().lower()
        prog_id    = program_map.get(prog_name)
        track_id   = track_map.get(track_name)

        try:
            year_val = int(row.get("enrollment_year") or 0) or None
        except (ValueError, TypeError):
            year_val = None

        major_val = str(row.get("program_name", "") or row.get("major", "") or "").strip() or None

        s = Student(
            student_number=code,
            major=major_val,
            year=year_val,
            program_id=prog_id,
            track_id=track_id,
        )
        new_students.append(s)
        inserted += 1

    if new_students:
        db.bulk_save_objects(new_students)
        db.flush()

    return inserted, skipped


def _upsert_transcript_rows(
    db: Session,
    rows: List[Dict],
    valid_row_numbers: Set[int],
) -> Tuple[int, int]:
    """
    Insert new StudentCourseAttempts.
    Uses: student_id (FK), course_id (FK), term_id (FK, required), attempt_number,
          letter_grade, grade_points, credit_hours, result.
    Returns (inserted, skipped).
    """
    inserted = 0
    skipped  = 0

    student_map = {
        r[0]: r[1]
        for r in db.query(Student.student_number, Student.id).all()
        if r[0]
    }
    course_map = {
        r[0].upper(): r[1]
        for r in db.query(Course.code, Course.id).all()
        if r[0]
    }
    term_map = {
        r[0].lower(): r[1]
        for r in db.query(AcademicTerm.name, AcademicTerm.id).all()
        if r[0]
    }

    # Get or create a fallback term for imports without term info
    default_term_id: Optional[int] = None
    if term_map:
        default_term_id = next(iter(term_map.values()))

    new_attempts: List[StudentCourseAttempt] = []
    for idx, row in enumerate(rows, start=1):
        if idx not in valid_row_numbers:
            skipped += 1
            continue

        s_code = str(row.get("student_code", "") or "").strip()
        c_code = str(row.get("course_code",  "") or "").strip().upper()
        s_id   = student_map.get(s_code)
        c_id   = course_map.get(c_code)

        if not (s_id and c_id):
            skipped += 1
            continue

        term_name = str(row.get("term_name", "") or "").strip().lower()
        term_id   = term_map.get(term_name) or default_term_id
        if not term_id:
            skipped += 1
            continue

        try:
            attempt_num = int(row.get("attempt_number", 1) or 1)
        except (ValueError, TypeError):
            attempt_num = 1

        exists = (
            db.query(StudentCourseAttempt.id)
            .filter(
                StudentCourseAttempt.student_id     == s_id,
                StudentCourseAttempt.course_id      == c_id,
                StudentCourseAttempt.attempt_number == attempt_num,
            )
            .first()
        )
        if exists:
            skipped += 1
            continue

        grade = str(row.get("grade", "") or "").upper() or None
        try:
            gp = float(row.get("grade_points") or 0)
        except (ValueError, TypeError):
            gp = 0.0
        try:
            ch = int(float(row.get("credit_hours") or 3))
        except (ValueError, TypeError):
            ch = 3

        if grade in ("F", "W", "WF"):
            result = AttemptResultEnum.FAILED
        elif grade == "W":
            result = AttemptResultEnum.WITHDRAWN
        elif grade == "I":
            result = AttemptResultEnum.INCOMPLETE
        elif grade:
            result = AttemptResultEnum.PASSED
        else:
            result = AttemptResultEnum.IN_PROGRESS

        attempt = StudentCourseAttempt(
            student_id=s_id,
            course_id=c_id,
            term_id=term_id,
            attempt_number=attempt_num,
            letter_grade=grade,
            grade_points=gp,
            credit_hours=ch,
            result=result,
        )
        new_attempts.append(attempt)
        inserted += 1

    if new_attempts:
        db.bulk_save_objects(new_attempts)
        db.flush()

    return inserted, skipped


def _upsert_curriculum_rows(
    db: Session,
    rows: List[Dict],
    valid_row_numbers: Set[int],
) -> Tuple[int, int]:
    """
    Insert new Courses from curriculum import.
    Course model: code, name, credits, category, program_id.
    Returns (inserted, skipped).
    """
    inserted = 0
    skipped  = 0

    existing = {
        r[0].upper()
        for r in db.query(Course.code).all()
        if r[0]
    }
    program_map = {
        r[0].lower(): r[1]
        for r in db.query(AcademicProgram.name, AcademicProgram.id).all()
        if r[0]
    }

    new_courses: List[Course] = []
    for idx, row in enumerate(rows, start=1):
        if idx not in valid_row_numbers:
            skipped += 1
            continue

        code = str(row.get("course_code", "") or "").strip().upper()
        if not code or code in existing:
            skipped += 1
            continue
        existing.add(code)

        name = str(row.get("course_name", "") or "").strip()
        try:
            credits_val = int(float(row.get("credit_hours") or 3))
        except (ValueError, TypeError):
            credits_val = 3

        category  = str(row.get("category", "core") or "core").strip().lower()
        prog_name = str(row.get("program_name", "") or "").strip().lower()
        prog_id   = program_map.get(prog_name)

        c = Course(
            code=code,
            name=name or code,
            credits=credits_val,
            category=category,
            program_id=prog_id,
        )
        new_courses.append(c)
        inserted += 1

    if new_courses:
        db.bulk_save_objects(new_courses)
        db.flush()

    return inserted, skipped


# ── Main import pipeline ──────────────────────────────────────────────────────

def run_import_pipeline(
    db: Session,
    filename: str,
    content: bytes,
    import_type: str,
    source_system: str,
    actor_id: Optional[int] = None,
    mapping_template_id: Optional[int] = None,
    notes: Optional[str] = None,
) -> ImportBatch:
    """
    Full import pipeline:
      1. Hash file → idempotency check
      2. Create ImportBatch record
      3. Parse file
      4. Apply field mapping (if template provided)
      5. Validate all rows → persist ValidationResult + ImportRowError
      6. Persist valid rows via bulk insert
      7. Run reconciliation → ReconciliationReport
      8. Emit structured audit events
      9. Update batch status + counters

    Returns the completed ImportBatch.
    """
    start_ts  = time.time()
    file_hash = compute_file_hash(content)
    fmt       = detect_format(filename, content)

    # ── Idempotency check ────────────────────────────────────────────────────
    existing_batch = (
        db.query(ImportBatch)
        .filter(ImportBatch.file_hash == file_hash)
        .first()
    )
    if existing_batch:
        logger.warning(
            "Duplicate import detected: hash=%s  existing_batch=%s",
            file_hash, existing_batch.batch_ref,
        )
        existing_batch.retry_count  = (existing_batch.retry_count or 0) + 1
        existing_batch.is_reprocess = True
        db.commit()
        db.refresh(existing_batch)
        return existing_batch

    # ── Create batch record ──────────────────────────────────────────────────
    batch_ref = str(uuid.uuid4())
    batch = ImportBatch(
        batch_ref=batch_ref,
        file_hash=file_hash,
        file_name=filename,
        file_size_bytes=len(content),
        file_format=FileFormatEnum(fmt),
        import_type=ImportTypeEnum(import_type),
        source_system=SourceSystemEnum(source_system),
        status=BatchStatusEnum.PROCESSING,
        imported_by=actor_id,
        started_at=datetime.now(timezone.utc),
        notes=notes,
    )
    db.add(batch)
    db.flush()

    _emit_audit(
        db, batch.id, AuditEventTypeEnum.IMPORT_STARTED,
        actor_id=actor_id,
        message=f"Import started: {filename} ({fmt.value.upper()}, {len(content)} bytes)",
        flush=True,
    )

    try:
        # ── Parse ────────────────────────────────────────────────────────────
        raw_rows       = parse_file(filename, content, fmt)
        batch.total_rows = len(raw_rows)
        db.flush()

        if not raw_rows:
            batch.status       = BatchStatusEnum.FAILED
            batch.completed_at = datetime.now(timezone.utc)
            _emit_audit(db, batch.id, AuditEventTypeEnum.IMPORT_FAILED,
                        message="File parsed to zero rows.")
            db.commit()
            return batch

        # ── Apply mapping ─────────────────────────────────────────────────────
        field_mappings: Dict[str, str] = {}
        transformations: Optional[Dict[str, str]] = None

        if mapping_template_id:
            version = get_current_version(db, mapping_template_id)
            if version:
                field_mappings  = version.field_mappings or {}
                transformations = version.transformations
                batch.mapping_version_id = version.id
                db.flush()
                _emit_audit(
                    db, batch.id, AuditEventTypeEnum.MAPPING_APPLIED,
                    message=f"Mapping template v{version.version_number} applied.",
                )

        mapped_rows = [
            apply_mapping(row, field_mappings, transformations)
            for row in raw_rows
        ]

        # ── Validate ─────────────────────────────────────────────────────────
        val_summary = run_validation(db, batch, mapped_rows, import_type)
        batch.warning_count = val_summary.total_warnings
        db.flush()

        _emit_audit(
            db, batch.id, AuditEventTypeEnum.VALIDATION_RAN,
            message=(
                f"Validation: {val_summary.passed_rows}/{val_summary.total_rows} passed, "
                f"{val_summary.total_errors} errors, {val_summary.total_warnings} warnings"
            ),
            payload={
                "passed_rows":    val_summary.passed_rows,
                "failed_rows":    val_summary.failed_rows,
                "total_errors":   val_summary.total_errors,
                "total_warnings": val_summary.total_warnings,
            },
        )

        # ── Determine valid row numbers ───────────────────────────────────────
        valid_row_numbers: Set[int] = {
            rr.row_number
            for rr in val_summary.row_results
            if rr.passed
        }

        # ── Persist valid rows ────────────────────────────────────────────────
        if import_type == "students":
            inserted, skipped = _upsert_student_rows(db, mapped_rows, valid_row_numbers)
        elif import_type == "transcripts":
            inserted, skipped = _upsert_transcript_rows(db, mapped_rows, valid_row_numbers)
        elif import_type == "curriculum":
            inserted, skipped = _upsert_curriculum_rows(db, mapped_rows, valid_row_numbers)
        else:
            inserted = 0
            skipped  = len(raw_rows)

        batch.success_rows = inserted
        batch.skipped_rows = skipped
        batch.failed_rows  = val_summary.failed_rows
        db.flush()

        # ── Reconciliation ────────────────────────────────────────────────────
        recon_report = run_reconciliation(db, batch, mapped_rows, import_type)
        _emit_audit(
            db, batch.id, AuditEventTypeEnum.RECONCILE_RAN,
            message=(
                f"Reconciliation: {recon_report.total_checked} checked, "
                f"{recon_report.duplicates_found} duplicates, "
                f"{recon_report.conflicts_found} conflicts"
            ),
            payload={
                "total_checked":    recon_report.total_checked,
                "duplicates_found": recon_report.duplicates_found,
                "conflicts_found":  recon_report.conflicts_found,
            },
        )

        # ── Finalise status ───────────────────────────────────────────────────
        duration_ms = int((time.time() - start_ts) * 1000)

        if val_summary.failed_rows == 0:
            batch.status = BatchStatusEnum.COMPLETED
        elif inserted > 0:
            batch.status = BatchStatusEnum.PARTIALLY_COMPLETED
        else:
            batch.status = BatchStatusEnum.FAILED

        batch.completed_at = datetime.now(timezone.utc)
        batch.duration_ms  = duration_ms
        db.flush()

        _emit_audit(
            db, batch.id, AuditEventTypeEnum.IMPORT_COMPLETED,
            actor_id=actor_id,
            message=f"Import completed in {duration_ms}ms. Status: {batch.status.value}",
            payload={
                "total_rows":   batch.total_rows,
                "success_rows": batch.success_rows,
                "failed_rows":  batch.failed_rows,
                "skipped_rows": batch.skipped_rows,
                "duration_ms":  duration_ms,
            },
        )

        db.commit()
        db.refresh(batch)

        logger.info(
            "Import complete: batch=%s  status=%s  inserted=%d  failed=%d  duration=%dms",
            batch.batch_ref, batch.status.value, inserted,
            batch.failed_rows, duration_ms,
        )
        return batch

    except Exception as exc:
        logger.exception("Import pipeline failed for batch %s: %s", batch_ref, exc)
        db.rollback()

        try:
            batch.status       = BatchStatusEnum.FAILED
            batch.completed_at = datetime.now(timezone.utc)
            batch.duration_ms  = int((time.time() - start_ts) * 1000)
            _emit_audit(
                db, batch.id, AuditEventTypeEnum.IMPORT_FAILED,
                actor_id=actor_id,
                message=f"Pipeline exception: {str(exc)[:500]}",
            )
            db.commit()
        except Exception:
            pass

        try:
            db.refresh(batch)
        except Exception:
            pass
        return batch
