-- pr_add_employee
-- Adds one new employee.
-- Concepts: implicit cursor on INSERT (SQL%ROWCOUNT), a user-defined exception (e_invalid_salary),
--           a named Oracle error (e_bad_department = ORA-02291), DUP_VAL_ON_INDEX, RAISE_APPLICATION_ERROR.
CREATE OR REPLACE PROCEDURE pr_add_employee (
    p_employee_id   IN NUMBER,
    p_first_name    IN VARCHAR2,
    p_last_name     IN VARCHAR2,
    p_email         IN VARCHAR2,
    p_phone_number  IN VARCHAR2,
    p_hire_date     IN DATE,
    p_job_title     IN VARCHAR2,
    p_salary        IN NUMBER,
    p_department_id IN NUMBER,
    p_status        IN VARCHAR2
)
IS
    e_invalid_salary EXCEPTION;

    e_bad_department EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_bad_department, -2291);
BEGIN
    IF p_salary IS NULL OR p_salary <= 0 THEN
        RAISE e_invalid_salary;
    END IF;

    INSERT INTO employees (
        employee_id, first_name, last_name, email, phone_number,
        hire_date, job_title, salary, department_id, employment_status
    )
    VALUES (
        p_employee_id, p_first_name, p_last_name, p_email, p_phone_number,
        p_hire_date, p_job_title, p_salary, p_department_id, p_status
    );

    DBMS_OUTPUT.PUT_LINE('Employee added. Rows inserted: ' || SQL%ROWCOUNT);

EXCEPTION
    WHEN e_invalid_salary THEN
        RAISE_APPLICATION_ERROR(-20001, 'Employee salary must be greater than zero.');
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20002, 'Employee ID or email already exists.');
    WHEN e_bad_department THEN
        RAISE_APPLICATION_ERROR(-20007, 'Department ' || p_department_id || ' does not exist.');
END;
/
