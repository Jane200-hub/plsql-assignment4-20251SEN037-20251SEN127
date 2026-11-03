-- pr_generate_payroll
-- Makes one payroll row for one ACTIVE employee and one pay period.
-- Concepts: %ROWTYPE record, calling the function fn_calculate_net_salary,
--           NO_DATA_FOUND and DUP_VAL_ON_INDEX turned into friendly RAISE_APPLICATION_ERROR messages.
-- Needs: fn_calculate_net_salary and the sequence seq_payroll_id (both made by earlier steps).
CREATE OR REPLACE PROCEDURE pr_generate_payroll (
    p_employee_id  IN NUMBER,
    p_period_start IN DATE,
    p_period_end   IN DATE,
    p_allowances   IN NUMBER,
    p_deductions   IN NUMBER
)
IS
    v_employee   employees%ROWTYPE;
    v_net_salary NUMBER(10,2);
BEGIN
    IF p_period_start IS NULL OR p_period_end IS NULL
       OR p_period_end < p_period_start THEN
        RAISE_APPLICATION_ERROR(-20020, 'Invalid payroll period.');
    END IF;

    SELECT *
    INTO v_employee
    FROM employees
    WHERE employee_id = p_employee_id;

    IF v_employee.employment_status <> 'ACTIVE' THEN
        RAISE_APPLICATION_ERROR(-20021, 'Employee is not active.');
    END IF;

    v_net_salary := fn_calculate_net_salary(
        v_employee.salary,
        p_allowances,
        p_deductions
    );

    INSERT INTO payroll (
        payroll_id, employee_id, pay_period_start, pay_period_end,
        basic_salary, allowances, deductions, net_salary, payment_status
    )
    VALUES (
        seq_payroll_id.NEXTVAL, p_employee_id, p_period_start, p_period_end,
        v_employee.salary, p_allowances, p_deductions, v_net_salary, 'PENDING'
    );

    DBMS_OUTPUT.PUT_LINE('Payroll generated successfully.');
    DBMS_OUTPUT.PUT_LINE('Employee: ' || v_employee.first_name || ' ' || v_employee.last_name);
    DBMS_OUTPUT.PUT_LINE('Basic salary: ' || v_employee.salary);
    DBMS_OUTPUT.PUT_LINE('Net salary: ' || v_net_salary);
    DBMS_OUTPUT.PUT_LINE('Rows inserted: ' || SQL%ROWCOUNT);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20022, 'Employee not found.');
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20023, 'Payroll already exists for this employee and period.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Payroll error: ' || SQLERRM);
        RAISE;
END;
/
