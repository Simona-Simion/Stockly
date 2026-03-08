package com.horecastock.api.controller;

import com.horecastock.api.dto.ApiResponse;
import com.horecastock.api.dto.VentaEscandalloRequest;
import com.horecastock.api.model.Venta;
import com.horecastock.api.service.VentaService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/ventas")
@RequiredArgsConstructor
public class VentaController {

    private final VentaService ventaService;

    @PostMapping
    public ResponseEntity<ApiResponse<Venta>> registrarVenta(@RequestBody VentaEscandalloRequest request) {
        Venta venta = ventaService.registrarVenta(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Venta registrada correctamente", venta));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<Venta>>> listarVentas() {
        List<Venta> ventas = ventaService.listarVentas();
        return ResponseEntity.ok(ApiResponse.success(ventas));
    }
}
