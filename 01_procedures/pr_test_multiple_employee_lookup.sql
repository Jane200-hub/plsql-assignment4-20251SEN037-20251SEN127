-- pr_test_multiple_employee_lookup
-- A demo on purpose: it asks SELECT INTO for ONE name from a department that has many people.
-- Concepts: TOO_MANY_ROWS and NO_DATA_FOUND, the two classic SELECT INTO errors.
CREATE OR REPLACE PROCEDURE pr_test_multiple_employee_lookup (
    p_department_id IN NUMBER
)
IS
    v_employee_name employees.first_name%TYPE;
BEGIN
    SELECT first_name
    INTO v_employee_name
    FROM employees
    WHERE department_id = p_department_id;

    DBMS_OUTPUT.PUT_LINE('Employee found: ' || v_employee_name);

EXCEPTION
    WHEN TOO_MANY_ROWS THEN
        DBMS_OUTPUT.PUT_LINE('TOO_MANY_ROWS: Multiple employees belong to this department.');
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('NO_DATA_FOUND: No employees belong to this department.');
END;
/
