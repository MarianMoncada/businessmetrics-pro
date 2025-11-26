-- ============================================
-- BusinessMetrics Pro - Datos de Ejemplo
-- Inserción de Datos para Testing y Demo
-- ============================================

\c businessmetrics;

-- ============================================
-- LIMPIAR DATOS EXISTENTES
-- ============================================
TRUNCATE TABLE ventas.detalle_ventas CASCADE;
TRUNCATE TABLE ventas.ventas CASCADE;
TRUNCATE TABLE inventario.productos CASCADE;
TRUNCATE TABLE inventario.categorias CASCADE;
TRUNCATE TABLE clientes.clientes CASCADE;
TRUNCATE TABLE rrhh.empleados CASCADE;

-- ============================================
-- INSERTAR CATEGORÍAS
-- ============================================
INSERT INTO inventario.categorias (nombre, descripcion) VALUES
('Electrónica', 'Dispositivos electrónicos y gadgets'),
('Computadoras', 'Laptops, desktops y accesorios'),
('Telefonía', 'Smartphones y accesorios móviles'),
('Audio', 'Audífonos, bocinas y equipos de sonido'),
('Accesorios', 'Cables, cargadores y otros accesorios'),
('Gaming', 'Consolas, videojuegos y accesorios gaming'),
('Smart Home', 'Dispositivos inteligentes para el hogar'),
('Cámaras', 'Cámaras fotográficas y de video');

-- ============================================
-- INSERTAR PRODUCTOS
-- ============================================
INSERT INTO inventario.productos (categoria_id, nombre, descripcion, precio, costo, stock_actual, stock_minimo) VALUES
-- Electrónica
(1, 'Tablet Samsung Galaxy Tab S9', 'Tablet Android de 11 pulgadas', 599.99, 450.00, 45, 10),
(1, 'Smartwatch Apple Watch Series 9', 'Reloj inteligente con GPS', 399.99, 300.00, 30, 10),
(1, 'Kindle Paperwhite', 'E-reader con pantalla de 6.8 pulgadas', 139.99, 90.00, 60, 15),

-- Computadoras
(2, 'MacBook Air M2', 'Laptop Apple con chip M2, 13 pulgadas', 1199.99, 900.00, 25, 5),
(2, 'Dell XPS 15', 'Laptop premium con Intel i7', 1499.99, 1100.00, 20, 5),
(2, 'HP Pavilion Desktop', 'PC de escritorio para uso general', 699.99, 500.00, 15, 5),
(2, 'Monitor LG UltraWide 34"', 'Monitor curvo para productividad', 449.99, 320.00, 35, 10),
(2, 'Teclado Mecánico Logitech', 'Teclado RGB para gaming', 129.99, 80.00, 50, 15),

-- Telefonía
(3, 'iPhone 15 Pro', 'Smartphone Apple 128GB', 999.99, 750.00, 40, 10),
(3, 'Samsung Galaxy S24', 'Smartphone Android flagship', 899.99, 650.00, 50, 10),
(3, 'Google Pixel 8', 'Smartphone con cámara avanzada', 699.99, 500.00, 35, 10),
(3, 'Xiaomi Redmi Note 13', 'Smartphone económico', 249.99, 180.00, 80, 20),

-- Audio
(4, 'AirPods Pro 2', 'Audífonos inalámbricos con ANC', 249.99, 180.00, 70, 20),
(4, 'Sony WH-1000XM5', 'Audífonos over-ear premium', 349.99, 250.00, 40, 10),
(4, 'JBL Flip 6', 'Bocina Bluetooth portátil', 129.99, 85.00, 55, 15),
(4, 'Bose SoundLink Mini', 'Bocina compacta de alta calidad', 199.99, 140.00, 30, 10),

-- Accesorios
(5, 'Cable USB-C 2m', 'Cable de carga rápida', 19.99, 8.00, 200, 50),
(5, 'Cargador Inalámbrico Anker', 'Cargador rápido 15W', 29.99, 15.00, 100, 30),
(5, 'Hub USB-C 7 en 1', 'Adaptador multiuerto', 49.99, 25.00, 75, 20),
(5, 'Protector de Pantalla', 'Vidrio templado universal', 9.99, 3.00, 300, 100),

-- Gaming
(6, 'PlayStation 5', 'Consola de videojuegos Sony', 499.99, 380.00, 20, 5),
(6, 'Xbox Series X', 'Consola Microsoft', 499.99, 380.00, 18, 5),
(6, 'Nintendo Switch OLED', 'Consola híbrida', 349.99, 260.00, 30, 10),
(6, 'Control DualSense', 'Control inalámbrico PS5', 69.99, 45.00, 60, 20),

-- Smart Home
(7, 'Echo Dot 5ta Gen', 'Asistente virtual Amazon', 49.99, 30.00, 90, 25),
(7, 'Google Nest Hub', 'Display inteligente con Asistente', 99.99, 65.00, 45, 15),
(7, 'Ring Video Doorbell', 'Timbre con cámara', 99.99, 60.00, 40, 10),
(7, 'Philips Hue Starter Kit', 'Kit de luces inteligentes', 199.99, 130.00, 35, 10),

-- Cámaras
(8, 'Canon EOS R6', 'Cámara mirrorless profesional', 2499.99, 1900.00, 10, 3),
(8, 'GoPro Hero 12', 'Cámara de acción 4K', 399.99, 280.00, 25, 8),
(8, 'DJI Mini 3 Pro', 'Drone con cámara 4K', 759.99, 550.00, 15, 5);

-- ============================================
-- INSERTAR CLIENTES
-- ============================================
INSERT INTO clientes.clientes (nombre, apellido, email, telefono, ciudad, pais) VALUES
('Juan', 'Pérez', 'juan.perez@email.com', '+52-555-1234', 'Ciudad de México', 'México'),
('María', 'García', 'maria.garcia@email.com', '+52-555-2345', 'Guadalajara', 'México'),
('Carlos', 'López', 'carlos.lopez@email.com', '+52-555-3456', 'Monterrey', 'México'),
('Ana', 'Martínez', 'ana.martinez@email.com', '+52-555-4567', 'Puebla', 'México'),
('Luis', 'Rodríguez', 'luis.rodriguez@email.com', '+52-555-5678', 'Tijuana', 'México'),
('Laura', 'Hernández', 'laura.hernandez@email.com', '+52-555-6789', 'León', 'México'),
('Jorge', 'González', 'jorge.gonzalez@email.com', '+52-555-7890', 'Cancún', 'México'),
('Sofia', 'Díaz', 'sofia.diaz@email.com', '+52-555-8901', 'Querétaro', 'México'),
('Miguel', 'Torres', 'miguel.torres@email.com', '+52-555-9012', 'Mérida', 'México'),
('Elena', 'Ramírez', 'elena.ramirez@email.com', '+52-555-0123', 'Aguascalientes', 'México'),
('Roberto', 'Flores', 'roberto.flores@email.com', '+52-555-1111', 'Toluca', 'México'),
('Patricia', 'Sánchez', 'patricia.sanchez@email.com', '+52-555-2222', 'Morelia', 'México'),
('Fernando', 'Morales', 'fernando.morales@email.com', '+52-555-3333', 'Chihuahua', 'México'),
('Carmen', 'Jiménez', 'carmen.jimenez@email.com', '+52-555-4444', 'Saltillo', 'México'),
('Diego', 'Ruiz', 'diego.ruiz@email.com', '+52-555-5555', 'Hermosillo', 'México');

-- ============================================
-- INSERTAR EMPLEADOS
-- ============================================
INSERT INTO rrhh.empleados (nombre, apellido, email, puesto, departamento, salario, fecha_contratacion, comision_porcentaje) VALUES
('Pedro', 'Vega', 'pedro.vega@company.com', 'Gerente de Ventas', 'Ventas', 45000.00, '2020-01-15', 5.0),
('Andrea', 'Cruz', 'andrea.cruz@company.com', 'Vendedor Senior', 'Ventas', 32000.00, '2021-03-20', 3.5),
('Ricardo', 'Ortiz', 'ricardo.ortiz@company.com', 'Vendedor', 'Ventas', 28000.00, '2022-06-10', 3.0),
('Gabriela', 'Mendoza', 'gabriela.mendoza@company.com', 'Vendedor', 'Ventas', 28000.00, '2022-08-15', 3.0),
('Alejandro', 'Castro', 'alejandro.castro@company.com', 'Analista de Inventario', 'Logística', 35000.00, '2021-02-01', 0),
('Valeria', 'Reyes', 'valeria.reyes@company.com', 'Especialista en Soporte', 'Soporte', 30000.00, '2022-04-12', 0);

-- ============================================
-- INSERTAR VENTAS Y DETALLES
-- ============================================
-- Función para generar ventas aleatorias
DO $$
DECLARE
    v_venta_id INTEGER;
    v_cliente_id INTEGER;
    v_empleado_id INTEGER;
    v_producto_id INTEGER;
    v_cantidad INTEGER;
    v_precio DECIMAL(10,2);
    v_subtotal DECIMAL(12,2);
    v_total DECIMAL(12,2);
    v_fecha TIMESTAMP;
    counter INTEGER := 0;
BEGIN
    -- Generar 100 ventas
    FOR counter IN 1..100 LOOP
        -- Seleccionar cliente y empleado aleatorios
        v_cliente_id := (SELECT cliente_id FROM clientes.clientes ORDER BY RANDOM() LIMIT 1);
        v_empleado_id := (SELECT empleado_id FROM rrhh.empleados WHERE departamento = 'Ventas' ORDER BY RANDOM() LIMIT 1);
        
        -- Generar fecha aleatoria en los últimos 12 meses
        v_fecha := CURRENT_TIMESTAMP - (RANDOM() * INTERVAL '365 days');
        
        -- Calcular subtotal inicial
        v_subtotal := 0;
        
        -- Insertar venta
        INSERT INTO ventas.ventas (cliente_id, empleado_id, fecha_venta, subtotal, impuestos, descuento, total, metodo_pago, estado, region)
        VALUES (v_cliente_id, v_empleado_id, v_fecha, 0, 0, 0, 0, 
                CASE (RANDOM() * 3)::INTEGER 
                    WHEN 0 THEN 'Tarjeta Crédito'
                    WHEN 1 THEN 'Tarjeta Débito'
                    WHEN 2 THEN 'Transferencia'
                    ELSE 'Efectivo'
                END,
                'completada',
                CASE (RANDOM() * 5)::INTEGER
                    WHEN 0 THEN 'Norte'
                    WHEN 1 THEN 'Sur'
                    WHEN 2 THEN 'Centro'
                    WHEN 3 THEN 'Este'
                    ELSE 'Oeste'
                END)
        RETURNING venta_id INTO v_venta_id;
        
        -- Insertar entre 1 y 5 productos por venta
        FOR i IN 1..(1 + (RANDOM() * 4)::INTEGER) LOOP
            v_producto_id := (SELECT producto_id FROM inventario.productos ORDER BY RANDOM() LIMIT 1);
            v_cantidad := 1 + (RANDOM() * 3)::INTEGER;
            v_precio := (SELECT precio FROM inventario.productos WHERE producto_id = v_producto_id);
            
            INSERT INTO ventas.detalle_ventas (venta_id, producto_id, cantidad, precio_unitario, subtotal, descuento)
            VALUES (v_venta_id, v_producto_id, v_cantidad, v_precio, v_cantidad * v_precio, 0);
            
            v_subtotal := v_subtotal + (v_cantidad * v_precio);
        END LOOP;
        
        -- Actualizar totales de la venta
        v_total := v_subtotal * 1.16; -- 16% IVA
        UPDATE ventas.ventas 
        SET subtotal = v_subtotal,
            impuestos = v_subtotal * 0.16,
            total = v_total
        WHERE venta_id = v_venta_id;
        
    END LOOP;
    
    RAISE NOTICE 'Se insertaron 100 ventas con sus detalles exitosamente';
END $$;

-- ============================================
-- ACTUALIZAR ESTADÍSTICAS DE CLIENTES
-- ============================================
UPDATE clientes.clientes c
SET total_compras = (
    SELECT COALESCE(SUM(v.total), 0)
    FROM ventas.ventas v
    WHERE v.cliente_id = c.cliente_id
),
ultima_compra = (
    SELECT MAX(v.fecha_venta)
    FROM ventas.ventas v
    WHERE v.cliente_id = c.cliente_id
);

-- ============================================
-- MENSAJE DE CONFIRMACIÓN
-- ============================================
DO $$
DECLARE
    total_categorias INTEGER;
    total_productos INTEGER;
    total_clientes INTEGER;
    total_empleados INTEGER;
    total_ventas INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_categorias FROM inventario.categorias;
    SELECT COUNT(*) INTO total_productos FROM inventario.productos;
    SELECT COUNT(*) INTO total_clientes FROM clientes.clientes;
    SELECT COUNT(*) INTO total_empleados FROM rrhh.empleados;
    SELECT COUNT(*) INTO total_ventas FROM ventas.ventas;
    
    RAISE NOTICE '====================================';
    RAISE NOTICE 'DATOS INSERTADOS EXITOSAMENTE';
    RAISE NOTICE '====================================';
    RAISE NOTICE 'Categorías: %', total_categorias;
    RAISE NOTICE 'Productos: %', total_productos;
    RAISE NOTICE 'Clientes: %', total_clientes;
    RAISE NOTICE 'Empleados: %', total_empleados;
    RAISE NOTICE 'Ventas: %', total_ventas;
    RAISE NOTICE '====================================';
END $$;
