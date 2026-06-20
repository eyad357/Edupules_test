"""
EduGuard AI — Sprint 4 Repository Layer
========================================
All Sprint 4 services access the database exclusively through these
repositories. No service contains direct ORM queries.

Design:
  - BaseRepository[T]        generic CRUD foundation
  - Each domain has its own typed repository
  - Services receive repositories via dependency injection
  - Direct session access is allowed ONLY inside repository methods
"""

from __future__ import annotations

from abc import ABC
from typing import Any, Dict, Generic, List, Optional, Tuple, Type, TypeVar
from decimal import Decimal
from datetime import datetime, timezone

from sqlalchemy.orm import Session
from sqlalchemy import desc, and_, or_, func

from app.db.database import Base
from app.models.models import Student, User, Course
from app.models.academic_models import (
    AcademicProgram, AcademicTrack, AcademicTerm,
    StudentCourseAttempt, StudentTermGPA,
    GradeScale, GraduationRequirement,
)
from app.models.sprint4_models import (
    AcademicRulesConfig,
    SemesterSnapshot,
    TranscriptVersion,
    TranscriptVerification,
    AcademicTimelineEvent,
    AcademicStatusHistory,
    DegreeProgressSnapshot,
    GraduationEligibilityRecord,
    HonorsRecord,
    GPAProjection,
    AcademicRiskRecord,
    RegistrarNote,
    AcademicAuditEntry,
    ScholarshipEvaluation,
    GPAVersion,
    AcademicAchievement,
    GPAExplanation,
)

T = TypeVar("T", bound=Base)


# ═════════════════════════════════════════════════════════════════════════════
# BASE REPOSITORY
# ═════════════════════════════════════════════════════════════════════════════

class BaseRepository(Generic[T]):
    """Generic repository providing standard CRUD operations."""

    def __init__(self, db: Session, model: Type[T]):
        self._db    = db
        self._model = model

    def get_by_id(self, entity_id: int) -> Optional[T]:
        return self._db.query(self._model).filter(
            self._model.id == entity_id
        ).first()

    def get_all(self, limit: int = 100, offset: int = 0) -> List[T]:
        return self._db.query(self._model).offset(offset).limit(limit).all()

    def create(self, data: Dict[str, Any]) -> T:
        obj = self._model(**data)
        self._db.add(obj)
        self._db.flush()
        return obj

    def update(self, entity_id: int, data: Dict[str, Any]) -> Optional[T]:
        obj = self.get_by_id(entity_id)
        if obj is None:
            return None
        for k, v in data.items():
            setattr(obj, k, v)
        self._db.flush()
        return obj

    def delete(self, entity_id: int) -> bool:
        obj = self.get_by_id(entity_id)
        if obj is None:
            return False
        self._db.delete(obj)
        self._db.flush()
        return True

    def commit(self) -> None:
        self._db.commit()

    def refresh(self, obj: T) -> T:
        self._db.refresh(obj)
        return obj


# ═════════════════════════════════════════════════════════════════════════════
# STUDENT REPOSITORY
# ═════════════════════════════════════════════════════════════════════════════

class StudentRepository(BaseRepository[Student]):

    def __init__(self, db: Session):
        super().__init__(db, Student)

    def get_with_user(self, student_id: int) -> Optional[Tuple[Student, User]]:
        row = (
            self._db.query(Student, User)
            .join(User, Student.user_id == User.id)
            .filter(Student.id == student_id)
            .first()
        )
        return row  # (Student, User) or None

    def get_program_and_track(
        self, student_id: int
    ) -> Tuple[Optional[AcademicProgram], Optional[AcademicTrack]]:
        student = self.get_by_id(student_id)
        if not student:
            return None, None
        prog  = (self._db.query(AcademicProgram)
                 .filter(AcademicProgram.id == student.program_id).first()
                 if student.program_id else None)
        track = (self._db.query(AcademicTrack)
                 .filter(AcademicTrack.id == student.track_id).first()
                 if student.track_id else None)
        return prog, track

    def update_cgpa(
        self,
        student_id: int,
        cgpa: Decimal,
        hours_attempted: int,
        hours_earned: int,
        quality_points: Decimal,
    ) -> None:
        self._db.query(Student).filter(Student.id == student_id).update({
            "cgpa": float(cgpa),
            "total_credit_hours_attempted": hours_attempted,
            "total_credit_hours_earned": hours_earned,
            "total_quality_points": float(quality_points),
        })
        self._db.flush()

    def set_standing(self, student_id: int, standing: str) -> None:
        self._db.query(Student).filter(Student.id == student_id).update({
            "academic_standing": standing
        })
        self._db.flush()

    def set_graduation_eligible(self, student_id: int, eligible: bool) -> None:
        self._db.query(Student).filter(Student.id == student_id).update({
            "is_eligible_for_graduation": eligible
        })
        self._db.flush()


# ═════════════════════════════════════════════════════════════════════════════
# RULES CONFIG REPOSITORY
# ═════════════════════════════════════════════════════════════════════════════

class RulesConfigRepository(BaseRepository[AcademicRulesConfig]):

    # Explicit PENDING marker for policies not in uploaded documents
    PENDING = "PENDING_POLICY_CONFIGURATION"

    # Only rules explicitly provable from uploaded documents
    DOCUMENT_SOURCED_RULES: Dict[str, Tuple[str, str]] = {
        # key: (value, source citation)
        "cgpa_formula":                ("sum(grade_points*credit_hours)/sum(credit_hours)", "CGPA_Calculator xlsx — formula verified: 100.70/78=1.291"),
        "repeat_policy":               ("all_attempts",    "CGPA_Calculator xlsx — 39 rows including repeated attempts all summed"),
        "p_grade_cgpa_exclusion":      ("excluded",        "CGPA_Calculator xlsx — LAN021: 0 CH, P grade, 0 weighted, excluded from sum"),
        "fl_grade_points":             ("0.0",             "CGPA_Calculator xlsx — FL grade mapped to 0.0 grade points"),
        "f_grade_points":              ("0.0",             "CGPA_Calculator xlsx — F grade mapped to 0.0 grade points"),
        "d_grade_points":              ("1.0",             "CGPA_Calculator xlsx — D grade mapped to 1.0 grade points"),
        "total_required_credits":      ("134",             "Track_Courses_List Study Plan — total CH column = 134"),
        "total_ects":                  ("268",             "Track_Courses_List Study Plan — total ECTS = 268"),
        "elective_slots_required":     ("3",               "Track_Courses_List — E1, E2, E3 elective slots"),
        "elective_credits_per_slot":   ("3",               "Track_Courses_List — each elective slot = 3 CH"),
        "university_req_count":        ("7",               "Track_Courses_List — UC1 through UC7"),
        "university_req_credits_each": ("2",               "Track_Courses_List — each UC = 2 CH"),
        "university_elective_count":   ("3",               "Track_Courses_List — UE1, UE2, UE3"),
        "university_elective_credits_each": ("2",          "Track_Courses_List — each UE = 2 CH"),
        "field_training_courses":      ("CSE191,CSE292",   "Track_Courses_List — semesters 3 and 6"),
        "field_training_credits_each": ("2",               "Track_Courses_List — CSE191=2CH, CSE292=2CH"),
        "graduation_project_1":        ("CSE493",          "Track_Courses_List — semester 7, 2 CH"),
        "graduation_project_2":        ("CSE494",          "Track_Courses_List — semester 8, 2 CH"),
        "graduation_project_credits":  ("2",               "Track_Courses_List — GP1=2CH, GP2=2CH"),
        # PENDING — not in uploaded documents
        "min_cgpa_graduation":         (PENDING,           "NOT in uploaded documents — awaiting university regulation upload"),
        "min_cgpa_good_standing":      (PENDING,           "NOT in uploaded documents — awaiting university regulation upload"),
        "min_cgpa_warning":            (PENDING,           "NOT in uploaded documents — awaiting university regulation upload"),
        "min_cgpa_probation":          (PENDING,           "NOT in uploaded documents — awaiting university regulation upload"),
        "min_cgpa_suspension":         (PENDING,           "NOT in uploaded documents — awaiting university regulation upload"),
        "deans_list_term_gpa":         (PENDING,           "NOT in uploaded documents — awaiting university regulation upload"),
        "deans_list_min_credits":      (PENDING,           "NOT in uploaded documents — awaiting university regulation upload"),
        "honors_cgpa":                 (PENDING,           "NOT in uploaded documents — awaiting university regulation upload"),
        "high_honors_cgpa":            (PENDING,           "NOT in uploaded documents — awaiting university regulation upload"),
        "distinction_cgpa":            (PENDING,           "NOT in uploaded documents — awaiting university regulation upload"),
        "scholarship_min_cgpa":        (PENDING,           "NOT in uploaded documents — awaiting university regulation upload"),
        "scholarship_min_credits":     (PENDING,           "NOT in uploaded documents — awaiting university regulation upload"),
        "max_repeat_attempts":         (PENDING,           "NOT in uploaded documents — awaiting university regulation upload"),
        "max_credit_load_per_term":    (PENDING,           "NOT in uploaded documents — awaiting university regulation upload"),
        "withdrawal_deadline_weeks":   (PENDING,           "NOT in uploaded documents — awaiting university regulation upload"),
    }

    def __init__(self, db: Session):
        super().__init__(db, AcademicRulesConfig)

    def get_rule(self, key: str, program_id: Optional[int] = None) -> Optional[str]:
        """Fetch rule — program-specific first, then global. Returns None if not found."""
        if program_id:
            row = self._db.query(AcademicRulesConfig).filter(
                AcademicRulesConfig.program_id == program_id,
                AcademicRulesConfig.rule_key == key,
            ).first()
            if row:
                return row.rule_value
        row = self._db.query(AcademicRulesConfig).filter(
            AcademicRulesConfig.program_id.is_(None),
            AcademicRulesConfig.rule_key == key,
        ).first()
        return row.rule_value if row else None

    def get_rule_or_pending(self, key: str, program_id: Optional[int] = None) -> str:
        """Return rule value or PENDING_POLICY_CONFIGURATION if not set."""
        val = self.get_rule(key, program_id)
        if val is None:
            return self.PENDING
        return val

    def is_pending(self, key: str, program_id: Optional[int] = None) -> bool:
        val = self.get_rule_or_pending(key, program_id)
        return val == self.PENDING

    def get_float_or_none(self, key: str, program_id: Optional[int] = None) -> Optional[float]:
        val = self.get_rule(key, program_id)
        if val is None or val == self.PENDING:
            return None
        try:
            return float(val)
        except (ValueError, TypeError):
            return None

    def get_int_or_none(self, key: str, program_id: Optional[int] = None) -> Optional[int]:
        val = self.get_rule(key, program_id)
        if val is None or val == self.PENDING:
            return None
        try:
            return int(val)
        except (ValueError, TypeError):
            return None

    def seed_documented_rules(self) -> int:
        """Seed only document-sourced rules. Returns count of newly inserted rows."""
        count = 0
        for key, (value, source) in self.DOCUMENT_SOURCED_RULES.items():
            exists = self._db.query(AcademicRulesConfig).filter(
                AcademicRulesConfig.program_id.is_(None),
                AcademicRulesConfig.rule_key == key,
            ).first()
            if not exists:
                self._db.add(AcademicRulesConfig(
                    program_id=None,
                    rule_key=key,
                    rule_value=value,
                    description=f"[SOURCE: {source}]",
                ))
                count += 1
        self._db.commit()
        return count

    def get_all_with_status(self, program_id: Optional[int] = None) -> List[Dict[str, Any]]:
        """Return all rules with PENDING flags clearly marked."""
        rows = self._db.query(AcademicRulesConfig).filter(
            or_(
                AcademicRulesConfig.program_id == program_id,
                AcademicRulesConfig.program_id.is_(None),
            )
        ).order_by(AcademicRulesConfig.rule_key).all()

        return [{
            "id": r.id,
            "rule_key": r.rule_key,
            "rule_value": r.rule_value,
            "is_pending": r.rule_value == self.PENDING,
            "description": r.description,
            "program_id": r.program_id,
            "updated_at": r.updated_at,
        } for r in rows]


# ═════════════════════════════════════════════════════════════════════════════
# GRADE SCALE REPOSITORY
# ═════════════════════════════════════════════════════════════════════════════

class GradeScaleRepository(BaseRepository[GradeScale]):

    def __init__(self, db: Session):
        super().__init__(db, GradeScale)

    def get_by_letter(self, letter: str, program_id: Optional[int] = None) -> Optional[GradeScale]:
        q = self._db.query(GradeScale).filter(GradeScale.letter_grade == letter.upper())
        if program_id:
            row = q.filter(GradeScale.program_id == program_id).first()
            if row:
                return row
        return q.filter(GradeScale.program_id.is_(None)).first()

    def get_for_program(self, program_id: Optional[int] = None) -> List[GradeScale]:
        if program_id:
            rows = self._db.query(GradeScale).filter(
                GradeScale.program_id == program_id
            ).all()
            if rows:
                return rows
        return self._db.query(GradeScale).filter(
            GradeScale.program_id.is_(None)
        ).order_by(desc(GradeScale.grade_points)).all()


# ═════════════════════════════════════════════════════════════════════════════
# COURSE ATTEMPT REPOSITORY
# ═════════════════════════════════════════════════════════════════════════════

class CourseAttemptRepository(BaseRepository[StudentCourseAttempt]):

    def __init__(self, db: Session):
        super().__init__(db, StudentCourseAttempt)

    def get_for_student(self, student_id: int) -> List[StudentCourseAttempt]:
        return self._db.query(StudentCourseAttempt).filter(
            StudentCourseAttempt.student_id == student_id
        ).order_by(StudentCourseAttempt.term_id, StudentCourseAttempt.attempt_number).all()

    def get_for_term(self, student_id: int, term_id: int) -> List[StudentCourseAttempt]:
        return self._db.query(StudentCourseAttempt).filter(
            StudentCourseAttempt.student_id == student_id,
            StudentCourseAttempt.term_id == term_id,
        ).all()

    def get_cgpa_eligible(self, student_id: int, up_to_term_id: Optional[int] = None) -> List[StudentCourseAttempt]:
        q = self._db.query(StudentCourseAttempt).filter(
            StudentCourseAttempt.student_id == student_id,
            StudentCourseAttempt.counts_in_cgpa == True,
        )
        if up_to_term_id:
            q = q.join(AcademicTerm, StudentCourseAttempt.term_id == AcademicTerm.id).filter(
                AcademicTerm.id <= up_to_term_id
            )
        return q.all()

    def get_passed(self, student_id: int) -> List[StudentCourseAttempt]:
        return self._db.query(StudentCourseAttempt).filter(
            StudentCourseAttempt.student_id == student_id,
            StudentCourseAttempt.result == "passed",
        ).all()

    def count_failed(self, student_id: int) -> int:
        return self._db.query(StudentCourseAttempt).filter(
            StudentCourseAttempt.student_id == student_id,
            StudentCourseAttempt.result == "failed",
        ).count()

    def count_withdrawn(self, student_id: int) -> int:
        return self._db.query(StudentCourseAttempt).filter(
            StudentCourseAttempt.student_id == student_id,
            StudentCourseAttempt.result == "withdrawn",
        ).count()

    def count_improvements(self, student_id: int) -> int:
        return self._db.query(StudentCourseAttempt).filter(
            StudentCourseAttempt.student_id == student_id,
            StudentCourseAttempt.is_improvement_attempt == True,
        ).count()

    def has_failures_in_term(self, student_id: int, term_id: int) -> bool:
        return self._db.query(StudentCourseAttempt).filter(
            StudentCourseAttempt.student_id == student_id,
            StudentCourseAttempt.term_id == term_id,
            StudentCourseAttempt.result.in_(["failed", "withdrawn"]),
        ).count() > 0

    def update_grade(
        self,
        attempt_id: int,
        letter_grade: str,
        grade_points: float,
        counts_in_cgpa: bool,
        result: str,
        graded_by: Optional[int],
    ) -> Optional[StudentCourseAttempt]:
        attempt = self.get_by_id(attempt_id)
        if not attempt:
            return None
        attempt.letter_grade    = letter_grade
        attempt.grade_points    = grade_points
        attempt.counts_in_cgpa  = counts_in_cgpa
        attempt.result          = result
        attempt.graded_by       = graded_by
        attempt.grade_posted_at = datetime.now(timezone.utc)
        self._db.flush()
        return attempt


# ═════════════════════════════════════════════════════════════════════════════
# TERM GPA REPOSITORY
# ═════════════════════════════════════════════════════════════════════════════

class TermGPARepository(BaseRepository[StudentTermGPA]):

    def __init__(self, db: Session):
        super().__init__(db, StudentTermGPA)

    def get_for_student_term(self, student_id: int, term_id: int) -> Optional[StudentTermGPA]:
        return self._db.query(StudentTermGPA).filter(
            StudentTermGPA.student_id == student_id,
            StudentTermGPA.term_id == term_id,
        ).first()

    def get_all_for_student(self, student_id: int, finalized_only: bool = False) -> List[StudentTermGPA]:
        q = self._db.query(StudentTermGPA).filter(StudentTermGPA.student_id == student_id)
        if finalized_only:
            q = q.filter(StudentTermGPA.finalized == True)
        return q.order_by(StudentTermGPA.term_id).all()

    def get_last_n_terms(self, student_id: int, n: int = 3) -> List[StudentTermGPA]:
        return self._db.query(StudentTermGPA).filter(
            StudentTermGPA.student_id == student_id,
            StudentTermGPA.finalized == True,
        ).order_by(desc(StudentTermGPA.term_id)).limit(n).all()

    def upsert(self, student_id: int, term_id: int, data: Dict[str, Any]) -> StudentTermGPA:
        existing = self.get_for_student_term(student_id, term_id)
        if existing:
            for k, v in data.items():
                setattr(existing, k, v)
            self._db.flush()
            return existing
        else:
            record = StudentTermGPA(student_id=student_id, term_id=term_id, **data)
            self._db.add(record)
            self._db.flush()
            return record


# ═════════════════════════════════════════════════════════════════════════════
# SNAPSHOT REPOSITORY
# ═════════════════════════════════════════════════════════════════════════════

class SnapshotRepository(BaseRepository[SemesterSnapshot]):

    def __init__(self, db: Session):
        super().__init__(db, SemesterSnapshot)

    def get_latest_version(self, student_id: int, term_id: int) -> Optional[SemesterSnapshot]:
        return self._db.query(SemesterSnapshot).filter(
            SemesterSnapshot.student_id == student_id,
            SemesterSnapshot.term_id == term_id,
        ).order_by(desc(SemesterSnapshot.version)).first()

    def get_next_version(self, student_id: int, term_id: int) -> int:
        last = self.get_latest_version(student_id, term_id)
        return (last.version + 1) if last else 1

    def get_for_student(self, student_id: int, term_id: Optional[int] = None) -> List[SemesterSnapshot]:
        q = self._db.query(SemesterSnapshot).filter(
            SemesterSnapshot.student_id == student_id
        )
        if term_id:
            q = q.filter(SemesterSnapshot.term_id == term_id)
        return q.order_by(SemesterSnapshot.term_id, SemesterSnapshot.version).all()


# ═════════════════════════════════════════════════════════════════════════════
# TRANSCRIPT REPOSITORY
# ═════════════════════════════════════════════════════════════════════════════

class TranscriptRepository(BaseRepository[TranscriptVersion]):

    def __init__(self, db: Session):
        super().__init__(db, TranscriptVersion)

    def get_current(self, student_id: int, transcript_type: Optional[str] = None) -> Optional[TranscriptVersion]:
        q = self._db.query(TranscriptVersion).filter(
            TranscriptVersion.student_id == student_id,
            TranscriptVersion.is_current == True,
        )
        if transcript_type:
            q = q.filter(TranscriptVersion.transcript_type == transcript_type)
        return q.order_by(desc(TranscriptVersion.generated_at)).first()

    def get_all_for_student(self, student_id: int, transcript_type: Optional[str] = None) -> List[TranscriptVersion]:
        q = self._db.query(TranscriptVersion).filter(
            TranscriptVersion.student_id == student_id
        )
        if transcript_type:
            q = q.filter(TranscriptVersion.transcript_type == transcript_type)
        return q.order_by(desc(TranscriptVersion.generated_at)).all()

    def mark_all_not_current(self, student_id: int, transcript_type: str) -> None:
        self._db.query(TranscriptVersion).filter(
            TranscriptVersion.student_id == student_id,
            TranscriptVersion.transcript_type == transcript_type,
            TranscriptVersion.is_current == True,
        ).update({"is_current": False})
        self._db.flush()

    def get_next_version_number(self, student_id: int, transcript_type: str) -> int:
        last = self._db.query(func.max(TranscriptVersion.version_number)).filter(
            TranscriptVersion.student_id == student_id,
            TranscriptVersion.transcript_type == transcript_type,
        ).scalar()
        return (last or 0) + 1

    def get_verification(self, transcript_id: int) -> Optional[TranscriptVerification]:
        return self._db.query(TranscriptVerification).filter(
            TranscriptVerification.transcript_id == transcript_id
        ).first()

    def get_by_verification_code(self, code: str) -> Optional[TranscriptVerification]:
        return self._db.query(TranscriptVerification).filter(
            TranscriptVerification.verification_code == code
        ).first()

    def increment_verification_count(self, verification_id: int) -> None:
        self._db.query(TranscriptVerification).filter(
            TranscriptVerification.id == verification_id
        ).update({
            "verified_count": TranscriptVerification.verified_count + 1,
            "last_verified_at": datetime.now(timezone.utc),
        })
        self._db.flush()


# ═════════════════════════════════════════════════════════════════════════════
# TIMELINE REPOSITORY
# ═════════════════════════════════════════════════════════════════════════════

class TimelineRepository(BaseRepository[AcademicTimelineEvent]):

    def __init__(self, db: Session):
        super().__init__(db, AcademicTimelineEvent)

    def get_for_student(
        self,
        student_id: int,
        event_type: Optional[str] = None,
        limit: int = 100,
        offset: int = 0,
    ) -> Tuple[int, List[AcademicTimelineEvent]]:
        q = self._db.query(AcademicTimelineEvent).filter(
            AcademicTimelineEvent.student_id == student_id
        )
        if event_type:
            q = q.filter(AcademicTimelineEvent.event_type == event_type)
        total = q.count()
        rows  = q.order_by(desc(AcademicTimelineEvent.occurred_at)).offset(offset).limit(limit).all()
        return total, rows


# ═════════════════════════════════════════════════════════════════════════════
# STATUS HISTORY REPOSITORY
# ═════════════════════════════════════════════════════════════════════════════

class StatusHistoryRepository(BaseRepository[AcademicStatusHistory]):

    def __init__(self, db: Session):
        super().__init__(db, AcademicStatusHistory)

    def get_latest(self, student_id: int) -> Optional[AcademicStatusHistory]:
        return self._db.query(AcademicStatusHistory).filter(
            AcademicStatusHistory.student_id == student_id
        ).order_by(desc(AcademicStatusHistory.occurred_at)).first()

    def get_all_for_student(self, student_id: int) -> List[AcademicStatusHistory]:
        return self._db.query(AcademicStatusHistory).filter(
            AcademicStatusHistory.student_id == student_id
        ).order_by(AcademicStatusHistory.occurred_at).all()


# ═════════════════════════════════════════════════════════════════════════════
# DEGREE PROGRESS REPOSITORY
# ═════════════════════════════════════════════════════════════════════════════

class DegreeProgressRepository(BaseRepository[DegreeProgressSnapshot]):

    def __init__(self, db: Session):
        super().__init__(db, DegreeProgressSnapshot)

    def get_latest(self, student_id: int) -> Optional[DegreeProgressSnapshot]:
        return self._db.query(DegreeProgressSnapshot).filter(
            DegreeProgressSnapshot.student_id == student_id
        ).order_by(desc(DegreeProgressSnapshot.version)).first()

    def get_next_version(self, student_id: int) -> int:
        last = self.get_latest(student_id)
        return (last.version + 1) if last else 1

    def get_graduation_requirements(self, program_id: int, track_id: Optional[int] = None) -> List[GraduationRequirement]:
        q = self._db.query(GraduationRequirement).filter(
            GraduationRequirement.program_id == program_id
        )
        if track_id:
            track_reqs = self._db.query(GraduationRequirement).filter(
                GraduationRequirement.track_id == track_id
            ).all()
            if track_reqs:
                prog_reqs  = q.all()
                req_map = {r.category: r for r in prog_reqs}
                for tr in track_reqs:
                    req_map[tr.category] = tr
                return list(req_map.values())
        return q.all()


# ═════════════════════════════════════════════════════════════════════════════
# GRADUATION ELIGIBILITY REPOSITORY
# ═════════════════════════════════════════════════════════════════════════════

class GraduationEligibilityRepository(BaseRepository[GraduationEligibilityRecord]):

    def __init__(self, db: Session):
        super().__init__(db, GraduationEligibilityRecord)

    def get_current(self, student_id: int) -> Optional[GraduationEligibilityRecord]:
        return self._db.query(GraduationEligibilityRecord).filter(
            GraduationEligibilityRecord.student_id == student_id,
            GraduationEligibilityRecord.is_current == True,
        ).first()

    def invalidate_current(self, student_id: int) -> None:
        self._db.query(GraduationEligibilityRecord).filter(
            GraduationEligibilityRecord.student_id == student_id,
            GraduationEligibilityRecord.is_current == True,
        ).update({"is_current": False})
        self._db.flush()


# ═════════════════════════════════════════════════════════════════════════════
# HONORS REPOSITORY
# ═════════════════════════════════════════════════════════════════════════════

class HonorsRepository(BaseRepository[HonorsRecord]):

    def __init__(self, db: Session):
        super().__init__(db, HonorsRecord)

    def get_all_for_student(self, student_id: int) -> List[HonorsRecord]:
        return self._db.query(HonorsRecord).filter(
            HonorsRecord.student_id == student_id
        ).order_by(desc(HonorsRecord.awarded_at)).all()

    def get_latest(self, student_id: int) -> Optional[HonorsRecord]:
        return self._db.query(HonorsRecord).filter(
            HonorsRecord.student_id == student_id
        ).order_by(desc(HonorsRecord.awarded_at)).first()


# ═════════════════════════════════════════════════════════════════════════════
# GPA VERSION REPOSITORY
# ═════════════════════════════════════════════════════════════════════════════

class GPAVersionRepository(BaseRepository[GPAVersion]):

    def __init__(self, db: Session):
        super().__init__(db, GPAVersion)

    def get_for_student(self, student_id: int, limit: int = 50) -> List[GPAVersion]:
        return self._db.query(GPAVersion).filter(
            GPAVersion.student_id == student_id
        ).order_by(desc(GPAVersion.recorded_at)).limit(limit).all()

    def get_next_version(self, student_id: int) -> int:
        last = self._db.query(func.max(GPAVersion.version_number)).filter(
            GPAVersion.student_id == student_id
        ).scalar()
        return (last or 0) + 1


# ═════════════════════════════════════════════════════════════════════════════
# GPA EXPLANATION REPOSITORY
# ═════════════════════════════════════════════════════════════════════════════

class GPAExplanationRepository(BaseRepository[GPAExplanation]):

    def __init__(self, db: Session):
        super().__init__(db, GPAExplanation)

    def get_latest(self, student_id: int) -> Optional[GPAExplanation]:
        return self._db.query(GPAExplanation).filter(
            GPAExplanation.student_id == student_id,
            GPAExplanation.is_current == True,
        ).order_by(desc(GPAExplanation.generated_at)).first()

    def get_for_term(self, student_id: int, term_id: int) -> Optional[GPAExplanation]:
        return self._db.query(GPAExplanation).filter(
            GPAExplanation.student_id == student_id,
            GPAExplanation.term_id == term_id,
        ).order_by(desc(GPAExplanation.generated_at)).first()

    def invalidate_current(self, student_id: int) -> None:
        self._db.query(GPAExplanation).filter(
            GPAExplanation.student_id == student_id,
            GPAExplanation.is_current == True,
        ).update({"is_current": False})
        self._db.flush()


# ═════════════════════════════════════════════════════════════════════════════
# SCHOLARSHIP REPOSITORY
# ═════════════════════════════════════════════════════════════════════════════

class ScholarshipRepository(BaseRepository[ScholarshipEvaluation]):

    def __init__(self, db: Session):
        super().__init__(db, ScholarshipEvaluation)

    def get_current(self, student_id: int) -> Optional[ScholarshipEvaluation]:
        return self._db.query(ScholarshipEvaluation).filter(
            ScholarshipEvaluation.student_id == student_id,
            ScholarshipEvaluation.is_current == True,
        ).first()

    def get_all_for_student(self, student_id: int) -> List[ScholarshipEvaluation]:
        return self._db.query(ScholarshipEvaluation).filter(
            ScholarshipEvaluation.student_id == student_id
        ).order_by(desc(ScholarshipEvaluation.evaluated_at)).all()

    def invalidate_current(self, student_id: int) -> None:
        self._db.query(ScholarshipEvaluation).filter(
            ScholarshipEvaluation.student_id == student_id,
            ScholarshipEvaluation.is_current == True,
        ).update({"is_current": False})
        self._db.flush()


# ═════════════════════════════════════════════════════════════════════════════
# ACHIEVEMENT REPOSITORY
# ═════════════════════════════════════════════════════════════════════════════

class AchievementRepository(BaseRepository[AcademicAchievement]):

    def __init__(self, db: Session):
        super().__init__(db, AcademicAchievement)

    def get_for_student(self, student_id: int, category: Optional[str] = None) -> List[AcademicAchievement]:
        q = self._db.query(AcademicAchievement).filter(
            AcademicAchievement.student_id == student_id
        )
        if category:
            q = q.filter(AcademicAchievement.category == category)
        return q.order_by(desc(AcademicAchievement.achieved_at)).all()


# ═════════════════════════════════════════════════════════════════════════════
# GPA PROJECTION REPOSITORY
# ═════════════════════════════════════════════════════════════════════════════

class GPAProjectionRepository(BaseRepository[GPAProjection]):

    def __init__(self, db: Session):
        super().__init__(db, GPAProjection)

    def get_history(self, student_id: int, limit: int = 20) -> List[GPAProjection]:
        return self._db.query(GPAProjection).filter(
            GPAProjection.student_id == student_id
        ).order_by(desc(GPAProjection.computed_at)).limit(limit).all()


# ═════════════════════════════════════════════════════════════════════════════
# RISK RECORD REPOSITORY
# ═════════════════════════════════════════════════════════════════════════════

class RiskRepository(BaseRepository[AcademicRiskRecord]):

    def __init__(self, db: Session):
        super().__init__(db, AcademicRiskRecord)

    def get_current(self, student_id: int) -> Optional[AcademicRiskRecord]:
        return self._db.query(AcademicRiskRecord).filter(
            AcademicRiskRecord.student_id == student_id,
            AcademicRiskRecord.is_current == True,
        ).first()

    def get_history(self, student_id: int) -> List[AcademicRiskRecord]:
        return self._db.query(AcademicRiskRecord).filter(
            AcademicRiskRecord.student_id == student_id
        ).order_by(desc(AcademicRiskRecord.assessed_at)).all()

    def invalidate_current(self, student_id: int) -> None:
        self._db.query(AcademicRiskRecord).filter(
            AcademicRiskRecord.student_id == student_id,
            AcademicRiskRecord.is_current == True,
        ).update({"is_current": False})
        self._db.flush()


# ═════════════════════════════════════════════════════════════════════════════
# REGISTRAR NOTE REPOSITORY
# ═════════════════════════════════════════════════════════════════════════════

class RegistrarNoteRepository(BaseRepository[RegistrarNote]):

    def __init__(self, db: Session):
        super().__init__(db, RegistrarNote)

    def search(
        self,
        student_id: int,
        note_type: Optional[str] = None,
        tag: Optional[str] = None,
        include_private: bool = False,
    ) -> List[RegistrarNote]:
        q = self._db.query(RegistrarNote).filter(
            RegistrarNote.student_id == student_id
        )
        if not include_private:
            q = q.filter(RegistrarNote.is_private == False)
        if note_type:
            q = q.filter(RegistrarNote.note_type == note_type)
        if tag:
            q = q.filter(RegistrarNote.tags.contains([tag]))
        return q.order_by(desc(RegistrarNote.created_at)).all()


# ═════════════════════════════════════════════════════════════════════════════
# AUDIT REPOSITORY
# ═════════════════════════════════════════════════════════════════════════════

class AuditRepository(BaseRepository[AcademicAuditEntry]):

    def __init__(self, db: Session):
        super().__init__(db, AcademicAuditEntry)

    def get_for_student(
        self,
        student_id: int,
        action: Optional[str] = None,
        limit: int = 50,
        offset: int = 0,
    ) -> List[AcademicAuditEntry]:
        q = self._db.query(AcademicAuditEntry).filter(
            AcademicAuditEntry.student_id == student_id
        )
        if action:
            q = q.filter(AcademicAuditEntry.action == action)
        return q.order_by(desc(AcademicAuditEntry.occurred_at)).offset(offset).limit(limit).all()

    def append(self, entry_data: Dict[str, Any]) -> AcademicAuditEntry:
        """Audit entries are append-only — never updated."""
        entry = AcademicAuditEntry(**entry_data)
        self._db.add(entry)
        self._db.flush()
        return entry
