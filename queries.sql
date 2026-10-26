
-- Autor: Ángela Chacón Pialres
-- Descripción: Consultas SQL de ejemplo para GradesDB
USE grades_db;

-- Consulta 1: todas las asignaturas
SELECT * 
FROM subjects;

-- Consulta 2: asignatura con acrónimo específico
SELECT * 
FROM subjects s
WHERE s.acronym = 'IISSI-1';

-- Consulta 3: columnas especificas
SELECT s.subject_name, s.acronym 
FROM subjects s;

-- Consulta 4: Filtrado por tipo
SELECT s.subject_name, s.acronym, s.subject_type
FROM subjects s
WHERE s.subject_type = 'Formación Básica';

-- Consulta 5: Estudiantes con Join
SELECT p.first_name, p.last_name, st.access_method
FROM students st
JOIN people p ON st.student_id = p.person_id
WHERE st.access_method = 'Selectividad';

-- Consulta 6: Profesores por categoria
SELECT p.first_name, p.last_name, pr.category
FROM professors pr
JOIN people p ON pr.professor_id = p.person_id
WHERE pr.category = 'Catedrático';

-- Vistas
-- Vistas v_professors
CREATE OR REPLACE VIEW v_professors AS
SELECT 
    pr.professor_id,
    pr.category,
    p.person_id,
    p.dni,
    p.first_name,
    p.last_name,
    p.age,
    p.email
FROM professors pr
JOIN people p ON pr.professor_id = p.person_id;

-- Vistas v_students
CREATE OR REPLACE VIEW v_students AS
SELECT 
    st.student_id,
    st.access_method,
    p.person_id,
    p.dni,
    p.first_name,
    p.last_name,
    p.age,
    p.email
FROM students st
JOIN people p ON st.student_id = p.person_id;

-- Funciones agregadas
-- Consulta 7: media de notas
SELECT AVG(g.grade_value) AS average_grade
FROM grades g
WHERE g.group_id = 1;

-- Consulta 8: suma de creditos
SELECT SUM(s.credits) AS total_credits
FROM subjects s 
WHERE s.degree_id = 3;

-- Consulta 9: contar registros
SELECT COUNT(*) AS total_students
FROM students;

-- Consulta 10: Contar con agrupación básica
SELECT activity, COUNT(*) AS total_groups
FROM groups
GROUP BY activity;

-- Consulta 11: valor máximo
SELECT MAX(g.grade_value) AS max_grade
FROM grades g;

-- Consulta 12: valor mínimo
SELECT MIN(g.grade_value) AS min_grade
FROM grades g;

-- Condiciones multiples
-- Consulta 13: OR lógico
SELECT g.grade_id, g.grade_value, g.exam_call
FROM grades g
WHERE g.grade_value < 5 OR g.grade_value > 9;
 
-- Consulta 14: Between
SELECT g.grade_id, g.grade_value, g.exam_call
FROM grades g
WHERE g.grade_value BETWEEN 5 AND 7;

-- Consulta 15: in
SELECT s.subject_name, s.credits
FROM subjects s
WHERE s.credits IN (6, 12);

-- Consulta 16: Rango de edad
SELECT p.first_name, p.last_name, p.age
FROM people p
WHERE p.age BETWEEN 20 AND 30;

-- DISTINCT: eliminacion de duplicados
-- Consulta 17: nombres únicos de grupos
SELECT DISTINCT g.group_name 
FROM groups g;

-- Consulta 18: tipos de asignatura
SELECT DISTINCT s.subject_type
FROM subjects s;

-- Consulta 19: años academicos
SELECT DISTINCT g.academic_year
FROM groups g
ORDER BY g.academic_year DESC;
