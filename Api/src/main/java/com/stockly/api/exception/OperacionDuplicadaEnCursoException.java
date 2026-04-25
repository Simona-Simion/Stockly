package com.stockly.api.exception;

public class OperacionDuplicadaEnCursoException extends RuntimeException {

    public OperacionDuplicadaEnCursoException(String message) {
        super(message);
    }
}
