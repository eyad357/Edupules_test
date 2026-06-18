"""
EduGuard AI — Sprint 1: Academic Foundation Schemas
Pydantic v2 schemas for API request/response serialization.
"""

from __future__ import annotations
from datetime import date, datetime
from typing import Optional, List
from pydantic import BaseModel, ConfigDict, Field


# ── Shared config ─────────────────────────────────────────────────────────────
class _Base(BaseModel):
    model_config = ConfigDict(from_attributes=True)


# ═════════════════════════════════════════════════════════════════════════════
# ACADEMIC PROGRAM
# ═════════════════════════════════════════════════════════════════════════════

class AcademicProgramBase(_Base):
    code:               str
    name:               str
    name_ar:            Optional[str]  = None
    total_credit_hours: int            = 134
    min_cgpa_grad:      float          = 2.00
    duration_years:     int            = 4
    is_active:          bool           = True
    description:        Optional[str]  = None

class AcademicProgramCreate(AcademicProgramBase):
    department_id: Optional[int] = None

class AcademicProgramRead(AcademicProgramBase):
    id:            int
    department_id: Optional[int] = None
    created_at:    datetime
    updated_at:    datetime
    tracks:        List["AcademicTrackRead"] = []


# ═════════════════════════════════════════════════════════════════════════════
# ACADEMIC TRACK
# ═════════════════════════════════════════════════════════════════════════════

class AcademicTrackBase(_Base):
    code:        str
    name:        str
    name_ar:     Optional[str] = None
    is_active:   bool          = True
    description: Optional[str] = None

class AcademicTrackCreate(AcademicTrackBase):
    program_id: int

class AcademicTrackRead(AcademicTrackBase):
    id:         int
    program_id: int
    created_at: datetime
    updated_at: datetime


# ═════════════════════════════════════════════════════════════════════════════
# ACADEMIC TERM
# ═════════════════════════════════════════════════════════════════════════════

class AcademicTermBase(_Base):
    code:               str
    name:               str
    term_type:          str
    academic_year:      int
    start_date:         Optional[date] = None
    end_date:           Optional[date] = None
    registration_start: Optional[date] = None
    registration_end:   Optional[date] = None
    is_active:          bool           = False
    is_summer:          bool           = False

class AcademicTermCreate(AcademicTermBase):
    pass

class AcademicTermRead(AcademicTermBase):
    id:         int
    created_at: datetime
    updated_at: datetime


# ═════════════════════════════════════════════════════════════════════════════
# COURSE (enriched)
# ═════════════════════════════════════════════════════════════════════════════

class CourseBase(_Base):
    code:             str
    name:             str
    description:      Optional[str]   = None
    credits:          int             = 3
    category:         str             = "core"
    curriculum_level: Optional[int]   = None
    plan_semester:    Optional[int]   = None
    lct_hours:        int             = 2
    lab_hours:        int             = 0
    tut_hours:        int             = 0
    contact_hours:    int             = 2
    ects_credits:     int             = 4
    swl_hours:        int             = 90
    slot_label:       Optional[str]   = None
    counts_in_cgpa:   bool            = True
    is_pass_fail:     bool            = False
    pass_threshold:   float           = 60.00
    name_ar:          Optional[str]   = None
    is_active:        bool            = True

class CourseCreate(CourseBase):
    program_id:  Optional[int] = None
    track_id:    Optional[int] = None
    professor_id: Optional[int] = None

class CourseRead(CourseBase):
    id:           int
    program_id:   Optional[int] = None
    track_id:     Optional[int] = None
    professor_id: Optional[int] = None

class CourseWithDependencies(CourseRead):
    prerequisites:     List["PrerequisiteRead"]  = []
    postrequisites:    List["PostrequisiteRead"] = []
    eligibility_rules: List["EligibilityRuleRead"] = []


# ═════════════════════════════════════════════════════════════════════════════
# COURSE PREREQUISITE
# ═════════════════════════════════════════════════════════════════════════════

class PrerequisiteRead(_Base):
    id:              int
    course_id:       int
    prerequisite_id: int
    prereq_type:     str
    min_grade:       float
    notes:           Optional[str] = None

    # Nested course info
    prerequisite_code: Optional[str] = None
    prerequisite_name: Optional[str] = None


class PrerequisiteCreate(_Base):
    course_id:       int
    prerequisite_id: int
    prereq_type:     str   = "hard"
    min_grade:       float = 60.00
    notes:           Optional[str] = None


# ═════════════════════════════════════════════════════════════════════════════
# COURSE POST-REQUISITE
# ═════════════════════════════════════════════════════════════════════════════

class PostrequisiteRead(_Base):
    id:           int
    course_id:    int
    postreq_id:   int
    unlock_type:  str
    notes:        Optional[str] = None

    postreq_code: Optional[str] = None
    postreq_name: Optional[str] = None


# ═════════════════════════════════════════════════════════════════════════════
# ELIGIBILITY RULE
# ═════════════════════════════════════════════════════════════════════════════

class EligibilityRuleRead(_Base):
    id:           int
    course_id:    int
    rule_type:    str
    rule_value:   Optional[float] = None
    rule_text:    Optional[str]   = None
    is_mandatory: bool


# ═════════════════════════════════════════════════════════════════════════════
# COURSE OFFERING
# ═════════════════════════════════════════════════════════════════════════════

class CourseOfferingBase(_Base):
    section:       str            = "A"
    max_capacity:  int            = 40
    room:          Optional[str]  = None
    schedule_json: Optional[dict] = None
    is_open:       bool           = True
    notes:         Optional[str]  = None

class CourseOfferingCreate(CourseOfferingBase):
    course_id:    int
    term_id:      int
    professor_id: Optional[int] = None

class CourseOfferingRead(CourseOfferingBase):
    id:               int
    course_id:        int
    term_id:          int
    professor_id:     Optional[int] = None
    current_enrolled: int
    created_at:       datetime
    updated_at:       datetime

    course: Optional[CourseRead]       = None
    term:   Optional[AcademicTermRead] = None


# ═════════════════════════════════════════════════════════════════════════════
# STUDENT COURSE ATTEMPT
# ═════════════════════════════════════════════════════════════════════════════

class StudentCourseAttemptBase(_Base):
    attempt_number:         int    = 1
    credit_hours:           int    = 3
    result:                 str    = "in_progress"
    is_improvement_attempt: bool   = False
    counts_in_cgpa:         bool   = True
    notes:                  Optional[str] = None

class StudentCourseAttemptCreate(StudentCourseAttemptBase):
    student_id: int
    course_id:  int
    term_id:    int

class StudentCourseAttemptRead(StudentCourseAttemptBase):
    id:               int
    student_id:       int
    course_id:        int
    term_id:          int
    numeric_grade:    Optional[float] = None
    letter_grade:     Optional[str]   = None
    grade_points:     Optional[float] = None
    registered_at:    datetime
    grade_posted_at:  Optional[datetime] = None
    withdrawn_at:     Optional[datetime] = None
    created_at:       datetime
    updated_at:       datetime

    course: Optional[CourseRead]       = None
    term:   Optional[AcademicTermRead] = None

class GradePostRequest(_Base):
    numeric_grade: float = Field(..., ge=0, le=100)
    letter_grade:  str
    grade_points:  float = Field(..., ge=0, le=4)
    result:        str


# ═════════════════════════════════════════════════════════════════════════════
# GRADE SCALE
# ═════════════════════════════════════════════════════════════════════════════

class GradeScaleRead(_Base):
    id:             int
    program_id:     Optional[int]   = None
    letter_grade:   str
    min_percentage: Optional[float] = None
    max_percentage: Optional[float] = None
    grade_points:   float
    counts_in_cgpa: bool
    is_passing:     bool
    description:    Optional[str]   = None


# ═════════════════════════════════════════════════════════════════════════════
# STUDENT TERM GPA
# ═════════════════════════════════════════════════════════════════════════════

class StudentTermGPARead(_Base):
    id:                         int
    student_id:                 int
    term_id:                    int
    term_credit_hours_attempted: int
    term_credit_hours_earned:    int
    term_quality_points:         float
    term_gpa:                    float
    cumulative_hours_attempted:  int
    cumulative_hours_earned:     int
    cumulative_quality_points:   float
    cgpa:                        float
    academic_standing:           str
    is_summer:                   bool
    finalized:                   bool
    finalized_at:                Optional[datetime] = None

    term: Optional[AcademicTermRead] = None


# ═════════════════════════════════════════════════════════════════════════════
# STUDENT ACADEMIC PROFILE SUMMARY
# ═════════════════════════════════════════════════════════════════════════════

class StudentAcademicProfileRead(_Base):
    student_id:                     int
    program_id:                     Optional[int]   = None
    track_id:                       Optional[int]   = None
    cgpa:                           float
    total_credit_hours_attempted:   int
    total_credit_hours_earned:      int
    total_quality_points:           float
    academic_standing:              str
    is_eligible_for_graduation:     bool
    academic_level:                 Optional[int]   = None

    program:  Optional[AcademicProgramRead] = None
    track:    Optional[AcademicTrackRead]   = None


# ═════════════════════════════════════════════════════════════════════════════
# GRADUATION REQUIREMENT & PROGRESS
# ═════════════════════════════════════════════════════════════════════════════

class GraduationRequirementRead(_Base):
    id:               int
    program_id:       int
    track_id:         Optional[int] = None
    category:         str
    label:            str
    required_credits: int
    required_courses: int
    min_cgpa:         float
    notes:            Optional[str] = None

class StudentGraduationProgressRead(_Base):
    id:                int
    student_id:        int
    requirement_id:    int
    credits_completed: int
    credits_remaining: int
    courses_completed: int
    courses_remaining: int
    completion_pct:    float
    last_computed_at:  datetime

    requirement: Optional[GraduationRequirementRead] = None

class GraduationStatusRead(_Base):
    student_id:                 int
    cgpa:                       float
    total_credits_earned:       int
    is_eligible_for_graduation: bool
    overall_completion_pct:     float
    requirements:               List[StudentGraduationProgressRead] = []


# ═════════════════════════════════════════════════════════════════════════════
# ADVISING PLAN
# ═════════════════════════════════════════════════════════════════════════════

class AdvisingPlanItemCreate(_Base):
    course_id:    int
    offering_id:  Optional[int] = None
    priority_rank: int          = 1
    reason:       Optional[str] = None
    is_mandatory: bool          = False
    notes:        Optional[str] = None

class AdvisingPlanItemRead(AdvisingPlanItemCreate):
    id:      int
    plan_id: int
    course:  Optional[CourseRead] = None

class AdvisingPlanCreate(_Base):
    student_id:    int
    term_id:       int
    max_credits:   int           = 18
    student_notes: Optional[str] = None
    items:         List[AdvisingPlanItemCreate] = []

class AdvisingPlanRead(_Base):
    id:               int
    student_id:       int
    advisor_id:       Optional[int] = None
    term_id:          int
    status:           str
    total_credits:    int
    max_credits:      int
    is_ai_generated:  bool
    student_notes:    Optional[str] = None
    advisor_notes:    Optional[str] = None
    rejection_reason: Optional[str] = None
    submitted_at:     Optional[datetime] = None
    reviewed_at:      Optional[datetime] = None
    approved_at:      Optional[datetime] = None
    created_at:       datetime
    updated_at:       datetime
    items:            List[AdvisingPlanItemRead] = []
    term:             Optional[AcademicTermRead] = None

class AdvisingPlanReviewRequest(_Base):
    action:          str  # "approve" | "reject"
    advisor_notes:   Optional[str] = None
    rejection_reason: Optional[str] = None


# ═════════════════════════════════════════════════════════════════════════════
# COURSE ELIGIBILITY CHECK  (used by recommendation engine)
# ═════════════════════════════════════════════════════════════════════════════

class CourseEligibilityResult(_Base):
    course_id:    int
    course_code:  str
    course_name:  str
    is_eligible:  bool
    reasons:      List[str] = []   # why eligible or not
    missing_prereqs: List[str] = []  # codes of missing prerequisites


class StudentEligibleCoursesResponse(_Base):
    student_id:       int
    term_id:          int
    eligible_courses: List[CourseEligibilityResult] = []
    total_eligible:   int
    computed_at:      datetime


# ═════════════════════════════════════════════════════════════════════════════
# IMPORT JOB
# ═════════════════════════════════════════════════════════════════════════════

class ImportJobRead(_Base):
    id:              int
    job_type:        str
    status:          str
    file_name:       Optional[str] = None
    total_rows:      int
    processed_rows:  int
    success_rows:    int
    error_rows:      int
    started_at:      Optional[datetime] = None
    completed_at:    Optional[datetime] = None
    error_summary:   Optional[str]      = None
    created_at:      datetime


# Forward-reference resolution
AcademicProgramRead.model_rebuild()
CourseWithDependencies.model_rebuild()
AdvisingPlanRead.model_rebuild()
StudentAcademicProfileRead.model_rebuild()
