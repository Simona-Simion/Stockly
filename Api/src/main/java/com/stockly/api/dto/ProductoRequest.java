package com.stockly.api.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.UUID;

// DTO para crear/actualizar un producto.
// Flutter envía los IDs de categoría y unidad de medida como UUIDs planos;
// el servicio los resuelve a las entidades correspondientes.
@Data
public class ProductoRequest {

    private String nombre;
    private String codigoBarras;
    private Double stockActual;
    private Double stockMinimo;
    private Double precioUnidad;

    @NotNull(message = "El id de categoría es obligatorio")
    private UUID categoriaId;

    @NotNull(message = "El id de unidad de medida es obligatorio")
    private UUID unidadMedidaId;
}
