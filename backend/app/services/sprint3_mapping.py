"""
EduGuard AI — Sprint 3: Mapping Engine
File: backend/app/services/sprint3_mapping.py

Responsibilities:
  - Manage mapping templates and their versioned snapshots
  - Apply field mappings + transformations to raw import rows
  - Validate mapping completeness before import starts
"""

from __future__ import annotations

import logging
from typing import Any, Dict, List, Optional

from sqlalchemy.orm import Session

from app.models.sprint3_models import (
    MappingTemplate,
    MappingTemplateVersion,
    ImportTypeEnum,
    SourceSystemEnum,
)

logger = logging.getLogger(__name__)


# ── Built-in default templates ────────────────────────────────────────────────

DEFAULT_TEMPLATES: Dict[str, Dict[str, Any]] = {
    "registrar_students": {
        "name": "Registrar Student Export",
        "import_type": ImportTypeEnum.STUDENTS,
        "source_system": SourceSystemEnum.REGISTRAR,
        "field_mappings": {
            "Student ID":       "student_code",
            "Full Name":        "full_name",
            "Email":            "university_email",
            "Enrollment Year":  "enrollment_year",
            "Academic Status":  "academic_status",
            "Department":       "department_name",
            "Program":          "program_name",
            "Track":            "track_name",
            "Level":            "academic_level",
        },
        "transformations": {
            "student_code":      "strip",
            "university_email":  "lower",
            "academic_status":   "lower",
        },
    },
    "registrar_transcripts": {
        "name": "Registrar Transcript Export",
        "import_type": ImportTypeEnum.TRANSCRIPTS,
        "source_system": SourceSystemEnum.REGISTRAR,
        "field_mappings": {
            "Student ID":    "student_code",
            "Course Code":   "course_code",
            "Attempt":       "attempt_number",
            "Term":          "term_name",
            "Grade":         "grade",
            "Grade Points":  "grade_points",
            "Credits":       "credit_hours",
            "Semester GPA":  "semester_gpa",
            "Term Credits":  "term_credits",
            "Earned Credits":"earned_credits",
        },
        "transformations": {
            "student_code": "strip",
            "course_code":  "upper",
            "grade":        "upper",
        },
    },
    "curriculum_import": {
        "name": "Curriculum System Export",
        "import_type": ImportTypeEnum.CURRICULUM,
        "source_system": SourceSystemEnum.CURRICULUM,
        "field_mappings": {
            "Course Code":     "course_code",
            "Course Name":     "course_name",
            "Credits":         "credit_hours",
            "Category":        "category",
            "Program":         "program_name",
            "Track":           "track_name",
            "Curriculum Year": "curriculum_year",
            "Prerequisite":    "prerequisite_code",
            "Postrequisite":   "postrequisite_code",
            "Elective Pool":   "elective_pool_name",
        },
        "transformations": {
            "course_code": "upper",
            "category":    "lower",
        },
    },
}


# ── Transformation helpers ─────────────────────────────────────────────────────

def _apply_transform(value: Any, transform: str) -> Any:
    if value is None:
        return value
    s = str(value)
    match transform:
        case "strip":   return s.strip()
        case "upper":   return s.strip().upper()
        case "lower":   return s.strip().lower()
        case "title":   return s.strip().title()
        case "int":
            try:    return int(float(s.strip()))
            except: return value
        case "float":
            try:    return float(s.strip())
            except: return value
        case _:         return value


def apply_mapping(
    raw_row: Dict[str, Any],
    field_mappings: Dict[str, str],
    transformations: Optional[Dict[str, str]] = None,
) -> Dict[str, Any]:
    """
    Map a raw dict (external column names) to internal field names,
    then apply configured transformations.

    Unknown source columns are silently preserved under their original name
    so validation can later flag missing required fields.
    """
    mapped: Dict[str, Any] = {}

    for src_col, value in raw_row.items():
        internal_field = field_mappings.get(src_col, src_col)
        mapped[internal_field] = value

    if transformations:
        for field, transform in transformations.items():
            if field in mapped:
                mapped[field] = _apply_transform(mapped[field], transform)

    return mapped


# ── DB helpers ────────────────────────────────────────────────────────────────

def get_template(db: Session, template_id: int) -> Optional[MappingTemplate]:
    return db.query(MappingTemplate).filter(MappingTemplate.id == template_id).first()


def list_templates(
    db: Session,
    import_type: Optional[ImportTypeEnum] = None,
    is_active: Optional[bool] = True,
) -> List[MappingTemplate]:
    q = db.query(MappingTemplate)
    if import_type:
        q = q.filter(MappingTemplate.import_type == import_type)
    if is_active is not None:
        q = q.filter(MappingTemplate.is_active == is_active)
    return q.order_by(MappingTemplate.name).all()


def create_template(
    db: Session,
    name: str,
    import_type: ImportTypeEnum,
    source_system: SourceSystemEnum,
    field_mappings: Dict[str, str],
    description: Optional[str] = None,
    transformations: Optional[Dict[str, str]] = None,
    created_by: Optional[int] = None,
) -> MappingTemplate:
    template = MappingTemplate(
        name=name,
        description=description,
        import_type=import_type,
        source_system=source_system,
        created_by=created_by,
    )
    db.add(template)
    db.flush()  # get template.id

    version = MappingTemplateVersion(
        template_id=template.id,
        version_number=1,
        field_mappings=field_mappings,
        transformations=transformations,
        is_current=True,
        published_by=created_by,
    )
    db.add(version)
    db.commit()
    db.refresh(template)
    return template


def update_template(
    db: Session,
    template: MappingTemplate,
    update_data: Dict[str, Any],
    actor_id: Optional[int] = None,
) -> MappingTemplate:
    """Update metadata and optionally publish a new mapping version."""
    if "name" in update_data and update_data["name"]:
        template.name = update_data["name"]
    if "description" in update_data:
        template.description = update_data["description"]
    if "is_active" in update_data and update_data["is_active"] is not None:
        template.is_active = update_data["is_active"]

    if update_data.get("field_mappings"):
        # Mark all existing versions as not-current
        db.query(MappingTemplateVersion).filter(
            MappingTemplateVersion.template_id == template.id
        ).update({"is_current": False})

        # Compute next version number
        last = (
            db.query(MappingTemplateVersion)
            .filter(MappingTemplateVersion.template_id == template.id)
            .order_by(MappingTemplateVersion.version_number.desc())
            .first()
        )
        next_ver = (last.version_number + 1) if last else 1

        new_version = MappingTemplateVersion(
            template_id=template.id,
            version_number=next_ver,
            field_mappings=update_data["field_mappings"],
            transformations=update_data.get("transformations"),
            is_current=True,
            published_by=actor_id,
            notes=update_data.get("version_notes"),
        )
        db.add(new_version)

    db.commit()
    db.refresh(template)
    return template


def get_current_version(
    db: Session, template_id: int
) -> Optional[MappingTemplateVersion]:
    return (
        db.query(MappingTemplateVersion)
        .filter(
            MappingTemplateVersion.template_id == template_id,
            MappingTemplateVersion.is_current == True,
        )
        .first()
    )


def seed_default_templates(db: Session, actor_id: Optional[int] = None) -> int:
    """Seed built-in templates if they do not already exist. Returns count created."""
    created = 0
    for key, cfg in DEFAULT_TEMPLATES.items():
        exists = (
            db.query(MappingTemplate)
            .filter(
                MappingTemplate.name == cfg["name"],
                MappingTemplate.import_type == cfg["import_type"],
            )
            .first()
        )
        if not exists:
            create_template(
                db=db,
                name=cfg["name"],
                import_type=cfg["import_type"],
                source_system=cfg["source_system"],
                field_mappings=cfg["field_mappings"],
                transformations=cfg.get("transformations"),
                created_by=actor_id,
            )
            created += 1
            logger.info("Seeded default mapping template: %s", cfg["name"])
    return created
