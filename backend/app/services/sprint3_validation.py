"""
EduGuard AI — Sprint 3: Validation Engine
File: backend/app/services/sprint3_validation.py

Runs all configured validation rules against mapped import rows.
Results are persisted to validation_results and import_row_errors tables.

Rule categories:
  - REFERENTIAL : entity existence checks (student, course, program, dept)
  - ACADEMIC    : grade validity, credit hours, semester, prerequisite refs
  - CURRICULUM  : requirement mapping, elective mapping, version consistency
  - INTEGRITY   : duplicate detection within the batch itself
  - BUSINESS    : cross-field business rules
"""

from __future__ import annotations

import logging
from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional, Set, Tuple

from sqlalchemy.orm import Session

from app.models.models import Course, Student
from app.models.academic_models import (
    AcademicProgram,
    AcademicTerm,
    GradeScale,
    StudentCourseAttempt,
)
from app.models.sprint3_models import (
    ImportBatch,
    ImportRowError,
    ValidationCategoryEnum,
    ValidationResult,
    ValidationSeverityEnum,
)

logger = logging.getLogger(__name__)


# ── Data structures ───────────────────────────────────────────────────────────

@dataclass
class RuleViolation:
    row_number: int
    field_name: str
    raw_value: Any
    error_code: str
    message: str
    severity: ValidationSeverityEnum = ValidationSeverityEnum.ERROR
    category: ValidationCategoryEnum = ValidationCategoryEnum.REFERENTIAL
    extra: Optional[Dict[str, Any]] = None


@dataclass
class RowValidationResult:
    row_number: int
    passed: bool
    violations: List[RuleViolation] = field(default_factory=list)


@dataclass
class BatchValidationSummary:
    total_rows: int
    passed_rows: int
    failed_rows: int
    warning_rows: int
    total_errors: int
    total_warnings: int
    row_results: List[RowValidationResult] = field(default_factory=list)


# ── Reference cache (per-batch) ────────────────────────────────────────────────

class ReferenceCache:
    """Loads reference data once per batch to avoid N+1 queries."""

    def __init__(self, db: Session):
        self.db = db
        self._student_codes: Optional[Set[str]] = None
        self._course_codes: Optional[Set[str]] = None
        self._program_names: Optional[Set[str]] = None
        self._term_names: Optional[Set[str]] = None
        self._valid_grades: Optional[Set[str]] = None

    @property
    def student_codes(self) -> Set[str]:
        if self._student_codes is None:
            rows = self.db.query(Student.student_id).all()
            self._student_codes = {r[0] for r in rows if r[0]}
        return self._student_codes

    @property
    def course_codes(self) -> Set[str]:
        if self._course_codes is None:
            rows = self.db.query(Course.code).all()
            self._course_codes = {r[0].upper() for r in rows if r[0]}
        return self._course_codes

    @property
    def program_names(self) -> Set[str]:
        if self._program_names is None:
            rows = self.db.query(AcademicProgram.name).all()
            self._program_names = {r[0].lower() for r in rows if r[0]}
        return self._program_names

    @property
    def term_names(self) -> Set[str]:
        if self._term_names is None:
            rows = self.db.query(AcademicTerm.name).all()
            self._term_names = {r[0].lower() for r in rows if r[0]}
        return self._term_names

    @property
    def valid_grades(self) -> Set[str]:
        if self._valid_grades is None:
            rows = self.db.query(GradeScale.letter_grade).all()
            self._valid_grades = {r[0].upper() for r in rows if r[0]}
            # Always include common grades as fallback
            self._valid_grades.update({
                "A+", "A", "A-", "B+", "B", "B-",
                "C+", "C", "C-", "D+", "D", "D-",
                "F", "W", "WP", "WF", "I", "IP",
            })
        return self._valid_grades


# ── Individual rule functions ──────────────────────────────────────────────────

def _check_required(row: Dict, field: str, row_num: int, error_code: str) -> Optional[RuleViolation]:
    val = row.get(field)
    if val is None or str(val).strip() == "":
        return RuleViolation(
            row_number=row_num,
            field_name=field,
            raw_value=val,
            error_code=error_code,
            message=f"Required field '{field}' is missing or empty.",
            severity=ValidationSeverityEnum.ERROR,
            category=ValidationCategoryEnum.INTEGRITY,
        )
    return None


def _check_student_exists(
    row: Dict, row_num: int, cache: ReferenceCache
) -> Optional[RuleViolation]:
    code = str(row.get("student_code", "")).strip()
    if code and code not in cache.student_codes:
        return RuleViolation(
            row_number=row_num,
            field_name="student_code",
            raw_value=code,
            error_code="REF_STUDENT_NOT_FOUND",
            message=f"Student with code '{code}' does not exist in the system.",
            severity=ValidationSeverityEnum.ERROR,
            category=ValidationCategoryEnum.REFERENTIAL,
        )
    return None


def _check_course_exists(
    row: Dict, row_num: int, cache: ReferenceCache
) -> Optional[RuleViolation]:
    code = str(row.get("course_code", "")).strip().upper()
    if code and code not in cache.course_codes:
        return RuleViolation(
            row_number=row_num,
            field_name="course_code",
            raw_value=code,
            error_code="REF_COURSE_NOT_FOUND",
            message=f"Course '{code}' does not exist in the course catalog.",
            severity=ValidationSeverityEnum.ERROR,
            category=ValidationCategoryEnum.REFERENTIAL,
        )
    return None


def _check_term_exists(
    row: Dict, row_num: int, cache: ReferenceCache
) -> Optional[RuleViolation]:
    term = str(row.get("term_name", "")).strip().lower()
    if term and term not in cache.term_names:
        return RuleViolation(
            row_number=row_num,
            field_name="term_name",
            raw_value=term,
            error_code="REF_TERM_NOT_FOUND",
            message=f"Academic term '{term}' does not exist.",
            severity=ValidationSeverityEnum.WARNING,
            category=ValidationCategoryEnum.REFERENTIAL,
        )
    return None


def _check_grade_valid(
    row: Dict, row_num: int, cache: ReferenceCache
) -> Optional[RuleViolation]:
    grade = str(row.get("grade", "")).strip().upper()
    if grade and grade not in cache.valid_grades:
        return RuleViolation(
            row_number=row_num,
            field_name="grade",
            raw_value=grade,
            error_code="ACAD_INVALID_GRADE",
            message=f"Grade '{grade}' is not a recognised grade value.",
            severity=ValidationSeverityEnum.ERROR,
            category=ValidationCategoryEnum.ACADEMIC,
        )
    return None


def _check_credit_hours(row: Dict, row_num: int) -> Optional[RuleViolation]:
    raw = row.get("credit_hours")
    if raw is not None:
        try:
            ch = float(raw)
            if ch < 0 or ch > 6:
                return RuleViolation(
                    row_number=row_num,
                    field_name="credit_hours",
                    raw_value=raw,
                    error_code="ACAD_INVALID_CREDITS",
                    message=f"Credit hours '{raw}' is outside valid range (0–6).",
                    severity=ValidationSeverityEnum.WARNING,
                    category=ValidationCategoryEnum.ACADEMIC,
                )
        except (ValueError, TypeError):
            return RuleViolation(
                row_number=row_num,
                field_name="credit_hours",
                raw_value=raw,
                error_code="ACAD_CREDITS_NOT_NUMERIC",
                message=f"Credit hours '{raw}' is not a valid number.",
                severity=ValidationSeverityEnum.ERROR,
                category=ValidationCategoryEnum.ACADEMIC,
            )
    return None


def _check_gpa_range(row: Dict, row_num: int, field_name: str = "cgpa") -> Optional[RuleViolation]:
    raw = row.get(field_name)
    if raw is not None:
        try:
            gpa = float(raw)
            if not (0.0 <= gpa <= 4.0):
                return RuleViolation(
                    row_number=row_num,
                    field_name=field_name,
                    raw_value=raw,
                    error_code="ACAD_GPA_OUT_OF_RANGE",
                    message=f"GPA value '{raw}' is outside valid range (0.0–4.0).",
                    severity=ValidationSeverityEnum.WARNING,
                    category=ValidationCategoryEnum.ACADEMIC,
                )
        except (ValueError, TypeError):
            pass  # non-numeric GPA is only a warning if field is optional
    return None


def _check_email_format(row: Dict, row_num: int) -> Optional[RuleViolation]:
    email = str(row.get("university_email", "")).strip()
    if email and "@" not in email:
        return RuleViolation(
            row_number=row_num,
            field_name="university_email",
            raw_value=email,
            error_code="BIZ_INVALID_EMAIL",
            message=f"Email '{email}' does not appear to be a valid email address.",
            severity=ValidationSeverityEnum.WARNING,
            category=ValidationCategoryEnum.BUSINESS,
        )
    return None


def _check_enrollment_year(row: Dict, row_num: int) -> Optional[RuleViolation]:
    raw = row.get("enrollment_year")
    if raw is not None:
        try:
            year = int(raw)
            if not (2000 <= year <= 2030):
                return RuleViolation(
                    row_number=row_num,
                    field_name="enrollment_year",
                    raw_value=raw,
                    error_code="BIZ_INVALID_ENROLL_YEAR",
                    message=f"Enrollment year '{raw}' is outside valid range (2000–2030).",
                    severity=ValidationSeverityEnum.WARNING,
                    category=ValidationCategoryEnum.BUSINESS,
                )
        except (ValueError, TypeError):
            return RuleViolation(
                row_number=row_num,
                field_name="enrollment_year",
                raw_value=raw,
                error_code="BIZ_ENROLL_YEAR_NOT_INT",
                message=f"Enrollment year '{raw}' must be an integer.",
                severity=ValidationSeverityEnum.ERROR,
                category=ValidationCategoryEnum.BUSINESS,
            )
    return None


def _check_curriculum_year(row: Dict, row_num: int) -> Optional[RuleViolation]:
    raw = row.get("curriculum_year")
    if raw is not None:
        try:
            year = int(raw)
            if not (2010 <= year <= 2030):
                return RuleViolation(
                    row_number=row_num,
                    field_name="curriculum_year",
                    raw_value=raw,
                    error_code="CURR_INVALID_YEAR",
                    message=f"Curriculum year '{raw}' is outside expected range (2010–2030).",
                    severity=ValidationSeverityEnum.WARNING,
                    category=ValidationCategoryEnum.CURRICULUM,
                )
        except (ValueError, TypeError):
            pass
    return None


# ── Per-import-type validation orchestrators ───────────────────────────────────

def validate_student_row(
    row: Dict, row_num: int, cache: ReferenceCache, seen_codes: Set[str]
) -> RowValidationResult:
    violations: List[RuleViolation] = []

    # Required fields
    for req_field, code in [
        ("student_code", "REQ_STUDENT_CODE"),
        ("full_name",    "REQ_FULL_NAME"),
    ]:
        v = _check_required(row, req_field, row_num, code)
        if v:
            violations.append(v)

    # Within-batch duplicate
    code = str(row.get("student_code", "")).strip()
    if code:
        if code in seen_codes:
            violations.append(RuleViolation(
                row_number=row_num,
                field_name="student_code",
                raw_value=code,
                error_code="INT_DUPLICATE_IN_BATCH",
                message=f"Student code '{code}' appears more than once in this import file.",
                severity=ValidationSeverityEnum.ERROR,
                category=ValidationCategoryEnum.INTEGRITY,
            ))
        else:
            seen_codes.add(code)

    # Optional field validations
    for check_fn in [_check_email_format, _check_enrollment_year]:
        v = check_fn(row, row_num)
        if v:
            violations.append(v)

    passed = all(v.severity != ValidationSeverityEnum.ERROR for v in violations)
    return RowValidationResult(row_number=row_num, passed=passed, violations=violations)


def validate_transcript_row(
    row: Dict, row_num: int, cache: ReferenceCache, seen_keys: Set[Tuple]
) -> RowValidationResult:
    violations: List[RuleViolation] = []

    for req_field, code in [
        ("student_code", "REQ_STUDENT_CODE"),
        ("course_code",  "REQ_COURSE_CODE"),
    ]:
        v = _check_required(row, req_field, row_num, code)
        if v:
            violations.append(v)

    # Referential checks (only if fields present)
    for check_fn in [
        lambda r, n: _check_student_exists(r, n, cache),
        lambda r, n: _check_course_exists(r, n, cache),
        lambda r, n: _check_term_exists(r, n, cache),
        lambda r, n: _check_grade_valid(r, n, cache),
    ]:
        v = check_fn(row, row_num)
        if v:
            violations.append(v)

    # Academic validations
    for check_fn in [_check_credit_hours, _check_gpa_range]:
        v = check_fn(row, row_num)
        if v:
            violations.append(v)

    # Within-batch duplicate attempt key
    key = (
        str(row.get("student_code", "")).strip(),
        str(row.get("course_code", "")).strip().upper(),
        str(row.get("attempt_number", "1")).strip(),
        str(row.get("term_name", "")).strip().lower(),
    )
    if any(key):
        if key in seen_keys:
            violations.append(RuleViolation(
                row_number=row_num,
                field_name="student_code,course_code,attempt_number,term_name",
                raw_value=str(key),
                error_code="INT_DUPLICATE_ATTEMPT",
                message="Duplicate course attempt record within this import file.",
                severity=ValidationSeverityEnum.ERROR,
                category=ValidationCategoryEnum.INTEGRITY,
            ))
        else:
            seen_keys.add(key)

    passed = all(v.severity != ValidationSeverityEnum.ERROR for v in violations)
    return RowValidationResult(row_number=row_num, passed=passed, violations=violations)


def validate_curriculum_row(
    row: Dict, row_num: int, cache: ReferenceCache, seen_codes: Set[str]
) -> RowValidationResult:
    violations: List[RuleViolation] = []

    for req_field, code in [
        ("course_code", "REQ_COURSE_CODE"),
        ("course_name", "REQ_COURSE_NAME"),
    ]:
        v = _check_required(row, req_field, row_num, code)
        if v:
            violations.append(v)

    for check_fn in [_check_credit_hours, _check_curriculum_year]:
        v = check_fn(row, row_num)
        if v:
            violations.append(v)

    # Curriculum category check
    valid_cats = {"core", "elective", "university_req", "university_elective", "field_training"}
    cat = str(row.get("category", "")).strip().lower()
    if cat and cat not in valid_cats:
        violations.append(RuleViolation(
            row_number=row_num,
            field_name="category",
            raw_value=cat,
            error_code="CURR_INVALID_CATEGORY",
            message=f"Category '{cat}' is not valid. Allowed: {', '.join(valid_cats)}.",
            severity=ValidationSeverityEnum.WARNING,
            category=ValidationCategoryEnum.CURRICULUM,
        ))

    passed = all(v.severity != ValidationSeverityEnum.ERROR for v in violations)
    return RowValidationResult(row_number=row_num, passed=passed, violations=violations)


# ── Main validation engine entry point ───────────────────────────────────────

def run_validation(
    db: Session,
    batch: ImportBatch,
    rows: List[Dict[str, Any]],
    import_type: str,
) -> BatchValidationSummary:
    """
    Run all validation rules for a batch.
    Persists ValidationResult and ImportRowError rows in bulk.
    Returns a BatchValidationSummary.
    """
    cache = ReferenceCache(db)
    seen_codes: Set[str] = set()
    seen_keys: Set[Tuple] = set()

    row_results: List[RowValidationResult] = []

    for idx, row in enumerate(rows, start=1):
        if import_type == "students":
            result = validate_student_row(row, idx, cache, seen_codes)
        elif import_type == "transcripts":
            result = validate_transcript_row(row, idx, cache, seen_keys)
        elif import_type == "curriculum":
            result = validate_curriculum_row(row, idx, cache, seen_codes)
        else:
            result = RowValidationResult(row_number=idx, passed=True)

        row_results.append(result)

    # Bulk-insert validation results and errors
    val_result_objs: List[ValidationResult] = []
    row_error_objs:  List[ImportRowError]   = []

    for rr in row_results:
        if rr.violations:
            for v in rr.violations:
                val_result_objs.append(ValidationResult(
                    batch_id=batch.id,
                    row_number=v.row_number,
                    rule_code=v.error_code,
                    field_name=v.field_name,
                    raw_value=str(v.raw_value) if v.raw_value is not None else None,
                    passed=False,
                    severity=v.severity,
                    message=v.message,
                ))
                if v.severity == ValidationSeverityEnum.ERROR:
                    row_error_objs.append(ImportRowError(
                        batch_id=batch.id,
                        row_number=v.row_number,
                        field_name=v.field_name,
                        raw_value=str(v.raw_value) if v.raw_value is not None else None,
                        error_code=v.error_code,
                        error_message=v.message,
                        severity=v.severity,
                        category=v.category,
                        extra_context=v.extra,
                    ))
        else:
            val_result_objs.append(ValidationResult(
                batch_id=batch.id,
                row_number=rr.row_number,
                rule_code="ALL_PASSED",
                passed=True,
                severity=ValidationSeverityEnum.INFO,
                message="All validation rules passed.",
            ))

    if val_result_objs:
        db.bulk_save_objects(val_result_objs)
    if row_error_objs:
        db.bulk_save_objects(row_error_objs)
    db.flush()

    # Summary counts
    passed_rows  = sum(1 for r in row_results if r.passed)
    failed_rows  = sum(1 for r in row_results if not r.passed)
    total_errors = sum(
        1 for r in row_results
        for v in r.violations
        if v.severity == ValidationSeverityEnum.ERROR
    )
    total_warnings = sum(
        1 for r in row_results
        for v in r.violations
        if v.severity == ValidationSeverityEnum.WARNING
    )
    warning_rows = sum(
        1 for r in row_results
        if any(v.severity == ValidationSeverityEnum.WARNING for v in r.violations)
        and r.passed
    )

    logger.info(
        "Validation complete for batch %s: %d/%d passed, %d errors, %d warnings",
        batch.batch_ref, passed_rows, len(rows), total_errors, total_warnings,
    )

    return BatchValidationSummary(
        total_rows=len(rows),
        passed_rows=passed_rows,
        failed_rows=failed_rows,
        warning_rows=warning_rows,
        total_errors=total_errors,
        total_warnings=total_warnings,
        row_results=row_results,
    )
