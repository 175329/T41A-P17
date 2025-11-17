-- 1. Crear tabla de productos con especificaciones en JSONB
CREATE TABLE productos_jsonb (
  id SERIAL PRIMARY KEY,
  nombre TEXT NOT NULL,
  especificaciones JSONB,
  precio DECIMAL(10,2),
  categoria TEXT
);

-- 2. Insertar al menos 5 productos con diferentes atributos
INSERT INTO productos_jsonb (nombre, precio, categoria, especificaciones)
VALUES 
  ('Laptop Gaming', 1200.00, 'Tecnología', '{"marca": "ASUS", "color": "negro", "ram": "16GB", "almacenamiento": "1TB SSD", "pantalla": "15.6"}'),
  ('Smartphone', 800.00, 'Tecnología', '{"marca": "Samsung", "color": "azul", "almacenamiento": "256GB", "bateria": "4000mAh", "camara": "48MP"}'),
  ('Mesa Oficina', 250.00, 'Muebles', '{"material": "madera", "color": "café", "dimensiones": "120x60x75cm", "peso": "15kg"}'),
  ('Silla Ergonómica', 350.00, 'Muebles', '{"material": "malla", "color": "negro", "ajustable": true, "ruedas": 5}'),
  ('Monitor 4K', 450.00, 'Tecnología', '{"marca": "LG", "pulgadas": 27, "resolucion": "3840x2160", "hz": 144}');

-- 3. Consultar productos por color, tamaño o categoría
SELECT nombre, especificaciones->>'color' as color, precio
FROM productos_jsonb
WHERE especificaciones->>'color' = 'negro';

SELECT nombre, categoria, precio, especificaciones->>'marca' as marca
FROM productos_jsonb
WHERE categoria = 'Tecnología';

SELECT nombre, especificaciones->>'pulgadas' as pulgadas, especificaciones->>'marca' as marca
FROM productos_jsonb
WHERE (especificaciones->>'pulgadas')::int > 15;

-- 4. Crear índices GIN y medir rendimiento
CREATE INDEX idx_especificaciones_gin ON productos_jsonb USING GIN (especificaciones);
CREATE INDEX idx_categoria ON productos_jsonb (categoria);

EXPLAIN ANALYZE 
SELECT nombre, especificaciones
FROM productos_jsonb
WHERE especificaciones @> '{"color": "negro"}';

-- 5. Implementar pruebas unitarias para JSONB
DO $$
BEGIN
  RAISE NOTICE '=== PRUEBAS JSONB ===';
  
  IF EXISTS (SELECT 1 FROM productos_jsonb WHERE nombre = 'Laptop Gaming') THEN
    RAISE NOTICE 'Producto Laptop Gaming insertado correctamente';
  ELSE
    RAISE EXCEPTION 'Producto Laptop Gaming no encontrado';
  END IF;

  IF EXISTS (
    SELECT 1 FROM productos_jsonb 
    WHERE nombre = 'Smartphone' AND especificaciones->>'marca' = 'Samsung'
  ) THEN
    RAISE NOTICE 'Especificaciones de smartphone correctas';
  ELSE
    RAISE EXCEPTION 'Especificaciones de smartphone incorrectas';
  END IF;

  IF (SELECT COUNT(*) FROM productos_jsonb WHERE categoria = 'Tecnología') = 3 THEN
    RAISE NOTICE '3 productos en categoría Tecnología';
  ELSE
    RAISE EXCEPTION '❌ Conteo incorrecto en categoría Tecnología';
  END IF;

  -- Verificar índice GIN
  IF EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_especificaciones_gin') THEN
    RAISE NOTICE 'Índice GIN creado correctamente';
  ELSE
    RAISE EXCEPTION 'Índice GIN no creado';
  END IF;

  RAISE NOTICE '=== TODAS LAS PRUEBAS JSONB PASARON ===';
END;
$$;
