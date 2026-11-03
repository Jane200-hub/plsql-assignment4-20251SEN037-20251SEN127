-- pr_update_employee_salary
-- Changes the salary of one employee.
-- Concepts: implicit cursor on UPDATE, SQL%NOTFOUND (nobody matched) and SQL%ROWCOUNT (how many changed).
CREATE OR REPLACE PROCEDURE pr_update_employee_salary (
    p_employee_id IN NUMBER,
    p_new_salary  IN NUMBER
)
IS
BEGIN
    IF p_new_salary IS NULL OR p_new_salary <= 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'New salary must be greater than zero.');
    END IF;

    UPDATE employees
    SET salary = p_new_salary
    WHERE employee_id = p_employee_id;

    IF SQL%NOTFOUND THEN
        DBMS_OUTPUT.PUT_LINE('No employee found with ID: ' || p_employee_id);
    ELSE
        DBMS_OUTPUT.PUT_LINE('Salary updated. Rows changed: ' || SQL%ROWCOUNT);
    END IF;
END;
/
