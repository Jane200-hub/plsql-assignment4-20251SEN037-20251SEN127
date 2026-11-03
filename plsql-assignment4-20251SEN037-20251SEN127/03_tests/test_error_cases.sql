-- ERROR TESTS: everything here is supposed to go wrong, and the code should say why.
-- Most blocks end with a red ORA-200xx message. That is the test passing.
-- Run after test_success_cases.sql, because tests 8 and 15 need Alice's October payroll row.
-- If your tool stays silent about output, run SET SERVEROUTPUT ON first.

-- TEST 1: Missing employee. NO_DATA_FOUND is caught and a friendly message prints.
BEGIN
    pr_show_employee(999999);
END;
/

-- TEST 2: Negative salary. User-defined exception, then ORA-20001.
BEGIN
    pr_add_employee(
        100013, 'Test', 'Employee', 'test.employee@example.com',
        '0780000013', DATE '2026-01-20', 'Test Officer', -100, 10, 'ACTIVE'
    );
END;
/

-- TEST 3: Duplicate employee ID. DUP_VAL_ON_INDEX, then ORA-20002.
BEGIN
    pr_add_employee(
        100001, 'Duplicate', 'Employee', 'duplicate@example.com',
        '0789999999', DATE '2026-01-20', 'Test Officer', 400000, 10, 'ACTIVE'
    );
END;
/

-- TEST 4: Department 99 does not exist. ORA-02291 becomes ORA-20007.
BEGIN
    pr_add_employee(
        100013, 'Test', 'Employee', 'test.employee@example.com',
        '0780000013', DATE '2026-01-20', 'Test Officer', 400000, 99, 'ACTIVE'
    );
END;
/

-- TEST 5: Update an employee who is not there. SQL%NOTFOUND path, no crash.
BEGIN
    pr_update_employee_salary(999999, 500000);
END;
/

-- TEST 6: Negative new salary. ORA-20003.
BEGIN
    pr_update_employee_salary(100001, -5);
END;
/

-- TEST 7: Delete an employee who is not there. SQL%FOUND is false, no crash.
BEGIN
    pr_delete_employee(999999);
END;
/

-- TEST 8: Delete Alice, who has payroll. ORA-02292 becomes ORA-20004.
BEGIN
    pr_delete_employee(100001);
END;
/

-- TEST 9: Invalid raise percentage. ORA-20005.
BEGIN
    pr_bulk_apply_salary_increase(-5);
END;
/

-- TEST 10: One name wanted, many people found. TOO_MANY_ROWS, then NO_DATA_FOUND.
BEGIN
    pr_test_multiple_employee_lookup(10);
END;
/

BEGIN
    pr_test_multiple_employee_lookup(99);
END;
/

-- TEST 11: Bulk insert with bad rows (FORALL SAVE EXCEPTIONS).
-- Expect 2 inserted, 2 failed: row 2 is a duplicate ID (ORA-00001), row 3 has no department (ORA-02291).
-- The good rows stay until we ROLLBACK, so the count goes 12, 14, 12.
SELECT COUNT(*) AS employees_before
FROM employees;

DECLARE
    v_inserted NUMBER;
    v_failed   NUMBER;
BEGIN
    pr_bulk_onboard_new_hires(v_inserted, v_failed);
    DBMS_OUTPUT.PUT_LINE('OUT inserted = ' || v_inserted || ', OUT failed = ' || v_failed);
END;
/

SELECT COUNT(*) AS employees_after_bulk
FROM employees;

ROLLBACK;

SELECT COUNT(*) AS employees_after_rollback
FROM employees;

-- TEST 12: Payroll with a backwards period. ORA-20020.
BEGIN
    pr_generate_payroll(
        100001, DATE '2026-11-30', DATE '2026-11-01', 0, 0
    );
END;
/

-- TEST 13: Payroll for an INACTIVE employee (Sarah, 100012). ORA-20021.
BEGIN
    pr_generate_payroll(
        100012, DATE '2026-11-01', DATE '2026-11-30', 0, 0
    );
END;
/

-- TEST 14: Payroll for an employee who is not there. NO_DATA_FOUND, then ORA-20022.
BEGIN
    pr_generate_payroll(
        999999, DATE '2026-11-01', DATE '2026-11-30', 50000, 25000
    );
END;
/

-- TEST 15: Same payroll twice. DUP_VAL_ON_INDEX, then ORA-20023.
BEGIN
    pr_generate_payroll(
        100001, DATE '2026-10-01', DATE '2026-10-31', 50000, 25000
    );
END;
/

-- TEST 16: Bad function inputs, one at a time. Expect ORA-20010, ORA-20011, ORA-20012, then ORA-20013.
SELECT fn_calculate_net_salary(0, 0, 0) AS net_salary
FROM dual;

SELECT fn_calculate_net_salary(850000, -1, 0) AS net_salary
FROM dual;

SELECT fn_calculate_net_salary(850000, 0, -1) AS net_salary
FROM dual;

SELECT fn_calculate_net_salary(850000, 50000, 5000000) AS net_salary
FROM dual;

-- TEST 17: Bad department for the second function. Expect ORA-20031 (NULL), then ORA-20030 (no such department).
SELECT fn_department_salary_total(NULL) AS total
FROM dual;

SELECT fn_department_salary_total(999) AS total
FROM dual;

-- TEST 18: A speed race with zero rows. ORA-20040.
BEGIN
    pr_compare_bulk_vs_loop(0);
END;
/
