package com.stockly.api.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.List;

@Data
public class RecetaRequest {

    @NotBlank(message = "El nombre es obligatorio")
    private String nombre;

    private String descripcion;

    @NotNull(message = "El precio de venta es obligatorio")
    private Double precioVenta;

    @NotEmpty(message = "La receta debe tener al menos un ingrediente")
    @Valid
    private List<LineaRecetaRequest> lineas;
}
