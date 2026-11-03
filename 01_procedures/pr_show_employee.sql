-- pr_show_employee
-- Shows one employee on screen.
-- Concepts: %ROWTYPE record (a box shaped exactly like one row of EMPLOYEES),
--           SELECT INTO, NO_DATA_FOUND and TOO_MANY_ROWS.
CREATE OR REPLACE PROCEDURE pr_show_employee (
    p_employee_id IN NUMBER
)
IS
    v_employee employees%ROWTYPE;
BEGIN
    SELECT *
    INTO v_employee
    FROM employees
    WHERE employee_id = p_employee_id;

    DBMS_OUTPUT.PUT_LINE('EMPLOYEE DETAILS');
    DBMS_OUTPUT.PUT_LINE('------------------------');
    DBMS_OUTPUT.PUT_LINE('ID: ' || v_employee.employee_id);
    DBMS_OUTPUT.PUT_LINE('Name: ' || v_employee.first_name || ' ' || v_employee.last_name);
    DBMS_OUTPUT.PUT_LINE('Job: ' || v_employee.job_title);
    DBMS_OUTPUT.PUT_LINE('Salary: ' || v_employee.salary);
    DBMS_OUTPUT.PUT_LINE('Department: ' || v_employee.department_id);
    DBMS_OUTPUT.PUT_LINE('Status: ' || v_employee.employment_status);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Error: Employee ' || p_employee_id || ' was not found.');
    WHEN TOO_MANY_ROWS THEN
        DBMS_OUTPUT.PUT_LINE('More than one employee was found.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        RAISE;
END;
/
