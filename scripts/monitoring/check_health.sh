#!/bin/bash

# ============================================
# Script de Verificación de Salud del Sistema
# ============================================

echo "======================================"
echo "HEALTH CHECK - BusinessMetrics Pro"
echo "======================================"
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

check_service() {
    SERVICE=$1
    URL=$2
    
    if curl -s -o /dev/null -w "%{http_code}" "$URL" | grep -q "200\|302"; then
        echo -e "${GREEN}✅${NC} $SERVICE: OK"
    else
        echo -e "${RED}❌${NC} $SERVICE: FALLO"
    fi
}

# Verificar servicios Docker
if docker ps | grep -q "businessmetrics"; then
    echo "Verificando servicios Docker..."
    echo ""
    
    check_service "PostgreSQL" "http://localhost:5432"
    check_service "Airflow" "http://localhost:8080"
    check_service "Grafana" "http://localhost:3000"
    check_service "pgAdmin" "http://localhost:5050"
    check_service "Prometheus" "http://localhost:9090"
    
    echo ""
    echo "Contenedores activos:"
    docker ps --format "table {{.Names}}\t{{.Status}}" | grep businessmetrics
fi

echo ""
echo "======================================"
