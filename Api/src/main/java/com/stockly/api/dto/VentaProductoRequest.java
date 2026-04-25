package com.stockly.api.dto;

import lombok.Data;

import java.util.UUID;

@Data
public class VentaProductoRequest {

    // ID del producto a vender directamente (sin receta)
    private UUID productoId;

    // Número de unidades a vender
    private Integer cantidad;

    // Identificador opcional para idempotencia.
    private String uuidOperacion;
}
