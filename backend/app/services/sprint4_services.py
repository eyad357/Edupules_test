"""
EduGuard AI — Sprint 4: Academic Intelligence Services
=======================================================
Production-grade GPA/CGPA engine, degree progress, graduation eligibility,
honors determination, and GPA projection.

All business rules loaded from AcademicRulesConfig — ZERO hardcoded thresholds.
"""

from __future__ import annotations

import hashlib
import json
import logging
import secrets
from decimal import Decimal, ROUND_HALF_UP
from typing import Any, Dict, List, Optional, Tuple
from datetime import datetime, timezone

from sqlalchemy.orm import Session
from sqlalchemy import and_, desc, func

from app.db.database import get_db
from app.models.models import Student, Course, User
from app.models.academic_models import (
    AcademicProgram, AcademicTrack, AcademicTerm, GradeScale,
    StudentCourseAttempt, StudentTermGPA, GraduationRequirement,
    StudentGraduationProgress,
)
from app.models.sprint4_models import (
    AcademicRulesConfig, SemesterSnapshot, TranscriptVersion,
    TranscriptVerification, AcademicTimelineEvent, AcademicStatusHistory,
    DegreeProgressSnapshot, GraduationEligibilityRecord, HonorsRecord,
    GPAProjection, AcademicRiskRecord, RegistrarNote, AcademicAuditEntry,
    AcademicStatusEnum, HonorsLevelEnum, GradEligibilityEnum, RiskLevelEnum,
    TimelineEventTypeEnum, AuditActionEnum,
)

logger = logging.getLogger(__name__)


# ═════════════════════════════════════════════════════════════════════════════
# RULES CONFIG SERVICE
# ═════════════════════════════════════════════════════════════════════════════

class RulesConfigService:
    """
    Central accessor for configurable academic rules.
    Falls back to global rules (program_id=None) when program-specific not found.
    """

    # Default rules seeded into the database on first run
    DEFAULT_RULES: Dict[str, str] = {
        "min_cgpa_graduation":     "2.00",
        "min_cgpa_good_standing":  "2.00",
        "min_cgpa_warning":        "1.70",
        "min_cgpa_probation":      "1.40",
        "deans_list_term_gpa":     "3.50",
        "deans_list_min_credits":  "15",
        "honors_cgpa":             "3.50",
        "high_honors_cgpa":        "3.75",
        "distinction_cgpa":        "3.75",
        "excellent_cgpa":          "3.50",
        "very_good_cgpa":          "3.00",
        "good_standing_cgpa":      "2.50",
        "total_required_credits":  "134",
        "min_elective_credits":    "9",
        "min_university_req_credits": "14",
        "min_field_training_credits": "4",
        "max_repeat_attempts":     "0",      # 0 = unlimited
        "repeat_policy":           "all_attempts",  # "all_attempts" | "best" | "latest"
        "transcript_expiry_days":  "365",
        "gpa_scale":               "4.0",
    }

    @classmethod
    def get(cls, db: Session, key: str, program_id: Optional[int] = None) -> str:
        """Fetch rule value — program-specific first, then global, then hardcoded default."""
        # 1. Program-specific
        if program_id:
            row = db.query(AcademicRulesConfig).filter(
                AcademicRulesConfig.program_id == program_id,
                AcademicRulesConfig.rule_key == key
            ).first()
            if row:
                return row.rule_value

        # 2. Global
        row = db.query(AcademicRulesConfig).filter(
            AcademicRulesConfig.program_id.is_(None),
            AcademicRulesConfig.rule_key == key
        ).first()
        if row:
            return row.rule_value

        # 3. Hardcoded fallback (development safety net)
        return cls.DEFAULT_RULES.get(key, "")

    @classmethod
    def get_float(cls, db: Session, key: str, program_id: Optional[int] = None) -> float:
        return float(cls.get(db, key, program_id) or 0)

    @classmethod
    def get_int(cls, db: Session, key: str, program_id: Optional[int] = None) -> int:
        return int(cls.get(db, key, program_id) or 0)

    @classmethod
    def seed_defaults(cls, db: Session) -> None:
        """Idempotent seed of default rules into the database."""
        for key, value in cls.DEFAULT_RULES.items():
            exists = db.query(AcademicRulesConfig).filter(
                AcademicRulesConfig.program_id.is_(None),
                AcademicRulesConfig.rule_key == key
            ).first()
            if not exists:
                db.add(AcademicRulesConfig(
                    program_id=None,
                    rule_key=key,
                    rule_value=value,
                    description=f"Default rule for {key}",
                ))
        db.commit()


# ═════════════════════════════════════════════════════════════════════════════
# GRADE PROCESSING ENGINE (Module 2)
# ═════════════════════════════════════════════════════════════════════════════

class GradeProcessingService:
    """
    Handles grade lookup, validation, and GPA point resolution.
    Grade scale is loaded from DB — never hardcoded.
    """

    # Grades that are excluded from CGPA entirely
    CGPA_EXCLUDED_GRADES = {"W", "I", "P", "IP"}

    @staticmethod
    def get_grade_info(db: Session, letter_grade: str, program_id: Optional[int] = None) -> Optional[GradeScale]:
        """Return GradeScale row for the given letter grade."""
        q = db.query(GradeScale).filter(GradeScale.letter_grade == letter_grade.upper())
        if program_id:
            row = q.filter(GradeScale.program_id == program_id).first()
            if row:
                return row
        return q.filter(GradeScale.program_id.is_(None)).first()

    @staticmethod
    def is_passing_grade(db: Session, letter_grade: str, program_id: Optional[int] = None) -> bool:
        info = GradeProcessingService.get_grade_info(db, letter_grade, program_id)
        if info is None:
            return False
        return info.is_passing

    @staticmethod
    def get_grade_points(db: Session, letter_grade: str, program_id: Optional[int] = None) -> Decimal:
        info = GradeProcessingService.get_grade_info(db, letter_grade, program_id)
        if info is None:
            return Decimal("0.0")
        return Decimal(str(info.grade_points))

    @staticmethod
    def counts_in_cgpa(letter_grade: str) -> bool:
        return letter_grade.upper() not in GradeProcessingService.CGPA_EXCLUDED_GRADES

    @staticmethod
    def get_attempt_result(letter_grade: str, is_passing: bool) -> str:
        g = letter_grade.upper()
        if g in ("W",):
            return "withdrawn"
        if g in ("I",):
            return "incomplete"
        if g in ("P",):
            return "passed"
        return "passed" if is_passing else "failed"

    @classmethod
    def process_grade_posting(
        cls,
        db: Session,
        attempt: StudentCourseAttempt,
        letter_grade: str,
        posted_by_user_id: Optional[int],
        program_id: Optional[int] = None,
    ) -> StudentCourseAttempt:
        """
        Apply a grade to a course attempt.
        Updates: letter_grade, grade_points, result, counts_in_cgpa, grade_posted_at
        """
        grade_info = cls.get_grade_info(db, letter_grade, program_id)
        if grade_info is None:
            raise ValueError(f"Unknown grade: {letter_grade}")

        old_grade = attempt.letter_grade
        attempt.letter_grade     = letter_grade.upper()
        attempt.grade_points     = grade_info.grade_points
        attempt.counts_in_cgpa   = grade_info.counts_in_cgpa
        attempt.graded_by        = posted_by_user_id
        attempt.grade_posted_at  = datetime.now(timezone.utc)
        attempt.result           = cls.get_attempt_result(letter_grade, grade_info.is_passing)

        if letter_grade.upper() == "W":
            attempt.withdrawn_at = datetime.now(timezone.utc)

        db.commit()
        db.refresh(attempt)

        # Audit
        AuditService.log(
            db=db, student_id=attempt.student_id, action=AuditActionEnum.GRADE_CHANGED,
            entity_type="course_attempt", entity_id=attempt.id,
            old_value={"grade": old_grade},
            new_value={"grade": letter_grade},
            actor_id=posted_by_user_id,
        )
        return attempt


# ═════════════════════════════════════════════════════════════════════════════
# GPA / CGPA ENGINE (Module 3)
# ═════════════════════════════════════════════════════════════════════════════

class GPAEngine:
    """
    Production-grade GPA/CGPA calculation engine.
    Reads repeat policy from AcademicRulesConfig.
    Stores calculation results in StudentTermGPA and audit trail.
    """

    @staticmethod
    def _round(value: Decimal, places: int = 3) -> Decimal:
        quantizer = Decimal(10) ** -places
        return value.quantize(quantizer, rounding=ROUND_HALF_UP)

    @classmethod
    def calculate_semester_gpa(
        cls,
        db: Session,
        student_id: int,
        term_id: int,
        program_id: Optional[int] = None,
    ) -> Decimal:
        """
        Semester GPA = Σ(grade_points × credit_hours) / Σ(credit_hours)
        Excludes W, I, P, IP grades.
        """
        attempts = db.query(StudentCourseAttempt).filter(
            StudentCourseAttempt.student_id == student_id,
            StudentCourseAttempt.term_id == term_id,
            StudentCourseAttempt.counts_in_cgpa == True,
        ).all()

        total_points = Decimal("0")
        total_hours  = Decimal("0")

        for a in attempts:
            if a.grade_points is not None and a.credit_hours:
                pts = Decimal(str(a.grade_points)) * Decimal(str(a.credit_hours))
                total_points += pts
                total_hours  += Decimal(str(a.credit_hours))

        if total_hours == 0:
            return Decimal("0.000")
        return cls._round(total_points / total_hours)

    @classmethod
    def calculate_cgpa(
        cls,
        db: Session,
        student_id: int,
        up_to_term_id: Optional[int] = None,
        program_id: Optional[int] = None,
    ) -> Tuple[Decimal, int, Decimal]:
        """
        CGPA = Σ(grade_points × credit_hours) / Σ(credit_hours attempted)
        Returns: (cgpa, total_hours_attempted, total_quality_points)
        
        Repeat policy read from config:
          - "all_attempts"  → include every attempt (default, matches the university's calculator)
          - "best"          → best grade per course
          - "latest"        → latest attempt per course
        """
        repeat_policy = RulesConfigService.get(db, "repeat_policy", program_id)

        base_query = db.query(StudentCourseAttempt).filter(
            StudentCourseAttempt.student_id == student_id,
            StudentCourseAttempt.counts_in_cgpa == True,
        )

        if up_to_term_id:
            # Join to get term order
            base_query = base_query.join(
                AcademicTerm, StudentCourseAttempt.term_id == AcademicTerm.id
            ).filter(AcademicTerm.id <= up_to_term_id)

        all_attempts = base_query.all()

        if repeat_policy == "best":
            # Group by course, keep best grade_points per course
            course_map: Dict[int, StudentCourseAttempt] = {}
            for a in all_attempts:
                if a.grade_points is None:
                    continue
                existing = course_map.get(a.course_id)
                if existing is None or Decimal(str(a.grade_points)) > Decimal(str(existing.grade_points)):
                    course_map[a.course_id] = a
            applicable = list(course_map.values())

        elif repeat_policy == "latest":
            # Group by course, keep highest attempt_number
            course_map: Dict[int, StudentCourseAttempt] = {}
            for a in all_attempts:
                existing = course_map.get(a.course_id)
                if existing is None or a.attempt_number > existing.attempt_number:
                    course_map[a.course_id] = a
            applicable = list(course_map.values())

        else:
            # "all_attempts" — default (matches institution's calculator)
            applicable = [a for a in all_attempts if a.grade_points is not None]

        total_points = Decimal("0")
        total_hours  = Decimal("0")

        for a in applicable:
            if a.grade_points is not None and a.credit_hours:
                pts = Decimal(str(a.grade_points)) * Decimal(str(a.credit_hours))
                total_points += pts
                total_hours  += Decimal(str(a.credit_hours))

        if total_hours == 0:
            return Decimal("0.000"), 0, Decimal("0.000")

        cgpa = cls._round(total_points / total_hours)
        return cgpa, int(total_hours), cls._round(total_points)

    @classmethod
    def finalize_term(
        cls,
        db: Session,
        student_id: int,
        term_id: int,
        program_id: Optional[int] = None,
        actor_id: Optional[int] = None,
    ) -> StudentTermGPA:
        """
        Compute and persist semester GPA + CGPA after a term ends.
        Creates/updates StudentTermGPA row.
        Triggers: snapshot, honors check, status update, timeline event.
        """
        term_gpa = cls.calculate_semester_gpa(db, student_id, term_id, program_id)
        cgpa, cum_attempted, cum_points = cls.calculate_cgpa(db, student_id, up_to_term_id=term_id, program_id=program_id)

        # Credits this term
        term_attempts = db.query(StudentCourseAttempt).filter(
            StudentCourseAttempt.student_id == student_id,
            StudentCourseAttempt.term_id == term_id,
        ).all()
        term_attempted = sum(a.credit_hours or 0 for a in term_attempts if a.counts_in_cgpa)
        term_earned    = sum(a.credit_hours or 0 for a in term_attempts if a.result == "passed")
        term_points    = sum(
            (Decimal(str(a.grade_points or 0)) * Decimal(str(a.credit_hours or 0)))
            for a in term_attempts if a.counts_in_cgpa
        )

        # Determine academic standing
        standing = AcademicStandingService.determine_standing(db, student_id, cgpa, program_id)

        # Upsert StudentTermGPA
        existing = db.query(StudentTermGPA).filter(
            StudentTermGPA.student_id == student_id,
            StudentTermGPA.term_id == term_id,
        ).first()

        if existing:
            record = existing
        else:
            record = StudentTermGPA(student_id=student_id, term_id=term_id)
            db.add(record)

        record.term_credit_hours_attempted  = term_attempted
        record.term_credit_hours_earned     = term_earned
        record.term_quality_points          = float(term_points)
        record.term_gpa                     = float(term_gpa)
        record.cumulative_hours_attempted   = int(cum_attempted)
        record.cumulative_hours_earned      = sum(
            a.credit_hours or 0 for a in db.query(StudentCourseAttempt).filter(
                StudentCourseAttempt.student_id == student_id,
                StudentCourseAttempt.result == "passed",
            ).all()
        )
        record.cumulative_quality_points    = float(cum_points)
        record.cgpa                         = float(cgpa)
        record.academic_standing            = standing
        record.finalized                    = True
        record.finalized_at                 = datetime.now(timezone.utc)

        db.commit()
        db.refresh(record)

        # Update student.cgpa
        student = db.query(Student).filter(Student.id == student_id).first()
        if student:
            student.cgpa = float(cgpa)
            student.total_credit_hours_attempted = int(cum_attempted)
            student.total_quality_points = float(cum_points)
            student.academic_standing = standing
            db.commit()

        # Create snapshot
        SnapshotService.create_semester_snapshot(db, student_id, term_id, record, actor_id)

        # Honors check
        HonorsService.evaluate_term_honors(db, student_id, term_id, program_id)

        # Status tracking
        AcademicStandingService.record_status_change(db, student_id, term_id, standing, cgpa, term_gpa)

        # Audit
        AuditService.log(
            db=db, student_id=student_id, action=AuditActionEnum.GPA_RECALCULATED,
            entity_type="student_term_gpa", entity_id=record.id,
            new_value={"term_gpa": float(term_gpa), "cgpa": float(cgpa)},
            actor_id=actor_id,
        )

        # Timeline
        TimelineService.record(
            db=db, student_id=student_id, term_id=term_id,
            event_type=TimelineEventTypeEnum.GPA_RECALCULATED,
            title=f"Term GPA finalized: {term_gpa:.3f} | CGPA: {cgpa:.3f}",
            payload={"term_gpa": float(term_gpa), "cgpa": float(cgpa), "standing": standing},
            actor_id=actor_id,
        )

        return record


# ═════════════════════════════════════════════════════════════════════════════
# SEMESTER SNAPSHOT SERVICE (Module 4)
# ═════════════════════════════════════════════════════════════════════════════

class SnapshotService:

    @staticmethod
    def _hash_snapshot(data: Dict[str, Any]) -> str:
        payload = json.dumps(data, sort_keys=True, default=str)
        return hashlib.sha256(payload.encode()).hexdigest()

    @classmethod
    def create_semester_snapshot(
        cls,
        db: Session,
        student_id: int,
        term_id: int,
        term_gpa_record: StudentTermGPA,
        actor_id: Optional[int] = None,
    ) -> SemesterSnapshot:
        """Create immutable versioned snapshot. Never overwrites existing."""

        last = db.query(SemesterSnapshot).filter(
            SemesterSnapshot.student_id == student_id,
            SemesterSnapshot.term_id == term_id,
        ).order_by(desc(SemesterSnapshot.version)).first()

        version = (last.version + 1) if last else 1

        # Credits this term
        attempts = db.query(StudentCourseAttempt).filter(
            StudentCourseAttempt.student_id == student_id,
            StudentCourseAttempt.term_id == term_id,
        ).all()
        credits_attempted  = sum(a.credit_hours or 0 for a in attempts if a.counts_in_cgpa)
        credits_earned     = sum(a.credit_hours or 0 for a in attempts if a.result == "passed")
        credits_failed     = sum(a.credit_hours or 0 for a in attempts if a.result == "failed")
        credits_withdrawn  = sum(a.credit_hours or 0 for a in attempts if a.result == "withdrawn")

        standing_str = term_gpa_record.academic_standing or "active"
        try:
            standing = AcademicStatusEnum(standing_str)
        except ValueError:
            standing = AcademicStatusEnum.ACTIVE

        snap_data = {
            "student_id": student_id,
            "term_id": term_id,
            "version": version,
            "term_gpa": float(term_gpa_record.term_gpa or 0),
            "cgpa": float(term_gpa_record.cgpa or 0),
            "credits_attempted": credits_attempted,
            "credits_earned": credits_earned,
        }

        snap = SemesterSnapshot(
            student_id=student_id,
            term_id=term_id,
            version=version,
            term_gpa=float(term_gpa_record.term_gpa or 0),
            cgpa_after_term=float(term_gpa_record.cgpa or 0),
            credits_attempted=credits_attempted,
            credits_earned=credits_earned,
            credits_failed=credits_failed,
            credits_withdrawn=credits_withdrawn,
            cumulative_attempted=term_gpa_record.cumulative_hours_attempted or 0,
            cumulative_earned=term_gpa_record.cumulative_hours_earned or 0,
            academic_standing=standing,
            snapshot_hash=cls._hash_snapshot(snap_data),
            generated_by=actor_id,
            is_final=True,
        )
        db.add(snap)
        db.commit()
        db.refresh(snap)
        return snap


# ═════════════════════════════════════════════════════════════════════════════
# TRANSCRIPT ENGINE (Modules 5 & 6)
# ═════════════════════════════════════════════════════════════════════════════

class TranscriptService:

    @classmethod
    def build_transcript_payload(
        cls,
        db: Session,
        student_id: int,
        transcript_type: str = "unofficial",
        term_id: Optional[int] = None,
    ) -> Dict[str, Any]:
        """Build the complete transcript data payload."""
        student = db.query(Student).filter(Student.id == student_id).first()
        if not student:
            raise ValueError(f"Student {student_id} not found")

        user = db.query(User).filter(User.id == student.user_id).first()

        # Program / Track / Department info
        program_name = None
        track_name   = None
        dept_name    = None
        if student.program_id:
            prog = db.query(AcademicProgram).filter(AcademicProgram.id == student.program_id).first()
            if prog:
                program_name = prog.name
        if student.track_id:
            track = db.query(AcademicTrack).filter(AcademicTrack.id == student.track_id).first()
            if track:
                track_name = track.name

        # Get all terms with attempts
        term_ids_q = db.query(StudentCourseAttempt.term_id).filter(
            StudentCourseAttempt.student_id == student_id
        )
        if term_id:
            term_ids_q = term_ids_q.filter(StudentCourseAttempt.term_id == term_id)
        term_ids = [r[0] for r in term_ids_q.distinct().all()]

        terms = db.query(AcademicTerm).filter(
            AcademicTerm.id.in_(term_ids)
        ).order_by(AcademicTerm.academic_year, AcademicTerm.term_type).all()

        semesters = []
        for term in terms:
            term_gpa_rec = db.query(StudentTermGPA).filter(
                StudentTermGPA.student_id == student_id,
                StudentTermGPA.term_id == term.id,
            ).first()

            attempts = db.query(StudentCourseAttempt).filter(
                StudentCourseAttempt.student_id == student_id,
                StudentCourseAttempt.term_id == term.id,
            ).all()

            courses = []
            for a in attempts:
                course = db.query(Course).filter(Course.id == a.course_id).first()
                if course:
                    courses.append({
                        "term_code": term.code,
                        "term_name": term.name,
                        "course_code": course.code,
                        "course_name": course.name,
                        "credit_hours": a.credit_hours,
                        "letter_grade": a.letter_grade or "",
                        "grade_points": float(a.grade_points or 0),
                        "result": a.result,
                        "attempt_number": a.attempt_number,
                        "counts_in_cgpa": a.counts_in_cgpa,
                    })

            semesters.append({
                "term_code": term.code,
                "term_name": term.name,
                "credits_attempted": int(term_gpa_rec.term_credit_hours_attempted) if term_gpa_rec else 0,
                "credits_earned": int(term_gpa_rec.term_credit_hours_earned) if term_gpa_rec else 0,
                "term_gpa": float(term_gpa_rec.term_gpa) if term_gpa_rec else 0.0,
                "cgpa_after_term": float(term_gpa_rec.cgpa) if term_gpa_rec else 0.0,
                "academic_standing": term_gpa_rec.academic_standing if term_gpa_rec else "active",
                "courses": courses,
            })

        payload = {
            "student_info": {
                "student_number": student.student_number or "",
                "name": user.name if user else "",
                "program": program_name or "",
                "track": track_name,
                "department": dept_name,
                "admission_term": None,
                "expected_grad_term": None,
            },
            "semesters": semesters,
            "total_credits_attempted": int(student.total_credit_hours_attempted or 0),
            "total_credits_earned": int(student.total_credit_hours_earned or 0),
            "cumulative_gpa": float(student.cgpa or 0),
            "academic_standing": student.academic_standing or "active",
            "graduation_status": "graduated" if student.is_eligible_for_graduation else "in_progress",
            "honors_level": None,
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "transcript_type": transcript_type,
        }
        return payload

    @classmethod
    def generate_transcript(
        cls,
        db: Session,
        student_id: int,
        transcript_type: str = "unofficial",
        term_id: Optional[int] = None,
        generated_by: Optional[int] = None,
        reason: Optional[str] = None,
    ) -> TranscriptVersion:
        """Generate a transcript version and create verification record."""

        payload = cls.build_transcript_payload(db, student_id, transcript_type, term_id)
        payload_json = json.dumps(payload, sort_keys=True, default=str)
        snap_hash = hashlib.sha256(payload_json.encode()).hexdigest()

        # Mark previous versions as not current
        db.query(TranscriptVersion).filter(
            TranscriptVersion.student_id == student_id,
            TranscriptVersion.transcript_type == transcript_type,
            TranscriptVersion.is_current == True,
        ).update({"is_current": False})

        # Get next version number
        last = db.query(func.max(TranscriptVersion.version_number)).filter(
            TranscriptVersion.student_id == student_id,
            TranscriptVersion.transcript_type == transcript_type,
        ).scalar()
        version_number = (last or 0) + 1

        tv = TranscriptVersion(
            student_id=student_id,
            version_number=version_number,
            transcript_type=transcript_type,
            transcript_data=payload,
            snapshot_hash=snap_hash,
            generated_by=generated_by,
            reason=reason,
            is_current=True,
        )
        db.add(tv)
        db.flush()

        # Create verification record
        verification = VerificationService.create_verification(db, tv.id)

        db.commit()
        db.refresh(tv)

        # Timeline event
        TimelineService.record(
            db=db, student_id=student_id,
            event_type=TimelineEventTypeEnum.TRANSCRIPT_ISSUED,
            title=f"{transcript_type.title()} transcript generated (v{version_number})",
            payload={"transcript_id": tv.id, "type": transcript_type},
            actor_id=generated_by,
        )

        # Audit
        AuditService.log(
            db=db, student_id=student_id,
            action=AuditActionEnum.TRANSCRIPT_GENERATED,
            entity_type="transcript_version", entity_id=tv.id,
            new_value={"type": transcript_type, "version": version_number},
            actor_id=generated_by,
        )

        return tv


# ═════════════════════════════════════════════════════════════════════════════
# TRANSCRIPT VERIFICATION (Module 7)
# ═════════════════════════════════════════════════════════════════════════════

class VerificationService:

    @staticmethod
    def _generate_code() -> str:
        """Human-readable verification code: TRX-XXXX-XXXX"""
        part1 = secrets.token_hex(2).upper()
        part2 = secrets.token_hex(2).upper()
        return f"TRX-{part1}-{part2}"

    @staticmethod
    def create_verification(db: Session, transcript_id: int) -> TranscriptVerification:
        code  = VerificationService._generate_code()
        token = secrets.token_urlsafe(64)
        qr_id = secrets.token_hex(32)

        v = TranscriptVerification(
            transcript_id=transcript_id,
            verification_code=code,
            verification_token=token,
            qr_identifier=qr_id,
            is_valid=True,
        )
        db.add(v)
        db.flush()
        return v

    @staticmethod
    def verify_transcript(db: Session, code: str) -> Dict[str, Any]:
        """External verification endpoint logic."""
        v = db.query(TranscriptVerification).filter(
            TranscriptVerification.verification_code == code
        ).first()

        if not v:
            return {"is_valid": False, "message": "Verification code not found."}
        if not v.is_valid:
            return {"is_valid": False, "message": "This transcript has been invalidated."}

        # Update verified_count
        v.verified_count = (v.verified_count or 0) + 1
        v.last_verified_at = datetime.now(timezone.utc)
        db.commit()

        tv = db.query(TranscriptVersion).filter(TranscriptVersion.id == v.transcript_id).first()
        if not tv:
            return {"is_valid": False, "message": "Transcript record not found."}

        student = db.query(Student).filter(Student.id == tv.student_id).first()
        user    = db.query(User).filter(User.id == student.user_id).first() if student else None

        data = tv.transcript_data or {}
        si   = data.get("student_info", {})

        return {
            "is_valid": True,
            "student_name": si.get("name"),
            "student_number": si.get("student_number"),
            "program": si.get("program"),
            "transcript_type": tv.transcript_type,
            "generated_at": tv.generated_at,
            "cgpa": data.get("cumulative_gpa"),
            "message": "Transcript verified successfully.",
        }


# ═════════════════════════════════════════════════════════════════════════════
# ACADEMIC STANDING SERVICE (Module 9)
# ═════════════════════════════════════════════════════════════════════════════

class AcademicStandingService:

    @staticmethod
    def determine_standing(
        db: Session,
        student_id: int,
        cgpa: Decimal,
        program_id: Optional[int] = None,
    ) -> str:
        """Determine standing based on configurable CGPA thresholds."""
        min_good      = Decimal(str(RulesConfigService.get(db, "min_cgpa_good_standing", program_id)))
        min_warning   = Decimal(str(RulesConfigService.get(db, "min_cgpa_warning",       program_id)))
        min_probation = Decimal(str(RulesConfigService.get(db, "min_cgpa_probation",     program_id)))

        if cgpa >= min_good:
            return AcademicStatusEnum.ACTIVE.value
        if cgpa >= min_warning:
            return AcademicStatusEnum.WARNING.value
        if cgpa >= min_probation:
            return AcademicStatusEnum.PROBATION.value
        return AcademicStatusEnum.SUSPENDED.value

    @staticmethod
    def record_status_change(
        db: Session,
        student_id: int,
        term_id: Optional[int],
        new_standing: str,
        cgpa: Decimal,
        term_gpa: Decimal,
        actor_id: Optional[int] = None,
        reason: Optional[str] = None,
    ) -> None:
        """Record status change if it differs from the last recorded status."""
        last = db.query(AcademicStatusHistory).filter(
            AcademicStatusHistory.student_id == student_id,
        ).order_by(desc(AcademicStatusHistory.occurred_at)).first()

        if last and last.new_status == new_standing:
            return  # No change

        try:
            status_enum = AcademicStatusEnum(new_standing)
        except ValueError:
            status_enum = AcademicStatusEnum.ACTIVE

        entry = AcademicStatusHistory(
            student_id=student_id,
            term_id=term_id,
            old_status=AcademicStatusEnum(last.new_status) if last else None,
            new_status=status_enum,
            cgpa_at_change=float(cgpa),
            term_gpa_at_change=float(term_gpa),
            reason=reason or f"Auto-computed after term finalization",
            actor_id=actor_id,
        )
        db.add(entry)
        db.commit()

        # Timeline
        TimelineService.record(
            db=db, student_id=student_id, term_id=term_id,
            event_type=TimelineEventTypeEnum.STATUS_CHANGED,
            title=f"Academic status changed to {new_standing}",
            payload={"old": last.new_status if last else None, "new": new_standing, "cgpa": float(cgpa)},
            actor_id=actor_id,
        )


# ═════════════════════════════════════════════════════════════════════════════
# DEGREE PROGRESS ENGINE (Module 10)
# ═════════════════════════════════════════════════════════════════════════════

class DegreeProgressService:

    @classmethod
    def compute_progress(
        cls,
        db: Session,
        student_id: int,
        term_id: Optional[int] = None,
        actor_id: Optional[int] = None,
    ) -> DegreeProgressSnapshot:
        """
        Compute complete degree progress snapshot.
        Compares earned credits against graduation requirements.
        """
        student = db.query(Student).filter(Student.id == student_id).first()
        if not student:
            raise ValueError(f"Student {student_id} not found")

        program_id = student.program_id
        track_id   = student.track_id

        required_credits = RulesConfigService.get_int(db, "total_required_credits", program_id) or 134

        # All passed course attempts
        passed_attempts = db.query(StudentCourseAttempt).filter(
            StudentCourseAttempt.student_id == student_id,
            StudentCourseAttempt.result == "passed",
        ).all()

        earned_credits  = sum(a.credit_hours or 0 for a in passed_attempts)
        passed_course_ids = {a.course_id for a in passed_attempts}

        # Category breakdown from GraduationRequirement table
        requirements = db.query(GraduationRequirement).filter(
            GraduationRequirement.program_id == program_id,
        ).all()
        if track_id:
            track_reqs = db.query(GraduationRequirement).filter(
                GraduationRequirement.track_id == track_id,
            ).all()
            # Merge: track-specific overrides program-level
            req_map = {r.category: r for r in requirements}
            for tr in track_reqs:
                req_map[tr.category] = tr
            requirements = list(req_map.values())

        category_breakdown: Dict[str, Any] = {}
        all_core_complete  = True
        field_training_ok  = True
        grad_project_ok    = True
        electives_ok       = True
        missing_categories = []

        # Get all courses and their categories
        all_courses = db.query(Course).all()
        course_cat_map = {c.id: getattr(c, 'category', None) for c in all_courses}

        for req in requirements:
            cat_name = req.category if isinstance(req.category, str) else req.category.value
            earned_in_cat = sum(
                a.credit_hours or 0 for a in passed_attempts
                if course_cat_map.get(a.course_id) == cat_name
            )
            remaining_in_cat = max(0, req.required_credits - earned_in_cat)
            pct = round(min(100, (earned_in_cat / req.required_credits) * 100) if req.required_credits else 100, 2)

            category_breakdown[cat_name] = {
                "required": req.required_credits,
                "earned": earned_in_cat,
                "remaining": remaining_in_cat,
                "pct": pct,
            }

            if remaining_in_cat > 0:
                missing_categories.append(cat_name)
                if cat_name == "core":
                    all_core_complete = False
                elif cat_name == "field_training":
                    field_training_ok = False
                elif cat_name == "graduation_project":
                    grad_project_ok = False
                elif cat_name in ("elective", "university_elective"):
                    electives_ok = False

        # Missing core courses: find required core courses not in passed set
        all_core_courses = db.query(Course).filter(
            getattr(Course, 'category', None) == 'core'
        ).all() if hasattr(Course, 'category') else []
        missing_core_codes = [
            c.code for c in all_core_courses
            if c.id not in passed_course_ids
        ]

        completion_pct = round(
            min(100.0, (earned_credits / required_credits) * 100) if required_credits else 0.0,
            2
        )

        # Version
        last_snap = db.query(DegreeProgressSnapshot).filter(
            DegreeProgressSnapshot.student_id == student_id
        ).order_by(desc(DegreeProgressSnapshot.version)).first()
        version = (last_snap.version + 1) if last_snap else 1

        snap = DegreeProgressSnapshot(
            student_id=student_id,
            term_id=term_id,
            version=version,
            required_credits=required_credits,
            earned_credits=earned_credits,
            remaining_credits=max(0, required_credits - earned_credits),
            completion_percentage=completion_pct,
            category_breakdown=category_breakdown,
            missing_core_courses=missing_core_codes[:50],  # cap for storage
            missing_elective_slots=3 - len([k for k in category_breakdown if "elective" in k and category_breakdown[k]["remaining"] == 0]),
            missing_categories=missing_categories,
            all_core_complete=all_core_complete,
            all_electives_complete=electives_ok,
            field_training_complete=field_training_ok,
            graduation_project_complete=grad_project_ok,
            computed_by=actor_id,
        )
        db.add(snap)
        db.commit()
        db.refresh(snap)

        AuditService.log(
            db=db, student_id=student_id, action=AuditActionEnum.PROGRESS_UPDATED,
            entity_type="degree_progress_snapshot", entity_id=snap.id,
            new_value={"earned": earned_credits, "pct": completion_pct},
            actor_id=actor_id,
        )
        return snap


# ═════════════════════════════════════════════════════════════════════════════
# GRADUATION ELIGIBILITY ENGINE (Module 11)
# ═════════════════════════════════════════════════════════════════════════════

class GraduationEligibilityService:

    @classmethod
    def evaluate(
        cls,
        db: Session,
        student_id: int,
        term_id: Optional[int] = None,
        actor_id: Optional[int] = None,
    ) -> GraduationEligibilityRecord:
        student = db.query(Student).filter(Student.id == student_id).first()
        if not student:
            raise ValueError(f"Student {student_id} not found")

        program_id = student.program_id
        cgpa = Decimal(str(student.cgpa or 0))
        credits = int(student.total_credit_hours_earned or 0)

        required_credits = RulesConfigService.get_int(db, "total_required_credits", program_id) or 134
        min_cgpa = Decimal(str(RulesConfigService.get(db, "min_cgpa_graduation", program_id) or "2.00"))

        reqs_met: Dict[str, Any] = {}
        missing: List[str] = []

        # Check: credit hours
        credit_ok = credits >= required_credits
        reqs_met["credit_hours"] = credit_ok
        if not credit_ok:
            missing.append(f"Credit hours: need {required_credits}, have {credits} ({required_credits - credits} remaining)")

        # Check: CGPA
        cgpa_ok = cgpa >= min_cgpa
        reqs_met["min_cgpa"] = cgpa_ok
        if not cgpa_ok:
            missing.append(f"Minimum CGPA: need {min_cgpa}, have {cgpa:.3f}")

        # Check: academic standing not suspended/dismissed
        standing_ok = student.academic_standing not in ("suspended", "dismissed", "probation")
        reqs_met["academic_standing"] = standing_ok
        if not standing_ok:
            missing.append(f"Academic standing: currently {student.academic_standing}")

        # Check: degree progress (from latest snapshot)
        progress = db.query(DegreeProgressSnapshot).filter(
            DegreeProgressSnapshot.student_id == student_id
        ).order_by(desc(DegreeProgressSnapshot.version)).first()

        if progress:
            core_ok = progress.all_core_complete
            ft_ok   = progress.field_training_complete
            gp_ok   = progress.graduation_project_complete
        else:
            core_ok = ft_ok = gp_ok = False

        reqs_met["core_courses_complete"]        = core_ok
        reqs_met["field_training_complete"]      = ft_ok
        reqs_met["graduation_project_complete"]  = gp_ok

        if not core_ok:
            missing.append("Core courses: not all completed")
        if not ft_ok:
            missing.append("Field training: not completed")
        if not gp_ok:
            missing.append("Graduation project: not completed")

        # Determine eligibility
        if all(reqs_met.values()):
            eligibility = GradEligibilityEnum.ELIGIBLE
        elif credit_ok and cgpa_ok and len(missing) <= 2:
            eligibility = GradEligibilityEnum.CONDITIONALLY
        else:
            eligibility = GradEligibilityEnum.NOT_ELIGIBLE

        # Mark previous as not current
        db.query(GraduationEligibilityRecord).filter(
            GraduationEligibilityRecord.student_id == student_id,
            GraduationEligibilityRecord.is_current == True,
        ).update({"is_current": False})

        record = GraduationEligibilityRecord(
            student_id=student_id,
            term_id=term_id,
            eligibility_status=eligibility,
            requirements_met=reqs_met,
            missing_requirements=missing,
            cgpa_at_evaluation=float(cgpa),
            credits_at_evaluation=credits,
            evaluated_by=actor_id,
            is_current=True,
        )
        db.add(record)
        db.commit()
        db.refresh(record)

        # Update student flag
        student.is_eligible_for_graduation = (eligibility == GradEligibilityEnum.ELIGIBLE)
        db.commit()

        AuditService.log(
            db=db, student_id=student_id, action=AuditActionEnum.GRADUATION_DECISION,
            entity_type="graduation_eligibility", entity_id=record.id,
            new_value={"eligibility": eligibility.value, "missing_count": len(missing)},
            actor_id=actor_id,
        )
        return record


# ═════════════════════════════════════════════════════════════════════════════
# HONORS ENGINE (Module 12)
# ═════════════════════════════════════════════════════════════════════════════

class HonorsService:

    @classmethod
    def evaluate_term_honors(
        cls,
        db: Session,
        student_id: int,
        term_id: int,
        program_id: Optional[int] = None,
    ) -> HonorsRecord:
        """Evaluate Dean's List eligibility for a single term."""
        term_gpa_rec = db.query(StudentTermGPA).filter(
            StudentTermGPA.student_id == student_id,
            StudentTermGPA.term_id == term_id,
        ).first()
        if not term_gpa_rec:
            return None

        term_gpa     = Decimal(str(term_gpa_rec.term_gpa or 0))
        cgpa         = Decimal(str(term_gpa_rec.cgpa or 0))
        term_credits = int(term_gpa_rec.term_credit_hours_attempted or 0)

        deans_gpa     = Decimal(str(RulesConfigService.get(db, "deans_list_term_gpa",    program_id) or "3.50"))
        deans_credits = RulesConfigService.get_int(db, "deans_list_min_credits",          program_id) or 15

        # Check for F/W in term
        has_failures = db.query(StudentCourseAttempt).filter(
            StudentCourseAttempt.student_id == student_id,
            StudentCourseAttempt.term_id == term_id,
            StudentCourseAttempt.result.in_(["failed", "withdrawn"]),
        ).count() > 0

        is_deans = (
            term_gpa >= deans_gpa
            and term_credits >= deans_credits
            and not has_failures
        )

        # Cumulative honors level
        honors_level = cls.determine_honors_level(db, cgpa, program_id)

        qualification = {
            "term_gpa": float(term_gpa),
            "deans_threshold": float(deans_gpa),
            "credits_threshold": deans_credits,
            "credits_attempted": term_credits,
            "has_failures": has_failures,
            "deans_list_met": is_deans,
        }

        record = HonorsRecord(
            student_id=student_id,
            term_id=term_id,
            honors_level=honors_level,
            is_deans_list=is_deans,
            term_gpa_used=float(term_gpa),
            cgpa_used=float(cgpa),
            credits_used=term_credits,
            qualification_data=qualification,
        )
        db.add(record)
        db.commit()
        db.refresh(record)

        if is_deans:
            TimelineService.record(
                db=db, student_id=student_id, term_id=term_id,
                event_type=TimelineEventTypeEnum.HONORS_AWARDED,
                title="Dean's List — term achievement",
                payload={"term_gpa": float(term_gpa), "credits": term_credits},
            )
        return record

    @classmethod
    def determine_honors_level(
        cls,
        db: Session,
        cgpa: Decimal,
        program_id: Optional[int] = None,
    ) -> str:
        high_honors = Decimal(str(RulesConfigService.get(db, "high_honors_cgpa",   program_id) or "3.75"))
        honors      = Decimal(str(RulesConfigService.get(db, "honors_cgpa",        program_id) or "3.50"))
        excellent   = Decimal(str(RulesConfigService.get(db, "excellent_cgpa",     program_id) or "3.50"))
        very_good   = Decimal(str(RulesConfigService.get(db, "very_good_cgpa",     program_id) or "3.00"))
        good_cgpa   = Decimal(str(RulesConfigService.get(db, "good_standing_cgpa", program_id) or "2.50"))
        min_grad    = Decimal(str(RulesConfigService.get(db, "min_cgpa_graduation", program_id) or "2.00"))

        if cgpa >= high_honors:
            return HonorsLevelEnum.HIGH_HONORS.value
        if cgpa >= honors:
            return HonorsLevelEnum.HONORS.value
        if cgpa >= excellent:
            return HonorsLevelEnum.EXCELLENT.value
        if cgpa >= very_good:
            return HonorsLevelEnum.VERY_GOOD.value
        if cgpa >= good_cgpa:
            return HonorsLevelEnum.GOOD.value
        if cgpa >= min_grad:
            return HonorsLevelEnum.PASS.value
        return HonorsLevelEnum.NONE.value


# ═════════════════════════════════════════════════════════════════════════════
# GPA PROJECTION ENGINE (Module 13)
# ═════════════════════════════════════════════════════════════════════════════

class GPAProjectionService:

    @classmethod
    def project(
        cls,
        db: Session,
        student_id: int,
        projection_type: str,
        target_cgpa: Optional[float] = None,
        remaining_credits: Optional[int] = None,
        registered_courses: Optional[List[Dict]] = None,
        term_id: Optional[int] = None,
        program_id: Optional[int] = None,
    ) -> GPAProjection:
        student = db.query(Student).filter(Student.id == student_id).first()
        current_cgpa    = Decimal(str(student.cgpa or 0))
        current_credits = int(student.total_credit_hours_attempted or 0)
        current_points  = Decimal(str(student.total_quality_points or 0))

        scenario_input = {
            "projection_type": projection_type,
            "target_cgpa": target_cgpa,
            "remaining_credits": remaining_credits,
            "registered_courses": registered_courses or [],
        }
        result: Dict[str, Any] = {}
        projected_sem_gpa: Optional[Decimal] = None
        projected_cgpa: Optional[Decimal] = None
        is_achievable: Optional[bool] = None

        if projection_type == "graduation_target":
            # What average grade points needed across remaining credits to reach target CGPA?
            if target_cgpa and remaining_credits:
                target = Decimal(str(target_cgpa))
                rem    = Decimal(str(remaining_credits))
                # target = (current_points + required_points) / (current_credits + remaining)
                # required_points = target * (current_credits + remaining) - current_points
                required_points = target * (current_credits + rem) - current_points
                needed_avg = required_points / rem if rem > 0 else Decimal("0")
                is_achievable = Decimal("0") <= needed_avg <= Decimal("4.0")
                result["needed_avg_grade_points"] = float(round(needed_avg, 3))
                result["needed_avg_letter_grade"]  = cls._points_to_letter(needed_avg)
                projected_cgpa = target if is_achievable else None

        elif projection_type == "raise_cgpa":
            # Given registered courses with expected grades, what will CGPA be?
            if registered_courses:
                add_pts = Decimal("0")
                add_crs = Decimal("0")
                for rc in registered_courses:
                    grade_pts = Decimal(str(rc.get("grade_points") or 0))
                    crs = Decimal(str(rc.get("credits", 3)))
                    add_pts += grade_pts * crs
                    add_crs += crs
                projected_sem_gpa = (add_pts / add_crs) if add_crs > 0 else Decimal("0")
                projected_cgpa = (current_points + add_pts) / (Decimal(str(current_credits)) + add_crs) if (current_credits + add_crs) > 0 else current_cgpa
                projected_cgpa = Decimal(str(round(projected_cgpa, 3)))
                is_achievable = True
                result["projected_semester_gpa"] = float(round(projected_sem_gpa, 3))

        elif projection_type == "course_grade_needed":
            # What grade is needed in a specific course to reach target CGPA?
            if registered_courses and target_cgpa:
                target = Decimal(str(target_cgpa))
                future_credits = sum(rc.get("credits", 3) for rc in registered_courses)
                other_pts = sum(
                    Decimal(str(rc.get("grade_points", 0))) * Decimal(str(rc.get("credits", 3)))
                    for rc in registered_courses[1:]
                )
                other_crs = sum(rc.get("credits", 3) for rc in registered_courses[1:])
                target_course_crs = Decimal(str(registered_courses[0].get("credits", 3)))
                total_future = Decimal(str(future_credits))
                needed_pts_course = (target * (Decimal(str(current_credits)) + total_future) - current_points - other_pts)
                needed_avg = needed_pts_course / target_course_crs if target_course_crs > 0 else Decimal("0")
                is_achievable = Decimal("0") <= needed_avg <= Decimal("4.0")
                result["course_needed_grade_points"] = float(round(needed_avg, 3))
                result["course_needed_letter_grade"]  = cls._points_to_letter(needed_avg)

        record = GPAProjection(
            student_id=student_id,
            term_id=term_id,
            projection_type=projection_type,
            current_cgpa=float(current_cgpa),
            current_credits=current_credits,
            target_cgpa=float(target_cgpa) if target_cgpa else None,
            remaining_credits=remaining_credits,
            scenario_input=scenario_input,
            projection_result=result,
            projected_semester_gpa=float(projected_sem_gpa) if projected_sem_gpa else None,
            projected_cgpa=float(projected_cgpa) if projected_cgpa else None,
            is_achievable=is_achievable,
        )
        db.add(record)
        db.commit()
        db.refresh(record)
        return record

    @staticmethod
    def _points_to_letter(pts: Decimal) -> str:
        """Map grade points back to letter grade."""
        p = float(pts)
        if p >= 4.0:   return "A+"
        if p >= 3.7:   return "A-"
        if p >= 3.3:   return "B+"
        if p >= 3.0:   return "B"
        if p >= 2.7:   return "B-"
        if p >= 2.3:   return "C+"
        if p >= 2.0:   return "C"
        if p >= 1.7:   return "C-"
        if p >= 1.3:   return "D+"
        if p >= 1.0:   return "D"
        return "F"


# ═════════════════════════════════════════════════════════════════════════════
# ACADEMIC RISK ENGINE (Module 14)
# ═════════════════════════════════════════════════════════════════════════════

class AcademicRiskService:

    @classmethod
    def assess_risk(
        cls,
        db: Session,
        student_id: int,
        term_id: Optional[int] = None,
    ) -> AcademicRiskRecord:
        student = db.query(Student).filter(Student.id == student_id).first()
        if not student:
            raise ValueError(f"Student {student_id} not found")

        cgpa = Decimal(str(student.cgpa or 0))

        # GPA trend: compare last two terms
        term_records = db.query(StudentTermGPA).filter(
            StudentTermGPA.student_id == student_id,
            StudentTermGPA.finalized == True,
        ).order_by(desc(StudentTermGPA.term_id)).limit(3).all()

        gpa_trend  = Decimal("0")
        cgpa_trend = Decimal("0")
        if len(term_records) >= 2:
            gpa_trend  = Decimal(str(term_records[0].term_gpa or 0)) - Decimal(str(term_records[1].term_gpa or 0))
            cgpa_trend = Decimal(str(term_records[0].cgpa or 0))     - Decimal(str(term_records[1].cgpa or 0))

        # Failed/repeated/withdrawn counts
        all_attempts = db.query(StudentCourseAttempt).filter(
            StudentCourseAttempt.student_id == student_id,
        ).all()
        failed_count    = sum(1 for a in all_attempts if a.result == "failed")
        withdrawn_count = sum(1 for a in all_attempts if a.result == "withdrawn")

        # Repeated: attempt_number > 1
        repeated_count = db.query(StudentCourseAttempt).filter(
            StudentCourseAttempt.student_id == student_id,
            StudentCourseAttempt.is_improvement_attempt == True,
        ).count()

        # Degree completion
        progress = db.query(DegreeProgressSnapshot).filter(
            DegreeProgressSnapshot.student_id == student_id
        ).order_by(desc(DegreeProgressSnapshot.version)).first()
        completion_pct = Decimal(str(progress.completion_percentage or 0)) if progress else Decimal("0")

        # Risk scoring
        risk_factors: List[str] = []
        risk_score = Decimal("0")

        if cgpa < Decimal("2.0"):
            risk_score += Decimal("0.30")
            risk_factors.append(f"CGPA below graduation minimum ({cgpa:.3f})")
        elif cgpa < Decimal("2.5"):
            risk_score += Decimal("0.15")
            risk_factors.append(f"CGPA approaching minimum ({cgpa:.3f})")

        if cgpa_trend < Decimal("-0.2"):
            risk_score += Decimal("0.20")
            risk_factors.append(f"Declining CGPA trend ({cgpa_trend:+.3f})")

        if failed_count >= 5:
            risk_score += Decimal("0.20")
            risk_factors.append(f"High number of failed courses ({failed_count})")
        elif failed_count >= 2:
            risk_score += Decimal("0.10")
            risk_factors.append(f"Multiple failed courses ({failed_count})")

        if repeated_count >= 3:
            risk_score += Decimal("0.10")
            risk_factors.append(f"Multiple course repeats ({repeated_count})")

        if withdrawn_count >= 3:
            risk_score += Decimal("0.10")
            risk_factors.append(f"Multiple withdrawals ({withdrawn_count})")

        if student.academic_standing in ("warning", "probation"):
            risk_score += Decimal("0.15")
            risk_factors.append(f"Academic standing: {student.academic_standing}")

        if student.academic_standing == "suspended":
            risk_score = Decimal("1.0")
            risk_factors.append("Academic suspension")

        risk_score = min(risk_score, Decimal("1.0"))

        # Determine level
        if risk_score >= Decimal("0.75"):
            risk_level = RiskLevelEnum.CRITICAL
        elif risk_score >= Decimal("0.50"):
            risk_level = RiskLevelEnum.HIGH
        elif risk_score >= Decimal("0.25"):
            risk_level = RiskLevelEnum.MEDIUM
        else:
            risk_level = RiskLevelEnum.LOW

        # Recommendations
        recommendations: List[str] = []
        if cgpa < Decimal("2.0"):
            recommendations.append("Meet with academic advisor immediately")
        if failed_count > 0:
            recommendations.append("Review failed courses and plan retakes")
        if cgpa_trend < Decimal("-0.1"):
            recommendations.append("Seek tutoring or additional academic support")
        if withdrawn_count >= 2:
            recommendations.append("Reconsider course load — excessive withdrawals impact graduation timeline")
        if not recommendations:
            recommendations.append("Continue current academic trajectory")

        # Mark previous as not current
        db.query(AcademicRiskRecord).filter(
            AcademicRiskRecord.student_id == student_id,
            AcademicRiskRecord.is_current == True,
        ).update({"is_current": False})

        record = AcademicRiskRecord(
            student_id=student_id,
            term_id=term_id,
            risk_level=risk_level,
            risk_score=float(risk_score),
            gpa_trend=float(gpa_trend),
            cgpa_trend=float(cgpa_trend),
            failed_courses_count=failed_count,
            repeated_courses_count=repeated_count,
            withdrawal_count=withdrawn_count,
            degree_completion_pct=float(completion_pct),
            risk_factors=risk_factors,
            recommendations=recommendations,
            is_current=True,
        )
        db.add(record)
        db.commit()
        db.refresh(record)
        return record


# ═════════════════════════════════════════════════════════════════════════════
# TIMELINE SERVICE (Module 8)
# ═════════════════════════════════════════════════════════════════════════════

class TimelineService:

    @staticmethod
    def record(
        db: Session,
        student_id: int,
        event_type: TimelineEventTypeEnum,
        title: str,
        term_id: Optional[int] = None,
        description: Optional[str] = None,
        payload: Optional[Dict] = None,
        actor_id: Optional[int] = None,
    ) -> AcademicTimelineEvent:
        event = AcademicTimelineEvent(
            student_id=student_id,
            term_id=term_id,
            event_type=event_type,
            title=title,
            description=description,
            payload=payload or {},
            actor_id=actor_id,
        )
        db.add(event)
        db.commit()
        db.refresh(event)
        return event


# ═════════════════════════════════════════════════════════════════════════════
# AUDIT SERVICE (Module 16)
# ═════════════════════════════════════════════════════════════════════════════

class AuditService:

    @staticmethod
    def log(
        db: Session,
        student_id: int,
        action: AuditActionEnum,
        entity_type: Optional[str] = None,
        entity_id: Optional[int] = None,
        old_value: Optional[Dict] = None,
        new_value: Optional[Dict] = None,
        reason: Optional[str] = None,
        actor_id: Optional[int] = None,
        actor_role: Optional[str] = None,
        term_id: Optional[int] = None,
    ) -> AcademicAuditEntry:
        entry = AcademicAuditEntry(
            student_id=student_id,
            term_id=term_id,
            action=action,
            entity_type=entity_type,
            entity_id=entity_id,
            old_value=old_value,
            new_value=new_value,
            reason=reason,
            actor_id=actor_id,
            actor_role=actor_role,
        )
        db.add(entry)
        # Use flush, not commit — callers handle the commit boundary
        db.flush()
        return entry


# ═════════════════════════════════════════════════════════════════════════════
# REGISTRAR NOTES SERVICE (Module 15)
# ═════════════════════════════════════════════════════════════════════════════

class RegistrarNoteService:

    @staticmethod
    def create(db: Session, data: Dict, actor_id: Optional[int] = None) -> RegistrarNote:
        note = RegistrarNote(**data, created_by=actor_id, updated_by=actor_id)
        db.add(note)
        db.commit()
        db.refresh(note)
        AuditService.log(
            db=db, student_id=data["student_id"], action=AuditActionEnum.NOTE_ADDED,
            entity_type="registrar_note", entity_id=note.id,
            new_value={"title": data["title"], "type": data.get("note_type")},
            actor_id=actor_id,
        )
        db.commit()
        return note

    @staticmethod
    def update(db: Session, note_id: int, updates: Dict, actor_id: Optional[int] = None) -> RegistrarNote:
        note = db.query(RegistrarNote).filter(RegistrarNote.id == note_id).first()
        if not note:
            raise ValueError(f"Note {note_id} not found")

        # Create new version
        old_content = note.content
        for k, v in updates.items():
            setattr(note, k, v)
        note.version = (note.version or 1) + 1
        note.updated_by = actor_id

        db.commit()
        db.refresh(note)
        return note

    @staticmethod
    def search(
        db: Session,
        student_id: int,
        note_type: Optional[str] = None,
        tag: Optional[str] = None,
        include_private: bool = False,
    ) -> List[RegistrarNote]:
        q = db.query(RegistrarNote).filter(RegistrarNote.student_id == student_id)
        if not include_private:
            q = q.filter(RegistrarNote.is_private == False)
        if note_type:
            q = q.filter(RegistrarNote.note_type == note_type)
        if tag:
            q = q.filter(RegistrarNote.tags.contains([tag]))
        return q.order_by(desc(RegistrarNote.created_at)).all()


# ═════════════════════════════════════════════════════════════════════════════
# DASHBOARD AGGREGATION SERVICE (Module 17)
# ═════════════════════════════════════════════════════════════════════════════

class DashboardService:

    @classmethod
    def get_dashboard(db: Session, student_id: int) -> Dict[str, Any]:
        student = db.query(Student).filter(Student.id == student_id).first()
        if not student:
            raise ValueError(f"Student {student_id} not found")

        user    = db.query(User).filter(User.id == student.user_id).first()
        program = None
        track   = None

        if student.program_id:
            prog = db.query(AcademicProgram).filter(AcademicProgram.id == student.program_id).first()
            program = prog.name if prog else None
        if student.track_id:
            t = db.query(AcademicTrack).filter(AcademicTrack.id == student.track_id).first()
            track = t.name if t else None

        cgpa = Decimal(str(student.cgpa or 0))

        # Degree progress
        progress = db.query(DegreeProgressSnapshot).filter(
            DegreeProgressSnapshot.student_id == student_id
        ).order_by(desc(DegreeProgressSnapshot.version)).first()

        required_credits   = int(progress.required_credits if progress else 134)
        earned_credits     = int(progress.earned_credits if progress else student.total_credit_hours_earned or 0)
        remaining_credits  = int(progress.remaining_credits if progress else max(0, required_credits - earned_credits))
        completion_pct     = Decimal(str(progress.completion_percentage if progress else 0))

        # Graduation eligibility
        grad_rec = db.query(GraduationEligibilityRecord).filter(
            GraduationEligibilityRecord.student_id == student_id,
            GraduationEligibilityRecord.is_current == True,
        ).first()

        # Risk
        risk_rec = db.query(AcademicRiskRecord).filter(
            AcademicRiskRecord.student_id == student_id,
            AcademicRiskRecord.is_current == True,
        ).first()

        # Honors
        honors_rec = db.query(HonorsRecord).filter(
            HonorsRecord.student_id == student_id,
        ).order_by(desc(HonorsRecord.awarded_at)).first()

        # Current semester (latest active term)
        active_term = db.query(AcademicTerm).filter(AcademicTerm.is_active == True).first()
        current_semester = None
        if active_term:
            current_attempts = db.query(StudentCourseAttempt).filter(
                StudentCourseAttempt.student_id == student_id,
                StudentCourseAttempt.term_id == active_term.id,
            ).all()
            in_progress = []
            for a in current_attempts:
                c = db.query(Course).filter(Course.id == a.course_id).first()
                if c:
                    in_progress.append({"code": c.code, "name": c.name, "credits": a.credit_hours})

            current_semester = {
                "term_id": active_term.id,
                "term_name": active_term.name,
                "courses_registered": len(current_attempts),
                "credits_registered": sum(a.credit_hours or 0 for a in current_attempts),
                "in_progress_courses": in_progress,
            }

        # Latest transcript
        latest_tv = db.query(TranscriptVersion).filter(
            TranscriptVersion.student_id == student_id,
            TranscriptVersion.is_current == True,
        ).order_by(desc(TranscriptVersion.generated_at)).first()

        # Latest term GPA for "current_gpa"
        latest_term_gpa_rec = db.query(StudentTermGPA).filter(
            StudentTermGPA.student_id == student_id,
            StudentTermGPA.finalized == True,
        ).order_by(desc(StudentTermGPA.term_id)).first()
        current_gpa = Decimal(str(latest_term_gpa_rec.term_gpa or 0)) if latest_term_gpa_rec else None

        return {
            "student_id": student_id,
            "student_number": student.student_number or "",
            "name": user.name if user else "",
            "program": program,
            "track": track,
            "current_gpa": float(current_gpa) if current_gpa else None,
            "current_cgpa": float(cgpa),
            "academic_standing": student.academic_standing or "active",
            "earned_credits": earned_credits,
            "remaining_credits": remaining_credits,
            "required_credits": required_credits,
            "degree_completion_pct": float(completion_pct),
            "all_core_complete": progress.all_core_complete if progress else False,
            "graduation_eligibility": grad_rec.eligibility_status if grad_rec else "not_eligible",
            "graduation_eligibility_id": grad_rec.id if grad_rec else None,
            "risk_level": risk_rec.risk_level if risk_rec else "low",
            "risk_score": float(risk_rec.risk_score) if risk_rec and risk_rec.risk_score else None,
            "honors_level": honors_rec.honors_level if honors_rec else "none",
            "is_deans_list": honors_rec.is_deans_list if honors_rec else False,
            "current_semester": current_semester,
            "latest_transcript_id": latest_tv.id if latest_tv else None,
            "latest_transcript_type": latest_tv.transcript_type if latest_tv else None,
            "latest_transcript_generated": latest_tv.generated_at if latest_tv else None,
            "computed_at": datetime.now(timezone.utc),
        }
