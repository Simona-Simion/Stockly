package com.stockly.api.service;

import com.stockly.api.model.MovimientoStock;
import com.stockly.api.repository.MovimientoStockRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class MovimientoStockService {

    private final MovimientoStockRepository repository;

    public MovimientoStock registrarMovimiento(MovimientoStock movimiento) {
        return repository.save(movimiento);
    }
}
