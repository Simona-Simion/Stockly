package com.stockly.api.controller;

import com.stockly.api.dto.MovimientoDTO;
import com.stockly.api.model.MovimientoStock;
import com.stockly.api.service.MovimientoStockService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/movimientos")
@RequiredArgsConstructor
public class MovimientoStockController {

    private final MovimientoStockService service;

    @GetMapping
    public ResponseEntity<List<MovimientoDTO>> listar() {
        return ResponseEntity.ok(service.listar());
    }

    @GetMapping("/producto/{productoId}")
    public ResponseEntity<List<MovimientoDTO>> listarPorProducto(
            @PathVariable UUID productoId) {
        return ResponseEntity.ok(service.listarPorProducto(productoId));
    }

    @PostMapping
    public ResponseEntity<MovimientoStock> registrar(@RequestBody MovimientoStock movimiento) {
        return ResponseEntity.ok(service.registrarMovimiento(movimiento));
    }
}
