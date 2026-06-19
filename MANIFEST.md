# MANIFEST.md — EduGuard AI Sprint 3 Deployment Package

## Files Added (new — did not exist before Sprint 3)

| Path | Description |
|------|-------------|
| `backend/app/models/sprint3_models.py` | 9 SQLAlchemy ORM models + 9 enums for the Import Platform |
| `backend/app/schemas/sprint3_schemas.py` | 18 Pydantic v2 request/response schemas |
| `backend/app/services/sprint3_mapping.py` | Mapping Engine — field renaming, transforms, versioned templates |
| `backend/app/services/sprint3_validation.py` | Validation Engine — 5-category rule system, reference cache |
| `backend/app/services/sprint3_reconciliation.py` | Reconciliation Engine — DUPLICATE / CONFLICT / MISMATCH detection |
| `backend/app/services/sprint3_import_engine.py` | Import Pipeline — parse → map → validate → persist → reconcile → audit |
| `backend/app/routers/sprint3_router.py` | 16 FastAPI endpoints for the Import Platform |
| `database/007_sprint3_import_platform.sql` | Additive SQL migration (9 tables, 9 enum types, 16 seed rules) |
| `SPRINT3_DELIVERY.md` | Architecture and feature documentation |
| `MANIFEST.md` | This file |
| `APPLY_INSTRUCTIONS.md` | Step-by-step deployment instructions |
| `VALIDATION_CHECKLIST.md` | Post-deployment verification checklist |

## Files Modified (existing files with Sprint 3 additions)

| Path | Change |
|------|--------|
| `backend/app/models/__init__.py` | Added imports and `__all__` exports for all 9 Sprint 3 models and 9 enums |
| `backend/main.py` | Added `sprint3_router` import and `app.include_router(sprint3_router)` registration |
| `backend/app/routers/sprint2_router.py` | Fixed pre-existing import bugs: `TranscriptRow` → `TranscriptAttemptRow`, `PrerequisiteChainNode` → `PrerequisiteNodeRead` (these caused startup failure before this fix) |

## New Database Tables (created by migration / create_all)

| Table | Rows at creation |
|-------|-----------------|
| `import_batches` | 0 |
| `import_row_errors` | 0 |
| `mapping_templates` | 0 |
| `mapping_template_versions` | 0 |
| `validation_rules` | 16 (seeded) |
| `validation_results` | 0 |
| `reconciliation_reports` | 0 |
| `reconciliation_items` | 0 |
| `import_audit_events` | 0 |

## No Sprint 1 or Sprint 2 Tables Were Modified
All changes are purely additive.
