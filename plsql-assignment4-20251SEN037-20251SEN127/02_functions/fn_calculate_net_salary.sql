-- fn_calculate_net_salary
-- Net salary = basic salary + allowances - deductions.
-- Says "no" with RAISE_APPLICATION_ERROR for bad inputs instead of returning a wrong number.
-- Used by pr_generate_payroll, and you can call it straight from SQL.
CREATE OR REPLACE FUNCTION fn_calculate_net_salary (
    p_basic_salary IN NUMBER,
    p_allowances   IN NUMBER,
    p_deductions   IN NUMBER
)
RETURN NUMBER
IS
    v_gross_salary NUMBER(10,2);
BEGIN
    IF p_basic_salary IS NULL OR p_basic_salary <= 0 THEN
        RAISE_APPLICATION_ERROR(-20010, 'Basic salary must be greater than zero.');
    END IF;

    IF p_allowances IS NULL OR p_allowances < 0 THEN
        RAISE_APPLICATION_ERROR(-20011, 'Allowances cannot be negative or NULL.');
    END IF;

    IF p_deductions IS NULL OR p_deductions < 0 THEN
        RAISE_APPLICATION_ERROR(-20012, 'Deductions cannot be negative or NULL.');
    END IF;

    v_gross_salary := p_basic_salary + p_allowances;

    IF p_deductions > v_gross_salary THEN
        RAISE_APPLICATION_ERROR(-20013, 'Deductions cannot exceed gross salary.');
    END IF;

    RETURN v_gross_salary - p_deductions;
END;
/
