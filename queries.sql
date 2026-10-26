
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
