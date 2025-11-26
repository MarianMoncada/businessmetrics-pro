#!/bin/bash

# ============================================
# BusinessMetrics Pro - Script de Respaldo Manual
# ============================================

echo "======================================"
echo "RESPALDO MANUAL DE BASE DE DATOS"
echo "======================================"

# Configuración
DB_HOST="${DB_HOST:-postgres}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-businessmetrics}"
DB_USER="${DB_USER:-admin}"
DB_PASSWORD="${DB_PASSWORD:-Admin123!Secure}"
BACKUP_DIR="/backup/manual"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/manual_backup_$TIMESTAMP.sql"

# Crear directorio si no existe
mkdir -p "$BACKUP_DIR"

echo "🔄 Iniciando respaldo manual..."
echo "Archivo: $BACKUP_FILE"

# Ejecutar respaldo
export PGPASSWORD="$DB_PASSWORD"
pg_dump -h "$DB_HOST" \
        -p "$DB_PORT" \
        -U "$DB_USER" \
        -d "$DB_NAME" \
        --verbose \
        --format=plain \
        --no-owner \
        --no-privileges \
        -f "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo "✅ Respaldo completado"
    
    # Comprimir
    echo "🗜️  Comprimiendo..."
    gzip "$BACKUP_FILE"
    
    FINAL_FILE="${BACKUP_FILE}.gz"
    FILE_SIZE=$(ls -lh "$FINAL_FILE" | awk '{print $5}')
    
    echo "✅ Respaldo finalizado"
    echo "Archivo: $FINAL_FILE"
    echo "Tamaño: $FILE_SIZE"
    
    # Listar respaldos disponibles
    echo ""
    echo "Respaldos disponibles:"
    ls -lh "$BACKUP_DIR"
else
    echo "❌ Error durante el respaldo"
    exit 1
fi
