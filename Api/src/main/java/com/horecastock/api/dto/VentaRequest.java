package com.horecastock.api.dto;



import lombok.Data;
import java.util.UUID;

@Data
public class VentaRequest {

    private UUID idProducto;
    private Integer cantidad;
}
