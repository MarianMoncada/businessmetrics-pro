-- ============================================
-- BusinessMetrics Pro - Schema Principal
-- Creación de Tablas y Estructura
-- ============================================

-- Eliminar base de datos si existe y recrear
DROP DATABASE IF EXISTS businessmetrics;
CREATE DATABASE businessmetrics;

\c businessmetrics;

-- ============================================
-- EXTENSIONES
-- ============================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- ============================================
-- SCHEMAS (Espacios Lógicos)
-- ============================================
CREATE SCHEMA IF NOT EXISTS ventas;
CREATE SCHEMA IF NOT EXISTS clientes;
CREATE SCHEMA IF NOT EXISTS inventario;
CREATE SCHEMA IF NOT EXISTS rrhh;
CREATE SCHEMA IF NOT EXISTS auditoria;

-- ============================================
-- TABLA: clientes.clientes
-- ============================================
CREATE TABLE clientes.clientes (
    cliente_id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    telefono VARCHAR(20),
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ciudad VARCHAR(100),
    pais VARCHAR(50),
    estado VARCHAR(20) DEFAULT 'activo' CHECK (estado IN ('activo', 'inactivo', 'suspendido')),
    total_compras DECIMAL(12,2) DEFAULT 0,
    ultima_compra TIMESTAMP
);

-- ============================================
-- TABLA: inventario.categorias
-- ============================================
CREATE TABLE inventario.categorias (
    categoria_id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- TABLA: inventario.productos
-- ============================================
CREATE TABLE inventario.productos (
    producto_id SERIAL PRIMARY KEY,
    categoria_id INTEGER REFERENCES inventario.categorias(categoria_id),
    nombre VARCHAR(200) NOT NULL,
    descripcion TEXT,
    precio DECIMAL(10,2) NOT NULL CHECK (precio >= 0),
    costo DECIMAL(10,2) NOT NULL CHECK (costo >= 0),
    stock_actual INTEGER DEFAULT 0 CHECK (stock_actual >= 0),
    stock_minimo INTEGER DEFAULT 10,
    stock_maximo INTEGER DEFAULT 1000,
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ultima_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- TABLA: rrhh.empleados
-- ============================================
CREATE TABLE rrhh.empleados (
    empleado_id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    puesto VARCHAR(100),
    departamento VARCHAR(100),
    salario DECIMAL(10,2),
    fecha_contratacion DATE NOT NULL,
    activo BOOLEAN DEFAULT TRUE,
    comision_porcentaje DECIMAL(5,2) DEFAULT 0
);

-- ============================================
-- TABLA: ventas.ventas
-- ============================================
CREATE TABLE ventas.ventas (
    venta_id SERIAL PRIMARY KEY,
    cliente_id INTEGER REFERENCES clientes.clientes(cliente_id),
    empleado_id INTEGER REFERENCES rrhh.empleados(empleado_id),
    fecha_venta TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    subtotal DECIMAL(12,2) NOT NULL,
    impuestos DECIMAL(12,2) NOT NULL,
    descuento DECIMAL(12,2) DEFAULT 0,
    total DECIMAL(12,2) NOT NULL,
    metodo_pago VARCHAR(50),
    estado VARCHAR(20) DEFAULT 'completada' CHECK (estado IN ('pendiente', 'completada', 'cancelada', 'reembolsada')),
    region VARCHAR(100),
    notas TEXT
);

-- ============================================
-- TABLA: ventas.detalle_ventas
-- ============================================
CREATE TABLE ventas.detalle_ventas (
    detalle_id SERIAL PRIMARY KEY,
    venta_id INTEGER REFERENCES ventas.ventas(venta_id) ON DELETE CASCADE,
    producto_id INTEGER REFERENCES inventario.productos(producto_id),
    cantidad INTEGER NOT NULL CHECK (cantidad > 0),
    precio_unitario DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(12,2) NOT NULL,
    descuento DECIMAL(10,2) DEFAULT 0
);

-- ============================================
-- TABLA: auditoria.log_acciones
-- ============================================
CREATE TABLE auditoria.log_acciones (
    log_id SERIAL PRIMARY KEY,
    tabla_afectada VARCHAR(100),
    accion VARCHAR(20) CHECK (accion IN ('INSERT', 'UPDATE', 'DELETE')),
    usuario VARCHAR(100),
    fecha_hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    datos_anteriores JSONB,
    datos_nuevos JSONB,
    ip_address INET
);

-- ============================================
-- TABLA: auditoria.respaldos
-- ============================================
CREATE TABLE auditoria.respaldos (
    respaldo_id SERIAL PRIMARY KEY,
    tipo_respaldo VARCHAR(20) CHECK (tipo_respaldo IN ('completo', 'incremental', 'diferencial')),
    fecha_inicio TIMESTAMP NOT NULL,
    fecha_fin TIMESTAMP,
    estado VARCHAR(20) CHECK (estado IN ('iniciado', 'completado', 'fallido')),
    tamaño_bytes BIGINT,
    ruta_archivo TEXT,
    notas TEXT
);

-- ============================================
-- VISTAS ÚTILES
-- ============================================

-- Vista: Resumen de ventas por cliente
CREATE OR REPLACE VIEW ventas.resumen_ventas_clientes AS
SELECT 
    c.cliente_id,
    c.nombre || ' ' || c.apellido AS nombre_completo,
    c.email,
    c.ciudad,
    c.pais,
    COUNT(v.venta_id) AS total_ventas,
    SUM(v.total) AS monto_total_compras,
    AVG(v.total) AS promedio_compra,
    MAX(v.fecha_venta) AS ultima_compra
FROM clientes.clientes c
LEFT JOIN ventas.ventas v ON c.cliente_id = v.cliente_id
GROUP BY c.cliente_id, c.nombre, c.apellido, c.email, c.ciudad, c.pais;

-- Vista: Productos más vendidos
CREATE OR REPLACE VIEW inventario.productos_mas_vendidos AS
SELECT 
    p.producto_id,
    p.nombre,
    c.nombre AS categoria,
    SUM(dv.cantidad) AS unidades_vendidas,
    SUM(dv.subtotal) AS ingresos_totales,
    p.stock_actual,
    p.precio
FROM inventario.productos p
JOIN inventario.categorias c ON p.categoria_id = c.categoria_id
LEFT JOIN ventas.detalle_ventas dv ON p.producto_id = dv.producto_id
GROUP BY p.producto_id, p.nombre, c.nombre, p.stock_actual, p.precio
ORDER BY unidades_vendidas DESC;

-- Vista: Rendimiento de empleados
CREATE OR REPLACE VIEW rrhh.rendimiento_empleados AS
SELECT 
    e.empleado_id,
    e.nombre || ' ' || e.apellido AS nombre_completo,
    e.puesto,
    e.departamento,
    COUNT(v.venta_id) AS total_ventas,
    SUM(v.total) AS ingresos_generados,
    AVG(v.total) AS promedio_venta,
    e.salario,
    (SUM(v.total) * e.comision_porcentaje / 100) AS comisiones_ganadas
FROM rrhh.empleados e
LEFT JOIN ventas.ventas v ON e.empleado_id = v.empleado_id
GROUP BY e.empleado_id, e.nombre, e.apellido, e.puesto, e.departamento, e.salario, e.comision_porcentaje;

-- ============================================
-- COMENTARIOS EN TABLAS
-- ============================================
COMMENT ON TABLE clientes.clientes IS 'Información de clientes del sistema';
COMMENT ON TABLE inventario.productos IS 'Catálogo de productos disponibles';
COMMENT ON TABLE ventas.ventas IS 'Registro de todas las ventas realizadas';
COMMENT ON TABLE rrhh.empleados IS 'Información de empleados de la empresa';
COMMENT ON TABLE auditoria.log_acciones IS 'Log de auditoría de todas las acciones en la BD';
COMMENT ON TABLE auditoria.respaldos IS 'Historial de respaldos realizados';

-- ============================================
-- MENSAJE DE CONFIRMACIÓN
-- ============================================
DO $$
BEGIN
    RAISE NOTICE 'Schema creado exitosamente - BusinessMetrics Pro';
    RAISE NOTICE 'Total de tablas creadas: 9';
    RAISE NOTICE 'Total de vistas creadas: 3';
END $$;

