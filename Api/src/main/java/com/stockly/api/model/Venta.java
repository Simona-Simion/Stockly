package com.stockly.api.model;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Entity
@Table(name = "ventas")
public class Venta {

    @Id
    @GeneratedValue
    private UUID id;

    // Referencia a la receta vendida (null en ventas directas de producto)
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "receta_id", nullable = true)
    private Receta receta;

    // Referencia al producto vendido directamente (null en ventas por receta)
    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "producto_id", nullable = true)
    private Producto producto;

    @Column(nullable = false)
    private Integer cantidad;

    @Column(name = "precio_total", nullable = false)
    private Double precioTotal;

    // Origen de la venta: MANUAL, TPV_WEBHOOK, TPV_FICHERO
    @Column(nullable = false)
    private String origen = "MANUAL";

    @Column(nullable = false)
    private LocalDateTime fecha = LocalDateTime.now();
}
