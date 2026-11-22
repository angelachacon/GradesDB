--
-- Autor: Ángela Chacón
-- Fecha: Noviembre de 2026
-- 
USE grades_db;

CREATE OR REPLACE TABLE test_results (
    test_id VARCHAR(20) PRIMARY KEY,
    test_name VARCHAR(200) NOT NULL,
    test_message VARCHAR(500) NOT NULL,
    test_status ENUM('PASS','FAIL') NOT NULL,
    execution_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DELIMITER //

CREATE OR REPLACE PROCEDURE p_log_test(
    IN p_test_id VARCHAR(20),
    IN p_message VARCHAR(500),
    IN p_status ENUM('PASS','FAIL')
)
BEGIN
    INSERT INTO test_results(test_id, test_name, test_message, test_status)
    VALUES (p_test_id, SUBSTRING_INDEX(p_message, ':', 1), p_message, p_status);
END //

-- RN02: una nota solo en grupos a los que pertenece el alumno
CREATE OR REPLACE PROCEDURE p_test_rn02_grade_in_group()
BEGIN
    DECLARE v_msg VARCHAR(500) DEFAULT '';
    DECLARE v_student INT;
    DECLARE v_group INT;
    DECLARE v_call VARCHAR(30);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
        ROLLBACK;
        IF v_msg LIKE 'RN02%' THEN
            CALL p_log_test('RN02', 'RN02: No se permite una nota en un grupo al que no pertenece el alumno', 'PASS');
        ELSE
            CALL p_log_test('RN02', CONCAT('ERROR inesperado: ', LEFT(v_msg, 300)), 'FAIL');
        END IF;
    END;

    START TRANSACTION;
    SELECT exam_call INTO v_call FROM grades LIMIT 1;
    -- Un alumno y un grupo en el que NO está matriculado
    SELECT s.student_id, g.group_id INTO v_student, v_group
    FROM students s
    CROSS JOIN groups g
    WHERE NOT EXISTS (SELECT 1 FROM group_enrollments ge
                      WHERE ge.student_id = s.student_id AND ge.group_id = g.group_id)
    LIMIT 1;

    INSERT INTO grades (student_id, group_id, grade_value, exam_call, with_honors)
        VALUES (v_student, v_group, 7.0, v_call, 0);

    ROLLBACK;
    CALL p_log_test('RN02', 'ERROR: Se permitió una nota en un grupo al que no pertenece el alumno', 'FAIL');
END //

-- RN03: un grupo no puede tener más de 2 profesores
CREATE OR REPLACE PROCEDURE p_test_rn03_professors_per_group()
BEGIN
    DECLARE v_msg VARCHAR(500) DEFAULT '';
    DECLARE v_group INT;
    DECLARE v_prof INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
        ROLLBACK;
        IF v_msg LIKE 'RN03%' THEN
            CALL p_log_test('RN03', 'RN03: No se permite añadir un tercer profesor al grupo', 'PASS');
        ELSE
            CALL p_log_test('RN03', CONCAT('ERROR inesperado: ', LEFT(v_msg, 300)), 'FAIL');
        END IF;
    END;

    START TRANSACTION;
    -- Un grupo que ya tiene 2 profesores y un profesor que no está en él
    SELECT group_id INTO v_group
    FROM teaching_loads GROUP BY group_id HAVING COUNT(*) >= 2 LIMIT 1;
    SELECT professor_id INTO v_prof
    FROM professors
    WHERE professor_id NOT IN (SELECT professor_id FROM teaching_loads WHERE group_id = v_group)
    LIMIT 1;

    INSERT INTO teaching_loads (professor_id, group_id, credits) VALUES (v_prof, v_group, 1.0);

    ROLLBACK;
    CALL p_log_test('RN03', 'ERROR: Se asignó un tercer profesor al grupo', 'FAIL');
END //

-- RN04: un alumno, como máximo un grupo de cada actividad por asignatura
CREATE OR REPLACE PROCEDURE p_test_rn04_student_group_limit()
BEGIN
    DECLARE v_msg VARCHAR(500) DEFAULT '';
    DECLARE v_student INT;
    DECLARE v_group2 INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
        ROLLBACK;
        IF v_msg LIKE 'RN04%' THEN
            CALL p_log_test('RN04', 'RN04: Un alumno no puede pertenecer a más grupos de los permitidos', 'PASS');
        ELSE
            CALL p_log_test('RN04', CONCAT('ERROR inesperado: ', LEFT(v_msg, 300)), 'FAIL');
        END IF;
    END;

    START TRANSACTION;
    -- Alumno matriculado en la asignatura y en un grupo, y otro grupo de la
    -- misma asignatura y actividad
    SELECT ge.student_id, g2.group_id INTO v_student, v_group2
    FROM group_enrollments ge
    JOIN groups g1 ON g1.group_id = ge.group_id
    JOIN subject_enrollments se ON se.student_id = ge.student_id AND se.subject_id = g1.subject_id
    JOIN groups g2 ON g2.subject_id = g1.subject_id
                  AND g2.activity = g1.activity
                  AND g2.group_id <> g1.group_id
    LIMIT 1;

    INSERT INTO group_enrollments (student_id, group_id) VALUES (v_student, v_group2);

    ROLLBACK;
    CALL p_log_test('RN04', 'ERROR: Se permitió un alumno en más grupos de los permitidos', 'FAIL');
END //

-- RN05: una nota no puede modificarse en más de 4 puntos
CREATE OR REPLACE PROCEDURE p_test_rn05_grade_delta()
BEGIN
    DECLARE v_msg VARCHAR(500) DEFAULT '';
    DECLARE v_id INT;
    DECLARE v_value DECIMAL(4,2);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
        ROLLBACK;
        IF v_msg LIKE 'RN05%' THEN
            CALL p_log_test('RN05', 'RN05: No se puede modificar la nota en más de 4 puntos', 'PASS');
        ELSE
            CALL p_log_test('RN05', CONCAT('ERROR inesperado: ', LEFT(v_msg, 300)), 'FAIL');
        END IF;
    END;

    START TRANSACTION;
    SELECT grade_id, grade_value INTO v_id, v_value FROM grades LIMIT 1;

    -- Salto de más de 4 puntos hacia el extremo más lejano
    UPDATE grades SET grade_value = IF(v_value >= 5, 0, 10) WHERE grade_id = v_id;

    ROLLBACK;
    CALL p_log_test('RN05', 'ERROR: Se permitió modificar la nota en más de 4 puntos', 'FAIL');
END //

-- RN06: por asignatura y año, un grupo de teoría y dos de laboratorio
CREATE OR REPLACE PROCEDURE p_test_rn06_extra_group()
BEGIN
    DECLARE v_msg VARCHAR(500) DEFAULT '';
    DECLARE v_subject INT;
    DECLARE v_year YEAR;
    DECLARE v_new INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
        ROLLBACK;
        IF v_msg LIKE 'RN06%' THEN
            CALL p_log_test('RN06', 'RN06: No se permite crear un segundo grupo de teoría para la asignatura', 'PASS');
        ELSE
            CALL p_log_test('RN06', CONCAT('ERROR inesperado: ', LEFT(v_msg, 300)), 'FAIL');
        END IF;
    END;

    START TRANSACTION;
    -- Una asignatura que ya tiene grupo de teoría ese año
    SELECT subject_id, academic_year INTO v_subject, v_year
    FROM groups WHERE activity = 'Teoría' LIMIT 1;
    SELECT MAX(group_id) + 1 INTO v_new FROM groups;

    INSERT INTO groups (group_id, subject_id, group_name, activity, academic_year)
        VALUES (v_new, v_subject, 'T9', 'Teoría', v_year);

    ROLLBACK;
    CALL p_log_test('RN06', 'ERROR: Se creó un segundo grupo de teoría para la misma asignatura', 'FAIL');
END //

-- RN07: un alumno solo puede estar en grupos de asignaturas en las que está matriculado
CREATE OR REPLACE PROCEDURE p_test_rn07_subject_enrollment()
BEGIN
    DECLARE v_msg VARCHAR(500) DEFAULT '';
    DECLARE v_group INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
        ROLLBACK;
        IF v_msg LIKE 'RN07%' THEN
            CALL p_log_test('RN07', 'RN07: No se puede añadir a un grupo sin matrícula en la asignatura', 'PASS');
        ELSE
            CALL p_log_test('RN07', CONCAT('ERROR inesperado: ', LEFT(v_msg, 300)), 'FAIL');
        END IF;
    END;

    START TRANSACTION;
    SELECT MIN(group_id) INTO v_group FROM groups;

    -- Alumno nuevo, sin ninguna matrícula en asignaturas
    INSERT INTO people (person_id, dni, first_name, last_name, age, email)
        VALUES (9002, '90000002B', 'Test', 'Alumno', 20, 'test.alumno@alum.us.es');
    INSERT INTO students (student_id, access_method) VALUES (9002, 'Selectividad');
    INSERT INTO group_enrollments (student_id, group_id) VALUES (9002, v_group);

    ROLLBACK;
    CALL p_log_test('RN07', 'ERROR: Se permitió unir a un grupo sin matrícula en la asignatura', 'FAIL');
END //

-- RN08: Selectividad solo con 16 años o más
CREATE OR REPLACE PROCEDURE p_test_rn08_min_age()
BEGIN
    DECLARE v_msg VARCHAR(500) DEFAULT '';
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
        ROLLBACK;
        IF v_msg LIKE 'RN08%' THEN
            CALL p_log_test('RN08', 'RN08: No se permite Selectividad con menos de 16 años', 'PASS');
        ELSE
            CALL p_log_test('RN08', CONCAT('ERROR inesperado: ', LEFT(v_msg, 300)), 'FAIL');
        END IF;
    END;

    START TRANSACTION;
    INSERT INTO people (person_id, dni, first_name, last_name, age, email)
        VALUES (9004, '90000004D', 'Test', 'Menor', 15, 'test.menor@alum.us.es');
    INSERT INTO students (student_id, access_method) VALUES (9004, 'Selectividad');

    ROLLBACK;
    CALL p_log_test('RN08', 'ERROR: Se permitió Selectividad para un menor', 'FAIL');
END //

-- RN17: una sola nota por asignatura, convocatoria y año
CREATE OR REPLACE PROCEDURE p_test_rn17_duplicate_grade()
BEGIN
    DECLARE v_msg VARCHAR(500) DEFAULT '';
    DECLARE v_student INT;
    DECLARE v_group INT;
    DECLARE v_call VARCHAR(30);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
        ROLLBACK;
        IF v_msg LIKE 'RN17%' THEN
            CALL p_log_test('RN17', 'RN17: No se permiten notas duplicadas por asignatura/convocatoria', 'PASS');
        ELSE
            CALL p_log_test('RN17', CONCAT('ERROR inesperado: ', LEFT(v_msg, 300)), 'FAIL');
        END IF;
    END;

    START TRANSACTION;
    -- Una nota ya existente: se intenta insertar otra igual
    SELECT student_id, group_id, exam_call INTO v_student, v_group, v_call
    FROM grades LIMIT 1;

    INSERT INTO grades (student_id, group_id, grade_value, exam_call, with_honors)
        VALUES (v_student, v_group, 6.0, v_call, 0);

    ROLLBACK;
    CALL p_log_test('RN17', 'ERROR: Se permitió duplicar nota en la misma convocatoria', 'FAIL');
END //

-- ORQUESTADOR
CREATE OR REPLACE PROCEDURE p_run_tests()
BEGIN
    DELETE FROM test_results;

    CALL p_test_rn02_grade_in_group();
    CALL p_test_rn03_professors_per_group();
    CALL p_test_rn04_student_group_limit();
    CALL p_test_rn05_grade_delta();
    CALL p_test_rn06_extra_group();
    CALL p_test_rn07_subject_enrollment();
    CALL p_test_rn08_min_age();
    CALL p_test_rn17_duplicate_grade();

    SELECT * FROM test_results ORDER BY test_id;
    SELECT test_status, COUNT(*) AS total FROM test_results GROUP BY test_status;
END //

DELIMITER ;

CALL p_run_tests();