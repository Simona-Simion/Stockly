package com.stockly.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Data;

import java.util.UUID;

@Data
public class EntradaStockRequest {

    @NotNull(message = "El producto es obligatorio")
    private UUID productoId;

    @NotNull(message = "La cantidad es obligatoria")
    @Positive(message = "La cantidad debe ser mayor que 0")
    private Double cantidad;

    private String motivo;

    private String origen;

    @NotBlank(message = "uuidOperacion es obligatorio")
    private String uuidOperacion;
}
