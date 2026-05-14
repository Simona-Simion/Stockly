CREATE OR REPLACE VIEW v_operaciones_procesadas_detalle AS
WITH operaciones AS (
    SELECT
        op.uuid_operacion,
        op.tipo_operacion,
        op.fecha_procesada,
        op.referencia_id,
        CASE
            WHEN op.referencia_id ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
                THEN op.referencia_id::uuid
            ELSE NULL
        END AS referencia_uuid
    FROM operaciones_procesadas op
)
SELECT
    op.uuid_operacion,
    op.tipo_operacion,
    op.fecha_procesada,
    op.referencia_id,
    CASE
        WHEN op.tipo_operacion = 'venta_producto' THEN producto_venta.nombre
        WHEN op.tipo_operacion = 'merma_producto' THEN producto_merma.nombre
        WHEN op.tipo_operacion = 'entrada_producto' THEN producto_entrada.nombre
        ELSE NULL
    END AS producto_nombre,
    CASE
        WHEN op.tipo_operacion = 'venta_receta' THEN receta_venta.nombre
        ELSE NULL
    END AS receta_nombre,
    CASE
        WHEN op.tipo_operacion = 'venta_producto' THEN producto_venta.nombre
        WHEN op.tipo_operacion = 'merma_producto' THEN producto_merma.nombre
        WHEN op.tipo_operacion = 'entrada_producto' THEN producto_entrada.nombre
        WHEN op.tipo_operacion = 'venta_receta' THEN receta_venta.nombre
        ELSE NULL
    END AS nombre_referencia
FROM operaciones op
LEFT JOIN ventas venta
    ON op.tipo_operacion IN ('venta_producto', 'venta_receta')
    AND venta.id = op.referencia_uuid
LEFT JOIN productos producto_venta
    ON op.tipo_operacion = 'venta_producto'
    AND producto_venta.id = venta.producto_id
LEFT JOIN recetas receta_venta
    ON op.tipo_operacion = 'venta_receta'
    AND receta_venta.id = venta.receta_id
LEFT JOIN movimientos_stock movimiento_merma
    ON op.tipo_operacion = 'merma_producto'
    AND movimiento_merma.id = op.referencia_uuid
LEFT JOIN productos producto_merma
    ON op.tipo_operacion = 'merma_producto'
    AND producto_merma.id = movimiento_merma.producto_id
LEFT JOIN movimientos_stock movimiento_entrada
    ON op.tipo_operacion = 'entrada_producto'
    AND movimiento_entrada.id = op.referencia_uuid
LEFT JOIN productos producto_entrada
    ON op.tipo_operacion = 'entrada_producto'
    AND producto_entrada.id = movimiento_entrada.producto_id;
