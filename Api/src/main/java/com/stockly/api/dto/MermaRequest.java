package com.stockly.api.dto;

import lombok.Data;

import java.util.UUID;

@Data
public class MermaRequest {

    // Producto que sufrió la merma
    private UUID productoId;

    // Cantidad perdida (en la unidad de medida del producto)
    private Double cantidad;

    // Descripción obligatoria: rotura, caducidad, derrame, etc.
    private String motivo;
}
