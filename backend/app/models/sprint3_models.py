"""
EduGuard AI — Sprint 3: Academic Data Import & Validation Platform Models
File: backend/app/models/sprint3_models.py

New tables (all additive, no Sprint 1/2 tables modified):
  - import_batches            : top-level import session with idempotency hash
  - import_row_errors         : row-level errors with severity
  - mapping_templates         : field-mapping config per source system
  - mapping_template_versions : immutable snapshot per template version
  - validation_rules          : configurable rule registry
  - validation_results        : per-row validation outcomes
  - reconciliation_reports    : cross-import duplicate/conflict analysis
  - reconciliation_items      : individual reconciliation findings
  - import_audit_events       : structured audit trail

Existing ImportJob / ImportError tables from Sprint 1 are EXTENDED via
relationships but not modified.
"""

from __future__ import annotations

import enum

from sqlalchemy import (
    BigInteger, Boolean, CheckConstraint, Column, DateTime, Enum,
    ForeignKey, Index, Integer, Numeric, SmallInteger, String, Text,
    UniqueConstraint,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.db.database import Base


# ── Helpers ───────────────────────────────────────────────────────────────────

def _vals(e):
    return [m.value for m in e]


# ── Enums ─────────────────────────────────────────────────────────────────────

class BatchStatusEnum(str, enum.Enum):
    PENDING             = "pending"
    PROCESSING          = "processing"
    COMPLETED           = "completed"
    FAILED              = "failed"
    PARTIALLY_COMPLETED = "partially_completed"


class ImportTypeEnum(str, enum.Enum):
    STUDENTS    = "students"
    TRANSCRIPTS = "transcripts"
    CURRICULUM  = "curriculum"


class FileFormatEnum(str, enum.Enum):
    CSV  = "csv"
    XLSX = "xlsx"
    JSON = "json"


class SourceSystemEnum(str, enum.Enum):
    REGISTRAR  = "registrar"
    SIS        = "sis"
    ERP        = "erp"
    CURRICULUM = "curriculum"
    MANUAL     = "manual"
    API        = "api"
    UNKNOWN    = "unknown"


class ValidationSeverityEnum(str, enum.Enum):
    ERROR   = "error"
    WARNING = "warning"
    INFO    = "info"


class ValidationCategoryEnum(str, enum.Enum):
    REFERENTIAL = "referential"
    ACADEMIC    = "academic"
    CURRICULUM  = "curriculum"
    INTEGRITY   = "integrity"
    BUSINESS    = "business"


class ReconciliationStatusEnum(str, enum.Enum):
    OPEN     = "open"
    RESOLVED = "resolved"
    IGNORED  = "ignored"


class ReconciliationTypeEnum(str, enum.Enum):
    DUPLICATE = "duplicate"
    CONFLICT  = "conflict"
    MISMATCH  = "mismatch"


class AuditEventTypeEnum(str, enum.Enum):
    IMPORT_STARTED    = "import_started"
    IMPORT_COMPLETED  = "import_completed"
    IMPORT_FAILED     = "import_failed"
    VALIDATION_RAN    = "validation_ran"
    RECONCILE_RAN     = "reconcile_ran"
    MAPPING_APPLIED   = "mapping_applied"
    ROW_INSERTED      = "row_inserted"
    ROW_FAILED        = "row_failed"
    ROW_SKIPPED       = "row_skipped"
    DUPLICATE_BLOCKED = "duplicate_blocked"


# ═════════════════════════════════════════════════════════════════════════════
# IMPORT BATCHES
# Top-level import session.  File hash provides idempotency.
# ═════════════════════════════════════════════════════════════════════════════

class ImportBatch(Base):
    __tablename__  = "import_batches"
    __table_args__ = (
        UniqueConstraint("file_hash", name="uq_import_batches_file_hash"),
        Index("ix_import_batches_status",      "status"),
        Index("ix_import_batches_import_type", "import_type"),
        Index("ix_import_batches_created_at",  "created_at"),
        {"extend_existing": True},
    )

    id              = Column(BigInteger, primary_key=True, index=True)

    # Identity & idempotency
    batch_ref       = Column(String(64),  nullable=False, unique=True, index=True)  # UUID
    file_hash       = Column(String(64),  nullable=False)  # SHA-256 hex
    file_name       = Column(String(512), nullable=False)
    file_size_bytes = Column(BigInteger,  default=0)
    file_format     = Column(
        Enum(FileFormatEnum, values_callable=_vals, name="file_format_enum"),
        nullable=False, default=FileFormatEnum.CSV,
    )

    # Classification
    import_type   = Column(
        Enum(ImportTypeEnum, values_callable=_vals, name="import_type_enum"),
        nullable=False,
    )
    source_system = Column(
        Enum(SourceSystemEnum, values_callable=_vals, name="source_system_enum"),
        nullable=False, default=SourceSystemEnum.MANUAL,
    )

    # Status & progress
    status         = Column(
        Enum(BatchStatusEnum, values_callable=_vals, name="batch_status_enum"),
        nullable=False, default=BatchStatusEnum.PENDING,
    )
    total_rows     = Column(Integer, default=0)
    success_rows   = Column(Integer, default=0)
    failed_rows    = Column(Integer, default=0)
    skipped_rows   = Column(Integer, default=0)
    warning_count  = Column(Integer, default=0)

    # Ownership
    imported_by    = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    assigned_to    = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))

    # Timing
    started_at     = Column(DateTime(timezone=True))
    completed_at   = Column(DateTime(timezone=True))
    duration_ms    = Column(Integer)  # wall-clock ms

    # Retry & versioning
    retry_count    = Column(SmallInteger, default=0)
    is_reprocess   = Column(Boolean, default=False)
    mapping_version_id = Column(
        BigInteger, ForeignKey("mapping_template_versions.id", ondelete="SET NULL")
    )

    # Notes / JSON metadata
    notes          = Column(Text)
    extra_meta     = Column(JSONB)

    created_at     = Column(DateTime(timezone=True), server_default=func.now())
    updated_at     = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    # Relationships
    row_errors      = relationship("ImportRowError",   back_populates="batch", cascade="all, delete-orphan")
    validation_results = relationship("ValidationResult", back_populates="batch", cascade="all, delete-orphan")
    audit_events    = relationship("ImportAuditEvent", back_populates="batch", cascade="all, delete-orphan")
    mapping_version = relationship("MappingTemplateVersion", back_populates="batches")
    importer        = relationship("User", foreign_keys=[imported_by])


# ═════════════════════════════════════════════════════════════════════════════
# IMPORT ROW ERRORS
# Row-level error/warning log.  Partial failure: success rows are committed
# even when other rows fail.
# ═════════════════════════════════════════════════════════════════════════════

class ImportRowError(Base):
    __tablename__  = "import_row_errors"
    __table_args__ = (
        Index("ix_import_row_errors_batch_id",  "batch_id"),
        Index("ix_import_row_errors_severity",  "severity"),
        {"extend_existing": True},
    )

    id            = Column(BigInteger, primary_key=True, index=True)
    batch_id      = Column(BigInteger, ForeignKey("import_batches.id", ondelete="CASCADE"), nullable=False)
    row_number    = Column(Integer)
    field_name    = Column(String(100))
    raw_value     = Column(Text)
    error_code    = Column(String(50))
    error_message = Column(Text, nullable=False)
    severity      = Column(
        Enum(ValidationSeverityEnum, values_callable=_vals, name="val_severity_enum"),
        nullable=False, default=ValidationSeverityEnum.ERROR,
    )
    category      = Column(
        Enum(ValidationCategoryEnum, values_callable=_vals, name="val_category_enum"),
    )
    extra_context = Column(JSONB)
    created_at    = Column(DateTime(timezone=True), server_default=func.now())

    batch = relationship("ImportBatch", back_populates="row_errors")


# ═════════════════════════════════════════════════════════════════════════════
# MAPPING TEMPLATES
# Configurable field mappings between external source columns → internal fields
# ═════════════════════════════════════════════════════════════════════════════

class MappingTemplate(Base):
    __tablename__  = "mapping_templates"
    __table_args__ = (
        UniqueConstraint("name", "import_type", name="uq_mapping_templates_name_type"),
        {"extend_existing": True},
    )

    id          = Column(BigInteger, primary_key=True, index=True)
    name        = Column(String(100), nullable=False)
    description = Column(Text)
    import_type = Column(
        Enum(ImportTypeEnum, values_callable=_vals, name="mt_import_type_enum"),
        nullable=False,
    )
    source_system = Column(
        Enum(SourceSystemEnum, values_callable=_vals, name="mt_source_system_enum"),
        nullable=False, default=SourceSystemEnum.MANUAL,
    )
    is_active   = Column(Boolean, default=True)
    created_by  = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    created_at  = Column(DateTime(timezone=True), server_default=func.now())
    updated_at  = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    versions    = relationship("MappingTemplateVersion", back_populates="template", cascade="all, delete-orphan")
    creator     = relationship("User", foreign_keys=[created_by])


class MappingTemplateVersion(Base):
    """Immutable snapshot of a mapping template at a given version number."""
    __tablename__  = "mapping_template_versions"
    __table_args__ = (
        UniqueConstraint("template_id", "version_number", name="uq_mtv_template_version"),
        {"extend_existing": True},
    )

    id              = Column(BigInteger, primary_key=True, index=True)
    template_id     = Column(BigInteger, ForeignKey("mapping_templates.id", ondelete="CASCADE"), nullable=False)
    version_number  = Column(SmallInteger, nullable=False)
    field_mappings  = Column(JSONB, nullable=False)
    # e.g. {"Student ID": "student_code", "Full Name": "full_name", ...}
    transformations = Column(JSONB)
    # e.g. {"grade": "uppercase", "student_code": "strip"}
    is_current      = Column(Boolean, default=False)
    published_by    = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    published_at    = Column(DateTime(timezone=True), server_default=func.now())
    notes           = Column(Text)

    template = relationship("MappingTemplate", back_populates="versions")
    batches  = relationship("ImportBatch", back_populates="mapping_version")


# ═════════════════════════════════════════════════════════════════════════════
# VALIDATION RULES
# Configurable rule registry — rules are evaluated by the validation engine
# ═════════════════════════════════════════════════════════════════════════════

class ValidationRule(Base):
    __tablename__  = "validation_rules"
    __table_args__ = (
        UniqueConstraint("rule_code", name="uq_validation_rules_code"),
        {"extend_existing": True},
    )

    id          = Column(BigInteger, primary_key=True, index=True)
    rule_code   = Column(String(50),  nullable=False)  # e.g. "REF_STUDENT_EXISTS"
    rule_name   = Column(String(150), nullable=False)
    description = Column(Text)
    category    = Column(
        Enum(ValidationCategoryEnum, values_callable=_vals, name="vr_category_enum"),
        nullable=False,
    )
    import_type = Column(
        Enum(ImportTypeEnum, values_callable=_vals, name="vr_import_type_enum"),
    )
    severity    = Column(
        Enum(ValidationSeverityEnum, values_callable=_vals, name="vr_severity_enum"),
        nullable=False, default=ValidationSeverityEnum.ERROR,
    )
    is_active   = Column(Boolean, default=True)
    rule_config = Column(JSONB)  # extra rule params
    created_at  = Column(DateTime(timezone=True), server_default=func.now())
    updated_at  = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())


# ═════════════════════════════════════════════════════════════════════════════
# VALIDATION RESULTS
# Stored per-row validation outcome per batch.  Queryable for audit.
# ═════════════════════════════════════════════════════════════════════════════

class ValidationResult(Base):
    __tablename__  = "validation_results"
    __table_args__ = (
        Index("ix_validation_results_batch_id",  "batch_id"),
        Index("ix_validation_results_passed",    "passed"),
        {"extend_existing": True},
    )

    id         = Column(BigInteger, primary_key=True, index=True)
    batch_id   = Column(BigInteger, ForeignKey("import_batches.id", ondelete="CASCADE"), nullable=False)
    row_number = Column(Integer)
    rule_code  = Column(String(50))
    field_name = Column(String(100))
    raw_value  = Column(Text)
    passed     = Column(Boolean, nullable=False)
    severity   = Column(
        Enum(ValidationSeverityEnum, values_callable=_vals, name="vres_severity_enum"),
        nullable=False, default=ValidationSeverityEnum.ERROR,
    )
    message    = Column(Text)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    batch = relationship("ImportBatch", back_populates="validation_results")


# ═════════════════════════════════════════════════════════════════════════════
# RECONCILIATION REPORTS + ITEMS
# Cross-import duplicate/conflict detection output
# ═════════════════════════════════════════════════════════════════════════════

class ReconciliationReport(Base):
    __tablename__  = "reconciliation_reports"
    __table_args__ = (
        Index("ix_recon_reports_batch_id",    "batch_id"),
        Index("ix_recon_reports_import_type", "import_type"),
        {"extend_existing": True},
    )

    id           = Column(BigInteger, primary_key=True, index=True)
    batch_id     = Column(BigInteger, ForeignKey("import_batches.id", ondelete="CASCADE"), nullable=False)
    import_type  = Column(
        Enum(ImportTypeEnum, values_callable=_vals, name="rr_import_type_enum"),
        nullable=False,
    )
    total_checked    = Column(Integer, default=0)
    duplicates_found = Column(Integer, default=0)
    conflicts_found  = Column(Integer, default=0)
    mismatches_found = Column(Integer, default=0)
    summary          = Column(JSONB)
    generated_at     = Column(DateTime(timezone=True), server_default=func.now())

    items = relationship("ReconciliationItem", back_populates="report", cascade="all, delete-orphan")
    batch = relationship("ImportBatch")


class ReconciliationItem(Base):
    __tablename__  = "reconciliation_items"
    __table_args__ = (
        Index("ix_recon_items_report_id", "report_id"),
        Index("ix_recon_items_status",    "status"),
        {"extend_existing": True},
    )

    id              = Column(BigInteger, primary_key=True, index=True)
    report_id       = Column(BigInteger, ForeignKey("reconciliation_reports.id", ondelete="CASCADE"), nullable=False)
    recon_type      = Column(
        Enum(ReconciliationTypeEnum, values_callable=_vals, name="recon_type_enum"),
        nullable=False,
    )
    entity_type     = Column(String(50))   # "student", "course", "curriculum_entry"
    entity_key      = Column(String(255))  # natural key, e.g. student_code
    incoming_value  = Column(JSONB)
    existing_value  = Column(JSONB)
    conflict_fields = Column(JSONB)        # list of differing field names
    status          = Column(
        Enum(ReconciliationStatusEnum, values_callable=_vals, name="recon_status_enum"),
        nullable=False, default=ReconciliationStatusEnum.OPEN,
    )
    resolved_by     = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    resolved_at     = Column(DateTime(timezone=True))
    resolution_note = Column(Text)
    created_at      = Column(DateTime(timezone=True), server_default=func.now())

    report = relationship("ReconciliationReport", back_populates="items")


# ═════════════════════════════════════════════════════════════════════════════
# IMPORT AUDIT EVENTS
# Structured, append-only audit trail for every import action
# ═════════════════════════════════════════════════════════════════════════════

class ImportAuditEvent(Base):
    __tablename__  = "import_audit_events"
    __table_args__ = (
        Index("ix_import_audit_batch_id",    "batch_id"),
        Index("ix_import_audit_event_type",  "event_type"),
        Index("ix_import_audit_created_at",  "created_at"),
        {"extend_existing": True},
    )

    id         = Column(BigInteger, primary_key=True, index=True)
    batch_id   = Column(BigInteger, ForeignKey("import_batches.id", ondelete="CASCADE"), nullable=False)
    event_type = Column(
        Enum(AuditEventTypeEnum, values_callable=_vals, name="audit_event_type_enum"),
        nullable=False,
    )
    actor_id   = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    row_number = Column(Integer)
    message    = Column(Text)
    payload    = Column(JSONB)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    batch = relationship("ImportBatch", back_populates="audit_events")
    actor = relationship("User", foreign_keys=[actor_id])
