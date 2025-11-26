"""
BusinessMetrics Pro - DAG de ETL
Procesos de Extracción, Transformación y Carga de datos
"""

from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'dba_admin',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email': ['admin@businessmetrics.com'],
    'email_on_failure': True,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

def actualizar_metricas_clientes():
    """
    Actualiza las métricas calculadas de clientes
    """
    import psycopg2
    
    conn = psycopg2.connect(
        host='postgres',
        database='businessmetrics',
        user='app_user',
        password='AppUser123!Secure'
    )
    
    cursor = conn.cursor()
    
    # Actualizar total de compras y última compra
    cursor.execute("""
        UPDATE clientes.clientes c
        SET 
            total_compras = (
                SELECT COALESCE(SUM(v.total), 0)
                FROM ventas.ventas v
                WHERE v.cliente_id = c.cliente_id
            ),
            ultima_compra = (
                SELECT MAX(v.fecha_venta)
                FROM ventas.ventas v
                WHERE v.cliente_id = c.cliente_id
            );
    """)
    
    conn.commit()
    rows_updated = cursor.rowcount
    
    cursor.close()
    conn.close()
    
    print(f"✅ Métricas actualizadas para {rows_updated} clientes")

def generar_reporte_ventas():
    """
    Genera un reporte consolidado de ventas
    """
    import psycopg2
    from datetime import datetime
    
    conn = psycopg2.connect(
        host='postgres',
        database='businessmetrics',
        user='analista_ventas',
        password='Ventas123!Secure'
    )
    
    cursor = conn.cursor()
    
    # Obtener resumen de ventas del día anterior
    cursor.execute("""
        SELECT 
            COUNT(*) as total_ventas,
            SUM(total) as ingresos_totales,
            AVG(total) as ticket_promedio
        FROM ventas.ventas
        WHERE DATE(fecha_venta) = CURRENT_DATE - INTERVAL '1 day';
    """)
    
    resultado = cursor.fetchone()
    
    cursor.close()
    conn.close()
    
    print(f"📊 Reporte de ventas generado:")
    print(f"   Total ventas: {resultado[0]}")
    print(f"   Ingresos: ${resultado[1]:.2f}")
    print(f"   Ticket promedio: ${resultado[2]:.2f}")

def alertar_stock_bajo():
    """
    Alerta productos con stock bajo
    """
    import psycopg2
    
    conn = psycopg2.connect(
        host='postgres',
        database='businessmetrics',
        user='analista_inventario',
        password='Inventario123!Secure'
    )
    
    cursor = conn.cursor()
    
    cursor.execute("""
        SELECT producto_id, nombre, stock_actual, stock_minimo
        FROM inventario.productos
        WHERE stock_actual <= stock_minimo
        AND activo = true;
    """)
    
    productos_bajo_stock = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    if productos_bajo_stock:
        print("⚠️  ALERTA: Productos con stock bajo:")
        for prod in productos_bajo_stock:
            print(f"   - {prod[1]}: {prod[2]} unidades (mínimo: {prod[3]})")
    else:
        print("✅ Todos los productos tienen stock adecuado")

# ============================================
# DAG: ETL Diario
# ============================================

with DAG(
    'etl_diario',
    default_args=default_args,
    description='Procesos ETL diarios',
    schedule_interval='0 5 * * *',  # Diario a las 5 AM
    catchup=False,
    tags=['etl', 'metricas'],
) as dag:

    actualizar_clientes = PythonOperator(
        task_id='actualizar_metricas_clientes',
        python_callable=actualizar_metricas_clientes,
    )

    generar_reporte = PythonOperator(
        task_id='generar_reporte_ventas',
        python_callable=generar_reporte_ventas,
    )

    verificar_stock = PythonOperator(
        task_id='alertar_stock_bajo',
        python_callable=alertar_stock_bajo,
    )

    actualizar_clientes >> generar_reporte >> verificar_stock
