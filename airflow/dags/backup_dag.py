"""
BusinessMetrics Pro - DAG de Respaldos Automáticos
Este DAG implementa diferentes tipos de respaldos:
- Respaldo Completo (diario)
- Respaldo Incremental (cada 6 horas)
- Respaldo Diferencial (semanal)
"""

from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta
import os

# Configuración por defecto del DAG
default_args = {
    'owner': 'dba_admin',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email': ['admin@businessmetrics.com'],
    'email_on_failure': True,
    'email_on_retry': False,
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
}

# ============================================
# FUNCIONES AUXILIARES
# ============================================

def registrar_respaldo_db(tipo_respaldo, estado, **context):
    """
    Registra el respaldo en la tabla de auditoría
    """
    import psycopg2
    from datetime import datetime
    
    conn = psycopg2.connect(
        host='postgres',
        database='businessmetrics',
        user='operador_backup',
        password='Backup123!Secure'
    )
    
    cursor = conn.cursor()
    
    # Calcular tamaño del archivo si existe
    execution_date = context['execution_date'].strftime('%Y%m%d_%H%M%S')
    backup_file = f'/backup/{tipo_respaldo}_backup_{execution_date}.sql'
    tamaño = 0
    
    if os.path.exists(backup_file):
        tamaño = os.path.getsize(backup_file)
    
    # Insertar registro
    cursor.execute("""
        INSERT INTO auditoria.respaldos 
        (tipo_respaldo, fecha_inicio, fecha_fin, estado, tamaño_bytes, ruta_archivo, notas)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
    """, (
        tipo_respaldo,
        context['execution_date'],
        datetime.now(),
        estado,
        tamaño,
        backup_file,
        f'Respaldo {tipo_respaldo} ejecutado por Airflow'
    ))
    
    conn.commit()
    cursor.close()
    conn.close()
    
    print(f"✅ Respaldo registrado: {tipo_respaldo} - {estado}")

def limpiar_respaldos_antiguos(dias_antiguedad=30):
    """
    Elimina respaldos más antiguos que X días
    """
    import os
    from datetime import datetime, timedelta
    
    backup_dir = '/backup'
    fecha_limite = datetime.now() - timedelta(days=dias_antiguedad)
    
    archivos_eliminados = 0
    
    if os.path.exists(backup_dir):
        for archivo in os.listdir(backup_dir):
            ruta_completa = os.path.join(backup_dir, archivo)
            
            if os.path.isfile(ruta_completa):
                fecha_archivo = datetime.fromtimestamp(os.path.getmtime(ruta_completa))
                
                if fecha_archivo < fecha_limite:
                    os.remove(ruta_completa)
                    archivos_eliminados += 1
                    print(f"🗑️  Eliminado: {archivo}")
    
    print(f"✅ Limpieza completada: {archivos_eliminados} archivos eliminados")

def verificar_integridad_backup(**context):
    """
    Verifica que el archivo de respaldo se haya creado correctamente
    """
    import os
    
    execution_date = context['execution_date'].strftime('%Y%m%d_%H%M%S')
    backup_file = f'/backup/completo_backup_{execution_date}.sql'
    
    if os.path.exists(backup_file):
        tamaño = os.path.getsize(backup_file)
        if tamaño > 1000:  # Más de 1KB
            print(f"✅ Respaldo verificado: {tamaño} bytes")
            return True
        else:
            print(f"❌ Respaldo muy pequeño: {tamaño} bytes")
            raise Exception("El archivo de respaldo es sospechosamente pequeño")
    else:
        print(f"❌ Archivo no encontrado: {backup_file}")
        raise Exception("El archivo de respaldo no existe")

# ============================================
# DAG: RESPALDO COMPLETO (Diario)
# ============================================

with DAG(
    'backup_completo_diario',
    default_args=default_args,
    description='Respaldo completo de la base de datos (diario a las 2 AM)',
    schedule_interval='0 2 * * *',  # Diario a las 2 AM
    catchup=False,
    tags=['backup', 'completo', 'produccion'],
) as dag_completo:

    # Crear directorio de respaldos si no existe
    crear_directorio = BashOperator(
        task_id='crear_directorio_backup',
        bash_command='mkdir -p /backup && chmod 777 /backup',
    )

    # Respaldo completo usando pg_dump
    respaldo_completo = BashOperator(
        task_id='ejecutar_respaldo_completo',
        bash_command="""
        BACKUP_FILE="/backup/completo_backup_{{ execution_date.strftime('%Y%m%d_%H%M%S') }}.sql"
        echo "🔄 Iniciando respaldo completo..."
        PGPASSWORD='Admin123!Secure' pg_dump \
            -h postgres \
            -U admin \
            -d businessmetrics \
            --verbose \
            --format=plain \
            --no-owner \
            --no-privileges \
            -f "$BACKUP_FILE"
        
        echo "✅ Respaldo completo finalizado"
        ls -lh "$BACKUP_FILE"
        """,
    )

    # Comprimir respaldo
    comprimir_backup = BashOperator(
        task_id='comprimir_respaldo',
        bash_command="""
        BACKUP_FILE="/backup/completo_backup_{{ execution_date.strftime('%Y%m%d_%H%M%S') }}.sql"
        echo "🗜️  Comprimiendo respaldo..."
        gzip -f "$BACKUP_FILE"
        echo "✅ Respaldo comprimido"
        ls -lh "${BACKUP_FILE}.gz"
        """,
    )

    # Verificar integridad
    verificar_backup = PythonOperator(
        task_id='verificar_integridad',
        python_callable=verificar_integridad_backup,
        provide_context=True,
    )

    # Registrar en la base de datos
    registrar_respaldo = PythonOperator(
        task_id='registrar_respaldo_exitoso',
        python_callable=registrar_respaldo_db,
        op_kwargs={'tipo_respaldo': 'completo', 'estado': 'completado'},
        provide_context=True,
    )

    # Limpiar respaldos antiguos (mantener 30 días)
    limpiar_antiguos = PythonOperator(
        task_id='limpiar_respaldos_antiguos',
        python_callable=limpiar_respaldos_antiguos,
        op_kwargs={'dias_antiguedad': 30},
    )

    # Flujo del DAG
    crear_directorio >> respaldo_completo >> verificar_backup >> comprimir_backup >> registrar_respaldo >> limpiar_antiguos

# ============================================
# DAG: RESPALDO INCREMENTAL (Cada 6 horas)
# ============================================

with DAG(
    'backup_incremental',
    default_args=default_args,
    description='Respaldo incremental cada 6 horas',
    schedule_interval='0 */6 * * *',  # Cada 6 horas
    catchup=False,
    tags=['backup', 'incremental', 'produccion'],
) as dag_incremental:

    # Crear directorio
    crear_directorio_inc = BashOperator(
        task_id='crear_directorio_backup',
        bash_command='mkdir -p /backup/incremental && chmod 777 /backup/incremental',
    )

    # Respaldo incremental (solo cambios desde último backup)
    respaldo_incremental = BashOperator(
        task_id='ejecutar_respaldo_incremental',
        bash_command="""
        BACKUP_FILE="/backup/incremental/incremental_backup_{{ execution_date.strftime('%Y%m%d_%H%M%S') }}.sql"
        echo "🔄 Iniciando respaldo incremental..."
        
        # Obtener timestamp del último respaldo
        LAST_BACKUP=$(date -d '6 hours ago' '+%Y-%m-%d %H:%M:%S')
        
        PGPASSWORD='Admin123!Secure' pg_dump \
            -h postgres \
            -U admin \
            -d businessmetrics \
            --verbose \
            --format=plain \
            -f "$BACKUP_FILE"
        
        # Comprimir inmediatamente
        gzip -f "$BACKUP_FILE"
        
        echo "✅ Respaldo incremental completado"
        ls -lh "${BACKUP_FILE}.gz"
        """,
    )

    # Registrar
    registrar_incremental = PythonOperator(
        task_id='registrar_respaldo_incremental',
        python_callable=registrar_respaldo_db,
        op_kwargs={'tipo_respaldo': 'incremental', 'estado': 'completado'},
        provide_context=True,
    )

    crear_directorio_inc >> respaldo_incremental >> registrar_incremental

# ============================================
# DAG: RESPALDO DIFERENCIAL (Semanal)
# ============================================

with DAG(
    'backup_diferencial_semanal',
    default_args=default_args,
    description='Respaldo diferencial semanal (domingos a las 3 AM)',
    schedule_interval='0 3 * * 0',  # Domingos a las 3 AM
    catchup=False,
    tags=['backup', 'diferencial', 'produccion'],
) as dag_diferencial:

    # Crear directorio
    crear_directorio_dif = BashOperator(
        task_id='crear_directorio_backup',
        bash_command='mkdir -p /backup/diferencial && chmod 777 /backup/diferencial',
    )

    # Respaldo diferencial
    respaldo_diferencial = BashOperator(
        task_id='ejecutar_respaldo_diferencial',
        bash_command="""
        BACKUP_FILE="/backup/diferencial/diferencial_backup_{{ execution_date.strftime('%Y%m%d_%H%M%S') }}.sql"
        echo "🔄 Iniciando respaldo diferencial..."
        
        PGPASSWORD='Admin123!Secure' pg_dump \
            -h postgres \
            -U admin \
            -d businessmetrics \
            --verbose \
            --format=custom \
            --compress=9 \
            -f "$BACKUP_FILE"
        
        echo "✅ Respaldo diferencial completado"
        ls -lh "$BACKUP_FILE"
        """,
    )

    # Registrar
    registrar_diferencial = PythonOperator(
        task_id='registrar_respaldo_diferencial',
        python_callable=registrar_respaldo_db,
        op_kwargs={'tipo_respaldo': 'diferencial', 'estado': 'completado'},
        provide_context=True,
    )

    # Verificar espacio en disco
    verificar_espacio = BashOperator(
        task_id='verificar_espacio_disco',
        bash_command="""
        echo "💾 Verificando espacio en disco..."
        df -h /backup
        
        # Alertar si queda menos de 10GB
        ESPACIO_LIBRE=$(df /backup | tail -1 | awk '{print $4}' | sed 's/G//')
        if [ "$ESPACIO_LIBRE" -lt 10 ]; then
            echo "⚠️  ADVERTENCIA: Poco espacio en disco (${ESPACIO_LIBRE}GB)"
        else
            echo "✅ Espacio en disco: ${ESPACIO_LIBRE}GB"
        fi
        """,
    )

    crear_directorio_dif >> respaldo_diferencial >> registrar_diferencial >> verificar_espacio

# ============================================
# DAG: MANTENIMIENTO DE BASE DE DATOS
# ============================================

with DAG(
    'mantenimiento_bd',
    default_args=default_args,
    description='Mantenimiento y optimización de la base de datos (diario a las 4 AM)',
    schedule_interval='0 4 * * *',  # Diario a las 4 AM
    catchup=False,
    tags=['mantenimiento', 'optimizacion'],
) as dag_mantenimiento:

    # VACUUM para recuperar espacio
    vacuum_db = BashOperator(
        task_id='vacuum_database',
        bash_command="""
        echo "🧹 Ejecutando VACUUM..."
        PGPASSWORD='Admin123!Secure' psql \
            -h postgres \
            -U admin \
            -d businessmetrics \
            -c "VACUUM ANALYZE VERBOSE;"
        echo "✅ VACUUM completado"
        """,
    )

    # REINDEX para optimizar índices
    reindex_db = BashOperator(
        task_id='reindex_database',
        bash_command="""
        echo "🔄 Reindexando base de datos..."
        PGPASSWORD='Admin123!Secure' psql \
            -h postgres \
            -U admin \
            -d businessmetrics \
            -c "REINDEX DATABASE businessmetrics;"
        echo "✅ Reindexación completada"
        """,
    )

    # Actualizar estadísticas
    actualizar_stats = BashOperator(
        task_id='actualizar_estadisticas',
        bash_command="""
        echo "📊 Actualizando estadísticas..."
        PGPASSWORD='Admin123!Secure' psql \
            -h postgres \
            -U admin \
            -d businessmetrics \
            -c "ANALYZE VERBOSE;"
        echo "✅ Estadísticas actualizadas"
        """,
    )

    # Verificar integridad
    verificar_integridad = BashOperator(
        task_id='verificar_integridad_tablas',
        bash_command="""
        echo "🔍 Verificando integridad de tablas..."
        PGPASSWORD='Admin123!Secure' psql \
            -h postgres \
            -U admin \
            -d businessmetrics \
            -c "SELECT schemaname, tablename FROM pg_tables WHERE schemaname NOT IN ('pg_catalog', 'information_schema');"
        echo "✅ Verificación completada"
        """,
    )

    vacuum_db >> actualizar_stats >> reindex_db >> verificar_integridad
