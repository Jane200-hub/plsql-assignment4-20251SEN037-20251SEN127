-- Run this file only when starting with an empty schema.
-- Order: departments, employees, payroll, the payroll id sequence, then a scratch table for the bulk speed test.

CREATE TABLE departments (
    department_id NUMBER(4) CONSTRAINT pk_departments PRIMARY KEY,
    department_name VARCHAR2(50) NOT NULL UNIQUE,
    location VARCHAR2(100)
);

CREATE TABLE employees (
    employee_id NUMBER(6) CONSTRAINT pk_employees PRIMARY KEY,
    first_name VARCHAR2(40) NOT NULL,
    last_name VARCHAR2(40) NOT NULL,
    email VARCHAR2(100) NOT NULL UNIQUE,
    phone_number VARCHAR2(20),
    hire_date DATE NOT NULL,
    job_title VARCHAR2(60) NOT NULL,
    salary NUMBER(10,2) NOT NULL,
    department_id NUMBER(4) NOT NULL,
    employment_status VARCHAR2(12) NOT NULL,
    CONSTRAINT fk_emp_department
        FOREIGN KEY (department_id) REFERENCES departments(department_id),
    CONSTRAINT chk_emp_salary CHECK (salary > 0),
    CONSTRAINT chk_emp_status
        CHECK (employment_status IN ('ACTIVE', 'INACTIVE'))
);

CREATE TABLE payroll (
    payroll_id NUMBER(8) CONSTRAINT pk_payroll PRIMARY KEY,
    employee_id NUMBER(6) NOT NULL,
    pay_period_start DATE NOT NULL,
    pay_period_end DATE NOT NULL,
    basic_salary NUMBER(10,2) NOT NULL,
    allowances NUMBER(10,2) DEFAULT 0 NOT NULL,
    deductions NUMBER(10,2) DEFAULT 0 NOT NULL,
    net_salary NUMBER(10,2) NOT NULL,
    payment_date DATE,
    payment_status VARCHAR2(12) DEFAULT 'PENDING' NOT NULL,
    CONSTRAINT fk_payroll_employee
        FOREIGN KEY (employee_id) REFERENCES employees(employee_id),
    CONSTRAINT chk_payroll_period
        CHECK (pay_period_end >= pay_period_start),
    CONSTRAINT chk_payroll_amounts
        CHECK (basic_salary >= 0 AND allowances >= 0 AND deductions >= 0),
    CONSTRAINT chk_payroll_deductions
        CHECK (deductions <= basic_salary + allowances),
    CONSTRAINT chk_payroll_net
        CHECK (net_salary = basic_salary + allowances - deductions),
    CONSTRAINT chk_payroll_status
        CHECK (payment_status IN ('PENDING', 'PAID')),
    CONSTRAINT uq_employee_pay_period
        UNIQUE (employee_id, pay_period_start, pay_period_end)
);

-- Hands out a new payroll_id each time pr_generate_payroll saves a row.
CREATE SEQUENCE seq_payroll_id
    START WITH 1
    INCREMENT BY 1
    NOCACHE;

-- Scratch table for pr_compare_bulk_vs_loop. It stays empty: the procedure rolls back its own rows.
CREATE TABLE bulk_perf_test (
    test_id NUMBER NOT NULL,
    method  VARCHAR2(20) NOT NULL
);
