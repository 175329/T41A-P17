-- 1. Activar la extensión HSTORE
CREATE EXTENSION IF NOT EXISTS hstore;

-- 2. Crear tabla con columna HSTORE
CREATE TABLE productos_hstore (
  id SERIAL PRIMARY KEY,
  nombre TEXT NOT NULL,
  precio DECIMAL(10,2),
  atributos HSTORE
);

-- 3. Insertar registros con múltiples pares clave-valor
INSERT INTO productos_hstore (nombre, precio, atributos)
VALUES 
  ('Televisor 55"', 899.99, 'marca => Sony, color => negro, resolucion => 4K, smart => true'),
  ('Refrigerador', 1200.00, 'marca => LG, color => acero, capacidad => 500L, eficiencia => A++'),
  ('Lavadora', 650.50, 'marca => Samsung, color => blanco, capacidad => 8kg, secadora => false'),
  ('Audífonos', 299.99, 'marca => Bose, color => plateado, inalambricos => true, cancelacion_ruido => true'),
  ('Tablet', 450.00, 'marca => Apple, color => space-gray, almacenamiento => 128GB, pantalla => 10.9"');

-- 4. Consultar por una clave específica
SELECT nombre, precio, atributos -> 'color' as color
FROM productos_hstore
WHERE atributos -> 'color' = 'negro';

-- 5. Actualizar un valor dentro del HSTORE
UPDATE productos_hstore
SET atributos = atributos || 'capacidad => 10kg'::hstore
WHERE nombre = 'Lavadora';

UPDATE productos_hstore
SET atributos = atributos || 'precio_oferta => 799.99'::hstore
WHERE nombre = 'Televisor 55"';

-- 6. Eliminar una clave de un registro
UPDATE productos_hstore
SET atributos = delete(atributos, 'precio_oferta')
WHERE nombre = 'Televisor 55"';

SELECT nombre, atributos FROM productos_hstore;

DO $$
BEGIN
  RAISE NOTICE '=== PRUEBAS HSTORE BÁSICOS ===';
  
  IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'hstore') THEN
    RAISE EXCEPTION 'Extensión HSTORE no activada';
  ELSE
    RAISE NOTICE 'Extensión HSTORE activada';
  END IF;

  IF (SELECT COUNT(*) FROM productos_hstore) < 5 THEN
    RAISE EXCEPTION 'Debe haber al menos 5 productos HSTORE';
  ELSE
    RAISE NOTICE 'Datos HSTORE insertados correctamente';
  END IF;

  IF (SELECT COUNT(*) FROM productos_hstore WHERE atributos -> 'color' = 'negro') < 1 THEN
    RAISE EXCEPTION 'Consulta por color negro no funciona';
  ELSE
    RAISE NOTICE 'Consultas por clave funcionando';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM productos_hstore WHERE nombre = 'Lavadora' AND atributos -> 'capacidad' = '10kg') THEN
    RAISE EXCEPTION 'Actualización de capacidad falló';
  ELSE
    RAISE NOTICE 'Actualizaciones HSTORE funcionando';
  END IF;

  RAISE NOTICE '=== TODAS LAS PRUEBAS HSTORE BÁSICOS PASARON ===';
END;
$$;
