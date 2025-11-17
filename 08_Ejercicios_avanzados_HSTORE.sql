-- 1. Indexar la columna HSTORE con GIN
CREATE INDEX idx_atributos_gin ON productos_hstore USING GIN (atributos);

SELECT 
  indexname, 
  indexdef 
FROM pg_indexes 
WHERE tablename = 'productos_hstore'
ORDER BY indexname;

EXPLAIN ANALYZE 
SELECT nombre, precio 
FROM productos_hstore 
WHERE atributos ? 'marca';

-- 2. Usar funciones agregadas con HSTORE
SELECT 
  atributos -> 'marca' as marca,
  COUNT(*) as total_productos,
  AVG(precio) as precio_promedio,
  MIN(precio) as precio_minimo,
  MAX(precio) as precio_maximo
FROM productos_hstore
WHERE atributos ? 'marca'
GROUP BY atributos -> 'marca'
ORDER BY total_productos DESC;

SELECT 
  atributos -> 'color' as color,
  atributos -> 'marca' as marca,
  COUNT(*) as cantidad,
  ROUND(AVG(precio), 2) as precio_promedio
FROM productos_hstore
WHERE atributos ? 'color' AND atributos ? 'marca'
GROUP BY atributos -> 'color', atributos -> 'marca'
ORDER BY color, cantidad DESC;

-- 3. Convertir HSTORE a JSON y viceversa
SELECT 
  nombre,
  hstore_to_json(atributos) as atributos_json,
  jsonb_pretty(hstore_to_json(atributos)::jsonb) as atributos_json_formateado
FROM productos_hstore
LIMIT 3;

CREATE TEMP TABLE productos_json_temp AS
SELECT 
  nombre,
  precio,
  hstore_to_json(atributos)::jsonb as especificaciones
FROM productos_hstore;

SELECT * FROM productos_json_temp;
DROP TABLE productos_json_temp;

-- 4. Validar existencia de múltiples claves
SELECT nombre, precio, atributos -> 'marca' as marca, atributos -> 'color' as color
FROM productos_hstore
WHERE atributos ?& ARRAY['marca', 'color'];

SELECT nombre, precio, atributos -> 'wifi' as wifi, atributos -> 'inalambricos' as inalambricos
FROM productos_hstore
WHERE atributos ?& ARRAY['wifi', 'inalambricos'];

SELECT nombre, precio, atributos
FROM productos_hstore
WHERE atributos ?| ARRAY['wifi', 'smart'];

-- 5. Crear una función que reciba un HSTORE y devuelva un resumen
CREATE OR REPLACE FUNCTION resumen_producto(producto_nombre TEXT)
RETURNS TEXT AS $$
DECLARE
  producto_record productos_hstore%ROWTYPE;
  resumen TEXT;
  marca TEXT;
  color TEXT;
  precio_base DECIMAL(10,2);
BEGIN
  SELECT * INTO producto_record 
  FROM productos_hstore 
  WHERE nombre = producto_nombre;
  
  IF NOT FOUND THEN
    RETURN 'Producto no encontrado: ' || producto_nombre;
  END IF;
  
  marca := producto_record.atributos -> 'marca';
  color := producto_record.atributos -> 'color';
  precio_base := producto_record.precio;
  
  resumen := 'Producto: ' || producto_record.nombre || E'\n';
  resumen := resumen || 'Precio: $' || precio_base || E'\n';
  
  IF marca IS NOT NULL THEN
    resumen := resumen || '🔧 Marca: ' || marca || E'\n';
  END IF;
  
  IF color IS NOT NULL THEN
    resumen := resumen || 'Color: ' || color || E'\n';
  END IF;
  
  IF producto_record.atributos ? 'wifi' AND producto_record.atributos -> 'wifi' = 'true' THEN
    resumen := resumen || 'WiFi: Sí' || E'\n';
  END IF;
  
  IF producto_record.atributos ? 'inalambricos' AND producto_record.atributos -> 'inalambricos' = 'true' THEN
    resumen := resumen || 'Inalámbrico: Sí' || E'\n';
  END IF;
  
  resumen := resumen || 'Total atributos: ' || (SELECT COUNT(*) FROM skeys(producto_record.atributos));
  
  RETURN resumen;
END;
$$ LANGUAGE plpgsql;

SELECT resumen_producto('Televisor 55"') as resumen;
SELECT resumen_producto('Audífonos') as resumen;

DO $$
BEGIN
  RAISE NOTICE '=== PRUEBAS HSTORE AVANZADOS ===';
  
  IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_atributos_gin') THEN
    RAISE EXCEPTION 'Índice GIN para HSTORE no creado';
  ELSE
    RAISE NOTICE 'Índice GIN para HSTORE creado';
  END IF;

  IF (SELECT COUNT(DISTINCT atributos -> 'marca') FROM productos_hstore WHERE atributos ? 'marca') < 3 THEN
    RAISE EXCEPTION 'Funciones agregadas no funcionan correctamente';
  ELSE
    RAISE NOTICE 'Funciones agregadas funcionando';
  END IF;

  IF (SELECT hstore_to_json(atributos) FROM productos_hstore LIMIT 1) IS NULL THEN
    RAISE EXCEPTION 'Conversión HSTORE a JSON falló';
  ELSE
    RAISE NOTICE 'Conversión HSTORE a JSON funcionando';
  END IF;

  IF (SELECT COUNT(*) FROM productos_hstore WHERE atributos ?& ARRAY['marca', 'color']) < 3 THEN
    RAISE EXCEPTION 'Operador ?& no funciona correctamente';
  ELSE
    RAISE NOTICE 'Operadores múltiples funcionando';
  END IF;

  IF (SELECT resumen_producto('Televisor 55"')) IS NULL THEN
    RAISE EXCEPTION 'Función resumen_producto no funciona';
  ELSE
    RAISE NOTICE 'Función resumen_producto funcionando';
  END IF;

  RAISE NOTICE '=== TODAS LAS PRUEBAS HSTORE AVANZADOS PASARON ===';
END;
$$;
