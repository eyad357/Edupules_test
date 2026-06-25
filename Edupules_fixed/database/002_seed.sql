-- ============================================================
-- EduGuard AI — Production-Safe Seed Data v4.0
-- ============================================================
-- Changes from v3.0 (C1 fix — hard-coded FK elimination):
--   All FK references now resolved via natural keys (email,
--   student_number, course_code, department_code) using
--   subqueries and CTEs. No positional id assumptions.
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
CASCADE;

-- Reset sequences
ALTER SEQUENCE departments_id_seq   RESTART WITH 1;
ALTER SEQUENCE users_id_seq         RESTART WITH 1;


-- ============================================================
-- DEPARTMENTS
-- Natural key: code
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
-- USERS
-- Natural key: email
-- ============================================================

-- Admins
INSERT INTO users (name, email, hashed_password, role) VALUES
('Dr. Sarah Mitchell',   'admin@eduguard.edu',    '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin'),
('System Administrator', 'sysadmin@eduguard.edu', '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin');

-- Professors
INSERT INTO users (name, email, hashed_password, role) VALUES
('Prof. James Anderson', 'j.anderson@eduguard.edu', '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'professor'),
('Prof. Emily Chen',     'e.chen@eduguard.edu',     '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'professor'),
('Prof. Robert Davis',   'r.davis@eduguard.edu',    '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'professor'),
('Prof. Lisa Thompson',  'l.thompson@eduguard.edu', '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'professor'),
('Prof. Michael Wong',   'm.wong@eduguard.edu',     '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'professor'),
('Prof. Anna Martinez',  'a.martinez@eduguard.edu', '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'professor'),
('Prof. David Nguyen',   'd.nguyen@eduguard.edu',   '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'professor');

-- Advisors
INSERT INTO users (name, email, hashed_password, role) VALUES
('Dr. Kevin Park',   'k.park@eduguard.edu',  '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'advisor'),
('Dr. Rachel Green', 'r.green@eduguard.edu', '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'advisor');

-- Teaching Assistants
INSERT INTO users (name, email, hashed_password, role) VALUES
('Marcus Johnson',  'ta.marcus@eduguard.edu', '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'ta'),
('Sofia Rodriguez', 'ta.sofia@eduguard.edu',  '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'ta');

-- Students
INSERT INTO users (name, email, hashed_password, role) VALUES
('Alice Johnson',  'alice@student.eduguard.edu',   '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
('Bob Smith',      'bob@student.eduguard.edu',     '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
('Carol White',    'carol@student.eduguard.edu',   '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
('David Brown',    'david@student.eduguard.edu',   '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
('Eva Martinez',   'eva@student.eduguard.edu',     '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
('Frank Lee',      'frank@student.eduguard.edu',   '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
('Grace Kim',      'grace@student.eduguard.edu',   '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
('Henry Wilson',   'henry@student.eduguard.edu',   '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
('Iris Patel',     'iris@student.eduguard.edu',    '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
('Jake Turner',    'jake@student.eduguard.edu',    '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
('Karen Liu',      'karen@student.eduguard.edu',   '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
('Leo Santos',     'leo@student.eduguard.edu',     '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
('Mia Chen',       'mia@student.eduguard.edu',     '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
('Noah Adams',     'noah@student.eduguard.edu',    '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
('Olivia Clark',   'olivia@student.eduguard.edu',  '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
('Peter Wright',   'peter@student.eduguard.edu',   '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
('Quinn Harris',   'quinn@student.eduguard.edu',   '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
('Rachel Scott',   'rachel@student.eduguard.edu',  '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
('Sam Baker',      'sam@student.eduguard.edu',     '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
('Tara Nelson',    'tara@student.eduguard.edu',    '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
('Uma Patel',      'uma@student.eduguard.edu',     '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student');


-- ============================================================
-- PROFESSORS
-- Lookup user_id by email, department_id by code
-- ============================================================
INSERT INTO professors (user_id, department_id, department, title, specialization, office_location, office_hours)
SELECT u.id, d.id, d.name, p.title, p.spec, p.office, p.hours
FROM (VALUES
    ('j.anderson@eduguard.edu', 'CS',  'Associate Professor', 'Algorithms & Data Structures',    'CS Building, Room 305',  'Mon/Wed 2–4 PM'),
    ('e.chen@eduguard.edu',     'AI',  'Professor',           'Machine Learning & Deep Learning', 'CS Building, Room 210',  'Tue/Thu 10–12 PM'),
    ('r.davis@eduguard.edu',    'IS',  'Assistant Professor', 'Database Systems & Analytics',    'IS Building, Room 102',  'Mon/Fri 1–3 PM'),
    ('l.thompson@eduguard.edu', 'NET', 'Professor',           'Network Protocols & Security',    'NET Lab, Room 401',      'Wed/Thu 3–5 PM'),
    ('m.wong@eduguard.edu',     'SE',  'Associate Professor', 'Software Architecture & DevOps',  'SE Building, Room 215',  'Tue/Thu 2–4 PM'),
    ('a.martinez@eduguard.edu', 'SEC', 'Assistant Professor', 'Ethical Hacking & Forensics',     'SEC Lab, Room 118',      'Mon/Wed/Fri 11–12 PM'),
    ('d.nguyen@eduguard.edu',   'DS',  'Associate Professor', 'Statistical Learning & Viz',      'DS Building, Room 330',  'Mon/Wed 3–5 PM')
) AS p(email, dept_code, title, spec, office, hours)
JOIN users       u ON u.email = p.email
JOIN departments d ON d.code  = p.dept_code;


-- ============================================================
-- ADVISORS
-- Lookup user_id by email, department_id by code
-- ============================================================
INSERT INTO advisors (user_id, department_id, specialization, max_students)
SELECT u.id, d.id, a.spec, a.max_stu
FROM (VALUES
    ('k.park@eduguard.edu',  'CS', 'CS & AI Counseling',       35),
    ('r.green@eduguard.edu', 'IS', 'IS & Networks Counseling', 30)
) AS a(email, dept_code, spec, max_stu)
JOIN users       u ON u.email = a.email
JOIN departments d ON d.code  = a.dept_code;


-- ============================================================
-- TEACHING ASSISTANTS
-- Lookup user_id by email, professor_id by professor's email,
-- department_id by code
-- ============================================================
INSERT INTO teaching_assistants (user_id, professor_id, department_id)
SELECT ta_u.id, p.id, d.id
FROM (VALUES
    ('ta.marcus@eduguard.edu', 'j.anderson@eduguard.edu', 'CS'),
    ('ta.sofia@eduguard.edu',  'e.chen@eduguard.edu',     'AI')
) AS t(ta_email, prof_email, dept_code)
JOIN users       ta_u ON ta_u.email = t.ta_email
JOIN users       pu   ON pu.email   = t.prof_email
JOIN professors  p    ON p.user_id  = pu.id
JOIN departments d    ON d.code     = t.dept_code;


-- ============================================================
-- STUDENTS
-- Lookup user_id by email, department_id by code,
-- advisor_id by advisor's user email
-- ============================================================
INSERT INTO students (user_id, student_number, department_id, major, year, gpa, enrollment_date, advisor_id, is_scholarship)
SELECT u.id, s.snum, d.id, s.major, s.yr, s.gpa, s.enroll::DATE, adv.id, s.scholar
FROM (VALUES
    -- email,                          snum,           dept, major,                      yr, gpa,  enroll,       adv_email,              scholar
    ('alice@student.eduguard.edu',   'STU-2022-001', 'CS',  'Computer Science',          3, 3.80, '2022-09-01', 'k.park@eduguard.edu',  TRUE),
    ('bob@student.eduguard.edu',     'STU-2023-002', 'CS',  'Computer Science',          2, 2.10, '2023-09-01', 'k.park@eduguard.edu',  FALSE),
    ('carol@student.eduguard.edu',   'STU-2022-003', 'CS',  'Computer Science',          3, 3.50, '2022-09-01', 'k.park@eduguard.edu',  FALSE),
    ('david@student.eduguard.edu',   'STU-2024-004', 'AI',  'Artificial Intelligence',   1, 1.80, '2024-09-01', 'k.park@eduguard.edu',  FALSE),
    ('eva@student.eduguard.edu',     'STU-2022-005', 'AI',  'Artificial Intelligence',   3, 3.20, '2022-09-01', 'k.park@eduguard.edu',  FALSE),
    ('frank@student.eduguard.edu',   'STU-2023-006', 'IS',  'Information Systems',       2, 3.82, '2023-09-01', 'r.green@eduguard.edu', FALSE),
    ('grace@student.eduguard.edu',   'STU-2023-007', 'NET', 'Computer Networks',         2, 2.24, '2023-09-01', 'r.green@eduguard.edu', FALSE),
    ('henry@student.eduguard.edu',   'STU-2021-008', 'SE',  'Software Engineering',      4, 1.84, '2021-09-01', 'r.green@eduguard.edu', FALSE),
    ('iris@student.eduguard.edu',    'STU-2022-009', 'SEC', 'Cybersecurity',             3, 3.26, '2022-09-01', 'r.green@eduguard.edu', FALSE),
    ('jake@student.eduguard.edu',    'STU-2021-010', 'DS',  'Data Science',              4, 3.22, '2021-09-01', 'k.park@eduguard.edu',  FALSE),
    ('karen@student.eduguard.edu',   'STU-2023-011', 'CS',  'Computer Science',          2, 2.70, '2023-09-01', 'k.park@eduguard.edu',  FALSE),
    ('leo@student.eduguard.edu',     'STU-2023-012', 'AI',  'Artificial Intelligence',   2, 2.40, '2023-09-01', 'k.park@eduguard.edu',  FALSE),
    ('mia@student.eduguard.edu',     'STU-2022-013', 'CS',  'Computer Science',          3, 3.60, '2022-09-01', 'k.park@eduguard.edu',  FALSE),
    ('noah@student.eduguard.edu',    'STU-2023-014', 'SE',  'Software Engineering',      2, 2.90, '2023-09-01', 'r.green@eduguard.edu', FALSE),
    ('olivia@student.eduguard.edu',  'STU-2023-015', 'SEC', 'Cybersecurity',             2, 2.80, '2023-09-01', 'r.green@eduguard.edu', FALSE),
    ('peter@student.eduguard.edu',   'STU-2022-016', 'NET', 'Computer Networks',         3, 1.70, '2022-09-01', 'r.green@eduguard.edu', FALSE),
    ('quinn@student.eduguard.edu',   'STU-2023-017', 'DS',  'Data Science',              2, 2.45, '2023-09-01', 'k.park@eduguard.edu',  FALSE),
    ('rachel@student.eduguard.edu',  'STU-2022-018', 'IS',  'Information Systems',       3, 2.50, '2022-09-01', 'r.green@eduguard.edu', FALSE),
    ('sam@student.eduguard.edu',     'STU-2023-019', 'AI',  'Artificial Intelligence',   2, 2.95, '2023-09-01', 'k.park@eduguard.edu',  FALSE),
    ('tara@student.eduguard.edu',    'STU-2024-020', 'CS',  'Computer Science',          1, 3.10, '2024-09-01', 'k.park@eduguard.edu',  FALSE),
    ('uma@student.eduguard.edu',     'STU-2024-021', 'SEC', 'Cybersecurity',             1, 1.95, '2024-09-01', 'r.green@eduguard.edu', FALSE)
) AS s(email, snum, dept_code, major, yr, gpa, enroll, adv_email, scholar)
JOIN users       u   ON u.email   = s.email
JOIN departments d   ON d.code    = s.dept_code
JOIN users       au  ON au.email  = s.adv_email
JOIN advisors    adv ON adv.user_id = au.id;


-- ============================================================
-- COURSES
-- Lookup professor_id by professor's user email,
-- department_id by code
-- ============================================================
INSERT INTO courses (code, name, description, credits, semester, year, professor_id, department_id, max_students)
SELECT c.code, c.name, c.descr, c.cred, c.sem, c.yr, p.id, d.id, c.max_stu
FROM (VALUES
    ('CS301',  'Advanced Algorithms',      'Algorithm design, complexity, graph theory',         3, 'Fall',   2025, 'j.anderson@eduguard.edu', 'CS',  40),
    ('CS201',  'Data Structures',          'Fundamental data structures and applications',       3, 'Fall',   2025, 'j.anderson@eduguard.edu', 'CS',  40),
    ('CS101',  'Intro to Programming',     'Python fundamentals, OOP',                           3, 'Spring', 2025, 'j.anderson@eduguard.edu', 'CS',  60),
    ('AI401',  'Machine Learning',         'Supervised and unsupervised learning',               4, 'Fall',   2025, 'e.chen@eduguard.edu',     'AI',  35),
    ('AI301',  'Neural Networks',          'Deep learning architectures',                        3, 'Fall',   2025, 'e.chen@eduguard.edu',     'AI',  30),
    ('IS201',  'Database Systems',         'SQL, NoSQL, data modeling',                          3, 'Fall',   2025, 'r.davis@eduguard.edu',    'IS',  45),
    ('IS301',  'Business Intelligence',    'Data warehousing and reporting',                     3, 'Fall',   2025, 'r.davis@eduguard.edu',    'IS',  35),
    ('NET301', 'Computer Networks',        'TCP/IP, routing protocols',                          3, 'Fall',   2025, 'l.thompson@eduguard.edu', 'NET', 40),
    ('NET401', 'Network Security',         'Firewalls, VPNs, intrusion detection',              3, 'Fall',   2025, 'l.thompson@eduguard.edu', 'NET', 30),
    ('SE301',  'Software Architecture',    'Design patterns, microservices',                     3, 'Fall',   2025, 'm.wong@eduguard.edu',     'SE',  35),
    ('SE101',  'Software Foundations',     'SDLC, agile, version control',                       2, 'Spring', 2025, 'm.wong@eduguard.edu',     'SE',  50),
    ('SEC301', 'Ethical Hacking',          'Penetration testing and vulnerability assessment',   3, 'Fall',   2025, 'a.martinez@eduguard.edu', 'SEC', 30),
    ('SEC201', 'Cryptography',             'Encryption algorithms and PKI',                      3, 'Fall',   2025, 'a.martinez@eduguard.edu', 'SEC', 35),
    ('DS301',  'Data Science Fundamentals','Statistics, Python, data pipelines',                 3, 'Fall',   2025, 'd.nguyen@eduguard.edu',   'DS',  40),
    ('DS401',  'Machine Learning for DS',  'Applied ML for data science workflows',             3, 'Fall',   2025, 'd.nguyen@eduguard.edu',   'DS',  35)
) AS c(code, name, descr, cred, sem, yr, prof_email, dept_code, max_stu)
JOIN users       pu ON pu.email   = c.prof_email
JOIN professors  p  ON p.user_id  = pu.id
JOIN departments d  ON d.code     = c.dept_code;


-- ============================================================
-- ENROLLMENTS
-- Lookup student_id by student_number, course_id by course_code
-- ============================================================
INSERT INTO enrollments (student_id, course_id, status, grade)
SELECT s.id, c.id, e.status, e.grade
FROM (VALUES
    -- student_number,   course_code, status,   grade
    -- CS301
    ('STU-2022-001', 'CS301', 'active', 88.0),
    ('STU-2023-002', 'CS301', 'active', 55.0),
    ('STU-2022-003', 'CS301', 'active', 76.0),
    ('STU-2023-011', 'CS301', 'active', 82.0),
    -- CS201
    ('STU-2022-001', 'CS201', 'active', 92.0),
    ('STU-2023-002', 'CS201', 'active', 48.0),
    ('STU-2022-013', 'CS201', 'active', 72.0),
    ('STU-2024-020', 'CS201', 'active', 65.0),
    -- CS101
    ('STU-2022-003', 'CS101', 'active', 85.0),
    ('STU-2023-011', 'CS101', 'active', 79.0),
    ('STU-2022-013', 'CS101', 'active', 69.0),
    ('STU-2024-020', 'CS101', 'active', 58.0),
    -- AI401
    ('STU-2024-004', 'AI401', 'active', 91.0),
    ('STU-2022-005', 'AI401', 'active', 73.0),
    ('STU-2023-012', 'AI401', 'active', 88.0),
    ('STU-2023-019', 'AI401', 'active', 61.0),
    -- AI301
    ('STU-2024-004', 'AI301', 'active', 86.0),
    ('STU-2022-005', 'AI301', 'active', 95.0),
    ('STU-2023-019', 'AI301', 'active', 78.0),
    -- IS201
    ('STU-2023-006', 'IS201', 'active', 89.0),
    ('STU-2022-018', 'IS201', 'active', 76.0),
    ('STU-2022-001', 'IS201', 'active', 91.0),
    -- IS301
    ('STU-2023-006', 'IS301', 'active', 55.0),
    ('STU-2022-018', 'IS301', 'active', 82.0),
    ('STU-2022-003', 'IS301', 'active', 77.0),
    -- NET301
    ('STU-2023-007', 'NET301', 'active', 80.0),
    ('STU-2022-016', 'NET301', 'active', 72.0),
    -- NET401
    ('STU-2023-007', 'NET401', 'active', 88.0),
    ('STU-2022-016', 'NET401', 'active', 75.0),
    -- SE301
    ('STU-2021-008', 'SE301', 'active', 42.0),
    ('STU-2023-014', 'SE301', 'active', 38.0),
    ('STU-2023-011', 'SE301', 'active', 71.0),
    -- SE101
    ('STU-2021-008', 'SE101', 'active', 35.0),
    ('STU-2023-014', 'SE101', 'active', 51.0),
    ('STU-2022-013', 'SE101', 'active', 45.0),
    -- SEC301
    ('STU-2022-009', 'SEC301', 'active', 84.0),
    ('STU-2023-015', 'SEC301', 'active', 93.0),
    ('STU-2024-021', 'SEC301', 'active', 76.0),
    -- SEC201
    ('STU-2022-009', 'SEC201', 'active', 88.0),
    ('STU-2023-015', 'SEC201', 'active', 79.0),
    -- DS301
    ('STU-2021-010', 'DS301', 'active', 86.0),
    ('STU-2023-017', 'DS301', 'active', 52.0),
    ('STU-2022-005', 'DS301', 'active', 73.0),
    -- DS401
    ('STU-2021-010', 'DS401', 'active', 78.0),
    ('STU-2023-017', 'DS401', 'active', 48.0),
    ('STU-2023-012', 'DS401', 'active', 65.0)
) AS e(snum, course_code, status, grade)
JOIN students s ON s.student_number = e.snum
JOIN courses  c ON c.code           = e.course_code;


-- ============================================================
-- ATTENDANCE
-- Lookup student_id by student_number, course_id by code
-- ============================================================
INSERT INTO attendances (student_id, course_id, date, status)
SELECT s.id, c.id, a.dt, a.status::attendance_status
FROM (VALUES
    ('STU-2022-001', 'CS301', CURRENT_DATE - 1,  'present'), ('STU-2022-001', 'CS301', CURRENT_DATE - 3,  'present'),
    ('STU-2022-001', 'CS301', CURRENT_DATE - 5,  'present'), ('STU-2022-001', 'CS301', CURRENT_DATE - 8,  'present'),
    ('STU-2022-001', 'CS301', CURRENT_DATE - 10, 'present'), ('STU-2022-001', 'CS201', CURRENT_DATE - 2,  'present'),
    ('STU-2022-001', 'CS201', CURRENT_DATE - 4,  'present'), ('STU-2022-001', 'CS201', CURRENT_DATE - 7,  'present'),
    ('STU-2023-002', 'CS301', CURRENT_DATE - 1,  'absent'),  ('STU-2023-002', 'CS301', CURRENT_DATE - 3,  'absent'),
    ('STU-2023-002', 'CS301', CURRENT_DATE - 5,  'present'), ('STU-2023-002', 'CS301', CURRENT_DATE - 8,  'absent'),
    ('STU-2023-002', 'CS201', CURRENT_DATE - 2,  'absent'),  ('STU-2023-002', 'CS201', CURRENT_DATE - 4,  'late'),
    ('STU-2022-003', 'CS301', CURRENT_DATE - 1,  'present'), ('STU-2022-003', 'CS301', CURRENT_DATE - 3,  'present'),
    ('STU-2022-003', 'CS301', CURRENT_DATE - 5,  'late'),    ('STU-2022-003', 'CS101', CURRENT_DATE - 2,  'present'),
    ('STU-2022-003', 'CS101', CURRENT_DATE - 4,  'present'), ('STU-2022-003', 'CS101', CURRENT_DATE - 7,  'present'),
    ('STU-2024-004', 'SE301', CURRENT_DATE - 1,  'absent'),  ('STU-2024-004', 'SE301', CURRENT_DATE - 3,  'absent'),
    ('STU-2024-004', 'SE301', CURRENT_DATE - 5,  'absent'),  ('STU-2024-004', 'SE301', CURRENT_DATE - 8,  'absent'),
    ('STU-2024-004', 'SE101', CURRENT_DATE - 2,  'absent'),  ('STU-2024-004', 'SE101', CURRENT_DATE - 4,  'absent'),
    ('STU-2022-005', 'AI401', CURRENT_DATE - 1,  'present'), ('STU-2022-005', 'AI401', CURRENT_DATE - 3,  'present'),
    ('STU-2022-005', 'AI301', CURRENT_DATE - 2,  'present'), ('STU-2022-005', 'AI301', CURRENT_DATE - 4,  'present'),
    ('STU-2023-006', 'IS201', CURRENT_DATE - 1,  'present'), ('STU-2023-006', 'IS201', CURRENT_DATE - 3,  'present'),
    ('STU-2023-006', 'IS201', CURRENT_DATE - 5,  'present'), ('STU-2023-006', 'IS301', CURRENT_DATE - 2,  'late'),
    ('STU-2023-006', 'IS301', CURRENT_DATE - 4,  'present'),
    ('STU-2023-007', 'NET301', CURRENT_DATE - 1, 'present'), ('STU-2023-007', 'NET301', CURRENT_DATE - 3, 'present'),
    ('STU-2023-007', 'NET301', CURRENT_DATE - 5, 'present'), ('STU-2023-007', 'NET401', CURRENT_DATE - 2, 'present'),
    ('STU-2023-007', 'NET401', CURRENT_DATE - 4, 'present'),
    ('STU-2021-008', 'SE301', CURRENT_DATE - 1,  'absent'),  ('STU-2021-008', 'SE301', CURRENT_DATE - 3,  'absent'),
    ('STU-2021-008', 'SE301', CURRENT_DATE - 5,  'late'),    ('STU-2021-008', 'SE101', CURRENT_DATE - 2,  'absent'),
    ('STU-2021-008', 'SE101', CURRENT_DATE - 4,  'absent'),
    ('STU-2022-009', 'SEC301', CURRENT_DATE - 1, 'present'), ('STU-2022-009', 'SEC301', CURRENT_DATE - 3, 'present'),
    ('STU-2022-009', 'SEC201', CURRENT_DATE - 2, 'present'), ('STU-2022-009', 'SEC201', CURRENT_DATE - 4, 'present'),
    ('STU-2021-010', 'DS301', CURRENT_DATE - 1,  'present'), ('STU-2021-010', 'DS301', CURRENT_DATE - 3,  'present'),
    ('STU-2021-010', 'DS401', CURRENT_DATE - 2,  'present'), ('STU-2021-010', 'DS401', CURRENT_DATE - 4,  'late'),
    ('STU-2023-017', 'DS301', CURRENT_DATE - 1,  'absent'),  ('STU-2023-017', 'DS301', CURRENT_DATE - 3,  'absent'),
    ('STU-2023-017', 'DS401', CURRENT_DATE - 2,  'present'), ('STU-2023-017', 'DS401', CURRENT_DATE - 4,  'absent')
) AS a(snum, course_code, dt, status)
JOIN students s ON s.student_number = a.snum
JOIN courses  c ON c.code           = a.course_code;


-- ============================================================
-- RISK ASSESSMENTS
-- Lookup student_id by student_number
-- ============================================================
INSERT INTO risk_assessments (
    student_id, risk_level, probability,
    grades_impact, attendance_impact, activity_impact,
    dropout_probability, graduation_delay_likelihood, scholarship_eligibility,
    trend, explanation, recommendations
)
SELECT s.id, r.risk_level::risk_level, r.prob,
       r.gi, r.ai, r.acti, r.dp, r.gdl, r.se, r.trend, r.expl, r.recs::JSONB
FROM (VALUES
    ('STU-2022-001', 'Normal',   12.0, 15.0, 10.0,  8.0,  5.0,  8.0, 92.0, 'stable',       'Excellent performance across all metrics.',                                 '["Maintain current performance","Consider advanced research courses"]'),
    ('STU-2023-002', 'High',     78.0, 65.0, 70.0, 55.0, 62.0, 71.0, 15.0, 'declining',    'GPA 2.10 and poor attendance driving high risk.',                           '["Schedule tutoring sessions","Contact advisor immediately"]'),
    ('STU-2022-003', 'Low',      28.0, 25.0, 20.0, 22.0, 12.0, 18.0, 72.0, 'stable',       'Performing adequately, some room for improvement.',                         '["Focus on weak assignments","Attend office hours"]'),
    ('STU-2023-011', 'Normal',   18.0, 20.0, 12.0, 15.0,  7.0, 12.0, 85.0, 'improving',    'Steady improvement in grades and attendance.',                              '["Consider electives","Maintain pace"]'),
    ('STU-2022-013', 'Normal',   22.0, 18.0, 15.0, 20.0,  9.0, 15.0, 80.0, 'stable',       'Solid performer, room to grow.',                                            '["Explore AI electives","Join study group"]'),
    ('STU-2024-004', 'Critical', 91.0, 82.0, 88.0, 60.0, 86.0, 90.0,  4.0, 'sudden_drop',  'GPA 1.80, attendance 0%, critical dropout risk.',                           '["Emergency advisor meeting","Counseling services","Review course load"]'),
    ('STU-2022-005', 'Low',      30.0, 28.0, 22.0, 30.0, 14.0, 20.0, 70.0, 'improving',    'Improving steadily this semester.',                                         '["Keep up momentum","Attend review sessions"]'),
    ('STU-2023-012', 'Normal',   20.0, 18.0, 14.0, 12.0,  8.0, 12.0, 82.0, 'stable',       'Performing well with consistent engagement.',                               '["Consider research project","Maintain pace"]'),
    ('STU-2023-019', 'Low',      38.0, 32.0, 28.0, 35.0, 18.0, 25.0, 60.0, 'stable',       'Moderate risk, needs academic support.',                                    '["Attend tutoring","Improve assignment completion"]'),
    ('STU-2023-006', 'Normal',   14.0, 12.0,  8.0, 10.0,  5.0,  8.0, 88.0, 'stable',       'Strong GPA, consistent attendance.',                                        '["Maintain current performance"]'),
    ('STU-2022-018', 'Low',      35.0, 30.0, 25.0, 28.0, 15.0, 22.0, 65.0, 'stable',       'Adequate performance, some attendance gaps.',                               '["Improve attendance","Review weaker modules"]'),
    ('STU-2023-007', 'Normal',   10.0,  8.0,  5.0,  7.0,  3.0,  5.0, 95.0, 'stable',       'Excellent student, top of class.',                                          '["Consider advanced networking certifications"]'),
    ('STU-2022-016', 'High',     72.0, 58.0, 52.0, 48.0, 55.0, 62.0, 20.0, 'declining',    'Low GPA and declining engagement.',                                         '["Set daily study goals","Join a study group","Meet with advisor"]'),
    ('STU-2021-008', 'High',     81.0, 72.0, 80.0, 55.0, 68.0, 76.0, 11.0, 'sudden_drop',  'Sudden drop in attendance and grades in SE courses.',                       '["Contact student immediately","Identify barriers","Attendance monitoring"]'),
    ('STU-2023-014', 'High',     68.0, 62.0, 55.0, 48.0, 52.0, 60.0, 18.0, 'declining',    'Failing SE courses, engagement declining.',                                 '["Tutoring for SE301","Advisor meeting"]'),
    ('STU-2022-009', 'Normal',   16.0, 12.0,  8.0, 10.0,  5.0,  8.0, 87.0, 'stable',       'Excellent in cybersecurity courses.',                                        '["Consider security certifications"]'),
    ('STU-2023-015', 'Normal',   18.0, 14.0, 10.0, 12.0,  6.0, 10.0, 83.0, 'stable',       'Good performance with strong lab scores.',                                  '["Maintain current pace"]'),
    ('STU-2024-021', 'High',     74.0, 62.0, 58.0, 50.0, 58.0, 66.0, 16.0, 'declining',    'Low GPA in first year, needs support.',                                     '["Foundational tutoring","Advisor check-in"]'),
    ('STU-2021-010', 'Normal',   20.0, 16.0, 12.0, 14.0,  7.0, 12.0, 83.0, 'stable',       'Strong analytical skills, good DS grades.',                                 '["Explore research opportunities"]'),
    ('STU-2023-017', 'High',     70.0, 60.0, 65.0, 45.0, 52.0, 58.0, 22.0, 'declining',    'Failing DS courses, low attendance.',                                       '["Tutoring for statistics","Advisor meeting"]'),
    ('STU-2024-020', 'Low',      32.0, 28.0, 22.0, 25.0, 14.0, 20.0, 67.0, 'stable',       'Adequate performance, some assignment gaps.',                               '["Complete pending labs","Attend office hours"]')
) AS r(snum, risk_level, prob, gi, ai, acti, dp, gdl, se, trend, expl, recs)
JOIN students s ON s.student_number = r.snum;


-- ============================================================
-- INTERVENTION PLANS
-- Lookup student_id by student_number, advisor_id by email
-- ============================================================
INSERT INTO intervention_plans (student_id, advisor_id, title, description, status, priority, deadline)
SELECT s.id, adv.id, ip.title, ip.descr, ip.status::intervention_status, ip.priority::priority_level, NOW() + ip.delta::INTERVAL
FROM (VALUES
    ('STU-2023-002', 'k.park@eduguard.edu',  'Academic Recovery Plan',        'Improve assignment completion and attendance for Bob',          'active',  'high',   '30 days'),
    ('STU-2024-004', 'k.park@eduguard.edu',  'Critical Intervention',         'Emergency support for David Brown — critical dropout risk',     'active',  'high',   '14 days'),
    ('STU-2022-016', 'r.green@eduguard.edu', 'Engagement Boost — Peter',      'Increase participation in NET courses',                         'pending', 'medium', '45 days'),
    ('STU-2021-008', 'k.park@eduguard.edu',  'Attendance Improvement — Henry','Address chronic absenteeism in SE courses',                     'active',  'high',   '21 days')
) AS ip(snum, adv_email, title, descr, status, priority, delta)
JOIN students  s   ON s.student_number = ip.snum
JOIN users     au  ON au.email         = ip.adv_email
JOIN advisors  adv ON adv.user_id      = au.id;


-- ============================================================
-- INTERVENTION ACTIONS
-- Lookup plan_id by plan title + student
-- ============================================================
INSERT INTO intervention_actions (plan_id, description, completed, order_index)
SELECT ip.id, a.descr, a.done, a.ord
FROM (VALUES
    ('STU-2023-002', 'Academic Recovery Plan',         'Schedule weekly tutoring for CS301', TRUE,  1),
    ('STU-2023-002', 'Academic Recovery Plan',         'Meet with advisor bi-weekly',        FALSE, 2),
    ('STU-2023-002', 'Academic Recovery Plan',         'Complete all pending assignments',   FALSE, 3),
    ('STU-2024-004', 'Critical Intervention',          'Emergency advisor meeting',          TRUE,  1),
    ('STU-2024-004', 'Critical Intervention',          'Connect with counseling services',   FALSE, 2),
    ('STU-2024-004', 'Critical Intervention',          'Review and reduce course load',      FALSE, 3),
    ('STU-2022-016', 'Engagement Boost — Peter',       'Set up daily study reminders',       FALSE, 1),
    ('STU-2022-016', 'Engagement Boost — Peter',       'Join NET study group',               FALSE, 2),
    ('STU-2021-008', 'Attendance Improvement — Henry', 'Set up attendance monitoring',       TRUE,  1),
    ('STU-2021-008', 'Attendance Improvement — Henry', 'Identify personal barriers',         FALSE, 2),
    ('STU-2021-008', 'Attendance Improvement — Henry', 'Create attendance contract',         FALSE, 3)
) AS a(snum, plan_title, descr, done, ord)
JOIN students          s  ON s.student_number = a.snum
JOIN intervention_plans ip ON ip.student_id  = s.id AND ip.title = a.plan_title;


-- ============================================================
-- QUIZZES
-- Lookup course_id by course_code, created_by by email
-- ============================================================
INSERT INTO quizzes (title, description, course_id, created_by, duration_minutes, attempts_limit,
                     start_time, end_time, shuffle_questions, status, total_points)
SELECT q.title, q.descr, c.id, u.id, q.dur, q.attempts,
       NOW() + q.start_off::INTERVAL, NOW() + q.end_off::INTERVAL,
       q.shuffle, q.status::quiz_status, q.points
FROM (VALUES
    ('Advanced Algorithms Quiz #3', 'Graph algorithms and dynamic programming', 'CS301', 'j.anderson@eduguard.edu', 60, 2, '-2 days', '3 days',   TRUE,  'published', 50),
    ('Data Structures Midterm',      'Comprehensive midterm',                    'CS201', 'j.anderson@eduguard.edu', 90, 1, '-5 days', '1 day',    FALSE, 'published', 100),
    ('AI401 ML Fundamentals Quiz',   'Supervised learning algorithms',           'AI401', 'e.chen@eduguard.edu',     45, 1, '2 days',  '7 days',   TRUE,  'draft',     30),
    ('Database Systems Assessment',  'SQL and data modeling',                    'IS201', 'r.davis@eduguard.edu',    60, 1, '-10 days','-3 days',  FALSE, 'closed',    40)
) AS q(title, descr, course_code, prof_email, dur, attempts, start_off, end_off, shuffle, status, points)
JOIN courses c ON c.code     = q.course_code
JOIN users   u ON u.email    = q.prof_email;

INSERT INTO questions (quiz_id, type, text, options_json, correct_answer, points, order_index)
SELECT q.id, 'multiple_choice',
    'What is the time complexity of Dijkstra''s algorithm with a binary heap?',
    '["O(V²)","O((V+E) log V)","O(V log V)","O(E log V)"]',
    'O((V+E) log V)', 5, 1
FROM quizzes q WHERE q.title = 'Advanced Algorithms Quiz #3';

INSERT INTO questions (quiz_id, type, text, options_json, correct_answer, points, order_index)
SELECT q.id, 'true_false',
    'Dynamic programming always requires memorization of all subproblems.',
    '["True","False"]', 'False', 3, 2
FROM quizzes q WHERE q.title = 'Advanced Algorithms Quiz #3';

INSERT INTO questions (quiz_id, type, text, options_json, correct_answer, points, order_index)
SELECT q.id, 'multiple_choice',
    'Worst-case time complexity of quicksort?',
    '["O(n log n)","O(n²)","O(n)","O(log n)"]',
    'O(n²)', 5, 1
FROM quizzes q WHERE q.title = 'Data Structures Midterm';


-- ============================================================
-- NOTIFICATIONS
-- Lookup user_id by email
-- ============================================================
INSERT INTO notifications (user_id, title, message, type, priority, read)
SELECT u.id, n.title, n.msg, n.type::notification_type, n.pri::priority_level, n.rd
FROM (VALUES
    ('admin@eduguard.edu',              'Critical Risk Alert',       'David Brown reached critical risk (91%)',    'risk_alert',   'high',   FALSE),
    ('admin@eduguard.edu',              'New Intervention Assigned', 'Academic Recovery Plan assigned to Bob',     'intervention', 'medium', FALSE),
    ('admin@eduguard.edu',              'Quiz Results Available',    'Algorithms Quiz #3 results ready',           'quiz',         'low',    TRUE),
    ('admin@eduguard.edu',              'Grade Drop Detected',       'Henry Wilson GPA dropped significantly',     'grade',        'high',   FALSE),
    ('admin@eduguard.edu',              'System Update',             'EduGuard AI upgraded to v3.0',               'system',       'low',    TRUE),
    ('j.anderson@eduguard.edu',         'New Submission',            '12 students submitted Algorithms Quiz #3',   'quiz',         'low',    FALSE),
    ('j.anderson@eduguard.edu',         'Risk Alert',                'Two students in CS301 show high risk',       'risk_alert',   'high',   FALSE),
    ('alice@student.eduguard.edu',      'Quiz Available',            'Advanced Algorithms Quiz #3 is now open',   'quiz',         'medium', FALSE),
    ('alice@student.eduguard.edu',      'Grade Posted',              'Your Data Structures grade: 92.0',           'grade',        'low',    FALSE),
    ('bob@student.eduguard.edu',        'Attendance Warning',        'Your attendance dropped below 70%',          'attendance',   'high',   FALSE),
    ('bob@student.eduguard.edu',        'Advisor Meeting',           'Your advisor requests an urgent meeting',    'intervention', 'high',   FALSE)
) AS n(email, title, msg, type, pri, rd)
JOIN users u ON u.email = n.email;


-- ============================================================
-- ACTIVITY LOGS
-- Lookup student_id by student_number
-- ============================================================
INSERT INTO activity_logs (student_id, action, duration_minutes, resource_type, resource_id)
SELECT s.id, a.action, a.dur, a.rtype, a.rid
FROM (VALUES
    ('STU-2022-001', 'quiz_attempt',  45, 'quiz',   NULL::BIGINT),
    ('STU-2022-001', 'course_view',   30, 'course', NULL::BIGINT),
    ('STU-2023-002', 'course_view',    5, 'course', NULL::BIGINT),
    ('STU-2024-004', 'login',          2, NULL,     NULL::BIGINT),
    ('STU-2023-012', 'quiz_attempt',  42, 'quiz',   NULL::BIGINT),
    ('STU-2023-012', 'course_view',   60, 'course', NULL::BIGINT),
    ('STU-2023-014', 'course_view',    8, 'course', NULL::BIGINT)
) AS a(snum, action, dur, rtype, rid)
JOIN students s ON s.student_number = a.snum;


-- ============================================================
-- ANNOUNCEMENTS
-- Lookup author_id by email, course_id by code
-- ============================================================
INSERT INTO announcements (title, content, author_id, is_global, published_at)
SELECT u.id, a.title, a.content, TRUE, NOW() + a.off::INTERVAL
FROM (VALUES
    ('admin@eduguard.edu', 'Welcome to Fall 2025 Semester',
     'Welcome all students. Please verify enrollment and check your course schedules.',
     '-5 days'),
    ('admin@eduguard.edu', 'EduGuard AI System Upgrade',
     'AI risk prediction upgraded to v3.0 with improved accuracy.',
     '-2 days'),
    ('admin@eduguard.edu', 'Mid-Semester Grade Review',
     'Professors: submit all mid-semester grades by end of week.',
     '-1 day')
) AS a(email, title, content, off)
JOIN users u ON u.email = a.email;

INSERT INTO announcements (title, content, author_id, course_id, is_global, published_at)
SELECT u.id, an.title, an.content, c.id, FALSE, NOW() + an.off::INTERVAL
FROM (VALUES
    ('j.anderson@eduguard.edu', 'CS301', 'CS301 Quiz #3 Guidelines',
     'Review chapters 8–12 before the quiz. No calculators permitted.', '-3 days'),
    ('e.chen@eduguard.edu',     'AI401', 'AI401 Office Hours Extended',
     'Office hours this week extended to Thursday 3–6 PM.',             '-1 day')
) AS an(email, course_code, title, content, off)
JOIN users   u ON u.email = an.email
JOIN courses c ON c.code  = an.course_code;

-- ============================================================
-- END — run 003_views.sql next
-- ============================================================
