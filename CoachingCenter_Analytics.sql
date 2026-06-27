-- ============================================================
-- Coaching Center Analytics
-- Business-facing queries built on top of CoachingCenter.sql
-- ============================================================

USE HOTWAX_COACHING;

-- 1. Course Popularity
-- Business Problem: Which courses are most/least in demand, to guide
-- marketing spend and decide which courses to add more batches for.
SELECT
  c.COURSE_ID,
  c.COURSE_NAME,
  COUNT(*) AS TOTAL_ENROLLMENTS
FROM ENROLLMENT e
JOIN COURSES c ON c.COURSE_ID = e.COURSE_ID
GROUP BY c.COURSE_ID, c.COURSE_NAME
ORDER BY TOTAL_ENROLLMENTS DESC;

-- 2. Batch Capacity Utilization
-- Business Problem: Operations wants to know which batches are full/near
-- capacity (to open a new batch) and which are underfilled (risk of
-- cancelling or merging).
SELECT
  b.BATCH_ID,
  b.BATCH_NAME,
  b.MAX_STUDENTS,
  COUNT(sb.PERSON_ID) AS CURRENT_STRENGTH,
  ROUND(COUNT(sb.PERSON_ID) * 100.0 / b.MAX_STUDENTS, 2) AS UTILIZATION_PCT
FROM BATCH b
LEFT JOIN STUDENT_BATCH sb ON sb.BATCH_ID = b.BATCH_ID
GROUP BY b.BATCH_ID, b.BATCH_NAME, b.MAX_STUDENTS
ORDER BY UTILIZATION_PCT DESC;

-- 3. Students Enrolled in Multiple Courses
-- Business Problem: Identify cross-sell candidates / your most engaged
-- students, who are already taking more than one course.
SELECT
  p.PERSON_ID,
  p.FIRST_NAME,
  p.LAST_NAME,
  COUNT(e.COURSE_ID) AS COURSES_ENROLLED
FROM PERSON p
JOIN ENROLLMENT e ON e.PERSON_ID = p.PERSON_ID
GROUP BY p.PERSON_ID, p.FIRST_NAME, p.LAST_NAME
HAVING COUNT(e.COURSE_ID) > 1
ORDER BY COURSES_ENROLLED DESC;

-- 4. Revenue Collected vs Revenue Due, Per Course
-- Business Problem: Finance needs to track how much of the expected fee
-- (course fee x active enrollments) has actually been collected.
SELECT
  c.COURSE_ID,
  c.COURSE_NAME,
  COUNT(DISTINCT e.PERSON_ID) AS ENROLLED_STUDENTS,
  c.COURSE_FEE * COUNT(DISTINCT e.PERSON_ID) AS REVENUE_DUE,
  COALESCE(SUM(fp.AMOUNT_PAID), 0) AS REVENUE_COLLECTED,
  (c.COURSE_FEE * COUNT(DISTINCT e.PERSON_ID)) - COALESCE(SUM(fp.AMOUNT_PAID), 0) AS REVENUE_OUTSTANDING
FROM COURSES c
JOIN ENROLLMENT e ON e.COURSE_ID = c.COURSE_ID
LEFT JOIN FEE_PAYMENT fp ON fp.PERSON_ID = e.PERSON_ID
  AND fp.COURSE_ID = e.COURSE_ID
  AND fp.ENROLLMENT_FROM_DATE = e.FROM_DATE
GROUP BY c.COURSE_ID, c.COURSE_NAME, c.COURSE_FEE
ORDER BY REVENUE_OUTSTANDING DESC;

-- 5. Students With Outstanding Fees
-- Business Problem: Collections team needs a per-student list of unpaid
-- balances to follow up on.
SELECT
  p.PERSON_ID,
  p.FIRST_NAME,
  p.LAST_NAME,
  c.COURSE_NAME,
  c.COURSE_FEE,
  COALESCE(SUM(fp.AMOUNT_PAID), 0) AS AMOUNT_PAID,
  c.COURSE_FEE - COALESCE(SUM(fp.AMOUNT_PAID), 0) AS AMOUNT_DUE
FROM ENROLLMENT e
JOIN PERSON p ON p.PERSON_ID = e.PERSON_ID
JOIN COURSES c ON c.COURSE_ID = e.COURSE_ID
LEFT JOIN FEE_PAYMENT fp ON fp.PERSON_ID = e.PERSON_ID
  AND fp.COURSE_ID = e.COURSE_ID
  AND fp.ENROLLMENT_FROM_DATE = e.FROM_DATE
GROUP BY p.PERSON_ID, p.FIRST_NAME, p.LAST_NAME, c.COURSE_NAME, c.COURSE_FEE
HAVING c.COURSE_FEE - COALESCE(SUM(fp.AMOUNT_PAID), 0) > 0
ORDER BY AMOUNT_DUE DESC;

-- 6. Monthly Revenue Trend
-- Business Problem: Finance wants to track collections month over month
-- to spot seasonality or a slowdown in cash flow.
SELECT
  DATE_FORMAT(fp.PAYMENT_DATE, '%Y-%m') AS PAYMENT_MONTH,
  COUNT(*) AS TOTAL_PAYMENTS,
  SUM(fp.AMOUNT_PAID) AS TOTAL_COLLECTED
FROM FEE_PAYMENT fp
GROUP BY PAYMENT_MONTH
ORDER BY PAYMENT_MONTH;

-- 7. Teacher Workload
-- Business Problem: Academic ops wants to see how many distinct courses
-- and batches each teacher is currently handling, to balance load.
SELECT
  p.PERSON_ID AS TEACHER_ID,
  p.FIRST_NAME,
  p.LAST_NAME,
  COUNT(DISTINCT ci.COURSE_ID) AS COURSES_TAUGHT,
  COUNT(DISTINCT ci.BATCH_ID) AS BATCHES_HANDLED
FROM PERSON p
JOIN COURSE_INSTRUCTOR ci ON ci.TEACHER_ID = p.PERSON_ID
WHERE p.PERSON_ROLE = 'TEACHER'
GROUP BY p.PERSON_ID, p.FIRST_NAME, p.LAST_NAME
ORDER BY BATCHES_HANDLED DESC, COURSES_TAUGHT DESC;

-- 8. Batches With No Assigned Teacher For a Course
-- Business Problem: Academic ops needs to catch scheduling gaps before
-- a batch starts a course with nobody assigned to teach it.
SELECT
  b.BATCH_ID,
  b.BATCH_NAME,
  c.COURSE_ID,
  c.COURSE_NAME
FROM BATCH b
CROSS JOIN COURSES c
LEFT JOIN COURSE_INSTRUCTOR ci ON ci.BATCH_ID = b.BATCH_ID AND ci.COURSE_ID = c.COURSE_ID
WHERE ci.TEACHER_ID IS NULL;

-- 9. Student Attendance Percentage Per Course
-- Business Problem: Academic counselors track attendance to flag
-- students who may need an intervention.
SELECT
  p.PERSON_ID,
  p.FIRST_NAME,
  p.LAST_NAME,
  a.COURSE_ID,
  COUNT(*) AS TOTAL_SESSIONS,
  SUM(CASE WHEN a.STATUS = 'PRESENT' THEN 1 ELSE 0 END) AS SESSIONS_PRESENT,
  ROUND(SUM(CASE WHEN a.STATUS = 'PRESENT' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS ATTENDANCE_PCT
FROM ATTENDANCE a
JOIN PERSON p ON p.PERSON_ID = a.PERSON_ID
GROUP BY p.PERSON_ID, p.FIRST_NAME, p.LAST_NAME, a.COURSE_ID;

-- 10. Students At Risk (Attendance Below 75%)
-- Business Problem: Proactively identify students likely to disengage
-- or fail, based on low attendance.
SELECT
  p.PERSON_ID,
  p.FIRST_NAME,
  p.LAST_NAME,
  a.COURSE_ID,
  ROUND(SUM(CASE WHEN a.STATUS = 'PRESENT' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS ATTENDANCE_PCT
FROM ATTENDANCE a
JOIN PERSON p ON p.PERSON_ID = a.PERSON_ID
GROUP BY p.PERSON_ID, p.FIRST_NAME, p.LAST_NAME, a.COURSE_ID
HAVING ATTENDANCE_PCT < 75
ORDER BY ATTENDANCE_PCT;

-- 11. Average Exam Score Per Course
-- Business Problem: Academic team wants to compare how students are
-- performing across different courses to spot course content/difficulty
-- issues.
SELECT
  c.COURSE_ID,
  c.COURSE_NAME,
  COUNT(*) AS TOTAL_ATTEMPTS,
  ROUND(AVG(er.MARKS_OBTAINED * 100.0 / er.MAX_MARKS), 2) AS AVG_SCORE_PCT
FROM EXAM_RESULT er
JOIN COURSES c ON c.COURSE_ID = er.COURSE_ID
GROUP BY c.COURSE_ID, c.COURSE_NAME
ORDER BY AVG_SCORE_PCT DESC;

-- 12. Top 10 Performing Students Overall
-- Business Problem: Recognize top performers (for scholarships,
-- testimonials, etc.) based on average score across all their exams.
SELECT
  p.PERSON_ID,
  p.FIRST_NAME,
  p.LAST_NAME,
  ROUND(AVG(er.MARKS_OBTAINED * 100.0 / er.MAX_MARKS), 2) AS AVG_SCORE_PCT
FROM EXAM_RESULT er
JOIN PERSON p ON p.PERSON_ID = er.PERSON_ID
GROUP BY p.PERSON_ID, p.FIRST_NAME, p.LAST_NAME
ORDER BY AVG_SCORE_PCT DESC
LIMIT 10;

-- 13. Pass Percentage Per Batch
-- Business Problem: Compare batches against each other (e.g. morning
-- vs evening, online vs offline) on academic outcomes, using 40% as
-- the passing threshold.
SELECT
  sb.BATCH_ID,
  b.BATCH_NAME,
  COUNT(*) AS TOTAL_ATTEMPTS,
  SUM(CASE WHEN er.MARKS_OBTAINED * 100.0 / er.MAX_MARKS >= 40 THEN 1 ELSE 0 END) AS PASSED,
  ROUND(SUM(CASE WHEN er.MARKS_OBTAINED * 100.0 / er.MAX_MARKS >= 40 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS PASS_PCT
FROM EXAM_RESULT er
JOIN STUDENT_BATCH sb ON sb.PERSON_ID = er.PERSON_ID
JOIN BATCH b ON b.BATCH_ID = sb.BATCH_ID
GROUP BY sb.BATCH_ID, b.BATCH_NAME
ORDER BY PASS_PCT DESC;

-- 14. Course Dropout Rate
-- Business Problem: Retention tracking -- what fraction of enrollments
-- for each course end in DROPPED rather than ACTIVE/COMPLETED.
SELECT
  c.COURSE_ID,
  c.COURSE_NAME,
  COUNT(*) AS TOTAL_ENROLLMENTS,
  SUM(CASE WHEN e.STATUS = 'DROPPED' THEN 1 ELSE 0 END) AS DROPPED,
  ROUND(SUM(CASE WHEN e.STATUS = 'DROPPED' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS DROPOUT_PCT
FROM ENROLLMENT e
JOIN COURSES c ON c.COURSE_ID = e.COURSE_ID
GROUP BY c.COURSE_ID, c.COURSE_NAME
ORDER BY DROPOUT_PCT DESC;

-- 15. New Student Enrollments Per Month
-- Business Problem: Growth tracking -- how many new students joined
-- each month, to measure marketing/admissions performance over time.
SELECT
  DATE_FORMAT(e.FROM_DATE, '%Y-%m') AS ENROLLMENT_MONTH,
  COUNT(DISTINCT e.PERSON_ID) AS NEW_STUDENTS
FROM ENROLLMENT e
GROUP BY ENROLLMENT_MONTH
ORDER BY ENROLLMENT_MONTH;
