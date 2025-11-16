-- 1. Activar la extensión HSTORE
CREATE EXTENSION IF NOT EXISTS hstore;

-- 2. Crear tabla de cursos con columna HSTORE
CREATE TABLE cursos_hstore (
  id_curso SERIAL PRIMARY KEY,
  nombre_curso TEXT NOT NULL,
  costo DECIMAL(10,2),
  metadata HSTORE -- Almacena detalles como dificultad, duración, tecnología, certificación.
);

-- 3. Insertar al menos 5 cursos con múltiples pares clave-valor
INSERT INTO cursos_hstore (nombre_curso, costo, metadata)
VALUES 
  ('Introducción a Python', 49.99, 'dificultad => facil, duracion => 10h, tecnologia => Python, certificacion => si'),
  ('Desarrollo Frontend Avanzado', 149.99, 'dificultad => avanzado, duracion => 40h, tecnologia => React, prerequisitos => JSX/Hooks, proyecto_final => si'),
  ('SQL para Data Science', 75.00, 'dificultad => intermedio, duracion => 20h, tecnologia => SQL, certificacion => si'),
  ('Habilidades Blandas', 29.99, 'dificultad => facil, duracion => 5h, formato => video'),
  ('DevOps con AWS', 199.99, 'dificultad => avanzado, duracion => 60h, tecnologia => AWS, prerequisitos => Linux/Networking');

-- 4. Filtrar registros que contienen una clave
-- Cursos que ofrecen una 'certificacion'
SELECT nombre_curso, costo, metadata -> 'certificacion' as certificacion
FROM cursos_hstore
WHERE metadata ? 'certificacion';

-- Cursos que tienen 'prerequisitos' definidos
SELECT nombre_curso, costo, metadata -> 'prerequisitos' as prerequisitos
FROM cursos_hstore
WHERE metadata ? 'prerequisitos';

-- 5. Combinar HSTORE con otras columnas
-- Cursos de 'Python' que cuestan menos de 100
SELECT nombre_curso, costo, metadata -> 'dificultad' as dificultad, metadata -> 'duracion' as duracion
FROM cursos_hstore
WHERE metadata -> 'tecnologia' = 'Python' AND costo < 100.00;

-- Cursos de dificultad 'avanzado' con duración mayor a 50 horas
SELECT nombre_curso, costo, metadata -> 'tecnologia' as tecnologia, metadata -> 'duracion' as duracion
FROM cursos_hstore
WHERE metadata -> 'dificultad' = 'avanzado' AND (metadata -> 'duracion')::TEXT ~ '^\d+h$' AND (REPLACE(metadata -> 'duracion', 'h', '')::int) > 50;

-- 6. Extraer todas las claves y valores
-- Listar el nombre del curso junto con todas sus claves y valores de metadata
SELECT 
  nombre_curso,
  skeys(metadata) AS claves, 
  svals(metadata) AS valores
FROM cursos_hstore
ORDER BY nombre_curso;

-- Listar todas las claves de metadata únicas en la tabla
SELECT DISTINCT skeys(metadata) as clave
FROM cursos_hstore
ORDER BY clave;

-- 7. Contar cuántos cursos tienen un atributo específico y agrupar
-- Contar cuántos cursos tienen la clave 'proyecto_final'
SELECT COUNT(*) as cursos_con_proyecto_final
FROM cursos_hstore
WHERE metadata ? 'proyecto_final';

-- Contar cursos agrupados por 'dificultad'
SELECT 
  metadata -> 'dificultad' as dificultad,
  COUNT(*) as cantidad
FROM cursos_hstore
WHERE metadata ? 'dificultad' -- Aseguramos que tengan la clave antes de agrupar
GROUP BY metadata -> 'dificultad'
ORDER BY cantidad DESC;

-- 8. Implementar pruebas unitarias para HSTORE (PL/pgSQL)
DO $$
DECLARE
  total_con_certificacion INT;
  total_facil INT;
BEGIN
  RAISE NOTICE '=== PRUEBAS HSTORE EN GESTIÓN DE CURSOS ===';
  
  -- Prueba 1: Verificar el operador ? (certificación)
  SELECT COUNT(*) INTO total_con_certificacion
  FROM cursos_hstore 
  WHERE metadata ? 'certificacion';
  
  IF total_con_certificacion < 2 THEN
    RAISE EXCEPTION '❌ Operador ? falló. Se esperaban al menos 2 cursos con certificación.';
  ELSE
    RAISE NOTICE '✅ Operador ? funcionando: % cursos tienen certificación', total_con_certificacion;
  END IF;

  -- Prueba 2: Verificar combinación HSTORE con columna (Python y costo)
  IF (SELECT COUNT(*) FROM cursos_hstore WHERE metadata -> 'tecnologia' = 'Python' AND costo < 100.00) <> 1 THEN
    RAISE EXCEPTION '❌ Combinación HSTORE con columnas falló.';
  ELSE
    RAISE NOTICE '✅ Combinación HSTORE con columnas funcionando.';
  END IF;

  -- Prueba 3: Verificar extracción de claves (skeys)
  IF (SELECT COUNT(DISTINCT skeys(metadata)) FROM cursos_hstore) < 4 THEN
    RAISE EXCEPTION '❌ Extracción de claves falló (skeys).';
  ELSE
    RAISE NOTICE '✅ Extracción de claves/valores funcionando.';
  END IF;

  -- Prueba 4: Verificar conteo agrupado por dificultad
  SELECT COUNT(*) INTO total_facil
  FROM cursos_hstore
  WHERE metadata -> 'dificultad' = 'facil';
  
  IF total_facil <> 2 THEN
    RAISE EXCEPTION '❌ Conteo de atributos agrupados falló.';
  ELSE
    RAISE NOTICE '✅ Conteo de atributos funcionando: % cursos con dificultad "facil"', total_facil;
  END IF;

  RAISE NOTICE '=== TODAS LAS PRUEBAS HSTORE INTERMEDIOS PASARON ===';
END;
$$;
