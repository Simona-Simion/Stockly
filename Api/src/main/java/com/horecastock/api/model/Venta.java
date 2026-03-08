package com.horecastock.api.model;

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

    // Referencia a la receta vendida (antes apuntaba a Producto directamente)
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "receta_id", nullable = false)
    private Receta receta;

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
