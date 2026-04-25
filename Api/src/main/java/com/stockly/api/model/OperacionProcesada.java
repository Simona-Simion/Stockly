package com.stockly.api.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Data
@Table(name = "operaciones_procesadas")
public class OperacionProcesada {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(name = "uuid_operacion", nullable = false, unique = true)
    private String uuidOperacion;

    @Column(name = "tipo_operacion", nullable = false)
    private String tipoOperacion;

    @Column(name = "fecha_procesada", nullable = false)
    private LocalDateTime fechaProcesada = LocalDateTime.now();

    @Column(name = "referencia_id")
    private String referenciaId;
}
