package com.stockly.api.exception;

public class ProductoDuplicadoException extends RuntimeException {

    public ProductoDuplicadoException(String message) {
        super(message);
    }
}
