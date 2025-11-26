# businessmetrics-pro
Sistema de Análisis de Métricas de Negocio - Proyecto Final Admin BD
# 📊 BusinessMetrics Pro

Sistema de Análisis de Métricas de Negocio con PostgreSQL, Docker, Kubernetes, Airflow y Grafana.

## 🎯 Descripción del Proyecto

BusinessMetrics Pro es un sistema completo de administración y análisis de bases de datos que implementa:
- Gestión de base de datos PostgreSQL
- Respaldos automatizados con Apache Airflow
- Monitoreo en tiempo real con Grafana
- Orquestación con Kubernetes
- Seguridad y control de acceso

## 🏗️ Arquitectura
```
┌─────────────────────────────────────────────────────┐
│                  Kubernetes Cluster                  │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐   │
│  │ PostgreSQL │  │  Airflow   │  │  Grafana   │   │
│  │    Pod     │  │    Pod     │  │    Pod     │   │
│  └────────────┘  └────────────┘  └────────────┘   │
└─────────────────────────────────────────────────────┘
```

## 📋 Requisitos Previos

- Docker Desktop
- Kubernetes (Minikube)
- Git
- Python 3.8+

## 🚀 Instalación Rápida

### 1. Clonar el repositorio
```bash
git clone https://github.com/TU_USUARIO/businessmetrics-pro.git
cd businessmetrics-pro
```

### 2. Iniciar Kubernetes
```bash
minikube start --driver=docker --memory=4096 --cpus=2
```

### 3. Desplegar con Docker Compose (Para desarrollo local)
```bash
docker compose -f docker/docker-compose.yml up -d
```

### 4. Desplegar en Kubernetes (Para producción simulada)
```bash
kubectl apply -f kubernetes/
```

## 📊 Acceso a los Servicios

- **PostgreSQL**: `localhost:5432`
  - Usuario: `admin`
  - Base de datos: `businessmetrics`
  
- **Airflow**: `http://localhost:8080`
  - Usuario: `admin`
  - Password: `admin`
  
- **Grafana**: `http://localhost:3000`
  - Usuario: `admin`
  - Password: `admin`

## 📁 Estructura del Proyecto
```
businessmetrics-pro/
├── README.md                      # Este archivo
├── docs/                          # Documentación del proyecto
│   ├── documento_proyecto.pdf     # Documento escrito
│   ├── presentacion.pptx          # Presentación
│   └── diagramas/                 # Diagramas del sistema
├── database/                      # Base de datos
│   ├── schema/                    # Esquemas y tablas
│   ├── data/                      # Datos de ejemplo
│   └── backup/                    # Scripts de respaldo
├── docker/                        # Configuración Docker
│   └── docker-compose.yml
├── kubernetes/                    # Manifiestos K8s
│   ├── postgres-deployment.yaml
│   ├── airflow-deployment.yaml
│   └── grafana-deployment.yaml
├── airflow/                       # DAGs de Airflow
│   └── dags/
├── grafana/                       # Dashboards
│   └── dashboards/
└── scripts/                       # Scripts auxiliares
```

## 🔧 Características Implementadas

### ✅ Administración de BD
- Roles y usuarios
- Permisos granulares
- Gestión de conexiones

### ✅ Espacios Lógicos y Físicos
- Tablespaces personalizados
- Optimización de almacenamiento
- Particionamiento de tablas

### ✅ Respaldo y Recuperación
- Respaldos completos automatizados
- Respaldos incrementales
- Point-in-Time Recovery (PITR)
- Respaldos en caliente y frío

### ✅ Monitoreo y Seguridad
- Dashboards de Grafana
- Métricas de rendimiento
- Autenticación y autorización
- Encriptación de datos

### ✅ Afinación
- Índices optimizados
- Queries optimizadas
- Configuración del servidor
- Análisis de planes de ejecución

## 📈 Dashboards Disponibles

1. **Métricas de Ventas**: Análisis de ventas por región, producto y tiempo
2. **Análisis de Clientes**: Comportamiento y segmentación
3. **Rendimiento de BD**: CPU, memoria, conexiones, queries
4. **Sistema de Respaldos**: Estado y historial de backups

## 🛠️ Uso

### Ejecutar respaldo manual
```bash
docker exec -it postgres pg_dump -U admin businessmetrics > backup.sql
```

### Ver logs de Airflow
```bash
kubectl logs -f deployment/airflow-webserver
```

### Acceder a PostgreSQL
```bash
docker exec -it postgres psql -U admin -d businessmetrics
```

## 👥 Autor

[Tu Nombre] - Proyecto Final Administración de Bases de Datos

## 📄 Licencia

Este proyecto es de uso académico.
