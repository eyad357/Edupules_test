"""
EduGuard AI — Sprint 5: Seed Data Generator
============================================
Generates 500 realistic students with Arabic names (transliterated),
full academic histories, risk scenarios, and graduation candidates.

Each batch is tracked via seed_batch_id.
Provides DELETE /seed-data/batch/{id} for safe cleanup.
"""

from __future__ import annotations

import logging
import random
import uuid
from datetime import datetime, date, timedelta, timezone
from decimal import Decimal
from typing import Any, Dict, List, Optional, Tuple

from sqlalchemy.orm import Session
from sqlalchemy import func

logger = logging.getLogger(__name__)

# ── Arabic Names (transliterated to English) ──────────────────────────────────

MALE_FIRST = [
    "Ahmed", "Mohamed", "Omar", "Ali", "Hassan", "Hussein", "Ibrahim",
    "Khaled", "Mahmoud", "Mustafa", "Youssef", "Karim", "Tarek", "Samir",
    "Amr", "Bilal", "Waleed", "Ziad", "Nader", "Sherif", "Essam", "Wael",
    "Hany", "Maged", "Ramadan", "Adel", "Fathy", "Gamal", "Hamdi", "Ismail",
    "Jabir", "Kareem", "Lotfi", "Marwan", "Nabil", "Osama", "Qassem",
    "Raed", "Samer", "Tamer", "Usama", "Vahid", "Wissam", "Yahya", "Zakariya",
    "Abdallah", "Abdelrahman", "Abdelaziz", "Abdelhamid", "Abdelnasser",
    "Abdelfattah", "Abdelwahab", "Abdelhakim", "Abdelkader", "Abdelmonem",
]

FEMALE_FIRST = [
    "Fatima", "Nour", "Sara", "Layla", "Hana", "Rania", "Dina", "Mona",
    "Nada", "Rana", "Heba", "Yasmin", "Amira", "Salma", "Mariam", "Asmaa",
    "Doaa", "Eman", "Ghada", "Hoda", "Iman", "Jana", "Kholoud", "Lubna",
    "Maha", "Nawal", "Ola", "Reem", "Shimaa", "Tahani", "Umayma", "Viviane",
    "Wafaa", "Yara", "Zainab", "Abeer", "Bothaina", "Cherifa", "Dalia",
    "Esraa", "Farida", "Howaida", "Ingy", "Karima", "Manar", "Nisreen",
]

LAST_NAMES = [
    "Ahmed", "Mohamed", "Hassan", "Ali", "Ibrahim", "Mahmoud", "Hussein",
    "Khalil", "Mostafa", "Abdallah", "Salem", "Farouk", "Sayed", "Gomaa",
    "Attia", "Badawi", "Darwish", "Elshemy", "Fouad", "Ghoneim", "Hamza",
    "Ismail", "Kamel", "Lotfy", "Mansour", "Nasser", "Osman", "Ragab",
    "Soliman", "Tawfik", "Wahba", "Youssef", "Zaki", "Badr", "Diab",
    "Eid", "Fayed", "Habib", "Kasem", "Labib", "Mahgoub", "Othman",
    "Radwan", "Sabry", "Talaat", "Uraby", "Zakaria", "Elnaggar", "Elmasry",
    "Elshafei", "Elgohary", "Elbehery", "Elreedy", "Elboushi", "Elabdy",
]

# NMU 15-grade scale (from uploaded CGPA calculator + Sprint 4 grade scale)
GRADE_SCALE = [
    ("A+",  4.0, 97, 100, True),
    ("A",   4.0, 93,  96, True),
    ("A-",  3.7, 90,  92, True),
    ("B+",  3.3, 87,  89, True),
    ("B",   3.0, 83,  86, True),
    ("B-",  2.7, 80,  82, True),
    ("C+",  2.3, 77,  79, True),
    ("C",   2.0, 73,  76, True),
    ("C-",  1.7, 70,  72, True),
    ("D+",  1.3, 67,  69, True),
    ("D",   1.0, 60,  66, True),
    ("F",   0.0,  0,  59, False),
    ("FL",  0.0,  0,   0, False),  # Failure for absence
    ("W",   0.0,  0,   0, False),  # Withdrawn
    ("P",   0.0,  0,   0, True),   # Pass (non-credit courses)
]

# CS courses from uploaded curriculum
CS_CORE_COURSES = [
    ("CSE014", "Structured Programming", 3),
    ("CSE015", "Object Oriented Programming", 3),
    ("CSE111", "Data Structures", 3),
    ("CSE112", "Design & Analysis of Algorithms", 3),
    ("CSE113", "Electric & Electronic Circuits", 3),
    ("CSE131", "Logic Design", 3),
    ("CSE132", "Computer Architecture & Organization", 3),
    ("CSE191", "Field Training 1 In Computer Science", 2),
    ("CSE211", "Web Programming", 3),
    ("CSE212", "Theory of Computation & Compilers", 3),
    ("CSE221", "Database Systems", 3),
    ("CSE233", "Operating Systems", 3),
    ("CSE241", "Security of Information Systems", 3),
    ("CSE251", "Software Engineering", 3),
    ("CSE261", "Computer Networks", 3),
    ("CSE292", "Field Training 2 In Computer Science", 2),
    ("CSE312", "Advanced Web Programming", 3),
    ("CSE313", "Mobile Development", 3),
    ("CSE315", "Discrete Mathematics", 3),
    ("CSE323", "Advanced Database Systems", 3),
    ("CSE352", "Systems Analysis & Design", 3),
    ("CSE363", "Cloud Computing", 3),
    ("CSE454", "Advanced Software Engineering", 3),
    ("CSE475", "Distributed Information Systems", 3),
    ("CSE493", "Graduation Project 1", 2),
    ("CSE494", "Graduation Project 2", 2),
    ("AIE111", "Artificial Intelligence", 3),
    ("AIE121", "Machine Learning", 3),
    ("AIE323", "Data Mining", 3),
    ("MAT112", "Mathematics II", 3),
    ("MAT114", "Analytical Geometry & Calculus I", 4),
    ("MAT131", "Statistics", 2),
    ("MAT212", "Linear Algebra", 3),
    ("MAT231", "Probability & Statistics", 3),
    ("MAT313", "Differential Equations & Numerical Analysis", 4),
    ("PHY211", "Physics II", 3),
]

CS_ELECTIVES = [
    ("CSE271", "Introduction to Parallel Computing", 3),
    ("CSE272", "Embedded Systems", 3),
    ("CSE281", "Image Processing", 3),
    ("CSE322", "Big Data Analytics 1", 3),
    ("CSE344", "Introduction to Cyber Security", 3),
    ("CSE424", "Data Warehousing", 3),
    ("CSE453", "Software Testing", 3),
    ("CSE455", "Selected Topics in Software Engineering", 3),
    ("AIE231", "Neural Networks", 3),
    ("AIE241", "Natural Language Processing", 3),
    ("AIE314", "Ai-Based Programming", 3),
    ("AIE322", "Advanced Machine Learning", 3),
    ("AIE332", "Deep Learning", 3),
]

UC_COURSES = [
    ("UC1", "University Requirement (1)", 2),
    ("UC2", "University Requirement (2)", 2),
    ("UC3", "University Requirement (3)", 2),
    ("UC4", "University Requirement (4)", 2),
    ("UC5", "University Requirement (5)", 2),
    ("UC6", "University Requirement (6)", 2),
    ("UC7", "University Requirement (7)", 2),
    ("UE1", "Elective University (1)", 2),
    ("UE2", "Elective University Requirement (2)", 2),
    ("UE3", "Elective University (3)", 2),
]

# Semester schedule (8 semesters across 4 years, by curriculum)
SEMESTER_COURSES = {
    1: ["CSE014", "PHY211", "MAT114", "UC1", "UE1", "UC2"],
    2: ["CSE015", "CSE113", "MAT131", "MAT112", "UC3", "UE2"],
    3: ["CSE111", "CSE131", "CSE191", "MAT313", "MAT231", "MAT212"],
    4: ["CSE112", "CSE132", "CSE221", "CSE251", "CSE315", "UC4"],
    5: ["CSE211", "CSE233", "CSE241", "CSE261", "AIE111", "UC5"],
    6: ["CSE212", "CSE292", "CSE323", "CSE352", "AIE121", "UC6", "UE3"],
    7: ["CSE454", "CSE475", "CSE493", "CSE313", "UC7"],
    8: ["CSE363", "CSE494", "AIE323", "CSE312"],
}


def _pick_grade(scenario: str, semester: int) -> Tuple[str, float, float, bool]:
    """Return (letter, points, numeric, passing) based on scenario."""
    if scenario == "excellent":
        weights = [("A+", 4.0, 98), ("A", 4.0, 94), ("A-", 3.7, 91), ("B+", 3.3, 88)]
        letter, pts, num = random.choice(weights)
    elif scenario == "good":
        weights = [("A-", 3.7, 91), ("B+", 3.3, 88), ("B", 3.0, 84), ("B-", 2.7, 81)]
        letter, pts, num = random.choice(weights)
    elif scenario == "average":
        weights = [("B-", 2.7, 81), ("C+", 2.3, 78), ("C", 2.0, 74), ("C-", 1.7, 71)]
        letter, pts, num = random.choice(weights)
    elif scenario == "at_risk":
        weights = [("C-", 1.7, 71), ("D+", 1.3, 68), ("D", 1.0, 63), ("F", 0.0, 45)]
        letter, pts, num = random.choice(weights)
    elif scenario == "dismissal_risk":
        # Mostly fails and low grades
        if random.random() < 0.45:
            letter, pts, num = "F", 0.0, random.randint(30, 59)
        elif random.random() < 0.3:
            letter, pts, num = "D", 1.0, random.randint(60, 66)
        else:
            letter, pts, num = "D+", 1.3, random.randint(67, 69)
    elif scenario == "near_graduate":
        weights = [("B+", 3.3, 88), ("B", 3.0, 84), ("B-", 2.7, 81), ("C+", 2.3, 78)]
        letter, pts, num = random.choice(weights)
    else:
        letter, pts, num = "C", 2.0, 73

    is_pass = letter not in ("F", "FL", "W")
    # Degradation in hard semesters
    if semester >= 5 and scenario == "at_risk" and random.random() < 0.3:
        letter, pts, num = "F", 0.0, random.randint(30, 59)
        is_pass = False

    return letter, pts, float(num), is_pass


class SeedDataGenerator:
    """
    Generates batches of realistic student data.
    Each batch is tracked with a seed_batch_id.
    """

    @staticmethod
    def generate_batch(
        db: Session,
        count: int = 500,
        label: Optional[str] = None,
        created_by: Optional[int] = None,
    ) -> Any:
        from app.models.sprint5_models import SeedBatch, SeedBatchMember
        from app.models.models import Student, User
        from app.models.academic_models import (
            AcademicProgram, AcademicTrack, AcademicTerm, StudentCourseAttempt, StudentTermGPA
        )

        batch_key = f"s5_batch_{uuid.uuid4().hex[:12]}"
        batch = SeedBatch(
            batch_key=batch_key,
            label=label or f"Sprint 5 Seed Batch — {count} Students",
            description=f"Auto-generated {count} realistic CS students with Arabic names",
            student_count=0,
            status="in_progress",
            created_by=created_by,
        )
        db.add(batch)
        db.commit()
        db.refresh(batch)

        # Get or create reference data
        program = db.query(AcademicProgram).filter(
            AcademicProgram.code == "CS"
        ).first()
        if not program:
            program = db.query(AcademicProgram).first()

        track = db.query(AcademicTrack).first()

        # Get existing terms
        terms = db.query(AcademicTerm).order_by(AcademicTerm.id).limit(16).all()
        if len(terms) < 8:
            logger.warning("Not enough academic terms for seed data; seeding limited history")

        count = min(count, 500)
        members = []
        created_students = 0

        # Scenario distribution (approximate real university distribution)
        scenarios = (
            ["excellent"]       * int(count * 0.10) +
            ["good"]            * int(count * 0.25) +
            ["average"]         * int(count * 0.30) +
            ["at_risk"]         * int(count * 0.20) +
            ["dismissal_risk"]  * int(count * 0.08) +
            ["near_graduate"]   * int(count * 0.07)
        )
        random.shuffle(scenarios)
        while len(scenarios) < count:
            scenarios.append("average")

        all_first_names = MALE_FIRST + FEMALE_FIRST

        for i in range(count):
            scenario = scenarios[i]

            # Generate name
            first = random.choice(all_first_names)
            last  = random.choice(LAST_NAMES)
            full_name = f"{first} {last}"

            # Enrollment year: 2018–2022
            enroll_year = random.randint(2018, 2022)
            enroll_sem  = random.choice([1, 2])
            student_code = f"CS{enroll_year}{str(i+1).zfill(4)}"

            # Create User
            email = f"{first.lower()}.{last.lower()}{i}@university.edu"
            user = User(
                name=full_name,
                email=email,
                role="student",
                is_active=True,
                password_hash="$2b$12$seededhashplaceholderxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
            )
            db.add(user)
            db.flush()

            # Create Student
            student = Student(
                name=full_name,
                student_id=student_code,
                email=email,
                user_id=user.id,
                program_id=program.id if program else None,
                track_id=track.id if track else None,
                is_active=True,
                enrollment_year=enroll_year,
            )
            db.add(student)
            db.flush()

            members.append(SeedBatchMember(batch_id=batch.id, entity_type="user",    entity_id=user.id))
            members.append(SeedBatchMember(batch_id=batch.id, entity_type="student", entity_id=student.id))

            # Determine how many semesters to simulate
            if scenario == "near_graduate":
                sem_count = random.randint(7, 8)
            elif scenario == "dismissal_risk":
                sem_count = random.randint(6, 8)
            elif scenario == "at_risk":
                sem_count = random.randint(4, 7)
            else:
                sem_count = random.randint(2, 8)

            # For near_graduate students: start earlier
            actual_sem_count = min(sem_count, len(terms))

            cum_q_pts = 0.0
            cum_hrs_att = 0
            cum_hrs_earned = 0
            cgpa = 0.0

            for sem_idx in range(actual_sem_count):
                if sem_idx >= len(terms):
                    break

                term = terms[sem_idx]
                curriculum_sem = sem_idx + 1
                is_summer = getattr(term, "is_summer", False)

                # Get course list for this semester
                sem_course_codes = SEMESTER_COURSES.get(curriculum_sem, [])
                if not sem_course_codes:
                    sem_course_codes = [f"CSE{100+curriculum_sem}", f"MAT{100+curriculum_sem}"]

                term_q_pts   = 0.0
                term_hrs_att = 0
                term_hrs_earned = 0

                for course_code in sem_course_codes[:5]:  # max 5 courses per sem
                    # Find course in DB
                    from app.models.models import Course
                    course = db.query(Course).filter(Course.code == course_code).first()
                    if not course:
                        continue

                    credit_hrs = getattr(course, "credit_hours", 3) or 3
                    letter, pts, numeric, is_pass = _pick_grade(scenario, curriculum_sem)

                    # Handle repeats for at-risk/dismissal scenarios
                    attempt_number = 1
                    result_str = "passed" if is_pass else "failed"
                    counts_in_cgpa = True

                    # If failed in previous semester, check for repeat
                    if letter == "F" and scenario in ("at_risk", "dismissal_risk") and random.random() < 0.3:
                        # Add a second attempt (improvement)
                        attempt_number = 2
                        # Might still fail on repeat
                        if random.random() < 0.5:
                            letter2, pts2, numeric2, is_pass2 = _pick_grade("at_risk", curriculum_sem)
                            if pts2 > pts:
                                pts, numeric, is_pass = pts2, numeric2, is_pass2
                                letter = letter2

                    # Grade points contribution (highest attempt rule — already implemented)
                    if letter not in ("F", "FL", "W", "P"):
                        term_q_pts  += pts * credit_hrs
                        term_hrs_att += credit_hrs
                        cum_hrs_att  += credit_hrs
                        if is_pass:
                            term_hrs_earned += credit_hrs
                            cum_hrs_earned  += credit_hrs
                    else:
                        term_hrs_att += credit_hrs
                        cum_hrs_att  += credit_hrs

                    attempt = StudentCourseAttempt(
                        student_id=student.id,
                        course_id=course.id,
                        term_id=term.id,
                        attempt_number=attempt_number,
                        numeric_grade=numeric if letter not in ("P", "W", "FL") else None,
                        letter_grade=letter,
                        grade_points=pts,
                        credit_hours=credit_hrs,
                        result=result_str,
                        counts_in_cgpa=(letter not in ("P", "W")),
                        grade_posted_at=datetime.now(timezone.utc),
                    )
                    db.add(attempt)
                    members.append(SeedBatchMember(
                        batch_id=batch.id, entity_type="attempt", entity_id=0  # will update after flush
                    ))

                # Compute term GPA
                term_gpa_val = (term_q_pts / term_hrs_att) if term_hrs_att > 0 else 0.0
                cum_q_pts   += term_q_pts
                cgpa         = (cum_q_pts / cum_hrs_att) if cum_hrs_att > 0 else 0.0

                # Academic standing
                if cgpa >= 3.50:
                    standing = "honors"
                elif cgpa >= 2.50:
                    standing = "good"
                elif cgpa >= 2.00:
                    standing = "warning"
                elif cgpa >= 1.40:
                    standing = "probation"
                else:
                    standing = "dismissed"

                term_gpa_record = StudentTermGPA(
                    student_id=student.id,
                    term_id=term.id,
                    term_credit_hours_attempted=term_hrs_att,
                    term_credit_hours_earned=term_hrs_earned,
                    term_quality_points=round(term_q_pts, 3),
                    term_gpa=round(term_gpa_val, 3),
                    cumulative_hours_attempted=cum_hrs_att,
                    cumulative_hours_earned=cum_hrs_earned,
                    cumulative_quality_points=round(cum_q_pts, 3),
                    cgpa=round(cgpa, 3),
                    academic_standing=standing,
                    is_summer=is_summer,
                    finalized=True,
                    finalized_at=datetime.now(timezone.utc),
                )
                db.add(term_gpa_record)
                members.append(SeedBatchMember(
                    batch_id=batch.id, entity_type="term_gpa", entity_id=0
                ))

            created_students += 1

            # Batch commit every 50 students
            if i % 50 == 49:
                db.flush()
                logger.info(f"Seed progress: {i+1}/{count} students processed")

        # Finalize batch
        batch.student_count = created_students
        batch.status = "completed"
        db.bulk_save_objects(members)
        db.commit()

        logger.info(f"Seed batch {batch_key} complete: {created_students} students")
        return batch

    @staticmethod
    def delete_batch(db: Session, batch_id: int) -> Dict[str, Any]:
        """
        Delete all students/users/attempts/term_gpas generated in a batch.
        Safe cleanup before importing real university data.
        """
        from app.models.sprint5_models import SeedBatch, SeedBatchMember
        from app.models.models import Student, User
        from app.models.academic_models import StudentTermGPA, StudentCourseAttempt

        batch = db.query(SeedBatch).filter(SeedBatch.id == batch_id).first()
        if not batch:
            return {"error": "Batch not found"}

        members = db.query(SeedBatchMember).filter(
            SeedBatchMember.batch_id == batch_id
        ).all()

        student_ids = [m.entity_id for m in members if m.entity_type == "student"]
        user_ids    = [m.entity_id for m in members if m.entity_type == "user"]

        deleted = {"attempts": 0, "term_gpas": 0, "students": 0, "users": 0}

        if student_ids:
            # Cascade deletes attempts and term GPAs via FK
            r = db.query(StudentCourseAttempt).filter(
                StudentCourseAttempt.student_id.in_(student_ids)
            ).delete(synchronize_session=False)
            deleted["attempts"] = r

            r = db.query(StudentTermGPA).filter(
                StudentTermGPA.student_id.in_(student_ids)
            ).delete(synchronize_session=False)
            deleted["term_gpas"] = r

            r = db.query(Student).filter(Student.id.in_(student_ids)).delete(synchronize_session=False)
            deleted["students"] = r

        if user_ids:
            r = db.query(User).filter(User.id.in_(user_ids)).delete(synchronize_session=False)
            deleted["users"] = r

        # Remove batch members and batch record
        db.query(SeedBatchMember).filter(SeedBatchMember.batch_id == batch_id).delete(synchronize_session=False)

        from datetime import timezone
        batch.status = "deleted"
        batch.deleted_at = datetime.now(timezone.utc)
        db.commit()

        return {
            "batch_key": batch.batch_key,
            "deleted": deleted,
            "message": f"Batch '{batch.batch_key}' successfully deleted.",
        }

    @staticmethod
    def list_batches(db: Session) -> List[Any]:
        from app.models.sprint5_models import SeedBatch
        return db.query(SeedBatch).filter(
            SeedBatch.status != "deleted"
        ).order_by(SeedBatch.created_at.desc()).all()

    @staticmethod
    def get_batch(db: Session, batch_id: int) -> Optional[Any]:
        from app.models.sprint5_models import SeedBatch
        return db.query(SeedBatch).filter(SeedBatch.id == batch_id).first()
