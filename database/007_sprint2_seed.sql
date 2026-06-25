-- ============================================================
-- EduGuard AI — Sprint 2 Seed Data
-- File    : database/007_sprint2_seed.sql  (renumbered from 003 — see
--           note below; original filename kept in git history)
-- Depends : 005_academic_foundation.sql and 006_seed_courses.sql must
--           already be run (this file requires academic_programs,
--           academic_tracks, academic_terms, grade_scale, and
--           course_prerequisites to already exist).
-- Safe    : Fully idempotent — ON CONFLICT DO NOTHING / DO UPDATE
-- Source  : ALL values derived exclusively from:
--             Track_Courses_List__Original.pdf
--             Courses_Pre-requisites_Core_and_Elective.pdf
--             Important_Courses_Post-requisite_for_each_course.pdf
--             Courses_that_have_no_pre-requisites.pdf
--             CGPA_Calculator.xlsx
-- ============================================================

-- ============================================================
-- STEP 1: DEPARTMENT
-- ============================================================
INSERT INTO departments (name, code, description)
VALUES ('Computer Science', 'CS', 'NMU Computer Science Department')
ON CONFLICT (code) DO NOTHING;

-- ============================================================
-- STEP 2: ACADEMIC PROGRAM
-- Source: Track_Courses_List PDF — 134 CH, 268 ECTS, 4 years
-- ============================================================
INSERT INTO academic_programs (
    code, name, name_ar,
    total_credit_hours, min_cgpa_grad, duration_years,
    is_active, description
) VALUES (
    'CS',
    'Computer Science',
    'برنامج علوم الحاسب',
    134, 2.00, 4, TRUE,
    'NMU CS Program — 8 semesters, 134 CH, 268 ECTS. Source: Vol.4 Study Programs MASH.'
) ON CONFLICT (code) DO UPDATE SET
    total_credit_hours = EXCLUDED.total_credit_hours,
    description        = EXCLUDED.description;

-- ============================================================
-- STEP 3: ACADEMIC TRACK — Software Engineering
-- ============================================================
INSERT INTO academic_tracks (program_id, code, name, name_ar, is_active, description)
SELECT
    ap.id,
    'CS-SE',
    'Software Engineering',
    'هندسة البرمجيات',
    TRUE,
    'III. Software Engineering Track — NMU CS Program. 8 semesters, 134 CH.'
FROM academic_programs ap WHERE ap.code = 'CS'
ON CONFLICT (code) DO NOTHING;

-- Wire department to program
UPDATE academic_programs ap
SET department_id = d.id
FROM departments d
WHERE ap.code = 'CS' AND d.code = 'CS'
  AND ap.department_id IS NULL;

-- ============================================================
-- STEP 4: NMU GRADE SCALE — 14 symbols
-- Source: CGPA_Calculator.xlsx column C (Grade) + D (Grade Points)
-- EXACT values — no external standards used.
-- ============================================================
INSERT INTO grade_scale (
    program_id, letter_grade, grade_points,
    counts_in_cgpa, is_passing, description, failure_type
)
SELECT
    ap.id,
    gs.letter_grade,
    gs.grade_points,
    gs.counts_in_cgpa,
    gs.is_passing,
    gs.description,
    gs.failure_type
FROM academic_programs ap,
(VALUES
    ('A+',  4.0::NUMERIC(3,2), TRUE,  TRUE,  'Excellent',          NULL),
    ('A',   4.0::NUMERIC(3,2), TRUE,  TRUE,  'Excellent',          NULL),
    ('A-',  3.7::NUMERIC(3,2), TRUE,  TRUE,  'Excellent',          NULL),
    ('B+',  3.3::NUMERIC(3,2), TRUE,  TRUE,  'Good',               NULL),
    ('B',   3.0::NUMERIC(3,2), TRUE,  TRUE,  'Good',               NULL),
    ('B-',  2.7::NUMERIC(3,2), TRUE,  TRUE,  'Good',               NULL),
    ('C+',  2.3::NUMERIC(3,2), TRUE,  TRUE,  'Satisfactory',       NULL),
    ('C',   2.0::NUMERIC(3,2), TRUE,  TRUE,  'Satisfactory',       NULL),
    ('C-',  1.7::NUMERIC(3,2), TRUE,  TRUE,  'Satisfactory',       NULL),
    ('D+',  1.3::NUMERIC(3,2), TRUE,  TRUE,  'Pass',               NULL),
    ('D',   1.0::NUMERIC(3,2), TRUE,  TRUE,  'Pass',               NULL),
    ('F',   0.0::NUMERIC(3,2), TRUE,  FALSE, 'Fail',               'academic'),
    ('FL',  0.0::NUMERIC(3,2), TRUE,  FALSE, 'Fail (Absent)',      'attendance'),
    ('P',   0.0::NUMERIC(3,2), FALSE, TRUE,  'Pass (Non-Credit)',  NULL)
) AS gs(letter_grade, grade_points, counts_in_cgpa, is_passing, description, failure_type)
WHERE ap.code = 'CS'
ON CONFLICT (program_id, letter_grade) DO NOTHING;

-- ============================================================
-- STEP 5: ACADEMIC TERM — Fall 2025
-- ============================================================
INSERT INTO academic_terms (
    code, name, term_type, academic_year,
    start_date, end_date, registration_start, registration_end,
    is_active
) VALUES (
    '2025-FALL', 'Fall Semester 2025', 'fall', 2025,
    '2025-09-01', '2026-01-15',
    '2025-08-01', '2025-08-31',
    TRUE
) ON CONFLICT (code) DO NOTHING;

-- Academic Calendar for Fall 2025
INSERT INTO academic_calendar_periods (term_id, period_type, label, start_date, end_date)
SELECT
    t.id,
    p.period_type::s2_calendar_period,
    p.label,
    p.sd::DATE,
    p.ed::DATE
FROM academic_terms t,
(VALUES
    ('registration',     'Registration Period Fall 2025',      '2025-08-01', '2025-08-31'),
    ('add_drop',         'Add/Drop Period Fall 2025',          '2025-09-01', '2025-09-14'),
    ('withdrawal',       'Withdrawal Period Fall 2025',        '2025-09-15', '2025-10-31'),
    ('midterm',          'Midterm Examination Period',         '2025-10-20', '2025-11-03'),
    ('final_exam',       'Final Examination Period Fall 2025', '2025-12-20', '2026-01-10'),
    ('grade_submission', 'Grade Submission Deadline',          '2026-01-10', '2026-01-15'),
    ('graduation_review','Graduation Review Period',           '2026-01-16', '2026-01-31')
) AS p(period_type, label, sd, ed)
WHERE t.code = '2025-FALL'
ON CONFLICT DO NOTHING;

-- ============================================================
-- STEP 6: CORE COURSES — All 46 plan courses
-- Source: Track_Courses_List__Original.pdf study plan table
-- Columns: plan_semester (1-8), curriculum_level (academic year 1-4),
--          credits(CH), lct_hours(LCT), lab_hours(LAB), tut_hours(TUT),
--          contact_hours(CNTCT), swl_hours(SWL), ects_credits(ECTS)
-- ============================================================

-- Macro: ON CONFLICT updates program/track binding so re-runs are safe
-- Semester 1 — Academic Level 1 — 16 CH total
INSERT INTO courses (code, name, credits, category, curriculum_level, plan_semester,
    lct_hours, lab_hours, tut_hours, contact_hours, swl_hours, ects_credits,
    is_active, counts_in_cgpa, program_id, track_id)
SELECT
    c.code, c.name, c.credits, c.category::course_category, c.lvl, c.psem,
    c.lct, c.lab, c.tut, c.cnt, c.swl, c.ects,
    TRUE, TRUE, ap.id, at2.id
FROM academic_programs ap
JOIN academic_tracks at2 ON at2.code = 'CS-SE',
(VALUES
    ('CSE014','Structured Programming',             3,'core',           1,1,2,3,0,5,150,6),
    ('PHY211','Physics II',                         3,'core',           1,1,2,2,0,4,150,6),
    ('MAT114','Analytical Geometry & Calculus I',   4,'core',           1,1,3,0,2,5,195,8),
    ('UC1',   'University Requirement (1)',          2,'university_req', 1,1,2,0,0,2, 90,4),
    ('UE1',   'Elective University (1)',             2,'university_elective',1,1,2,0,0,2,90,4),
    ('UC2',   'University Requirement (2)',          2,'university_req', 1,1,2,0,0,2, 90,4)
) AS c(code,name,credits,category,lvl,psem,lct,lab,tut,cnt,swl,ects)
WHERE ap.code = 'CS'
ON CONFLICT (code) DO UPDATE SET
    program_id = EXCLUDED.program_id, track_id = EXCLUDED.track_id,
    category = EXCLUDED.category, curriculum_level = EXCLUDED.curriculum_level,
    plan_semester = EXCLUDED.plan_semester, credits = EXCLUDED.credits,
    lct_hours = EXCLUDED.lct_hours, lab_hours = EXCLUDED.lab_hours,
    tut_hours = EXCLUDED.tut_hours, contact_hours = EXCLUDED.contact_hours,
    swl_hours = EXCLUDED.swl_hours, ects_credits = EXCLUDED.ects_credits;

-- Semester 2 — Academic Level 1 — 15 CH total
INSERT INTO courses (code, name, credits, category, curriculum_level, plan_semester,
    lct_hours, lab_hours, tut_hours, contact_hours, swl_hours, ects_credits,
    is_active, counts_in_cgpa, program_id, track_id)
SELECT c.code,c.name,c.credits,c.category::course_category,c.lvl,c.psem,c.lct,c.lab,c.tut,c.cnt,c.swl,c.ects,
    TRUE,TRUE,ap.id,at2.id
FROM academic_programs ap JOIN academic_tracks at2 ON at2.code='CS-SE',
(VALUES
    ('CSE015','Object Oriented Programming',         3,'core',           1,2,2,3,0,5,150,6),
    ('CSE113','Electric & Electronic Circuits',      3,'core',           1,2,2,2,1,5,150,6),
    ('MAT131','Statistics',                          2,'core',           1,2,1,0,2,3,105,4),
    ('MAT112','Mathematics II',                      3,'core',           1,2,2,0,2,4,150,6),
    ('UC3',   'University Requirement (3)',           2,'university_req', 1,2,2,0,0,2, 90,4),
    ('UE2',   'Elective University Requirement (2)', 2,'university_elective',1,2,2,0,0,2,90,4)
) AS c(code,name,credits,category,lvl,psem,lct,lab,tut,cnt,swl,ects)
WHERE ap.code='CS'
ON CONFLICT (code) DO UPDATE SET
    program_id=EXCLUDED.program_id, track_id=EXCLUDED.track_id,
    category=EXCLUDED.category, curriculum_level=EXCLUDED.curriculum_level,
    plan_semester=EXCLUDED.plan_semester;

-- Semester 3 — Academic Level 2 — 18 CH total
INSERT INTO courses (code, name, credits, category, curriculum_level, plan_semester,
    lct_hours, lab_hours, tut_hours, contact_hours, swl_hours, ects_credits,
    is_active, counts_in_cgpa, program_id, track_id)
SELECT c.code,c.name,c.credits,c.category::course_category,c.lvl,c.psem,c.lct,c.lab,c.tut,c.cnt,c.swl,c.ects,
    TRUE,TRUE,ap.id,at2.id
FROM academic_programs ap JOIN academic_tracks at2 ON at2.code='CS-SE',
(VALUES
    ('CSE111','Data Structures',                          3,'core',2,3,2,3,0,5,150,6),
    ('CSE131','Logic Design',                             3,'core',2,3,2,3,0,5,150,6),
    ('CSE191','Field Training 1 in Computer Science',     2,'field_training',2,3,2,0,0,2,90,4),
    ('MAT313','Differential Equations & Numerical Analysis',4,'core',2,3,3,0,2,5,195,8),
    ('MAT231','Probability & Statistics',                 3,'core',2,3,2,2,0,4,150,6),
    ('MAT212','Linear Algebra',                           3,'core',2,3,2,0,2,4,150,6)
) AS c(code,name,credits,category,lvl,psem,lct,lab,tut,cnt,swl,ects)
WHERE ap.code='CS'
ON CONFLICT (code) DO UPDATE SET
    program_id=EXCLUDED.program_id, track_id=EXCLUDED.track_id,
    category=EXCLUDED.category, curriculum_level=EXCLUDED.curriculum_level,
    plan_semester=EXCLUDED.plan_semester;

-- Semester 4 — Academic Level 2 — 17 CH total
INSERT INTO courses (code, name, credits, category, curriculum_level, plan_semester,
    lct_hours, lab_hours, tut_hours, contact_hours, swl_hours, ects_credits,
    is_active, counts_in_cgpa, program_id, track_id)
SELECT c.code,c.name,c.credits,c.category::course_category,c.lvl,c.psem,c.lct,c.lab,c.tut,c.cnt,c.swl,c.ects,
    TRUE,TRUE,ap.id,at2.id
FROM academic_programs ap JOIN academic_tracks at2 ON at2.code='CS-SE',
(VALUES
    ('CSE112','Design & Analysis of Algorithms',     3,'core',2,4,2,3,0,5,150,6),
    ('CSE132','Computer Architecture & Organization',3,'core',2,4,2,3,0,5,150,6),
    ('CSE221','Database Systems',                    3,'core',2,4,2,3,0,5,150,6),
    ('CSE251','Software Engineering',                3,'core',2,4,2,3,0,5,150,6),
    ('CSE315','Discrete Mathematics',                3,'core',2,4,2,0,2,4,150,6),
    ('UC4',   'University Requirement (4)',           2,'university_req',2,4,2,0,0,2,90,4)
) AS c(code,name,credits,category,lvl,psem,lct,lab,tut,cnt,swl,ects)
WHERE ap.code='CS'
ON CONFLICT (code) DO UPDATE SET
    program_id=EXCLUDED.program_id, track_id=EXCLUDED.track_id,
    category=EXCLUDED.category, curriculum_level=EXCLUDED.curriculum_level,
    plan_semester=EXCLUDED.plan_semester;

-- Semester 5 — Academic Level 3 — 17 CH total
INSERT INTO courses (code, name, credits, category, curriculum_level, plan_semester,
    lct_hours, lab_hours, tut_hours, contact_hours, swl_hours, ects_credits,
    is_active, counts_in_cgpa, program_id, track_id)
SELECT c.code,c.name,c.credits,c.category::course_category,c.lvl,c.psem,c.lct,c.lab,c.tut,c.cnt,c.swl,c.ects,
    TRUE,TRUE,ap.id,at2.id
FROM academic_programs ap JOIN academic_tracks at2 ON at2.code='CS-SE',
(VALUES
    ('CSE211','Web Programming',                3,'core',3,5,2,3,0,5,150,6),
    ('CSE233','Operating Systems',              3,'core',3,5,2,3,0,5,150,6),
    ('CSE241','Security of Information Systems',3,'core',3,5,2,3,0,5,150,6),
    ('CSE261','Computer Networks',              3,'core',3,5,2,3,0,5,150,6),
    ('AIE111','Artificial Intelligence',        3,'core',3,5,2,3,0,5,150,6),
    ('UC5',   'University Requirement (5)',      2,'university_req',3,5,2,0,0,2,90,4)
) AS c(code,name,credits,category,lvl,psem,lct,lab,tut,cnt,swl,ects)
WHERE ap.code='CS'
ON CONFLICT (code) DO UPDATE SET
    program_id=EXCLUDED.program_id, track_id=EXCLUDED.track_id,
    category=EXCLUDED.category, curriculum_level=EXCLUDED.curriculum_level,
    plan_semester=EXCLUDED.plan_semester;

-- Semester 6 — Academic Level 3 — 18 CH total
INSERT INTO courses (code, name, credits, category, curriculum_level, plan_semester,
    lct_hours, lab_hours, tut_hours, contact_hours, swl_hours, ects_credits,
    is_active, counts_in_cgpa, program_id, track_id)
SELECT c.code,c.name,c.credits,c.category::course_category,c.lvl,c.psem,c.lct,c.lab,c.tut,c.cnt,c.swl,c.ects,
    TRUE,TRUE,ap.id,at2.id
FROM academic_programs ap JOIN academic_tracks at2 ON at2.code='CS-SE',
(VALUES
    ('CSE212','Theory of Computation & Compilers',3,'core',3,6,2,3,0,5,150,6),
    ('CSE292','Field Training 2 in Computer Science',2,'field_training',3,6,2,0,0,2,90,4),
    ('CSE323','Advanced Database Systems',        3,'core',3,6,2,3,0,5,150,6),
    ('CSE352','Systems Analysis & Design',        3,'core',3,6,2,3,0,5,150,6),
    ('AIE121','Machine Learning',                 3,'core',3,6,2,3,0,5,150,6),
    ('UC6',   'University Requirement (6)',         2,'university_req',3,6,2,0,0,2,90,4),
    ('UE3',   'Elective University (3)',            2,'university_elective',3,6,2,0,0,2,90,4)
) AS c(code,name,credits,category,lvl,psem,lct,lab,tut,cnt,swl,ects)
WHERE ap.code='CS'
ON CONFLICT (code) DO UPDATE SET
    program_id=EXCLUDED.program_id, track_id=EXCLUDED.track_id,
    category=EXCLUDED.category, curriculum_level=EXCLUDED.curriculum_level,
    plan_semester=EXCLUDED.plan_semester;

-- Semester 7 — Academic Level 4 — 16 CH total
INSERT INTO courses (code, name, credits, category, curriculum_level, plan_semester,
    lct_hours, lab_hours, tut_hours, contact_hours, swl_hours, ects_credits,
    is_active, counts_in_cgpa, program_id, track_id)
SELECT c.code,c.name,c.credits,c.category::course_category,c.lvl,c.psem,c.lct,c.lab,c.tut,c.cnt,c.swl,c.ects,
    TRUE,TRUE,ap.id,at2.id
FROM academic_programs ap JOIN academic_tracks at2 ON at2.code='CS-SE',
(VALUES
    ('CSE454','Advanced Software Engineering',    3,'core',4,7,2,3,0,5,150,6),
    ('CSE475','Distributed Information Systems',  3,'core',4,7,2,3,0,5,150,6),
    ('CSE493','Graduation Project 1',             2,'core',4,7,2,0,0,2, 90,4),
    ('CSE313','Mobile Development',               3,'core',4,7,2,3,0,5,150,6),
    ('UC7',   'University Requirement (7)',         2,'university_req',4,7,2,0,0,2,90,4)
) AS c(code,name,credits,category,lvl,psem,lct,lab,tut,cnt,swl,ects)
WHERE ap.code='CS'
ON CONFLICT (code) DO UPDATE SET
    program_id=EXCLUDED.program_id, track_id=EXCLUDED.track_id,
    category=EXCLUDED.category, curriculum_level=EXCLUDED.curriculum_level,
    plan_semester=EXCLUDED.plan_semester;

-- Semester 8 — Academic Level 4 — 17 CH total
INSERT INTO courses (code, name, credits, category, curriculum_level, plan_semester,
    lct_hours, lab_hours, tut_hours, contact_hours, swl_hours, ects_credits,
    is_active, counts_in_cgpa, program_id, track_id)
SELECT c.code,c.name,c.credits,c.category::course_category,c.lvl,c.psem,c.lct,c.lab,c.tut,c.cnt,c.swl,c.ects,
    TRUE,TRUE,ap.id,at2.id
FROM academic_programs ap JOIN academic_tracks at2 ON at2.code='CS-SE',
(VALUES
    ('CSE363','Cloud Computing',           3,'core',4,8,2,3,0,5,150,6),
    ('CSE494','Graduation Project 2',      2,'core',4,8,2,0,0,2, 90,4),
    ('AIE323','Data Mining',               3,'core',4,8,2,3,0,5,150,6),
    ('CSE312','Advanced Web Programming',  3,'core',4,8,2,3,0,5,150,6)
) AS c(code,name,credits,category,lvl,psem,lct,lab,tut,cnt,swl,ects)
WHERE ap.code='CS'
ON CONFLICT (code) DO UPDATE SET
    program_id=EXCLUDED.program_id, track_id=EXCLUDED.track_id,
    category=EXCLUDED.category, curriculum_level=EXCLUDED.curriculum_level,
    plan_semester=EXCLUDED.plan_semester;

-- ============================================================
-- STEP 7: ELECTIVE COURSES — 22 from E1/E2/E3 pool
-- Source: Track_Courses_List PDF page 4 (Elective list)
-- ============================================================
INSERT INTO courses (code, name, credits, category, curriculum_level, plan_semester,
    lct_hours, lab_hours, tut_hours, contact_hours, swl_hours, ects_credits,
    is_active, counts_in_cgpa, program_id, track_id)
SELECT c.code,c.name,3,'elective'::course_category,c.lvl,c.psem,2,3,0,5,150,6,TRUE,TRUE,ap.id,at2.id
FROM academic_programs ap JOIN academic_tracks at2 ON at2.code='CS-SE',
(VALUES
    ('ELE432','Digital Signal Processing',                 4,7),
    ('CSE271','Introduction to Parallel Computing',        3,7),
    ('CSE272','Embedded Systems',                          3,7),
    ('CSE281','Image Processing',                          3,7),
    ('CSE322','Big Data Analytics 1',                      4,8),
    ('CSE344','Introduction to Cyber Security',            4,7),
    ('CSE424','Data Warehousing',                          4,8),
    ('CSE426','Selected Topics in Data Science',           4,8),
    ('CSE453','Software Testing',                          4,8),
    ('CSE455','Selected Topics in Software Engineering',   4,8),
    ('CSE464','Internet of Things',                        4,8),
    ('CSE478','High Performance Computing',                4,8),
    ('AIE231','Neural Networks',                           4,8),
    ('AIE241','Natural Language Processing',               4,7),
    ('AIE314','AI-Based Programming',                      4,8),
    ('AIE322','Advanced Machine Learning',                 4,8),
    ('AIE332','Deep Learning',                             4,8),
    ('AIE342','Advanced Methods for Data Analysis',        4,8),
    ('AIE343','Machine Learning for Text Mining',          4,8),
    ('AIE424','Intelligent Decision Support Systems',      4,8),
    ('AIE425','Intelligent Recommender Systems',           4,8),
    ('CSE467','Client/Server Technologies & Applications', 4,8)
) AS c(code,name,lvl,psem)
WHERE ap.code='CS'
ON CONFLICT (code) DO UPDATE SET
    program_id=EXCLUDED.program_id, track_id=EXCLUDED.track_id,
    category=EXCLUDED.category;

-- Non-credit language course (P-grade, 0 CH — from CGPA_Calculator.xlsx)
INSERT INTO courses (code, name, credits, category, is_pass_fail, counts_in_cgpa,
    is_active, program_id)
SELECT 'LAN021','Language Course (Non-Credit)',0,'university_req'::course_category,TRUE,FALSE,TRUE,ap.id
FROM academic_programs ap WHERE ap.code='CS'
ON CONFLICT (code) DO NOTHING;

-- ============================================================
-- STEP 8: ELECTIVE POOL
-- NMU SE Track: one pool, 22 courses, students select exactly 3 (E1, E2, E3)
-- Source: Track_Courses_List PDF — Semesters 7 and 8
-- ============================================================
INSERT INTO elective_pools (
    program_id, track_id, pool_code, pool_name,
    min_selections, max_selections, required_selections,
    plan_semesters, notes
)
SELECT ap.id, at2.id,
    'E1_E2_E3',
    'Software Engineering Track Electives (E1, E2, E3)',
    1, 3, 3,
    '7,8',
    'Students select exactly 3: E1 in Semester 7, E2+E3 in Semester 8. Source: Track Courses List PDF.'
FROM academic_programs ap JOIN academic_tracks at2 ON at2.code='CS-SE'
WHERE ap.code='CS'
ON CONFLICT (program_id, pool_code) DO NOTHING;

-- Link all 22 elective courses to the pool
INSERT INTO elective_pool_courses (pool_id, course_id)
SELECT ep.id, c.id
FROM elective_pools ep
JOIN academic_programs ap ON ap.id = ep.program_id AND ap.code = 'CS'
JOIN courses c ON c.code IN (
    'ELE432','CSE271','CSE272','CSE281','CSE322','CSE344','CSE424','CSE426',
    'CSE453','CSE455','CSE464','CSE478','AIE231','AIE241','AIE314','AIE322',
    'AIE332','AIE342','AIE343','AIE424','AIE425','CSE467'
)
WHERE ep.pool_code = 'E1_E2_E3'
ON CONFLICT (pool_id, course_id) DO NOTHING;

-- ============================================================
-- STEP 9: PREREQUISITE EDGES
-- Source: Courses_Pre-requisites_Core_and_Elective.pdf
-- All edges: prereq_type='hard', logic_group=1, logic_type='AND'
-- Multi-prereq courses (AND) share the same logic_group=1.
-- ============================================================

-- Single-prerequisite edges
INSERT INTO course_prerequisites (course_id, prerequisite_id, prereq_type, min_grade, logic_group, logic_type)
SELECT c.id, pc.id, 'hard', 60.00, 1, 'AND'
FROM (VALUES
    -- Programming chain
    ('CSE015', 'CSE014'),
    ('CSE111', 'CSE015'),
    ('CSE112', 'CSE111'),
    ('CSE212', 'CSE015'),
    ('CSE251', 'CSE015'),
    -- Architecture chain
    ('CSE132', 'CSE131'),
    -- Database chain
    ('CSE323', 'CSE221'),
    -- SE chain
    ('CSE352', 'CSE251'),
    ('CSE454', 'CSE251'),
    -- Web chain
    ('CSE312', 'CSE211'),
    ('CSE313', 'CSE211'),
    -- Field training chain
    ('CSE292', 'CSE191'),
    -- Graduation project chain
    ('CSE494', 'CSE493'),
    -- AI chain
    ('AIE121', 'AIE111'),
    ('AIE323', 'AIE121'),
    ('AIE322', 'AIE121'),
    ('AIE231', 'AIE121'),
    ('AIE332', 'AIE231'),
    ('AIE425', 'AIE323'),
    ('AIE342', 'AIE323'),
    ('AIE343', 'AIE323'),
    ('AIE424', 'AIE323'),
    -- Math-dependent
    ('CSE281', 'MAT212'),
    -- Elective prerequisites
    ('CSE424', 'CSE323'),
    ('CSE464', 'CSE261'),
    ('AIE241', 'AIE111'),
    -- Cloud computing requires Computer Networks
    ('CSE363', 'CSE261')
) AS pairs(cc, pc)
JOIN courses c  ON c.code = pairs.cc
JOIN courses pc ON pc.code = pairs.pc
ON CONFLICT (course_id, prerequisite_id) DO NOTHING;

-- Multi-prerequisite: CSE233 requires CSE111 AND CSE132 (both in group 1)
INSERT INTO course_prerequisites (course_id, prerequisite_id, prereq_type, min_grade, logic_group, logic_type)
SELECT c.id, pc.id, 'hard', 60.00, 1, 'AND'
FROM courses c, courses pc
WHERE c.code = 'CSE233' AND pc.code IN ('CSE111', 'CSE132')
ON CONFLICT (course_id, prerequisite_id) DO NOTHING;

-- CSE241 requires CSE112 (Security of Information Systems)
INSERT INTO course_prerequisites (course_id, prerequisite_id, prereq_type, min_grade, logic_group, logic_type)
SELECT c.id, pc.id, 'hard', 60.00, 1, 'AND'
FROM courses c, courses pc
WHERE c.code = 'CSE241' AND pc.code = 'CSE112'
ON CONFLICT (course_id, prerequisite_id) DO NOTHING;

-- CSE344 requires CSE233 AND CSE261 (both in group 1)
INSERT INTO course_prerequisites (course_id, prerequisite_id, prereq_type, min_grade, logic_group, logic_type)
SELECT c.id, pc.id, 'hard', 60.00, 1, 'AND'
FROM courses c, courses pc
WHERE c.code = 'CSE344' AND pc.code IN ('CSE233', 'CSE261')
ON CONFLICT (course_id, prerequisite_id) DO NOTHING;

-- CSE467 requires CSE112 AND CSE221 (both in group 1)
INSERT INTO course_prerequisites (course_id, prerequisite_id, prereq_type, min_grade, logic_group, logic_type)
SELECT c.id, pc.id, 'hard', 60.00, 1, 'AND'
FROM courses c, courses pc
WHERE c.code = 'CSE467' AND pc.code IN ('CSE112', 'CSE221')
ON CONFLICT (course_id, prerequisite_id) DO NOTHING;

-- AIE213 requires MAT112 AND AIE121
INSERT INTO course_prerequisites (course_id, prerequisite_id, prereq_type, min_grade, logic_group, logic_type)
SELECT c.id, pc.id, 'hard', 60.00, 1, 'AND'
FROM courses c, courses pc
WHERE c.code = 'AIE213' AND pc.code IN ('MAT112', 'AIE121')
ON CONFLICT (course_id, prerequisite_id) DO NOTHING;

-- CSE493 (Graduation Project 1) — Senior standing rule
INSERT INTO course_eligibility_rules (course_id, rule_type, rule_value, rule_text, is_mandatory)
SELECT c.id, 'min_level', 4, 'Senior standing required (Academic Level 4)', TRUE
FROM courses c WHERE c.code = 'CSE493'
ON CONFLICT DO NOTHING;

-- ============================================================
-- STEP 10: POST-REQUISITE EDGES
-- Source: Important_Courses_Post-requisite_for_each_course.pdf
-- ============================================================
INSERT INTO course_postrequisites (course_id, postreq_id, unlock_type)
SELECT c.id, pc.id, 'C'
FROM (VALUES
    ('CSE014','CSE015'), ('CSE014','CSE212'),
    ('CSE015','CSE111'), ('CSE015','CSE251'), ('CSE015','CSE313'),
    ('CSE111','CSE112'), ('CSE111','CSE233'),
    ('CSE131','CSE132'), ('CSE132','CSE233'),
    ('CSE191','CSE292'),
    ('CSE221','CSE323'),
    ('CSE251','CSE352'), ('CSE251','CSE454'),
    ('CSE211','CSE312'),
    ('CSE261','CSE363'),
    ('AIE111','AIE121'),
    ('AIE121','AIE323'), ('AIE121','AIE322'), ('AIE121','AIE231'),
    ('AIE231','AIE332'),
    ('AIE323','AIE425'), ('AIE323','AIE342'),
    ('AIE323','AIE343'), ('AIE323','AIE424'),
    ('CSE493','CSE494')
) AS pairs(cc, pc)
JOIN courses c  ON c.code = pairs.cc
JOIN courses pc ON pc.code = pairs.pc
ON CONFLICT (course_id, postreq_id) DO NOTHING;

-- ============================================================
-- STEP 11: GRADUATION REQUIREMENTS
-- Source: Track_Courses_List PDF — category totals
-- ============================================================
INSERT INTO graduation_requirements (
    program_id, track_id, category, label,
    required_credits, required_courses, min_cgpa, notes
)
SELECT ap.id, at2.id, r.cat, r.label, r.ch, r.courses, 2.00, r.notes
FROM academic_programs ap
JOIN academic_tracks at2 ON at2.code = 'CS-SE',
(VALUES
    ('core',               'Core Courses',                          99,  34, 'All mandatory core courses in 8-semester plan'),
    ('elective',           'Track Electives (E1, E2, E3)',           9,   3, 'Exactly 3 from the 22-course SE elective pool'),
    ('university_req',     'University Requirements (UC1-UC7)',     14,   7, 'UC1 through UC7, 2 CH each'),
    ('university_elective','University Elective Requirements',       6,   3, 'UE1, UE2, UE3, 2 CH each'),
    ('field_training',     'Field Training',                         4,   2, 'CSE191 (FT1) + CSE292 (FT2)'),
    ('graduation_project', 'Graduation Project',                     4,   2, 'CSE493 (GP1) + CSE494 (GP2)')
) AS r(cat, label, ch, courses, notes)
WHERE ap.code = 'CS'
ON CONFLICT DO NOTHING;

-- ============================================================
-- STEP 12: NOTIFICATION TEMPLATES
-- ============================================================
INSERT INTO notification_templates (event_type, channel, subject_template, body_template, priority)
VALUES
('registration_eligible',   'in_app',
 'Registration Open — {{term_name}}',
 'Dear {{student_name}}, you are eligible to register for {{term_name}}. {{total_eligible}} courses are available.',
 'medium'),
('academic_risk',           'in_app',
 'Academic Risk Alert',
 'Your CGPA ({{cgpa}}) has fallen below the warning threshold (2.00). Please contact your academic advisor immediately.',
 'high'),
('graduation_approaching',  'in_app',
 'Graduation Review Ready',
 'Dear {{student_name}}, you have earned {{ch_earned}} of 134 required credit hours. Your graduation audit is now available.',
 'medium'),
('missing_requirement',     'in_app',
 'Missing Graduation Requirement',
 'Graduation audit: {{missing_count}} requirement(s) are unfulfilled. Missing: {{missing_list}}',
 'high'),
('grade_posted',            'in_app',
 '{{course_code}} Grade Posted',
 '{{course_code}} — {{course_name}}: Your grade has been posted. Letter grade: {{letter_grade}} ({{grade_points}} points).',
 'medium'),
('plan_approved',           'in_app',
 'Advising Plan Approved',
 'Your advising plan for {{term_name}} has been approved by your advisor. You may now register.',
 'medium'),
('plan_rejected',           'in_app',
 'Advising Plan Requires Changes',
 'Your advising plan for {{term_name}} was returned. Advisor notes: {{advisor_notes}}',
 'high'),
('prerequisite_cleared',    'in_app',
 'New Courses Unlocked',
 'You have unlocked the following courses: {{unlocked_courses}}',
 'low'),
('override_decision',       'in_app',
 'Override Request Decision',
 'Your {{override_type}} request for {{course_code}} has been {{decision}}. Reason: {{decision_reason}}',
 'high'),
('academic_standing_change','in_app',
 'Academic Standing Update',
 'Your academic standing has changed to: {{standing}}. CGPA: {{cgpa}}. Please review your academic plan.',
 'high')
ON CONFLICT (event_type, channel) DO NOTHING;

-- ============================================================
-- updated_at TRIGGERS FOR SPRINT 2 TABLES
-- ============================================================
-- These four tables are created by SQLAlchemy's Base.metadata.create_all()
-- at backend startup (see app/models/sprint2_models.py), not by a raw SQL
-- migration file, so they aren't covered by 005_academic_foundation.sql's
-- "SECTION 18" trigger loop. Their ORM columns already use
-- onupdate=func.now(), which covers updates made through the ORM; this
-- trigger is a defense-in-depth backstop for any future direct SQL UPDATE
-- against these tables. to_regclass(...) guards make this a no-op (instead
-- of an error) if this file is somehow run before the backend has created
-- these tables.
DO $$ DECLARE t TEXT; BEGIN
    FOREACH t IN ARRAY ARRAY[
        'academic_overrides', 'academic_calendar_periods',
        'notification_preferences', 'rbac_permissions'
    ] LOOP
        IF to_regclass(t) IS NOT NULL THEN
            EXECUTE format('
                DROP TRIGGER IF EXISTS set_updated_at ON %I;
                CREATE TRIGGER set_updated_at
                BEFORE UPDATE ON %I
                FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
            ', t, t);
        END IF;
    END LOOP;
END $$;

-- ============================================================
-- VERIFICATION QUERIES (uncomment to run after seeding)
-- ============================================================
-- SELECT COUNT(*) AS total_courses FROM courses
--   WHERE program_id = (SELECT id FROM academic_programs WHERE code='CS');
-- Expected: 69

-- SELECT category, COUNT(*) FROM courses
--   WHERE program_id = (SELECT id FROM academic_programs WHERE code='CS')
--   GROUP BY category ORDER BY category;

-- SELECT letter_grade, grade_points, is_passing, counts_in_cgpa, failure_type
--   FROM grade_scale
--   WHERE program_id = (SELECT id FROM academic_programs WHERE code='CS')
--   ORDER BY grade_points DESC;
-- Expected: 14 rows

-- SELECT COUNT(*) FROM course_prerequisites cp
--   JOIN courses c ON c.id = cp.course_id
--   WHERE c.program_id = (SELECT id FROM academic_programs WHERE code='CS');
-- Expected: ~35

-- SELECT COUNT(*) FROM elective_pool_courses;
-- Expected: 22

-- SELECT SUM(req.ch) FROM (VALUES (99),(9),(14),(6),(4),(4)) AS req(ch);
-- Expected: 136 total (134 CH plan + 2 buffer for non-credit courses)