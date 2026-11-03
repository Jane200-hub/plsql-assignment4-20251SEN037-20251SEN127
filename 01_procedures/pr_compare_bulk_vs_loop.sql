-- pr_compare_bulk_vs_loop
-- A speed race: insert the same number of rows one by one, then with FORALL, and time both.
-- Concepts: why bulk processing is faster (fewer trips between the PL/SQL engine and the SQL engine),
--           an associative array, FORALL, DBMS_UTILITY.GET_TIME (counts in hundredths of a second).
-- AUTONOMOUS_TRANSACTION keeps the race away from your own uncommitted work.
-- Both rounds ROLLBACK their rows, so BULK_PERF_TEST stays empty.
CREATE OR REPLACE PROCEDURE pr_compare_bulk_vs_loop (
    p_rows IN NUMBER DEFAULT 20000
)
IS
    PRAGMA AUTONOMOUS_TRANSACTION;

    TYPE t_id_list IS TABLE OF bulk_perf_test.test_id%TYPE
        INDEX BY PLS_INTEGER;

    v_ids       t_id_list;
    v_start     NUMBER;
    v_loop_time NUMBER;
    v_bulk_time NUMBER;
BEGIN
    IF p_rows IS NULL OR p_rows < 1 OR p_rows > 100000 THEN
        RAISE_APPLICATION_ERROR(-20040, 'Row count must be between 1 and 100000.');
    END IF;

    -- Round 1: one INSERT per trip.
    v_start := DBMS_UTILITY.GET_TIME;
    FOR i IN 1 .. p_rows LOOP
        INSERT INTO bulk_perf_test (test_id, method) VALUES (i, 'ROW BY ROW');
    END LOOP;
    v_loop_time := DBMS_UTILITY.GET_TIME - v_start;
    ROLLBACK;

    -- Round 2: pack the ids into a collection, then send them all in one trip.
    FOR i IN 1 .. p_rows LOOP
        v_ids(i) := i;
    END LOOP;

    v_start := DBMS_UTILITY.GET_TIME;
    FORALL i IN 1 .. v_ids.COUNT
        INSERT INTO bulk_perf_test (test_id, method) VALUES (v_ids(i), 'BULK');
    v_bulk_time := DBMS_UTILITY.GET_TIME - v_start;
    ROLLBACK;

    DBMS_OUTPUT.PUT_LINE('SPEED RACE: ' || p_rows || ' inserts');
    DBMS_OUTPUT.PUT_LINE('------------------------');
    DBMS_OUTPUT.PUT_LINE('Row by row: ' || TO_CHAR(v_loop_time / 100, 'FM990.00') || ' seconds');
    DBMS_OUTPUT.PUT_LINE('FORALL bulk: ' || TO_CHAR(v_bulk_time / 100, 'FM990.00') || ' seconds');

    IF v_bulk_time > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Bulk was about ' || ROUND(v_loop_time / v_bulk_time, 1) || ' times faster.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Bulk finished in under 0.01 seconds.');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Speed race failed: ' || SQLERRM);
        RAISE;
END;
/
