-- ============================================================
-- EduGuard AI — Demo Users Seed  (004_demo_users.sql)
-- ============================================================
-- Run AFTER 002_seed.sql every time you reseed.
--
-- Passwords:
--   admin@eduguard.edu                      → 1
--   j.anderson@eduguard.edu                 → 11
--   ta.marcus@eduguard.edu                  → 111
--   ahmed.hassan@student.eduguard.edu       → 1111
--   (all other seeded users)                → password123
-- ============================================================

UPDATE users SET hashed_password = '$2b$12$wjx2p3/7UEWmn8CBZbjggeNup8OYvxLKAl1DJ12Fao77VE8JX9FZe'
WHERE email = 'admin@eduguard.edu';

UPDATE users SET hashed_password = '$2b$12$Y5Kr.EeJ65ZCLXqyGWdomutnTRKW8BB9pmCI0fkV8gBAKA9LNGcYC'
WHERE email = 'j.anderson@eduguard.edu';

UPDATE users SET hashed_password = '$2b$12$zJDzhRUHdS6kCNevedO9Eu27AUuo36XseizgZ3cgU7Bp.CTHkyAJG'
WHERE email = 'ta.marcus@eduguard.edu';

UPDATE users SET hashed_password = '$2b$12$RRZf7fTgnvj4/DsAh8kl3OwqrVvdQRDb1PpiDGlJZ9uDXe6TXrIaa'
WHERE email = 'ahmed.hassan@student.eduguard.edu';

-- Verify (run manually after seeding):
-- SELECT email, role, LEFT(hashed_password,7) AS prefix FROM users
-- WHERE email IN (
--   'admin@eduguard.edu',
--   'j.anderson@eduguard.edu',
--   'ta.marcus@eduguard.edu',
--   'ahmed.hassan@student.eduguard.edu'
-- );