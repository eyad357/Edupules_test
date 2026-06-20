# EduGuard AI — Sprint 4 Enterprise Final
## Apply Instructions

### Prerequisites
- Sprint 1, 2, 3 fully deployed and running
- Sprint 4 Core deployed (migrations 008 applied)
- PostgreSQL running and accessible
- Python 3.10+ with existing requirements installed

---

## Step 1: Extract the package

```bash
tar -xzf Edupules_Sprint4_Enterprise_Final.tar.gz --strip-components=1
```

This overlays new files onto your existing repository. No existing files are deleted.

---

## Step 2: Install optional PDF dependency

```bash
pip install reportlab --break-system-packages
```

`reportlab` enables production PDF transcript generation.
Without it, PDF jobs complete with a stub placeholder — the system still functions.

---

## Step 3: Run database migrations in order

```bash
# If not already applied:
psql -U postgres -d eduguard -f database/008_sprint4_academic_intelligence.sql

# New in this release:
psql -U postgres -d eduguard -f database/009_sprint4_extended_tables.sql
psql -U postgres -d eduguard -f database/010_enterprise_academic_platform.sql
```

All migrations are idempotent — safe to re-run.

---

## Step 4: Start the server

```bash
cd backend
uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4
```

---

## Step 5: Verify all routers are registered

```bash
curl -s http://localhost:8000/openapi.json | python3 -c \
  "import json,sys; paths=json.load(sys.stdin)['paths']; \
   enterprise=[p for p in paths if '/enterprise/' in p]; \
   print(f'Enterprise endpoints: {len(enterprise)}')"
```

Expected: `Enterprise endpoints: 35+`

---

## Step 6: Verify policy gap status

```bash
curl http://localhost:8000/api/v1/academic/policy-gaps
```

Expected: `pending_count >= 19` with full list of unconfigured rules.

---

## Step 7: Configure pending policies (when regulation documents available)

```bash
# Example: configure graduation CGPA after uploading university regulations
curl -X PUT http://localhost:8000/api/v1/academic/rules/{rule_id} \
  -H "Content-Type: application/json" \
  -d '{"rule_value": "2.00", "description": "[SOURCE: University Graduation Bylaws, Art. 45]"}'
```

---

## Rollback

Each migration is wrapped in `BEGIN/COMMIT`. To rollback enterprise tables:

```sql
DROP TABLE IF EXISTS
  prerequisite_validations,
  registrar_task_assignments, registrar_tasks,
  pdf_transcript_jobs, academic_record_versions,
  academic_exemptions, transfer_credits,
  academic_case_decisions, academic_cases,
  student_documents, registration_events,
  cohort_memberships, student_cohorts
CASCADE;
```
