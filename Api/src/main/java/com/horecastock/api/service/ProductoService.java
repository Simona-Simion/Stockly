package com.horecastock.api.service;


import com.horecastock.api.model.Producto;

import java.util.List;
import java.util.UUID;

public interface ProductoService {

    List<Producto> findAll();

    Producto findById(UUID id);

    Producto save(Producto producto);

    Producto update(UUID id, Producto producto);

    void delete(UUID id);

    Producto findByCodigoBarras(String codigo);
}
