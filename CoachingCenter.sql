CREATE SCHEMA HOTWAX_COACHING;

USE HOTWAX_COACHING;

CREATE TABLE COURSES (
  COURSE_ID INT PRIMARY KEY,
  COURSE_NAME VARCHAR(100) NOT NULL,
  COURSE_DURATION INT,
  COURSE_FEE DECIMAL(10, 2)
);

CREATE TABLE PERSON (
  PERSON_ID INT PRIMARY KEY,
  PERSON_ROLE VARCHAR(20) NOT NULL CHECK (PERSON_ROLE IN ('STUDENT', 'TEACHER')),
  FIRST_NAME VARCHAR(50) NOT NULL,
  LAST_NAME VARCHAR(50) NOT NULL,
  EMAIL VARCHAR(100) NOT NULL UNIQUE,
  PHONE_NUMBER VARCHAR(15)
);

CREATE TABLE BATCH (
  BATCH_ID INT PRIMARY KEY,
  BATCH_NAME VARCHAR(50),
  START_DATE DATE,
  END_DATE DATE,
  MAX_STUDENTS INT,
  CHECK (END_DATE IS NULL OR START_DATE IS NULL OR END_DATE > START_DATE)
);

-- A student belongs to exactly one batch; PERSON_ID as the PK structurally enforces
-- "single batch per student" instead of relying on application logic.
-- (PERSON_ID must reference a PERSON with PERSON_ROLE = 'STUDENT' -- enforce in app/trigger.)
CREATE TABLE STUDENT_BATCH (
  PERSON_ID INT PRIMARY KEY,
  BATCH_ID INT NOT NULL,
  FROM_DATE DATE NOT NULL,
  FOREIGN KEY (PERSON_ID) REFERENCES PERSON(PERSON_ID),
  FOREIGN KEY (BATCH_ID) REFERENCES BATCH(BATCH_ID)
);

-- Student enrollment in courses -- many-to-many, independent of batch.
-- (PERSON_ID must reference a PERSON with PERSON_ROLE = 'STUDENT' -- enforce in app/trigger.)
CREATE TABLE ENROLLMENT (
  PERSON_ID INT,
  COURSE_ID INT,
  FROM_DATE DATE,
  TO_DATE DATE,
  STATUS VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (STATUS IN ('ACTIVE', 'COMPLETED', 'DROPPED')),
  PRIMARY KEY (PERSON_ID, COURSE_ID, FROM_DATE),
  FOREIGN KEY (PERSON_ID) REFERENCES PERSON(PERSON_ID),
  FOREIGN KEY (COURSE_ID) REFERENCES COURSES(COURSE_ID),
  CHECK (TO_DATE IS NULL OR TO_DATE > FROM_DATE)
);

-- Teacher assigned to teach a course within a batch -- a teacher can teach
-- multiple courses across multiple batches.
-- (TEACHER_ID must reference a PERSON with PERSON_ROLE = 'TEACHER' -- enforce in app/trigger.)
CREATE TABLE COURSE_INSTRUCTOR (
  BATCH_ID INT,
  COURSE_ID INT,
  TEACHER_ID INT,
  FROM_DATE DATE,
  TO_DATE DATE,
  PRIMARY KEY (BATCH_ID, COURSE_ID, TEACHER_ID, FROM_DATE),
  FOREIGN KEY (BATCH_ID) REFERENCES BATCH(BATCH_ID),
  FOREIGN KEY (COURSE_ID) REFERENCES COURSES(COURSE_ID),
  FOREIGN KEY (TEACHER_ID) REFERENCES PERSON(PERSON_ID),
  CHECK (TO_DATE IS NULL OR TO_DATE > FROM_DATE)
);

-- Fee payments made against a specific enrollment.
CREATE TABLE FEE_PAYMENT (
  PAYMENT_ID INT PRIMARY KEY,
  PERSON_ID INT NOT NULL,
  COURSE_ID INT NOT NULL,
  ENROLLMENT_FROM_DATE DATE NOT NULL,
  AMOUNT_PAID DECIMAL(10, 2) NOT NULL,
  PAYMENT_DATE DATE NOT NULL,
  PAYMENT_METHOD VARCHAR(20) CHECK (PAYMENT_METHOD IN ('CASH', 'CARD', 'ONLINE', 'CHEQUE')),
  FOREIGN KEY (PERSON_ID, COURSE_ID, ENROLLMENT_FROM_DATE) REFERENCES ENROLLMENT(PERSON_ID, COURSE_ID, FROM_DATE)
);

-- Per-session attendance for a student within a batch/course.
CREATE TABLE ATTENDANCE (
  BATCH_ID INT,
  COURSE_ID INT,
  PERSON_ID INT,
  ATTENDANCE_DATE DATE,
  STATUS VARCHAR(10) NOT NULL CHECK (STATUS IN ('PRESENT', 'ABSENT', 'LATE')),
  PRIMARY KEY (BATCH_ID, COURSE_ID, PERSON_ID, ATTENDANCE_DATE),
  FOREIGN KEY (BATCH_ID) REFERENCES BATCH(BATCH_ID),
  FOREIGN KEY (COURSE_ID) REFERENCES COURSES(COURSE_ID),
  FOREIGN KEY (PERSON_ID) REFERENCES PERSON(PERSON_ID)
);

-- Exam/assessment results per student per course.
CREATE TABLE EXAM_RESULT (
  RESULT_ID INT PRIMARY KEY,
  PERSON_ID INT NOT NULL,
  COURSE_ID INT NOT NULL,
  EXAM_NAME VARCHAR(100) NOT NULL,
  EXAM_DATE DATE,
  MARKS_OBTAINED DECIMAL(5, 2),
  MAX_MARKS DECIMAL(5, 2),
  FOREIGN KEY (PERSON_ID) REFERENCES PERSON(PERSON_ID),
  FOREIGN KEY (COURSE_ID) REFERENCES COURSES(COURSE_ID)
);

INSERT INTO COURSES (COURSE_ID, COURSE_NAME, COURSE_DURATION, COURSE_FEE) VALUES
(1, 'Java Programming', 30, 5000),
(2, 'Python Programming', 25, 4500),
(3, 'Web Development', 40, 6000),
(4, 'Data Science', 35, 7000),
(5, 'Machine Learning', 45, 8000);

-- ============================================================
-- BATCHES (10)
-- ============================================================
INSERT INTO BATCH (BATCH_ID, BATCH_NAME, START_DATE, END_DATE, MAX_STUDENTS) VALUES
(1, 'Morning Batch A', '2026-01-05', '2026-06-05', 100),
(2, 'Morning Batch B', '2026-01-05', '2026-06-05', 100),
(3, 'Afternoon Batch A', '2026-01-05', '2026-06-05', 100),
(4, 'Afternoon Batch B', '2026-01-05', '2026-06-05', 100),
(5, 'Evening Batch A', '2026-01-05', '2026-06-05', 100),
(6, 'Evening Batch B', '2026-01-05', '2026-06-05', 100),
(7, 'Weekend Batch A', '2026-01-10', '2026-07-10', 100),
(8, 'Weekend Batch B', '2026-01-10', '2026-07-10', 100),
(9, 'Fast Track Batch', '2026-02-01', '2026-05-01', 100),
(10, 'Online Batch', '2026-01-15', '2026-06-15', 100);

-- ============================================================
-- TEACHERS (20) -- PERSON_ID 1-20
-- ============================================================
INSERT INTO PERSON (PERSON_ID, PERSON_ROLE, FIRST_NAME, LAST_NAME, EMAIL, PHONE_NUMBER) VALUES
(1, 'TEACHER', 'Robert', 'Stevens', 'robert.stevens@hotwaxcoaching.com', '9800000001'),
(2, 'TEACHER', 'Susan', 'Mitchell', 'susan.mitchell@hotwaxcoaching.com', '9800000002'),
(3, 'TEACHER', 'William', 'Carter', 'william.carter@hotwaxcoaching.com', '9800000003'),
(4, 'TEACHER', 'Karen', 'Foster', 'karen.foster@hotwaxcoaching.com', '9800000004'),
(5, 'TEACHER', 'Michael', 'Bennett', 'michael.bennett@hotwaxcoaching.com', '9800000005'),
(6, 'TEACHER', 'Laura', 'Coleman', 'laura.coleman@hotwaxcoaching.com', '9800000006'),
(7, 'TEACHER', 'David', 'Reynolds', 'david.reynolds@hotwaxcoaching.com', '9800000007'),
(8, 'TEACHER', 'Angela', 'Brooks', 'angela.brooks@hotwaxcoaching.com', '9800000008'),
(9, 'TEACHER', 'Kevin', 'Sanders', 'kevin.sanders@hotwaxcoaching.com', '9800000009'),
(10, 'TEACHER', 'Rachel', 'Price', 'rachel.price@hotwaxcoaching.com', '9800000010'),
(11, 'TEACHER', 'Brian', 'Cooper', 'brian.cooper@hotwaxcoaching.com', '9800000011'),
(12, 'TEACHER', 'Stephanie', 'Ward', 'stephanie.ward@hotwaxcoaching.com', '9800000012'),
(13, 'TEACHER', 'Eric', 'Bailey', 'eric.bailey@hotwaxcoaching.com', '9800000013'),
(14, 'TEACHER', 'Nicole', 'Richardson', 'nicole.richardson@hotwaxcoaching.com', '9800000014'),
(15, 'TEACHER', 'Jason', 'Cox', 'jason.cox@hotwaxcoaching.com', '9800000015'),
(16, 'TEACHER', 'Amanda', 'Howard', 'amanda.howard@hotwaxcoaching.com', '9800000016'),
(17, 'TEACHER', 'Justin', 'Ross', 'justin.ross@hotwaxcoaching.com', '9800000017'),
(18, 'TEACHER', 'Melissa', 'Barnes', 'melissa.barnes@hotwaxcoaching.com', '9800000018'),
(19, 'TEACHER', 'Ryan', 'Henderson', 'ryan.henderson@hotwaxcoaching.com', '9800000019'),
(20, 'TEACHER', 'Heather', 'Patterson', 'heather.patterson@hotwaxcoaching.com', '9800000020');

-- ============================================================
-- STUDENTS (1000) -- PERSON_ID 21-1020
-- Built from a 40-first-name x 30-last-name pool (1200 distinct
-- combinations), so every student gets a real-looking, distinct name.
-- ============================================================
INSERT INTO PERSON (PERSON_ID, PERSON_ROLE, FIRST_NAME, LAST_NAME, EMAIL, PHONE_NUMBER)
WITH first_names AS (
  SELECT 1 AS id, 'James' AS name UNION ALL SELECT 2, 'Mary' UNION ALL SELECT 3, 'John' UNION ALL
  SELECT 4, 'Patricia' UNION ALL SELECT 5, 'Robert' UNION ALL SELECT 6, 'Jennifer' UNION ALL
  SELECT 7, 'Michael' UNION ALL SELECT 8, 'Linda' UNION ALL SELECT 9, 'William' UNION ALL
  SELECT 10, 'Elizabeth' UNION ALL SELECT 11, 'David' UNION ALL SELECT 12, 'Barbara' UNION ALL
  SELECT 13, 'Richard' UNION ALL SELECT 14, 'Susan' UNION ALL SELECT 15, 'Joseph' UNION ALL
  SELECT 16, 'Jessica' UNION ALL SELECT 17, 'Thomas' UNION ALL SELECT 18, 'Sarah' UNION ALL
  SELECT 19, 'Charles' UNION ALL SELECT 20, 'Karen' UNION ALL SELECT 21, 'Christopher' UNION ALL
  SELECT 22, 'Nancy' UNION ALL SELECT 23, 'Daniel' UNION ALL SELECT 24, 'Lisa' UNION ALL
  SELECT 25, 'Matthew' UNION ALL SELECT 26, 'Margaret' UNION ALL SELECT 27, 'Anthony' UNION ALL
  SELECT 28, 'Betty' UNION ALL SELECT 29, 'Mark' UNION ALL SELECT 30, 'Sandra' UNION ALL
  SELECT 31, 'Donald' UNION ALL SELECT 32, 'Ashley' UNION ALL SELECT 33, 'Steven' UNION ALL
  SELECT 34, 'Dorothy' UNION ALL SELECT 35, 'Paul' UNION ALL SELECT 36, 'Kimberly' UNION ALL
  SELECT 37, 'Andrew' UNION ALL SELECT 38, 'Emily' UNION ALL SELECT 39, 'Joshua' UNION ALL
  SELECT 40, 'Donna'
),
last_names AS (
  SELECT 1 AS id, 'Smith' AS name UNION ALL SELECT 2, 'Johnson' UNION ALL SELECT 3, 'Williams' UNION ALL
  SELECT 4, 'Brown' UNION ALL SELECT 5, 'Jones' UNION ALL SELECT 6, 'Garcia' UNION ALL
  SELECT 7, 'Miller' UNION ALL SELECT 8, 'Davis' UNION ALL SELECT 9, 'Rodriguez' UNION ALL
  SELECT 10, 'Martinez' UNION ALL SELECT 11, 'Hernandez' UNION ALL SELECT 12, 'Lopez' UNION ALL
  SELECT 13, 'Gonzalez' UNION ALL SELECT 14, 'Wilson' UNION ALL SELECT 15, 'Anderson' UNION ALL
  SELECT 16, 'Thomas' UNION ALL SELECT 17, 'Taylor' UNION ALL SELECT 18, 'Moore' UNION ALL
  SELECT 19, 'Jackson' UNION ALL SELECT 20, 'Martin' UNION ALL SELECT 21, 'Lee' UNION ALL
  SELECT 22, 'Perez' UNION ALL SELECT 23, 'Thompson' UNION ALL SELECT 24, 'White' UNION ALL
  SELECT 25, 'Harris' UNION ALL SELECT 26, 'Sanchez' UNION ALL SELECT 27, 'Clark' UNION ALL
  SELECT 28, 'Ramirez' UNION ALL SELECT 29, 'Lewis' UNION ALL SELECT 30, 'Robinson'
),
combos AS (
  SELECT
    f.name AS first_name,
    l.name AS last_name,
    ROW_NUMBER() OVER (ORDER BY f.id, l.id) AS rn
  FROM first_names f
  CROSS JOIN last_names l
)
SELECT
  rn + 20,
  'STUDENT',
  first_name,
  last_name,
  CONCAT(LOWER(first_name), '.', LOWER(last_name), rn, '@hotwaxcoaching.com'),
  CONCAT('97', LPAD(rn, 8, '0'))
FROM combos
WHERE rn <= 1000;

-- ============================================================
-- STUDENT_BATCH -- each of the 1000 students assigned to exactly one
-- of the 10 batches (round-robin).
-- ============================================================
INSERT INTO STUDENT_BATCH (PERSON_ID, BATCH_ID, FROM_DATE)
SELECT
  PERSON_ID,
  ((PERSON_ID - 21) % 10) + 1,
  '2026-01-05'
FROM PERSON
WHERE PERSON_ROLE = 'STUDENT';

-- ============================================================
-- ENROLLMENT -- every student enrolls in one course (round-robin
-- across the 5 courses); roughly a third also enroll in a second,
-- distinct course to exercise the multi-course-per-student rule.
-- ============================================================
INSERT INTO ENROLLMENT (PERSON_ID, COURSE_ID, FROM_DATE, STATUS)
SELECT
  PERSON_ID,
  ((PERSON_ID - 21) % 5) + 1,
  '2026-01-05',
  'ACTIVE'
FROM PERSON
WHERE PERSON_ROLE = 'STUDENT';

INSERT INTO ENROLLMENT (PERSON_ID, COURSE_ID, FROM_DATE, STATUS)
SELECT
  PERSON_ID,
  (((PERSON_ID - 21) % 5) + 1) % 5 + 1,
  '2026-01-05',
  'ACTIVE'
FROM PERSON
WHERE PERSON_ROLE = 'STUDENT' AND (PERSON_ID - 21) % 3 = 0;

-- ============================================================
-- COURSE_INSTRUCTOR -- every (batch, course) combination gets a
-- teacher, cycling through all 20 teachers so each teacher ends up
-- teaching several courses across several batches.
-- ============================================================
INSERT INTO COURSE_INSTRUCTOR (BATCH_ID, COURSE_ID, TEACHER_ID, FROM_DATE)
SELECT
  b.BATCH_ID,
  c.COURSE_ID,
  1 + ((b.BATCH_ID - 1) * 5 + (c.COURSE_ID - 1)) % 20,
  '2026-01-05'
FROM BATCH b
CROSS JOIN COURSES c;
