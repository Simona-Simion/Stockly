package com.stockly.api.service;

import com.stockly.api.dto.EntradaStockRequest;
import com.stockly.api.dto.MovimientoDTO;

public interface EntradaStockService {

    MovimientoDTO registrarEntrada(EntradaStockRequest request);
}
