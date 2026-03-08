package com.horecastock.api.controller;

import com.horecastock.api.dto.ApiResponse;
import com.horecastock.api.model.Producto;
import com.horecastock.api.service.AlertaService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/alertas")
@RequiredArgsConstructor
public class AlertaController {

    private final AlertaService alertaService;

    @GetMapping("/stock-minimo")
    public ResponseEntity<ApiResponse<List<Producto>>> getProductosBajoMinimo() {
        List<Producto> productos = alertaService.obtenerProductosBajoMinimo();
        return ResponseEntity.ok(ApiResponse.success(productos));
    }
}
