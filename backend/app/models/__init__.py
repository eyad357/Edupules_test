"""Models package — exports all ORM models for EduGuard AI."""

# ── Core models (Sprint 0 / original)
from app.models.models import (
    User, Student, Professor, Advisor,
    Course, Enrollment, Attendance, ActivityLog,
    RiskAssessment, InterventionPlan, InterventionAction,
    Notification, AuditLog, Quiz, Question, QuizSubmission,
    UserRole, RiskLevel, InterventionStatus, Priority, NotificationType,
)

# ── Sprint 1: Academic Foundation models
from app.models.academic_models import (
    AcademicProgram, AcademicTrack, AcademicTerm,
    CoursePrerequisite, CoursePostrequisite, CourseEligibilityRule,
    CourseOffering, StudentCourseAttempt, GradeScale,
    StudentTermGPA, GraduationRequirement, StudentGraduationProgress,
    AdvisingPlan, AdvisingPlanItem,
    ImportJob, ImportError,
    CourseCategoryEnum, TermTypeEnum, AttemptResultEnum,
    AdvisingPlanStatusEnum, ReqCategoryEnum, ImportStatusEnum,
)

# ── Sprint 2: Academic Rules Engine models
from app.models.sprint2_models import (
    PrerequisiteException, PrerequisiteValidationLog,
    ElectivePool, ElectivePoolCourse, StudentElectiveSelection,
    GraduationAuditResult,
    AcademicCalendarPeriod,
    AcademicOverride, AcademicOverrideHistory,
    NotificationTemplate, NotificationDeliveryLog, NotificationPreference,
    RbacPermission,
    AcademicDecisionLog,
    OverrideStatusEnum, OverrideTypeEnum, CalendarPeriodTypeEnum,
    NotifChannelEnum, NotifEventTypeEnum,
)

# ── Sprint 3: Import & Validation Platform models
from app.models.sprint3_models import (
    ImportBatch,
    ImportRowError,
    MappingTemplate,
    MappingTemplateVersion,
    ValidationRule,
    ValidationResult,
    ReconciliationReport,
    ReconciliationItem,
    ImportAuditEvent,
    # Enums
    BatchStatusEnum,
    ImportTypeEnum,
    FileFormatEnum,
    SourceSystemEnum,
    ValidationSeverityEnum,
    ValidationCategoryEnum,
    ReconciliationStatusEnum,
    ReconciliationTypeEnum,
    AuditEventTypeEnum,
)

__all__ = [
    # Core
    "User", "Student", "Professor", "Advisor",
    "Course", "Enrollment", "Attendance", "ActivityLog",
    "RiskAssessment", "InterventionPlan", "InterventionAction",
    "Notification", "AuditLog", "Quiz", "Question", "QuizSubmission",
    "UserRole", "RiskLevel", "InterventionStatus", "Priority", "NotificationType",
    # Sprint 1 Academic Foundation
    "AcademicProgram", "AcademicTrack", "AcademicTerm",
    "CoursePrerequisite", "CoursePostrequisite", "CourseEligibilityRule",
    "CourseOffering", "StudentCourseAttempt", "GradeScale",
    "StudentTermGPA", "GraduationRequirement", "StudentGraduationProgress",
    "AdvisingPlan", "AdvisingPlanItem",
    "ImportJob", "ImportError",
    "CourseCategoryEnum", "TermTypeEnum", "AttemptResultEnum",
    "AdvisingPlanStatusEnum", "ReqCategoryEnum", "ImportStatusEnum",
    # Sprint 2 Academic Rules Engine
    "PrerequisiteException", "PrerequisiteValidationLog",
    "ElectivePool", "ElectivePoolCourse", "StudentElectiveSelection",
    "GraduationAuditResult",
    "AcademicCalendarPeriod",
    "AcademicOverride", "AcademicOverrideHistory",
    "NotificationTemplate", "NotificationDeliveryLog", "NotificationPreference",
    "RbacPermission",
    "AcademicDecisionLog",
    "OverrideStatusEnum", "OverrideTypeEnum", "CalendarPeriodTypeEnum",
    "NotifChannelEnum", "NotifEventTypeEnum",
    # Sprint 3 Import Platform
    "ImportBatch", "ImportRowError",
    "MappingTemplate", "MappingTemplateVersion",
    "ValidationRule", "ValidationResult",
    "ReconciliationReport", "ReconciliationItem",
    "ImportAuditEvent",
    "BatchStatusEnum", "ImportTypeEnum", "FileFormatEnum", "SourceSystemEnum",
    "ValidationSeverityEnum", "ValidationCategoryEnum",
    "ReconciliationStatusEnum", "ReconciliationTypeEnum", "AuditEventTypeEnum",
]