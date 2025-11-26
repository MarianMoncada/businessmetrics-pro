#!/bin/bash

# ============================================
# BusinessMetrics Pro - Script de Limpieza
# ============================================

echo "=========================================="
echo "  BusinessMetrics Pro - Limpieza"
echo "=========================================="
echo ""

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}⚠️  ADVERTENCIA: Esto eliminará todos los contenedores, volúmenes y datos${NC}"
read -p "¿Está seguro? (escriba 'SI' para confirmar): " confirmacion

if [ "$confirmacion" != "SI" ]; then
    echo "Operación cancelada"
    exit 0
fi

# Limpiar Docker
echo ""
echo "Limpiando Docker Compose..."
cd docker
docker compose down -v
cd ..

# Limpiar Kubernetes
echo ""
echo "Limpiando Kubernetes..."
kubectl delete namespace businessmetrics 2>/dev/null || true
minikube stop 2>/dev/null || true

echo ""
echo -e "${RED}✅ Limpieza completada${NC}"
