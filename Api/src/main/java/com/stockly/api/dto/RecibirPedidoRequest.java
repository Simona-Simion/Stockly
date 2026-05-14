package com.stockly.api.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class RecibirPedidoRequest {

    @NotBlank(message = "uuidOperacion es obligatorio")
    private String uuidOperacion;
}
