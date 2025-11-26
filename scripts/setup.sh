#!/bin/bash

# ============================================
# BusinessMetrics Pro - Script de Setup Completo
# ============================================

set -e  # Salir si hay error

echo "=========================================="
echo "  BusinessMetrics Pro - Setup Completo"
echo "=========================================="
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Verificar que estamos en el directorio correcto
if [ ! -f "README.md" ]; then
    log_error "Debe ejecutar este script desde el directorio raíz del proyecto"
    exit 1
fi

# ============================================
# OPCIÓN 1: Docker Compose (Desarrollo Local)
# ============================================
setup_docker() {
    log_step "Configurando con Docker Compose..."
    
    # Crear directorios necesarios
    log_info "Creando directorios..."
    mkdir -p airflow/logs
    mkdir -p database/backup
    chmod -R 777 airflow/logs
    chmod -R 777 database/backup
    
    # Iniciar servicios
    log_info "Iniciando servicios con Docker Compose..."
    cd docker
    docker compose up -d
    cd ..
    
    log_info "Esperando a que los servicios estén listos..."
    sleep 30
    
    # Verificar servicios
    log_info "Verificando servicios..."
    docker ps
    
    echo ""
    log_info "✅ Setup con Docker completado!"
    echo ""
    echo "Servicios disponibles:"
    echo "  - PostgreSQL:  http://localhost:5432"
    echo "  - Airflow:     http://localhost:8080 (admin/admin)"
    echo "  - Grafana:     http://localhost:3000 (admin/admin)"
    echo "  - pgAdmin:     http://localhost:5050 (admin@businessmetrics.com/admin)"
    echo "  - Prometheus:  http://localhost:9090"
    echo ""
}

# ============================================
# OPCIÓN 2: Kubernetes (Producción Simulada)
# ============================================
setup_kubernetes() {
    log_step "Configurando con Kubernetes..."
    
    # Verificar Minikube
    if ! command -v minikube &> /dev/null; then
        log_error "Minikube no está instalado"
        exit 1
    fi
    
    # Iniciar Minikube
    log_info "Iniciando Minikube..."
    minikube start --driver=docker --memory=4096 --cpus=2
    
    # Habilitar addons
    log_info "Habilitando addons..."
    minikube addons enable ingress
    minikube addons enable metrics-server
    
    # Aplicar manifiestos
    log_info "Desplegando en Kubernetes..."
    kubectl apply -f kubernetes/postgres-deployment.yaml
    kubectl apply -f kubernetes/airflow-deployment.yaml
    kubectl apply -f kubernetes/grafana-deployment.yaml
    
    # Esperar a que los pods estén listos
    log_info "Esperando a que los pods estén listos..."
    kubectl wait --for=condition=ready pod -l app=postgres -n businessmetrics --timeout=300s
    
    # Verificar deployment
    log_info "Verificando deployments..."
    kubectl get all -n businessmetrics
    
    echo ""
    log_info "✅ Setup con Kubernetes completado!"
    echo ""
    echo "Para acceder a los servicios, ejecute:"
    echo "  minikube service postgres-service -n businessmetrics"
    echo "  minikube service airflow-webserver-service -n businessmetrics"
    echo "  minikube service grafana-service -n businessmetrics"
    echo ""
}

# ============================================
# INICIALIZAR BASE DE DATOS
# ============================================
init_database() {
    log_step "Inicializando base de datos..."
    
    # Esperar a que PostgreSQL esté listo
    log_info "Esperando a PostgreSQL..."
    sleep 10
    
    # Ejecutar scripts de inicialización
    log_info "Ejecutando scripts de schema..."
    
    if [ "$1" == "docker" ]; then
        docker exec -i businessmetrics-postgres psql -U admin -d postgres < database/schema/01_create_tables.sql
        docker exec -i businessmetrics-postgres psql -U admin -d businessmetrics < database/schema/02_create_indexes.sql
        docker exec -i businessmetrics-postgres psql -U admin -d businessmetrics < database/schema/03_create_users.sql
        docker exec -i businessmetrics-postgres psql -U admin -d businessmetrics < database/data/insert_sample_data.sql
    else
        # Para Kubernetes
        POD_NAME=$(kubectl get pod -n businessmetrics -l app=postgres -o jsonpath="{.items[0].metadata.name}")
        kubectl exec -i $POD_NAME -n businessmetrics -- psql -U admin -d postgres < database/schema/01_create_tables.sql
        kubectl exec -i $POD_NAME -n businessmetrics -- psql -U admin -d businessmetrics < database/schema/02_create_indexes.sql
        kubectl exec -i $POD_NAME -n businessmetrics -- psql -U admin -d businessmetrics < database/schema/03_create_users.sql
        kubectl exec -i $POD_NAME -n businessmetrics -- psql -U admin -d businessmetrics < database/data/insert_sample_data.sql
    fi
    
    log_info "✅ Base de datos inicializada correctamente"
}

# ============================================
# MENÚ PRINCIPAL
# ============================================
echo "Seleccione el método de deployment:"
echo "  1) Docker Compose (Recomendado para desarrollo)"
echo "  2) Kubernetes (Producción simulada)"
echo "  3) Ambos"
echo ""
read -p "Opción [1-3]: " opcion

case $opcion in
    1)
        setup_docker
        init_database "docker"
        ;;
    2)
        setup_kubernetes
        init_database "kubernetes"
        ;;
    3)
        setup_docker
        setup_kubernetes
        init_database "docker"
        ;;
    *)
        log_error "Opción inválida"
        exit 1
        ;;
esac

echo ""
echo "=========================================="
echo "  ✅ Setup Completado Exitosamente"
echo "=========================================="
echo ""
log_info "Siguiente paso: Verificar los servicios y acceder a las interfaces web"
echo ""
