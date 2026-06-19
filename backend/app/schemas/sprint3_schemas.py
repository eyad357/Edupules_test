"""
EduGuard AI — Sprint 3: Import Platform Schemas
File: backend/app/schemas/sprint3_schemas.py

Request / Response models for all Sprint 3 API endpoints.
"""

from __future__ import annotations

from datetime import datetime
from typing import Any, Dict, List, Optional

from pydantic import BaseModel, Field, field_validator

from app.models.sprint3_models import (
    AuditEventTypeEnum,
    BatchStatusEnum,
    FileFormatEnum,
    ImportTypeEnum,
    ReconciliationStatusEnum,
    ReconciliationTypeEnum,
    SourceSystemEnum,
    ValidationCategoryEnum,
    ValidationSeverityEnum,
)


# ── Shared base ───────────────────────────────────────────────────────────────

class OrmBase(BaseModel):
    model_config = {"from_attributes": True}


# ═════════════════════════════════════════════════════════════════════════════
# MAPPING TEMPLATES
# ═════════════════════════════════════════════════════════════════════════════

class MappingTemplateVersionCreate(BaseModel):
    field_mappings: Dict[str, str] = Field(
        ...,
        example={"Student ID": "student_code", "Full Name": "full_name", "GPA": "cgpa"},
    )
    transformations: Optional[Dict[str, str]] = Field(
        None,
        example={"student_code": "strip", "grade": "uppercase"},
    )
    notes: Optional[str] = None


class MappingTemplateVersionOut(OrmBase):
    id: int
    template_id: int
    version_number: int
    field_mappings: Dict[str, Any]
    transformations: Optional[Dict[str, Any]]
    is_current: bool
    published_at: datetime
    notes: Optional[str]


class MappingTemplateCreate(BaseModel):
    name: str = Field(..., max_length=100)
    description: Optional[str] = None
    import_type: ImportTypeEnum
    source_system: SourceSystemEnum = SourceSystemEnum.MANUAL
    field_mappings: Dict[str, str] = Field(
        ...,
        description="Initial version field mappings",
    )
    transformations: Optional[Dict[str, str]] = None


class MappingTemplateUpdate(BaseModel):
    name: Optional[str] = Field(None, max_length=100)
    description: Optional[str] = None
    is_active: Optional[bool] = None
    field_mappings: Optional[Dict[str, str]] = None
    transformations: Optional[Dict[str, str]] = None
    version_notes: Optional[str] = None


class MappingTemplateOut(OrmBase):
    id: int
    name: str
    description: Optional[str]
    import_type: ImportTypeEnum
    source_system: SourceSystemEnum
    is_active: bool
    created_at: datetime
    updated_at: datetime
    current_version: Optional[MappingTemplateVersionOut] = None


# ═════════════════════════════════════════════════════════════════════════════
# VALIDATION RULES
# ═════════════════════════════════════════════════════════════════════════════

class ValidationRuleOut(OrmBase):
    id: int
    rule_code: str
    rule_name: str
    description: Optional[str]
    category: ValidationCategoryEnum
    import_type: Optional[ImportTypeEnum]
    severity: ValidationSeverityEnum
    is_active: bool
    rule_config: Optional[Dict[str, Any]]


# ═════════════════════════════════════════════════════════════════════════════
# IMPORT BATCHES
# ═════════════════════════════════════════════════════════════════════════════

class ImportBatchOut(OrmBase):
    id: int
    batch_ref: str
    file_name: str
    file_size_bytes: int
    file_format: FileFormatEnum
    import_type: ImportTypeEnum
    source_system: SourceSystemEnum
    status: BatchStatusEnum
    total_rows: int
    success_rows: int
    failed_rows: int
    skipped_rows: int
    warning_count: int
    retry_count: int
    is_reprocess: bool
    started_at: Optional[datetime]
    completed_at: Optional[datetime]
    duration_ms: Optional[int]
    notes: Optional[str]
    created_at: datetime
    updated_at: datetime


class ImportBatchListOut(OrmBase):
    id: int
    batch_ref: str
    file_name: str
    import_type: ImportTypeEnum
    source_system: SourceSystemEnum
    status: BatchStatusEnum
    total_rows: int
    success_rows: int
    failed_rows: int
    created_at: datetime


# ═════════════════════════════════════════════════════════════════════════════
# ROW ERRORS
# ═════════════════════════════════════════════════════════════════════════════

class ImportRowErrorOut(OrmBase):
    id: int
    batch_id: int
    row_number: Optional[int]
    field_name: Optional[str]
    raw_value: Optional[str]
    error_code: Optional[str]
    error_message: str
    severity: ValidationSeverityEnum
    category: Optional[ValidationCategoryEnum]
    created_at: datetime


# ═════════════════════════════════════════════════════════════════════════════
# VALIDATION RESULTS
# ═════════════════════════════════════════════════════════════════════════════

class ValidationResultOut(OrmBase):
    id: int
    batch_id: int
    row_number: Optional[int]
    rule_code: Optional[str]
    field_name: Optional[str]
    raw_value: Optional[str]
    passed: bool
    severity: ValidationSeverityEnum
    message: Optional[str]
    created_at: datetime


# ═════════════════════════════════════════════════════════════════════════════
# RECONCILIATION
# ═════════════════════════════════════════════════════════════════════════════

class ReconciliationItemOut(OrmBase):
    id: int
    report_id: int
    recon_type: ReconciliationTypeEnum
    entity_type: Optional[str]
    entity_key: Optional[str]
    incoming_value: Optional[Dict[str, Any]]
    existing_value: Optional[Dict[str, Any]]
    conflict_fields: Optional[List[str]]
    status: ReconciliationStatusEnum
    resolved_by: Optional[int]
    resolved_at: Optional[datetime]
    resolution_note: Optional[str]
    created_at: datetime


class ReconciliationReportOut(OrmBase):
    id: int
    batch_id: int
    import_type: ImportTypeEnum
    total_checked: int
    duplicates_found: int
    conflicts_found: int
    mismatches_found: int
    summary: Optional[Dict[str, Any]]
    generated_at: datetime
    items: List[ReconciliationItemOut] = []


# ═════════════════════════════════════════════════════════════════════════════
# AUDIT
# ═════════════════════════════════════════════════════════════════════════════

class AuditEventOut(OrmBase):
    id: int
    batch_id: int
    event_type: AuditEventTypeEnum
    actor_id: Optional[int]
    row_number: Optional[int]
    message: Optional[str]
    payload: Optional[Dict[str, Any]]
    created_at: datetime


# ═════════════════════════════════════════════════════════════════════════════
# REPORTS (aggregated)
# ═════════════════════════════════════════════════════════════════════════════

class ImportSummaryReport(BaseModel):
    batch_ref: str
    file_name: str
    import_type: str
    source_system: str
    status: str
    total_rows: int
    success_rows: int
    failed_rows: int
    skipped_rows: int
    warning_count: int
    duration_ms: Optional[int]
    started_at: Optional[datetime]
    completed_at: Optional[datetime]
    error_breakdown: Dict[str, int]  # category → count
    top_errors: List[str]


class ValidationErrorReport(BaseModel):
    batch_ref: str
    total_errors: int
    total_warnings: int
    by_category: Dict[str, int]
    by_severity: Dict[str, int]
    errors: List[ImportRowErrorOut]


class AuditReport(BaseModel):
    batch_ref: str
    import_type: str
    imported_by: Optional[int]
    started_at: Optional[datetime]
    completed_at: Optional[datetime]
    duration_ms: Optional[int]
    retry_count: int
    event_count: int
    events: List[AuditEventOut]


# ═════════════════════════════════════════════════════════════════════════════
# PAGINATION
# ═════════════════════════════════════════════════════════════════════════════

class PaginatedImportBatches(BaseModel):
    total: int
    page: int
    page_size: int
    items: List[ImportBatchListOut]


class PaginatedErrors(BaseModel):
    total: int
    page: int
    page_size: int
    items: List[ImportRowErrorOut]


class PaginatedReconciliationReports(BaseModel):
    total: int
    page: int
    page_size: int
    items: List[ReconciliationReportOut]
