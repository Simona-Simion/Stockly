package com.stockly.api.dto;

import lombok.Data;

import java.util.UUID;

@Data
public class VentaEscandalloRequest {

    // ID de la receta a vender (no el producto — el escandallo parte de la receta)
    private UUID recetaId;

    // Número de unidades de la receta vendidas (ej: 2 Cuba Libres)
    private Integer cantidad;

    // Origen de la venta: MANUAL, TPV_WEBHOOK, TPV_FICHERO. Por defecto MANUAL.
    private String origen;
}
