-- 1. Activar la extensión HSTORE
CREATE EXTENSION IF NOT EXISTS hstore;

-- 2. Crear tabla de vehículos con columna HSTORE
CREATE TABLE vehiculos_hstore (
  id_vehiculo SERIAL PRIMARY KEY,
  modelo TEXT NOT NULL,
  precio DECIMAL(10,2),
  atributos HSTORE -- Almacena detalles como marca, motor, transmisión, año y extras.
);

-- 3. Insertar al menos 5 vehículos con múltiples pares clave-valor
INSERT INTO vehiculos_hstore (modelo, precio, atributos)
VALUES 
  ('Sedán Familiar', 25000.00, 'marca => Toyota, motor => 2.0L, transmision => automatico, ano => 2022, extras => gps'),
  ('Deportivo Coupé', 75000.00, 'marca => Porsche, motor => 4.0L, transmision => manual, ano => 2023, color => rojo, extras => sunroof'),
  ('Pickup Trabajo', 45000.00, 'marca => Ford, motor => diesel, transmision => automatico, ano => 2021, traccion => 4x4'),
  ('SUV Eléctrico', 60000.00, 'marca => Tesla, motor => electrico, transmision => automatico, ano => 2024, autopilot => true'),
  ('Compacto Urbano', 18000.00, 'marca => Toyota, motor => 1.5L, transmision => manual, ano => 2023, color => gris');


-- 1. Indexar la columna HSTORE con GIN
CREATE INDEX idx_vehiculos_atributos_gin ON vehiculos_hstore USING GIN (atributos);

-- Verificar la creación del índice
SELECT 
  indexname, 
  indexdef 
FROM pg_indexes 
WHERE tablename = 'vehiculos_hstore'
ORDER BY indexname;

-- Medir rendimiento de una consulta utilizando el índice GIN
EXPLAIN ANALYZE 
SELECT modelo, precio 
FROM vehiculos_hstore 
WHERE atributos ? 'motor';

-- 2. Usar funciones agregadas con HSTORE
-- Agrupar por 'marca' y obtener estadísticas de precios
SELECT 
  atributos -> 'marca' as marca,
  COUNT(*) as total_vehiculos,
  AVG(precio) as precio_promedio,
  MIN(precio) as precio_minimo,
  MAX(precio) as precio_maximo
FROM vehiculos_hstore
WHERE atributos ? 'marca'
GROUP BY atributos -> 'marca'
ORDER BY total_vehiculos DESC;

-- Agrupar por 'transmision' y 'motor'
SELECT 
  atributos -> 'transmision' as transmision,
  atributos -> 'motor' as tipo_motor,
  COUNT(*) as cantidad,
  ROUND(AVG(precio), 2) as precio_promedio
FROM vehiculos_hstore
WHERE atributos ? 'transmision' AND atributos ? 'motor'
GROUP BY atributos -> 'transmision', atributos -> 'motor'
ORDER BY cantidad DESC, tipo_motor;

-- 3. Convertir HSTORE a JSON y viceversa
-- Convertir los atributos HSTORE a JSONB formateado
SELECT 
  modelo,
  hstore_to_json(atributos) as atributos_json,
  jsonb_pretty(hstore_to_json(atributos)::jsonb) as atributos_json_formateado
FROM vehiculos_hstore
LIMIT 3;

-- Crear una tabla temporal convirtiendo HSTORE a JSONB
CREATE TEMP TABLE vehiculos_json_temp AS
SELECT 
  modelo,
  precio,
  hstore_to_json(atributos)::jsonb as especificaciones_jsonb
FROM vehiculos_hstore;

SELECT * FROM vehiculos_json_temp;
DROP TABLE vehiculos_json_temp;

-- 4. Validar existencia de múltiples claves
-- Vehículos que tienen ABS Y GPS (operador ?&)
SELECT modelo, precio, atributos -> 'extras' as extras, atributos -> 'ano' as ano
FROM vehiculos_hstore
WHERE atributos ?& ARRAY['marca', 'extras']; -- Solo se filtra por los que tienen ambas claves

-- Vehículos que tienen 'extras' O 'traccion' (operador ?|)
SELECT modelo, precio, atributos -> 'extras' as extras, atributos -> 'traccion' as traccion
FROM vehiculos_hstore
WHERE atributos ?| ARRAY['extras', 'traccion'];

-- 5. Crear una función que reciba el nombre del vehículo y devuelva un resumen
CREATE OR REPLACE FUNCTION resumen_vehiculo(nombre_modelo TEXT)
RETURNS TEXT AS $$
DECLARE
  vehiculo_record vehiculos_hstore%ROWTYPE;
  resumen TEXT;
  marca TEXT;
  motor TEXT;
  precio_base DECIMAL(10,2);
  ano_modelo TEXT;
BEGIN
  SELECT * INTO vehiculo_record 
  FROM vehiculos_hstore 
  WHERE modelo = nombre_modelo;
  
  IF NOT FOUND THEN
    RETURN 'Vehículo no encontrado: ' || nombre_modelo;
  END IF;
  
  marca := vehiculo_record.atributos -> 'marca';
  motor := vehiculo_record.atributos -> 'motor';
  ano_modelo := vehiculo_record.atributos -> 'ano';
  precio_base := vehiculo_record.precio;
  
  resumen := 'Modelo: ' || vehiculo_record.modelo || E'\n';
  resumen := resumen || 'Precio: $' || precio_base || E'\n';
  
  IF marca IS NOT NULL THEN
    resumen := resumen || '🏭 Marca: ' || marca || E'\n';
  END IF;
  
  IF ano_modelo IS NOT NULL THEN
    resumen := resumen || '📅 Año: ' || ano_modelo || E'\n';
  END IF;
  
  IF motor IS NOT NULL THEN
    resumen := resumen || '⚙️ Motor: ' || motor || E'\n';
  END IF;
  
  IF vehiculo_record.atributos ? 'autopilot' AND vehiculo_record.atributos -> 'autopilot' = 'true' THEN
    resumen := resumen || 'Extra: Piloto Automático' || E'\n';
  END IF;
  
  resumen := resumen || 'Total atributos únicos: ' || (SELECT COUNT(*) FROM skeys(vehiculo_record.atributos));
  
  RETURN resumen;
END;
$$ LANGUAGE plpgsql;

-- Ejecutar la función para probar
SELECT resumen_vehiculo('Sedán Familiar') as resumen;
SELECT resumen_vehiculo('SUV Eléctrico') as resumen;

-- 6. Implementar pruebas unitarias para HSTORE (PL/pgSQL)
DO $$
DECLARE
  total_por_marca INT;
  total_con_extras_y_marca INT;
BEGIN
  RAISE NOTICE '=== PRUEBAS HSTORE AVANZADOS EN VEHÍCULOS ===';
  
  -- Prueba 1: Índice GIN
  IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_vehiculos_atributos_gin') THEN
    RAISE EXCEPTION '❌ Índice GIN para HSTORE no creado';
  ELSE
    RAISE NOTICE '✅ Índice GIN para HSTORE creado';
  END IF;

  -- Prueba 2: Funciones agregadas (Conteo por marca)
  SELECT COUNT(DISTINCT atributos -> 'marca') INTO total_por_marca 
  FROM vehiculos_hstore 
  WHERE atributos ? 'marca';
  
  IF total_por_marca < 3 THEN
    RAISE EXCEPTION '❌ Funciones agregadas no funcionan correctamente (menos de 3 marcas distintas)';
  ELSE
    RAISE NOTICE '✅ Funciones agregadas funcionando: % marcas distintas', total_por_marca;
  END IF;

  -- Prueba 3: Conversión HSTORE a JSON
  IF (SELECT hstore_to_json(atributos) FROM vehiculos_hstore LIMIT 1) IS NULL THEN
    RAISE EXCEPTION '❌ Conversión HSTORE a JSON falló';
  ELSE
    RAISE NOTICE '✅ Conversión HSTORE a JSON funcionando';
  END IF;

  -- Prueba 4: Operador ?& (existencia de ambas claves)
  SELECT COUNT(*) INTO total_con_extras_y_marca
  FROM vehiculos_hstore 
  WHERE atributos ?& ARRAY['marca', 'extras'];

  IF total_con_extras_y_marca <> 2 THEN
    RAISE EXCEPTION '❌ Operador ?& falló. Esperado 2, obtenido %', total_con_extras_y_marca;
  ELSE
    RAISE NOTICE '✅ Operadores múltiples (?&) funcionando';
  END IF;

  -- Prueba 5: Función resumen
  IF (SELECT resumen_vehiculo('Deportivo Coupé')) IS NULL THEN
    RAISE EXCEPTION '❌ Función resumen_vehiculo no funciona';
  ELSE
    RAISE NOTICE '✅ Función resumen_vehiculo funcionando';
  END IF;

  RAISE NOTICE '=== TODAS LAS PRUEBAS HSTORE AVANZADOS PASARON ===';
END;
$$;
