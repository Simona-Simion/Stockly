package com.horecastock.api.service;

import com.horecastock.api.model.MovimientoStock;
import com.horecastock.api.repository.MovimientoStockRepository;
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
