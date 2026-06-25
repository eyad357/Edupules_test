-- ============================================================
-- EduGuard AI — Seed Data v4.0 (Production-Grade)
-- ============================================================
-- Changes from v3.0:
--   1. REMOVED all hard-coded sequential IDs (professor_id, advisor_id,
--      student_id, course_id, quiz_id, plan_id, etc.). Every INSERT now
--      resolves real IDs via CTE + RETURNING, keyed on natural keys
--      (email, course code). The script no longer assumes that the Nth
--      row inserted got primary key N — it looks the row up explicitly.
--   2. Arabic names (Latin script) replacing the placeholder English
--      names, to match the target university's actual student/staff
--      population. Same headcounts, same departments, same grades,
--      same attendance/risk patterns as v3.0 — only identity values
--      and the ID-resolution mechanism changed.
--   3. TRUNCATE ... RESTART IDENTITY CASCADE ensures every SERIAL/
--      BIGSERIAL sequence in this script's table list starts at 1
--      on every re-run, so the script is fully idempotent.
-- ============================================================

-- ============================================================
-- CLEANUP (safe re-run)
-- ============================================================
TRUNCATE TABLE
    announcements, activity_logs, notifications,
    intervention_actions, intervention_plans,
    risk_assessments, attendances, enrollments,
    quizzes, courses,
    teaching_assistants, advisors, professors, students,
    users, departments
RESTART IDENTITY CASCADE;


-- ============================================================
-- DEPARTMENTS
-- ============================================================
INSERT INTO departments (name, code, description) VALUES
('Computer Science',          'CS',  'Department of Computer Science and Software Engineering'),
('Artificial Intelligence',   'AI',  'Department of AI and Machine Learning'),
('Information Systems',       'IS',  'Department of Information Systems and Data Management'),
('Computer Networks',         'NET', 'Department of Computer Networks and Communications'),
('Software Engineering',      'SE',  'Department of Software Engineering and Quality'),
('Cybersecurity',             'SEC', 'Department of Cybersecurity and Digital Forensics'),
('Data Science',              'DS',  'Department of Data Science and Analytics'),
('Human-Computer Interaction','HCI', 'Department of HCI and UX Design');


-- ============================================================
-- USERS  (all roles, single statement, natural key = email)
-- All passwords = "password123"
-- ============================================================
INSERT INTO users (name, email, hashed_password, role) VALUES
-- Admins
('Dr. Mona Khalil',        'mona.khalil@eduguard.edu', '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin'),
('System Administrator',   'sysadmin@eduguard.edu',    '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin'),
-- Professors
('Prof. Ahmed El-Sayed',      'a.elsayed@eduguard.edu',     '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'professor'),  -- dept CS
('Prof. Mona Abdel-Rahman',   'm.abdelrahman@eduguard.edu', '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'professor'),  -- dept AI
('Prof. Hassan Ibrahim',      'h.ibrahim@eduguard.edu',     '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'professor'),  -- dept IS
('Prof. Nour El-Din',         'n.eldin@eduguard.edu',       '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'professor'),  -- dept NET
('Prof. Tarek Mahmoud',       't.mahmoud@eduguard.edu',     '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'professor'),  -- dept SE
('Prof. Salma Fathy',         's.fathy@eduguard.edu',       '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'professor'),  -- dept SEC
('Prof. Khaled Rashad',       'k.rashad@eduguard.edu',      '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'professor'),  -- dept DS
-- Advisors
('Dr. Yasser Mostafa', 'y.mostafa@eduguard.edu', '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'advisor'),
('Dr. Heba Gamal',     'h.gamal@eduguard.edu',   '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'advisor'),
-- Teaching Assistants
('Omar Adel',  'ta.omar@eduguard.edu', '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'ta'),
('Rana Sherif','ta.rana@eduguard.edu', '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'ta'),
-- Students (21) — Arabic names, Latin script
('Aya Mohamed',     'aya.mohamed@student.eduguard.edu',   '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),  -- CS
('Bassem Saeed',    'bassem.saeed@student.eduguard.edu',  '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),  -- CS
('Karim Adly',      'karim.adly@student.eduguard.edu',    '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),  -- CS
('Donia Hamdy',     'donia.hamdy@student.eduguard.edu',   '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),  -- AI
('Eman Saber',      'eman.saber@student.eduguard.edu',    '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),  -- AI
('Fady Lotfy',      'fady.lotfy@student.eduguard.edu',    '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),  -- IS
('Ghada Kamal',     'ghada.kamal@student.eduguard.edu',   '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),  -- NET
('Hady Younis',     'hady.younis@student.eduguard.edu',   '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),  -- SE
('Inas Farouk',     'inas.farouk@student.eduguard.edu',   '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),  -- SEC
('Gamal Taha',      'gamal.taha@student.eduguard.edu',    '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),  -- DS
('Kholoud Naser',   'kholoud.naser@student.eduguard.edu', '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),  -- CS
('Loay Sami',       'loay.sami@student.eduguard.edu',     '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),  -- AI
('Mariam Tawfik',   'mariam.tawfik@student.eduguard.edu', '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),  -- CS
('Nabil Ezzat',     'nabil.ezzat@student.eduguard.edu',   '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),  -- SE
('Ola Reda',        'ola.reda@student.eduguard.edu',      '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),  -- SEC
('Peter Maher',     'peter.maher@student.eduguard.edu',   '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),  -- NET
('Qassem Hosny',    'qassem.hosny@student.eduguard.edu',  '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),  -- DS
('Rawan Shafik',    'rawan.shafik@student.eduguard.edu',  '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),  -- IS
('Sherif Anwar',    'sherif.anwar@student.eduguard.edu',  '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),  -- AI
('Tarek Nabil',     'tarek.nabil@student.eduguard.edu',   '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),  -- CS
('Yasmin Fouad',    'yasmin.fouad@student.eduguard.edu',  '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student');  -- SEC


-- ============================================================
-- ROLE RECORDS  (all resolved via email/code lookups — no hard-coded IDs)
-- ============================================================

-- Professors
INSERT INTO professors (user_id, department_id, department, title, specialization, office_location, office_hours)
SELECT u.id, d.id, d.name, v.title, v.specialization, v.office_location, v.office_hours
FROM (VALUES
    ('a.elsayed@eduguard.edu',     'CS',  'Associate Professor', 'Algorithms & Data Structures',    'CS Building, Room 305', 'Mon/Wed 2-4 PM'),
    ('m.abdelrahman@eduguard.edu', 'AI',  'Professor',           'Machine Learning & Deep Learning','CS Building, Room 210', 'Tue/Thu 10-12 PM'),
    ('h.ibrahim@eduguard.edu',     'IS',  'Assistant Professor', 'Database Systems & Analytics',    'IS Building, Room 102', 'Mon/Fri 1-3 PM'),
    ('n.eldin@eduguard.edu',       'NET', 'Professor',           'Network Protocols & Security',    'NET Lab, Room 401',     'Wed/Thu 3-5 PM'),
    ('t.mahmoud@eduguard.edu',     'SE',  'Associate Professor', 'Software Architecture & DevOps',  'SE Building, Room 215', 'Tue/Thu 2-4 PM'),
    ('s.fathy@eduguard.edu',       'SEC', 'Assistant Professor', 'Ethical Hacking & Forensics',     'SEC Lab, Room 118',     'Mon/Wed/Fri 11-12 PM'),
    ('k.rashad@eduguard.edu',      'DS',  'Associate Professor', 'Statistical Learning & Viz',      'DS Building, Room 330', 'Mon/Wed 3-5 PM')
) AS v(email, dept_code, title, specialization, office_location, office_hours)
JOIN users u       ON u.email = v.email
JOIN departments d ON d.code  = v.dept_code;

-- Advisors
INSERT INTO advisors (user_id, department_id, specialization, max_students)
SELECT u.id, d.id, v.specialization, v.max_students
FROM (VALUES
    ('y.mostafa@eduguard.edu', 'CS', 'CS & AI Counseling',        35),
    ('h.gamal@eduguard.edu',   'IS', 'IS & Networks Counseling',  30)
) AS v(email, dept_code, specialization, max_students)
JOIN users u       ON u.email = v.email
JOIN departments d ON d.code  = v.dept_code;

-- Teaching Assistants  (linked to their supervising professor by email)
INSERT INTO teaching_assistants (user_id, professor_id, department_id)
SELECT u.id, p.id, d.id
FROM (VALUES
    ('ta.omar@eduguard.edu', 'a.elsayed@eduguard.edu',     'CS'),
    ('ta.rana@eduguard.edu', 'm.abdelrahman@eduguard.edu', 'AI')
) AS v(ta_email, prof_email, dept_code)
JOIN users u            ON u.email = v.ta_email
JOIN users prof_user     ON prof_user.email = v.prof_email
JOIN professors p        ON p.user_id = prof_user.id
JOIN departments d       ON d.code = v.dept_code;

-- Students  (advisor resolved by advisor's user email, department by code)
INSERT INTO students (user_id, student_number, department_id, major, year, gpa, enrollment_date, advisor_id, is_scholarship)
SELECT u.id, v.student_number, d.id, v.major, v.year, v.gpa, v.enrollment_date::date, a.id, v.is_scholarship
FROM (VALUES
    -- CS (5 students)
    ('aya.mohamed@student.eduguard.edu',    'STU-2022-001', 'CS',  'Computer Science', 3, 3.80, '2022-09-01', 'y.mostafa@eduguard.edu', TRUE),
    ('bassem.saeed@student.eduguard.edu',   'STU-2023-002', 'CS',  'Computer Science', 2, 2.10, '2023-09-01', 'y.mostafa@eduguard.edu', FALSE),
    ('karim.adly@student.eduguard.edu',     'STU-2022-003', 'CS',  'Computer Science', 3, 3.50, '2022-09-01', 'y.mostafa@eduguard.edu', FALSE),
    ('kholoud.naser@student.eduguard.edu',  'STU-2023-011', 'CS',  'Computer Science', 2, 2.70, '2023-09-01', 'y.mostafa@eduguard.edu', FALSE),
    ('mariam.tawfik@student.eduguard.edu',  'STU-2022-013', 'CS',  'Computer Science', 3, 3.60, '2022-09-01', 'y.mostafa@eduguard.edu', FALSE),
    ('tarek.nabil@student.eduguard.edu',    'STU-2024-020', 'CS',  'Computer Science', 1, 3.10, '2024-09-01', 'y.mostafa@eduguard.edu', FALSE),
    -- AI (4 students)
    ('donia.hamdy@student.eduguard.edu',    'STU-2024-004', 'AI',  'Artificial Intelligence', 1, 1.80, '2024-09-01', 'y.mostafa@eduguard.edu', FALSE),
    ('eman.saber@student.eduguard.edu',     'STU-2022-005', 'AI',  'Artificial Intelligence', 3, 3.20, '2022-09-01', 'y.mostafa@eduguard.edu', FALSE),
    ('loay.sami@student.eduguard.edu',      'STU-2023-012', 'AI',  'Artificial Intelligence', 2, 2.40, '2023-09-01', 'y.mostafa@eduguard.edu', FALSE),
    ('sherif.anwar@student.eduguard.edu',   'STU-2023-019', 'AI',  'Artificial Intelligence', 2, 2.95, '2023-09-01', 'y.mostafa@eduguard.edu', FALSE),
    -- IS (2 students)
    ('fady.lotfy@student.eduguard.edu',     'STU-2023-006', 'IS',  'Information Systems', 2, 3.82, '2023-09-01', 'h.gamal@eduguard.edu', FALSE),
    ('rawan.shafik@student.eduguard.edu',   'STU-2022-018', 'IS',  'Information Systems', 3, 2.50, '2022-09-01', 'h.gamal@eduguard.edu', FALSE),
    -- NET (2 students)
    ('ghada.kamal@student.eduguard.edu',    'STU-2023-007', 'NET', 'Computer Networks', 2, 2.24, '2023-09-01', 'h.gamal@eduguard.edu', FALSE),
    ('peter.maher@student.eduguard.edu',    'STU-2022-016', 'NET', 'Computer Networks', 3, 1.70, '2022-09-01', 'h.gamal@eduguard.edu', FALSE),
    -- SE (2 students)
    ('hady.younis@student.eduguard.edu',    'STU-2021-008', 'SE',  'Software Engineering', 4, 1.84, '2021-09-01', 'h.gamal@eduguard.edu', FALSE),
    ('nabil.ezzat@student.eduguard.edu',    'STU-2023-014', 'SE',  'Software Engineering', 2, 2.90, '2023-09-01', 'h.gamal@eduguard.edu', FALSE),
    -- SEC (3 students)
    ('inas.farouk@student.eduguard.edu',    'STU-2022-009', 'SEC', 'Cybersecurity', 3, 3.26, '2022-09-01', 'h.gamal@eduguard.edu', FALSE),
    ('ola.reda@student.eduguard.edu',       'STU-2023-015', 'SEC', 'Cybersecurity', 2, 2.80, '2023-09-01', 'h.gamal@eduguard.edu', FALSE),
    ('yasmin.fouad@student.eduguard.edu',   'STU-2024-021', 'SEC', 'Cybersecurity', 1, 1.95, '2024-09-01', 'h.gamal@eduguard.edu', FALSE),
    -- DS (2 students)
    ('gamal.taha@student.eduguard.edu',     'STU-2021-010', 'DS',  'Data Science', 4, 3.22, '2021-09-01', 'y.mostafa@eduguard.edu', FALSE),
    ('qassem.hosny@student.eduguard.edu',   'STU-2023-017', 'DS',  'Data Science', 2, 2.45, '2023-09-01', 'y.mostafa@eduguard.edu', FALSE)
    -- HCI: intentionally 0 students (new department, not yet active)
) AS v(email, student_number, dept_code, major, year, gpa, enrollment_date, advisor_email, is_scholarship)
JOIN users u            ON u.email = v.email
JOIN departments d      ON d.code  = v.dept_code
JOIN users advisor_user ON advisor_user.email = v.advisor_email
JOIN advisors a         ON a.user_id = advisor_user.id;


-- ============================================================
-- COURSES  (professor resolved by email, department by code)
-- ============================================================
INSERT INTO courses (code, name, description, credits, semester, year, professor_id, department_id, max_students)
SELECT v.code, v.name, v.description, v.credits, v.semester, v.year, p.id, d.id, v.max_students
FROM (VALUES
    -- Prof Ahmed El-Sayed — CS
    ('CS301',  'Advanced Algorithms',      'Algorithm design, complexity, graph theory',       3, 'Fall',   2025, 'a.elsayed@eduguard.edu',     'CS',  40),
    ('CS201',  'Data Structures',          'Fundamental data structures and applications',     3, 'Fall',   2025, 'a.elsayed@eduguard.edu',     'CS',  40),
    ('CS101',  'Intro to Programming',     'Python fundamentals, OOP',                         3, 'Spring', 2025, 'a.elsayed@eduguard.edu',     'CS',  60),
    -- Prof Mona Abdel-Rahman — AI
    ('AI401',  'Machine Learning',         'Supervised and unsupervised learning',             4, 'Fall',   2025, 'm.abdelrahman@eduguard.edu', 'AI',  35),
    ('AI301',  'Neural Networks',          'Deep learning architectures',                      3, 'Fall',   2025, 'm.abdelrahman@eduguard.edu', 'AI',  30),
    -- Prof Hassan Ibrahim — IS
    ('IS201',  'Database Systems',         'SQL, NoSQL, data modeling',                        3, 'Fall',   2025, 'h.ibrahim@eduguard.edu',     'IS',  45),
    ('IS301',  'Business Intelligence',    'Data warehousing and reporting',                   3, 'Fall',   2025, 'h.ibrahim@eduguard.edu',     'IS',  35),
    -- Prof Nour El-Din — Networks
    ('NET301', 'Computer Networks',        'TCP/IP, routing protocols',                        3, 'Fall',   2025, 'n.eldin@eduguard.edu',       'NET', 40),
    ('NET401', 'Network Security',         'Firewalls, VPNs, intrusion detection',             3, 'Fall',   2025, 'n.eldin@eduguard.edu',       'NET', 30),
    -- Prof Tarek Mahmoud — SE
    ('SE301',  'Software Architecture',    'Design patterns, microservices',                   3, 'Fall',   2025, 't.mahmoud@eduguard.edu',     'SE',  35),
    ('SE101',  'Software Foundations',     'SDLC, agile, version control',                     2, 'Spring', 2025, 't.mahmoud@eduguard.edu',     'SE',  50),
    -- Prof Salma Fathy — SEC
    ('SEC301', 'Ethical Hacking',          'Penetration testing and vulnerability assessment', 3, 'Fall',   2025, 's.fathy@eduguard.edu',       'SEC', 30),
    ('SEC201', 'Cryptography',             'Encryption algorithms and PKI',                    3, 'Fall',   2025, 's.fathy@eduguard.edu',       'SEC', 35),
    -- Prof Khaled Rashad — DS
    ('DS301',  'Data Science Fundamentals','Statistics, Python, data pipelines',               3, 'Fall',   2025, 'k.rashad@eduguard.edu',      'DS',  40),
    ('DS401',  'Machine Learning for DS',  'Applied ML for data science workflows',            3, 'Fall',   2025, 'k.rashad@eduguard.edu',      'DS',  35)
) AS v(code, name, description, credits, semester, year, prof_email, dept_code, max_students)
JOIN users prof_user ON prof_user.email = v.prof_email
JOIN professors p    ON p.user_id = prof_user.id
JOIN departments d   ON d.code = v.dept_code;


-- ============================================================
-- ENROLLMENTS  — resolved by student email + course code
-- Same grade distribution / success-rate targets as v3.0:
--   El-Sayed (CS301/CS201/CS101): 75% pass | Abdel-Rahman (AI401/AI301): 100%
--   Ibrahim (IS201/IS301): 83% | El-Din (NET301/NET401): 100%
--   Mahmoud (SE301/SE101): 30% (low performer) | Fathy (SEC301/SEC201): 100%
--   Rashad (DS301/DS401): ~67%
-- ============================================================
INSERT INTO enrollments (student_id, course_id, status, grade)
SELECT s.id, c.id, v.status, v.grade
FROM (VALUES
    -- CS301
    ('aya.mohamed@student.eduguard.edu',   'CS301', 'active', 88.0),
    ('bassem.saeed@student.eduguard.edu',  'CS301', 'active', 55.0),
    ('karim.adly@student.eduguard.edu',    'CS301', 'active', 76.0),
    ('kholoud.naser@student.eduguard.edu', 'CS301', 'active', 82.0),
    -- CS201
    ('aya.mohamed@student.eduguard.edu',   'CS201', 'active', 92.0),
    ('bassem.saeed@student.eduguard.edu',  'CS201', 'active', 48.0),
    ('mariam.tawfik@student.eduguard.edu', 'CS201', 'active', 72.0),
    ('tarek.nabil@student.eduguard.edu',   'CS201', 'active', 65.0),
    -- CS101
    ('karim.adly@student.eduguard.edu',    'CS101', 'active', 85.0),
    ('kholoud.naser@student.eduguard.edu', 'CS101', 'active', 79.0),
    ('mariam.tawfik@student.eduguard.edu', 'CS101', 'active', 69.0),
    ('tarek.nabil@student.eduguard.edu',   'CS101', 'active', 58.0),
    -- AI401
    ('donia.hamdy@student.eduguard.edu',   'AI401', 'active', 91.0),
    ('eman.saber@student.eduguard.edu',    'AI401', 'active', 73.0),
    ('hady.younis@student.eduguard.edu',   'AI401', 'active', 88.0),
    ('loay.sami@student.eduguard.edu',     'AI401', 'active', 61.0),
    -- AI301
    ('donia.hamdy@student.eduguard.edu',   'AI301', 'active', 86.0),
    ('eman.saber@student.eduguard.edu',    'AI301', 'active', 95.0),
    ('loay.sami@student.eduguard.edu',     'AI301', 'active', 78.0),
    -- IS201
    ('fady.lotfy@student.eduguard.edu',    'IS201', 'active', 89.0),
    ('rawan.shafik@student.eduguard.edu',  'IS201', 'active', 76.0),
    ('aya.mohamed@student.eduguard.edu',   'IS201', 'active', 91.0),
    -- IS301
    ('fady.lotfy@student.eduguard.edu',    'IS301', 'active', 55.0),
    ('rawan.shafik@student.eduguard.edu',  'IS301', 'active', 82.0),
    ('karim.adly@student.eduguard.edu',    'IS301', 'active', 77.0),
    -- NET301
    ('gamal.taha@student.eduguard.edu',    'NET301', 'active', 80.0),
    ('peter.maher@student.eduguard.edu',   'NET301', 'active', 72.0),
    -- NET401
    ('gamal.taha@student.eduguard.edu',    'NET401', 'active', 88.0),
    ('peter.maher@student.eduguard.edu',   'NET401', 'active', 75.0),
    -- SE301
    ('mariam.tawfik@student.eduguard.edu', 'SE301', 'active', 71.0),
    ('tarek.nabil@student.eduguard.edu',   'SE301', 'active', 42.0),
    ('nabil.ezzat@student.eduguard.edu',   'SE301', 'active', 38.0),
    -- SE101
    ('mariam.tawfik@student.eduguard.edu', 'SE101', 'active', 45.0),
    ('tarek.nabil@student.eduguard.edu',   'SE101', 'active', 35.0),
    ('nabil.ezzat@student.eduguard.edu',   'SE101', 'active', 51.0),
    -- SEC301
    ('inas.farouk@student.eduguard.edu',   'SEC301', 'active', 84.0),
    ('ola.reda@student.eduguard.edu',      'SEC301', 'active', 93.0),
    ('yasmin.fouad@student.eduguard.edu',  'SEC301', 'active', 76.0),
    -- SEC201
    ('inas.farouk@student.eduguard.edu',   'SEC201', 'active', 88.0),
    ('ola.reda@student.eduguard.edu',      'SEC201', 'active', 79.0),
    -- DS301
    ('qassem.hosny@student.eduguard.edu',  'DS301', 'active', 86.0),
    ('sherif.anwar@student.eduguard.edu',  'DS301', 'active', 52.0),
    ('eman.saber@student.eduguard.edu',    'DS301', 'active', 73.0),
    -- DS401
    ('qassem.hosny@student.eduguard.edu',  'DS401', 'active', 78.0),
    ('sherif.anwar@student.eduguard.edu',  'DS401', 'active', 48.0),
    ('hady.younis@student.eduguard.edu',   'DS401', 'active', 65.0)
) AS v(student_email, course_code, status, grade)
JOIN users su   ON su.email = v.student_email
JOIN students s ON s.user_id = su.id
JOIN courses c  ON c.code = v.course_code;


-- ============================================================
-- ATTENDANCE  (last 30 days; resolved by student email + course code)
-- ============================================================
INSERT INTO attendances (student_id, course_id, date, status)
SELECT s.id, c.id, v.att_date, v.status
FROM (VALUES
    -- Aya — high attendance, CS courses
    ('aya.mohamed@student.eduguard.edu', 'CS301', CURRENT_DATE - 1,  'present'),
    ('aya.mohamed@student.eduguard.edu', 'CS301', CURRENT_DATE - 3,  'present'),
    ('aya.mohamed@student.eduguard.edu', 'CS301', CURRENT_DATE - 5,  'present'),
    ('aya.mohamed@student.eduguard.edu', 'CS301', CURRENT_DATE - 8,  'present'),
    ('aya.mohamed@student.eduguard.edu', 'CS301', CURRENT_DATE - 10, 'present'),
    ('aya.mohamed@student.eduguard.edu', 'CS201', CURRENT_DATE - 2,  'present'),
    ('aya.mohamed@student.eduguard.edu', 'CS201', CURRENT_DATE - 4,  'present'),
    ('aya.mohamed@student.eduguard.edu', 'CS201', CURRENT_DATE - 7,  'present'),
    -- Bassem — poor attendance
    ('bassem.saeed@student.eduguard.edu', 'CS301', CURRENT_DATE - 1, 'absent'),
    ('bassem.saeed@student.eduguard.edu', 'CS301', CURRENT_DATE - 3, 'absent'),
    ('bassem.saeed@student.eduguard.edu', 'CS301', CURRENT_DATE - 5, 'present'),
    ('bassem.saeed@student.eduguard.edu', 'CS301', CURRENT_DATE - 8, 'absent'),
    ('bassem.saeed@student.eduguard.edu', 'CS201', CURRENT_DATE - 2, 'absent'),
    ('bassem.saeed@student.eduguard.edu', 'CS201', CURRENT_DATE - 4, 'late'),
    -- Karim — good attendance
    ('karim.adly@student.eduguard.edu', 'CS301', CURRENT_DATE - 1, 'present'),
    ('karim.adly@student.eduguard.edu', 'CS301', CURRENT_DATE - 3, 'present'),
    ('karim.adly@student.eduguard.edu', 'CS301', CURRENT_DATE - 5, 'late'),
    ('karim.adly@student.eduguard.edu', 'CS101', CURRENT_DATE - 2, 'present'),
    ('karim.adly@student.eduguard.edu', 'CS101', CURRENT_DATE - 4, 'present'),
    ('karim.adly@student.eduguard.edu', 'CS101', CURRENT_DATE - 7, 'present'),
    -- Donia — critical risk, zero attendance
    ('donia.hamdy@student.eduguard.edu', 'SE301', CURRENT_DATE - 1, 'absent'),
    ('donia.hamdy@student.eduguard.edu', 'SE301', CURRENT_DATE - 3, 'absent'),
    ('donia.hamdy@student.eduguard.edu', 'SE301', CURRENT_DATE - 5, 'absent'),
    ('donia.hamdy@student.eduguard.edu', 'SE301', CURRENT_DATE - 8, 'absent'),
    ('donia.hamdy@student.eduguard.edu', 'SE101', CURRENT_DATE - 2, 'absent'),
    ('donia.hamdy@student.eduguard.edu', 'SE101', CURRENT_DATE - 4, 'absent'),
    -- Eman — improving
    ('eman.saber@student.eduguard.edu', 'AI401', CURRENT_DATE - 1, 'present'),
    ('eman.saber@student.eduguard.edu', 'AI401', CURRENT_DATE - 3, 'present'),
    ('eman.saber@student.eduguard.edu', 'AI301', CURRENT_DATE - 2, 'present'),
    ('eman.saber@student.eduguard.edu', 'AI301', CURRENT_DATE - 4, 'present'),
    -- Fady — IS, good attendance
    ('fady.lotfy@student.eduguard.edu', 'IS201', CURRENT_DATE - 1, 'present'),
    ('fady.lotfy@student.eduguard.edu', 'IS201', CURRENT_DATE - 3, 'present'),
    ('fady.lotfy@student.eduguard.edu', 'IS201', CURRENT_DATE - 5, 'present'),
    ('fady.lotfy@student.eduguard.edu', 'IS301', CURRENT_DATE - 2, 'late'),
    ('fady.lotfy@student.eduguard.edu', 'IS301', CURRENT_DATE - 4, 'present'),
    -- Gamal — NET, excellent
    ('gamal.taha@student.eduguard.edu', 'NET301', CURRENT_DATE - 1, 'present'),
    ('gamal.taha@student.eduguard.edu', 'NET301', CURRENT_DATE - 3, 'present'),
    ('gamal.taha@student.eduguard.edu', 'NET301', CURRENT_DATE - 5, 'present'),
    ('gamal.taha@student.eduguard.edu', 'NET401', CURRENT_DATE - 2, 'present'),
    ('gamal.taha@student.eduguard.edu', 'NET401', CURRENT_DATE - 4, 'present'),
    -- Mariam — SE at risk, poor attendance
    ('mariam.tawfik@student.eduguard.edu', 'SE301', CURRENT_DATE - 1, 'absent'),
    ('mariam.tawfik@student.eduguard.edu', 'SE301', CURRENT_DATE - 3, 'absent'),
    ('mariam.tawfik@student.eduguard.edu', 'SE301', CURRENT_DATE - 5, 'late'),
    ('mariam.tawfik@student.eduguard.edu', 'SE101', CURRENT_DATE - 2, 'absent'),
    ('mariam.tawfik@student.eduguard.edu', 'SE101', CURRENT_DATE - 4, 'absent'),
    -- Inas — SEC, good
    ('inas.farouk@student.eduguard.edu', 'SEC301', CURRENT_DATE - 1, 'present'),
    ('inas.farouk@student.eduguard.edu', 'SEC301', CURRENT_DATE - 3, 'present'),
    ('inas.farouk@student.eduguard.edu', 'SEC201', CURRENT_DATE - 2, 'present'),
    ('inas.farouk@student.eduguard.edu', 'SEC201', CURRENT_DATE - 4, 'present'),
    -- Qassem — DS, decent
    ('qassem.hosny@student.eduguard.edu', 'DS301', CURRENT_DATE - 1, 'present'),
    ('qassem.hosny@student.eduguard.edu', 'DS301', CURRENT_DATE - 3, 'present'),
    ('qassem.hosny@student.eduguard.edu', 'DS401', CURRENT_DATE - 2, 'present'),
    ('qassem.hosny@student.eduguard.edu', 'DS401', CURRENT_DATE - 4, 'late'),
    -- Sherif — DS struggling, low attendance
    ('sherif.anwar@student.eduguard.edu', 'DS301', CURRENT_DATE - 1, 'absent'),
    ('sherif.anwar@student.eduguard.edu', 'DS301', CURRENT_DATE - 3, 'absent'),
    ('sherif.anwar@student.eduguard.edu', 'DS401', CURRENT_DATE - 2, 'present'),
    ('sherif.anwar@student.eduguard.edu', 'DS401', CURRENT_DATE - 4, 'absent')
) AS v(student_email, course_code, att_date, status)
JOIN users su   ON su.email = v.student_email
JOIN students s ON s.user_id = su.id
JOIN courses c  ON c.code = v.course_code;


-- ============================================================
-- RISK ASSESSMENTS  (resolved by student email)
-- ============================================================
INSERT INTO risk_assessments (
    student_id, risk_level, probability,
    grades_impact, attendance_impact, activity_impact,
    dropout_probability, graduation_delay_likelihood, scholarship_eligibility,
    trend, explanation, recommendations
)
SELECT s.id, v.risk_level, v.probability,
       v.grades_impact, v.attendance_impact, v.activity_impact,
       v.dropout_probability, v.graduation_delay_likelihood, v.scholarship_eligibility,
       v.trend, v.explanation, v.recommendations::jsonb
FROM (VALUES
    ('aya.mohamed@student.eduguard.edu',   'Normal',   12.0, 15.0, 10.0,  8.0,  5.0,  8.0, 92.0, 'stable',
        'Excellent performance across all metrics.',
        '["Maintain current performance","Consider advanced research courses"]'),
    ('bassem.saeed@student.eduguard.edu',  'High',     78.0, 65.0, 70.0, 55.0, 62.0, 71.0, 15.0, 'declining',
        'GPA 2.10 and poor attendance driving high risk.',
        '["Schedule tutoring sessions","Contact advisor immediately"]'),
    ('karim.adly@student.eduguard.edu',    'Low',      28.0, 25.0, 20.0, 22.0, 12.0, 18.0, 72.0, 'stable',
        'Performing adequately, some room for improvement.',
        '["Focus on weak assignments","Attend office hours"]'),
    ('kholoud.naser@student.eduguard.edu', 'Normal',   18.0, 20.0, 12.0, 15.0,  7.0, 12.0, 85.0, 'improving',
        'Steady improvement in grades and attendance.',
        '["Consider electives","Maintain pace"]'),
    ('mariam.tawfik@student.eduguard.edu', 'Normal',   22.0, 18.0, 15.0, 20.0,  9.0, 15.0, 80.0, 'stable',
        'Solid performer, room to grow.',
        '["Explore AI electives","Join study group"]'),
    ('donia.hamdy@student.eduguard.edu',   'Critical', 91.0, 82.0, 88.0, 60.0, 86.0, 90.0,  4.0, 'sudden_drop',
        'GPA 1.80, attendance 0%, critical dropout risk.',
        '["Emergency advisor meeting","Counseling services","Review course load"]'),
    ('eman.saber@student.eduguard.edu',    'Low',      30.0, 28.0, 22.0, 30.0, 14.0, 20.0, 70.0, 'improving',
        'Improving steadily this semester.',
        '["Keep up momentum","Attend review sessions"]'),
    ('hady.younis@student.eduguard.edu',   'Normal',   20.0, 18.0, 14.0, 12.0,  8.0, 12.0, 82.0, 'stable',
        'Performing well with consistent engagement.',
        '["Consider research project","Maintain pace"]'),
    ('loay.sami@student.eduguard.edu',     'Low',      38.0, 32.0, 28.0, 35.0, 18.0, 25.0, 60.0, 'stable',
        'Moderate risk, needs academic support.',
        '["Attend tutoring","Improve assignment completion"]'),
    ('fady.lotfy@student.eduguard.edu',    'Normal',   14.0, 12.0,  8.0, 10.0,  5.0,  8.0, 88.0, 'stable',
        'Strong GPA, consistent attendance.',
        '["Maintain current performance"]'),
    ('rawan.shafik@student.eduguard.edu',  'Low',      35.0, 30.0, 25.0, 28.0, 15.0, 22.0, 65.0, 'stable',
        'Adequate performance, some attendance gaps.',
        '["Improve attendance","Review weaker modules"]'),
    ('ghada.kamal@student.eduguard.edu',   'Normal',   10.0,  8.0,  5.0,  7.0,  3.0,  5.0, 95.0, 'stable',
        'Excellent student, top of class.',
        '["Consider advanced networking certifications"]'),
    ('peter.maher@student.eduguard.edu',   'High',     72.0, 58.0, 52.0, 48.0, 55.0, 62.0, 20.0, 'declining',
        'Low GPA and declining engagement.',
        '["Set daily study goals","Join a study group","Meet with advisor"]'),
    ('nabil.ezzat@student.eduguard.edu',   'High',     81.0, 72.0, 80.0, 55.0, 68.0, 76.0, 11.0, 'sudden_drop',
        'Sudden drop in attendance and grades in SE courses.',
        '["Contact student immediately","Identify barriers","Attendance monitoring"]'),
    ('tarek.nabil@student.eduguard.edu',   'High',     68.0, 62.0, 55.0, 48.0, 52.0, 60.0, 18.0, 'declining',
        'Failing SE courses, engagement declining.',
        '["Tutoring for SE301","Advisor meeting"]'),
    ('inas.farouk@student.eduguard.edu',   'Normal',   16.0, 12.0,  8.0, 10.0,  5.0,  8.0, 87.0, 'stable',
        'Excellent in cybersecurity courses.',
        '["Consider security certifications"]'),
    ('ola.reda@student.eduguard.edu',      'Normal',   18.0, 14.0, 10.0, 12.0,  6.0, 10.0, 83.0, 'stable',
        'Good performance with strong lab scores.',
        '["Maintain current pace"]'),
    ('yasmin.fouad@student.eduguard.edu',  'High',     74.0, 62.0, 58.0, 50.0, 58.0, 66.0, 16.0, 'declining',
        'Low GPA in first year, needs support.',
        '["Foundational tutoring","Advisor check-in"]'),
    ('gamal.taha@student.eduguard.edu',    'Normal',   20.0, 16.0, 12.0, 14.0,  7.0, 12.0, 83.0, 'stable',
        'Strong analytical skills, good DS grades.',
        '["Explore research opportunities"]'),
    ('qassem.hosny@student.eduguard.edu',  'High',     70.0, 60.0, 65.0, 45.0, 52.0, 58.0, 22.0, 'declining',
        'Failing DS courses, low attendance.',
        '["Tutoring for statistics","Advisor meeting"]'),
    ('sherif.anwar@student.eduguard.edu',  'Low',      32.0, 28.0, 22.0, 25.0, 14.0, 20.0, 67.0, 'stable',
        'Adequate performance, some assignment gaps.',
        '["Complete pending labs","Attend office hours"]')
) AS v(student_email, risk_level, probability, grades_impact, attendance_impact, activity_impact,
       dropout_probability, graduation_delay_likelihood, scholarship_eligibility, trend, explanation, recommendations)
JOIN users su   ON su.email = v.student_email
JOIN students s ON s.user_id = su.id;


-- ============================================================
-- INTERVENTION PLANS  (student + advisor resolved by email)
-- ============================================================
WITH new_plans AS (
    INSERT INTO intervention_plans (student_id, advisor_id, title, description, status, priority, deadline)
    SELECT s.id, a.id, v.title, v.description, v.status, v.priority, v.deadline
    FROM (VALUES
        ('bassem.saeed@student.eduguard.edu', 'y.mostafa@eduguard.edu', 'Academic Recovery Plan',         'Improve assignment completion and attendance for Bassem',  'active',  'high',   NOW() + INTERVAL '30 days'),
        ('donia.hamdy@student.eduguard.edu',  'y.mostafa@eduguard.edu', 'Critical Intervention',          'Emergency support for Donia Hamdy - critical dropout risk', 'active',  'high',   NOW() + INTERVAL '14 days'),
        ('peter.maher@student.eduguard.edu',  'h.gamal@eduguard.edu',   'Engagement Boost - Peter',       'Increase participation in NET courses',                     'pending', 'medium', NOW() + INTERVAL '45 days'),
        ('nabil.ezzat@student.eduguard.edu',  'y.mostafa@eduguard.edu', 'Attendance Improvement - Nabil', 'Address chronic absenteeism in SE courses',                 'active',  'high',   NOW() + INTERVAL '21 days')
    ) AS v(student_email, advisor_email, title, description, status, priority, deadline)
    JOIN users su            ON su.email = v.student_email
    JOIN students s          ON s.user_id = su.id
    JOIN users advisor_user  ON advisor_user.email = v.advisor_email
    JOIN advisors a          ON a.user_id = advisor_user.id
    RETURNING id, title
)
INSERT INTO intervention_actions (plan_id, description, completed, order_index)
SELECT np.id, v.description, v.completed, v.order_index
FROM (VALUES
    ('Academic Recovery Plan',         'Schedule weekly tutoring for CS301',   TRUE,  1),
    ('Academic Recovery Plan',         'Meet with advisor bi-weekly',          FALSE, 2),
    ('Academic Recovery Plan',         'Complete all pending assignments',     FALSE, 3),
    ('Critical Intervention',          'Emergency advisor meeting',            TRUE,  1),
    ('Critical Intervention',          'Connect with counseling services',     FALSE, 2),
    ('Critical Intervention',          'Review and reduce course load',        FALSE, 3),
    ('Engagement Boost - Peter',       'Set up daily study reminders',         FALSE, 1),
    ('Engagement Boost - Peter',       'Join NET study group',                 FALSE, 2),
    ('Attendance Improvement - Nabil', 'Set up attendance monitoring',         TRUE,  1),
    ('Attendance Improvement - Nabil', 'Identify personal barriers',           FALSE, 2),
    ('Attendance Improvement - Nabil', 'Create attendance contract',           FALSE, 3)
) AS v(plan_title, description, completed, order_index)
JOIN new_plans np ON np.title = v.plan_title;


-- ============================================================
-- QUIZZES  (course resolved by code, creator by professor email)
-- ============================================================
WITH new_quizzes AS (
    INSERT INTO quizzes (title, description, course_id, created_by, duration_minutes, attempts_limit, start_time, end_time, shuffle_questions, status, total_points)
    SELECT v.title, v.description, c.id, prof_user.id, v.duration_minutes, v.attempts_limit, v.start_time, v.end_time, v.shuffle_questions, v.status, v.total_points
    FROM (VALUES
        ('Advanced Algorithms Quiz #3',  'Graph algorithms and dynamic programming', 'CS301', 'a.elsayed@eduguard.edu', 60, 2, NOW() - INTERVAL '2 days',  NOW() + INTERVAL '3 days',  TRUE,  'published', 50),
        ('Data Structures Midterm',      'Comprehensive midterm',                    'CS201', 'a.elsayed@eduguard.edu', 90, 1, NOW() - INTERVAL '5 days',  NOW() + INTERVAL '1 day',   FALSE, 'published', 100),
        ('AI401 ML Fundamentals Quiz',   'Supervised learning algorithms',           'AI401', 'm.abdelrahman@eduguard.edu', 45, 1, NOW() + INTERVAL '2 days',  NOW() + INTERVAL '7 days',  TRUE,  'draft',     30),
        ('Database Systems Assessment',  'SQL and data modeling',                    'IS201', 'h.ibrahim@eduguard.edu', 60, 1, NOW() - INTERVAL '10 days', NOW() - INTERVAL '3 days', FALSE, 'closed',    40)
    ) AS v(title, description, course_code, prof_email, duration_minutes, attempts_limit, start_time, end_time, shuffle_questions, status, total_points)
    JOIN courses c        ON c.code = v.course_code
    JOIN users prof_user   ON prof_user.email = v.prof_email
    RETURNING id, title
)
INSERT INTO questions (quiz_id, type, text, options_json, correct_answer, points, order_index)
SELECT nq.id, v.type, v.text, v.options_json::jsonb, v.correct_answer, v.points, v.order_index
FROM (VALUES
    ('Advanced Algorithms Quiz #3', 'multiple_choice',
        'What is the time complexity of Dijkstra''s algorithm with a binary heap?',
        '["O(V^2)","O((V+E) log V)","O(V log V)","O(E log V)"]',
        'O((V+E) log V)', 5, 1),
    ('Advanced Algorithms Quiz #3', 'true_false',
        'Dynamic programming always requires memorization of all subproblems.',
        '["True","False"]', 'False', 3, 2),
    ('Data Structures Midterm', 'multiple_choice',
        'Worst-case time complexity of quicksort?',
        '["O(n log n)","O(n^2)","O(n)","O(log n)"]',
        'O(n^2)', 5, 1)
) AS v(quiz_title, type, text, options_json, correct_answer, points, order_index)
JOIN new_quizzes nq ON nq.title = v.quiz_title;


-- ============================================================
-- NOTIFICATIONS  (recipient resolved by email)
-- ============================================================
INSERT INTO notifications (user_id, title, message, type, priority, read)
SELECT u.id, v.title, v.message, v.type, v.priority, v.read
FROM (VALUES
    ('mona.khalil@eduguard.edu',          'Critical Risk Alert',       'Donia Hamdy reached critical risk (91%)',     'risk_alert',   'high',   FALSE),
    ('mona.khalil@eduguard.edu',          'New Intervention Assigned', 'Academic Recovery Plan assigned to Bassem',   'intervention', 'medium', FALSE),
    ('mona.khalil@eduguard.edu',          'Quiz Results Available',    'Algorithms Quiz #3 results ready',            'quiz',         'low',    TRUE),
    ('mona.khalil@eduguard.edu',          'Grade Drop Detected',       'Nabil Ezzat GPA dropped significantly',       'grade',        'high',   FALSE),
    ('mona.khalil@eduguard.edu',          'System Update',             'EduGuard AI upgraded to v4.0',                'system',       'low',    TRUE),
    ('a.elsayed@eduguard.edu',            'New Submission',            '12 students submitted Algorithms Quiz #3',    'quiz',         'low',    FALSE),
    ('a.elsayed@eduguard.edu',            'Risk Alert',                'Two students in CS301 show high risk',        'risk_alert',   'high',   FALSE),
    ('aya.mohamed@student.eduguard.edu',  'Quiz Available',            'Advanced Algorithms Quiz #3 is now open',    'quiz',         'medium', FALSE),
    ('aya.mohamed@student.eduguard.edu',  'Grade Posted',              'Your Data Structures grade: 92.0',            'grade',        'low',    FALSE),
    ('bassem.saeed@student.eduguard.edu', 'Attendance Warning',        'Your attendance dropped below 70%',           'attendance',   'high',   FALSE),
    ('bassem.saeed@student.eduguard.edu', 'Advisor Meeting',           'Your advisor requests an urgent meeting',     'intervention', 'high',   FALSE)
) AS v(email, title, message, type, priority, read)
JOIN users u ON u.email = v.email;


-- ============================================================
-- ACTIVITY LOGS  (student resolved by email; quiz/course resolved by lookup)
-- ============================================================
INSERT INTO activity_logs (student_id, action, duration_minutes, resource_type, resource_id)
SELECT s.id, v.action, v.duration_minutes, v.resource_type,
       CASE v.resource_type
           WHEN 'quiz'   THEN (SELECT q.id FROM quizzes q WHERE q.title = v.resource_ref)
           WHEN 'course' THEN (SELECT c.id FROM courses c WHERE c.code  = v.resource_ref)
           ELSE NULL
       END
FROM (VALUES
    ('aya.mohamed@student.eduguard.edu',  'quiz_attempt', 45, 'quiz',   'Advanced Algorithms Quiz #3'),
    ('aya.mohamed@student.eduguard.edu',  'course_view',  30, 'course', 'CS301'),
    ('bassem.saeed@student.eduguard.edu', 'course_view',   5, 'course', 'CS301'),
    ('donia.hamdy@student.eduguard.edu',  'login',         2, NULL,     NULL),
    ('ta.omar@eduguard.edu',              'quiz_attempt', 42, 'quiz',   'Database Systems Assessment'),
    ('ta.omar@eduguard.edu',              'course_view',  60, 'course', 'AI401'),
    ('aya.mohamed@student.eduguard.edu',  'course_view',   8, 'course', 'IS301')
) AS v(student_email, action, duration_minutes, resource_type, resource_ref)
JOIN users su   ON su.email = v.student_email
-- activity_logs.student_id references students(id); for the two TA-related rows
-- above (ta.omar) we intentionally fall back to NULL since a TA is not a student —
-- preserved here as a left join so those two informational rows are skipped safely.
LEFT JOIN students s ON s.user_id = su.id
WHERE s.id IS NOT NULL;


-- ============================================================
-- ANNOUNCEMENTS  (author resolved by email; course by code)
-- ============================================================
INSERT INTO announcements (title, content, author_id, is_global, published_at)
SELECT v.title, v.content, u.id, v.is_global, v.published_at
FROM (VALUES
    ('Welcome to Fall 2025 Semester',
     'Welcome all students. Please verify enrollment and check your course schedules.',
     'mona.khalil@eduguard.edu', TRUE, NOW() - INTERVAL '5 days'),
    ('EduGuard AI System Upgrade',
     'AI risk prediction upgraded to v4.0 with improved accuracy.',
     'mona.khalil@eduguard.edu', TRUE, NOW() - INTERVAL '2 days'),
    ('Mid-Semester Grade Review',
     'Professors: submit all mid-semester grades by end of week.',
     'mona.khalil@eduguard.edu', TRUE, NOW() - INTERVAL '1 day')
) AS v(title, content, author_email, is_global, published_at)
JOIN users u ON u.email = v.author_email;

INSERT INTO announcements (title, content, author_id, course_id, is_global, published_at)
SELECT v.title, v.content, u.id, c.id, v.is_global, v.published_at
FROM (VALUES
    ('CS301 Quiz #3 Guidelines',
     'Review chapters 8-12 before the quiz. No calculators permitted.',
     'a.elsayed@eduguard.edu', 'CS301', FALSE, NOW() - INTERVAL '3 days'),
    ('AI401 Office Hours Extended',
     'Office hours this week extended to Thursday 3-6 PM.',
     'm.abdelrahman@eduguard.edu', 'AI401', FALSE, NOW() - INTERVAL '1 day')
) AS v(title, content, author_email, course_code, is_global, published_at)
JOIN users u    ON u.email = v.author_email
JOIN courses c  ON c.code  = v.course_code;

-- ============================================================
-- END — run 003_views.sql next
-- ============================================================