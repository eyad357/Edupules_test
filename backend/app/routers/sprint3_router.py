"""
EduGuard AI — Sprint 3: Import Platform Router
File: backend/app/routers/sprint3_router.py

Endpoints:
  POST   /api/v1/imports/students
  POST   /api/v1/imports/transcripts
  POST   /api/v1/imports/curriculum
  GET    /api/v1/imports
  GET    /api/v1/imports/{batch_ref}
  GET    /api/v1/imports/{batch_ref}/errors
  GET    /api/v1/imports/{batch_ref}/report
  GET    /api/v1/imports/{batch_ref}/reconciliation
  GET    /api/v1/imports/{batch_ref}/audit
  GET    /api/v1/mapping-templates
  POST   /api/v1/mapping-templates
  PUT    /api/v1/mapping-templates/{id}
  GET    /api/v1/mapping-templates/{id}/versions
  GET    /api/v1/validation-rules
  GET    /api/v1/reconciliation-reports
  GET    /api/v1/reconciliation-reports/{id}
"""

from __future__ import annotations

import logging
from typing import List, Optional

from fastapi import (
    APIRouter, Depends, File, Form, HTTPException,
    Query, UploadFile, status,
)
from sqlalchemy.orm import Session

from app.api.auth import get_current_user
from app.db.database import get_db
from app.models.models import User, UserRole
from app.models.sprint3_models import (
    ImportBatch,
    ImportRowError,
    ImportTypeEnum,
    MappingTemplate,
    MappingTemplateVersion,
    ReconciliationReport,
    ValidationResult,
    ValidationRule,
    ImportAuditEvent,
    BatchStatusEnum,
    SourceSystemEnum,
)
from app.schemas.sprint3_schemas import (
    AuditEventOut,
    AuditReport,
    ImportBatchListOut,
    ImportBatchOut,
    ImportRowErrorOut,
    ImportSummaryReport,
    MappingTemplateCreate,
    MappingTemplateOut,
    MappingTemplateUpdate,
    MappingTemplateVersionOut,
    PaginatedErrors,
    PaginatedImportBatches,
    PaginatedReconciliationReports,
    ReconciliationReportOut,
    ValidationErrorReport,
    ValidationResultOut,
    ValidationRuleOut,
)
from app.services.sprint3_import_engine import run_import_pipeline
from app.services.sprint3_mapping import (
    create_template,
    get_current_version,
    get_template,
    list_templates,
    update_template,
)

logger = logging.getLogger(__name__)

sprint3_router = APIRouter(prefix="/api/v1", tags=["Sprint 3 - Import Platform"])


# ── Auth helpers ──────────────────────────────────────────────────────────────

def _require_admin_or_advisor(current_user: User) -> None:
    if current_user.role not in (UserRole.ADMIN, UserRole.ADVISOR, UserRole.PROFESSOR):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Import operations require admin, advisor, or professor role.",
        )


def _require_admin(current_user: User) -> None:
    if current_user.role != UserRole.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This operation requires admin role.",
        )


def _get_batch_or_404(db: Session, batch_ref: str) -> ImportBatch:
    batch = db.query(ImportBatch).filter(ImportBatch.batch_ref == batch_ref).first()
    if not batch:
        raise HTTPException(status_code=404, detail=f"Import batch '{batch_ref}' not found.")
    return batch


# ═════════════════════════════════════════════════════════════════════════════
# IMPORT ENDPOINTS
# ═════════════════════════════════════════════════════════════════════════════

@sprint3_router.post(
    "/imports/students",
    response_model=ImportBatchOut,
    status_code=status.HTTP_202_ACCEPTED,
    summary="Import student records (CSV / XLSX / JSON)",
)
async def import_students(
    file: UploadFile = File(..., description="Student data file (CSV, XLSX, or JSON)"),
    source_system: str = Form(default="manual"),
    mapping_template_id: Optional[int] = Form(default=None),
    notes: Optional[str] = Form(default=None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _require_admin_or_advisor(current_user)
    content = await file.read()
    if not content:
        raise HTTPException(status_code=400, detail="Uploaded file is empty.")
    _validate_source_system(source_system)

    batch = run_import_pipeline(
        db=db,
        filename=file.filename or "upload.csv",
        content=content,
        import_type="students",
        source_system=source_system,
        actor_id=current_user.id,
        mapping_template_id=mapping_template_id,
        notes=notes,
    )
    return ImportBatchOut.model_validate(batch)


@sprint3_router.post(
    "/imports/transcripts",
    response_model=ImportBatchOut,
    status_code=status.HTTP_202_ACCEPTED,
    summary="Import transcript / course-attempt records",
)
async def import_transcripts(
    file: UploadFile = File(...),
    source_system: str = Form(default="manual"),
    mapping_template_id: Optional[int] = Form(default=None),
    notes: Optional[str] = Form(default=None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _require_admin_or_advisor(current_user)
    content = await file.read()
    if not content:
        raise HTTPException(status_code=400, detail="Uploaded file is empty.")
    _validate_source_system(source_system)

    batch = run_import_pipeline(
        db=db,
        filename=file.filename or "upload.csv",
        content=content,
        import_type="transcripts",
        source_system=source_system,
        actor_id=current_user.id,
        mapping_template_id=mapping_template_id,
        notes=notes,
    )
    return ImportBatchOut.model_validate(batch)


@sprint3_router.post(
    "/imports/curriculum",
    response_model=ImportBatchOut,
    status_code=status.HTTP_202_ACCEPTED,
    summary="Import curriculum / course catalog records",
)
async def import_curriculum(
    file: UploadFile = File(...),
    source_system: str = Form(default="curriculum"),
    mapping_template_id: Optional[int] = Form(default=None),
    notes: Optional[str] = Form(default=None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _require_admin_or_advisor(current_user)
    content = await file.read()
    if not content:
        raise HTTPException(status_code=400, detail="Uploaded file is empty.")
    _validate_source_system(source_system)

    batch = run_import_pipeline(
        db=db,
        filename=file.filename or "upload.csv",
        content=content,
        import_type="curriculum",
        source_system=source_system,
        actor_id=current_user.id,
        mapping_template_id=mapping_template_id,
        notes=notes,
    )
    return ImportBatchOut.model_validate(batch)


# ═════════════════════════════════════════════════════════════════════════════
# IMPORT BATCH LIST + DETAIL
# ═════════════════════════════════════════════════════════════════════════════

@sprint3_router.get(
    "/imports",
    response_model=PaginatedImportBatches,
    summary="List all import batches with pagination and filtering",
)
def list_imports(
    import_type: Optional[str]  = Query(None, description="Filter by type: students|transcripts|curriculum"),
    status_filter: Optional[str] = Query(None, alias="status", description="Filter by batch status"),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _require_admin_or_advisor(current_user)

    q = db.query(ImportBatch).order_by(ImportBatch.created_at.desc())

    if import_type:
        try:
            q = q.filter(ImportBatch.import_type == ImportTypeEnum(import_type))
        except ValueError:
            raise HTTPException(status_code=400, detail=f"Invalid import_type '{import_type}'.")

    if status_filter:
        try:
            q = q.filter(ImportBatch.status == BatchStatusEnum(status_filter))
        except ValueError:
            raise HTTPException(status_code=400, detail=f"Invalid status '{status_filter}'.")

    total   = q.count()
    batches = q.offset((page - 1) * page_size).limit(page_size).all()

    return PaginatedImportBatches(
        total=total,
        page=page,
        page_size=page_size,
        items=[ImportBatchListOut.model_validate(b) for b in batches],
    )


@sprint3_router.get(
    "/imports/{batch_ref}",
    response_model=ImportBatchOut,
    summary="Get full details of an import batch",
)
def get_import(
    batch_ref: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _require_admin_or_advisor(current_user)
    return ImportBatchOut.model_validate(_get_batch_or_404(db, batch_ref))


@sprint3_router.get(
    "/imports/{batch_ref}/errors",
    response_model=PaginatedErrors,
    summary="Get row-level errors for an import batch",
)
def get_import_errors(
    batch_ref: str,
    severity: Optional[str] = Query(None, description="Filter by severity: error|warning|info"),
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=200),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _require_admin_or_advisor(current_user)
    batch = _get_batch_or_404(db, batch_ref)

    q = db.query(ImportRowError).filter(ImportRowError.batch_id == batch.id)
    if severity:
        from app.models.sprint3_models import ValidationSeverityEnum
        try:
            q = q.filter(ImportRowError.severity == ValidationSeverityEnum(severity))
        except ValueError:
            raise HTTPException(status_code=400, detail=f"Invalid severity '{severity}'.")

    q = q.order_by(ImportRowError.row_number)
    total  = q.count()
    errors = q.offset((page - 1) * page_size).limit(page_size).all()

    return PaginatedErrors(
        total=total,
        page=page,
        page_size=page_size,
        items=[ImportRowErrorOut.model_validate(e) for e in errors],
    )


@sprint3_router.get(
    "/imports/{batch_ref}/report",
    response_model=ImportSummaryReport,
    summary="Get aggregated import summary report",
)
def get_import_report(
    batch_ref: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _require_admin_or_advisor(current_user)
    batch = _get_batch_or_404(db, batch_ref)

    # Error breakdown by category
    from sqlalchemy import func as sqlfunc
    from app.models.sprint3_models import ValidationCategoryEnum
    category_counts = (
        db.query(ImportRowError.category, sqlfunc.count(ImportRowError.id))
        .filter(ImportRowError.batch_id == batch.id)
        .group_by(ImportRowError.category)
        .all()
    )
    error_breakdown = {
        (str(cat.value) if cat else "unknown"): cnt
        for cat, cnt in category_counts
    }

    # Top 5 distinct error messages
    top_errors_rows = (
        db.query(ImportRowError.error_message)
        .filter(ImportRowError.batch_id == batch.id)
        .distinct()
        .limit(5)
        .all()
    )
    top_errors = [r[0] for r in top_errors_rows if r[0]]

    return ImportSummaryReport(
        batch_ref=batch.batch_ref,
        file_name=batch.file_name,
        import_type=batch.import_type.value,
        source_system=batch.source_system.value,
        status=batch.status.value,
        total_rows=batch.total_rows or 0,
        success_rows=batch.success_rows or 0,
        failed_rows=batch.failed_rows or 0,
        skipped_rows=batch.skipped_rows or 0,
        warning_count=batch.warning_count or 0,
        duration_ms=batch.duration_ms,
        started_at=batch.started_at,
        completed_at=batch.completed_at,
        error_breakdown=error_breakdown,
        top_errors=top_errors,
    )


@sprint3_router.get(
    "/imports/{batch_ref}/reconciliation",
    response_model=ReconciliationReportOut,
    summary="Get reconciliation report for an import batch",
)
def get_import_reconciliation(
    batch_ref: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _require_admin_or_advisor(current_user)
    batch = _get_batch_or_404(db, batch_ref)

    report = (
        db.query(ReconciliationReport)
        .filter(ReconciliationReport.batch_id == batch.id)
        .first()
    )
    if not report:
        raise HTTPException(status_code=404, detail="No reconciliation report found for this batch.")

    return ReconciliationReportOut.model_validate(report)


@sprint3_router.get(
    "/imports/{batch_ref}/audit",
    response_model=AuditReport,
    summary="Get full structured audit trail for an import batch",
)
def get_import_audit(
    batch_ref: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _require_admin_or_advisor(current_user)
    batch = _get_batch_or_404(db, batch_ref)

    events = (
        db.query(ImportAuditEvent)
        .filter(ImportAuditEvent.batch_id == batch.id)
        .order_by(ImportAuditEvent.created_at)
        .all()
    )

    return AuditReport(
        batch_ref=batch.batch_ref,
        import_type=batch.import_type.value,
        imported_by=batch.imported_by,
        started_at=batch.started_at,
        completed_at=batch.completed_at,
        duration_ms=batch.duration_ms,
        retry_count=batch.retry_count or 0,
        event_count=len(events),
        events=[AuditEventOut.model_validate(e) for e in events],
    )


# ═════════════════════════════════════════════════════════════════════════════
# MAPPING TEMPLATES
# ═════════════════════════════════════════════════════════════════════════════

@sprint3_router.get(
    "/mapping-templates",
    response_model=List[MappingTemplateOut],
    summary="List all mapping templates",
)
def list_mapping_templates(
    import_type: Optional[str] = Query(None),
    is_active: Optional[bool]  = Query(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _require_admin_or_advisor(current_user)

    it = None
    if import_type:
        try:
            it = ImportTypeEnum(import_type)
        except ValueError:
            raise HTTPException(status_code=400, detail=f"Invalid import_type '{import_type}'.")

    templates = list_templates(db, import_type=it, is_active=is_active)
    result = []
    for t in templates:
        out = MappingTemplateOut.model_validate(t)
        current_ver = get_current_version(db, t.id)
        if current_ver:
            out.current_version = MappingTemplateVersionOut.model_validate(current_ver)
        result.append(out)
    return result


@sprint3_router.post(
    "/mapping-templates",
    response_model=MappingTemplateOut,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new mapping template",
)
def create_mapping_template(
    data: MappingTemplateCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _require_admin(current_user)

    template = create_template(
        db=db,
        name=data.name,
        import_type=data.import_type,
        source_system=data.source_system,
        field_mappings=data.field_mappings,
        description=data.description,
        transformations=data.transformations,
        created_by=current_user.id,
    )
    out = MappingTemplateOut.model_validate(template)
    current_ver = get_current_version(db, template.id)
    if current_ver:
        out.current_version = MappingTemplateVersionOut.model_validate(current_ver)
    return out


@sprint3_router.put(
    "/mapping-templates/{template_id}",
    response_model=MappingTemplateOut,
    summary="Update a mapping template (publishes a new version if field_mappings provided)",
)
def update_mapping_template(
    template_id: int,
    data: MappingTemplateUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _require_admin(current_user)

    tmpl = get_template(db, template_id)
    if not tmpl:
        raise HTTPException(status_code=404, detail="Mapping template not found.")

    updated = update_template(db, tmpl, data.model_dump(exclude_none=True), actor_id=current_user.id)
    out = MappingTemplateOut.model_validate(updated)
    current_ver = get_current_version(db, updated.id)
    if current_ver:
        out.current_version = MappingTemplateVersionOut.model_validate(current_ver)
    return out


@sprint3_router.get(
    "/mapping-templates/{template_id}/versions",
    response_model=List[MappingTemplateVersionOut],
    summary="List all versions of a mapping template",
)
def list_template_versions(
    template_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _require_admin_or_advisor(current_user)

    tmpl = get_template(db, template_id)
    if not tmpl:
        raise HTTPException(status_code=404, detail="Mapping template not found.")

    versions = (
        db.query(MappingTemplateVersion)
        .filter(MappingTemplateVersion.template_id == template_id)
        .order_by(MappingTemplateVersion.version_number.desc())
        .all()
    )
    return [MappingTemplateVersionOut.model_validate(v) for v in versions]


# ═════════════════════════════════════════════════════════════════════════════
# VALIDATION RULES
# ═════════════════════════════════════════════════════════════════════════════

@sprint3_router.get(
    "/validation-rules",
    response_model=List[ValidationRuleOut],
    summary="List all configured validation rules",
)
def list_validation_rules(
    import_type: Optional[str] = Query(None),
    is_active: Optional[bool]  = Query(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _require_admin_or_advisor(current_user)

    q = db.query(ValidationRule)
    if import_type:
        try:
            q = q.filter(ValidationRule.import_type == ImportTypeEnum(import_type))
        except ValueError:
            pass
    if is_active is not None:
        q = q.filter(ValidationRule.is_active == is_active)

    return [ValidationRuleOut.model_validate(r) for r in q.order_by(ValidationRule.rule_code).all()]


# ═════════════════════════════════════════════════════════════════════════════
# RECONCILIATION REPORTS
# ═════════════════════════════════════════════════════════════════════════════

@sprint3_router.get(
    "/reconciliation-reports",
    response_model=PaginatedReconciliationReports,
    summary="List all reconciliation reports",
)
def list_reconciliation_reports(
    import_type: Optional[str] = Query(None),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _require_admin_or_advisor(current_user)

    q = db.query(ReconciliationReport).order_by(ReconciliationReport.generated_at.desc())
    if import_type:
        try:
            q = q.filter(ReconciliationReport.import_type == ImportTypeEnum(import_type))
        except ValueError:
            pass

    total   = q.count()
    reports = q.offset((page - 1) * page_size).limit(page_size).all()

    return PaginatedReconciliationReports(
        total=total,
        page=page,
        page_size=page_size,
        items=[ReconciliationReportOut.model_validate(r) for r in reports],
    )


@sprint3_router.get(
    "/reconciliation-reports/{report_id}",
    response_model=ReconciliationReportOut,
    summary="Get a specific reconciliation report with all items",
)
def get_reconciliation_report(
    report_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _require_admin_or_advisor(current_user)

    report = db.query(ReconciliationReport).filter(ReconciliationReport.id == report_id).first()
    if not report:
        raise HTTPException(status_code=404, detail="Reconciliation report not found.")

    return ReconciliationReportOut.model_validate(report)


# ── Internal helper ────────────────────────────────────────────────────────────

def _validate_source_system(value: str) -> None:
    valid = {e.value for e in SourceSystemEnum}
    if value not in valid:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid source_system '{value}'. Must be one of: {', '.join(sorted(valid))}.",
        )
