-- pr_delete_employee
-- Removes one employee, unless payroll rows still point at them.
-- Concepts: implicit cursor on DELETE (SQL%FOUND, SQL%ROWCOUNT),
--           a named exception for ORA-02292 (child rows exist), RAISE_APPLICATION_ERROR.
CREATE OR REPLACE PROCEDURE pr_delete_employee (
    p_employee_id IN NUMBER
)
IS
    e_has_payroll EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_has_payroll, -2292);
BEGIN
    DELETE FROM employees
    WHERE employee_id = p_employee_id;

    IF SQL%FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Employee deleted. Rows deleted: ' || SQL%ROWCOUNT);
    ELSE
        DBMS_OUTPUT.PUT_LINE('No employee found with ID: ' || p_employee_id);
    END IF;

EXCEPTION
    WHEN e_has_payroll THEN
        RAISE_APPLICATION_ERROR(-20004, 'Cannot delete this employee because payroll records exist.');
END;
/
