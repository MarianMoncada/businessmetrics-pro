-- ============================================
-- BusinessMetrics Pro - Usuarios y Seguridad
-- Gestión de Roles y Permisos
-- ============================================

\c businessmetrics;

-- ============================================
-- ELIMINAR USUARIOS SI EXISTEN
-- ============================================
DROP USER IF EXISTS dba_admin;
DROP USER IF EXISTS analista_ventas;
DROP USER IF EXISTS analista_inventario;
DROP USER IF EXISTS operador_backup;
DROP USER IF EXISTS usuario_readonly;
DROP USER IF EXISTS app_user;

-- ============================================
-- CREAR ROLES PRINCIPALES
-- ============================================

-- 1. DBA_ADMIN: Administrador completo de la base de datos
CREATE USER dba_admin WITH
    PASSWORD 'Admin123!Secure'
    SUPERUSER
    CREATEDB
    CREATEROLE
    LOGIN;

COMMENT ON ROLE dba_admin IS 'Administrador principal con acceso completo';

-- 2. ANALISTA_VENTAS: Acceso completo a ventas y clientes
CREATE USER analista_ventas WITH
    PASSWORD 'Ventas123!Secure'
    NOSUPERUSER
    NOCREATEDB
    NOCREATEROLE
    LOGIN;

COMMENT ON ROLE analista_ventas IS 'Analista con acceso a módulos de ventas y clientes';

-- 3. ANALISTA_INVENTARIO: Acceso a inventario y productos
CREATE USER analista_inventario WITH
    PASSWORD 'Inventario123!Secure'
    NOSUPERUSER
    NOCREATEDB
    NOCREATEROLE
    LOGIN;

COMMENT ON ROLE analista_inventario IS 'Analista con acceso al módulo de inventario';

-- 4. OPERADOR_BACKUP: Usuario para respaldos y recuperación
CREATE USER operador_backup WITH
    PASSWORD 'Backup123!Secure'
    NOSUPERUSER
    NOCREATEDB
    NOCREATEROLE
    LOGIN
    REPLICATION;

COMMENT ON ROLE operador_backup IS 'Usuario especializado en respaldos y recuperación';

-- 5. USUARIO_READONLY: Solo lectura en toda la BD
CREATE USER usuario_readonly WITH
    PASSWORD 'ReadOnly123!Secure'
    NOSUPERUSER
    NOCREATEDB
    NOCREATEROLE
    LOGIN;

COMMENT ON ROLE usuario_readonly IS 'Usuario con permisos de solo lectura';

-- 6. APP_USER: Usuario para la aplicación
CREATE USER app_user WITH
    PASSWORD 'AppUser123!Secure'
    NOSUPERUSER
    NOCREATEDB
    NOCREATEROLE
    LOGIN
    CONNECTION LIMIT 50;

COMMENT ON ROLE app_user IS 'Usuario para conexiones desde la aplicación';

-- ============================================
-- PERMISOS PARA ANALISTA_VENTAS
-- ============================================
-- Acceso a schemas
GRANT USAGE ON SCHEMA ventas TO analista_ventas;
GRANT USAGE ON SCHEMA clientes TO analista_ventas;
GRANT USAGE ON SCHEMA rrhh TO analista_ventas;

-- Permisos en tablas
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ventas TO analista_ventas;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA clientes TO analista_ventas;
GRANT SELECT ON ALL TABLES IN SCHEMA rrhh TO analista_ventas;

-- Permisos en secuencias
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA ventas TO analista_ventas;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA clientes TO analista_ventas;

-- Permisos futuros
ALTER DEFAULT PRIVILEGES IN SCHEMA ventas GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO analista_ventas;
ALTER DEFAULT PRIVILEGES IN SCHEMA clientes GRANT SELECT, INSERT, UPDATE ON TABLES TO analista_ventas;

-- ============================================
-- PERMISOS PARA ANALISTA_INVENTARIO
-- ============================================
GRANT USAGE ON SCHEMA inventario TO analista_inventario;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA inventario TO analista_inventario;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA inventario TO analista_inventario;

ALTER DEFAULT PRIVILEGES IN SCHEMA inventario GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO analista_inventario;

-- ============================================
-- PERMISOS PARA OPERADOR_BACKUP
-- ============================================
-- Acceso a todos los schemas para respaldo
GRANT USAGE ON SCHEMA ventas, clientes, inventario, rrhh, auditoria TO operador_backup;

-- Solo lectura en todas las tablas
GRANT SELECT ON ALL TABLES IN SCHEMA ventas TO operador_backup;
GRANT SELECT ON ALL TABLES IN SCHEMA clientes TO operador_backup;
GRANT SELECT ON ALL TABLES IN SCHEMA inventario TO operador_backup;
GRANT SELECT ON ALL TABLES IN SCHEMA rrhh TO operador_backup;
GRANT SELECT ON ALL TABLES IN SCHEMA auditoria TO operador_backup;

-- Permisos especiales para tabla de respaldos
GRANT INSERT, UPDATE ON auditoria.respaldos TO operador_backup;
GRANT USAGE ON SEQUENCE auditoria.respaldos_respaldo_id_seq TO operador_backup;

-- ============================================
-- PERMISOS PARA USUARIO_READONLY
-- ============================================
GRANT USAGE ON SCHEMA ventas, clientes, inventario, rrhh, auditoria TO usuario_readonly;

GRANT SELECT ON ALL TABLES IN SCHEMA ventas TO usuario_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA clientes TO usuario_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA inventario TO usuario_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA rrhh TO usuario_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA auditoria TO usuario_readonly;

-- ============================================
-- PERMISOS PARA APP_USER
-- ============================================
GRANT USAGE ON SCHEMA ventas, clientes, inventario TO app_user;

-- Permisos de lectura y escritura básicos
GRANT SELECT, INSERT, UPDATE ON ventas.ventas TO app_user;
GRANT SELECT, INSERT, UPDATE ON ventas.detalle_ventas TO app_user;
GRANT SELECT, INSERT, UPDATE ON clientes.clientes TO app_user;
GRANT SELECT ON inventario.productos TO app_user;
GRANT SELECT ON inventario.categorias TO app_user;

-- Permisos en secuencias
GRANT USAGE ON ALL SEQUENCES IN SCHEMA ventas TO app_user;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA clientes TO app_user;

-- ============================================
-- POLÍTICAS DE SEGURIDAD (Row Level Security)
-- ============================================

-- Habilitar RLS en tabla de ventas
ALTER TABLE ventas.ventas ENABLE ROW LEVEL SECURITY;

-- Política: Los analistas de ventas solo ven ventas de su región
CREATE POLICY politica_ventas_por_region ON ventas.ventas
    FOR SELECT
    TO analista_ventas
    USING (region = current_setting('app.region', true));

-- Habilitar RLS en clientes
ALTER TABLE clientes.clientes ENABLE ROW LEVEL SECURITY;

-- Política: Clientes activos para usuarios de aplicación
CREATE POLICY politica_clientes_activos ON clientes.clientes
    FOR SELECT
    TO app_user
    USING (estado = 'activo');

-- ============================================
-- CONFIGURACIÓN DE SEGURIDAD ADICIONAL
-- ============================================

-- Limitar conexiones concurrentes por usuario
ALTER USER analista_ventas CONNECTION LIMIT 10;
ALTER USER analista_inventario CONNECTION LIMIT 10;
ALTER USER operador_backup CONNECTION LIMIT 5;
ALTER USER usuario_readonly CONNECTION LIMIT 20;

-- Establecer timeout de sesión (15 minutos de inactividad)
ALTER DATABASE businessmetrics SET idle_in_transaction_session_timeout = '15min';

-- Configurar logging de conexiones
ALTER DATABASE businessmetrics SET log_connections = 'on';
ALTER DATABASE businessmetrics SET log_disconnections = 'on';

-- ============================================
-- FUNCIONES DE AUDITORÍA
-- ============================================

-- Función para registrar accesos
CREATE OR REPLACE FUNCTION auditoria.registrar_acceso()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO auditoria.log_acciones (
        tabla_afectada,
        accion,
        usuario,
        fecha_hora,
        datos_nuevos,
        ip_address
    ) VALUES (
        TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME,
        TG_OP,
        current_user,
        CURRENT_TIMESTAMP,
        row_to_json(NEW),
        inet_client_addr()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger de auditoría en tablas críticas
CREATE TRIGGER trigger_auditoria_ventas
AFTER INSERT OR UPDATE OR DELETE ON ventas.ventas
FOR EACH ROW EXECUTE FUNCTION auditoria.registrar_acceso();

CREATE TRIGGER trigger_auditoria_clientes
AFTER INSERT OR UPDATE OR DELETE ON clientes.clientes
FOR EACH ROW EXECUTE FUNCTION auditoria.registrar_acceso();

-- ============================================
-- VISTA DE USUARIOS Y PERMISOS
-- ============================================
CREATE OR REPLACE VIEW auditoria.usuarios_sistema AS
SELECT 
    r.rolname AS usuario,
    r.rolsuper AS es_superusuario,
    r.rolcreatedb AS puede_crear_db,
    r.rolcreaterole AS puede_crear_roles,
    r.rolcanlogin AS puede_login,
    r.rolconnlimit AS limite_conexiones,
    ARRAY_AGG(DISTINCT s.nspname) AS schemas_acceso
FROM pg_roles r
LEFT JOIN pg_namespace s ON has_schema_privilege(r.oid, s.oid, 'USAGE')
WHERE r.rolcanlogin = true
GROUP BY r.rolname, r.rolsuper, r.rolcreatedb, r.rolcreaterole, r.rolcanlogin, r.rolconnlimit
ORDER BY r.rolname;

-- ============================================
-- RESUMEN DE USUARIOS CREADOS
-- ============================================
DO $$
BEGIN
    RAISE NOTICE '====================================';
    RAISE NOTICE 'USUARIOS CREADOS EXITOSAMENTE';
    RAISE NOTICE '====================================';
    RAISE NOTICE '1. dba_admin         - Administrador completo';
    RAISE NOTICE '2. analista_ventas   - Acceso a ventas y clientes';
    RAISE NOTICE '3. analista_inventario - Acceso a inventario';
    RAISE NOTICE '4. operador_backup   - Respaldos y recuperación';
    RAISE NOTICE '5. usuario_readonly  - Solo lectura';
    RAISE NOTICE '6. app_user          - Usuario de aplicación';
    RAISE NOTICE '====================================';
    RAISE NOTICE 'Políticas de seguridad aplicadas';
    RAISE NOTICE 'Auditoría configurada';
    RAISE NOTICE '====================================';
END $$;

-- ============================================
-- GUARDAR INFORMACIÓN DE USUARIOS
-- ============================================
-- Crear tabla para documentar usuarios
CREATE TABLE IF NOT EXISTS auditoria.usuarios_documentacion (
    usuario VARCHAR(100) PRIMARY KEY,
    password_ejemplo VARCHAR(100),
    descripcion TEXT,
    permisos TEXT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO auditoria.usuarios_documentacion (usuario, password_ejemplo, descripcion, permisos) VALUES
('dba_admin', 'Admin123!Secure', 'Administrador principal del sistema', 'Todos los permisos - SUPERUSER'),
('analista_ventas', 'Ventas123!Secure', 'Analista de ventas y clientes', 'SELECT, INSERT, UPDATE, DELETE en ventas y clientes'),
('analista_inventario', 'Inventario123!Secure', 'Analista de inventario', 'SELECT, INSERT, UPDATE, DELETE en inventario'),
('operador_backup', 'Backup123!Secure', 'Operador de respaldos', 'SELECT en todas las tablas, permisos de replicación'),
('usuario_readonly', 'ReadOnly123!Secure', 'Usuario de solo lectura', 'SELECT en todas las tablas'),
('app_user', 'AppUser123!Secure', 'Usuario para aplicaciones', 'Permisos limitados de lectura y escritura');
