-- ============================================
-- BusinessMetrics Pro - Índices
-- Optimización de Consultas
-- ============================================

\c businessmetrics;

-- ============================================
-- ÍNDICES PARA CLIENTES
-- ============================================
CREATE INDEX idx_clientes_email ON clientes.clientes(email);
CREATE INDEX idx_clientes_ciudad ON clientes.clientes(ciudad);
CREATE INDEX idx_clientes_pais ON clientes.clientes(pais);
CREATE INDEX idx_clientes_estado ON clientes.clientes(estado);
CREATE INDEX idx_clientes_fecha_registro ON clientes.clientes(fecha_registro);
CREATE INDEX idx_clientes_ultima_compra ON clientes.clientes(ultima_compra);

-- ============================================
-- ÍNDICES PARA PRODUCTOS
-- ============================================
CREATE INDEX idx_productos_categoria ON inventario.productos(categoria_id);
CREATE INDEX idx_productos_nombre ON inventario.productos(nombre);
CREATE INDEX idx_productos_activo ON inventario.productos(activo);
CREATE INDEX idx_productos_precio ON inventario.productos(precio);
CREATE INDEX idx_productos_stock ON inventario.productos(stock_actual);

-- Índice compuesto para búsquedas complejas
CREATE INDEX idx_productos_categoria_activo ON inventario.productos(categoria_id, activo);

-- ============================================
-- ÍNDICES PARA VENTAS
-- ============================================
CREATE INDEX idx_ventas_cliente ON ventas.ventas(cliente_id);
CREATE INDEX idx_ventas_empleado ON ventas.ventas(empleado_id);
CREATE INDEX idx_ventas_fecha ON ventas.ventas(fecha_venta);
CREATE INDEX idx_ventas_estado ON ventas.ventas(estado);
CREATE INDEX idx_ventas_region ON ventas.ventas(region);
CREATE INDEX idx_ventas_metodo_pago ON ventas.ventas(metodo_pago);

-- Índices compuestos para reportes
CREATE INDEX idx_ventas_fecha_estado ON ventas.ventas(fecha_venta, estado);
CREATE INDEX idx_ventas_region_fecha ON ventas.ventas(region, fecha_venta);

-- ============================================
-- ÍNDICES PARA DETALLE VENTAS
-- ============================================
CREATE INDEX idx_detalle_venta ON ventas.detalle_ventas(venta_id);
CREATE INDEX idx_detalle_producto ON ventas.detalle_ventas(producto_id);

-- Índice para análisis de productos vendidos
CREATE INDEX idx_detalle_producto_cantidad ON ventas.detalle_ventas(producto_id, cantidad);

-- ============================================
-- ÍNDICES PARA EMPLEADOS
-- ============================================
CREATE INDEX idx_empleados_email ON rrhh.empleados(email);
CREATE INDEX idx_empleados_departamento ON rrhh.empleados(departamento);
CREATE INDEX idx_empleados_puesto ON rrhh.empleados(puesto);
CREATE INDEX idx_empleados_activo ON rrhh.empleados(activo);
CREATE INDEX idx_empleados_fecha_contratacion ON rrhh.empleados(fecha_contratacion);

-- ============================================
-- ÍNDICES PARA AUDITORÍA
-- ============================================
CREATE INDEX idx_log_tabla ON auditoria.log_acciones(tabla_afectada);
CREATE INDEX idx_log_fecha ON auditoria.log_acciones(fecha_hora);
CREATE INDEX idx_log_usuario ON auditoria.log_acciones(usuario);
CREATE INDEX idx_log_accion ON auditoria.log_acciones(accion);

-- Índice para búsquedas en JSONB
CREATE INDEX idx_log_datos_nuevos ON auditoria.log_acciones USING GIN(datos_nuevos);

-- ============================================
-- ÍNDICES PARA RESPALDOS
-- ============================================
CREATE INDEX idx_respaldos_fecha ON auditoria.respaldos(fecha_inicio);
CREATE INDEX idx_respaldos_tipo ON auditoria.respaldos(tipo_respaldo);
CREATE INDEX idx_respaldos_estado ON auditoria.respaldos(estado);

-- ============================================
-- ÍNDICES DE TEXTO COMPLETO (Full-Text Search)
-- ============================================
-- Para búsquedas de texto en productos
ALTER TABLE inventario.productos ADD COLUMN busqueda_texto tsvector;

CREATE INDEX idx_productos_busqueda ON inventario.productos USING GIN(busqueda_texto);

-- Trigger para actualizar el índice de búsqueda automáticamente
CREATE OR REPLACE FUNCTION inventario.actualizar_busqueda_texto()
RETURNS TRIGGER AS $$
BEGIN
    NEW.busqueda_texto := 
        setweight(to_tsvector('spanish', COALESCE(NEW.nombre, '')), 'A') ||
        setweight(to_tsvector('spanish', COALESCE(NEW.descripcion, '')), 'B');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_actualizar_busqueda_texto
BEFORE INSERT OR UPDATE ON inventario.productos
FOR EACH ROW
EXECUTE FUNCTION inventario.actualizar_busqueda_texto();

-- ============================================
-- ANÁLISIS Y ESTADÍSTICAS
-- ============================================
-- Actualizar estadísticas para el optimizador
ANALYZE clientes.clientes;
ANALYZE inventario.productos;
ANALYZE inventario.categorias;
ANALYZE ventas.ventas;
ANALYZE ventas.detalle_ventas;
ANALYZE rrhh.empleados;
ANALYZE auditoria.log_acciones;
ANALYZE auditoria.respaldos;

-- ============================================
-- MENSAJE DE CONFIRMACIÓN
-- ============================================
DO $$
BEGIN
    RAISE NOTICE 'Índices creados exitosamente';
    RAISE NOTICE 'Total de índices: 35+';
    RAISE NOTICE 'Optimización de consultas completada';
END $$;
