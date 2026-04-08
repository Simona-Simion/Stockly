package com.stockly.api.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.UUID;

@Data
public class LineaRecetaRequest {

    @NotNull(message = "El id de producto es obligatorio")
    private UUID productoId;

    @NotNull(message = "La cantidad es obligatoria")
    private Double cantidad;

    private UUID unidadMedidaId;
}
