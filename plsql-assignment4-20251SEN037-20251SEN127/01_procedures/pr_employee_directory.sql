-- pr_employee_directory
-- Prints every employee, one line each.
-- Concepts: user-defined RECORD type, explicit cursor (OPEN, FETCH, CLOSE),
--           cursor attributes %NOTFOUND, %ROWCOUNT and %ISOPEN.
CREATE OR REPLACE PROCEDURE pr_employee_directory
IS
    TYPE t_employee_record IS RECORD (
        employee_id employees.employee_id%TYPE,
        full_name   VARCHAR2(100),
        job_title   employees.job_title%TYPE,
        salary      employees.salary%TYPE
    );

    v_employee t_employee_record;

    CURSOR c_employees IS
        SELECT employee_id,
               first_name || ' ' || last_name AS full_name,
               job_title,
               salary
        FROM employees
        ORDER BY employee_id;
BEGIN
    DBMS_OUTPUT.PUT_LINE('EMPLOYEE DIRECTORY');
    DBMS_OUTPUT.PUT_LINE('------------------------');

    OPEN c_employees;

    LOOP
        FETCH c_employees INTO v_employee;
        EXIT WHEN c_employees%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE(
            v_employee.employee_id || ' | ' || v_employee.full_name ||
            ' | ' || v_employee.job_title || ' | RWF ' || v_employee.salary
        );
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('Employees listed: ' || c_employees%ROWCOUNT);

    CLOSE c_employees;

EXCEPTION
    WHEN OTHERS THEN
        IF c_employees%ISOPEN THEN
            CLOSE c_employees;
        END IF;
        DBMS_OUTPUT.PUT_LINE('Directory error: ' || SQLERRM);
        RAISE;
END;
/
