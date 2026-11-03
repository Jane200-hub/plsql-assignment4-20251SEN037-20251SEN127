-- SUCCESS TESTS: everything here should work.
-- Run after the schema, sample data, functions and procedures are all ready.
-- If your tool stays silent about output, run SET SERVEROUTPUT ON first.

-- TEST 0: Sample data is in. Expect 12 employees.
SELECT COUNT(*) AS total_employees
FROM employees;

-- TEST 1: Display an existing employee (%ROWTYPE record)
BEGIN
    pr_show_employee(100001);
END;
/

-- TEST 2: Display the employee directory (user-defined record + explicit cursor)
BEGIN
    pr_employee_directory;
END;
/

-- TEST 3: Add an employee (implicit cursor on INSERT)
BEGIN
    pr_add_employee(
        100013, 'Test', 'Employee', 'test.employee@example.com',
        '0780000013', DATE '2026-01-20', 'Test Officer', 400000, 10, 'ACTIVE'
    );
END;
/

-- TEST 4: Update that employee's salary (implicit cursor on UPDATE)
BEGIN
    pr_update_employee_salary(100013, 450000);
END;
/

-- TEST 5: Delete that employee (implicit cursor on DELETE)
BEGIN
    pr_delete_employee(100013);
END;
/

-- TEST 6: Bulk 5% raise (BULK COLLECT + FORALL). Alice should go from 850000 to 892500.
BEGIN
    pr_bulk_apply_salary_increase(5);
END;
/

SELECT employee_id, first_name, salary
FROM employees
WHERE employee_id = 100001;

-- Undo the raise so the sample salaries stay the same.
ROLLBACK;

SELECT employee_id, first_name, salary
FROM employees
WHERE employee_id = 100001;

-- TEST 7: Function called from SQL. Expect 875000.
SELECT fn_calculate_net_salary(850000, 50000, 25000) AS net_salary
FROM dual;

-- TEST 8: Functions called from an anonymous block. Expect 875000 and 3050000.
DECLARE
    v_net_salary NUMBER;
    v_it_total   NUMBER;
BEGIN
    v_net_salary := fn_calculate_net_salary(850000, 50000, 25000);
    v_it_total   := fn_department_salary_total(20);

    DBMS_OUTPUT.PUT_LINE('Net salary from a block: ' || v_net_salary);
    DBMS_OUTPUT.PUT_LINE('IT active salary total: ' || v_it_total);
END;
/

-- TEST 9: A function called once per row in a query.
-- Expect 1880000, 3050000, 2450000 and 1500000 (Sarah is INACTIVE, so Marketing skips her).
SELECT department_id,
       department_name,
       fn_department_salary_total(department_id) AS active_salary_total
FROM departments
ORDER BY department_id;

-- TEST 10: Generate payroll for Alice, October 2026. Expect net salary 875000.
-- The DELETE first lets you run this file again without a duplicate-payroll error.
DELETE FROM payroll
WHERE employee_id = 100001
  AND pay_period_start = DATE '2026-10-01'
  AND pay_period_end = DATE '2026-10-31';

COMMIT;

BEGIN
    pr_generate_payroll(
        100001, DATE '2026-10-01', DATE '2026-10-31', 50000, 25000
    );
END;
/

COMMIT;

SELECT *
FROM payroll
WHERE employee_id = 100001
  AND pay_period_start = DATE '2026-10-01';

-- TEST 11: The speed race. Row by row vs FORALL, 20000 inserts each.
-- Your times will differ. Bulk should win by a lot.
BEGIN
    pr_compare_bulk_vs_loop(20000);
END;
/
