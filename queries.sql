
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
