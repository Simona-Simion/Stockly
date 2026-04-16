package com.stockly.api.controller;

import com.stockly.api.dto.MovimientoDTO;
import com.stockly.api.model.MovimientoStock;
import com.stockly.api.service.MovimientoStockService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/movimientos")
@RequiredArgsConstructor
public class MovimientoStockController {

    private final MovimientoStockService service;

    @PreAuthorize("hasAnyRole('ADMIN','EMPLEADO')")
    @GetMapping
    public ResponseEntity<List<MovimientoDTO>> listar() {
        return ResponseEntity.ok(service.listar());
    }

    @PreAuthorize("hasAnyRole('ADMIN','EMPLEADO')")
    @GetMapping("/producto/{productoId}")
    public ResponseEntity<List<MovimientoDTO>> listarPorProducto(
            @PathVariable UUID productoId) {
        return ResponseEntity.ok(service.listarPorProducto(productoId));
    }

    @PreAuthorize("hasAnyRole('ADMIN','EMPLEADO')")
    @PostMapping
    public ResponseEntity<MovimientoStock> registrar(@RequestBody MovimientoStock movimiento) {
        return ResponseEntity.ok(service.registrarMovimiento(movimiento));
    }
}
