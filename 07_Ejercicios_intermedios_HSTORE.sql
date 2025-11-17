-- 1. Filtrar registros que contienen una clave
SELECT nombre, precio, atributos -> 'marca' as marca
FROM productos_hstore
WHERE atributos ? 'marca';

SELECT nombre, precio, atributos -> 'smart' as smart
FROM productos_hstore
WHERE atributos ? 'smart';

-- 2. Combinar HSTORE con otras columnas
SELECT nombre, precio, atributos -> 'marca' as marca, atributos -> 'color' as color
FROM productos_hstore
WHERE atributos -> 'marca' = 'Sony' AND precio > 500;

SELECT nombre, precio, atributos -> 'color' as color, atributos -> 'marca' as marca
FROM productos_hstore
WHERE atributos -> 'color' = 'negro' AND precio BETWEEN 300 AND 1000;

-- 3. Extraer todas las claves y valores
SELECT 
  nombre,
  skeys(atributos) AS clave, 
  svals(atributos) AS valor
FROM productos_hstore
ORDER BY nombre, clave;

SELECT DISTINCT skeys(atributos) as clave
FROM productos_hstore
ORDER BY clave;

-- 4. Contar cuántos productos tienen un atributo específico
SELECT COUNT(*) as productos_con_color
FROM productos_hstore
WHERE atributos ? 'color';

SELECT 
  atributos -> 'color' as color,
  COUNT(*) as cantidad
FROM productos_hstore
WHERE atributos ? 'color'
GROUP BY atributos -> 'color'
ORDER BY cantidad DESC;

DO $$
DECLARE
  total_con_marca INT;
  total_con_color INT;
BEGIN
  RAISE NOTICE '=== PRUEBAS HSTORE INTERMEDIOS ===';
  
  SELECT COUNT(*) INTO total_con_marca
  FROM productos_hstore 
  WHERE atributos ? 'marca';
  
  IF total_con_marca < 5 THEN
    RAISE EXCEPTION 'Operador ? no funciona correctamente';
  ELSE
    RAISE NOTICE 'Operador ? funcionando: % productos tienen marca', total_con_marca;
  END IF;

  IF (SELECT COUNT(*) FROM productos_hstore WHERE atributos -> 'marca' = 'Sony' AND precio > 500) < 1 THEN
    RAISE EXCEPTION 'Combinación HSTORE con columnas falló';
  ELSE
    RAISE NOTICE 'Combinación HSTORE con columnas funcionando';
  END IF;

  IF (SELECT COUNT(DISTINCT skeys(atributos)) FROM productos_hstore) < 5 THEN
    RAISE EXCEPTION 'Extracción de claves falló';
  ELSE
    RAISE NOTICE 'Extracción de claves/valores funcionando';
  END IF;

  SELECT COUNT(*) INTO total_con_color
  FROM productos_hstore 
  WHERE atributos ? 'color';
  
  IF total_con_color < 4 THEN
    RAISE EXCEPTION 'Conteo de atributos falló';
  ELSE
    RAISE NOTICE 'Conteo de atributos funcionando: % productos tienen color', total_con_color;
  END IF;

  RAISE NOTICE '=== TODAS LAS PRUEBAS HSTORE INTERMEDIOS PASARON ===';
END;
$$;
