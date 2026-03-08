package com.horecastock.api.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.Data;

import java.util.UUID;

@Data
@Entity
@Table(name = "lineas_receta")
public class LineaReceta {

    @Id
    @GeneratedValue
    private UUID id;

    // Relación con la receta padre — ignorada en JSON para evitar referencia circular
    @JsonIgnore
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "receta_id", nullable = false)
    private Receta receta;

    // Producto que se descuenta al vender esta receta
    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "producto_id", nullable = false)
    private Producto producto;

    // Cantidad exacta a descontar del stock (ej: 0.050 para 5cl de ron)
    @Column(nullable = false)
    private Double cantidad;
}
