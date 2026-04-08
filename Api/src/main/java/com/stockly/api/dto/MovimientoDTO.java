package com.stockly.api.dto;

import java.time.LocalDateTime;
import java.util.UUID;

public class MovimientoDTO {

    public UUID id;
    public String tipo;
    public Double cantidad;
    public String motivo;
    public String origen;
    public LocalDateTime fecha;
    public ProductoResumen producto;

    public MovimientoDTO(UUID id, String tipo, Double cantidad,
                         String motivo, String origen, LocalDateTime fecha,
                         UUID productoId, String productoNombre) {
        this.id = id;
        this.tipo = tipo;
        this.cantidad = cantidad;
        this.motivo = motivo;
        this.origen = origen;
        this.fecha = fecha;
        this.producto = new ProductoResumen(productoId, productoNombre);
    }

    public static class ProductoResumen {
        public UUID id;
        public String nombre;

        public ProductoResumen(UUID id, String nombre) {
            this.id = id;
            this.nombre = nombre;
        }
    }
}
