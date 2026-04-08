package com.stockly.api.service;

import com.stockly.api.dto.ProductoRequest;
import com.stockly.api.model.Producto;

import java.util.List;
import java.util.UUID;

public interface ProductoService {

    List<Producto> findAll();

    Producto findById(UUID id);

    Producto save(Producto producto);

    Producto saveFromRequest(ProductoRequest request);

    Producto update(UUID id, Producto producto);

    Producto updateFromRequest(UUID id, ProductoRequest request);

    void delete(UUID id);

    Producto findByCodigoBarras(String codigo);
}
