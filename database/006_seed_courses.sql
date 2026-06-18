-- ============================================================
-- EduGuard AI — Sprint 1: CS Course Catalog Seed
-- ============================================================
-- File        : 006_seed_courses.sql
-- Description : Seeds the complete CS Software Engineering Track
--               course catalog extracted from official documents:
--                 - Track_Courses_List (study plan)
--                 - Courses_Pre-requisites
--                 - Courses_no_pre-requisites
--                 - Important_Courses_Post-requisite
-- Run order   : 6 → after 005_academic_foundation.sql
-- ============================================================

-- ============================================================
-- HELPER: get program and track IDs
-- ============================================================
DO $$
DECLARE
    v_prog_id   BIGINT;
    v_track_id  BIGINT;
BEGIN
    SELECT id INTO v_prog_id  FROM academic_programs WHERE code = 'CS';
    SELECT id INTO v_track_id FROM academic_tracks    WHERE code = 'CS-SE';

    IF v_prog_id IS NULL THEN
        RAISE EXCEPTION 'CS program not found. Run 005_academic_foundation.sql first.';
    END IF;

    -- ========================================================
    -- STEP 1: INSERT ALL COURSES INTO CATALOG
    -- Columns: code, name, credits, category, curriculum_level,
    --          plan_semester, lct_hours, lab_hours, tut_hours,
    --          contact_hours, swl_hours, ects_credits,
    --          is_pass_fail, slot_label, program_id, track_id
    -- ========================================================

    -- Semester 1 — Core
    INSERT INTO courses (code, name, credits, category, curriculum_level, plan_semester,
                         lct_hours, lab_hours, tut_hours, contact_hours, swl_hours, ects_credits,
                         program_id, track_id, is_active)
    VALUES
        ('CSE014', 'Structured Programming',                 3, 'core',               1, 1, 2, 3, 0, 5, 150, 6, v_prog_id, v_track_id, TRUE),
        ('PHY211', 'Physics II',                             3, 'core',               1, 1, 2, 2, 0, 4, 150, 6, v_prog_id, v_track_id, TRUE),
        ('MAT114', 'Analytical Geometry & Calculus I',       4, 'core',               1, 1, 3, 0, 2, 5, 195, 8, v_prog_id, v_track_id, TRUE),
        ('UC1',    'University Requirement (1)',              2, 'university_req',     1, 1, 2, 0, 0, 2,  90, 4, v_prog_id, v_track_id, TRUE),
        ('UE1',    'Elective University (1)',                 2, 'university_elective',1, 1, 2, 0, 0, 2,  90, 4, v_prog_id, v_track_id, TRUE),
        ('UC2',    'University Requirement (2)',              2, 'university_req',     1, 1, 2, 0, 0, 2,  90, 4, v_prog_id, v_track_id, TRUE)
    ON CONFLICT (code) DO UPDATE SET
        program_id = EXCLUDED.program_id,
        track_id   = EXCLUDED.track_id,
        category   = EXCLUDED.category,
        plan_semester = EXCLUDED.plan_semester,
        curriculum_level = EXCLUDED.curriculum_level;

    -- Semester 2 — Core
    INSERT INTO courses (code, name, credits, category, curriculum_level, plan_semester,
                         lct_hours, lab_hours, tut_hours, contact_hours, swl_hours, ects_credits,
                         program_id, track_id, is_active)
    VALUES
        ('CSE015', 'Object Oriented Programming',            3, 'core',               1, 2, 2, 3, 0, 5, 150, 6, v_prog_id, v_track_id, TRUE),
        ('CSE113', 'Electric & Electronic Circuits',         3, 'core',               1, 2, 2, 2, 1, 5, 150, 6, v_prog_id, v_track_id, TRUE),
        ('MAT131', 'Statistics',                             2, 'core',               1, 2, 1, 0, 2, 3, 105, 4, v_prog_id, v_track_id, TRUE),
        ('MAT112', 'Mathematics II',                         3, 'core',               1, 2, 2, 0, 2, 4, 150, 6, v_prog_id, v_track_id, TRUE),
        ('UC3',    'University Requirement (3)',              2, 'university_req',     1, 2, 2, 0, 0, 2,  90, 4, v_prog_id, v_track_id, TRUE),
        ('UE2',    'Elective University Requirement (2)',     2, 'university_elective',1, 2, 2, 0, 0, 2,  90, 4, v_prog_id, v_track_id, TRUE)
    ON CONFLICT (code) DO UPDATE SET
        program_id = EXCLUDED.program_id, track_id = EXCLUDED.track_id,
        category = EXCLUDED.category, plan_semester = EXCLUDED.plan_semester,
        curriculum_level = EXCLUDED.curriculum_level;

    -- Semester 3 — Core
    INSERT INTO courses (code, name, credits, category, curriculum_level, plan_semester,
                         lct_hours, lab_hours, tut_hours, contact_hours, swl_hours, ects_credits,
                         program_id, track_id, is_active, is_pass_fail)
    VALUES
        ('CSE111', 'Data Structures',                        3, 'core',         2, 3, 2, 3, 0, 5, 150, 6, v_prog_id, v_track_id, TRUE, FALSE),
        ('CSE131', 'Logic Design',                           3, 'core',         2, 3, 2, 3, 0, 5, 150, 6, v_prog_id, v_track_id, TRUE, FALSE),
        ('CSE191', 'Field Training 1 In Computer Science',   2, 'field_training',2, 3, 2, 0, 0, 2,  90, 4, v_prog_id, v_track_id, TRUE, TRUE),
        ('MAT313', 'Differential Equations & Numerical Analysis', 4, 'core',    2, 3, 3, 0, 2, 5, 195, 8, v_prog_id, v_track_id, TRUE, FALSE),
        ('MAT231', 'Probability & Statistics',               3, 'core',         2, 3, 2, 0, 2, 4, 150, 6, v_prog_id, v_track_id, TRUE, FALSE),
        ('MAT212', 'Linear Algebra',                         3, 'core',         2, 3, 2, 0, 2, 4, 150, 6, v_prog_id, v_track_id, TRUE, FALSE)
    ON CONFLICT (code) DO UPDATE SET
        program_id = EXCLUDED.program_id, track_id = EXCLUDED.track_id,
        category = EXCLUDED.category, plan_semester = EXCLUDED.plan_semester,
        is_pass_fail = EXCLUDED.is_pass_fail, curriculum_level = EXCLUDED.curriculum_level;

    -- Semester 4 — Core
    INSERT INTO courses (code, name, credits, category, curriculum_level, plan_semester,
                         lct_hours, lab_hours, tut_hours, contact_hours, swl_hours, ects_credits,
                         program_id, track_id, is_active)
    VALUES
        ('CSE112', 'Design & Analysis of Algorithms',        3, 'core', 2, 4, 2, 3, 0, 5, 150, 6, v_prog_id, v_track_id, TRUE),
        ('CSE132', 'Computer Architecture & Organization',   3, 'core', 2, 4, 2, 3, 0, 5, 150, 6, v_prog_id, v_track_id, TRUE),
        ('CSE221', 'Database Systems',                       3, 'core', 2, 4, 2, 3, 0, 5, 150, 6, v_prog_id, v_track_id, TRUE),
        ('CSE251', 'Software Engineering',                   3, 'core', 2, 4, 2, 3, 0, 5, 150, 6, v_prog_id, v_track_id, TRUE),
        ('CSE315', 'Discrete Mathematics',                   3, 'core', 2, 4, 2, 0, 2, 4, 150, 6, v_prog_id, v_track_id, TRUE),
        ('UC4',    'University Requirement (4)',              2, 'university_req', 2, 4, 2, 0, 0, 2, 90, 4, v_prog_id, v_track_id, TRUE)
    ON CONFLICT (code) DO UPDATE SET
        program_id = EXCLUDED.program_id, track_id = EXCLUDED.track_id,
        category = EXCLUDED.category, plan_semester = EXCLUDED.plan_semester,
        curriculum_level = EXCLUDED.curriculum_level;

    -- Semester 5 — Core
    INSERT INTO courses (code, name, credits, category, curriculum_level, plan_semester,
                         lct_hours, lab_hours, tut_hours, contact_hours, swl_hours, ects_credits,
                         program_id, track_id, is_active)
    VALUES
        ('CSE211', 'Web Programming',                        3, 'core', 3, 5, 2, 3, 0, 5, 150, 6, v_prog_id, v_track_id, TRUE),
        ('CSE233', 'Operating Systems',                      3, 'core', 3, 5, 2, 3, 0, 5, 150, 6, v_prog_id, v_track_id, TRUE),
        ('CSE241', 'Security of Information Systems',        3, 'core', 3, 5, 2, 3, 0, 5, 150, 6, v_prog_id, v_track_id, TRUE),
        ('CSE261', 'Computer Networks',                      3, 'core', 3, 5, 2, 3, 0, 5, 150, 6, v_prog_id, v_track_id, TRUE),
        ('AIE111', 'Artificial Intelligence',                3, 'core', 3, 5, 2, 3, 0, 5, 150, 6, v_prog_id, v_track_id, TRUE),
        ('UC5',    'University Requirement (5)',              2, 'university_req', 3, 5, 2, 0, 0, 2, 90, 4, v_prog_id, v_track_id, TRUE)
    ON CONFLICT (code) DO UPDATE SET
        program_id = EXCLUDED.program_id, track_id = EXCLUDED.track_id,
        category = EXCLUDED.category, plan_semester = EXCLUDED.plan_semester,
        curriculum_level = EXCLUDED.curriculum_level;

    -- Semester 6 — Core
    INSERT INTO courses (code, name, credits, category, curriculum_level, plan_semester,
                         lct_hours, lab_hours, tut_hours, contact_hours, swl_hours, ects_credits,
                         program_id, track_id, is_active, is_pass_fail)
    VALUES
        ('CSE212', 'Theory of Computation & Compilers',      3, 'core', 3, 6, 2, 3, 0, 5, 150, 6, v_prog_id, v_track_id, TRUE, FALSE),
        ('CSE292', 'Field Training 2 In Computer Science',   2, 'field_training', 3, 6, 2, 0, 0, 2, 90, 4, v_prog_id, v_track_id, TRUE, TRUE),
        ('CSE323', 'Advanced Database Systems',              3, 'core', 3, 6, 2, 3, 0, 5, 150, 6, v_prog_id, v_track_id, TRUE, FALSE),
        ('CSE352', 'Systems Analysis & Design',              3, 'core', 3, 6, 2, 3, 0, 5, 150, 6, v_prog_id, v_track_id, TRUE, FALSE),
        ('AIE121', 'Machine Learning',                       3, 'core', 3, 6, 2, 3, 0, 5, 150, 6, v_prog_id, v_track_id, TRUE, FALSE),
        ('UC6',    'University Requirement (6)',              2, 'university_req', 3, 6, 2, 0, 0, 2, 90, 4, v_prog_id, v_track_id, TRUE, FALSE),
        ('UE3',    'Elective University (3)',                 2, 'university_elective', 3, 6, 2, 0, 0, 2, 90, 4, v_prog_id, v_track_id, TRUE, FALSE)
    ON CONFLICT (code) DO UPDATE SET
        program_id = EXCLUDED.program_id, track_id = EXCLUDED.track_id,
        category = EXCLUDED.category, plan_semester = EXCLUDED.plan_semester,
        is_pass_fail = EXCLUDED.is_pass_fail, curriculum_level = EXCLUDED.curriculum_level;

    -- Semester 7 — Core + Elective slot 1
    INSERT INTO courses (code, name, credits, category, curriculum_level, plan_semester,
                         lct_hours, lab_hours, tut_hours, contact_hours, swl_hours, ects_credits,
                         program_id, track_id, is_active, is_pass_fail)
    VALUES
        ('CSE454', 'Advanced Software Engineering',          3, 'core', 4, 7, 2, 3, 0, 5, 150, 6, v_prog_id, v_track_id, TRUE, FALSE),
        ('CSE475', 'Distributed Information Systems',        3, 'core', 4, 7, 2, 3, 0, 5, 150, 6, v_prog_id, v_track_id, TRUE, FALSE),
        ('CSE493', 'Graduation Project 1',                   2, 'core', 4, 7, 2, 0, 0, 2,  90, 4, v_prog_id, v_track_id, TRUE, TRUE),
        ('CSE313', 'Mobile Development',                     3, 'core', 4, 7, 2, 3, 0, 5, 150, 6, v_prog_id, v_track_id, TRUE, FALSE),
        ('UC7',    'University Requirement (7)',              2, 'university_req', 4, 7, 2, 0, 0, 2, 90, 4, v_prog_id, v_track_id, TRUE, FALSE)
    ON CONFLICT (code) DO UPDATE SET
        program_id = EXCLUDED.program_id, track_id = EXCLUDED.track_id,
        category = EXCLUDED.category, plan_semester = EXCLUDED.plan_semester,
        is_pass_fail = EXCLUDED.is_pass_fail, curriculum_level = EXCLUDED.curriculum_level;

    -- Semester 8 — Core + Elective slots 2, 3
    INSERT INTO courses (code, name, credits, category, curriculum_level, plan_semester,
                         lct_hours, lab_hours, tut_hours, contact_hours, swl_hours, ects_credits,
                         program_id, track_id, is_active, is_pass_fail)
    VALUES
        ('CSE363', 'Cloud Computing',                        3, 'core', 4, 8, 2, 3, 0, 5, 150, 6, v_prog_id, v_track_id, TRUE, FALSE),
        ('CSE494', 'Graduation Project 2',                   2, 'core', 4, 8, 2, 0, 0, 2,  90, 4, v_prog_id, v_track_id, TRUE, TRUE),
        ('AIE323', 'Data Mining',                            3, 'core', 4, 8, 2, 3, 0, 5, 150, 6, v_prog_id, v_track_id, TRUE, FALSE),
        ('CSE312', 'Advanced Web Programming',               3, 'core', 4, 8, 2, 3, 0, 5, 150, 6, v_prog_id, v_track_id, TRUE, FALSE)
    ON CONFLICT (code) DO UPDATE SET
        program_id = EXCLUDED.program_id, track_id = EXCLUDED.track_id,
        category = EXCLUDED.category, plan_semester = EXCLUDED.plan_semester,
        is_pass_fail = EXCLUDED.is_pass_fail, curriculum_level = EXCLUDED.curriculum_level;

    -- Elective Pool (E1/E2/E3 — appear in slots in semesters 7-8)
    INSERT INTO courses (code, name, credits, category, program_id, track_id, is_active, slot_label)
    VALUES
        ('ELE432', 'Digital Signal Processing',                    3, 'elective', v_prog_id, v_track_id, TRUE, 'E1:E3'),
        ('CSE271', 'Introduction to Parallel Computing',           3, 'elective', v_prog_id, v_track_id, TRUE, 'E1:E3'),
        ('CSE272', 'Embedded Systems',                             3, 'elective', v_prog_id, v_track_id, TRUE, 'E1:E3'),
        ('CSE281', 'Image Processing',                             3, 'elective', v_prog_id, v_track_id, TRUE, 'E1:E3'),
        ('CSE322', 'Big Data Analytics 1',                         3, 'elective', v_prog_id, v_track_id, TRUE, 'E1:E3'),
        ('CSE344', 'Introduction to Cyber Security',               3, 'elective', v_prog_id, v_track_id, TRUE, 'E1:E3'),
        ('CSE424', 'Data Warehousing',                             3, 'elective', v_prog_id, v_track_id, TRUE, 'E1:E3'),
        ('CSE426', 'Selected Topics in Data Science',              3, 'elective', v_prog_id, v_track_id, TRUE, 'E1:E3'),
        ('CSE453', 'Software Testing',                             3, 'elective', v_prog_id, v_track_id, TRUE, 'E1:E3'),
        ('CSE455', 'Selected Topics in Software Engineering',      3, 'elective', v_prog_id, v_track_id, TRUE, 'E1:E3'),
        ('CSE464', 'Internet of Things',                           3, 'elective', v_prog_id, v_track_id, TRUE, 'E1:E3'),
        ('CSE478', 'High Performance Computing',                   3, 'elective', v_prog_id, v_track_id, TRUE, 'E1:E3'),
        ('AIE231', 'Neural Networks',                              3, 'elective', v_prog_id, v_track_id, TRUE, 'E1:E3'),
        ('AIE241', 'Natural Language Processing',                  3, 'elective', v_prog_id, v_track_id, TRUE, 'E1:E3'),
        ('AIE314', 'Ai-Based Programming',                         3, 'elective', v_prog_id, v_track_id, TRUE, 'E1:E3'),
        ('AIE322', 'Advanced Machine Learning',                    3, 'elective', v_prog_id, v_track_id, TRUE, 'E1:E3'),
        ('AIE332', 'Deep Learning',                                3, 'elective', v_prog_id, v_track_id, TRUE, 'E1:E3'),
        ('AIE342', 'Advanced Methods for Data Analysis',           3, 'elective', v_prog_id, v_track_id, TRUE, 'E1:E3'),
        ('AIE343', 'Machine Learning for Text Mining',             3, 'elective', v_prog_id, v_track_id, TRUE, 'E1:E3'),
        ('AIE424', 'Intelligent Decision Support Systems',         3, 'elective', v_prog_id, v_track_id, TRUE, 'E1:E3'),
        ('AIE425', 'Intelligent Recommender Systems',              3, 'elective', v_prog_id, v_track_id, TRUE, 'E1:E3'),
        ('CSE467', 'Client/Server Technologies & Applications',    3, 'elective', v_prog_id, v_track_id, TRUE, 'E1:E3')
    ON CONFLICT (code) DO UPDATE SET
        program_id = EXCLUDED.program_id, track_id = EXCLUDED.track_id,
        category = EXCLUDED.category, slot_label = EXCLUDED.slot_label;

    RAISE NOTICE 'Course catalog inserted/updated successfully.';
END $$;

-- ============================================================
-- STEP 2: PREREQUISITES
-- Source: Courses_Pre-requisites_Core___Elective_.pdf
-- ============================================================

DO $$
DECLARE v_prog_id BIGINT;
BEGIN
    SELECT id INTO v_prog_id FROM academic_programs WHERE code = 'CS';

    -- CSE015 ← CSE014
    INSERT INTO course_prerequisites (course_id, prerequisite_id)
    SELECT c.id, p.id FROM courses c, courses p WHERE c.code='CSE015' AND p.code='CSE014'
    ON CONFLICT DO NOTHING;

    -- CSE111 ← CSE015
    INSERT INTO course_prerequisites (course_id, prerequisite_id)
    SELECT c.id, p.id FROM courses c, courses p WHERE c.code='CSE111' AND p.code='CSE015'
    ON CONFLICT DO NOTHING;

    -- CSE112 ← CSE111
    INSERT INTO course_prerequisites (course_id, prerequisite_id)
    SELECT c.id, p.id FROM courses c, courses p WHERE c.code='CSE112' AND p.code='CSE111'
    ON CONFLICT DO NOTHING;

    -- CSE132 ← CSE131
    INSERT INTO course_prerequisites (course_id, prerequisite_id)
    SELECT c.id, p.id FROM courses c, courses p WHERE c.code='CSE132' AND p.code='CSE131'
    ON CONFLICT DO NOTHING;

    -- CSE233 ← CSE111
    INSERT INTO course_prerequisites (course_id, prerequisite_id)
    SELECT c.id, p.id FROM courses c, courses p WHERE c.code='CSE233' AND p.code='CSE111'
    ON CONFLICT DO NOTHING;

    -- CSE233 ← CSE132
    INSERT INTO course_prerequisites (course_id, prerequisite_id)
    SELECT c.id, p.id FROM courses c, courses p WHERE c.code='CSE233' AND p.code='CSE132'
    ON CONFLICT DO NOTHING;

    -- CSE212 ← CSE015 (Theory of Computation & Compilers)
    INSERT INTO course_prerequisites (course_id, prerequisite_id)
    SELECT c.id, p.id FROM courses c, courses p WHERE c.code='CSE212' AND p.code='CSE015'
    ON CONFLICT DO NOTHING;

    -- CSE241 ← CSE112
    INSERT INTO course_prerequisites (course_id, prerequisite_id)
    SELECT c.id, p.id FROM courses c, courses p WHERE c.code='CSE241' AND p.code='CSE112'
    ON CONFLICT DO NOTHING;

    -- CSE251 ← CSE015 (Software Engineering)
    INSERT INTO course_prerequisites (course_id, prerequisite_id)
    SELECT c.id, p.id FROM courses c, courses p WHERE c.code='CSE251' AND p.code='CSE015'
    ON CONFLICT DO NOTHING;

    -- AIE121 ← AIE111
    INSERT INTO course_prerequisites (course_id, prerequisite_id)
    SELECT c.id, p.id FROM courses c, courses p WHERE c.code='AIE121' AND p.code='AIE111'
    ON CONFLICT DO NOTHING;

    -- CSE281 ← MAT212  (elective: Image Processing)
    INSERT INTO course_prerequisites (course_id, prerequisite_id)
    SELECT c.id, p.id FROM courses c, courses p WHERE c.code='CSE281' AND p.code='MAT212'
    ON CONFLICT DO NOTHING;

    -- CSE323 ← CSE221
    INSERT INTO course_prerequisites (course_id, prerequisite_id)
    SELECT c.id, p.id FROM courses c, courses p WHERE c.code='CSE323' AND p.code='CSE221'
    ON CONFLICT DO NOTHING;

    -- CSE352 ← CSE251
    INSERT INTO course_prerequisites (course_id, prerequisite_id)
    SELECT c.id, p.id FROM courses c, courses p WHERE c.code='CSE352' AND p.code='CSE251'
    ON CONFLICT DO NOTHING;

    -- CSE454 ← CSE251
    INSERT INTO course_prerequisites (course_id, prerequisite_id)
    SELECT c.id, p.id FROM courses c, courses p WHERE c.code='CSE454' AND p.code='CSE251'
    ON CONFLICT DO NOTHING;

    -- CSE313 ← CSE015 (Mobile Development — derived from post-req list)
    INSERT INTO course_prerequisites (course_id, prerequisite_id)
    SELECT c.id, p.id FROM courses c, courses p WHERE c.code='CSE313' AND p.code='CSE015'
    ON CONFLICT DO NOTHING;

    -- CSE312 ← CSE211
    INSERT INTO course_prerequisites (course_id, prerequisite_id)
    SELECT c.id, p.id FROM courses c, courses p WHERE c.code='CSE312' AND p.code='CSE211'
    ON CONFLICT DO NOTHING;

    -- CSE363 ← CSE261 (Cloud Computing)
    INSERT INTO course_prerequisites (course_id, prerequisite_id)
    SELECT c.id, p.id FROM courses c, courses p WHERE c.code='CSE363' AND p.code='CSE261'
    ON CONFLICT DO NOTHING;

    -- AIE323 ← AIE121 (Data Mining)
    INSERT INTO course_prerequisites (course_id, prerequisite_id)
    SELECT c.id, p.id FROM courses c, courses p WHERE c.code='AIE323' AND p.code='AIE121'
    ON CONFLICT DO NOTHING;

    -- CSE292 ← CSE191 (Field Training 2 ← Field Training 1)
    INSERT INTO course_prerequisites (course_id, prerequisite_id)
    SELECT c.id, p.id FROM courses c, courses p WHERE c.code='CSE292' AND p.code='CSE191'
    ON CONFLICT DO NOTHING;

    -- CSE494 ← CSE493 (GP2 ← GP1)
    INSERT INTO course_prerequisites (course_id, prerequisite_id)
    SELECT c.id, p.id FROM courses c, courses p WHERE c.code='CSE494' AND p.code='CSE493'
    ON CONFLICT DO NOTHING;

    -- ELECTIVE prerequisites
    -- CSE382 ← CSE014 (Computer Graphics)
    -- CSE467 ← CSE112 + CSE221
    INSERT INTO course_prerequisites (course_id, prerequisite_id)
    SELECT c.id, p.id FROM courses c, courses p WHERE c.code='CSE467' AND p.code='CSE112'
    ON CONFLICT DO NOTHING;
    INSERT INTO course_prerequisites (course_id, prerequisite_id)
    SELECT c.id, p.id FROM courses c, courses p WHERE c.code='CSE467' AND p.code='CSE221'
    ON CONFLICT DO NOTHING;

    -- CSE363 (already listed above as core) also requires CSE261 ✓

    -- CSE344 ← CSE233 + CSE261
    INSERT INTO course_prerequisites (course_id, prerequisite_id)
    SELECT c.id, p.id FROM courses c, courses p WHERE c.code='CSE344' AND p.code='CSE233'
    ON CONFLICT DO NOTHING;
    INSERT INTO course_prerequisites (course_id, prerequisite_id)
    SELECT c.id, p.id FROM courses c, courses p WHERE c.code='CSE344' AND p.code='CSE261'
    ON CONFLICT DO NOTHING;

    -- AIE231 ← AIE121 (Neural Networks)
    INSERT INTO course_prerequisites (course_id, prerequisite_id)
    SELECT c.id, p.id FROM courses c, courses p WHERE c.code='AIE231' AND p.code='AIE121'
    ON CONFLICT DO NOTHING;

    -- AIE241 ← AIE111 (NLP)
    INSERT INTO course_prerequisites (course_id, prerequisite_id)
    SELECT c.id, p.id FROM courses c, courses p WHERE c.code='AIE241' AND p.code='AIE111'
    ON CONFLICT DO NOTHING;

    -- AIE322 ← AIE121 (Advanced ML)
    INSERT INTO course_prerequisites (course_id, prerequisite_id)
    SELECT c.id, p.id FROM courses c, courses p WHERE c.code='AIE322' AND p.code='AIE121'
    ON CONFLICT DO NOTHING;

    -- AIE332 ← AIE231 (Deep Learning)
    INSERT INTO course_prerequisites (course_id, prerequisite_id)
    SELECT c.id, p.id FROM courses c, courses p WHERE c.code='AIE332' AND p.code='AIE231'
    ON CONFLICT DO NOTHING;

    -- AIE342 ← AIE323 (Advanced Data Analysis)
    INSERT INTO course_prerequisites (course_id, prerequisite_id)
    SELECT c.id, p.id FROM courses c, courses p WHERE c.code='AIE342' AND p.code='AIE323'
    ON CONFLICT DO NOTHING;

    -- AIE343 ← AIE323 (ML for Text Mining)
    INSERT INTO course_prerequisites (course_id, prerequisite_id)
    SELECT c.id, p.id FROM courses c, courses p WHERE c.code='AIE343' AND p.code='AIE323'
    ON CONFLICT DO NOTHING;

    -- AIE424 ← AIE323 (Intelligent Decision Support)
    INSERT INTO course_prerequisites (course_id, prerequisite_id)
    SELECT c.id, p.id FROM courses c, courses p WHERE c.code='AIE424' AND p.code='AIE323'
    ON CONFLICT DO NOTHING;

    -- AIE425 ← AIE323 (Intelligent Recommender Systems)
    INSERT INTO course_prerequisites (course_id, prerequisite_id)
    SELECT c.id, p.id FROM courses c, courses p WHERE c.code='AIE425' AND p.code='AIE323'
    ON CONFLICT DO NOTHING;

    -- CSE281 Image Processing (elective) ← MAT212 (already above)
    -- CSE383 ← CSE281
    INSERT INTO course_prerequisites (course_id, prerequisite_id)
    SELECT c.id, p.id FROM courses c, courses p WHERE c.code='CSE383' AND p.code='CSE281'
    ON CONFLICT DO NOTHING;

    -- AIE444 ← AIE241
    INSERT INTO course_prerequisites (course_id, prerequisite_id)
    SELECT c.id, p.id FROM courses c, courses p WHERE c.code='AIE444' AND p.code='AIE241'
    ON CONFLICT DO NOTHING;

    -- CSE424 ← CSE323 (Data Warehousing)
    INSERT INTO course_prerequisites (course_id, prerequisite_id)
    SELECT c.id, p.id FROM courses c, courses p WHERE c.code='CSE424' AND p.code='CSE323'
    ON CONFLICT DO NOTHING;

    RAISE NOTICE 'Prerequisites seeded.';
END $$;

-- ============================================================
-- STEP 3: POST-REQUISITES
-- Source: Important_Courses_Post-requisite_for_each_course.pdf
-- ============================================================

DO $$
BEGIN
    -- CSE014 → CSE015 (C), CSE212 (C)
    INSERT INTO course_postrequisites (course_id, postreq_id, unlock_type)
    SELECT c.id, p.id, 'C' FROM courses c, courses p WHERE c.code='CSE014' AND p.code='CSE015'
    ON CONFLICT DO NOTHING;
    INSERT INTO course_postrequisites (course_id, postreq_id, unlock_type)
    SELECT c.id, p.id, 'C' FROM courses c, courses p WHERE c.code='CSE014' AND p.code='CSE212'
    ON CONFLICT DO NOTHING;

    -- CSE015 → CSE111 (C), CSE251 (C), CSE313 (C)
    INSERT INTO course_postrequisites (course_id, postreq_id, unlock_type)
    SELECT c.id, p.id, 'C' FROM courses c, courses p WHERE c.code='CSE015' AND p.code='CSE111'
    ON CONFLICT DO NOTHING;
    INSERT INTO course_postrequisites (course_id, postreq_id, unlock_type)
    SELECT c.id, p.id, 'C' FROM courses c, courses p WHERE c.code='CSE015' AND p.code='CSE251'
    ON CONFLICT DO NOTHING;
    INSERT INTO course_postrequisites (course_id, postreq_id, unlock_type)
    SELECT c.id, p.id, 'C' FROM courses c, courses p WHERE c.code='CSE015' AND p.code='CSE313'
    ON CONFLICT DO NOTHING;

    -- CSE111 → CSE112 (C), CSE233 (C)
    INSERT INTO course_postrequisites (course_id, postreq_id, unlock_type)
    SELECT c.id, p.id, 'C' FROM courses c, courses p WHERE c.code='CSE111' AND p.code='CSE112'
    ON CONFLICT DO NOTHING;
    INSERT INTO course_postrequisites (course_id, postreq_id, unlock_type)
    SELECT c.id, p.id, 'C' FROM courses c, courses p WHERE c.code='CSE111' AND p.code='CSE233'
    ON CONFLICT DO NOTHING;

    -- CSE131 → CSE132 (C)
    INSERT INTO course_postrequisites (course_id, postreq_id, unlock_type)
    SELECT c.id, p.id, 'C' FROM courses c, courses p WHERE c.code='CSE131' AND p.code='CSE132'
    ON CONFLICT DO NOTHING;

    -- CSE191 → CSE292 (C)
    INSERT INTO course_postrequisites (course_id, postreq_id, unlock_type)
    SELECT c.id, p.id, 'C' FROM courses c, courses p WHERE c.code='CSE191' AND p.code='CSE292'
    ON CONFLICT DO NOTHING;

    -- MAT212 → CSE281 (E)
    INSERT INTO course_postrequisites (course_id, postreq_id, unlock_type)
    SELECT c.id, p.id, 'E' FROM courses c, courses p WHERE c.code='MAT212' AND p.code='CSE281'
    ON CONFLICT DO NOTHING;

    -- CSE112 → CSE241 (C), CSE467 (E)
    INSERT INTO course_postrequisites (course_id, postreq_id, unlock_type)
    SELECT c.id, p.id, 'C' FROM courses c, courses p WHERE c.code='CSE112' AND p.code='CSE241'
    ON CONFLICT DO NOTHING;
    INSERT INTO course_postrequisites (course_id, postreq_id, unlock_type)
    SELECT c.id, p.id, 'E' FROM courses c, courses p WHERE c.code='CSE112' AND p.code='CSE467'
    ON CONFLICT DO NOTHING;

    -- CSE132 → CSE233 (C)
    INSERT INTO course_postrequisites (course_id, postreq_id, unlock_type)
    SELECT c.id, p.id, 'C' FROM courses c, courses p WHERE c.code='CSE132' AND p.code='CSE233'
    ON CONFLICT DO NOTHING;

    -- CSE221 → CSE323 (C), CSE467 (E)
    INSERT INTO course_postrequisites (course_id, postreq_id, unlock_type)
    SELECT c.id, p.id, 'C' FROM courses c, courses p WHERE c.code='CSE221' AND p.code='CSE323'
    ON CONFLICT DO NOTHING;
    INSERT INTO course_postrequisites (course_id, postreq_id, unlock_type)
    SELECT c.id, p.id, 'E' FROM courses c, courses p WHERE c.code='CSE221' AND p.code='CSE467'
    ON CONFLICT DO NOTHING;

    -- CSE251 → CSE352 (C), CSE454 (C)
    INSERT INTO course_postrequisites (course_id, postreq_id, unlock_type)
    SELECT c.id, p.id, 'C' FROM courses c, courses p WHERE c.code='CSE251' AND p.code='CSE352'
    ON CONFLICT DO NOTHING;
    INSERT INTO course_postrequisites (course_id, postreq_id, unlock_type)
    SELECT c.id, p.id, 'C' FROM courses c, courses p WHERE c.code='CSE251' AND p.code='CSE454'
    ON CONFLICT DO NOTHING;

    -- CSE211 → CSE312 (C)
    INSERT INTO course_postrequisites (course_id, postreq_id, unlock_type)
    SELECT c.id, p.id, 'C' FROM courses c, courses p WHERE c.code='CSE211' AND p.code='CSE312'
    ON CONFLICT DO NOTHING;

    -- CSE233 → CSE344 (E)
    INSERT INTO course_postrequisites (course_id, postreq_id, unlock_type)
    SELECT c.id, p.id, 'E' FROM courses c, courses p WHERE c.code='CSE233' AND p.code='CSE344'
    ON CONFLICT DO NOTHING;

    -- CSE261 → CSE344 (E), CSE363 (C)
    INSERT INTO course_postrequisites (course_id, postreq_id, unlock_type)
    SELECT c.id, p.id, 'E' FROM courses c, courses p WHERE c.code='CSE261' AND p.code='CSE344'
    ON CONFLICT DO NOTHING;
    INSERT INTO course_postrequisites (course_id, postreq_id, unlock_type)
    SELECT c.id, p.id, 'C' FROM courses c, courses p WHERE c.code='CSE261' AND p.code='CSE363'
    ON CONFLICT DO NOTHING;

    -- AIE111 → AIE121 (C), AIE241 (E)
    INSERT INTO course_postrequisites (course_id, postreq_id, unlock_type)
    SELECT c.id, p.id, 'C' FROM courses c, courses p WHERE c.code='AIE111' AND p.code='AIE121'
    ON CONFLICT DO NOTHING;
    INSERT INTO course_postrequisites (course_id, postreq_id, unlock_type)
    SELECT c.id, p.id, 'E' FROM courses c, courses p WHERE c.code='AIE111' AND p.code='AIE241'
    ON CONFLICT DO NOTHING;

    -- CSE323 → CSE424 (E)
    INSERT INTO course_postrequisites (course_id, postreq_id, unlock_type)
    SELECT c.id, p.id, 'E' FROM courses c, courses p WHERE c.code='CSE323' AND p.code='CSE424'
    ON CONFLICT DO NOTHING;

    -- AIE121 → AIE323 (C), AIE231 (E), AIE322 (E)
    INSERT INTO course_postrequisites (course_id, postreq_id, unlock_type)
    SELECT c.id, p.id, 'C' FROM courses c, courses p WHERE c.code='AIE121' AND p.code='AIE323'
    ON CONFLICT DO NOTHING;
    INSERT INTO course_postrequisites (course_id, postreq_id, unlock_type)
    SELECT c.id, p.id, 'E' FROM courses c, courses p WHERE c.code='AIE121' AND p.code='AIE231'
    ON CONFLICT DO NOTHING;
    INSERT INTO course_postrequisites (course_id, postreq_id, unlock_type)
    SELECT c.id, p.id, 'E' FROM courses c, courses p WHERE c.code='AIE121' AND p.code='AIE322'
    ON CONFLICT DO NOTHING;

    -- CSE493 → CSE494 (C)
    INSERT INTO course_postrequisites (course_id, postreq_id, unlock_type)
    SELECT c.id, p.id, 'C' FROM courses c, courses p WHERE c.code='CSE493' AND p.code='CSE494'
    ON CONFLICT DO NOTHING;

    -- AIE323 → AIE343 (E), AIE424 (E), AIE425 (E), AIE342 (E)
    INSERT INTO course_postrequisites (course_id, postreq_id, unlock_type)
    SELECT c.id, p.id, 'E' FROM courses c, courses p WHERE c.code='AIE323' AND p.code='AIE343'
    ON CONFLICT DO NOTHING;
    INSERT INTO course_postrequisites (course_id, postreq_id, unlock_type)
    SELECT c.id, p.id, 'E' FROM courses c, courses p WHERE c.code='AIE323' AND p.code='AIE424'
    ON CONFLICT DO NOTHING;
    INSERT INTO course_postrequisites (course_id, postreq_id, unlock_type)
    SELECT c.id, p.id, 'E' FROM courses c, courses p WHERE c.code='AIE323' AND p.code='AIE425'
    ON CONFLICT DO NOTHING;
    INSERT INTO course_postrequisites (course_id, postreq_id, unlock_type)
    SELECT c.id, p.id, 'E' FROM courses c, courses p WHERE c.code='AIE323' AND p.code='AIE342'
    ON CONFLICT DO NOTHING;

    -- AIE231 → AIE332 (E: Deep Learning)
    INSERT INTO course_postrequisites (course_id, postreq_id, unlock_type)
    SELECT c.id, p.id, 'E' FROM courses c, courses p WHERE c.code='AIE231' AND p.code='AIE332'
    ON CONFLICT DO NOTHING;

    -- AIE241 → AIE444 (E)
    INSERT INTO course_postrequisites (course_id, postreq_id, unlock_type)
    SELECT c.id, p.id, 'E' FROM courses c, courses p WHERE c.code='AIE241' AND p.code='AIE444'
    ON CONFLICT DO NOTHING;

    RAISE NOTICE 'Post-requisites seeded.';
END $$;

-- ============================================================
-- STEP 4: SPECIAL ELIGIBILITY RULES
-- ============================================================

-- CSE493 Graduation Project 1 requires "Senior Standing"
-- (= completed ≥ 90 credit hours based on the study plan position)
INSERT INTO course_eligibility_rules (course_id, rule_type, rule_value, rule_text)
SELECT c.id, 'min_credits_earned', 90, 'Senior Standing: must have earned at least 90 credit hours'
FROM courses c WHERE c.code = 'CSE493'
ON CONFLICT DO NOTHING;

-- CSE292 Field Training 2 requires Field Training 1 passed
INSERT INTO course_eligibility_rules (course_id, rule_type, rule_text)
SELECT c.id, 'completed_course', 'Must have completed CSE191 (Field Training 1)'
FROM courses c WHERE c.code = 'CSE292'
ON CONFLICT DO NOTHING;

-- ============================================================
-- END OF FILE
-- ============================================================
