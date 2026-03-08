package com.horecastock.api.model;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Data
@Table(name = "movimientos_stock")
public class MovimientoStock {

    @Id
    @GeneratedValue
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "producto_id", nullable = false)
    private Producto producto;

    private String tipo;

    private Double cantidad;

    // Descripción opcional del movimiento (motivo de merma, ajuste, etc.)
    private String motivo;

    private LocalDateTime fecha = LocalDateTime.now();

    private String origen;
}
