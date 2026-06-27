# Coaching Center — ER Diagram

ER diagram for the schema defined in [CoachingCenter.sql](CoachingCenter.sql). Rendered with Mermaid (GitHub renders this natively).

```mermaid
erDiagram
    PERSON {
        int PERSON_ID PK
        varchar PERSON_ROLE "STUDENT | TEACHER"
        varchar FIRST_NAME
        varchar LAST_NAME
        varchar EMAIL "UNIQUE"
        varchar PHONE_NUMBER
    }

    COURSES {
        int COURSE_ID PK
        varchar COURSE_NAME
        int COURSE_DURATION
        decimal COURSE_FEE
    }

    BATCH {
        int BATCH_ID PK
        varchar BATCH_NAME
        date START_DATE
        date END_DATE
        int MAX_STUDENTS
    }

    STUDENT_BATCH {
        int PERSON_ID PK, FK
        int BATCH_ID FK
        date FROM_DATE
    }

    ENROLLMENT {
        int PERSON_ID PK, FK
        int COURSE_ID PK, FK
        date FROM_DATE PK
        date TO_DATE
        varchar STATUS "ACTIVE | COMPLETED | DROPPED"
    }

    COURSE_INSTRUCTOR {
        int BATCH_ID PK, FK
        int COURSE_ID PK, FK
        int TEACHER_ID PK, FK
        date FROM_DATE PK
        date TO_DATE
    }

    FEE_PAYMENT {
        int PAYMENT_ID PK
        int PERSON_ID FK
        int COURSE_ID FK
        date ENROLLMENT_FROM_DATE FK
        decimal AMOUNT_PAID
        date PAYMENT_DATE
        varchar PAYMENT_METHOD "CASH | CARD | ONLINE | CHEQUE"
    }

    ATTENDANCE {
        int BATCH_ID PK, FK
        int COURSE_ID PK, FK
        int PERSON_ID PK, FK
        date ATTENDANCE_DATE PK
        varchar STATUS "PRESENT | ABSENT | LATE"
    }

    EXAM_RESULT {
        int RESULT_ID PK
        int PERSON_ID FK
        int COURSE_ID FK
        varchar EXAM_NAME
        date EXAM_DATE
        decimal MARKS_OBTAINED
        decimal MAX_MARKS
    }

    %% A student belongs to exactly one batch (PK on PERSON_ID enforces this)
    PERSON ||--o| STUDENT_BATCH : "student belongs to"
    BATCH  ||--o{ STUDENT_BATCH : "has students"

    %% A student enrolls in many courses
    PERSON  ||--o{ ENROLLMENT : "enrolls in"
    COURSES ||--o{ ENROLLMENT : "has enrollments"

    %% A teacher teaches many courses across many batches
    BATCH   ||--o{ COURSE_INSTRUCTOR : "runs"
    COURSES ||--o{ COURSE_INSTRUCTOR : "taught as"
    PERSON  ||--o{ COURSE_INSTRUCTOR : "teaches"

    %% Fee payments are made against a specific enrollment
    ENROLLMENT ||--o{ FEE_PAYMENT : "paid via"

    %% Attendance is tracked per student, per batch/course session
    BATCH   ||--o{ ATTENDANCE : "tracks"
    COURSES ||--o{ ATTENDANCE : "tracks"
    PERSON  ||--o{ ATTENDANCE : "attends"

    %% Exam results are tracked per student, per course
    PERSON  ||--o{ EXAM_RESULT : "takes"
    COURSES ||--o{ EXAM_RESULT : "assessed in"
```

## Notes

- `PERSON` is a single table for both roles (`STUDENT` / `TEACHER`), distinguished by `PERSON_ROLE`. The diagram shows it linked from both the student-side tables (`STUDENT_BATCH`, `ENROLLMENT`, `ATTENDANCE`, `EXAM_RESULT`) and the teacher-side table (`COURSE_INSTRUCTOR`) — these are the same physical table, not two entities.
- `STUDENT_BATCH.PERSON_ID` is the primary key (not part of a composite key), which structurally enforces the rule that **a student belongs to exactly one batch**.
- `ENROLLMENT` and `COURSE_INSTRUCTOR` are many-to-many(-to-many) junction tables, which is how **a student enrolls in multiple courses** and **a teacher teaches multiple courses across multiple batches** are both represented.
- `FEE_PAYMENT` references `ENROLLMENT`'s composite key (`PERSON_ID`, `COURSE_ID`, `FROM_DATE`), so a payment is always tied to a specific enrollment period, not just a student/course pair in the abstract.
