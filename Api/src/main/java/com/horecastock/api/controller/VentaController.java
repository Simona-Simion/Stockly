package com.horecastock.api.controller;


import com.horecastock.api.dto.VentaRequest;
import com.horecastock.api.service.VentaService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/ventas")
public class VentaController {

    private final VentaService ventaService;

    public VentaController(VentaService ventaService) {
        this.ventaService = ventaService;
    }

    @PostMapping
    public ResponseEntity<String> registrarVenta(@RequestBody VentaRequest request) {
        ventaService.registrarVenta(request);
        return ResponseEntity.ok("Venta registrada correctamente");
    }
}
