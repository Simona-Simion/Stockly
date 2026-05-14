package com.stockly.api.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PedidoLineaResponse {

    private UUID id;
    private UUID productoId;
    private String productoNombre;
    private Double cantidad;
    private Double precioUnitario;
}
