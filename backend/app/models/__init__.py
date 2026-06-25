"""Models package — exports all ORM models for EduGuard AI."""

# ── Core models (Sprint 0 / original)
from app.models.models import (
    User, Student, Professor, Advisor,
    Course, Enrollment, Attendance, ActivityLog,
    RiskAssessment, InterventionPlan, InterventionAction,
    Notification, AuditLog, Quiz, Question, QuizSubmission,
    GradeRecord, Department,
    UserRole, RiskLevel, InterventionStatus, Priority, NotificationType,
    AttendanceStatus, QuizStatus,
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

# ── Sprint 4: Academic Intelligence models
from app.models.sprint4_models import (
    AcademicRulesConfig, SemesterSnapshot, TranscriptVersion,
    TranscriptVerification, AcademicTimelineEvent, AcademicStatusHistory,
    DegreeProgressSnapshot, GraduationEligibilityRecord, HonorsRecord,
    GPAProjection, AcademicRiskRecord, RegistrarNote, AcademicAuditEntry,
    AcademicStatusEnum, TranscriptTypeEnum, GradEligibilityEnum,
    HonorsLevelEnum, RiskLevelEnum as Sprint4RiskLevelEnum,
    TimelineEventTypeEnum, NoteTypeEnum, AuditActionEnum,
)

# ── Sprint 4 Extended: Scholarship / GPA Versioning / Achievements models
from app.models.sprint4_extended_models import (
    ScholarshipEvaluation, GPAVersion, AcademicAchievement, GPAExplanation,
    ScholarshipStatusEnum, AchievementCategoryEnum,
)

# ── Enterprise: Cohorts, Cases, Documents, Transfer Credits, Registrar Ops
from app.models.enterprise_models import (
    StudentCohort, CohortMembership, RegistrationEvent, StudentDocument,
    AcademicCase, AcademicCaseDecision, TransferCredit, AcademicExemption,
    AcademicRecordVersion, PDFTranscriptJob, RegistrarTask,
    RegistrarTaskAssignment, PrerequisiteValidation,
    CohortStatusEnum, RegistrationEventTypeEnum, DocumentTypeEnum,
    DocumentStatusEnum, CaseTypeEnum, CaseStatusEnum,
    TransferCreditStatusEnum, ExemptionTypeEnum, ExemptionStatusEnum,
    RecordVersionTriggerEnum, PDFJobStatusEnum, RegistrarTaskTypeEnum,
    TaskStatusEnum, TaskPriorityEnum,
)

__all__ = [
    # Core
    "User", "Student", "Professor", "Advisor",
    "Course", "Enrollment", "Attendance", "ActivityLog",
    "RiskAssessment", "InterventionPlan", "InterventionAction",
    "Notification", "AuditLog", "Quiz", "Question", "QuizSubmission",
    "GradeRecord", "Department",
    "UserRole", "RiskLevel", "InterventionStatus", "Priority", "NotificationType",
    "AttendanceStatus", "QuizStatus",
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
    # Sprint 4 Academic Intelligence
    "AcademicRulesConfig", "SemesterSnapshot", "TranscriptVersion",
    "TranscriptVerification", "AcademicTimelineEvent", "AcademicStatusHistory",
    "DegreeProgressSnapshot", "GraduationEligibilityRecord", "HonorsRecord",
    "GPAProjection", "AcademicRiskRecord", "RegistrarNote", "AcademicAuditEntry",
    "AcademicStatusEnum", "TranscriptTypeEnum", "GradEligibilityEnum",
    "HonorsLevelEnum", "Sprint4RiskLevelEnum",
    "TimelineEventTypeEnum", "NoteTypeEnum", "AuditActionEnum",
    # Sprint 4 Extended
    "ScholarshipEvaluation", "GPAVersion", "AcademicAchievement", "GPAExplanation",
    "ScholarshipStatusEnum", "AchievementCategoryEnum",
    # Enterprise
    "StudentCohort", "CohortMembership", "RegistrationEvent", "StudentDocument",
    "AcademicCase", "AcademicCaseDecision", "TransferCredit", "AcademicExemption",
    "AcademicRecordVersion", "PDFTranscriptJob", "RegistrarTask",
    "RegistrarTaskAssignment", "PrerequisiteValidation",
    "CohortStatusEnum", "RegistrationEventTypeEnum", "DocumentTypeEnum",
    "DocumentStatusEnum", "CaseTypeEnum", "CaseStatusEnum",
    "TransferCreditStatusEnum", "ExemptionTypeEnum", "ExemptionStatusEnum",
    "RecordVersionTriggerEnum", "PDFJobStatusEnum", "RegistrarTaskTypeEnum",
    "TaskStatusEnum", "TaskPriorityEnum",
]