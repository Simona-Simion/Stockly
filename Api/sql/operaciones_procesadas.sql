CREATE TABLE IF NOT EXISTS operaciones_procesadas (
    id UUID PRIMARY KEY,
    uuid_operacion VARCHAR(255) NOT NULL,
    tipo_operacion VARCHAR(100) NOT NULL,
    fecha_procesada TIMESTAMP NOT NULL,
    referencia_id VARCHAR(255),
    CONSTRAINT uk_operaciones_procesadas_uuid UNIQUE (uuid_operacion)
);
