package com.horecastock.api.controller;

import com.horecastock.api.model.MovimientoStock;
import com.horecastock.api.service.MovimientoStockService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/movimientos")
@RequiredArgsConstructor
public class MovimientoStockController {

    private final MovimientoStockService service;

    @PostMapping
    public MovimientoStock registrar(@RequestBody MovimientoStock movimiento) {
        return service.registrarMovimiento(movimiento);
    }
}
