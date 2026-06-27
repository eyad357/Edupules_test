-- ============================================================
-- EduGuard AI — Production-Safe Seed Data v5.0
-- Sprint 4 complete, idempotent, FK-safe
-- ============================================================

TRUNCATE TABLE
    transcript_verifications,
    transcript_versions,
    academic_audit_entries,
    registrar_notes,
    academic_risk_records,
    gpa_projections,
    honors_records,
    graduation_eligibility_records,
    degree_progress_snapshots,
    academic_status_history,
    academic_timeline_events,
    semester_snapshots,
    academic_terms,
    grade_records,
    quiz_submissions,
    questions,
    announcements, activity_logs, notifications,
    intervention_actions, intervention_plans,
    risk_assessments, attendances, enrollments,
    quizzes, courses,
    teaching_assistants, advisors, professors, students,
    users, departments
CASCADE;

ALTER SEQUENCE departments_id_seq RESTART WITH 1;
ALTER SEQUENCE users_id_seq       RESTART WITH 1;

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
-- USERS — Admins
-- ============================================================
INSERT INTO users (name, email, hashed_password, role) VALUES
('Dr. Sarah Mitchell',   'admin@eduguard.edu',    '$2b$12$B9/i4YIFdYbEHQuHT2NCFel3kX9xI5RHTLxDURNlVlDPAvH72/maO', 'admin'),
('System Administrator', 'sysadmin@eduguard.edu', '$2b$12$B9/i4YIFdYbEHQuHT2NCFel3kX9xI5RHTLxDURNlVlDPAvH72/maO', 'admin');

INSERT INTO users (name, email, hashed_password, role) VALUES
('Prof. James Anderson', 'j.anderson@eduguard.edu', '$2b$12$B9/i4YIFdYbEHQuHT2NCFel3kX9xI5RHTLxDURNlVlDPAvH72/maO', 'professor'),
('Prof. Emily Chen',     'e.chen@eduguard.edu',     '$2b$12$B9/i4YIFdYbEHQuHT2NCFel3kX9xI5RHTLxDURNlVlDPAvH72/maO', 'professor'),
('Prof. Robert Davis',   'r.davis@eduguard.edu',    '$2b$12$B9/i4YIFdYbEHQuHT2NCFel3kX9xI5RHTLxDURNlVlDPAvH72/maO', 'professor'),
('Prof. Lisa Thompson',  'l.thompson@eduguard.edu', '$2b$12$B9/i4YIFdYbEHQuHT2NCFel3kX9xI5RHTLxDURNlVlDPAvH72/maO', 'professor'),
('Prof. Michael Wong',   'm.wong@eduguard.edu',     '$2b$12$B9/i4YIFdYbEHQuHT2NCFel3kX9xI5RHTLxDURNlVlDPAvH72/maO', 'professor'),
('Prof. Anna Martinez',  'a.martinez@eduguard.edu', '$2b$12$B9/i4YIFdYbEHQuHT2NCFel3kX9xI5RHTLxDURNlVlDPAvH72/maO', 'professor'),
('Prof. David Nguyen',   'd.nguyen@eduguard.edu',   '$2b$12$B9/i4YIFdYbEHQuHT2NCFel3kX9xI5RHTLxDURNlVlDPAvH72/maO', 'professor');

INSERT INTO users (name, email, hashed_password, role) VALUES
('Dr. Kevin Park',   'k.park@eduguard.edu',  '$2b$12$B9/i4YIFdYbEHQuHT2NCFel3kX9xI5RHTLxDURNlVlDPAvH72/maO', 'advisor'),
('Dr. Rachel Green', 'r.green@eduguard.edu', '$2b$12$B9/i4YIFdYbEHQuHT2NCFel3kX9xI5RHTLxDURNlVlDPAvH72/maO', 'advisor');

INSERT INTO users (name, email, hashed_password, role) VALUES
('Marcus Johnson',  'ta.marcus@eduguard.edu', '$2b$12$B9/i4YIFdYbEHQuHT2NCFel3kX9xI5RHTLxDURNlVlDPAvH72/maO', 'ta'),
('Sofia Rodriguez', 'ta.sofia@eduguard.edu',  '$2b$12$B9/i4YIFdYbEHQuHT2NCFel3kX9xI5RHTLxDURNlVlDPAvH72/maO', 'ta');

INSERT INTO users (name, email, hashed_password, role) VALUES
('Ahmed Hassan',      'ahmed.hassan@student.eduguard.edu',      '$2b$12$B9/i4YIFdYbEHQuHT2NCFel3kX9xI5RHTLxDURNlVlDPAvH72/maO', 'student'),
('Mariam Hassan',     'mariam.hassan@student.eduguard.edu',     '$2b$12$B9/i4YIFdYbEHQuHT2NCFel3kX9xI5RHTLxDURNlVlDPAvH72/maO', 'student'),
('Omar Khaled',       'omar.khaled@student.eduguard.edu',       '$2b$12$B9/i4YIFdYbEHQuHT2NCFel3kX9xI5RHTLxDURNlVlDPAvH72/maO', 'student'),
('Nourhan Ali',       'nourhan.ali@student.eduguard.edu',       '$2b$12$B9/i4YIFdYbEHQuHT2NCFel3kX9xI5RHTLxDURNlVlDPAvH72/maO', 'student'),
('Youssef Mostafa',   'youssef.mostafa@student.eduguard.edu',   '$2b$12$B9/i4YIFdYbEHQuHT2NCFel3kX9xI5RHTLxDURNlVlDPAvH72/maO', 'student'),
('Farah Mahmoud',     'farah.mahmoud@student.eduguard.edu',     '$2b$12$B9/i4YIFdYbEHQuHT2NCFel3kX9xI5RHTLxDURNlVlDPAvH72/maO', 'student'),
('Salma Khaled',      'salma.khaled@student.eduguard.edu',      '$2b$12$B9/i4YIFdYbEHQuHT2NCFel3kX9xI5RHTLxDURNlVlDPAvH72/maO', 'student'),
('Hana Tarek',        'hana.tarek@student.eduguard.edu',        '$2b$12$B9/i4YIFdYbEHQuHT2NCFel3kX9xI5RHTLxDURNlVlDPAvH72/maO', 'student'),
('Mahmoud Tarek',     'mahmoud.tarek@student.eduguard.edu',     '$2b$12$B9/i4YIFdYbEHQuHT2NCFel3kX9xI5RHTLxDURNlVlDPAvH72/maO', 'student'),
('Karim Adel',        'karim.adel@student.eduguard.edu',        '$2b$12$B9/i4YIFdYbEHQuHT2NCFel3kX9xI5RHTLxDURNlVlDPAvH72/maO', 'student'),
('Aya Mostafa',       'aya.mostafa@student.eduguard.edu',       '$2b$12$B9/i4YIFdYbEHQuHT2NCFel3kX9xI5RHTLxDURNlVlDPAvH72/maO', 'student'),
('Abdelrahman Ahmed', 'abdelrahman.ahmed@student.eduguard.edu', '$2b$12$B9/i4YIFdYbEHQuHT2NCFel3kX9xI5RHTLxDURNlVlDPAvH72/maO', 'student'),
('Sara Mohamed',      'sara.mohamed@student.eduguard.edu',      '$2b$12$B9/i4YIFdYbEHQuHT2NCFel3kX9xI5RHTLxDURNlVlDPAvH72/maO', 'student'),
('Mostafa Samir',     'mostafa.samir@student.eduguard.edu',     '$2b$12$B9/i4YIFdYbEHQuHT2NCFel3kX9xI5RHTLxDURNlVlDPAvH72/maO', 'student'),
('Hassan Ibrahim',    'hassan.ibrahim@student.eduguard.edu',    '$2b$12$B9/i4YIFdYbEHQuHT2NCFel3kX9xI5RHTLxDURNlVlDPAvH72/maO', 'student'),
('Amr Nabil',         'amr.nabil@student.eduguard.edu',         '$2b$12$B9/i4YIFdYbEHQuHT2NCFel3kX9xI5RHTLxDURNlVlDPAvH72/maO', 'student'),
('Mohamed Ali',       'mohamed.ali@student.eduguard.edu',       '$2b$12$B9/i4YIFdYbEHQuHT2NCFel3kX9xI5RHTLxDURNlVlDPAvH72/maO', 'student'),
('Layla Ahmed',       'layla.ahmed@student.eduguard.edu',       '$2b$12$B9/i4YIFdYbEHQuHT2NCFel3kX9xI5RHTLxDURNlVlDPAvH72/maO', 'student'),
('Tarek Hassan',      'tarek.hassan@student.eduguard.edu',      '$2b$12$B9/i4YIFdYbEHQuHT2NCFel3kX9xI5RHTLxDURNlVlDPAvH72/maO', 'student'),
('Rania Mostafa',     'rania.mostafa@student.eduguard.edu',     '$2b$12$B9/i4YIFdYbEHQuHT2NCFel3kX9xI5RHTLxDURNlVlDPAvH72/maO', 'student'),
('Khaled Samir',      'khaled.samir@student.eduguard.edu',      '$2b$12$B9/i4YIFdYbEHQuHT2NCFel3kX9xI5RHTLxDURNlVlDPAvH72/maO', 'student');

-- ============================================================
-- PROFESSORS
-- ============================================================
INSERT INTO professors (user_id, department_id, department, title, specialization, office_location, office_hours)
SELECT u.id, d.id, d.name, p.title, p.spec, p.office, p.hours
FROM (VALUES
    ('j.anderson@eduguard.edu','CS', 'Associate Professor','Algorithms & Data Structures',    'CS Building, Room 305', 'Mon/Wed 2-4 PM'),
    ('e.chen@eduguard.edu',    'AI', 'Professor',          'Machine Learning & Deep Learning','CS Building, Room 210', 'Tue/Thu 10-12 PM'),
    ('r.davis@eduguard.edu',   'IS', 'Assistant Professor','Database Systems & Analytics',    'IS Building, Room 102', 'Mon/Fri 1-3 PM'),
    ('l.thompson@eduguard.edu','NET','Professor',          'Network Protocols & Security',    'NET Lab, Room 401',     'Wed/Thu 3-5 PM'),
    ('m.wong@eduguard.edu',    'SE', 'Associate Professor','Software Architecture & DevOps',  'SE Building, Room 215', 'Tue/Thu 2-4 PM'),
    ('a.martinez@eduguard.edu','SEC','Assistant Professor','Ethical Hacking & Forensics',     'SEC Lab, Room 118',     'Mon/Wed/Fri 11-12 PM'),
    ('d.nguyen@eduguard.edu',  'DS', 'Associate Professor','Statistical Learning & Viz',      'DS Building, Room 330', 'Mon/Wed 3-5 PM')
) AS p(email, dept_code, title, spec, office, hours)
JOIN users u ON u.email = p.email
JOIN departments d ON d.code = p.dept_code;

-- ============================================================
-- ADVISORS
-- ============================================================
INSERT INTO advisors (user_id, department_id, specialization, max_students)
SELECT u.id, d.id, a.spec, a.max_stu
FROM (VALUES
    ('k.park@eduguard.edu',  'CS','CS & AI Counseling',       35),
    ('r.green@eduguard.edu', 'IS','IS & Networks Counseling', 30)
) AS a(email, dept_code, spec, max_stu)
JOIN users u ON u.email = a.email
JOIN departments d ON d.code = a.dept_code;

-- ============================================================
-- TEACHING ASSISTANTS
-- ============================================================
INSERT INTO teaching_assistants (user_id, professor_id, department_id)
SELECT ta_u.id, p.id, d.id
FROM (VALUES
    ('ta.marcus@eduguard.edu','j.anderson@eduguard.edu','CS'),
    ('ta.sofia@eduguard.edu', 'e.chen@eduguard.edu',    'AI')
) AS t(ta_email, prof_email, dept_code)
JOIN users ta_u ON ta_u.email = t.ta_email
JOIN users pu   ON pu.email   = t.prof_email
JOIN professors p ON p.user_id = pu.id
JOIN departments d ON d.code = t.dept_code;

-- ============================================================
-- STUDENTS
-- ============================================================
INSERT INTO students (user_id, student_number, department_id, major, year, gpa, enrollment_date, advisor_id, is_scholarship)
SELECT u.id, s.snum, d.id, s.major, s.yr, s.gpa, s.enroll::DATE, adv.id, s.scholar
FROM (VALUES
    ('ahmed.hassan@student.eduguard.edu',      'CS2021001','CS', 'Computer Science',        4,3.88,'2021-09-01','k.park@eduguard.edu', TRUE),
    ('mariam.hassan@student.eduguard.edu',     'CS2021002','CS', 'Computer Science',        4,3.72,'2021-09-01','k.park@eduguard.edu', TRUE),
    ('omar.khaled@student.eduguard.edu',       'CS2022003','CS', 'Computer Science',        3,3.55,'2022-09-01','k.park@eduguard.edu', FALSE),
    ('nourhan.ali@student.eduguard.edu',       'CS2022004','CS', 'Computer Science',        3,3.40,'2022-09-01','k.park@eduguard.edu', FALSE),
    ('youssef.mostafa@student.eduguard.edu',   'CS2023005','CS', 'Computer Science',        2,2.85,'2023-09-01','k.park@eduguard.edu', FALSE),
    ('farah.mahmoud@student.eduguard.edu',     'CS2023006','CS', 'Computer Science',        2,2.60,'2023-09-01','k.park@eduguard.edu', FALSE),
    ('salma.khaled@student.eduguard.edu',      'CS2024007','CS', 'Computer Science',        1,3.10,'2024-09-01','k.park@eduguard.edu', FALSE),
    ('hana.tarek@student.eduguard.edu',        'CS2024008','CS', 'Computer Science',        1,1.90,'2024-09-01','k.park@eduguard.edu', FALSE),
    ('mahmoud.tarek@student.eduguard.edu',     'AI2022009','AI', 'Artificial Intelligence', 3,3.78,'2022-09-01','k.park@eduguard.edu', TRUE),
    ('karim.adel@student.eduguard.edu',        'AI2023010','AI', 'Artificial Intelligence', 2,2.45,'2023-09-01','k.park@eduguard.edu', FALSE),
    ('aya.mostafa@student.eduguard.edu',       'AI2023011','AI', 'Artificial Intelligence', 2,2.20,'2023-09-01','k.park@eduguard.edu', FALSE),
    ('abdelrahman.ahmed@student.eduguard.edu', 'IS2022012','IS', 'Information Systems',     3,3.62,'2022-09-01','r.green@eduguard.edu',FALSE),
    ('sara.mohamed@student.eduguard.edu',      'IS2023013','IS', 'Information Systems',     2,2.75,'2023-09-01','r.green@eduguard.edu',FALSE),
    ('mostafa.samir@student.eduguard.edu',     'NET2022014','NET','Computer Networks',      3,3.50,'2022-09-01','r.green@eduguard.edu',FALSE),
    ('hassan.ibrahim@student.eduguard.edu',    'NET2023015','NET','Computer Networks',      2,2.30,'2023-09-01','r.green@eduguard.edu',FALSE),
    ('amr.nabil@student.eduguard.edu',         'SE2021016','SE', 'Software Engineering',    4,1.75,'2021-09-01','r.green@eduguard.edu',FALSE),
    ('mohamed.ali@student.eduguard.edu',       'SE2023017','SE', 'Software Engineering',    2,2.95,'2023-09-01','r.green@eduguard.edu',FALSE),
    ('layla.ahmed@student.eduguard.edu',       'SEC2022018','SEC','Cybersecurity',          3,3.65,'2022-09-01','r.green@eduguard.edu',FALSE),
    ('tarek.hassan@student.eduguard.edu',      'SEC2023019','SEC','Cybersecurity',          2,2.80,'2023-09-01','r.green@eduguard.edu',FALSE),
    ('rania.mostafa@student.eduguard.edu',     'DS2021020','DS', 'Data Science',            4,3.82,'2021-09-01','k.park@eduguard.edu', TRUE),
    ('khaled.samir@student.eduguard.edu',      'DS2023021','DS', 'Data Science',            2,1.60,'2023-09-01','k.park@eduguard.edu', FALSE)
) AS s(email, snum, dept_code, major, yr, gpa, enroll, adv_email, scholar)
JOIN users u   ON u.email     = s.email
JOIN departments d ON d.code  = s.dept_code
JOIN users au  ON au.email    = s.adv_email
JOIN advisors adv ON adv.user_id = au.id;

-- ============================================================
-- COURSES
-- ============================================================
INSERT INTO courses (code, name, description, credits, semester, year, professor_id, department_id, max_students)
SELECT c.code, c.name, c.descr, c.cred, c.sem, c.yr, p.id, d.id, c.max_stu
FROM (VALUES
    ('CS301', 'Advanced Algorithms',      'Algorithm design, complexity, graph theory',       3,'Fall',  2025,'j.anderson@eduguard.edu','CS', 40),
    ('CS201', 'Data Structures',          'Fundamental data structures and applications',     3,'Fall',  2025,'j.anderson@eduguard.edu','CS', 40),
    ('CS101', 'Intro to Programming',     'Python fundamentals, OOP',                         3,'Spring',2025,'j.anderson@eduguard.edu','CS', 60),
    ('AI401', 'Machine Learning',         'Supervised and unsupervised learning',             4,'Fall',  2025,'e.chen@eduguard.edu',    'AI',35),
    ('AI301', 'Neural Networks',          'Deep learning architectures',                      3,'Fall',  2025,'e.chen@eduguard.edu',    'AI',30),
    ('IS201', 'Database Systems',         'SQL, NoSQL, data modeling',                        3,'Fall',  2025,'r.davis@eduguard.edu',   'IS',45),
    ('IS301', 'Business Intelligence',    'Data warehousing and reporting',                   3,'Fall',  2025,'r.davis@eduguard.edu',   'IS',35),
    ('NET301','Computer Networks',        'TCP/IP, routing protocols',                        3,'Fall',  2025,'l.thompson@eduguard.edu','NET',40),
    ('NET401','Network Security',         'Firewalls, VPNs, intrusion detection',             3,'Fall',  2025,'l.thompson@eduguard.edu','NET',30),
    ('SE301', 'Software Architecture',    'Design patterns, microservices',                   3,'Fall',  2025,'m.wong@eduguard.edu',    'SE',35),
    ('SE101', 'Software Foundations',     'SDLC, agile, version control',                     2,'Spring',2025,'m.wong@eduguard.edu',    'SE',50),
    ('SEC301','Ethical Hacking',          'Penetration testing and vulnerability assessment', 3,'Fall',  2025,'a.martinez@eduguard.edu','SEC',30),
    ('SEC201','Cryptography',             'Encryption algorithms and PKI',                    3,'Fall',  2025,'a.martinez@eduguard.edu','SEC',35),
    ('DS301', 'Data Science Fundamentals','Statistics, Python, data pipelines',               3,'Fall',  2025,'d.nguyen@eduguard.edu',  'DS',40),
    ('DS401', 'Machine Learning for DS',  'Applied ML for data science workflows',            3,'Fall',  2025,'d.nguyen@eduguard.edu',  'DS',35)
) AS c(code, name, descr, cred, sem, yr, prof_email, dept_code, max_stu)
JOIN users pu ON pu.email = c.prof_email
JOIN professors p ON p.user_id = pu.id
JOIN departments d ON d.code = c.dept_code;

-- ============================================================
-- ENROLLMENTS
-- ============================================================
INSERT INTO enrollments (student_id, course_id, status, grade)
SELECT s.id, c.id, e.status, e.grade
FROM (VALUES
    ('CS2021001','CS301','completed',97.0),('CS2021001','CS201','completed',95.0),
    ('CS2021001','IS201','completed',93.0),('CS2021001','AI401','active',96.0),
    ('CS2021002','CS301','completed',91.0),('CS2021002','CS201','completed',93.0),
    ('CS2021002','IS301','completed',88.0),('CS2021002','AI301','active',90.0),
    ('CS2022003','CS301','active',88.0),('CS2022003','CS201','active',85.0),('CS2022003','CS101','completed',90.0),
    ('CS2022004','CS301','active',84.0),('CS2022004','CS201','active',82.0),('CS2022004','IS201','active',87.0),
    ('CS2023005','CS101','completed',76.0),('CS2023005','CS201','active',72.0),('CS2023005','SE101','active',68.0),
    ('CS2023006','CS101','completed',68.0),('CS2023006','CS201','active',65.0),('CS2023006','IS201','active',62.0),
    ('CS2024007','CS101','active',78.0),('CS2024007','SE101','active',80.0),
    ('CS2024008','CS101','active',52.0),('CS2024008','SE101','active',44.0),
    ('AI2022009','AI401','active',94.0),('AI2022009','AI301','active',93.0),('AI2022009','CS301','completed',95.0),
    ('AI2023010','AI401','active',62.0),('AI2023010','AI301','active',60.0),('AI2023010','CS101','completed',66.0),
    ('AI2023011','AI401','active',55.0),('AI2023011','AI301','active',57.0),('AI2023011','CS101','completed',60.0),
    ('IS2022012','IS201','active',92.0),('IS2022012','IS301','active',89.0),('IS2022012','CS201','completed',90.0),
    ('IS2023013','IS201','active',72.0),('IS2023013','CS101','completed',69.0),('IS2023013','SE101','active',70.0),
    ('NET2022014','NET301','active',88.0),('NET2022014','NET401','active',87.0),('NET2022014','CS301','completed',86.0),
    ('NET2023015','NET301','active',60.0),('NET2023015','CS101','completed',55.0),('NET2023015','SE101','active',58.0),
    ('SE2021016','SE301','active',44.0),('SE2021016','SE101','active',38.0),('SE2021016','CS301','active',42.0),
    ('SE2023017','SE101','active',76.0),('SE2023017','CS101','completed',73.0),('SE2023017','CS201','active',74.0),
    ('SEC2022018','SEC301','active',92.0),('SEC2022018','SEC201','active',91.0),('SEC2022018','CS301','completed',89.0),
    ('SEC2023019','SEC301','active',74.0),('SEC2023019','SEC201','active',70.0),('SEC2023019','CS101','completed',72.0),
    ('DS2021020','DS301','completed',96.0),('DS2021020','DS401','active',95.0),('DS2021020','AI401','completed',93.0),
    ('DS2023021','DS301','active',40.0),('DS2023021','DS401','active',38.0),('DS2023021','CS101','active',42.0)
) AS e(snum, course_code, status, grade)
JOIN students s ON s.student_number = e.snum
JOIN courses c ON c.code = e.course_code;

-- ============================================================
-- ATTENDANCES
-- ============================================================
INSERT INTO attendances (student_id, course_id, date, status)
SELECT s.id, c.id, a.dt, a.status::attendance_status
FROM (VALUES
    ('CS2021001','CS301',CURRENT_DATE-1,'present'),('CS2021001','CS301',CURRENT_DATE-3,'present'),
    ('CS2021001','CS301',CURRENT_DATE-5,'present'),('CS2021001','CS301',CURRENT_DATE-8,'present'),
    ('CS2021001','CS301',CURRENT_DATE-10,'present'),('CS2021001','CS201',CURRENT_DATE-2,'present'),
    ('CS2021001','CS201',CURRENT_DATE-4,'present'),('CS2021001','CS201',CURRENT_DATE-7,'present'),
    ('CS2021001','IS201',CURRENT_DATE-6,'present'),('CS2021001','IS201',CURRENT_DATE-9,'present'),
    ('CS2021001','AI401',CURRENT_DATE-11,'present'),('CS2021001','AI401',CURRENT_DATE-12,'present'),
    ('CS2021002','CS301',CURRENT_DATE-1,'present'),('CS2021002','CS301',CURRENT_DATE-3,'present'),
    ('CS2021002','CS301',CURRENT_DATE-5,'present'),('CS2021002','CS201',CURRENT_DATE-2,'present'),
    ('CS2021002','CS201',CURRENT_DATE-4,'present'),('CS2021002','AI301',CURRENT_DATE-6,'present'),
    ('CS2021002','AI301',CURRENT_DATE-8,'present'),('CS2021002','IS301',CURRENT_DATE-7,'late'),
    ('CS2022003','CS301',CURRENT_DATE-1,'present'),('CS2022003','CS301',CURRENT_DATE-3,'present'),
    ('CS2022003','CS301',CURRENT_DATE-5,'late'),('CS2022003','CS201',CURRENT_DATE-2,'present'),
    ('CS2022003','CS201',CURRENT_DATE-4,'present'),('CS2022003','CS101',CURRENT_DATE-6,'present'),
    ('CS2022003','CS101',CURRENT_DATE-9,'absent'),
    ('CS2022004','CS301',CURRENT_DATE-1,'present'),('CS2022004','CS301',CURRENT_DATE-3,'present'),
    ('CS2022004','CS201',CURRENT_DATE-2,'present'),('CS2022004','CS201',CURRENT_DATE-4,'present'),
    ('CS2022004','IS201',CURRENT_DATE-5,'present'),('CS2022004','IS201',CURRENT_DATE-7,'late'),
    ('CS2023005','CS101',CURRENT_DATE-2,'present'),('CS2023005','CS101',CURRENT_DATE-5,'absent'),
    ('CS2023005','CS201',CURRENT_DATE-1,'present'),('CS2023005','CS201',CURRENT_DATE-4,'late'),
    ('CS2023005','SE101',CURRENT_DATE-3,'present'),('CS2023005','SE101',CURRENT_DATE-7,'absent'),
    ('CS2023006','CS101',CURRENT_DATE-2,'present'),('CS2023006','CS101',CURRENT_DATE-5,'absent'),
    ('CS2023006','CS201',CURRENT_DATE-1,'late'),('CS2023006','CS201',CURRENT_DATE-4,'absent'),
    ('CS2023006','IS201',CURRENT_DATE-3,'present'),('CS2023006','IS201',CURRENT_DATE-8,'absent'),
    ('CS2024007','CS101',CURRENT_DATE-1,'present'),('CS2024007','CS101',CURRENT_DATE-3,'present'),
    ('CS2024007','CS101',CURRENT_DATE-5,'late'),('CS2024007','SE101',CURRENT_DATE-2,'present'),
    ('CS2024007','SE101',CURRENT_DATE-4,'present'),
    ('CS2024008','CS101',CURRENT_DATE-1,'absent'),('CS2024008','CS101',CURRENT_DATE-3,'absent'),
    ('CS2024008','CS101',CURRENT_DATE-5,'present'),('CS2024008','SE101',CURRENT_DATE-2,'absent'),
    ('CS2024008','SE101',CURRENT_DATE-4,'absent'),
    ('AI2022009','AI401',CURRENT_DATE-1,'present'),('AI2022009','AI401',CURRENT_DATE-3,'present'),
    ('AI2022009','AI401',CURRENT_DATE-5,'present'),('AI2022009','AI301',CURRENT_DATE-2,'present'),
    ('AI2022009','AI301',CURRENT_DATE-4,'present'),('AI2022009','CS301',CURRENT_DATE-6,'present'),
    ('AI2023010','AI401',CURRENT_DATE-1,'present'),('AI2023010','AI401',CURRENT_DATE-3,'absent'),
    ('AI2023010','AI301',CURRENT_DATE-2,'present'),('AI2023010','AI301',CURRENT_DATE-4,'late'),
    ('AI2023010','CS101',CURRENT_DATE-5,'absent'),('AI2023010','CS101',CURRENT_DATE-7,'absent'),
    ('AI2023011','AI401',CURRENT_DATE-1,'absent'),('AI2023011','AI401',CURRENT_DATE-3,'absent'),
    ('AI2023011','AI301',CURRENT_DATE-2,'present'),('AI2023011','AI301',CURRENT_DATE-4,'absent'),
    ('AI2023011','CS101',CURRENT_DATE-5,'present'),('AI2023011','CS101',CURRENT_DATE-7,'absent'),
    ('IS2022012','IS201',CURRENT_DATE-1,'present'),('IS2022012','IS201',CURRENT_DATE-3,'present'),
    ('IS2022012','IS301',CURRENT_DATE-2,'present'),('IS2022012','IS301',CURRENT_DATE-4,'present'),
    ('IS2022012','CS201',CURRENT_DATE-5,'present'),('IS2022012','CS201',CURRENT_DATE-7,'late'),
    ('IS2023013','IS201',CURRENT_DATE-1,'present'),('IS2023013','IS201',CURRENT_DATE-3,'late'),
    ('IS2023013','CS101',CURRENT_DATE-2,'present'),('IS2023013','CS101',CURRENT_DATE-5,'absent'),
    ('IS2023013','SE101',CURRENT_DATE-4,'present'),('IS2023013','SE101',CURRENT_DATE-7,'absent'),
    ('NET2022014','NET301',CURRENT_DATE-1,'present'),('NET2022014','NET301',CURRENT_DATE-3,'present'),
    ('NET2022014','NET401',CURRENT_DATE-2,'present'),('NET2022014','NET401',CURRENT_DATE-4,'present'),
    ('NET2022014','CS301',CURRENT_DATE-5,'present'),('NET2022014','CS301',CURRENT_DATE-7,'late'),
    ('NET2023015','NET301',CURRENT_DATE-1,'absent'),('NET2023015','NET301',CURRENT_DATE-3,'present'),
    ('NET2023015','CS101',CURRENT_DATE-2,'absent'),('NET2023015','CS101',CURRENT_DATE-4,'absent'),
    ('NET2023015','SE101',CURRENT_DATE-5,'present'),('NET2023015','SE101',CURRENT_DATE-7,'absent'),
    ('SE2021016','SE301',CURRENT_DATE-1,'absent'),('SE2021016','SE301',CURRENT_DATE-3,'absent'),
    ('SE2021016','SE301',CURRENT_DATE-5,'absent'),('SE2021016','SE101',CURRENT_DATE-2,'absent'),
    ('SE2021016','SE101',CURRENT_DATE-4,'present'),('SE2021016','CS301',CURRENT_DATE-6,'absent'),
    ('SE2023017','SE101',CURRENT_DATE-1,'present'),('SE2023017','SE101',CURRENT_DATE-3,'present'),
    ('SE2023017','CS101',CURRENT_DATE-2,'present'),('SE2023017','CS101',CURRENT_DATE-4,'late'),
    ('SE2023017','CS201',CURRENT_DATE-5,'present'),('SE2023017','CS201',CURRENT_DATE-7,'absent'),
    ('SEC2022018','SEC301',CURRENT_DATE-1,'present'),('SEC2022018','SEC301',CURRENT_DATE-3,'present'),
    ('SEC2022018','SEC201',CURRENT_DATE-2,'present'),('SEC2022018','SEC201',CURRENT_DATE-4,'present'),
    ('SEC2022018','CS301',CURRENT_DATE-5,'present'),('SEC2022018','CS301',CURRENT_DATE-7,'late'),
    ('SEC2023019','SEC301',CURRENT_DATE-1,'present'),('SEC2023019','SEC301',CURRENT_DATE-3,'late'),
    ('SEC2023019','SEC201',CURRENT_DATE-2,'present'),('SEC2023019','SEC201',CURRENT_DATE-4,'absent'),
    ('SEC2023019','CS101',CURRENT_DATE-5,'present'),('SEC2023019','CS101',CURRENT_DATE-7,'absent'),
    ('DS2021020','DS301',CURRENT_DATE-1,'present'),('DS2021020','DS301',CURRENT_DATE-3,'present'),
    ('DS2021020','DS401',CURRENT_DATE-2,'present'),('DS2021020','DS401',CURRENT_DATE-4,'present'),
    ('DS2021020','AI401',CURRENT_DATE-5,'present'),('DS2021020','AI401',CURRENT_DATE-7,'present'),
    ('DS2023021','DS301',CURRENT_DATE-1,'absent'),('DS2023021','DS301',CURRENT_DATE-3,'absent'),
    ('DS2023021','DS401',CURRENT_DATE-2,'absent'),('DS2023021','DS401',CURRENT_DATE-4,'present'),
    ('DS2023021','CS101',CURRENT_DATE-5,'absent'),('DS2023021','CS101',CURRENT_DATE-7,'absent')
) AS a(snum, course_code, dt, status)
JOIN students s ON s.student_number = a.snum
JOIN courses c ON c.code = a.course_code;

-- ============================================================
-- GRADE RECORDS
-- ============================================================
INSERT INTO grade_records (student_id, course_id, assessment_type, assessment_name, score, max_score, weight, graded_by)
SELECT s.id, c.id, g.atype, g.aname, g.score, g.max_s, g.wt, pu.id
FROM (VALUES
    ('CS2021001','CS301','midterm',   'CS301 Midterm Exam',    48.0,50.0,30.0,'j.anderson@eduguard.edu'),
    ('CS2021001','CS301','quiz',      'CS301 Quiz 1',          19.0,20.0,10.0,'j.anderson@eduguard.edu'),
    ('CS2021001','CS301','assignment','CS301 Project 1',       29.0,30.0,20.0,'j.anderson@eduguard.edu'),
    ('CS2021001','CS201','midterm',   'CS201 Midterm Exam',    47.0,50.0,30.0,'j.anderson@eduguard.edu'),
    ('CS2021001','CS201','quiz',      'CS201 Quiz 1',          18.0,20.0,10.0,'j.anderson@eduguard.edu'),
    ('CS2021002','CS301','midterm',   'CS301 Midterm Exam',    45.0,50.0,30.0,'j.anderson@eduguard.edu'),
    ('CS2021002','CS301','quiz',      'CS301 Quiz 1',          18.0,20.0,10.0,'j.anderson@eduguard.edu'),
    ('CS2021002','CS201','midterm',   'CS201 Midterm Exam',    46.0,50.0,30.0,'j.anderson@eduguard.edu'),
    ('SE2021016','SE301','midterm',   'SE301 Midterm Exam',    20.0,50.0,30.0,'m.wong@eduguard.edu'),
    ('SE2021016','SE301','quiz',      'SE301 Quiz 1',           8.0,20.0,10.0,'m.wong@eduguard.edu'),
    ('SE2021016','SE301','assignment','SE301 Lab Report',       8.0,30.0,20.0,'m.wong@eduguard.edu'),
    ('SE2021016','SE101','midterm',   'SE101 Midterm Exam',    15.0,50.0,30.0,'m.wong@eduguard.edu'),
    ('SE2021016','SE101','quiz',      'SE101 Quiz 1',           6.0,20.0,10.0,'m.wong@eduguard.edu'),
    ('DS2023021','DS301','midterm',   'DS301 Midterm Exam',    18.0,50.0,30.0,'d.nguyen@eduguard.edu'),
    ('DS2023021','DS301','quiz',      'DS301 Quiz 1',           7.0,20.0,10.0,'d.nguyen@eduguard.edu'),
    ('DS2023021','DS401','midterm',   'DS401 Midterm Exam',    16.0,50.0,30.0,'d.nguyen@eduguard.edu'),
    ('DS2021020','DS301','midterm',   'DS301 Midterm Exam',    49.0,50.0,30.0,'d.nguyen@eduguard.edu'),
    ('DS2021020','DS301','quiz',      'DS301 Quiz 1',          20.0,20.0,10.0,'d.nguyen@eduguard.edu'),
    ('DS2021020','DS301','project',   'DS301 Capstone Project',30.0,30.0,20.0,'d.nguyen@eduguard.edu'),
    ('AI2022009','AI401','midterm',   'AI401 Midterm Exam',    46.0,50.0,30.0,'e.chen@eduguard.edu'),
    ('AI2022009','AI401','quiz',      'AI401 Quiz 1',          19.0,20.0,10.0,'e.chen@eduguard.edu'),
    ('CS2024008','CS101','midterm',   'CS101 Midterm Exam',    24.0,50.0,30.0,'j.anderson@eduguard.edu'),
    ('CS2024008','CS101','quiz',      'CS101 Quiz 1',           9.0,20.0,10.0,'j.anderson@eduguard.edu'),
    ('CS2024008','SE101','midterm',   'SE101 Midterm Exam',    20.0,50.0,30.0,'m.wong@eduguard.edu'),
    ('SEC2022018','SEC301','midterm', 'SEC301 Midterm Exam',   45.0,50.0,30.0,'a.martinez@eduguard.edu'),
    ('SEC2022018','SEC301','quiz',    'SEC301 Quiz 1',         19.0,20.0,10.0,'a.martinez@eduguard.edu'),
    ('SEC2022018','SEC301','project', 'SEC301 Penetration Lab',29.0,30.0,20.0,'a.martinez@eduguard.edu'),
    ('NET2022014','NET301','midterm', 'NET301 Midterm Exam',   43.0,50.0,30.0,'l.thompson@eduguard.edu'),
    ('NET2022014','NET301','quiz',    'NET301 Quiz 1',         17.0,20.0,10.0,'l.thompson@eduguard.edu'),
    ('IS2022012','IS201','midterm',   'IS201 Midterm Exam',    44.0,50.0,30.0,'r.davis@eduguard.edu'),
    ('IS2022012','IS201','quiz',      'IS201 Quiz 1',          18.0,20.0,10.0,'r.davis@eduguard.edu'),
    ('IS2022012','IS201','assignment','IS201 DB Design Project',27.0,30.0,20.0,'r.davis@eduguard.edu'),
    ('AI2023011','AI401','midterm',   'AI401 Midterm Exam',    24.0,50.0,30.0,'e.chen@eduguard.edu'),
    ('AI2023011','AI401','quiz',      'AI401 Quiz 1',           9.0,20.0,10.0,'e.chen@eduguard.edu'),
    ('NET2023015','NET301','midterm', 'NET301 Midterm Exam',   27.0,50.0,30.0,'l.thompson@eduguard.edu'),
    ('NET2023015','NET301','quiz',    'NET301 Quiz 1',         10.0,20.0,10.0,'l.thompson@eduguard.edu')
) AS g(snum, course_code, atype, aname, score, max_s, wt, prof_email)
JOIN students s  ON s.student_number = g.snum
JOIN courses  c  ON c.code           = g.course_code
JOIN users    pu ON pu.email         = g.prof_email;

-- ============================================================
-- RISK ASSESSMENTS
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
    ('CS2021001','Normal',  8.0, 5.0, 3.0, 4.0, 2.0, 3.0,98.0,'improving','Exceptional performance. GPA 3.88, attendance 97%, consistently top of class.','["Consider academic excellence award","Apply for graduate school","Research assistantship recommended"]'),
    ('CS2021002','Normal', 10.0, 6.0, 4.0, 5.0, 3.0, 5.0,96.0,'stable','Strong academic profile. GPA 3.72, scholarship recipient, excellent engagement.','["Maintain current performance","Consider TA role next semester"]'),
    ('CS2022003','Low',    22.0,18.0,12.0,15.0, 8.0,12.0,80.0,'stable','Good standing. GPA 3.55, minor attendance lapses.','["Address occasional absences","Office hours recommended for CS301"]'),
    ('CS2022004','Low',    25.0,20.0,10.0,18.0, 9.0,14.0,78.0,'stable','Consistent performance. GPA 3.40, minor late arrivals only.','["Engage with study groups","Explore electives for specialization"]'),
    ('CS2023005','Normal', 30.0,28.0,22.0,25.0,14.0,20.0,65.0,'stable','Average student. GPA 2.85, attendance 78%. Manageable risk.','["Attend all remaining lectures","Complete pending SE101 assignments"]'),
    ('CS2023006','Low',    35.0,32.0,28.0,30.0,18.0,25.0,58.0,'declining','GPA 2.60 declining. Attendance gaps widening. Needs proactive support.','["Tutoring for CS201","Improve attendance immediately","Advisor check-in"]'),
    ('CS2024007','Normal', 20.0,16.0,15.0,12.0, 7.0,10.0,82.0,'improving','Strong freshman. GPA 3.10, attendance 85%. Positive trajectory.','["Maintain momentum","Explore CS clubs and hackathons"]'),
    ('CS2024008','High',   72.0,68.0,75.0,50.0,58.0,65.0,12.0,'declining','At-risk freshman. GPA 1.90, attendance 45%, failing CS101 and SE101.','["Emergency advisor meeting","Peer tutoring for CS101","Attendance contract required","Counseling referral"]'),
    ('AI2022009','Normal',  9.0, 5.0, 3.0, 4.0, 2.0, 4.0,97.0,'stable','Outstanding AI student. GPA 3.78, attendance 96%, scholarship holder.','["AI research project recommended","Conference submission encouraged"]'),
    ('AI2023010','Normal', 32.0,30.0,32.0,28.0,16.0,22.0,62.0,'stable','Borderline performance. GPA 2.45, attendance 68%.','["Attend all AI401 labs","Tutoring for Neural Networks"]'),
    ('AI2023011','High',   68.0,62.0,65.0,45.0,52.0,60.0,18.0,'declining','GPA 2.20, attendance 55%, borderline failing AI courses.','["Immediate advisor intervention","AI401 tutoring sessions","Study group enrollment"]'),
    ('IS2022012','Normal', 12.0, 8.0, 6.0, 7.0, 4.0, 6.0,90.0,'stable','Solid IS student. GPA 3.62, attendance 94%.','["Consider IS specialization electives","Present at department showcase"]'),
    ('IS2023013','Normal', 28.0,24.0,24.0,22.0,12.0,18.0,68.0,'stable','Average IS student. GPA 2.75, attendance 76%. On track.','["Improve IS201 lab submissions","Attend office hours"]'),
    ('NET2022014','Low',   18.0,14.0, 9.0,12.0, 6.0, 9.0,85.0,'stable','Good NET student. GPA 3.50, attendance 91%.','["Consider networking certifications","Maintain current pace"]'),
    ('NET2023015','High',  65.0,58.0,62.0,42.0,50.0,55.0,20.0,'declining','GPA 2.30, attendance 58%. Failing CS101. Needs immediate support.','["CS101 tutoring essential","Attendance improvement plan","Advisor meeting this week"]'),
    ('SE2021016','Critical',90.0,82.0,85.0,60.0,82.0,92.0, 5.0,'sudden_drop','CRITICAL: GPA 1.75, attendance 35%, failing all SE courses. Fourth-year probation.','["Emergency dean meeting","Academic probation review","Counseling services mandatory","Reduced course load","Weekly advisor check-ins"]'),
    ('SE2023017','Normal', 22.0,18.0,20.0,16.0, 9.0,14.0,72.0,'stable','Average SE student. GPA 2.95, attendance 80%.','["Complete SE101 projects on time","Office hours for CS201 doubts"]'),
    ('SEC2022018','Normal',11.0, 7.0, 7.0, 6.0, 4.0, 7.0,91.0,'stable','Strong SEC student. GPA 3.65, attendance 93%. Excellent lab performance.','["Security certification path recommended","Consider CTF competitions"]'),
    ('SEC2023019','Normal',27.0,22.0,21.0,20.0,11.0,16.0,70.0,'stable','Average SEC student. GPA 2.80, attendance 79%.','["Improve SEC201 lab attendance","Study cryptography fundamentals"]'),
    ('DS2021020','Normal',  7.0, 4.0, 2.0, 3.0, 2.0, 3.0,99.0,'improving','Excellent DS student. GPA 3.82, attendance 98%, scholarship holder. Graduation ready.','["Graduation application advised","Research publication opportunity"]'),
    ('DS2023021','Critical',93.0,88.0,92.0,65.0,88.0,95.0, 2.0,'sudden_drop','CRITICAL: GPA 1.60, attendance 28%, failing DS301, DS401 and CS101. Immediate intervention required.','["Emergency advisor meeting today","Counseling and mental health support","Consider academic leave","Attendance contract mandatory"]')
) AS r(snum, risk_level, prob, gi, ai, acti, dp, gdl, se, trend, expl, recs)
JOIN students s ON s.student_number = r.snum;

-- ============================================================
-- INTERVENTION PLANS
-- ============================================================
INSERT INTO intervention_plans (student_id, advisor_id, title, description, status, priority, deadline)
SELECT s.id, adv.id, ip.title, ip.descr, ip.status::intervention_status, ip.priority::priority_level, NOW() + ip.delta::INTERVAL
FROM (VALUES
    ('CS2024008','k.park@eduguard.edu','Freshman Emergency Support - Hana Tarek','Immediate academic support for first-year student failing CS101 and SE101 with 45% attendance.','active','high','21 days'),
    ('AI2023011','k.park@eduguard.edu','Academic Recovery Plan - Aya Mostafa','Address declining grades and poor attendance in AI courses before semester end.','active','high','28 days'),
    ('NET2023015','r.green@eduguard.edu','Attendance and Grade Improvement - Hassan Ibrahim','Structured attendance monitoring and tutoring plan for NET2023015.','active','medium','35 days'),
    ('SE2021016','r.green@eduguard.edu','Critical Probation Intervention - Amr Nabil','Emergency academic probation support. Fourth-year student at graduation risk. Mandatory counseling and dean review.','active','high','14 days'),
    ('DS2023021','k.park@eduguard.edu','Critical Emergency Intervention - Khaled Samir','Most severe case this semester. Failing three courses with 28% attendance. Immediate multi-department response.','active','high','7 days'),
    ('CS2023006','k.park@eduguard.edu','Sliding Performance Support - Farah Mahmoud','Proactive support for declining GPA trend in second-year CS student.','pending','medium','45 days')
) AS ip(snum, adv_email, title, descr, status, priority, delta)
JOIN students s ON s.student_number = ip.snum
JOIN users au ON au.email = ip.adv_email
JOIN advisors adv ON adv.user_id = au.id;

-- ============================================================
-- INTERVENTION ACTIONS
-- ============================================================
INSERT INTO intervention_actions (plan_id, description, completed, order_index)
SELECT ip.id, a.descr, a.done, a.ord
FROM (VALUES
    ('CS2024008','Freshman Emergency Support - Hana Tarek','Emergency meeting with student advisor',TRUE,1),
    ('CS2024008','Freshman Emergency Support - Hana Tarek','Enroll in peer tutoring program for CS101',TRUE,2),
    ('CS2024008','Freshman Emergency Support - Hana Tarek','Sign attendance contract with department',FALSE,3),
    ('CS2024008','Freshman Emergency Support - Hana Tarek','Weekly progress check-ins for 4 weeks',FALSE,4),
    ('CS2024008','Freshman Emergency Support - Hana Tarek','Refer to student counseling services',FALSE,5),
    ('AI2023011','Academic Recovery Plan - Aya Mostafa','Schedule bi-weekly tutoring for AI401',TRUE,1),
    ('AI2023011','Academic Recovery Plan - Aya Mostafa','Meet with AI department advisor',TRUE,2),
    ('AI2023011','Academic Recovery Plan - Aya Mostafa','Complete all pending AI301 assignments',FALSE,3),
    ('AI2023011','Academic Recovery Plan - Aya Mostafa','Attendance improvement plan signed',FALSE,4),
    ('NET2023015','Attendance and Grade Improvement - Hassan Ibrahim','Set up attendance alerts',TRUE,1),
    ('NET2023015','Attendance and Grade Improvement - Hassan Ibrahim','Enroll in CS101 supplemental sessions',FALSE,2),
    ('NET2023015','Attendance and Grade Improvement - Hassan Ibrahim','Weekly advisor meetings',FALSE,3),
    ('SE2021016','Critical Probation Intervention - Amr Nabil','Dean of Students meeting scheduled',TRUE,1),
    ('SE2021016','Critical Probation Intervention - Amr Nabil','Mandatory counseling session booked',TRUE,2),
    ('SE2021016','Critical Probation Intervention - Amr Nabil','Reduced course load evaluation',FALSE,3),
    ('SE2021016','Critical Probation Intervention - Amr Nabil','Weekly professor check-ins for SE301',FALSE,4),
    ('SE2021016','Critical Probation Intervention - Amr Nabil','Graduation timeline review with registrar',FALSE,5),
    ('DS2023021','Critical Emergency Intervention - Khaled Samir','Emergency advisor meeting completed',TRUE,1),
    ('DS2023021','Critical Emergency Intervention - Khaled Samir','Mental health counseling referral issued',TRUE,2),
    ('DS2023021','Critical Emergency Intervention - Khaled Samir','Academic leave assessment in progress',FALSE,3),
    ('DS2023021','Critical Emergency Intervention - Khaled Samir','DS department chair notified',FALSE,4),
    ('DS2023021','Critical Emergency Intervention - Khaled Samir','Attendance contract mandatory this week',FALSE,5),
    ('CS2023006','Sliding Performance Support - Farah Mahmoud','Initial advisor meeting scheduled',FALSE,1),
    ('CS2023006','Sliding Performance Support - Farah Mahmoud','CS201 tutoring resources shared',FALSE,2),
    ('CS2023006','Sliding Performance Support - Farah Mahmoud','Attendance monitoring set up',FALSE,3)
) AS a(snum, plan_title, descr, done, ord)
JOIN students s ON s.student_number = a.snum
JOIN intervention_plans ip ON ip.student_id = s.id AND ip.title = a.plan_title;

-- ============================================================
-- QUIZZES + QUESTIONS + SUBMISSIONS
-- ============================================================
INSERT INTO quizzes (title, description, course_id, created_by, duration_minutes, attempts_limit, start_time, end_time, shuffle_questions, status, total_points)
SELECT q.title, q.descr, c.id, u.id, q.dur, q.attempts,
       NOW() + q.start_off::INTERVAL, NOW() + q.end_off::INTERVAL,
       q.shuffle, q.status::quiz_status, q.points
FROM (VALUES
    ('Advanced Algorithms Quiz 3','Graph algorithms and dynamic programming',    'CS301','j.anderson@eduguard.edu',60,2,'-2 days','3 days', TRUE,'published',50),
    ('Data Structures Midterm',   'Comprehensive midterm assessment',            'CS201','j.anderson@eduguard.edu',90,1,'-5 days','1 day',  FALSE,'published',100),
    ('AI401 ML Fundamentals Quiz','Supervised learning algorithms',              'AI401','e.chen@eduguard.edu',    45,1,'2 days', '7 days', TRUE,'draft',    30),
    ('Database Systems Assessment','SQL queries and data modeling',              'IS201','r.davis@eduguard.edu',   60,1,'-10 days','-3 days',FALSE,'closed', 40),
    ('Network Security Quiz 1',   'Firewalls and VPN fundamentals',              'NET401','l.thompson@eduguard.edu',45,2,'-1 day','4 days', TRUE,'published',35),
    ('Ethical Hacking Lab Quiz',  'Penetration testing fundamentals',            'SEC301','a.martinez@eduguard.edu',50,1,'-3 days','2 days',FALSE,'published',40)
) AS q(title, descr, course_code, prof_email, dur, attempts, start_off, end_off, shuffle, status, points)
JOIN courses c ON c.code = q.course_code
JOIN users u ON u.email = q.prof_email;

INSERT INTO questions (quiz_id, type, text, options_json, correct_answer, points, order_index)
SELECT q.id,'multiple_choice','What is the time complexity of Dijkstra algorithm with a binary heap?',
    '["O(V2)","O((V+E) log V)","O(V log V)","O(E log V)"]','O((V+E) log V)',5,1
FROM quizzes q WHERE q.title = 'Advanced Algorithms Quiz 3';

INSERT INTO questions (quiz_id, type, text, options_json, correct_answer, points, order_index)
SELECT q.id,'true_false','Dynamic programming always requires memorization of all subproblems.',
    '["True","False"]','False',3,2
FROM quizzes q WHERE q.title = 'Advanced Algorithms Quiz 3';

INSERT INTO questions (quiz_id, type, text, options_json, correct_answer, points, order_index)
SELECT q.id,'multiple_choice','Worst-case time complexity of quicksort?',
    '["O(n log n)","O(n2)","O(n)","O(log n)"]','O(n2)',5,1
FROM quizzes q WHERE q.title = 'Data Structures Midterm';

INSERT INTO questions (quiz_id, type, text, options_json, correct_answer, points, order_index)
SELECT q.id,'multiple_choice','Which SQL clause filters grouped results?',
    '["WHERE","GROUP BY","HAVING","ORDER BY"]','HAVING',5,1
FROM quizzes q WHERE q.title = 'Database Systems Assessment';

INSERT INTO quiz_submissions (quiz_id, student_id, answers_json, score, max_score, percentage, passed, attempt_number, time_taken_minutes)
SELECT qz.id, s.id, qs.answers::JSONB, qs.score, qs.max_s, qs.pct, qs.passed, 1, qs.mins
FROM (VALUES
    ('Advanced Algorithms Quiz 3','CS2021001','{"q1":"O((V+E) log V)","q2":"False"}',48.0,50.0,96.0,TRUE,55),
    ('Advanced Algorithms Quiz 3','CS2021002','{"q1":"O((V+E) log V)","q2":"False"}',46.0,50.0,92.0,TRUE,58),
    ('Advanced Algorithms Quiz 3','CS2022003','{"q1":"O((V+E) log V)","q2":"True"}', 40.0,50.0,80.0,TRUE,54),
    ('Advanced Algorithms Quiz 3','CS2022004','{"q1":"O(V2)","q2":"False"}',         38.0,50.0,76.0,TRUE,60),
    ('Advanced Algorithms Quiz 3','AI2022009','{"q1":"O((V+E) log V)","q2":"False"}',47.0,50.0,94.0,TRUE,50),
    ('Advanced Algorithms Quiz 3','SE2021016','{"q1":"O(n2)","q2":"True"}',          18.0,50.0,36.0,FALSE,62),
    ('Data Structures Midterm','CS2021001','{"q1":"O(n2)"}',92.0,100.0,92.0,TRUE,85),
    ('Data Structures Midterm','CS2021002','{"q1":"O(n2)"}',90.0,100.0,90.0,TRUE,88),
    ('Data Structures Midterm','CS2022003','{"q1":"O(n log n)"}',78.0,100.0,78.0,TRUE,87),
    ('Data Structures Midterm','CS2023005','{"q1":"O(n)"}',62.0,100.0,62.0,TRUE,89),
    ('Data Structures Midterm','CS2023006','{"q1":"O(n)"}',58.0,100.0,58.0,FALSE,91),
    ('Database Systems Assessment','IS2022012','{"q1":"HAVING"}',38.0,40.0,95.0,TRUE,55),
    ('Database Systems Assessment','CS2021001','{"q1":"HAVING"}',37.0,40.0,92.5,TRUE,57),
    ('Network Security Quiz 1','NET2022014','{"q1":"stateful inspection"}',32.0,35.0,91.4,TRUE,42),
    ('Network Security Quiz 1','SEC2022018','{"q1":"stateful inspection"}',33.0,35.0,94.3,TRUE,40),
    ('Ethical Hacking Lab Quiz','SEC2022018','{"q1":"nmap","q2":"Metasploit"}',38.0,40.0,95.0,TRUE,47),
    ('Ethical Hacking Lab Quiz','SEC2023019','{"q1":"nmap","q2":"Wireshark"}',30.0,40.0,75.0,TRUE,50),
    ('Ethical Hacking Lab Quiz','NET2022014','{"q1":"Wireshark","q2":"Metasploit"}',28.0,40.0,70.0,TRUE,52)
) AS qs(quiz_title, snum, answers, score, max_s, pct, passed, mins)
JOIN quizzes qz ON qz.title = qs.quiz_title
JOIN students s ON s.student_number = qs.snum;

-- ============================================================
-- ACADEMIC TERMS
-- ============================================================
INSERT INTO academic_terms (code, name, term_type, academic_year, start_date, end_date, is_active)
VALUES
    ('FALL-2021',   'Fall Semester 2021',   'fall',  2021,'2021-09-01','2022-01-15',FALSE),
    ('SPRING-2022', 'Spring Semester 2022', 'spring',2022,'2022-02-01','2022-06-15',FALSE),
    ('FALL-2022',   'Fall Semester 2022',   'fall',  2022,'2022-09-01','2023-01-15',FALSE),
    ('SPRING-2023', 'Spring Semester 2023', 'spring',2023,'2023-02-01','2023-06-15',FALSE),
    ('FALL-2023',   'Fall Semester 2023',   'fall',  2023,'2023-09-01','2024-01-15',FALSE),
    ('SPRING-2024', 'Spring Semester 2024', 'spring',2024,'2024-02-01','2024-06-15',FALSE),
    ('FALL-2024',   'Fall Semester 2024',   'fall',  2024,'2024-09-01','2025-01-15',FALSE),
    ('SPRING-2025', 'Spring Semester 2025', 'spring',2025,'2025-02-01','2025-06-15',FALSE),
    ('FALL-2025',   'Fall Semester 2025',   'fall',  2025,'2025-09-01','2026-01-15',TRUE)
ON CONFLICT (code) DO NOTHING;

-- ============================================================
-- SEMESTER SNAPSHOTS
-- ============================================================
INSERT INTO semester_snapshots (
    student_id, term_id, version, term_gpa, cgpa_after_term,
    credits_attempted, credits_earned, credits_failed,
    cumulative_attempted, cumulative_earned,
    academic_standing, honors_level, dean_list_eligible, risk_flags
)
SELECT s.id, t.id, ss.ver, ss.tgpa, ss.cgpa, ss.ca, ss.ce, ss.cf,
       ss.cuma, ss.cume, ss.standing::academic_status,
       ss.hon::honors_level_snap, ss.dl, ss.rf::JSONB
FROM (VALUES
    ('CS2021001','FALL-2021',  1,3.80,3.80,18,18,0, 18, 18,'active','excellent',TRUE,'[]'),
    ('CS2021001','SPRING-2022',1,3.90,3.85,18,18,0, 36, 36,'active','excellent',TRUE,'[]'),
    ('CS2021001','FALL-2022',  1,3.88,3.86,18,18,0, 54, 54,'active','excellent',TRUE,'[]'),
    ('CS2021001','SPRING-2023',1,3.92,3.87,18,18,0, 72, 72,'active','excellent',TRUE,'[]'),
    ('CS2021001','FALL-2023',  1,3.85,3.87,18,18,0, 90, 90,'active','excellent',TRUE,'[]'),
    ('CS2021001','SPRING-2024',1,3.90,3.88,15,15,0,105,105,'active','excellent',TRUE,'[]'),
    ('CS2021002','FALL-2021',  1,3.70,3.70,18,18,0, 18, 18,'active','very_good',TRUE,'[]'),
    ('CS2021002','SPRING-2022',1,3.75,3.72,18,18,0, 36, 36,'active','very_good',TRUE,'[]'),
    ('CS2021002','FALL-2022',  1,3.70,3.71,18,18,0, 54, 54,'active','very_good',TRUE,'[]'),
    ('CS2021002','SPRING-2023',1,3.75,3.72,18,18,0, 72, 72,'active','very_good',TRUE,'[]'),
    ('CS2021002','FALL-2023',  1,3.72,3.72,18,18,0, 90, 90,'active','very_good',TRUE,'[]'),
    ('CS2021002','SPRING-2024',1,3.70,3.72,15,15,0,105,105,'active','very_good',TRUE,'[]'),
    ('DS2021020','FALL-2021',  1,3.85,3.85,18,18,0, 18, 18,'active','excellent',TRUE,'[]'),
    ('DS2021020','SPRING-2022',1,3.80,3.82,18,18,0, 36, 36,'active','excellent',TRUE,'[]'),
    ('DS2021020','FALL-2022',  1,3.85,3.83,18,18,0, 54, 54,'active','excellent',TRUE,'[]'),
    ('DS2021020','SPRING-2023',1,3.82,3.83,18,18,0, 72, 72,'active','excellent',TRUE,'[]'),
    ('DS2021020','FALL-2023',  1,3.80,3.82,18,18,0, 90, 90,'active','excellent',TRUE,'[]'),
    ('DS2021020','SPRING-2024',1,3.85,3.82,15,15,0,105,105,'active','excellent',TRUE,'[]'),
    ('SE2021016','FALL-2021',  1,2.80,2.80,18,18,0, 18, 18,'active',  'good', FALSE,'[]'),
    ('SE2021016','SPRING-2022',1,2.40,2.60,18,15,3, 36, 33,'warning', 'good', FALSE,'["low_gpa"]'),
    ('SE2021016','FALL-2022',  1,1.90,2.30,18,12,6, 54, 45,'warning', 'none', FALSE,'["low_gpa","failed_courses"]'),
    ('SE2021016','SPRING-2023',1,1.60,2.05,18, 9,9, 72, 54,'probation','none',FALSE,'["low_gpa","failed_courses","attendance"]'),
    ('SE2021016','FALL-2023',  1,1.50,1.90,18, 9,9, 90, 63,'probation','none',FALSE,'["low_gpa","failed_courses","attendance","probation"]'),
    ('SE2021016','SPRING-2024',1,1.70,1.82,15, 9,6,105, 72,'probation','none',FALSE,'["low_gpa","attendance","probation"]'),
    ('AI2022009','FALL-2022',  1,3.80,3.80,18,18,0, 18, 18,'active','excellent',TRUE,'[]'),
    ('AI2022009','SPRING-2023',1,3.75,3.77,18,18,0, 36, 36,'active','excellent',TRUE,'[]'),
    ('AI2022009','FALL-2023',  1,3.78,3.78,18,18,0, 54, 54,'active','excellent',TRUE,'[]'),
    ('CS2022003','FALL-2022',  1,3.60,3.60,18,18,0, 18, 18,'active','very_good',TRUE,'[]'),
    ('CS2022003','SPRING-2023',1,3.50,3.55,18,18,0, 36, 36,'active','very_good',FALSE,'[]'),
    ('CS2022003','FALL-2023',  1,3.55,3.55,18,18,0, 54, 54,'active','very_good',FALSE,'[]'),
    ('SEC2022018','FALL-2022', 1,3.70,3.70,18,18,0, 18, 18,'active','very_good',TRUE,'[]'),
    ('SEC2022018','SPRING-2023',1,3.65,3.67,18,18,0,36, 36,'active','very_good',TRUE,'[]'),
    ('SEC2022018','FALL-2023', 1,3.62,3.66,18,18,0, 54, 54,'active','very_good',TRUE,'[]'),
    ('IS2022012','FALL-2022',  1,3.65,3.65,18,18,0, 18, 18,'active','very_good',TRUE,'[]'),
    ('IS2022012','SPRING-2023',1,3.62,3.63,18,18,0, 36, 36,'active','very_good',TRUE,'[]'),
    ('IS2022012','FALL-2023',  1,3.60,3.62,18,18,0, 54, 54,'active','very_good',FALSE,'[]'),
    ('NET2022014','FALL-2022', 1,3.55,3.55,18,18,0, 18, 18,'active','very_good',FALSE,'[]'),
    ('NET2022014','SPRING-2023',1,3.50,3.52,18,18,0,36, 36,'active','good',     FALSE,'[]'),
    ('NET2022014','FALL-2023', 1,3.48,3.51,18,18,0, 54, 54,'active','good',     FALSE,'[]'),
    ('CS2022004','FALL-2022',  1,3.50,3.50,18,18,0, 18, 18,'active','very_good',FALSE,'[]'),
    ('CS2022004','SPRING-2023',1,3.40,3.45,18,18,0, 36, 36,'active','good',     FALSE,'[]'),
    ('CS2022004','FALL-2023',  1,3.38,3.42,18,18,0, 54, 54,'active','good',     FALSE,'[]'),
    ('DS2023021','FALL-2023',  1,2.00,2.00,18,12,6, 18, 12,'warning','none',    FALSE,'["low_grades"]'),
    ('DS2023021','SPRING-2024',1,1.40,1.70,18, 6,12,36, 18,'probation','none',  FALSE,'["low_gpa","failed_courses","attendance"]'),
    ('CS2024008','FALL-2024',  1,1.80,1.80,12, 6,6, 12,  6,'warning','none',    FALSE,'["low_gpa","failed_cs101"]'),
    ('AI2023011','FALL-2023',  1,2.40,2.40,18,15,3, 18, 15,'active','none',     FALSE,'["borderline_grades"]'),
    ('AI2023011','SPRING-2024',1,2.00,2.20,18,12,6, 36, 27,'warning','none',    FALSE,'["low_gpa","attendance"]'),
    ('NET2023015','FALL-2023', 1,2.60,2.60,18,15,3, 18, 15,'active','none',     FALSE,'["borderline_grades"]'),
    ('NET2023015','SPRING-2024',1,2.00,2.30,18,12,6,36, 27,'warning','none',    FALSE,'["low_gpa","attendance"]'),
    ('CS2023005','FALL-2023',  1,2.90,2.90,18,18,0, 18, 18,'active','good',     FALSE,'[]'),
    ('CS2023005','SPRING-2024',1,2.80,2.85,18,18,0, 36, 36,'active','good',     FALSE,'[]')
) AS ss(snum, term_code, ver, tgpa, cgpa, ca, ce, cf, cuma, cume, standing, hon, dl, rf)
JOIN students s ON s.student_number = ss.snum
JOIN academic_terms t ON t.code = ss.term_code;

-- ============================================================
-- ACADEMIC STATUS HISTORY
-- ============================================================
INSERT INTO academic_status_history (student_id, term_id, old_status, new_status, cgpa_at_change, term_gpa_at_change, reason, actor_id)
SELECT s.id, t.id, h.old_s::acad_status_old, h.new_s::acad_status_new, h.cgpa, h.tgpa, h.reason, u.id
FROM (VALUES
    ('CS2021001','FALL-2021',   NULL,       'active',    3.80,3.80,'Initial enrollment active status','admin@eduguard.edu'),
    ('DS2021020','FALL-2021',   NULL,       'active',    3.85,3.85,'Initial enrollment active status','admin@eduguard.edu'),
    ('SE2021016','SPRING-2022', 'active',   'warning',   2.60,2.40,'GPA dropped below threshold for two consecutive assessments','admin@eduguard.edu'),
    ('SE2021016','FALL-2022',   'warning',  'warning',   2.30,1.90,'Continued academic difficulty and attendance declining','admin@eduguard.edu'),
    ('SE2021016','SPRING-2023', 'warning',  'probation', 2.05,1.60,'GPA fell below 1.70; academic probation initiated per policy','admin@eduguard.edu'),
    ('SE2021016','FALL-2023',   'probation','probation', 1.90,1.50,'Probation continued; no improvement observed','admin@eduguard.edu'),
    ('DS2023021','FALL-2023',   'active',   'warning',   2.00,2.00,'First semester performance below expectations','admin@eduguard.edu'),
    ('DS2023021','SPRING-2024', 'warning',  'probation', 1.70,1.40,'Severe decline; failed 12 credits; probation applied','admin@eduguard.edu'),
    ('CS2024008','FALL-2024',   'active',   'warning',   1.80,1.80,'Below minimum GPA threshold after first semester','admin@eduguard.edu'),
    ('AI2023011','SPRING-2024', 'active',   'warning',   2.20,2.00,'GPA dropped below 2.50; academic warning issued','admin@eduguard.edu'),
    ('NET2023015','SPRING-2024','active',   'warning',   2.30,2.00,'Attendance issues and grade decline triggered warning','admin@eduguard.edu')
) AS h(snum, term_code, old_s, new_s, cgpa, tgpa, reason, actor_email)
JOIN students s ON s.student_number = h.snum
JOIN academic_terms t ON t.code = h.term_code
JOIN users u ON u.email = h.actor_email;

-- ============================================================
-- ACADEMIC TIMELINE EVENTS
-- ============================================================
INSERT INTO academic_timeline_events (student_id, term_id, event_type, title, description, payload, actor_id, occurred_at)
SELECT s.id, t.id, e.etype::timeline_event_type, e.title, e.descr, e.payload::JSONB, u.id, NOW() + e.off::INTERVAL
FROM (VALUES
    ('CS2021001','FALL-2021',   'enrollment',      'Initial Enrollment',            'Student enrolled in CS Fall 2021',             '{"credits":18}','admin@eduguard.edu','-4 years'),
    ('CS2021001','FALL-2022',   'grade_posted',    'CS201 Grade Posted',            'Grade A posted for Data Structures',           '{"grade":"A","course":"CS201"}','j.anderson@eduguard.edu','-2 years'),
    ('CS2021001','SPRING-2024', 'gpa_recalculated','CGPA Updated to 3.88',          'CGPA recalculated after spring grades',        '{"old_cgpa":3.87,"new_cgpa":3.88}','admin@eduguard.edu','-6 months'),
    ('CS2021001','SPRING-2024', 'honors_awarded',  'Deans List Spring 2024',        'Added to Deans List',                          '{"term_gpa":3.90,"cgpa":3.88}','admin@eduguard.edu','-6 months'),
    ('CS2021001','FALL-2025',   'transcript_issued','Official Transcript Generated', 'For graduate school application',              '{"type":"official"}','admin@eduguard.edu','-1 month'),
    ('DS2021020','FALL-2021',   'enrollment',      'Initial Enrollment',            'Student enrolled in DS Fall 2021',             '{"credits":18}','admin@eduguard.edu','-4 years'),
    ('DS2021020','SPRING-2024', 'honors_awarded',  'Deans List Spring 2024',        'Deans List for GPA 3.85',                      '{"term_gpa":3.85,"cgpa":3.82}','admin@eduguard.edu','-6 months'),
    ('DS2021020','FALL-2025',   'transcript_issued','Unofficial Transcript',         'For internship application',                   '{"type":"unofficial"}','admin@eduguard.edu','-1 month'),
    ('CS2021002','SPRING-2024', 'honors_awarded',  'Deans List Spring 2024',        'Deans List for GPA 3.70',                      '{"term_gpa":3.70,"cgpa":3.72}','admin@eduguard.edu','-6 months'),
    ('SE2021016','SPRING-2022', 'status_changed',  'Academic Warning Issued',       'Status changed to warning',                    '{"old":"active","new":"warning"}','admin@eduguard.edu','-3 years'),
    ('SE2021016','SPRING-2023', 'status_changed',  'Academic Probation',            'Student placed on probation',                  '{"old":"warning","new":"probation"}','admin@eduguard.edu','-2 years'),
    ('SE2021016','FALL-2025',   'advisor_note',    'Emergency Advisor Meeting',     'Probation review meeting',                     '{"type":"probation_review"}','r.green@eduguard.edu','-2 weeks'),
    ('DS2023021','FALL-2023',   'enrollment',      'Initial Enrollment',            'Student enrolled in DS Fall 2023',             '{"credits":18}','admin@eduguard.edu','-2 years'),
    ('DS2023021','SPRING-2024', 'status_changed',  'Probation Status Applied',      'GPA 1.40 triggers probation',                  '{"old":"warning","new":"probation"}','admin@eduguard.edu','-12 months'),
    ('DS2023021','FALL-2025',   'registrar_action','Intervention Plan Activated',   'Emergency intervention opened',                '{"plan":"Critical Emergency"}','admin@eduguard.edu','-1 week'),
    ('CS2024008','FALL-2024',   'enrollment',      'Initial Enrollment',            'Freshman enrolled in CS Fall 2024',            '{"credits":12}','admin@eduguard.edu','-1 year'),
    ('CS2024008','FALL-2024',   'status_changed',  'Academic Warning Fall 2024',    'Warning for GPA 1.80',                         '{"old":"active","new":"warning"}','admin@eduguard.edu','-8 months'),
    ('AI2022009','FALL-2022',   'enrollment',      'Initial Enrollment',            'Student enrolled in AI Fall 2022',             '{"credits":18}','admin@eduguard.edu','-3 years'),
    ('AI2022009','FALL-2023',   'honors_awarded',  'Deans List Fall 2023',          'Deans List for GPA 3.78',                      '{"term_gpa":3.78,"cgpa":3.78}','admin@eduguard.edu','-1 year'),
    ('SEC2022018','FALL-2023',  'honors_awarded',  'Deans List Fall 2023',          'Deans List for GPA 3.62',                      '{"term_gpa":3.62,"cgpa":3.66}','admin@eduguard.edu','-1 year')
) AS e(snum, term_code, etype, title, descr, payload, actor_email, off)
JOIN students s ON s.student_number = e.snum
JOIN academic_terms t ON t.code = e.term_code
JOIN users u ON u.email = e.actor_email;

-- ============================================================
-- DEGREE PROGRESS SNAPSHOTS
-- ============================================================
INSERT INTO degree_progress_snapshots (
    student_id, term_id, version,
    required_credits, earned_credits, remaining_credits, completion_percentage,
    category_breakdown, missing_core_courses, missing_elective_slots,
    all_core_complete, all_electives_complete, field_training_complete, graduation_project_complete
)
SELECT s.id, t.id, dp.ver, dp.req_cr, dp.earn_cr, dp.rem_cr, dp.pct,
       dp.cat_bkd::JSONB, dp.miss_core::JSONB, dp.miss_elec,
       dp.core_done, dp.elec_done, dp.ft_done, dp.gp_done
FROM (VALUES
    ('CS2021001','SPRING-2024',1,134,105,29,78.36,'{"core":85,"elective":12,"university_req":8}', '["SE493","SE494"]',1,FALSE,FALSE,TRUE,FALSE),
    ('CS2021002','SPRING-2024',1,134,105,29,78.36,'{"core":82,"elective":12,"university_req":11}','["SE493","SE494"]',1,FALSE,FALSE,TRUE,FALSE),
    ('DS2021020','SPRING-2024',1,134,105,29,78.36,'{"core":88,"elective":12,"university_req":5}', '["DS493","DS494"]',0,FALSE,FALSE,TRUE,FALSE),
    ('SE2021016','SPRING-2024',1,134, 72,62,53.73,'{"core":55,"elective":9,"university_req":8}',  '["SE301","SE302","SE401","SE493","SE494","SE395"]',3,FALSE,FALSE,FALSE,FALSE),
    ('AI2022009','FALL-2023', 1,134, 54,80,40.30,'{"core":45,"elective":6,"university_req":3}',  '["AI401","AI402","AI403"]',2,FALSE,FALSE,FALSE,FALSE),
    ('CS2022003','FALL-2023', 1,134, 54,80,40.30,'{"core":45,"elective":6,"university_req":3}',  '["CS401","CS402","AI401"]',2,FALSE,FALSE,FALSE,FALSE),
    ('SEC2022018','FALL-2023',1,134, 54,80,40.30,'{"core":45,"elective":6,"university_req":3}',  '["SEC401","SEC402","SEC403"]',2,FALSE,FALSE,FALSE,FALSE),
    ('IS2022012','FALL-2023', 1,134, 54,80,40.30,'{"core":45,"elective":6,"university_req":3}',  '["IS401","IS402","IS403"]',2,FALSE,FALSE,FALSE,FALSE),
    ('DS2023021','SPRING-2024',1,134,18,116,13.43,'{"core":12,"elective":0,"university_req":6}', '["DS201","DS202","DS301","DS302","DS401","DS402"]',3,FALSE,FALSE,FALSE,FALSE),
    ('CS2024008','FALL-2024', 1,134,  6,128, 4.48,'{"core":6,"elective":0,"university_req":0}',  '["CS101","CS201","CS301"]',3,FALSE,FALSE,FALSE,FALSE),
    ('CS2023005','SPRING-2024',1,134, 36,98,26.87,'{"core":30,"elective":3,"university_req":3}', '["CS301","CS401","AI201"]',3,FALSE,FALSE,FALSE,FALSE)
) AS dp(snum, term_code, ver, req_cr, earn_cr, rem_cr, pct, cat_bkd, miss_core, miss_elec, core_done, elec_done, ft_done, gp_done)
JOIN students s ON s.student_number = dp.snum
JOIN academic_terms t ON t.code = dp.term_code;

-- ============================================================
-- GRADUATION ELIGIBILITY RECORDS
-- ============================================================
INSERT INTO graduation_eligibility_records (
    student_id, term_id, eligibility_status, requirements_met, missing_requirements,
    cgpa_at_evaluation, credits_at_evaluation, evaluated_by, notes, is_current
)
SELECT s.id, t.id, ger.elig::grad_eligibility,
       ger.req_met::JSONB, ger.missing::JSONB,
       ger.cgpa, ger.credits, u.id, ger.notes, TRUE
FROM (VALUES
    ('CS2021001','SPRING-2024','conditionally_eligible',
     '{"cgpa_met":true,"credits_partial":true,"core_partial":true,"field_training":true}',
     '["Complete Graduation Project 1 and 2","1 elective slot remaining"]',
     3.88,105,'admin@eduguard.edu','On track for Spring 2026 graduation pending GP completion.'),
    ('CS2021002','SPRING-2024','conditionally_eligible',
     '{"cgpa_met":true,"credits_partial":true,"core_partial":true,"field_training":true}',
     '["Complete Graduation Project 1 and 2","1 elective slot remaining"]',
     3.72,105,'admin@eduguard.edu','Expected graduation Spring 2026 if GP courses completed.'),
    ('DS2021020','SPRING-2024','conditionally_eligible',
     '{"cgpa_met":true,"credits_partial":true,"core_partial":true,"field_training":true}',
     '["Complete DS493 and DS494 graduation project"]',
     3.82,105,'admin@eduguard.edu','Strong candidate for distinction-level graduation.'),
    ('SE2021016','SPRING-2024','not_eligible',
     '{"cgpa_met":false,"total_credits_met":false,"core_met":false}',
     '["GPA 1.75 below 2.00 minimum","62 credits remaining","6 core courses missing","GP not started"]',
     1.75,72,'admin@eduguard.edu','Student on academic probation. Minimum 3 additional semesters required.'),
    ('DS2023021','SPRING-2024','not_eligible',
     '{"cgpa_met":false,"total_credits_met":false,"core_met":false}',
     '["GPA 1.60 below 2.00 minimum","116 credits remaining","Critical academic standing"]',
     1.60,18,'admin@eduguard.edu','Student in critical academic standing. Immediate intervention required.')
) AS ger(snum, term_code, elig, req_met, missing, cgpa, credits, eval_email, notes)
JOIN students s ON s.student_number = ger.snum
JOIN academic_terms t ON t.code = ger.term_code
JOIN users u ON u.email = ger.eval_email;

-- ============================================================
-- HONORS RECORDS
-- ============================================================
INSERT INTO honors_records (
    student_id, term_id, honors_level, is_deans_list,
    term_gpa_used, cgpa_used, credits_used, qualification_data, awarded_by
)
SELECT s.id, t.id, h.hon::honors_level_rec, h.dl, h.tgpa, h.cgpa, h.credits, h.qual::JSONB, u.id
FROM (VALUES
    ('CS2021001','FALL-2021',  'excellent',TRUE,3.80,3.80,18,'{"status":"Deans_List","reason":"Term GPA above 3.50"}','admin@eduguard.edu'),
    ('CS2021001','SPRING-2022','excellent',TRUE,3.90,3.85,18,'{"status":"Deans_List","reason":"Term GPA above 3.50"}','admin@eduguard.edu'),
    ('CS2021001','FALL-2022',  'excellent',TRUE,3.88,3.86,18,'{"status":"Deans_List","reason":"Term GPA above 3.50"}','admin@eduguard.edu'),
    ('CS2021001','SPRING-2023','excellent',TRUE,3.92,3.87,18,'{"status":"Deans_List","reason":"Term GPA above 3.50"}','admin@eduguard.edu'),
    ('CS2021001','FALL-2023',  'excellent',TRUE,3.85,3.87,18,'{"status":"Deans_List","reason":"Term GPA above 3.50"}','admin@eduguard.edu'),
    ('CS2021001','SPRING-2024','excellent',TRUE,3.90,3.88,15,'{"status":"Deans_List","reason":"Term GPA above 3.50"}','admin@eduguard.edu'),
    ('CS2021002','FALL-2021',  'very_good',TRUE,3.70,3.70,18,'{"status":"Deans_List","reason":"Term GPA above 3.50"}','admin@eduguard.edu'),
    ('CS2021002','SPRING-2022','very_good',TRUE,3.75,3.72,18,'{"status":"Deans_List","reason":"Term GPA above 3.50"}','admin@eduguard.edu'),
    ('CS2021002','FALL-2022',  'very_good',TRUE,3.70,3.71,18,'{"status":"Deans_List","reason":"Term GPA above 3.50"}','admin@eduguard.edu'),
    ('CS2021002','SPRING-2023','very_good',TRUE,3.75,3.72,18,'{"status":"Deans_List","reason":"Term GPA above 3.50"}','admin@eduguard.edu'),
    ('CS2021002','FALL-2023',  'very_good',TRUE,3.72,3.72,18,'{"status":"Deans_List","reason":"Term GPA above 3.50"}','admin@eduguard.edu'),
    ('CS2021002','SPRING-2024','very_good',TRUE,3.70,3.72,15,'{"status":"Deans_List","reason":"Term GPA above 3.50"}','admin@eduguard.edu'),
    ('DS2021020','FALL-2021',  'excellent',TRUE,3.85,3.85,18,'{"status":"Deans_List","reason":"Term GPA above 3.50"}','admin@eduguard.edu'),
    ('DS2021020','SPRING-2022','excellent',TRUE,3.80,3.82,18,'{"status":"Deans_List","reason":"Term GPA above 3.50"}','admin@eduguard.edu'),
    ('DS2021020','FALL-2022',  'excellent',TRUE,3.85,3.83,18,'{"status":"Deans_List","reason":"Term GPA above 3.50"}','admin@eduguard.edu'),
    ('DS2021020','SPRING-2023','excellent',TRUE,3.82,3.83,18,'{"status":"Deans_List","reason":"Term GPA above 3.50"}','admin@eduguard.edu'),
    ('DS2021020','FALL-2023',  'excellent',TRUE,3.80,3.82,18,'{"status":"Deans_List","reason":"Term GPA above 3.50"}','admin@eduguard.edu'),
    ('DS2021020','SPRING-2024','excellent',TRUE,3.85,3.82,15,'{"status":"Deans_List","reason":"Term GPA above 3.50"}','admin@eduguard.edu'),
    ('AI2022009','FALL-2022',  'excellent',TRUE,3.80,3.80,18,'{"status":"Deans_List","reason":"Term GPA above 3.50"}','admin@eduguard.edu'),
    ('AI2022009','SPRING-2023','excellent',TRUE,3.75,3.77,18,'{"status":"Deans_List","reason":"Term GPA above 3.50"}','admin@eduguard.edu'),
    ('AI2022009','FALL-2023',  'excellent',TRUE,3.78,3.78,18,'{"status":"Deans_List","reason":"Term GPA above 3.50"}','admin@eduguard.edu'),
    ('SEC2022018','FALL-2022', 'very_good',TRUE,3.70,3.70,18,'{"status":"Deans_List","reason":"Term GPA above 3.50"}','admin@eduguard.edu'),
    ('SEC2022018','SPRING-2023','very_good',TRUE,3.65,3.67,18,'{"status":"Deans_List","reason":"Term GPA above 3.50"}','admin@eduguard.edu'),
    ('SEC2022018','FALL-2023', 'very_good',TRUE,3.62,3.66,18,'{"status":"Deans_List","reason":"Term GPA above 3.50"}','admin@eduguard.edu'),
    ('IS2022012','FALL-2022',  'very_good',TRUE,3.65,3.65,18,'{"status":"Deans_List","reason":"Term GPA above 3.50"}','admin@eduguard.edu'),
    ('IS2022012','SPRING-2023','very_good',TRUE,3.62,3.63,18,'{"status":"Deans_List","reason":"Term GPA above 3.50"}','admin@eduguard.edu'),
    ('CS2022003','FALL-2022',  'very_good',TRUE,3.60,3.60,18,'{"status":"Deans_List","reason":"Term GPA above 3.50"}','admin@eduguard.edu'),
    ('CS2022003','SPRING-2023','very_good',TRUE,3.50,3.55,18,'{"status":"Deans_List","reason":"Term GPA above 3.50"}','admin@eduguard.edu'),
    ('NET2022014','FALL-2022', 'very_good',TRUE,3.55,3.55,18,'{"status":"Deans_List","reason":"Term GPA above 3.50"}','admin@eduguard.edu')
) AS h(snum, term_code, hon, dl, tgpa, cgpa, credits, qual, award_email)
JOIN students s ON s.student_number = h.snum
JOIN academic_terms t ON t.code = h.term_code
JOIN users u ON u.email = h.award_email;

-- ============================================================
-- GPA PROJECTIONS
-- ============================================================
INSERT INTO gpa_projections (
    student_id, term_id, projection_type, current_cgpa, current_credits,
    target_cgpa, remaining_credits, scenario_input, projection_result,
    projected_semester_gpa, projected_cgpa, is_achievable
)
SELECT s.id, t.id, gp.ptype, gp.cur_cgpa, gp.cur_cr, gp.tgt_cgpa, gp.rem_cr,
       gp.scenario::JSONB, gp.result::JSONB, gp.proj_sgpa, gp.proj_cgpa, gp.achievable
FROM (VALUES
    ('CS2021001','FALL-2025','graduation_projection',3.88,105,3.90,29,
     '{"scenario":"maintain_current","avg_grade_needed":92}',
     '{"projected_final_cgpa":3.89,"honors_eligible":true,"graduation_term":"SPRING-2026"}',3.90,3.89,TRUE),
    ('CS2021002','FALL-2025','graduation_projection',3.72,105,3.75,29,
     '{"scenario":"maintain_current","avg_grade_needed":88}',
     '{"projected_final_cgpa":3.73,"honors_eligible":true,"graduation_term":"SPRING-2026"}',3.75,3.73,TRUE),
    ('DS2021020','FALL-2025','graduation_projection',3.82,105,3.85,29,
     '{"scenario":"maintain_current","avg_grade_needed":91}',
     '{"projected_final_cgpa":3.83,"honors_eligible":true,"graduation_term":"SPRING-2026"}',3.85,3.83,TRUE),
    ('SE2021016','FALL-2025','graduation_projection',1.75,72,2.00,62,
     '{"scenario":"minimum_pass","avg_grade_needed":73}',
     '{"projected_final_cgpa":1.98,"note":"Requires 73 average in remaining 62 credits","graduation_term":"SPRING-2028"}',2.50,1.98,FALSE),
    ('DS2023021','FALL-2025','recovery_projection',1.60,18,2.00,116,
     '{"scenario":"strong_recovery","avg_grade_needed":78}',
     '{"projected_final_cgpa":2.01,"note":"Achievable with consistent 78 average over 5 semesters"}',2.80,2.01,TRUE),
    ('CS2024008','FALL-2025','recovery_projection',1.90,6,2.00,128,
     '{"scenario":"strong_recovery","avg_grade_needed":75}',
     '{"projected_final_cgpa":2.00,"note":"Recovery possible with tutoring and full attendance"}',2.60,2.00,TRUE)
) AS gp(snum, term_code, ptype, cur_cgpa, cur_cr, tgt_cgpa, rem_cr, scenario, result, proj_sgpa, proj_cgpa, achievable)
JOIN students s ON s.student_number = gp.snum
JOIN academic_terms t ON t.code = gp.term_code;

-- ============================================================
-- ACADEMIC RISK RECORDS
-- ============================================================
INSERT INTO academic_risk_records (
    student_id, term_id, risk_level, risk_score,
    gpa_trend, cgpa_trend, failed_courses_count, repeated_courses_count, withdrawal_count,
    degree_completion_pct, risk_factors, recommendations, is_current
)
SELECT s.id, t.id, ar.rl::risk_level_s4, ar.score, ar.gpa_t, ar.cgpa_t,
       ar.failed, ar.repeated, ar.withdrawn, ar.comp_pct,
       ar.factors::JSONB, ar.recs::JSONB, TRUE
FROM (VALUES
    ('CS2021001','FALL-2025','low',   0.08, 0.010, 0.005,0,0,0,78.36,'[]','["Continue current performance","Graduate school prep"]'),
    ('CS2021002','FALL-2025','low',   0.10, 0.005, 0.002,0,0,0,78.36,'[]','["Maintain GPA","Explore leadership roles"]'),
    ('DS2021020','FALL-2025','low',   0.07, 0.010, 0.005,0,0,0,78.36,'[]','["Graduation on track","Publish research"]'),
    ('AI2022009','FALL-2025','low',   0.09, 0.008, 0.004,0,0,0,40.30,'[]','["Maintain Deans List","AI research project"]'),
    ('CS2022003','FALL-2025','low',   0.22, 0.000,-0.002,0,0,0,40.30,'["minor_attendance"]','["Address attendance gaps"]'),
    ('SEC2022018','FALL-2025','low',  0.11, 0.005, 0.002,0,0,0,40.30,'[]','["Security certifications recommended"]'),
    ('IS2022012','FALL-2025','low',   0.12, 0.003,-0.001,0,0,0,40.30,'[]','["Explore BI specialization"]'),
    ('NET2022014','FALL-2025','low',  0.18,-0.002,-0.001,0,0,1,40.30,'["one_withdrawal"]','["Monitor NET401 grades"]'),
    ('CS2022004','FALL-2025','low',   0.25,-0.005,-0.003,0,0,0,40.30,'["slight_decline"]','["Improve study consistency"]'),
    ('CS2024007','FALL-2025','low',   0.20, 0.005, 0.005,0,0,0, 4.48,'[]','["Promising freshman","Maintain attendance"]'),
    ('CS2023005','FALL-2025','medium',0.30,-0.010,-0.008,0,0,0,26.87,'["borderline_gpa","attendance_gaps"]','["Tutoring for CS201"]'),
    ('IS2023013','FALL-2025','medium',0.28,-0.005,-0.003,0,0,0,26.87,'["attendance_gaps"]','["IS201 office hours"]'),
    ('SE2023017','FALL-2025','medium',0.22, 0.005, 0.002,0,0,0,26.87,'["borderline_gpa"]','["Complete SE101 projects"]'),
    ('SEC2023019','FALL-2025','medium',0.27,-0.005,-0.003,0,0,0,26.87,'["attendance_gaps"]','["SEC201 attendance improvement"]'),
    ('CS2023006','FALL-2025','medium',0.35,-0.020,-0.015,0,0,0,26.87,'["declining_grades","attendance_gaps"]','["Immediate advisor meeting","CS201 tutoring"]'),
    ('AI2023010','FALL-2025','medium',0.32,-0.015,-0.010,0,0,0,26.87,'["borderline_grades","attendance_drops"]','["AI401 and AI301 tutoring"]'),
    ('AI2023011','FALL-2025','high',  0.68,-0.040,-0.030,3,0,0,26.87,'["low_gpa","failing_courses","poor_attendance"]','["Immediate intervention","Tutoring for AI courses"]'),
    ('NET2023015','FALL-2025','high', 0.65,-0.060,-0.040,3,0,0,26.87,'["low_gpa","failing_cs101","poor_attendance"]','["CS101 supplemental classes","NET attendance monitoring"]'),
    ('CS2024008','FALL-2025','high',  0.72,-0.020,-0.020,6,0,0, 4.48,'["low_gpa_freshman","failing_both_courses","very_poor_attendance"]','["Emergency support plan active","Peer tutoring for CS101"]'),
    ('SE2021016','FALL-2025','critical',0.90,-0.100,-0.080,18,6,0,53.73,'["probation","very_low_gpa","multiple_failed_courses","chronic_absenteeism"]','["Dean meeting required","Counseling mandatory"]'),
    ('DS2023021','FALL-2025','critical',0.93,-0.120,-0.100,18,0,0,13.43,'["critical_gpa","failing_all_courses","almost_zero_attendance","probation","dropout_risk"]','["Emergency intervention active","Consider academic leave"]')
) AS ar(snum, term_code, rl, score, gpa_t, cgpa_t, failed, repeated, withdrawn, comp_pct, factors, recs)
JOIN students s ON s.student_number = ar.snum
JOIN academic_terms t ON t.code = ar.term_code;

-- ============================================================
-- REGISTRAR NOTES
-- ============================================================
INSERT INTO registrar_notes (student_id, term_id, note_type, title, content, tags, is_private, created_by, updated_by)
SELECT s.id, t.id, rn.ntype::note_type, rn.title, rn.content, rn.tags::JSONB, rn.priv, u.id, u.id
FROM (VALUES
    ('CS2021001','FALL-2025','registrar','Graduation Application Filed',
     'Ahmed Hassan filed graduation application for Spring 2026. All core requirements met except GP1 and GP2. CGPA 3.88 qualifies for honors.',
     '["graduation","honors","spring-2026"]',FALSE,'admin@eduguard.edu'),
    ('CS2021002','FALL-2025','registrar','Graduation Application Mariam Hassan',
     'Graduation application filed for Spring 2026. CGPA 3.72 meets honors threshold.',
     '["graduation","honors"]',FALSE,'admin@eduguard.edu'),
    ('DS2021020','FALL-2025','registrar','Distinction Track Rania Mostafa',
     'CGPA 3.82 places student on distinction track. Graduation expected Spring 2026 pending DS493 and DS494 completion.',
     '["graduation","distinction"]',FALSE,'admin@eduguard.edu'),
    ('SE2021016','FALL-2025','academic','Academic Probation Semester 8',
     'Amr Nabil remains on academic probation entering 8th semester. Cumulative failed credits 18. GPA 1.75. Emergency dean review scheduled.',
     '["probation","academic-risk","dean-review"]',TRUE,'admin@eduguard.edu'),
    ('SE2021016','FALL-2025','flag','URGENT Attendance Below 40 Percent',
     'Attendance tracking for Fall 2025 shows 35 percent rate. FL grades possible for SE301 and SE101 if not corrected by Week 8.',
     '["fl-risk","attendance","urgent"]',TRUE,'admin@eduguard.edu'),
    ('DS2023021','FALL-2025','academic','Critical Academic Standing Khaled Samir',
     'GPA 1.60, attendance 28 percent, failing all three enrolled courses. Emergency intervention plan activated. Counseling services notified.',
     '["critical","intervention","counseling"]',TRUE,'admin@eduguard.edu'),
    ('DS2023021','FALL-2025','flag','Dropout Risk Flagged',
     'AI risk engine flagged Khaled Samir DS2023021 at 93 percent dropout probability. Multi-department response initiated.',
     '["dropout-risk","critical","ai-flagged"]',TRUE,'admin@eduguard.edu'),
    ('CS2024008','FALL-2025','advisor','Freshman Support Plan Active',
     'Hana Tarek enrolled in emergency freshman support program. Tutoring 3 times per week. Attendance contract signed.',
     '["freshman","support","attendance"]',FALSE,'admin@eduguard.edu'),
    ('CS2021001','SPRING-2024','registrar','Official Transcript Requested',
     'Student requested official transcript for graduate school application to AUC and GUC. Transcript issued with verification code.',
     '["transcript","official","graduate-application"]',FALSE,'admin@eduguard.edu'),
    ('SEC2022018','FALL-2025','academic','CEH Certification Pathway',
     'Layla Ahmed pursuing CEH certification alongside coursework. Department approved study leave for certification exam.',
     '["certification","cybersecurity","approved"]',FALSE,'admin@eduguard.edu')
) AS rn(snum, term_code, ntype, title, content, tags, priv, creator_email)
JOIN students s ON s.student_number = rn.snum
JOIN academic_terms t ON t.code = rn.term_code
JOIN users u ON u.email = rn.creator_email;

-- ============================================================
-- ACADEMIC AUDIT ENTRIES
-- ============================================================
INSERT INTO academic_audit_entries (
    student_id, term_id, action, entity_type, old_value, new_value,
    reason, actor_id, actor_role, occurred_at
)
SELECT s.id, t.id, ae.action::audit_action, ae.etype,
       ae.old_v::JSONB, ae.new_v::JSONB, ae.reason, u.id, ae.actor_role, NOW() + ae.off::INTERVAL
FROM (VALUES
    ('CS2021001','FALL-2021',  'snapshot_created','semester_snapshot',
     '{}','{"term_gpa":3.80,"cgpa":3.80}','End-of-term snapshot created','admin@eduguard.edu','registrar','-4 years'),
    ('CS2021001','SPRING-2024','gpa_recalculated','student',
     '{"cgpa":3.87}','{"cgpa":3.88}','Spring 2024 grades finalized','admin@eduguard.edu','registrar','-6 months'),
    ('CS2021001','FALL-2025',  'transcript_generated','transcript',
     '{}','{"type":"official","version":1}','Graduate school application','admin@eduguard.edu','registrar','-1 month'),
    ('CS2021001','SPRING-2024','progress_updated','degree_progress',
     '{"completion_pct":71.64}','{"completion_pct":78.36}','Progress updated after Spring 2024','admin@eduguard.edu','registrar','-6 months'),
    ('CS2021002','SPRING-2024','snapshot_created','semester_snapshot',
     '{}','{"term_gpa":3.70,"cgpa":3.72}','Spring 2024 semester finalized','admin@eduguard.edu','registrar','-6 months'),
    ('DS2021020','FALL-2025',  'transcript_generated','transcript',
     '{}','{"type":"unofficial","version":1}','Internship application','admin@eduguard.edu','registrar','-1 month'),
    ('DS2021020','SPRING-2024','progress_updated','degree_progress',
     '{"completion_pct":71.64}','{"completion_pct":78.36}','Progress updated after Spring 2024','admin@eduguard.edu','registrar','-6 months'),
    ('SE2021016','SPRING-2022','status_changed','student',
     '{"status":"active"}','{"status":"warning"}','GPA 2.40 triggered academic warning','admin@eduguard.edu','registrar','-3 years'),
    ('SE2021016','SPRING-2023','status_changed','student',
     '{"status":"warning"}','{"status":"probation"}','GPA below 1.70; probation applied','admin@eduguard.edu','registrar','-2 years'),
    ('SE2021016','FALL-2025',  'grade_changed','enrollment',
     '{"grade":null}','{"grade":42,"course":"CS301"}','Mid-semester grade posted','j.anderson@eduguard.edu','professor','-2 weeks'),
    ('DS2023021','SPRING-2024','status_changed','student',
     '{"status":"warning"}','{"status":"probation"}','GPA 1.40 triggers probation','admin@eduguard.edu','registrar','-12 months'),
    ('DS2023021','FALL-2025',  'note_added','registrar_note',
     '{}','{"note_type":"flag","title":"Dropout Risk Flagged"}','AI engine flagged 93 percent dropout probability','admin@eduguard.edu','registrar','-1 week'),
    ('CS2024008','FALL-2024',  'status_changed','student',
     '{"status":"active"}','{"status":"warning"}','First semester GPA 1.80 below threshold','admin@eduguard.edu','registrar','-8 months'),
    ('AI2022009','FALL-2023',  'snapshot_created','semester_snapshot',
     '{}','{"term_gpa":3.78,"cgpa":3.78,"dean_list":true}','Fall 2023 finalized. Deans List added.','admin@eduguard.edu','registrar','-1 year'),
    ('SEC2022018','FALL-2023', 'snapshot_created','semester_snapshot',
     '{}','{"term_gpa":3.62,"cgpa":3.66,"dean_list":true}','Fall 2023 finalized. Deans List added.','admin@eduguard.edu','registrar','-1 year'),
    ('AI2023011','FALL-2025',  'grade_changed','enrollment',
     '{"grade":null}','{"grade":55,"course":"AI401"}','Mid-semester assessment posted','e.chen@eduguard.edu','professor','-5 days')
) AS ae(snum, term_code, action, etype, old_v, new_v, reason, actor_email, actor_role, off)
JOIN students s ON s.student_number = ae.snum
JOIN academic_terms t ON t.code = ae.term_code
JOIN users u ON u.email = ae.actor_email;

-- ============================================================
-- TRANSCRIPT VERSIONS
-- ============================================================
INSERT INTO transcript_versions (
    student_id, version_number, transcript_type, transcript_data,
    snapshot_hash, generated_by, reason, is_current
)
SELECT s.id, tv.ver, tv.ttype::transcript_type, tv.tdata::JSONB,
       tv.shash, u.id, tv.reason, TRUE
FROM (VALUES
    ('CS2021001',1,'official',
     '{"student":"Ahmed Hassan","student_number":"CS2021001","cgpa":3.88,"credits_earned":105,"department":"Computer Science","dean_list_terms":6}',
     'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2',
     'admin@eduguard.edu','Graduate school application AUC and GUC'),
    ('DS2021020',1,'unofficial',
     '{"student":"Rania Mostafa","student_number":"DS2021020","cgpa":3.82,"credits_earned":105,"department":"Data Science","dean_list_terms":6}',
     'b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3',
     'admin@eduguard.edu','Internship application at IBM Research'),
    ('CS2021002',1,'unofficial',
     '{"student":"Mariam Hassan","student_number":"CS2021002","cgpa":3.72,"credits_earned":105,"department":"Computer Science","dean_list_terms":6}',
     'c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4',
     'admin@eduguard.edu','Scholarship renewal documentation')
) AS tv(snum, ver, ttype, tdata, shash, gen_email, reason)
JOIN students s ON s.student_number = tv.snum
JOIN users u ON u.email = tv.gen_email;

-- ============================================================
-- TRANSCRIPT VERIFICATIONS
-- ============================================================
INSERT INTO transcript_verifications (
    transcript_id, verification_code, verification_token,
    qr_identifier, is_valid, expires_at, verified_count
)
SELECT tv.id, tver.vcode, tver.vtoken, tver.qrid, TRUE,
       NOW() + INTERVAL '365 days', tver.vcount
FROM (VALUES
    ('CS2021001','EG-CS-2025-001','tok_ahmed_hassan_cs2021001_off_v1_2025','qr_cs2021001_off_v1',2),
    ('DS2021020','EG-DS-2025-001','tok_rania_mostafa_ds2021020_unoff_v1_2025','qr_ds2021020_unoff_v1',1),
    ('CS2021002','EG-CS-2025-002','tok_mariam_hassan_cs2021002_unoff_v1_2025','qr_cs2021002_unoff_v1',0)
) AS tver(snum, vcode, vtoken, qrid, vcount)
JOIN students s ON s.student_number = tver.snum
JOIN transcript_versions tv ON tv.student_id = s.id;

-- ============================================================
-- NOTIFICATIONS
-- ============================================================
INSERT INTO notifications (user_id, title, message, type, priority, read)
SELECT u.id, n.title, n.msg, n.type::notification_type, n.pri::priority_level, n.rd
FROM (VALUES
    ('admin@eduguard.edu','CRITICAL Khaled Samir Risk 93 Percent','DS2023021 reached critical dropout risk 93 percent. Emergency intervention activated.','risk_alert','high',FALSE),
    ('admin@eduguard.edu','CRITICAL Amr Nabil Probation','SE2021016 remains on probation entering 8th semester. Dean review required.','risk_alert','high',FALSE),
    ('admin@eduguard.edu','High Risk Hana Tarek','CS2024008 freshman risk level High 72 percent. Support plan activated.','risk_alert','high',FALSE),
    ('admin@eduguard.edu','Intervention Plan Created','Emergency intervention for Khaled Samir assigned to Dr Kevin Park.','intervention','medium',FALSE),
    ('admin@eduguard.edu','Deans List Fall 2025','Ahmed Hassan, Mariam Hassan, Rania Mostafa, Mahmoud Tarek qualified for Deans List.','system','low',TRUE),
    ('admin@eduguard.edu','Graduation Applications Received','3 students filed Spring 2026 graduation applications this week.','system','medium',FALSE),
    ('admin@eduguard.edu','Quiz Results Available','Advanced Algorithms Quiz 3 results ready for CS301.','quiz','low',TRUE),
    ('admin@eduguard.edu','System Update','EduGuard AI risk engine updated to v4.0 with Sprint 4 academic intelligence.','system','low',TRUE),
    ('j.anderson@eduguard.edu','Risk Alert SE2021016 in CS301','Amr Nabil is failing CS301 grade 42. Risk level Critical.','risk_alert','high',FALSE),
    ('j.anderson@eduguard.edu','Quiz Submissions','18 students submitted Advanced Algorithms Quiz 3.','quiz','low',FALSE),
    ('j.anderson@eduguard.edu','Attendance Alert','CS2024008 Hana Tarek has 45 percent attendance in CS101. Action required.','attendance','high',FALSE),
    ('e.chen@eduguard.edu','Risk Alert AI2023011','Aya Mostafa failing AI401 grade 55. Attendance 55 percent.','risk_alert','high',FALSE),
    ('e.chen@eduguard.edu','Deans List Confirmation','AI2022009 Mahmoud Tarek qualified for Deans List this term.','grade','low',TRUE),
    ('m.wong@eduguard.edu','CRITICAL SE2021016 Amr Nabil','Student failing SE301 44 and SE101 38. Attendance 35 percent. Probation case active.','risk_alert','high',FALSE),
    ('d.nguyen@eduguard.edu','CRITICAL DS2023021 Khaled Samir','Student failing DS301 40 and DS401 38. Attendance 28 percent. Intervention active.','risk_alert','high',FALSE),
    ('d.nguyen@eduguard.edu','Deans List DS2021020','Rania Mostafa qualified for Deans List for 6 consecutive terms.','grade','low',TRUE),
    ('ahmed.hassan@student.eduguard.edu','Deans List Fall 2025','Congratulations! You have been added to the Deans List for Fall 2025.','grade','low',FALSE),
    ('ahmed.hassan@student.eduguard.edu','Transcript Ready','Your official transcript has been generated and verified.','system','low',FALSE),
    ('ahmed.hassan@student.eduguard.edu','Graduation Application Update','Your graduation application for Spring 2026 has been received.','system','medium',FALSE),
    ('ahmed.hassan@student.eduguard.edu','Quiz Available','Advanced Algorithms Quiz 3 is now open. Deadline in 3 days.','quiz','medium',FALSE),
    ('mariam.hassan@student.eduguard.edu','Deans List Fall 2025','Congratulations! You have qualified for the Deans List.','grade','low',FALSE),
    ('mariam.hassan@student.eduguard.edu','Graduation Application Update','Graduation application for Spring 2026 has been received.','system','medium',FALSE),
    ('rania.mostafa@student.eduguard.edu','Deans List 6th Consecutive Term','Outstanding! Deans List status for 6 consecutive terms.','grade','low',FALSE),
    ('rania.mostafa@student.eduguard.edu','Graduation Application Update','Graduation application for Spring 2026 received. Distinction track confirmed.','system','medium',FALSE),
    ('amr.nabil@student.eduguard.edu','Academic Probation Notice','You remain on academic probation. GPA 1.75. Mandatory dean meeting scheduled.','risk_alert','high',FALSE),
    ('amr.nabil@student.eduguard.edu','Advisor Meeting Required','Your advisor Dr Rachel Green has requested an urgent meeting.','intervention','high',FALSE),
    ('amr.nabil@student.eduguard.edu','Attendance Warning','Your attendance in SE301 is 35 percent. FL grade risk is high.','attendance','high',FALSE),
    ('khaled.samir@student.eduguard.edu','URGENT Academic Standing Critical','GPA 1.60, attendance 28 percent. Emergency intervention activated.','risk_alert','high',FALSE),
    ('khaled.samir@student.eduguard.edu','Counseling Services Referral','You have been referred to student counseling services. Please attend your appointment.','intervention','high',FALSE),
    ('khaled.samir@student.eduguard.edu','Attendance Warning','You are absent from DS301, DS401 and CS101. Course failure risk is imminent.','attendance','high',FALSE),
    ('hana.tarek@student.eduguard.edu','Academic Warning Issued','GPA 1.90 is below the minimum threshold. Warning status applied.','risk_alert','high',FALSE),
    ('hana.tarek@student.eduguard.edu','Support Plan Enrolled','You have been enrolled in the Freshman Emergency Support Program.','intervention','high',FALSE),
    ('hana.tarek@student.eduguard.edu','Attendance Contract Required','Your attendance rate 45 percent requires an attendance contract.','attendance','high',FALSE),
    ('mahmoud.tarek@student.eduguard.edu','Deans List Fall 2025','Congratulations! You have been added to the Deans List for Fall 2025.','grade','low',FALSE),
    ('aya.mostafa@student.eduguard.edu','Academic Warning','GPA 2.20 and attendance 55 percent require immediate improvement.','risk_alert','high',FALSE),
    ('aya.mostafa@student.eduguard.edu','Intervention Plan Assigned','Academic Recovery Plan assigned by your advisor.','intervention','high',FALSE)
) AS n(email, title, msg, type, pri, rd)
JOIN users u ON u.email = n.email;

-- ============================================================
-- ACTIVITY LOGS
-- ============================================================
INSERT INTO activity_logs (student_id, action, duration_minutes, resource_type, resource_id)
SELECT s.id, a.action, a.dur, a.rtype, NULL::BIGINT
FROM (VALUES
    ('CS2021001','quiz_attempt',55,'quiz'),('CS2021001','course_view',45,'course'),
    ('CS2021001','assignment_submit',30,'assignment'),('CS2021001','study_session',90,'course'),
    ('CS2021002','quiz_attempt',52,'quiz'),('CS2021002','course_view',40,'course'),
    ('CS2021002','study_session',75,'course'),
    ('DS2021020','quiz_attempt',48,'quiz'),('DS2021020','course_view',60,'course'),
    ('DS2021020','assignment_submit',45,'assignment'),('DS2021020','study_session',120,'course'),
    ('AI2022009','quiz_attempt',50,'quiz'),('AI2022009','course_view',55,'course'),
    ('AI2022009','study_session',90,'course'),
    ('CS2022003','quiz_attempt',42,'quiz'),('CS2022003','course_view',30,'course'),
    ('SEC2022018','quiz_attempt',45,'quiz'),('SEC2022018','course_view',40,'course'),
    ('SEC2022018','assignment_submit',35,'assignment'),
    ('IS2022012','quiz_attempt',40,'quiz'),('IS2022012','course_view',35,'course'),
    ('NET2022014','quiz_attempt',38,'quiz'),('NET2022014','course_view',32,'course'),
    ('CS2022004','quiz_attempt',36,'quiz'),('CS2022004','course_view',28,'course'),
    ('CS2023005','course_view',20,'course'),('CS2023005','quiz_attempt',30,'quiz'),
    ('IS2023013','course_view',18,'course'),('IS2023013','assignment_submit',15,'assignment'),
    ('SE2023017','course_view',25,'course'),('SE2023017','assignment_submit',20,'assignment'),
    ('CS2023006','course_view',12,'course'),('CS2023006','login',5,NULL),
    ('NET2023015','login',3,NULL),('NET2023015','course_view',8,'course'),
    ('AI2023011','login',4,NULL),('AI2023011','course_view',10,'course'),
    ('CS2024007','course_view',22,'course'),('CS2024007','quiz_attempt',28,'quiz'),
    ('CS2024008','login',2,NULL),('CS2024008','course_view',5,'course'),
    ('SE2021016','login',2,NULL),('SE2021016','course_view',4,'course'),
    ('DS2023021','login',1,NULL)
) AS a(snum, action, dur, rtype)
JOIN students s ON s.student_number = a.snum;

-- ============================================================
-- ANNOUNCEMENTS
-- ============================================================
INSERT INTO announcements (author_id, title, content, is_global, published_at)
SELECT u.id, a.title, a.content, TRUE, NOW() + a.off::INTERVAL
FROM (VALUES
    ('admin@eduguard.edu','Welcome to Fall 2025 Semester',
     'Welcome all students. Please verify enrollment and check course schedules. Academic risk monitoring is active via EduGuard AI v4.0.','-5 days'),
    ('admin@eduguard.edu','EduGuard AI Sprint 4 Launch',
     'Sprint 4 academic intelligence features are now live: full transcript management, degree progress tracking, and enhanced GPA projections.','-3 days'),
    ('admin@eduguard.edu','Deans List Fall 2025 Announced',
     'Congratulations to all Deans List recipients for Fall 2025: Ahmed Hassan, Mariam Hassan, Rania Mostafa, Mahmoud Tarek and 3 others.','-1 day'),
    ('admin@eduguard.edu','Mid-Semester Grade Review Deadline',
     'All professors must submit mid-semester progress grades by end of this week to enable risk assessment updates.','-2 days'),
    ('admin@eduguard.edu','Academic Probation Review Sessions',
     'Students on academic probation are reminded that review sessions are scheduled this week. Attendance is mandatory.','-1 day')
) AS a(email, title, content, off)
JOIN users u ON u.email = a.email;

INSERT INTO announcements (author_id, title, content, course_id, is_global, published_at)
SELECT u.id, an.title, an.content, c.id, FALSE, NOW() + an.off::INTERVAL
FROM (VALUES
    ('j.anderson@eduguard.edu','CS301','CS301 Quiz 3 Study Guide',
     'Review chapters 8-12 focusing on Dijkstra and A-star algorithms. No calculators permitted. Time limit 60 minutes.','-3 days'),
    ('j.anderson@eduguard.edu','CS201','CS201 Midterm Results Posted',
     'Midterm results are now available. Average score 72 percent. Please review feedback in the course portal.','-1 day'),
    ('e.chen@eduguard.edu','AI401','AI401 Office Hours Extended',
     'Office hours this week extended: Thursday 3-6 PM and Friday 10 AM to 12 PM for pre-quiz support.','-1 day'),
    ('m.wong@eduguard.edu','SE301','SE301 Project Submission Deadline',
     'Design Pattern project due Friday 11:59 PM. Late submissions will not be accepted. Upload to portal.','-2 days'),
    ('d.nguyen@eduguard.edu','DS301','DS301 Attendance Reminder',
     'Several students have attendance below 70 percent. Note that below 60 percent triggers automatic FL grade review.','-1 day'),
    ('a.martinez@eduguard.edu','SEC301','SEC301 Penetration Lab Results',
     'Lab results posted. Outstanding performance from Layla Ahmed 95 percent. Lab 3 scheduled for next week.','-2 days')
) AS an(email, course_code, title, content, off)
JOIN users u ON u.email = an.email
JOIN courses c ON c.code = an.course_code;

-- ============================================================
-- END OF SEED v5.0
-- Run 003_views.sql next
-- ============================================================