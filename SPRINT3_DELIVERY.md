# EduGuard AI — Sprint 3 Delivery Report
## Academic Data Import & Validation Platform

---

## Architecture Overview

Sprint 3 implements a production-grade Academic Data Import & Validation Platform
layered on top of the existing Sprint 1 + Sprint 2 architecture.
No existing tables, models, services, or routes were modified.

```
┌─────────────────────────────────────────────────────────────┐
│                   Sprint 3 Platform                         │
│                                                             │
│  POST /imports/{type}                                       │
│       │                                                     │
│       ▼                                                     │
│  Import Engine (sprint3_import_engine.py)                   │
│  ├─ File Hash → Idempotency Check                           │
│  ├─ Create ImportBatch record                               │
│  ├─ Parse (CSV / XLSX / JSON)                               │
│  ├─ Apply Mapping (MappingEngine)                           │
│  ├─ Validate (ValidationEngine)  ──→ ValidationResult rows  │
│  │                               ──→ ImportRowError rows    │
│  ├─ Persist valid rows (bulk insert)                        │
│  ├─ Reconcile (ReconciliationEngine) ──→ ReconReport        │
│  └─ Audit trail (ImportAuditEvent rows)                     │
└─────────────────────────────────────────────────────────────┘
```

---

## Database Schema Changes (Additive Only)

### New Tables

| Table | Purpose |
|---|---|
| `mapping_templates` | Named field-mapping configs per source system |
| `mapping_template_versions` | Immutable versioned snapshots of mappings |
| `import_batches` | Top-level import session with idempotency hash |
| `import_row_errors` | Row-level errors/warnings with severity + category |
| `validation_rules` | Configurable rule registry (16 built-in rules seeded) |
| `validation_results` | Persisted per-row validation outcomes |
| `reconciliation_reports` | Cross-import duplicate/conflict analysis |
| `reconciliation_items` | Individual reconciliation findings |
| `import_audit_events` | Structured append-only audit trail |

### New PostgreSQL Enum Types

`batch_status_enum`, `import_type_enum`, `file_format_enum`,
`source_system_enum`, `val_severity_enum`, `val_category_enum`,
`recon_type_enum`, `recon_status_enum`, `audit_event_type_enum`

---

## Files Created

### Models
- `backend/app/models/sprint3_models.py` — 9 ORM models + 9 enums

### Schemas
- `backend/app/schemas/sprint3_schemas.py` — 20+ Pydantic request/response schemas

### Services
- `backend/app/services/sprint3_mapping.py` — Mapping Engine
- `backend/app/services/sprint3_validation.py` — Validation Engine
- `backend/app/services/sprint3_reconciliation.py` — Reconciliation Engine
- `backend/app/services/sprint3_import_engine.py` — Import Engine (pipeline coordinator)

### Router
- `backend/app/routers/sprint3_router.py` — 16 API endpoints

### Migration
- `database/007_sprint3_import_platform.sql` — Additive SQL migration

## Files Modified

- `backend/app/models/__init__.py` — Added Sprint 3 model exports
- `backend/main.py` — Registered `sprint3_router`

---

## API Endpoints (16 total)

### Import Operations
| Method | Path | Description |
|---|---|---|
| POST | `/api/v1/imports/students` | Import student records |
| POST | `/api/v1/imports/transcripts` | Import transcript/attempt records |
| POST | `/api/v1/imports/curriculum` | Import course catalog |
| GET  | `/api/v1/imports` | List all batches (paginated, filterable) |
| GET  | `/api/v1/imports/{batch_ref}` | Full batch detail |
| GET  | `/api/v1/imports/{batch_ref}/errors` | Row-level errors (paginated) |
| GET  | `/api/v1/imports/{batch_ref}/report` | Import summary report |
| GET  | `/api/v1/imports/{batch_ref}/reconciliation` | Reconciliation report |
| GET  | `/api/v1/imports/{batch_ref}/audit` | Full audit trail |

### Mapping Templates
| Method | Path | Description |
|---|---|---|
| GET  | `/api/v1/mapping-templates` | List templates |
| POST | `/api/v1/mapping-templates` | Create template |
| PUT  | `/api/v1/mapping-templates/{id}` | Update (publishes new version) |
| GET  | `/api/v1/mapping-templates/{id}/versions` | List all versions |

### Rules & Reconciliation
| Method | Path | Description |
|---|---|---|
| GET  | `/api/v1/validation-rules` | List validation rules |
| GET  | `/api/v1/reconciliation-reports` | List all reports |
| GET  | `/api/v1/reconciliation-reports/{id}` | Single report with items |

---

## Engines

### Import Engine
- Supports CSV, XLSX, JSON
- SHA-256 file hash for idempotency (duplicate uploads auto-detected)
- Partial failure handling: valid rows committed, failed rows logged
- Batch inserts (no N+1 writes)

### Mapping Engine
- Configurable field mappings (external column → internal field)
- Immutable versioned templates (3 built-in: Registrar Students, Registrar Transcripts, Curriculum)
- Field transformations: strip, upper, lower, title, int, float
- Historical imports record exact mapping version used

### Validation Engine
- 16 built-in rules across 5 categories: REFERENTIAL, ACADEMIC, CURRICULUM, INTEGRITY, BUSINESS
- Reference cache (loads all student codes, course codes, term names, grades once per batch)
- Per-row results persisted to `validation_results`
- ERROR-severity violations block the row; WARNING-severity rows still proceed
- Within-batch duplicate detection

### Reconciliation Engine
- Compares incoming rows against existing database records
- Detects: DUPLICATE (same key, same values), CONFLICT (same key, different values), MISMATCH
- Generates granular ReconciliationItems with full incoming vs existing data
- Items remain OPEN for future manual resolution workflow

### Audit Engine
- Structured audit events for every pipeline stage
- 10 event types: IMPORT_STARTED, IMPORT_COMPLETED, IMPORT_FAILED, VALIDATION_RAN,
  RECONCILE_RAN, MAPPING_APPLIED, ROW_INSERTED, ROW_FAILED, ROW_SKIPPED, DUPLICATE_BLOCKED
- All events stored with timestamp, actor_id, row_number, payload JSON

---

## Production Requirements Coverage

| Requirement | Implementation |
|---|---|
| Idempotency | SHA-256 file hash stored in `import_batches.file_hash` with UNIQUE constraint |
| Partial failure | Rows validated individually; valid rows committed regardless of others |
| Async-compatible | Pipeline is synchronous but isolated per request; ready for background task wrapping |
| Versioning | `mapping_template_versions` — immutable snapshots; curriculum year stored per row |
| Bulk inserts | `db.bulk_save_objects()` used for all row persisting |
| No N+1 queries | Reference cache loads all lookup data in single queries before row loop |
| Role security | All endpoints require admin, advisor, or professor role via JWT |
| Audit logging | Structured `ImportAuditEvent` rows for full traceability |
| Pagination | All list endpoints support `page` + `page_size` query params |
| Filtering | Import list filters by `import_type` and `status` |

---

## To Deploy

1. Apply migration: `psql -d eduguard -f database/007_sprint3_import_platform.sql`
2. Restart backend: `uvicorn main:app --reload`
3. Tables auto-created via SQLAlchemy `Base.metadata.create_all()` on startup
4. Visit `/docs` → Sprint 3 - Import Platform section

---

## Validation Checklist

- [x] All Sprint 3 modules import without errors
- [x] Router registers 16 routes cleanly
- [x] No circular imports
- [x] No breaking changes to Sprint 1 or Sprint 2 models/routers
- [x] `apply_mapping()` tested: correct field rename + transformation
- [x] `parse_csv()` tested: 2-row CSV → 2 dicts
- [x] `parse_xlsx()` tested: XLSX → row dicts
- [x] `parse_json()` tested: envelope key extraction
- [x] `compute_file_hash()` tested: deterministic SHA-256
- [x] `models/__init__.py` exports all Sprint 3 models
- [x] `main.py` registers `sprint3_router`
