package com.horecastock.api.exception;

// Lanzada cuando algún ingrediente de una receta no tiene stock suficiente.
// Provoca HTTP 409 Conflict y rollback completo de la transacción.
public class StockInsuficienteException extends RuntimeException {

    public StockInsuficienteException(String message) {
        super(message);
    }
}
