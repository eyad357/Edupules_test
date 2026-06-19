# APPLY_INSTRUCTIONS.md — Sprint 3 Deployment Guide

## Prerequisites
- Existing EduGuard AI Sprint 1 + Sprint 2 codebase cloned from GitHub
- PostgreSQL database already running with Sprint 1 + Sprint 2 tables
- Python 3.10+ environment with existing dependencies installed

---

## Step 1 — Extract the archive into your repository root

```bash
# Navigate to the root of your repository (same level as backend/ and database/)
cd /path/to/your/Edupules_test

# Extract — this will overwrite only the Sprint 3 files
tar -xzf Edupules_test_fixed.tar.gz
```

The archive preserves the exact repository structure. Extraction will:
- Add 7 new Python files under `backend/app/`
- Overwrite 3 existing files (`__init__.py`, `main.py`, `sprint2_router.py`) with Sprint 3-compatible versions
- Add `database/007_sprint3_import_platform.sql`
- Add `MANIFEST.md`, `APPLY_INSTRUCTIONS.md`, `VALIDATION_CHECKLIST.md`

---

## Step 2 — Install the one new dependency

```bash
cd backend
pip install openpyxl
```

> `openpyxl` is required for XLSX file parsing. All other dependencies are already present from Sprint 1 and Sprint 2.

---

## Step 3 — Create the new database tables

Run this from inside the `backend/` directory:

```bash
cd backend
python3 -c "
from app.db.database import engine, Base
import app.models.models
import app.models.academic_models
import app.models.sprint3_models
Base.metadata.create_all(bind=engine)
print('Sprint 3 tables created successfully')
"
```

This is safe to run multiple times — SQLAlchemy skips tables that already exist.

---

## Step 4 — Seed the 16 built-in validation rules

```bash
cd backend
python3 -c "
from app.db.database import SessionLocal
from app.models.sprint3_models import (
    ValidationRule, ValidationCategoryEnum,
    ValidationSeverityEnum, ImportTypeEnum
)

db = SessionLocal()

rules = [
  ('REQ_STUDENT_CODE',      'Student Code Required',           'student_code must be present and non-empty',  'integrity',   'students',    'error'),
  ('REQ_FULL_NAME',         'Full Name Required',              'full_name must be present and non-empty',     'integrity',   'students',    'error'),
  ('REQ_COURSE_CODE',       'Course Code Required',            'course_code must be present and non-empty',   'integrity',   'transcripts', 'error'),
  ('REQ_COURSE_NAME',       'Course Name Required',            'course_name required for curriculum import',  'integrity',   'curriculum',  'error'),
  ('REF_STUDENT_EXISTS',    'Student Exists Check',            'student_code must exist in the database',     'referential', 'transcripts', 'error'),
  ('REF_COURSE_EXISTS',     'Course Exists Check',             'course_code must exist in the catalog',       'referential', 'transcripts', 'error'),
  ('REF_TERM_EXISTS',       'Term Exists Check',               'term_name must exist in academic_terms',      'referential', 'transcripts', 'warning'),
  ('ACAD_INVALID_GRADE',    'Grade Validity Check',            'grade must be a recognised letter grade',     'academic',    'transcripts', 'error'),
  ('ACAD_INVALID_CREDITS',  'Credit Hours Range Check',        'credit_hours must be numeric and 0-6',        'academic',    None,          'warning'),
  ('ACAD_GPA_OUT_OF_RANGE', 'GPA Range Check',                 'GPA values must be in range 0.0-4.0',         'academic',    None,          'warning'),
  ('BIZ_INVALID_EMAIL',     'Email Format Check',              'university_email must contain @',             'business',    'students',    'warning'),
  ('BIZ_INVALID_ENROLL_YEAR','Enrollment Year Range Check',    'enrollment_year must be integer 2000-2030',   'business',    'students',    'warning'),
  ('INT_DUPLICATE_IN_BATCH','Intra-Batch Duplicate Check',     'Same student_code cannot appear twice in file','integrity',  'students',    'error'),
  ('INT_DUPLICATE_ATTEMPT', 'Duplicate Attempt in Batch',      'Same student+course+attempt in one file',     'integrity',   'transcripts', 'error'),
  ('CURR_INVALID_CATEGORY', 'Curriculum Category Check',       'category must be a recognised curriculum value','curriculum','curriculum',  'warning'),
  ('CURR_INVALID_YEAR',     'Curriculum Year Range Check',     'curriculum_year must be integer 2010-2030',   'curriculum',  'curriculum',  'warning'),
]

created = 0
for code, name, desc, cat, itype, sev in rules:
    exists = db.query(ValidationRule).filter(ValidationRule.rule_code == code).first()
    if not exists:
        db.add(ValidationRule(
            rule_code=code,
            rule_name=name,
            description=desc,
            category=ValidationCategoryEnum(cat),
            import_type=ImportTypeEnum(itype) if itype else None,
            severity=ValidationSeverityEnum(sev),
            is_active=True,
        ))
        created += 1

db.commit()
db.close()
print(f'Done — {created} rules seeded ({16 - created} already existed)')
"
```

---

## Step 5 — Start the server

```bash
cd backend
uvicorn main:app --reload
```

---

## Step 6 — Verify in the browser

Open: `http://localhost:8000/docs`

Scroll to the **Sprint 3 - Import Platform** section. You should see 16 endpoints grouped under:
- `POST /api/v1/imports/students`
- `POST /api/v1/imports/transcripts`
- `POST /api/v1/imports/curriculum`
- `GET  /api/v1/imports` (and sub-routes)
- `GET/POST/PUT /api/v1/mapping-templates`
- `GET /api/v1/validation-rules`
- `GET /api/v1/reconciliation-reports`

---

## Rollback (if needed)

Sprint 3 is fully additive. To roll back:
1. Stop the server.
2. Drop the 9 new tables: `import_batches`, `import_row_errors`, `mapping_templates`, `mapping_template_versions`, `validation_rules`, `validation_results`, `reconciliation_reports`, `reconciliation_items`, `import_audit_events`.
3. Restore the original `backend/app/models/__init__.py` and `backend/main.py` from git.
4. Restart the server.

No Sprint 1 or Sprint 2 data is ever affected.
