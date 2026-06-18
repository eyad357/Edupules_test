"""Students API"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import List, Optional

from app.db.database import get_db
from app.models.models import Student, User, RiskAssessment, Attendance
from app.api.auth import get_current_user

router = APIRouter()

class StudentCreate(BaseModel):
    student_number: str
    major: str
    year: int
    gpa: float = 0.0

class StudentResponse(BaseModel):
    id: int
    student_number: str
    name: str
    email: str
    major: str
    year: int
    gpa: float

    class Config:
        from_attributes = True

@router.get("/stats/overview")
def students_stats_overview(db: Session = Depends(get_db)):
    """
    KPI summary for the students dashboard (StudentsAPI.stats()).
    Registered ahead of /{student_id} so "stats" is never captured as a
    student_id path parameter.
    """
    total = db.query(Student).count()
    at_risk = db.query(RiskAssessment).filter(
        RiskAssessment.risk_level.in_(["High", "Critical"])
    ).count()
    critical = db.query(RiskAssessment).filter(
        RiskAssessment.risk_level == "Critical"
    ).count()
    avg_gpa = db.query(func.avg(Student.gpa)).scalar() or 0

    total_attendance  = db.query(func.count(Attendance.id)).scalar() or 0
    present_attendance = db.query(func.count(Attendance.id)).filter(
        Attendance.status.in_(["present", "late"])
    ).scalar() or 0
    attendance_rate = round((present_attendance / total_attendance) * 100, 1) if total_attendance else 0

    return {
        "total_students":     total,
        "at_risk_count":      at_risk,
        "critical_count":     critical,
        "avg_gpa":            round(float(avg_gpa), 2),
        "attendance_rate":    attendance_rate,
        "intervention_count": 4,
    }

@router.get("/", response_model=List[StudentResponse])
def list_students(
    skip: int = 0, 
    limit: int = 100, 
    search: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = db.query(Student).join(User)
    if search:
        query = query.filter(User.name.ilike(f"%{search}%"))
    return query.offset(skip).limit(limit).all()

@router.get("/{student_id}", response_model=StudentResponse)
def get_student(student_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    student = db.query(Student).filter(Student.id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    return student

@router.post("/", response_model=StudentResponse)
def create_student(student: StudentCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    db_student = Student(**student.dict())
    db.add(db_student)
    db.commit()
    db.refresh(db_student)
    return db_student
