DO $$
DECLARE
  total_jsonb INT;
  total_hstore INT;
  resumen_text TEXT;
BEGIN
  RAISE NOTICE '=== INICIANDO TESTS FINALES COMPLETOS ===';
  
  -- Verificar estado general de la base de datos
  SELECT COUNT(*) INTO total_jsonb FROM productos_jsonb;
  SELECT COUNT(*) INTO total_hstore FROM productos_hstore;
  
  RAISE NOTICE 'ESTADO BASE DE DATOS:';
  RAISE NOTICE '   - Productos JSONB: %', total_jsonb;
  RAISE NOTICE '   - Productos HSTORE: %', total_hstore;
  
  -- Verificar que todos los ejercicios JSONB funcionan
  IF total_jsonb < 5 THEN
    RAISE EXCEPTION 'FALLO: Debe haber al menos 5 productos JSONB';
  ELSE
    RAISE NOTICE 'JSONB: Datos básicos correctos';
  END IF;

  -- Verificar índices JSONB
  IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_especificaciones_gin') THEN
    RAISE EXCEPTION 'FALLO: Índice GIN JSONB no existe';
  ELSE
    RAISE NOTICE 'JSONB: Índices creados correctamente';
  END IF;

  -- Verificar que todos los ejercicios HSTORE funcionan
  IF total_hstore < 5 THEN
    RAISE EXCEPTION 'FALLO: Debe haber al menos 5 productos HSTORE';
  ELSE
    RAISE NOTICE 'HSTORE: Datos básicos correctos';
  END IF;

  -- Verificar extensión HSTORE
  IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'hstore') THEN
    RAISE EXCEPTION 'FALLO: Extensión HSTORE no activada';
  ELSE
    RAISE NOTICE 'HSTORE: Extensión activada';
  END IF;

  -- Verificar índices HSTORE
  IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_atributos_gin') THEN
    RAISE EXCEPTION 'FALLO: Índice GIN HSTORE no existe';
  ELSE
    RAISE NOTICE 'HSTORE: Índices creados correctamente';
  END IF;

  -- Verificar función personalizada
  SELECT resumen_producto('Televisor 55"') INTO resumen_text;
  IF resumen_text IS NULL OR resumen_text = '' THEN
    RAISE EXCEPTION 'FALLO: Función resumen_producto no retorna valor';
  ELSE
    RAISE NOTICE 'HSTORE: Función personalizada funcionando';
  END IF;

  -- Verificar consultas complejas
  IF (SELECT COUNT(*) FROM productos_hstore WHERE atributos ?& ARRAY['marca', 'color']) < 3 THEN
    RAISE EXCEPTION 'FALLO: Consultas complejas con múltiples claves fallaron';
  ELSE
    RAISE NOTICE 'HSTORE: Consultas complejas funcionando';
  END IF;

  -- Verificar rendimiento con índices
  RAISE NOTICE 'RENDIMIENTO: Índices GIN activos para JSONB y HSTORE';

  -- Estado final
  RAISE NOTICE 'ESTADO FINAL:';
  RAISE NOTICE '   - Tablas creadas: 3 (usuarios, productos_jsonb, productos_hstore)';
  RAISE NOTICE '   - Índices GIN: 2 (JSONB y HSTORE)';
  RAISE NOTICE '   - Funciones personalizadas: 1 (resumen_producto)';
  RAISE NOTICE '   - Total registros: %', (total_jsonb + total_hstore + (SELECT COUNT(*) FROM usuarios));
  
  RAISE NOTICE '=== TODOS LOS TESTS FINALES PASARON EXITOSAMENTE ===';
  
EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'ERROR EN TESTS FINALES: %', SQLERRM;
END;
$$;
