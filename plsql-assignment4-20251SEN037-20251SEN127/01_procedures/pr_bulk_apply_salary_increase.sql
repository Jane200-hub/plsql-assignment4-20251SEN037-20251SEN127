-- pr_bulk_apply_salary_increase
-- Gives every ACTIVE employee a raise, all at once.
-- Concepts: associative arrays (collections), BULK COLLECT (read many rows in one trip),
--           FORALL (write many rows in one trip), SQL%ROWCOUNT, RAISE_APPLICATION_ERROR.
CREATE OR REPLACE PROCEDURE pr_bulk_apply_salary_increase (
    p_percentage IN NUMBER
)
IS
    TYPE t_employee_ids IS TABLE OF employees.employee_id%TYPE
        INDEX BY PLS_INTEGER;

    TYPE t_new_salaries IS TABLE OF employees.salary%TYPE
        INDEX BY PLS_INTEGER;

    v_employee_ids t_employee_ids;
    v_new_salaries t_new_salaries;
BEGIN
    IF p_percentage IS NULL OR p_percentage <= 0 OR p_percentage > 100 THEN
        RAISE_APPLICATION_ERROR(
            -20005,
            'Increase percentage must be greater than 0 and at most 100.'
        );
    END IF;

    SELECT employee_id, salary
    BULK COLLECT INTO v_employee_ids, v_new_salaries
    FROM employees
    WHERE employment_status = 'ACTIVE';

    IF v_employee_ids.COUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20006, 'No active employees found for bulk processing.');
    END IF;

    FOR i IN 1 .. v_employee_ids.COUNT LOOP
        v_new_salaries(i) := v_new_salaries(i) * (1 + p_percentage / 100);
    END LOOP;

    FORALL i IN 1 .. v_employee_ids.COUNT
        UPDATE employees
        SET salary = v_new_salaries(i)
        WHERE employee_id = v_employee_ids(i);

    DBMS_OUTPUT.PUT_LINE('Bulk salary processing completed.');
    DBMS_OUTPUT.PUT_LINE('Employees processed: ' || SQL%ROWCOUNT);
    DBMS_OUTPUT.PUT_LINE('Salary increase applied: ' || p_percentage || '%');

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Bulk processing failed: ' || SQLERRM);
        RAISE;
END;
/
