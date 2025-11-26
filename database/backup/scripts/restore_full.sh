#!/bin/bash

# ============================================
# BusinessMetrics Pro - Script de Restauración Completa
# ============================================

echo "======================================"
echo "RESTAURACIÓN COMPLETA DE BASE DE DATOS"
echo "======================================"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuración
DB_HOST="${DB_HOST:-postgres}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-businessmetrics}"
DB_USER="${DB_USER:-admin}"
DB_PASSWORD="${DB_PASSWORD:-Admin123!Secure}"
BACKUP_DIR="/backup"

# Función para logging
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar que se proporcionó el archivo de respaldo
if [ -z "$1" ]; then
    log_error "Debe proporcionar la ruta del archivo de respaldo"
    echo "Uso: $0 <archivo_respaldo.sql.gz>"
    echo ""
    echo "Respaldos disponibles:"
    ls -lh $BACKUP_DIR/*.sql.gz 2>/dev/null || echo "No hay respaldos disponibles"
    exit 1
fi

BACKUP_FILE="$1"

# Verificar que el archivo existe
if [ ! -f "$BACKUP_FILE" ]; then
    log_error "El archivo $BACKUP_FILE no existe"
    exit 1
fi

log_info "Archivo de respaldo: $BACKUP_FILE"
log_info "Host: $DB_HOST:$DB_PORT"
log_info "Base de datos: $DB_NAME"

# Confirmar restauración
echo ""
echo -e "${YELLOW}⚠️  ADVERTENCIA: Esta operación eliminará todos los datos actuales${NC}"
read -p "¿Está seguro que desea continuar? (escriba 'SI' para confirmar): " confirmacion

if [ "$confirmacion" != "SI" ]; then
    log_warning "Restauración cancelada"
    exit 0
fi

# Descomprimir archivo si está comprimido
TEMP_FILE="$BACKUP_DIR/temp_restore.sql"
if [[ $BACKUP_FILE == *.gz ]]; then
    log_info "Descomprimiendo archivo..."
    gunzip -c "$BACKUP_FILE" > "$TEMP_FILE"
    RESTORE_FILE="$TEMP_FILE"
else
    RESTORE_FILE="$BACKUP_FILE"
fi

# Cerrar conexiones existentes
log_info "Cerrando conexiones existentes..."
export PGPASSWORD="$DB_PASSWORD"
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c \
    "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$DB_NAME' AND pid <> pg_backend_pid();" \
    2>/dev/null

# Eliminar base de datos existente
log_warning "Eliminando base de datos existente..."
dropdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$DB_NAME" 2>/dev/null

# Crear nueva base de datos
log_info "Creando nueva base de datos..."
createdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$DB_NAME"

if [ $? -ne 0 ]; then
    log_error "Error al crear la base de datos"
    rm -f "$TEMP_FILE"
    exit 1
fi

# Restaurar desde respaldo
log_info "Restaurando datos..."
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" < "$RESTORE_FILE"

if [ $? -eq 0 ]; then
    log_info "✅ Restauración completada exitosamente"
    
    # Verificar integridad
    log_info "Verificando integridad..."
    TABLE_COUNT=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c \
        "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema NOT IN ('pg_catalog', 'information_schema');")
    
    log_info "Tablas restauradas: $TABLE_COUNT"
    
    # Actualizar estadísticas
    log_info "Actualizando estadísticas..."
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "ANALYZE;"
    
    log_info "✅ Proceso de restauración finalizado"
else
    log_error "Error durante la restauración"
    rm -f "$TEMP_FILE"
    exit 1
fi

# Limpiar archivo temporal
rm -f "$TEMP_FILE"

echo ""
echo "======================================"
echo "RESTAURACIÓN COMPLETADA"
echo "======================================"
