package com.stockly.api.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.List;
import java.util.UUID;

@Data
public class CrearPedidoRequest {

    @NotNull(message = "El proveedor es obligatorio")
    private UUID proveedorId;

    @Valid
    @NotEmpty(message = "El pedido debe tener al menos una linea")
    private List<CrearPedidoLineaRequest> lineas;
}
