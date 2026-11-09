USE grades_db;

DROP TABLE IF EXISTS test_results;

CREATE TABLE test_results (
    test_id INT AUTO_INCREMENT PRIMARY KEY,
    test_name VARCHAR(100) NOT NULL,
    expected_result VARCHAR(50) NOT NULL,
    actual_result VARCHAR(50) NOT NULL,
    status VARCHAR(10) NOT NULL, -- 'PASSED' o 'FAILED'
    execution_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DELIMITER //

CREATE OR REPLACE PROCEDURE test_invalid_grade_check()
BEGIN
    -- Manejador de excepción para capturar el fallo esperado (SQLEXCEPTION)
    DECLARE sys_error INT DEFAULT 0;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET sys_error = 1;

    -- Intento de inserción de nota inválida (ej. nota mayor que 10)
    INSERT INTO grades (student_id, subject_id, group_id, grade_value, call_number) 
    VALUES (1, 1, 1, 15.0, 1);

    -- Evaluar resultado
    IF sys_error = 1 THEN
        INSERT INTO test_results (test_name, expected_result, actual_result, status)
        VALUES ('test_invalid_grade_check', 'ERROR', 'ERROR', 'PASSED');
    ELSE
        INSERT INTO test_results (test_name, expected_result, actual_result, status)
        VALUES ('test_invalid_grade_check', 'ERROR', 'SUCCESS', 'FAILED');
    END IF;
END //

DELIMITER ;

DELIMITER //

CREATE OR REPLACE PROCEDURE p_run_all_tests()
BEGIN
    DELETE FROM test_results;
    
    -- Llamada a las pruebas individuales
    CALL test_invalid_grade_check();
    
    -- Mostrar reporte de pruebas ejecutadas
    SELECT * FROM test_results;
END //

DELIMITER ;