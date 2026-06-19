# VALIDATION_CHECKLIST.md — Sprint 3 Post-Deployment Verification

Run each check after completing APPLY_INSTRUCTIONS.md.

---

## A. Import Checks (run from `backend/` directory)

```bash
cd backend
python3 -c "
import sys; sys.path.insert(0, '.')

checks = []

def chk(label, fn):
    try:
        fn()
        checks.append((label, True, ''))
    except Exception as e:
        checks.append((label, False, str(e)[:100]))

chk('sprint3_models',          lambda: __import__('app.models.sprint3_models', fromlist=['ImportBatch']))
chk('sprint3_schemas',         lambda: __import__('app.schemas.sprint3_schemas', fromlist=['ImportBatchOut']))
chk('sprint3_mapping',         lambda: __import__('app.services.sprint3_mapping', fromlist=['apply_mapping']))
chk('sprint3_validation',      lambda: __import__('app.services.sprint3_validation', fromlist=['run_validation']))
chk('sprint3_reconciliation',  lambda: __import__('app.services.sprint3_reconciliation', fromlist=['run_reconciliation']))
chk('sprint3_import_engine',   lambda: __import__('app.services.sprint3_import_engine', fromlist=['run_import_pipeline']))
chk('sprint3_router',          lambda: __import__('app.routers.sprint3_router', fromlist=['sprint3_router']))
chk('sprint2_router (fixed)',  lambda: __import__('app.routers.sprint2_router', fromlist=['sprint2_router']))
chk('models __init__ exports', lambda: __import__('app.models', fromlist=['ImportBatch', 'MappingTemplate']))

passed = sum(1 for _, ok, _ in checks if ok)
for label, ok, err in checks:
    print(('OK  ' if ok else 'FAIL') + '  ' + label + ('  -> ' + err if err else ''))
print()
print(str(passed) + '/' + str(len(checks)) + ' import checks passed')
"
```

**Expected:** `9/9 import checks passed`

---

## B. Route Registration Check

```bash
cd backend
python3 -c "
import sys; sys.path.insert(0, '.')
from app.routers.sprint3_router import sprint3_router
paths = sorted(r.path for r in sprint3_router.routes)
for p in paths:
    print(p)
print()
print(str(len(paths)) + ' routes registered')
"
```

**Expected output — 16 routes:**
```
/api/v1/imports
/api/v1/imports/curriculum
/api/v1/imports/students
/api/v1/imports/transcripts
/api/v1/imports/{batch_ref}
/api/v1/imports/{batch_ref}/audit
/api/v1/imports/{batch_ref}/errors
/api/v1/imports/{batch_ref}/reconciliation
/api/v1/imports/{batch_ref}/report
/api/v1/mapping-templates
/api/v1/mapping-templates
/api/v1/mapping-templates/{template_id}
/api/v1/mapping-templates/{template_id}/versions
/api/v1/reconciliation-reports
/api/v1/reconciliation-reports/{report_id}
/api/v1/validation-rules
```

---

## C. Database Table Check

```bash
cd backend
python3 -c "
import sys; sys.path.insert(0, '.')
from app.db.database import engine
from sqlalchemy import inspect

inspector = inspect(engine)
existing = set(inspector.get_table_names())

required = [
    'import_batches',
    'import_row_errors',
    'mapping_templates',
    'mapping_template_versions',
    'validation_rules',
    'validation_results',
    'reconciliation_reports',
    'reconciliation_items',
    'import_audit_events',
]

all_ok = True
for t in required:
    ok = t in existing
    print(('OK  ' if ok else 'MISS') + '  ' + t)
    if not ok:
        all_ok = False

print()
print('All Sprint 3 tables present: ' + str(all_ok))
"
```

**Expected:** All 9 tables show `OK`

---

## D. Validation Rules Seeded Check

```bash
cd backend
python3 -c "
import sys; sys.path.insert(0, '.')
from app.db.database import SessionLocal
from app.models.sprint3_models import ValidationRule

db = SessionLocal()
count = db.query(ValidationRule).count()
db.close()
print('Validation rules in DB: ' + str(count))
print('Expected: 16')
print('OK' if count >= 16 else 'FAIL — run seed step from APPLY_INSTRUCTIONS.md')
"
```

**Expected:** `Validation rules in DB: 16`

---

## E. Server Startup Check

```bash
cd backend
uvicorn main:app --host 0.0.0.0 --port 8000
```

**Expected:** No `ImportError`, `NameError`, or `AttributeError` in startup output.

---

## F. Live API Check (server must be running)

```bash
# GET /api/v1/imports — requires auth token
# Replace TOKEN with a valid JWT from your login endpoint

curl -s -H "Authorization: Bearer TOKEN" \
  http://localhost:8000/api/v1/imports | python3 -m json.tool
```

**Expected response:**
```json
{
    "total": 0,
    "page": 1,
    "page_size": 20,
    "items": []
}
```

---

## G. File Upload Test (server must be running)

Create a test CSV file:
```bash
echo "Student ID,Full Name,Email,Enrollment Year
S999,Test Student,test@nmu.edu.eg,2024" > /tmp/test_students.csv
```

Upload it:
```bash
curl -s -X POST \
  -H "Authorization: Bearer TOKEN" \
  -F "file=@/tmp/test_students.csv" \
  -F "source_system=manual" \
  http://localhost:8000/api/v1/imports/students | python3 -m json.tool
```

**Expected response includes:**
```json
{
    "batch_ref": "...",
    "status": "completed",
    "total_rows": 1,
    ...
}
```

---

## Summary

| Check | Command | Expected |
|-------|---------|----------|
| A. Imports | `python3 -c "..."` | 9/9 passed |
| B. Routes | `python3 -c "..."` | 16 routes |
| C. Tables | `python3 -c "..."` | 9 tables OK |
| D. Rules | `python3 -c "..."` | 16 rules |
| E. Startup | `uvicorn main:app` | No errors |
| F. API GET | `curl ...` | `{"total":0,...}` |
| G. Upload | `curl -F file=...` | `status: completed` |

All 7 checks passing = Sprint 3 fully operational.
