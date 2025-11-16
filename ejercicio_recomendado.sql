CREATE TABLE catalogo_ropa (
  sku SERIAL PRIMARY KEY,
  nombre_articulo TEXT NOT NULL,
  detalles JSONB,
  precio_venta DECIMAL(10,2),
  talla_stock TEXT 
);

-- 2. Insertar al menos 5 artículos con diferentes atributos
INSERT INTO catalogo_ropa (nombre_articulo, precio_venta, talla_stock, detalles)
VALUES 
  ('Jeans Slim Fit', 79.99, 'M', '{"material": "Denim", "corte": "Slim", "genero": "Masculino", "color": "Azul Oscuro", "elasticidad": false}'),
  ('Vestido Floral Verano', 45.50, 'S', '{"material": "Algodón", "corte": "A-line", "genero": "Femenino", "estampado": "Floral", "temporada": "Verano"}'),
  ('Chaqueta Impermeable', 120.00, 'L', '{"material": "Poliéster", "corte": "Regular", "genero": "Unisex", "resistencia_agua": true, "capucha": true}'),
  ('Camiseta Gráfica', 25.00, 'XL', '{"material": "Algodón Orgánico", "corte": "Oversize", "genero": "Masculino", "tipo_cuello": "Redondo"}'),
  ('Falda Midi de Seda', 65.90, 'S', '{"material": "Seda", "corte": "Midi", "genero": "Femenino", "tipo_cierre": "Cremallera invisible"}');

-- 3. Consultar artículos por material, corte o género
-- Consulta artículos de género 'Femenino'
SELECT nombre_articulo, precio_venta, detalles->>'material' AS material
FROM catalogo_ropa
WHERE detalles->>'genero' = 'Femenino';

-- Consulta artículos hechos de 'Algodón' (puede ser 'Algodón' o 'Algodón Orgánico')
SELECT nombre_articulo, detalles->>'material' AS material, detalles->>'corte' AS corte
FROM catalogo_ropa
WHERE detalles->>'material' LIKE 'Algodón%';

-- Consulta artículos que son impermeables (el atributo 'resistencia_agua' es verdadero, almacenado como booleano en JSONB)
SELECT nombre_articulo, detalles->>'color' AS color, talla_stock
FROM catalogo_ropa
WHERE (detalles->>'resistencia_agua')::boolean = true;

-- 4. Crear índices GIN y medir rendimiento
-- Índice GIN para consultas eficientes en la columna de detalles JSONB
CREATE INDEX idx_detalles_gin ON catalogo_ropa USING GIN (detalles);
-- Índice estándar para el stock
CREATE INDEX idx_talla_stock ON catalogo_ropa (talla_stock);

-- Medir rendimiento de una consulta sobre JSONB utilizando el operador de contención (@>)
EXPLAIN ANALYZE 
SELECT nombre_articulo, detalles
FROM catalogo_ropa
WHERE detalles @> '{"corte": "Slim"}';

-- 5. Implementar pruebas unitarias para JSONB (PL/pgSQL)
DO $$
BEGIN
  RAISE NOTICE '=== PRUEBAS JSONB PARA EL CATÁLOGO DE ROPA ===';
  
  -- Prueba 1: Verificar inserción y talla
  IF EXISTS (SELECT 1 FROM catalogo_ropa WHERE nombre_articulo = 'Jeans Slim Fit' AND talla_stock = 'M') THEN
    RAISE NOTICE '✅ Artículo "Jeans Slim Fit" insertado con talla M correctamente.';
  ELSE
    RAISE EXCEPTION '❌ Error: Artículo Jeans o talla incorrecta.';
  END IF;

  -- Prueba 2: Verificar una especificación anidada (Género)
  IF EXISTS (
    SELECT 1 FROM catalogo_ropa 
    WHERE nombre_articulo = 'Falda Midi de Seda' AND detalles->>'genero' = 'Femenino'
  ) THEN
    RAISE NOTICE '✅ Género de la Falda Midi de Seda es correcto.';
  ELSE
    RAISE EXCEPTION '❌ Error: Género incorrecto para Falda Midi.';
  END IF;

  -- Prueba 3: Conteo por corte ('Oversize')
  IF (SELECT COUNT(*) FROM catalogo_ropa WHERE detalles->>'corte' = 'Oversize') = 1 THEN
    RAISE NOTICE '✅ Conteo correcto: 1 artículo con corte Oversize.';
  ELSE
    RAISE EXCEPTION '❌ Error: Conteo incorrecto para corte Oversize.';
  END IF;

  -- Prueba 4: Verificar existencia del índice GIN
  IF EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_detalles_gin') THEN
    RAISE NOTICE '✅ Índice GIN creado correctamente para detalles.';
  ELSE
    RAISE EXCEPTION '❌ Error: Índice GIN no creado.';
  END IF;

  RAISE NOTICE '=== TODAS LAS PRUEBAS JSONB PARA ROPA PASARON ===';
END;
$$;
