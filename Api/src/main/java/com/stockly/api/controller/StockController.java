package com.stockly.api.controller;

import com.stockly.api.dto.ApiResponse;
import com.stockly.api.dto.EntradaStockRequest;
import com.stockly.api.dto.MovimientoDTO;
import com.stockly.api.service.EntradaStockService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/stock")
@RequiredArgsConstructor
public class StockController {

    private final EntradaStockService entradaStockService;

    @PreAuthorize("hasAnyRole('ADMIN','EMPLEADO')")
    @PostMapping("/entrada")
    public ResponseEntity<ApiResponse<MovimientoDTO>> registrarEntrada(
            @Valid @RequestBody EntradaStockRequest request
    ) {
        MovimientoDTO movimiento = entradaStockService.registrarEntrada(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Entrada de stock registrada correctamente", movimiento));
    }
}
