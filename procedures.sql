USE GradesDB;

DELIMITER //

CREATE OR REPLACE PROCEDURE p_delete_student_grades(
    IN p_dni VARCHAR(9)
)
BEGIN
    DECLARE v_student_id INT;

    -- Obtener el ID del estudiante a partir del DNI
    SELECT s.student_id INTO v_student_id
    FROM students s
    JOIN people p ON s.person_id = p.person_id
    WHERE p.dni = p_dni;

    -- Borrar las notas del estudiante
    DELETE FROM grades WHERE student_id = v_student_id;
END //

DELIMITER ;