# Implementation Notes

This is the "how and why" file. The [README](../README.md) shows what the project does. This file explains how we built it, and why we picked each tool.

## The plan in one minute

We built a tiny company: 4 departments, 12 employees, and a payroll table. Then we wrote 10 procedures and 2 functions that run it. Each assignment idea (records, collections, cursors, bulk processing, exceptions) has a real job to do. None of them is just there for show.

## Tables and their rules

The tables guard themselves. Our code checks things too, but a table rule never takes a day off.

| Rule | Table | What it stops |
|---|---|---|
| Primary keys | all three | Two rows pretending to be the same row |
| `UNIQUE` on department name and email | `departments`, `employees` | Twin departments and shared emails |
| Foreign keys | `employees`, `payroll` | An employee in a department that does not exist, or pay for a ghost |
| `salary > 0` | `employees` | Free work |
| Status is `ACTIVE` or `INACTIVE` | `employees` | Made-up statuses |
| Net pay equals basic plus allowances minus deductions | `payroll` | Payslips that do not add up |
| One row per employee and pay period | `payroll` | Paying someone twice for the same month |

Two helpers live in the schema file too. `seq_payroll_id` hands out payroll numbers. `bulk_perf_test` is an empty scratch table for the speed race.

## Records

A record is a box with named slots, so related values travel together.

- **`%ROWTYPE`** makes a box shaped like a whole table row. `pr_show_employee` and `pr_generate_payroll` use it. If someone adds a column later, the box grows by itself.
- **Our own record type** is `t_employee_record` in `pr_employee_directory`. It holds just four things: ID, full name, job title and salary. We built the full name by joining first and last name in the cursor.
- **A list of records** is the batch inside `pr_bulk_onboard_new_hires`. One `INSERT INTO employees VALUES v_hires(i)` saves a whole record at once.

## Collections

A collection is a list that lives in memory. We use **associative arrays** (`INDEX BY PLS_INTEGER`) everywhere.

We picked that kind because it needs no `EXTEND` and no size limit, and `BULK COLLECT` fills it for us. Nested tables and `VARRAY`s are lists too, but they add steps we did not need.

- `pr_bulk_apply_salary_increase` keeps two arrays: employee IDs and new salaries.
- `pr_bulk_onboard_new_hires` keeps one array of records.
- `pr_compare_bulk_vs_loop` keeps one array of numbers to insert.

We lean on `.COUNT` to know how many items a list holds.

## Cursors

A cursor is Oracle's finger, pointing at the row it is working on.

| Kind | Who makes it | Where we use it |
|---|---|---|
| Implicit | Oracle, for every `INSERT`, `UPDATE` and `DELETE` | `pr_add_employee` reads `SQL%ROWCOUNT`. `pr_update_employee_salary` reads `SQL%NOTFOUND`. `pr_delete_employee` reads `SQL%FOUND`. |
| Explicit | Us, with `CURSOR c_employees IS ...` | `pr_employee_directory` does `OPEN`, then `FETCH` in a loop, then `CLOSE` |

The explicit cursor also uses `%NOTFOUND` to know when to stop, `%ROWCOUNT` to count lines, and `%ISOPEN` so the error handler never closes a cursor twice.

## Bulk processing and speed

### Why bulk is faster

PL/SQL and SQL are two different engines. Every time PL/SQL asks SQL to do something, the work jumps from one engine to the other. That jump is called a context switch, and it is not free.

Row by row is one jump per row. With 20000 rows, that is 20000 jumps. Bulk is one jump for the whole pile. Think of buying 20000 apples: one walk to the shop per apple, or one walk with a big bag.

### What we used

- **`BULK COLLECT`** reads many rows into a collection in one jump. See `pr_bulk_apply_salary_increase`.
- **`FORALL`** sends many `INSERT`s or `UPDATE`s in one jump. It is not a loop, even though it looks like one.
- **`SAVE EXCEPTIONS`** deals with bad rows. Without it, the first bad row stops `FORALL`, and Oracle undoes that whole statement. With it, Oracle keeps going and raises `ORA-24381` at the end. The list of bad rows waits in `SQL%BULK_EXCEPTIONS`, with an `ERROR_INDEX` (which row) and an `ERROR_CODE` (what happened). Good rows stay saved until we `COMMIT` or `ROLLBACK`.

`pr_bulk_onboard_new_hires` shows all of this. Its batch has four rows. Two are good, one has a duplicate ID (`ORA-00001`) and one has a department that does not exist (`ORA-02291`). It tells us which rows failed, and sends back the counts through two `OUT` parameters.

### The speed race

With 12 employees, bulk and row by row finish at the same time. Nobody can see the difference. So `pr_compare_bulk_vs_loop` makes its own crowd. It inserts 20000 rows one at a time, then 20000 rows with `FORALL`, and times both with `DBMS_UTILITY.GET_TIME`.

Run `test_success_cases.sql` (test 11) and read the numbers on your own machine. The exact gap changes from computer to computer. Bulk should win by a lot.

Two details keep the race fair and clean. `AUTONOMOUS_TRANSACTION` stops the race from touching your own unsaved work. Both rounds end in `ROLLBACK`, so the scratch table stays empty.

### Memory and `LIMIT`

Our tables are small, so we load every row at once. For a table with millions of rows, that would eat memory. The fix is `LIMIT`, which takes the rows in slices:

```sql
LOOP
    FETCH c_employees BULK COLLECT INTO v_batch LIMIT 1000;
    EXIT WHEN v_batch.COUNT = 0;
    -- work on these 1000 rows, then loop for the next slice
END LOOP;
```

## Functions

A function hands back one answer, so it can sit inside a query.

- **`fn_calculate_net_salary`** returns basic plus allowances minus deductions. Bad input gets an error (`ORA-20010` to `ORA-20013`), not a made-up number. A wrong answer that looks right is worse than a loud failure.
- **`fn_department_salary_total`** adds up the pay of active employees in one department. A department that does not exist gets `ORA-20030`. A real department with nobody active returns 0, which is true.

Both are called from SQL (`SELECT ... FROM dual`), and from an anonymous block (success tests 7 to 9). `pr_generate_payroll` also calls the first one.

## Exceptions

An exception is Oracle yelling "something is wrong". Our job is to catch the yell and say something useful.

| Kind | Ours | Where |
|---|---|---|
| Built into Oracle | `NO_DATA_FOUND`, `TOO_MANY_ROWS`, `DUP_VAL_ON_INDEX` | `pr_show_employee`, `pr_test_multiple_employee_lookup`, `pr_add_employee`, `pr_generate_payroll`, `fn_department_salary_total` |
| Made by us | `e_invalid_salary`, raised with `RAISE` | `pr_add_employee` |
| Oracle error with a name we gave it (`PRAGMA EXCEPTION_INIT`) | `e_bad_department` (`ORA-02291`), `e_has_payroll` (`ORA-02292`), `e_bulk_errors` (`ORA-24381`) | `pr_add_employee`, `pr_delete_employee`, `pr_bulk_onboard_new_hires` |
| Friendly message with a number | `RAISE_APPLICATION_ERROR`, codes `-20001` to `-20040` | everywhere, listed in the [README](../README.md#when-things-go-wrong) |

Our rule is that **no error disappears.** A handler either fixes the problem and says so, or turns the error into a clear message and raises it again. The `WHEN OTHERS` handlers print the problem and then use `RAISE`.

A few procedures print a message and carry on instead of failing. `pr_show_employee` does this for a missing employee. `pr_update_employee_salary` and `pr_delete_employee` do it when nobody matches. We chose that on purpose, so you can see `SQL%NOTFOUND` and `SQL%FOUND` at work. If a project needed a hard stop there, `RAISE_APPLICATION_ERROR` is a one-line change.

## Tests

`03_tests/test_success_cases.sql` has tests 0 to 11. The numbers to look for:

| Test | What you should see |
|---|---|
| 0 | 12 employees |
| 6 | Alice goes from 850000 to 892500, then back to 850000 after `ROLLBACK`. 11 employees processed. |
| 7 and 8 | Net salary 875000. IT department total 3050000. |
| 9 | Department totals 1880000, 3050000, 2450000 and 1500000 |
| 10 | A payroll row for Alice with net salary 875000 |
| 11 | Two timings, with bulk faster |

`03_tests/test_error_cases.sql` has tests 1 to 18. Each one ends in a named error or a friendly message. Test 11 is the most fun, because the employee count goes 12, then 14, then back to 12.

Run the success file first. Tests 8 and 15 in the error file need Alice's October payroll row. You can run both files again and again, because the success file deletes that row before it makes a new one.

## Choices and limits

We would rather tell you than have you find out.

- `pr_test_multiple_employee_lookup` is a teaching demo. It asks for one name from a department with many people, to trigger `TOO_MANY_ROWS`.
- The hire batch in `pr_bulk_onboard_new_hires` is written inside the procedure so the demo needs no extra files. A real system would read it from a staging table.
- `ORA-20006` (no active employees) is not tested. It would need every employee to be inactive, and we did not want to break the sample data to prove it.
- The speed race times will differ on every machine. We did not copy a number into this file, because a number from one laptop would not be true on another.
