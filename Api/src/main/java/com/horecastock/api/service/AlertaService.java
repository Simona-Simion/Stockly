package com.horecastock.api.service;

import com.horecastock.api.model.Producto;

import java.util.List;

public interface AlertaService {

    // Comprueba si el stock del producto bajó del mínimo y lanza alerta si corresponde
    void comprobarStockMinimo(Producto producto);

    // Devuelve todos los productos cuyo stock actual está por debajo del mínimo
    List<Producto> obtenerProductosBajoMinimo();
}
