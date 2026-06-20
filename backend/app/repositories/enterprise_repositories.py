"""
EduGuard AI — Enterprise Repositories
=======================================
Repository layer for all enterprise modules.
Follows the same BaseRepository[T] pattern established in sprint4_repositories.py.
No direct ORM access in services — all queries through repositories.
"""

from __future__ import annotations

import hashlib
import json
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Tuple, Type
from decimal import Decimal

from sqlalchemy.orm import Session
from sqlalchemy import desc, and_, func

from app.repositories.sprint4_repositories import BaseRepository
from app.models.enterprise_models import (
    StudentCohort, CohortMembership,
    RegistrationEvent,
    StudentDocument,
    AcademicCase, AcademicCaseDecision,
    TransferCredit,
    AcademicExemption,
    AcademicRecordVersion,
    PDFTranscriptJob,
    RegistrarTask, RegistrarTaskAssignment,
    PrerequisiteValidation,
    CaseStatusEnum, TransferCreditStatusEnum,
    ExemptionStatusEnum, PDFJobStatusEnum, TaskStatusEnum,
)
from app.models.models import Student
from app.models.academic_models import AcademicTerm


# ═════════════════════════════════════════════════════════════════════════════
# COHORT REPOSITORIES
# ═════════════════════════════════════════════════════════════════════════════

class CohortRepository(BaseRepository[StudentCohort]):

    def __init__(self, db: Session):
        super().__init__(db, StudentCohort)

    def get_by_code(self, code: str) -> Optional[StudentCohort]:
        return self._db.query(StudentCohort).filter(
            StudentCohort.cohort_code == code
        ).first()

    def get_for_program(self, program_id: int) -> List[StudentCohort]:
        return self._db.query(StudentCohort).filter(
            StudentCohort.program_id == program_id
        ).order_by(desc(StudentCohort.intake_year)).all()

    def get_with_stats(self, cohort_id: int) -> Dict:
        cohort = self.get_by_id(cohort_id)
        if not cohort:
            return {}
        member_count = self._db.query(func.count(CohortMembership.id)).filter(
            CohortMembership.cohort_id == cohort_id
        ).scalar()
        return {
            "cohort": cohort,
            "member_count": member_count,
        }

    def refresh_stats(self, cohort_id: int) -> None:
        """Recompute denormalized cohort statistics."""
        from app.models.enterprise_models import CohortStatusEnum
        total     = self._db.query(func.count(CohortMembership.id)).filter(
            CohortMembership.cohort_id == cohort_id).scalar() or 0
        graduated = self._db.query(func.count(CohortMembership.id)).filter(
            CohortMembership.cohort_id == cohort_id,
            CohortMembership.status == CohortStatusEnum.GRADUATED).scalar() or 0
        delayed   = self._db.query(func.count(CohortMembership.id)).filter(
            CohortMembership.cohort_id == cohort_id,
            CohortMembership.is_delayed == True).scalar() or 0
        self._db.query(StudentCohort).filter(
            StudentCohort.id == cohort_id
        ).update({"total_enrolled": total, "total_graduated": graduated, "total_delayed": delayed})
        self._db.flush()


class CohortMembershipRepository(BaseRepository[CohortMembership]):

    def __init__(self, db: Session):
        super().__init__(db, CohortMembership)

    def get_for_student(self, student_id: int) -> List[CohortMembership]:
        return self._db.query(CohortMembership).filter(
            CohortMembership.student_id == student_id
        ).all()

    def get_for_cohort(self, cohort_id: int, limit: int = 200, offset: int = 0) -> List[CohortMembership]:
        return self._db.query(CohortMembership).filter(
            CohortMembership.cohort_id == cohort_id
        ).offset(offset).limit(limit).all()

    def get_active_cohort(self, student_id: int) -> Optional[CohortMembership]:
        from app.models.enterprise_models import CohortStatusEnum
        return self._db.query(CohortMembership).filter(
            CohortMembership.student_id == student_id,
            CohortMembership.status == CohortStatusEnum.ACTIVE,
        ).first()

    def exists(self, student_id: int, cohort_id: int) -> bool:
        return self._db.query(CohortMembership).filter(
            CohortMembership.student_id == student_id,
            CohortMembership.cohort_id  == cohort_id,
        ).count() > 0


# ═════════════════════════════════════════════════════════════════════════════
# REGISTRATION EVENT REPOSITORY
# ═════════════════════════════════════════════════════════════════════════════

class RegistrationEventRepository(BaseRepository[RegistrationEvent]):

    def __init__(self, db: Session):
        super().__init__(db, RegistrationEvent)

    def get_for_student(self, student_id: int, term_id: Optional[int] = None,
                        limit: int = 100) -> List[RegistrationEvent]:
        q = self._db.query(RegistrationEvent).filter(
            RegistrationEvent.student_id == student_id
        )
        if term_id:
            q = q.filter(RegistrationEvent.term_id == term_id)
        return q.order_by(desc(RegistrationEvent.occurred_at)).limit(limit).all()

    def get_pending_approvals(self, term_id: Optional[int] = None) -> List[RegistrationEvent]:
        q = self._db.query(RegistrationEvent).filter(
            RegistrationEvent.requires_approval == True,
            RegistrationEvent.approved_by.is_(None),
            RegistrationEvent.rejection_reason.is_(None),
        )
        if term_id:
            q = q.filter(RegistrationEvent.term_id == term_id)
        return q.order_by(RegistrationEvent.occurred_at).all()

    def append(self, data: Dict) -> RegistrationEvent:
        """Registration events are append-only."""
        event = RegistrationEvent(**data)
        self._db.add(event)
        self._db.flush()
        return event


# ═════════════════════════════════════════════════════════════════════════════
# DOCUMENT REPOSITORY
# ═════════════════════════════════════════════════════════════════════════════

class DocumentRepository(BaseRepository[StudentDocument]):

    def __init__(self, db: Session):
        super().__init__(db, StudentDocument)

    def get_for_student(self, student_id: int,
                        doc_type: Optional[str] = None,
                        active_only: bool = True) -> List[StudentDocument]:
        q = self._db.query(StudentDocument).filter(
            StudentDocument.student_id == student_id
        )
        if active_only:
            q = q.filter(StudentDocument.is_active == True)
        if doc_type:
            q = q.filter(StudentDocument.document_type == doc_type)
        return q.order_by(desc(StudentDocument.upload_date)).all()

    def get_expiring_soon(self, days: int = 30) -> List[StudentDocument]:
        from datetime import timedelta
        cutoff = datetime.now(timezone.utc) + timedelta(days=days)
        return self._db.query(StudentDocument).filter(
            StudentDocument.expiry_date <= cutoff.date(),
            StudentDocument.is_active == True,
            StudentDocument.status != "expired",
        ).all()

    def add_revision(self, doc_id: int, new_storage_key: str, uploaded_by: int) -> StudentDocument:
        doc = self.get_by_id(doc_id)
        if not doc:
            raise ValueError(f"Document {doc_id} not found")
        history = list(doc.revision_history or [])
        history.append({
            "version": doc.version,
            "storage_key": doc.storage_key,
            "uploaded_at": doc.upload_date.isoformat() if doc.upload_date else None,
            "uploaded_by": uploaded_by,
        })
        doc.revision_history = history
        doc.version          = (doc.version or 1) + 1
        doc.storage_key      = new_storage_key
        doc.upload_date      = datetime.now(timezone.utc)
        doc.uploaded_by      = uploaded_by
        self._db.flush()
        return doc


# ═════════════════════════════════════════════════════════════════════════════
# ACADEMIC CASE REPOSITORY
# ═════════════════════════════════════════════════════════════════════════════

class AcademicCaseRepository(BaseRepository[AcademicCase]):

    def __init__(self, db: Session):
        super().__init__(db, AcademicCase)

    def get_for_student(self, student_id: int,
                        status: Optional[str] = None,
                        case_type: Optional[str] = None) -> List[AcademicCase]:
        q = self._db.query(AcademicCase).filter(AcademicCase.student_id == student_id)
        if status:
            q = q.filter(AcademicCase.status == status)
        if case_type:
            q = q.filter(AcademicCase.case_type == case_type)
        return q.order_by(desc(AcademicCase.submitted_at)).all()

    def get_open_cases(self, assigned_to: Optional[int] = None) -> List[AcademicCase]:
        q = self._db.query(AcademicCase).filter(
            AcademicCase.status.in_([
                CaseStatusEnum.SUBMITTED.value,
                CaseStatusEnum.UNDER_REVIEW.value,
            ])
        )
        if assigned_to:
            q = q.filter(AcademicCase.assigned_to == assigned_to)
        return q.order_by(AcademicCase.submitted_at).all()

    def generate_case_number(self) -> str:
        year = datetime.now().year
        count = self._db.query(func.count(AcademicCase.id)).filter(
            func.extract("year", AcademicCase.submitted_at) == year
        ).scalar() or 0
        return f"CASE-{year}-{(count + 1):05d}"

    def transition_status(self, case_id: int, new_status: str,
                          decision: str, decided_by: int,
                          notes: Optional[str] = None) -> Tuple[AcademicCase, AcademicCaseDecision]:
        case = self.get_by_id(case_id)
        if not case:
            raise ValueError(f"Case {case_id} not found")

        old_status = case.status
        case.status = CaseStatusEnum(new_status)
        if new_status in (CaseStatusEnum.APPROVED.value, CaseStatusEnum.REJECTED.value,
                          CaseStatusEnum.CLOSED.value):
            case.resolved_by = decided_by
            case.resolved_at = datetime.now(timezone.utc)
        if new_status == CaseStatusEnum.CLOSED.value:
            case.closed_at = datetime.now(timezone.utc)

        decision_record = AcademicCaseDecision(
            case_id     = case_id,
            from_status = CaseStatusEnum(old_status) if old_status else None,
            to_status   = CaseStatusEnum(new_status),
            decision    = decision,
            notes       = notes,
            decided_by  = decided_by,
        )
        self._db.add(decision_record)
        self._db.flush()
        return case, decision_record


class CaseDecisionRepository(BaseRepository[AcademicCaseDecision]):

    def __init__(self, db: Session):
        super().__init__(db, AcademicCaseDecision)

    def get_for_case(self, case_id: int) -> List[AcademicCaseDecision]:
        return self._db.query(AcademicCaseDecision).filter(
            AcademicCaseDecision.case_id == case_id
        ).order_by(AcademicCaseDecision.decided_at).all()


# ═════════════════════════════════════════════════════════════════════════════
# TRANSFER CREDIT REPOSITORY
# ═════════════════════════════════════════════════════════════════════════════

class TransferCreditRepository(BaseRepository[TransferCredit]):

    def __init__(self, db: Session):
        super().__init__(db, TransferCredit)

    def get_for_student(self, student_id: int,
                        status: Optional[str] = None) -> List[TransferCredit]:
        q = self._db.query(TransferCredit).filter(TransferCredit.student_id == student_id)
        if status:
            q = q.filter(TransferCredit.status == status)
        return q.order_by(desc(TransferCredit.submitted_at)).all()

    def get_approved_for_student(self, student_id: int) -> List[TransferCredit]:
        return self._db.query(TransferCredit).filter(
            TransferCredit.student_id == student_id,
            TransferCredit.status == TransferCreditStatusEnum.APPROVED,
        ).all()

    def get_pending(self) -> List[TransferCredit]:
        return self._db.query(TransferCredit).filter(
            TransferCredit.status == TransferCreditStatusEnum.PENDING
        ).order_by(TransferCredit.submitted_at).all()

    def approve(self, transfer_id: int, approved_by: int,
                notes: Optional[str] = None) -> TransferCredit:
        tc = self.get_by_id(transfer_id)
        if not tc:
            raise ValueError(f"Transfer {transfer_id} not found")
        history = list(tc.approval_history or [])
        history.append({
            "action": "approved", "actor": approved_by,
            "timestamp": datetime.now(timezone.utc).isoformat(), "notes": notes,
        })
        tc.status          = TransferCreditStatusEnum.APPROVED
        tc.approved_by     = approved_by
        tc.approved_at     = datetime.now(timezone.utc)
        tc.evaluation_notes = notes
        tc.approval_history = history
        self._db.flush()
        return tc

    def reject(self, transfer_id: int, rejected_by: int, reason: str) -> TransferCredit:
        tc = self.get_by_id(transfer_id)
        if not tc:
            raise ValueError(f"Transfer {transfer_id} not found")
        history = list(tc.approval_history or [])
        history.append({
            "action": "rejected", "actor": rejected_by,
            "timestamp": datetime.now(timezone.utc).isoformat(), "reason": reason,
        })
        tc.status           = TransferCreditStatusEnum.REJECTED
        tc.rejection_reason = reason
        tc.approval_history = history
        self._db.flush()
        return tc


# ═════════════════════════════════════════════════════════════════════════════
# EXEMPTION REPOSITORY
# ═════════════════════════════════════════════════════════════════════════════

class ExemptionRepository(BaseRepository[AcademicExemption]):

    def __init__(self, db: Session):
        super().__init__(db, AcademicExemption)

    def get_for_student(self, student_id: int,
                        status: Optional[str] = None) -> List[AcademicExemption]:
        q = self._db.query(AcademicExemption).filter(
            AcademicExemption.student_id == student_id
        )
        if status:
            q = q.filter(AcademicExemption.status == status)
        return q.order_by(desc(AcademicExemption.requested_at)).all()

    def get_approved(self, student_id: int) -> List[AcademicExemption]:
        return self._db.query(AcademicExemption).filter(
            AcademicExemption.student_id == student_id,
            AcademicExemption.status == ExemptionStatusEnum.APPROVED,
        ).all()

    def approve(self, exemption_id: int, approved_by: int, notes: str) -> AcademicExemption:
        ex = self.get_by_id(exemption_id)
        if not ex:
            raise ValueError(f"Exemption {exemption_id} not found")
        history = list(ex.approval_history or [])
        history.append({"action": "approved", "actor": approved_by,
                         "timestamp": datetime.now(timezone.utc).isoformat(), "notes": notes})
        ex.status       = ExemptionStatusEnum.APPROVED
        ex.approved_by  = approved_by
        ex.approved_at  = datetime.now(timezone.utc)
        ex.decision_notes = notes
        ex.approval_history = history
        ex.version      = (ex.version or 1) + 1
        self._db.flush()
        return ex

    def reject(self, exemption_id: int, rejected_by: int, reason: str) -> AcademicExemption:
        ex = self.get_by_id(exemption_id)
        if not ex:
            raise ValueError(f"Exemption {exemption_id} not found")
        history = list(ex.approval_history or [])
        history.append({"action": "rejected", "actor": rejected_by,
                         "timestamp": datetime.now(timezone.utc).isoformat(), "reason": reason})
        ex.status       = ExemptionStatusEnum.REJECTED
        ex.decision_notes = reason
        ex.reviewed_by  = rejected_by
        ex.reviewed_at  = datetime.now(timezone.utc)
        ex.approval_history = history
        self._db.flush()
        return ex


# ═════════════════════════════════════════════════════════════════════════════
# ACADEMIC RECORD VERSION REPOSITORY
# ═════════════════════════════════════════════════════════════════════════════

class AcademicRecordVersionRepository(BaseRepository[AcademicRecordVersion]):

    def __init__(self, db: Session):
        super().__init__(db, AcademicRecordVersion)

    def get_current(self, student_id: int) -> Optional[AcademicRecordVersion]:
        return self._db.query(AcademicRecordVersion).filter(
            AcademicRecordVersion.student_id == student_id,
            AcademicRecordVersion.is_current  == True,
        ).order_by(desc(AcademicRecordVersion.authored_at)).first()

    def get_history(self, student_id: int, limit: int = 50) -> List[AcademicRecordVersion]:
        return self._db.query(AcademicRecordVersion).filter(
            AcademicRecordVersion.student_id == student_id,
        ).order_by(desc(AcademicRecordVersion.version_number)).limit(limit).all()

    def get_next_version(self, student_id: int) -> int:
        last = self._db.query(func.max(AcademicRecordVersion.version_number)).filter(
            AcademicRecordVersion.student_id == student_id
        ).scalar()
        return (last or 0) + 1

    def invalidate_current(self, student_id: int) -> None:
        self._db.query(AcademicRecordVersion).filter(
            AcademicRecordVersion.student_id == student_id,
            AcademicRecordVersion.is_current  == True,
        ).update({"is_current": False})
        self._db.flush()

    def compare(self, v1_id: int, v2_id: int) -> Dict:
        v1 = self.get_by_id(v1_id)
        v2 = self.get_by_id(v2_id)
        if not v1 or not v2:
            raise ValueError("One or both versions not found")
        return {
            "version_1": {"id": v1.id, "number": v1.version_number,
                          "cgpa": float(v1.cgpa or 0), "standing": v1.academic_standing,
                          "authored_at": v1.authored_at},
            "version_2": {"id": v2.id, "number": v2.version_number,
                          "cgpa": float(v2.cgpa or 0), "standing": v2.academic_standing,
                          "authored_at": v2.authored_at},
            "cgpa_delta": float((v2.cgpa or 0) - (v1.cgpa or 0)),
            "standing_changed": v1.academic_standing != v2.academic_standing,
            "completion_delta": float((v2.degree_completion_pct or 0) - (v1.degree_completion_pct or 0)),
        }


# ═════════════════════════════════════════════════════════════════════════════
# PDF TRANSCRIPT JOB REPOSITORY
# ═════════════════════════════════════════════════════════════════════════════

class PDFTranscriptJobRepository(BaseRepository[PDFTranscriptJob]):

    def __init__(self, db: Session):
        super().__init__(db, PDFTranscriptJob)

    def get_for_student(self, student_id: int) -> List[PDFTranscriptJob]:
        return self._db.query(PDFTranscriptJob).filter(
            PDFTranscriptJob.student_id == student_id
        ).order_by(desc(PDFTranscriptJob.queued_at)).all()

    def get_pending(self) -> List[PDFTranscriptJob]:
        return self._db.query(PDFTranscriptJob).filter(
            PDFTranscriptJob.status.in_([
                PDFJobStatusEnum.QUEUED.value, PDFJobStatusEnum.PROCESSING.value
            ])
        ).order_by(PDFTranscriptJob.queued_at).all()

    def mark_complete(self, job_id: int, result_key: str,
                      page_count: int, file_size: int) -> PDFTranscriptJob:
        job = self.get_by_id(job_id)
        if not job:
            raise ValueError(f"PDF job {job_id} not found")
        job.status       = PDFJobStatusEnum.COMPLETE
        job.result_key   = result_key
        job.page_count   = page_count
        job.file_size_bytes = file_size
        job.completed_at = datetime.now(timezone.utc)
        self._db.flush()
        return job

    def mark_failed(self, job_id: int, error: str) -> PDFTranscriptJob:
        job = self.get_by_id(job_id)
        if not job:
            raise ValueError(f"PDF job {job_id} not found")
        job.status        = PDFJobStatusEnum.FAILED
        job.error_message = error
        job.completed_at  = datetime.now(timezone.utc)
        self._db.flush()
        return job


# ═════════════════════════════════════════════════════════════════════════════
# REGISTRAR TASK REPOSITORY
# ═════════════════════════════════════════════════════════════════════════════

class RegistrarTaskRepository(BaseRepository[RegistrarTask]):

    def __init__(self, db: Session):
        super().__init__(db, RegistrarTask)

    def generate_task_number(self) -> str:
        year  = datetime.now().year
        count = self._db.query(func.count(RegistrarTask.id)).filter(
            func.extract("year", RegistrarTask.created_at) == year
        ).scalar() or 0
        return f"TASK-{year}-{(count + 1):05d}"

    def get_open_tasks(self, assigned_to: Optional[int] = None,
                       task_type: Optional[str] = None,
                       priority: Optional[str] = None) -> List[RegistrarTask]:
        q = self._db.query(RegistrarTask).filter(
            RegistrarTask.status.in_([TaskStatusEnum.OPEN.value,
                                      TaskStatusEnum.IN_PROGRESS.value])
        )
        if assigned_to:
            q = q.filter(RegistrarTask.assigned_to == assigned_to)
        if task_type:
            q = q.filter(RegistrarTask.task_type == task_type)
        if priority:
            q = q.filter(RegistrarTask.priority == priority)
        return q.order_by(RegistrarTask.created_at).all()

    def get_for_student(self, student_id: int) -> List[RegistrarTask]:
        return self._db.query(RegistrarTask).filter(
            RegistrarTask.student_id == student_id
        ).order_by(desc(RegistrarTask.created_at)).all()

    def complete_task(self, task_id: int, completed_by: int, notes: str) -> RegistrarTask:
        task = self.get_by_id(task_id)
        if not task:
            raise ValueError(f"Task {task_id} not found")
        task.status          = TaskStatusEnum.COMPLETE
        task.completed_by    = completed_by
        task.completed_at    = datetime.now(timezone.utc)
        task.resolution_notes = notes
        self._db.flush()
        return task

    def assign_task(self, task_id: int, assigned_to: int,
                    assigned_by: int, notes: Optional[str] = None) -> RegistrarTask:
        task = self.get_by_id(task_id)
        if not task:
            raise ValueError(f"Task {task_id} not found")
        # Close previous assignment
        prev = self._db.query(RegistrarTaskAssignment).filter(
            RegistrarTaskAssignment.task_id == task_id,
            RegistrarTaskAssignment.unassigned_at.is_(None),
        ).first()
        if prev:
            prev.unassigned_at = datetime.now(timezone.utc)

        assignment = RegistrarTaskAssignment(
            task_id=task_id, assigned_to=assigned_to,
            assigned_by=assigned_by, notes=notes,
        )
        self._db.add(assignment)
        task.assigned_to = assigned_to
        task.assigned_at = datetime.now(timezone.utc)
        task.status      = TaskStatusEnum.IN_PROGRESS
        self._db.flush()
        return task

    def get_workspace_summary(self, registrar_user_id: Optional[int] = None) -> Dict:
        """Dashboard summary for the registrar workspace."""
        base = self._db.query(RegistrarTask)
        if registrar_user_id:
            base = base.filter(RegistrarTask.assigned_to == registrar_user_id)

        return {
            "open":        base.filter(RegistrarTask.status == TaskStatusEnum.OPEN.value).count(),
            "in_progress": base.filter(RegistrarTask.status == TaskStatusEnum.IN_PROGRESS.value).count(),
            "urgent":      base.filter(RegistrarTask.priority == "urgent",
                                       RegistrarTask.status != TaskStatusEnum.COMPLETE.value).count(),
            "overdue":     base.filter(
                RegistrarTask.due_date < datetime.now(timezone.utc),
                RegistrarTask.status.notin_([TaskStatusEnum.COMPLETE.value,
                                              TaskStatusEnum.CANCELLED.value]),
            ).count(),
        }


# ═════════════════════════════════════════════════════════════════════════════
# PREREQUISITE VALIDATION REPOSITORY
# ═════════════════════════════════════════════════════════════════════════════

class PrerequisiteValidationRepository(BaseRepository[PrerequisiteValidation]):

    def __init__(self, db: Session):
        super().__init__(db, PrerequisiteValidation)

    def get_for_student(self, student_id: int,
                        term_id: Optional[int] = None) -> List[PrerequisiteValidation]:
        q = self._db.query(PrerequisiteValidation).filter(
            PrerequisiteValidation.student_id == student_id
        )
        if term_id:
            q = q.filter(PrerequisiteValidation.term_id == term_id)
        return q.order_by(desc(PrerequisiteValidation.validated_at)).all()

    def get_failed_checks(self, student_id: int) -> List[PrerequisiteValidation]:
        return self._db.query(PrerequisiteValidation).filter(
            PrerequisiteValidation.student_id == student_id,
            PrerequisiteValidation.is_eligible == False,
            PrerequisiteValidation.override_applied == False,
        ).all()
