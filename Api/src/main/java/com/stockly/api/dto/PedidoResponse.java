package com.stockly.api.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PedidoResponse {

    private UUID id;
    private UUID proveedorId;
    private String proveedorNombre;
    private LocalDateTime fecha;
    private String estado;
    private List<PedidoLineaResponse> lineas;
}
