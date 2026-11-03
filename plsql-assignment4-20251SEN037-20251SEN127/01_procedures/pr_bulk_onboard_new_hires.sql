-- pr_bulk_onboard_new_hires
-- Hires a small batch of people in one go and reports which rows failed.
-- Concepts: collection of records, FORALL ... SAVE EXCEPTIONS (keep going after a bad row),
--           SQL%BULK_EXCEPTIONS (the list of bad rows), OUT parameters, a named Oracle error (ORA-24381).
-- The batch is built inside the procedure on purpose, so the demo needs no extra files.
-- It holds two good rows, one duplicate ID and one department that does not exist.
CREATE OR REPLACE PROCEDURE pr_bulk_onboard_new_hires (
    p_inserted OUT NUMBER,
    p_failed   OUT NUMBER
)
IS
    TYPE t_hire_list IS TABLE OF employees%ROWTYPE
        INDEX BY PLS_INTEGER;

    v_hires t_hire_list;

    e_bulk_errors EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_bulk_errors, -24381);

    -- Adds one person to the end of the batch.
    PROCEDURE add_hire (
        p_id         IN NUMBER,
        p_first_name IN VARCHAR2,
        p_last_name  IN VARCHAR2,
        p_email      IN VARCHAR2,
        p_job_title  IN VARCHAR2,
        p_salary     IN NUMBER,
        p_department IN NUMBER
    )
    IS
        v_next PLS_INTEGER := v_hires.COUNT + 1;
    BEGIN
        v_hires(v_next).employee_id       := p_id;
        v_hires(v_next).first_name        := p_first_name;
        v_hires(v_next).last_name         := p_last_name;
        v_hires(v_next).email             := p_email;
        v_hires(v_next).hire_date         := TRUNC(SYSDATE);
        v_hires(v_next).job_title         := p_job_title;
        v_hires(v_next).salary            := p_salary;
        v_hires(v_next).department_id     := p_department;
        v_hires(v_next).employment_status := 'ACTIVE';
    END add_hire;
BEGIN
    p_inserted := 0;
    p_failed   := 0;

    add_hire(100014, 'Aline',     'Umutoni',  'aline.umutoni@example.com',  'QA Tester',    520000, 20);
    add_hire(100001, 'Duplicate', 'Hire',     'duplicate.hire@example.com', 'Ghost Writer', 400000, 10);
    add_hire(100015, 'Jean',      'Habineza', 'jean.habineza@example.com',  'Planner',      480000, 99);
    add_hire(100016, 'Mary',      'Ineza',    'mary.ineza@example.com',     'Auditor',      610000, 30);

    FORALL i IN 1 .. v_hires.COUNT SAVE EXCEPTIONS
        INSERT INTO employees VALUES v_hires(i);

    p_inserted := SQL%ROWCOUNT;
    DBMS_OUTPUT.PUT_LINE('All hires inserted. Rows inserted: ' || p_inserted);

EXCEPTION
    WHEN e_bulk_errors THEN
        p_inserted := SQL%ROWCOUNT;
        p_failed   := SQL%BULK_EXCEPTIONS.COUNT;

        DBMS_OUTPUT.PUT_LINE('Bulk insert finished with some bad rows.');
        FOR j IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
            DBMS_OUTPUT.PUT_LINE(
                'Row ' || SQL%BULK_EXCEPTIONS(j).ERROR_INDEX ||
                ' (employee ' || v_hires(SQL%BULK_EXCEPTIONS(j).ERROR_INDEX).employee_id || ')' ||
                ' failed: ' || SQLERRM(-SQL%BULK_EXCEPTIONS(j).ERROR_CODE)
            );
        END LOOP;
        DBMS_OUTPUT.PUT_LINE('Rows inserted: ' || p_inserted || ', rows failed: ' || p_failed);
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Bulk onboarding failed: ' || SQLERRM);
        RAISE;
END;
/
