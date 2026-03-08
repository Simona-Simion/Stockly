package com.horecastock.api.service;

import com.horecastock.api.model.Receta;

public interface EscandalloService {

    // Valida el stock de todos los ingredientes y los descuenta si hay suficiente.
    // Lanza StockInsuficienteException si cualquier ingrediente falla → rollback completo.
    void aplicarEscandallo(Receta receta, Integer cantidad, String origen);
}
