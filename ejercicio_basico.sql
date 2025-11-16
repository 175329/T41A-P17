CREATE EXTENSION IF NOT EXISTS hstore;

-- 2. Crear tabla de propiedades con columna HSTORE
CREATE TABLE propiedades_hstore (
  id_propiedad SERIAL PRIMARY KEY,
  direccion TEXT NOT NULL,
  precio_listado DECIMAL(10,2),
  caracteristicas HSTORE -- Almacena atributos variables de la propiedad
);

-- 3. Insertar al menos 5 propiedades con múltiples pares clave-valor
INSERT INTO propiedades_hstore (direccion, precio_listado, caracteristicas)
VALUES 
  ('Calle Falsa 123', 150000.00, 'tipo => apartamento, habitaciones => 3, banos => 2, zona => centro, balcon => true, estado => venta'),
  ('Avenida Siempre Viva 742', 280000.00, 'tipo => casa, habitaciones => 4, banos => 3, zona => suburbio, piscina => true, garaje => 2, estado => venta'),
  ('Lote Industrial A-5', 95000.00, 'tipo => terreno, superficie_m2 => 1000, edificable => true, uso_principal => industrial, estado => alquiler'),
  ('Torre Central Piso 10', 320000.00, 'tipo => oficina, superficie_m2 => 80, bano_privado => false, internet_fibra => true, estado => venta'),
  ('Plaza del Sol Local 3', 180000.00, 'tipo => local_comercial, superficie_m2 => 50, aire_acondicionado => true, vitrina => 5m, estado => alquiler');

-- 4. Consultar por una clave específica (e.g., propiedades en 'suburbio')
SELECT direccion, precio_listado, caracteristicas -> 'tipo' as tipo_propiedad
FROM propiedades_hstore
WHERE caracteristicas -> 'zona' = 'suburbio';

-- 5. Actualizar un valor dentro del HSTORE (añadir o modificar un atributo)
-- Añadir el atributo 'amueblado' al apartamento
UPDATE propiedades_hstore
SET caracteristicas = caracteristicas || 'amueblado => true'::hstore
WHERE direccion = 'Calle Falsa 123';

-- Modificar el estado del local comercial a 'vendido'
UPDATE propiedades_hstore
SET caracteristicas = caracteristicas || 'estado => vendido'::hstore
WHERE direccion = 'Plaza del Sol Local 3';

-- 6. Eliminar una clave de un registro (e.g., eliminar 'uso_principal' del terreno)
UPDATE propiedades_hstore
SET caracteristicas = delete(caracteristicas, 'uso_principal')
WHERE direccion = 'Lote Industrial A-5';

-- Mostrar los resultados de las operaciones de actualización y eliminación
SELECT direccion, caracteristicas FROM propiedades_hstore;

-- 7. Implementar pruebas unitarias para HSTORE (PL/pgSQL)
DO $$
BEGIN
  RAISE NOTICE '=== PRUEBAS HSTORE EN GESTIÓN DE INMUEBLES ===';
  
  -- Verificar extensión
  IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'hstore') THEN
    RAISE EXCEPTION '❌ Extensión HSTORE no activada';
  ELSE
    RAISE NOTICE '✅ Extensión HSTORE activada';
  END IF;

  -- Verificar conteo de registros
  IF (SELECT COUNT(*) FROM propiedades_hstore) < 5 THEN
    RAISE EXCEPTION '❌ Debe haber al menos 5 propiedades HSTORE';
  ELSE
    RAISE NOTICE '✅ Datos HSTORE insertados correctamente';
  END IF;

  -- Verificar consulta por zona
  IF (SELECT COUNT(*) FROM propiedades_hstore WHERE caracteristicas -> 'zona' = 'suburbio') <> 1 THEN
    RAISE EXCEPTION '❌ Consulta por zona no funciona o devuelve un número incorrecto de resultados';
  ELSE
    RAISE NOTICE '✅ Consultas por clave (zona) funcionando';
  END IF;

  -- Verificar actualización (amueblado)
  IF NOT EXISTS (SELECT 1 FROM propiedades_hstore WHERE direccion = 'Calle Falsa 123' AND caracteristicas -> 'amueblado' = 'true') THEN
    RAISE EXCEPTION '❌ Actualización de atributo (amueblado) falló';
  ELSE
    RAISE NOTICE '✅ Actualizaciones HSTORE (adición de clave) funcionando';
  END IF;
  
  -- Verificar eliminación (uso_principal)
  -- El operador '?' verifica si una clave existe
  IF EXISTS (SELECT 1 FROM propiedades_hstore WHERE direccion = 'Lote Industrial A-5' AND caracteristicas ? 'uso_principal') THEN
    RAISE EXCEPTION '❌ Eliminación de clave (uso_principal) falló';
  ELSE
    RAISE NOTICE '✅ Eliminación de clave HSTORE funcionando';
  END IF;

  RAISE NOTICE '=== TODAS LAS PRUEBAS HSTORE PASARON ===';
END;
$$;
