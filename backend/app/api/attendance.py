"""
Attendance API

Backs the frontend's AttendanceAPI (frontend/src/lib/api.ts):
    GET /api/v1/ai/attendance                -> list()
    GET /api/v1/ai/attendance/student/{id}    -> byStudent(id)

This router was added to replace a previous setup where main.py mounted
risk_router (app/api/risk.py) under the /api/v1/ai/attendance prefix as a
stopgap. That mount produced risk-assessment JSON under attendance-shaped
URLs, which silently served the wrong data instead of 404ing.
"""
from datetime import datetime
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.api.auth import get_current_user
from app.db.database import get_db
from app.models.models import Attendance, Student, User

router = APIRouter()


class AttendanceRecordResponse(BaseModel):
    id: int
    student_id: int
    course_id: Optional[int] = None
    date: Optional[datetime] = None
    status: Optional[str] = None

    class Config:
        from_attributes = True


@router.get("/", response_model=List[AttendanceRecordResponse])
def list_attendance(
    student_id: Optional[int] = None,
    course_id: Optional[int] = None,
    status: Optional[str] = None,
    skip: int = 0,
    limit: int = 200,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = db.query(Attendance)
    if student_id is not None:
        query = query.filter(Attendance.student_id == student_id)
    if course_id is not None:
        query = query.filter(Attendance.course_id == course_id)
    if status is not None:
        query = query.filter(Attendance.status == status)
    return (
        query.order_by(Attendance.date.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )


@router.get("/student/{student_id}", response_model=List[AttendanceRecordResponse])
def get_attendance_for_student(
    student_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    student = db.query(Student).filter(Student.id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    return (
        db.query(Attendance)
        .filter(Attendance.student_id == student_id)
        .order_by(Attendance.date.desc())
        .all()
    )
