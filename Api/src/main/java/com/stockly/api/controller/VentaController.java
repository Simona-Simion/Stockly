package com.stockly.api.controller;

import com.stockly.api.dto.ApiResponse;
import com.stockly.api.dto.VentaEscandalloRequest;
import com.stockly.api.dto.VentaProductoRequest;
import com.stockly.api.model.Venta;
import com.stockly.api.service.VentaService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/ventas")
@RequiredArgsConstructor
public class VentaController {

    private final VentaService ventaService;

    @PreAuthorize("hasAnyRole('ADMIN','EMPLEADO')")
    @PostMapping
    public ResponseEntity<ApiResponse<Venta>> registrarVenta(@RequestBody VentaEscandalloRequest request) {
        Venta venta = ventaService.registrarVenta(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Venta registrada correctamente", venta));
    }

    @PreAuthorize("hasAnyRole('ADMIN','EMPLEADO')")
    @PostMapping("/producto")
    public ResponseEntity<ApiResponse<Venta>> registrarVentaProducto(@RequestBody VentaProductoRequest request) {
        Venta venta = ventaService.registrarVentaProducto(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Venta de producto registrada correctamente", venta));
    }

    @PreAuthorize("hasAnyRole('ADMIN','EMPLEADO')")
    @GetMapping
    public ResponseEntity<ApiResponse<List<Venta>>> listarVentas() {
        List<Venta> ventas = ventaService.listarVentas();
        return ResponseEntity.ok(ApiResponse.success(ventas));
    }
}
