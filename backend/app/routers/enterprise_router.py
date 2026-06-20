"""
EduGuard AI — Enterprise Router
=================================
All enterprise module endpoints. Prefix: /api/v1/enterprise

Modules:
  /cohorts/*                  — Cohort Management
  /students/{id}/cohort       — Student Cohort
  /students/{id}/registration-history  — Registration Events
  /students/{id}/documents    — Document Registry
  /students/{id}/cases        — Academic Cases
  /cases/*                    — Case Management (registrar view)
  /students/{id}/transfers    — Transfer Credits
  /students/{id}/exemptions   — Academic Exemptions
  /students/{id}/record-versions — Academic Record Versioning
  /students/{id}/pdf-transcript  — PDF Export
  /registrar/*                — Registrar Workspace
  /students/{id}/prerequisites — Prerequisite Validation
  /students/{id}/profile      — Enterprise Profile Aggregation
"""

from __future__ import annotations

import logging
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.models.models import Student

from app.schemas.enterprise_schemas import (
    CohortCreate, CohortRead, CohortEnrollRequest, CohortMemberRead,
    RegistrationEventCreate, RegistrationEventRead,
    DocumentUploadRequest, DocumentRead, DocumentRegistryResponse,
    CaseSubmitRequest, CaseTransitionRequest, CaseRead,
    TransferCreditSubmitRequest, TransferCreditApproveRequest,
    TransferCreditRejectRequest, TransferCreditRead,
    ExemptionRequestBody, ExemptionApproveRequest, ExemptionRejectRequest, ExemptionRead,
    RecordVersionRead, RecordVersionCompareResponse,
    PDFJobRequest, PDFJobRead,
    TaskCreateRequest, TaskAssignRequest, TaskCompleteRequest, TaskRead, WorkspaceSummary,
    PrerequisiteCheckRequest, PrerequisiteValidationRead,
    StudentEnterpriseProfile,
)
from app.services.enterprise_services import (
    CohortService, RegistrationHistoryService, DocumentService,
    AcademicCaseService, TransferCreditService, ExemptionService,
    AcademicRecordVersionService, PDFTranscriptService,
    RegistrarTaskService, PrerequisiteService,
)
from app.repositories.enterprise_repositories import (
    CohortRepository, CohortMembershipRepository,
    RegistrationEventRepository, DocumentRepository,
    AcademicCaseRepository, TransferCreditRepository,
    ExemptionRepository, AcademicRecordVersionRepository,
    PDFTranscriptJobRepository, RegistrarTaskRepository,
    PrerequisiteValidationRepository,
)
from app.models.enterprise_models import (
    RegistrationEventTypeEnum, RecordVersionTriggerEnum,
    TaskPriorityEnum, CaseStatusEnum,
)

logger = logging.getLogger(__name__)

enterprise_router = APIRouter(tags=["Enterprise Academic Platform"])


def _student_or_404(db: Session, student_id: int) -> Student:
    s = db.query(Student).filter(Student.id == student_id).first()
    if not s:
        raise HTTPException(404, f"Student {student_id} not found")
    return s


# ═════════════════════════════════════════════════════════════════════════════
# MODULE 1: COHORT MANAGEMENT
# ═════════════════════════════════════════════════════════════════════════════

@enterprise_router.post("/cohorts", response_model=CohortRead, status_code=201,
                        summary="Create a new student cohort")
def create_cohort(data: CohortCreate, db: Session = Depends(get_db)):
    try:
        cohort = CohortService.create_cohort(db, data.model_dump())
        return cohort
    except ValueError as e:
        raise HTTPException(400, str(e))


@enterprise_router.get("/cohorts", summary="List all cohorts")
def list_cohorts(program_id: Optional[int] = Query(None),
                 db: Session = Depends(get_db)):
    repo = CohortRepository(db)
    if program_id:
        cohorts = repo.get_for_program(program_id)
    else:
        cohorts = repo.get_all(limit=200)
    return {"total": len(cohorts), "cohorts": [
        {"id": c.id, "cohort_code": c.cohort_code, "cohort_name": c.cohort_name,
         "intake_year": c.intake_year, "intake_semester": c.intake_semester,
         "status": c.status, "total_enrolled": c.total_enrolled,
         "expected_grad_year": c.expected_grad_year}
        for c in cohorts
    ]}


@enterprise_router.get("/cohorts/{cohort_id}", response_model=CohortRead,
                       summary="Get cohort details")
def get_cohort(cohort_id: int, db: Session = Depends(get_db)):
    try:
        return CohortService.get_cohort_details(db, cohort_id)
    except ValueError as e:
        raise HTTPException(404, str(e))


@enterprise_router.get("/cohorts/{cohort_id}/students",
                       summary="List students in cohort")
def get_cohort_students(cohort_id: int,
                        limit: int = Query(100, ge=1, le=500),
                        offset: int = Query(0, ge=0),
                        db: Session = Depends(get_db)):
    students = CohortService.get_cohort_students(db, cohort_id, limit, offset)
    return {"cohort_id": cohort_id, "total": len(students), "students": students}


@enterprise_router.post("/cohorts/enroll", response_model=CohortMemberRead,
                        status_code=201, summary="Enroll student in cohort")
def enroll_in_cohort(req: CohortEnrollRequest, db: Session = Depends(get_db)):
    _student_or_404(db, req.student_id)
    try:
        m = CohortService.enroll_student(
            db, req.student_id, req.cohort_id,
            join_date=str(req.join_date) if req.join_date else None,
            expected_grad_date=str(req.expected_grad_date) if req.expected_grad_date else None,
        )
        return m
    except ValueError as e:
        raise HTTPException(400, str(e))


@enterprise_router.get("/students/{student_id}/cohort",
                       summary="Get student cohort information")
def get_student_cohort(student_id: int, db: Session = Depends(get_db)):
    _student_or_404(db, student_id)
    result = CohortService.get_student_cohort(db, student_id)
    if not result:
        return {"student_id": student_id, "cohort": None,
                "message": "Student not assigned to any cohort"}
    return {"student_id": student_id, "cohort": result}


@enterprise_router.post("/cohorts/{cohort_id}/refresh-stats",
                        summary="Refresh cohort statistics")
def refresh_cohort_stats(cohort_id: int, db: Session = Depends(get_db)):
    CohortService.refresh_cohort_stats(db, cohort_id)
    return {"cohort_id": cohort_id, "message": "Statistics refreshed"}


# ═════════════════════════════════════════════════════════════════════════════
# MODULE 2: REGISTRATION EVENT HISTORY
# ═════════════════════════════════════════════════════════════════════════════

@enterprise_router.get("/students/{student_id}/registration-history",
                       summary="Full registration event history")
def get_registration_history(student_id: int,
                              term_id: Optional[int] = Query(None),
                              db: Session = Depends(get_db)):
    _student_or_404(db, student_id)
    events = RegistrationHistoryService.get_history(db, student_id, term_id)
    return {
        "student_id": student_id,
        "total": len(events),
        "events": [
            {
                "id": e.id,
                "term_id": e.term_id,
                "course_id": e.course_id,
                "event_type": e.event_type,
                "event_detail": e.event_detail,
                "payload": e.payload,
                "requires_approval": e.requires_approval,
                "approved_by": e.approved_by,
                "approved_at": e.approved_at,
                "actor_id": e.actor_id,
                "occurred_at": e.occurred_at,
            }
            for e in events
        ],
    }


@enterprise_router.post("/students/{student_id}/registration-history",
                        status_code=201, summary="Record a registration event")
def record_registration_event(student_id: int,
                               data: RegistrationEventCreate,
                               db: Session = Depends(get_db)):
    _student_or_404(db, student_id)
    try:
        event_type = RegistrationEventTypeEnum(data.event_type)
    except ValueError:
        raise HTTPException(400, f"Invalid event_type: {data.event_type}")

    event = RegistrationHistoryService.record(
        db, student_id, data.term_id, event_type,
        course_id=data.course_id,
        detail=data.event_detail,
        payload=data.payload,
        requires_approval=data.requires_approval,
    )
    db.commit()
    return {"id": event.id, "event_type": event.event_type, "occurred_at": event.occurred_at}


@enterprise_router.get("/registration/pending-approvals",
                       summary="List registration events requiring approval")
def get_pending_approvals(term_id: Optional[int] = Query(None),
                          db: Session = Depends(get_db)):
    events = RegistrationHistoryService.get_pending_approvals(db, term_id)
    return {"total": len(events), "events": [
        {"id": e.id, "student_id": e.student_id, "term_id": e.term_id,
         "event_type": e.event_type, "occurred_at": e.occurred_at}
        for e in events
    ]}


@enterprise_router.post("/registration/events/{event_id}/approve",
                        summary="Approve a registration event")
def approve_registration_event(event_id: int,
                                approved_by: int = Query(...),
                                db: Session = Depends(get_db)):
    try:
        event = RegistrationHistoryService.approve_event(db, event_id, approved_by)
        return {"id": event.id, "approved_at": event.approved_at}
    except ValueError as e:
        raise HTTPException(404, str(e))


# ═════════════════════════════════════════════════════════════════════════════
# MODULE 3: STUDENT DOCUMENTS REGISTRY
# ═════════════════════════════════════════════════════════════════════════════

@enterprise_router.get("/students/{student_id}/documents",
                       response_model=DocumentRegistryResponse,
                       summary="Student document registry")
def get_document_registry(student_id: int, db: Session = Depends(get_db)):
    _student_or_404(db, student_id)
    return DocumentService.get_registry(db, student_id)


@enterprise_router.post("/students/{student_id}/documents",
                        status_code=201, summary="Upload a student document")
def upload_document(student_id: int,
                    data: DocumentUploadRequest,
                    uploaded_by: int = Query(...),
                    db: Session = Depends(get_db)):
    _student_or_404(db, student_id)
    doc = DocumentService.upload(db, student_id, data.model_dump(), uploaded_by)
    return {"id": doc.id, "document_type": doc.document_type,
            "title": doc.title, "status": doc.status}


@enterprise_router.post("/documents/{doc_id}/verify",
                        summary="Verify a student document")
def verify_document(doc_id: int,
                    verified_by: int = Query(...),
                    db: Session = Depends(get_db)):
    try:
        doc = DocumentService.verify(db, doc_id, verified_by)
        return {"id": doc.id, "status": doc.status, "verified_at": doc.verified_at}
    except ValueError as e:
        raise HTTPException(404, str(e))


@enterprise_router.post("/documents/{doc_id}/reject",
                        summary="Reject a student document")
def reject_document(doc_id: int,
                    rejected_by: int = Query(...),
                    reason: str = Query(...),
                    db: Session = Depends(get_db)):
    try:
        doc = DocumentService.reject(db, doc_id, rejected_by, reason)
        return {"id": doc.id, "status": doc.status}
    except ValueError as e:
        raise HTTPException(404, str(e))


@enterprise_router.get("/documents/expiring",
                       summary="List documents expiring within N days")
def get_expiring_documents(days: int = Query(30, ge=1, le=365),
                           db: Session = Depends(get_db)):
    docs = DocumentRepository(db).get_expiring_soon(days)
    return {"total": len(docs), "days_ahead": days, "documents": [
        {"id": d.id, "student_id": d.student_id, "document_type": d.document_type,
         "title": d.title, "expiry_date": d.expiry_date}
        for d in docs
    ]}


# ═════════════════════════════════════════════════════════════════════════════
# MODULE 4: ACADEMIC CASE MANAGEMENT
# ═════════════════════════════════════════════════════════════════════════════

@enterprise_router.post("/students/{student_id}/cases",
                        status_code=201, summary="Submit academic case")
def submit_case(student_id: int, data: CaseSubmitRequest,
                submitted_by: int = Query(...),
                db: Session = Depends(get_db)):
    _student_or_404(db, student_id)
    try:
        case = AcademicCaseService.submit(db, student_id, data.model_dump(), submitted_by)
        return {"id": case.id, "case_number": case.case_number,
                "status": case.status, "submitted_at": case.submitted_at}
    except Exception as e:
        logger.exception("Case submission failed")
        raise HTTPException(500, str(e))


@enterprise_router.get("/students/{student_id}/cases",
                       summary="Get student academic cases")
def get_student_cases(student_id: int,
                      status: Optional[str] = Query(None),
                      case_type: Optional[str] = Query(None),
                      db: Session = Depends(get_db)):
    _student_or_404(db, student_id)
    cases = AcademicCaseService.get_for_student(db, student_id, status)
    return {"student_id": student_id, "total": len(cases), "cases": [
        {"id": c.id, "case_number": c.case_number, "case_type": c.case_type,
         "status": c.status, "title": c.title, "submitted_at": c.submitted_at,
         "priority": c.priority, "assigned_to": c.assigned_to}
        for c in cases
    ]}


@enterprise_router.get("/cases/{case_id}", response_model=CaseRead,
                       summary="Get case details with decision history")
def get_case(case_id: int, db: Session = Depends(get_db)):
    repo = AcademicCaseRepository(db)
    case = repo.get_by_id(case_id)
    if not case:
        raise HTTPException(404, f"Case {case_id} not found")
    return case


@enterprise_router.post("/cases/{case_id}/transition",
                        summary="Transition case status")
def transition_case(case_id: int, data: CaseTransitionRequest,
                    decided_by: int = Query(...),
                    db: Session = Depends(get_db)):
    try:
        case = AcademicCaseService.transition(
            db, case_id, data.new_status, data.decision, decided_by, data.notes
        )
        return {"id": case.id, "case_number": case.case_number, "status": case.status}
    except ValueError as e:
        raise HTTPException(400, str(e))


@enterprise_router.get("/cases", summary="List open cases (registrar view)")
def list_open_cases(assigned_to: Optional[int] = Query(None),
                    db: Session = Depends(get_db)):
    cases = AcademicCaseService.get_open_cases(db, assigned_to)
    return {"total": len(cases), "cases": [
        {"id": c.id, "case_number": c.case_number, "student_id": c.student_id,
         "case_type": c.case_type, "status": c.status, "title": c.title,
         "priority": c.priority, "submitted_at": c.submitted_at}
        for c in cases
    ]}


# ═════════════════════════════════════════════════════════════════════════════
# MODULE 5: TRANSFER CREDITS ENGINE
# ═════════════════════════════════════════════════════════════════════════════

@enterprise_router.post("/students/{student_id}/transfers",
                        status_code=201, summary="Submit transfer credit request")
def submit_transfer(student_id: int, data: TransferCreditSubmitRequest,
                    submitted_by: int = Query(...),
                    db: Session = Depends(get_db)):
    _student_or_404(db, student_id)
    tc = TransferCreditService.submit(db, student_id, data.model_dump(), submitted_by)
    return {"id": tc.id, "status": tc.status, "source_course": tc.source_course_code}


@enterprise_router.get("/students/{student_id}/transfers",
                       summary="Get student transfer credits")
def get_transfers(student_id: int,
                  status: Optional[str] = Query(None),
                  db: Session = Depends(get_db)):
    _student_or_404(db, student_id)
    records = TransferCreditService.get_for_student(db, student_id, status)
    total_approved = TransferCreditService.get_total_approved_credits(db, student_id)
    return {
        "student_id":             student_id,
        "total":                  len(records),
        "approved_credits_total": total_approved,
        "transfers": [
            {
                "id": tc.id, "source_institution": tc.source_institution,
                "source_course_code": tc.source_course_code,
                "target_course_code": tc.target_course_code,
                "source_credit_hours": tc.source_credit_hours,
                "target_credit_hours": tc.target_credit_hours,
                "status": tc.status, "counts_toward_degree": tc.counts_toward_degree,
                "submitted_at": tc.submitted_at,
            }
            for tc in records
        ],
    }


@enterprise_router.post("/transfers/{transfer_id}/approve",
                        summary="Approve transfer credit")
def approve_transfer(transfer_id: int, data: TransferCreditApproveRequest,
                     approved_by: int = Query(...),
                     db: Session = Depends(get_db)):
    try:
        tc = TransferCreditService.approve(db, transfer_id, approved_by, data.notes)
        return {"id": tc.id, "status": tc.status, "approved_at": tc.approved_at}
    except ValueError as e:
        raise HTTPException(404, str(e))


@enterprise_router.post("/transfers/{transfer_id}/reject",
                        summary="Reject transfer credit")
def reject_transfer(transfer_id: int, data: TransferCreditRejectRequest,
                    rejected_by: int = Query(...),
                    db: Session = Depends(get_db)):
    try:
        tc = TransferCreditService.reject(db, transfer_id, rejected_by, data.reason)
        return {"id": tc.id, "status": tc.status}
    except ValueError as e:
        raise HTTPException(404, str(e))


@enterprise_router.get("/transfers/pending",
                       summary="List all pending transfer evaluations")
def get_pending_transfers(db: Session = Depends(get_db)):
    transfers = TransferCreditRepository(db).get_pending()
    return {"total": len(transfers), "transfers": [
        {"id": tc.id, "student_id": tc.student_id,
         "source_institution": tc.source_institution,
         "source_course_code": tc.source_course_code,
         "submitted_at": tc.submitted_at}
        for tc in transfers
    ]}


# ═════════════════════════════════════════════════════════════════════════════
# MODULE 6: ACADEMIC EXEMPTIONS ENGINE
# ═════════════════════════════════════════════════════════════════════════════

@enterprise_router.post("/students/{student_id}/exemptions",
                        status_code=201, summary="Request academic exemption")
def request_exemption(student_id: int, data: ExemptionRequestBody,
                      requested_by: int = Query(...),
                      db: Session = Depends(get_db)):
    _student_or_404(db, student_id)
    ex = ExemptionService.request(db, student_id, data.model_dump(), requested_by)
    return {"id": ex.id, "status": ex.status, "exemption_type": ex.exemption_type}


@enterprise_router.get("/students/{student_id}/exemptions",
                       summary="Get student exemptions")
def get_exemptions(student_id: int,
                   status: Optional[str] = Query(None),
                   db: Session = Depends(get_db)):
    _student_or_404(db, student_id)
    records = ExemptionService.get_for_student(db, student_id, status)
    return {"student_id": student_id, "total": len(records), "exemptions": [
        {"id": e.id, "exemption_type": e.exemption_type, "status": e.status,
         "course_code": e.course_code, "requirement_desc": e.requirement_desc,
         "requested_at": e.requested_at, "approved_at": e.approved_at}
        for e in records
    ]}


@enterprise_router.post("/exemptions/{exemption_id}/approve",
                        summary="Approve exemption")
def approve_exemption(exemption_id: int, data: ExemptionApproveRequest,
                      approved_by: int = Query(...),
                      db: Session = Depends(get_db)):
    try:
        ex = ExemptionService.approve(db, exemption_id, approved_by, data.notes)
        return {"id": ex.id, "status": ex.status, "approved_at": ex.approved_at}
    except ValueError as e:
        raise HTTPException(404, str(e))


@enterprise_router.post("/exemptions/{exemption_id}/reject",
                        summary="Reject exemption")
def reject_exemption(exemption_id: int, data: ExemptionRejectRequest,
                     rejected_by: int = Query(...),
                     db: Session = Depends(get_db)):
    try:
        ex = ExemptionService.reject(db, exemption_id, rejected_by, data.reason)
        return {"id": ex.id, "status": ex.status}
    except ValueError as e:
        raise HTTPException(404, str(e))


# ═════════════════════════════════════════════════════════════════════════════
# MODULE 7: ACADEMIC RECORD VERSIONING
# ═════════════════════════════════════════════════════════════════════════════

@enterprise_router.get("/students/{student_id}/record-versions",
                       summary="Academic record version history")
def get_record_versions(student_id: int,
                        limit: int = Query(50, ge=1, le=200),
                        db: Session = Depends(get_db)):
    _student_or_404(db, student_id)
    versions = AcademicRecordVersionService.get_history(db, student_id, limit)
    return {
        "student_id": student_id,
        "total": len(versions),
        "versions": [
            {
                "id": v.id, "version_number": v.version_number,
                "trigger": v.trigger, "trigger_detail": v.trigger_detail,
                "cgpa": float(v.cgpa or 0),
                "academic_standing": v.academic_standing,
                "degree_completion_pct": float(v.degree_completion_pct or 0),
                "snapshot_hash": v.snapshot_hash,
                "is_current": v.is_current,
                "authored_at": v.authored_at,
            }
            for v in versions
        ],
    }


@enterprise_router.get("/students/{student_id}/record-versions/current",
                       summary="Current academic record version")
def get_current_record_version(student_id: int, db: Session = Depends(get_db)):
    _student_or_404(db, student_id)
    v = AcademicRecordVersionService.get_current(db, student_id)
    if not v:
        raise HTTPException(404, "No record version found — trigger a GPA finalization first")
    return {"id": v.id, "version_number": v.version_number, "cgpa": float(v.cgpa or 0),
            "snapshot_hash": v.snapshot_hash, "authored_at": v.authored_at}


@enterprise_router.post("/students/{student_id}/record-versions/snapshot",
                        status_code=201, summary="Manually create record version snapshot")
def create_record_snapshot(student_id: int,
                           trigger: str = Query(default="registrar_override"),
                           detail: Optional[str] = Query(None),
                           authored_by: int = Query(...),
                           db: Session = Depends(get_db)):
    _student_or_404(db, student_id)
    try:
        trig = RecordVersionTriggerEnum(trigger)
    except ValueError:
        raise HTTPException(400, f"Invalid trigger: {trigger}")
    v = AcademicRecordVersionService.create_version(db, student_id, trig, detail, authored_by)
    db.commit()
    return {"id": v.id, "version_number": v.version_number, "snapshot_hash": v.snapshot_hash}


@enterprise_router.get("/record-versions/compare",
                       response_model=RecordVersionCompareResponse,
                       summary="Compare two academic record versions")
def compare_record_versions(v1_id: int = Query(...),
                             v2_id: int = Query(...),
                             db: Session = Depends(get_db)):
    try:
        return AcademicRecordVersionService.compare(db, v1_id, v2_id)
    except ValueError as e:
        raise HTTPException(404, str(e))


# ═════════════════════════════════════════════════════════════════════════════
# MODULE 8: PDF TRANSCRIPT EXPORT
# ═════════════════════════════════════════════════════════════════════════════

@enterprise_router.post("/students/{student_id}/pdf-transcript",
                        status_code=201, summary="Queue PDF transcript generation job")
def queue_pdf_transcript(student_id: int, data: PDFJobRequest,
                         requested_by: int = Query(...),
                         db: Session = Depends(get_db)):
    _student_or_404(db, student_id)
    job = PDFTranscriptService.queue_job(
        db, student_id,
        transcript_type=data.transcript_type,
        transcript_version_id=data.transcript_version_id,
        requested_by=requested_by,
        options=data.options,
    )
    return {"job_id": job.id, "status": job.status, "queued_at": job.queued_at}


@enterprise_router.post("/pdf-transcript/jobs/{job_id}/generate",
                        summary="Synchronously generate PDF for a queued job")
def generate_pdf(job_id: int, db: Session = Depends(get_db)):
    """
    Triggers synchronous PDF generation.
    In production, this would be handled by a background worker.
    Returns the completed job with result_key.
    """
    try:
        job = PDFTranscriptService.generate_sync(db, job_id)
        return {
            "job_id":    job.id,
            "status":    job.status,
            "result_key": job.result_key,
            "page_count": job.page_count,
            "file_size_bytes": job.file_size_bytes,
            "completed_at":    job.completed_at,
        }
    except Exception as e:
        logger.exception("PDF generation failed")
        raise HTTPException(500, str(e))


@enterprise_router.get("/students/{student_id}/pdf-transcript/jobs",
                       summary="List PDF transcript jobs for student")
def list_pdf_jobs(student_id: int, db: Session = Depends(get_db)):
    _student_or_404(db, student_id)
    jobs = PDFTranscriptService.get_jobs(db, student_id)
    return {"student_id": student_id, "total": len(jobs), "jobs": [
        {"id": j.id, "transcript_type": j.transcript_type, "status": j.status,
         "result_key": j.result_key, "queued_at": j.queued_at,
         "completed_at": j.completed_at, "expires_at": j.expires_at}
        for j in jobs
    ]}


@enterprise_router.get("/pdf-transcript/pending",
                       summary="List pending PDF generation jobs")
def list_pending_pdf_jobs(db: Session = Depends(get_db)):
    jobs = PDFTranscriptJobRepository(db).get_pending()
    return {"total": len(jobs), "jobs": [
        {"id": j.id, "student_id": j.student_id, "transcript_type": j.transcript_type,
         "status": j.status, "queued_at": j.queued_at}
        for j in jobs
    ]}


# ═════════════════════════════════════════════════════════════════════════════
# MODULE 9: REGISTRAR WORKFLOW SYSTEM
# ═════════════════════════════════════════════════════════════════════════════

@enterprise_router.get("/registrar/workspace",
                       response_model=WorkspaceSummary,
                       summary="Registrar workspace dashboard")
def get_registrar_workspace(assigned_to: Optional[int] = Query(None),
                             db: Session = Depends(get_db)):
    return RegistrarTaskService.get_workspace(db, assigned_to)


@enterprise_router.get("/registrar/tasks",
                       summary="List registrar tasks")
def list_tasks(assigned_to: Optional[int] = Query(None),
               task_type: Optional[str] = Query(None),
               priority: Optional[str] = Query(None),
               db: Session = Depends(get_db)):
    tasks = RegistrarTaskRepository(db).get_open_tasks(assigned_to, task_type, priority)
    return {"total": len(tasks), "tasks": [
        {"id": t.id, "task_number": t.task_number, "task_type": t.task_type,
         "status": t.status, "priority": t.priority, "title": t.title,
         "student_id": t.student_id, "due_date": t.due_date,
         "assigned_to": t.assigned_to, "created_at": t.created_at}
        for t in tasks
    ]}


@enterprise_router.post("/registrar/tasks", status_code=201,
                        summary="Create registrar task")
def create_task(data: TaskCreateRequest,
                created_by: int = Query(...),
                db: Session = Depends(get_db)):
    try:
        task = RegistrarTaskService.create_task(db, data.model_dump(), created_by)
        db.commit()
        return {"id": task.id, "task_number": task.task_number, "status": task.status}
    except Exception as e:
        logger.exception("Task creation failed")
        raise HTTPException(500, str(e))


@enterprise_router.post("/registrar/tasks/{task_id}/assign",
                        summary="Assign task to registrar staff")
def assign_task(task_id: int, data: TaskAssignRequest,
                assigned_by: int = Query(...),
                db: Session = Depends(get_db)):
    try:
        task = RegistrarTaskService.assign(db, task_id, data.assigned_to,
                                           assigned_by, data.notes)
        return {"id": task.id, "assigned_to": task.assigned_to, "status": task.status}
    except ValueError as e:
        raise HTTPException(404, str(e))


@enterprise_router.post("/registrar/tasks/{task_id}/complete",
                        summary="Mark task as complete")
def complete_task(task_id: int, data: TaskCompleteRequest,
                  completed_by: int = Query(...),
                  db: Session = Depends(get_db)):
    try:
        task = RegistrarTaskService.complete(db, task_id, completed_by, data.notes)
        return {"id": task.id, "status": task.status, "completed_at": task.completed_at}
    except ValueError as e:
        raise HTTPException(404, str(e))


@enterprise_router.get("/students/{student_id}/registrar/tasks",
                       summary="Tasks related to a specific student")
def get_student_tasks(student_id: int, db: Session = Depends(get_db)):
    _student_or_404(db, student_id)
    tasks = RegistrarTaskRepository(db).get_for_student(student_id)
    return {"student_id": student_id, "total": len(tasks), "tasks": [
        {"id": t.id, "task_number": t.task_number, "task_type": t.task_type,
         "status": t.status, "title": t.title, "created_at": t.created_at}
        for t in tasks
    ]}


# ═════════════════════════════════════════════════════════════════════════════
# PREREQUISITE VALIDATION
# ═════════════════════════════════════════════════════════════════════════════

@enterprise_router.post("/students/{student_id}/prerequisites/validate",
                        status_code=201,
                        summary="Validate course prerequisites for student")
def validate_prerequisites(student_id: int, data: PrerequisiteCheckRequest,
                            db: Session = Depends(get_db)):
    _student_or_404(db, student_id)
    result = PrerequisiteService.validate(db, student_id, data.course_id, data.term_id)
    db.commit()
    return {
        "student_id":        student_id,
        "course_id":         result.course_id,
        "course_code":       result.course_code,
        "is_eligible":       result.is_eligible,
        "missing_prereqs":   result.missing_prereqs,
        "satisfied_prereqs": result.satisfied_prereqs,
        "policy_source":     result.policy_source,
        "override_applied":  result.override_applied,
    }


@enterprise_router.get("/students/{student_id}/prerequisites/history",
                       summary="Prerequisite validation history")
def get_prereq_history(student_id: int,
                       term_id: Optional[int] = Query(None),
                       db: Session = Depends(get_db)):
    _student_or_404(db, student_id)
    records = PrerequisiteValidationRepository(db).get_for_student(student_id, term_id)
    return {"student_id": student_id, "total": len(records), "validations": [
        {"id": r.id, "course_code": r.course_code, "is_eligible": r.is_eligible,
         "missing_prereqs": r.missing_prereqs, "validated_at": r.validated_at}
        for r in records
    ]}


# ═════════════════════════════════════════════════════════════════════════════
# ENTERPRISE STUDENT PROFILE AGGREGATION
# ═════════════════════════════════════════════════════════════════════════════

@enterprise_router.get("/students/{student_id}/enterprise-profile",
                       response_model=StudentEnterpriseProfile,
                       summary="Full enterprise student profile — all history aggregated")
def get_enterprise_profile(student_id: int, db: Session = Depends(get_db)):
    """
    Single endpoint returning the complete enterprise view of a student.
    Aggregates: cohort, cases, transfers, exemptions, documents, tasks, record version.
    """
    student = _student_or_404(db, student_id)
    from app.models.models import User
    user = db.query(User).filter(User.id == student.user_id).first()
    from app.models.academic_models import AcademicProgram, AcademicTrack
    prog  = (db.query(AcademicProgram).filter(AcademicProgram.id == student.program_id).first()
             if student.program_id else None)
    track = (db.query(AcademicTrack).filter(AcademicTrack.id == student.track_id).first()
             if student.track_id else None)

    cohort       = CohortService.get_student_cohort(db, student_id)
    open_cases   = len(AcademicCaseRepository(db).get_for_student(student_id, status="submitted")) + \
                   len(AcademicCaseRepository(db).get_for_student(student_id, status="under_review"))
    pending_tc   = len(TransferCreditRepository(db).get_for_student(student_id, status="pending"))
    pending_ex   = len(ExemptionRepository(db).get_for_student(student_id, status="pending"))
    all_docs     = DocumentRepository(db).get_for_student(student_id)
    unverified   = sum(1 for d in all_docs if d.verification_status != "verified")
    current_rv   = AcademicRecordVersionRepository(db).get_current(student_id)
    open_tasks   = len(RegistrarTaskRepository(db).get_for_student(student_id))

    return {
        "student_id":           student_id,
        "student_number":       student.student_number or "",
        "name":                 user.name if user else "",
        "program":              prog.name if prog else None,
        "track":                track.name if track else None,
        "current_cgpa":         float(student.cgpa or 0),
        "academic_standing":    student.academic_standing or "active",
        "cohort":               cohort,
        "open_cases":           open_cases,
        "pending_transfers":    pending_tc,
        "pending_exemptions":   pending_ex,
        "document_count":       len(all_docs),
        "unverified_documents": unverified,
        "record_version":       current_rv.version_number if current_rv else None,
        "open_tasks":           open_tasks,
        "computed_at":          datetime.now(timezone.utc),
    }
