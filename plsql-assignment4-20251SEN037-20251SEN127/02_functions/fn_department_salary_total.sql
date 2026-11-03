-- fn_department_salary_total
-- Adds up the salaries of the ACTIVE people in one department.
-- A department that does not exist raises an error. A real department with nobody active returns 0.
-- Concepts: local variables, NO_DATA_FOUND turned into RAISE_APPLICATION_ERROR, callable from SQL or a block.
CREATE OR REPLACE FUNCTION fn_department_salary_total (
    p_department_id IN NUMBER
)
RETURN NUMBER
IS
    v_department_name departments.department_name%TYPE;
    v_total           NUMBER(14,2);
BEGIN
    IF p_department_id IS NULL THEN
        RAISE_APPLICATION_ERROR(-20031, 'Department ID cannot be NULL.');
    END IF;

    SELECT department_name
    INTO v_department_name
    FROM departments
    WHERE department_id = p_department_id;

    SELECT NVL(SUM(salary), 0)
    INTO v_total
    FROM employees
    WHERE department_id = p_department_id
      AND employment_status = 'ACTIVE';

    RETURN v_total;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20030, 'Department ' || p_department_id || ' does not exist.');
END;
/
