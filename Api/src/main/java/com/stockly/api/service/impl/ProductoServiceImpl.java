package com.stockly.api.service.impl;

import com.stockly.api.exception.ResourceNotFoundException;
import com.stockly.api.model.Producto;
import com.stockly.api.repository.ProductoRepository;
import com.stockly.api.service.ProductoService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional
public class ProductoServiceImpl implements ProductoService {

    private final ProductoRepository repository;

    @Override
    @Transactional(readOnly = true)
    public List<Producto> findAll() {
        return repository.findAll();
    }

    @Override
    @Transactional(readOnly = true)
    public Producto findById(UUID id) {
        return repository.findById(id).orElseThrow(()
                -> new ResourceNotFoundException("Producto", "id", id));

    }

    @Override
    public Producto save(Producto producto) {
        // Validar que no exista otro producto con el mismo código de barras
        if (producto.getCodigoBarras() != null && !producto.getCodigoBarras().isEmpty()) {
            repository.findByCodigoBarras(producto.getCodigoBarras())
                    .ifPresent(p -> {
                        throw new RuntimeException("Ya existe un producto con el código de barras: " + producto.getCodigoBarras());
                    });
        }
        return repository.save(producto);
    }

    @Override
    public Producto update(UUID id, Producto producto) {
        Producto existente = findById(id);

        // Validar código de barras si se está actualizando
        if (producto.getCodigoBarras() != null && !producto.getCodigoBarras().isEmpty()) {
            repository.findByCodigoBarras(producto.getCodigoBarras())
                    .ifPresent(p -> {
                        if (!p.getId().equals(id)) {
                            throw new RuntimeException("Ya existe otro producto con el código de barras: " + producto.getCodigoBarras());
                        }
                    });
        }

        existente.setNombre(producto.getNombre());
        existente.setCategoria(producto.getCategoria());
        existente.setCodigoBarras(producto.getCodigoBarras());
        existente.setStockActual(producto.getStockActual());
        existente.setStockMinimo(producto.getStockMinimo());
        existente.setUnidadMedida(producto.getUnidadMedida());
        existente.setPrecioUnidad(producto.getPrecioUnidad());

        if (producto.getActivo() != null) {
            existente.setActivo(producto.getActivo());
        }

        return repository.save(existente);
    }

    @Override
    public void delete(UUID id) {
        Producto producto = findById(id);
        // Borrado lógico: nunca se elimina físicamente de la base de datos
        producto.setActivo(false);
        repository.save(producto);
    }

    @Override
    @Transactional(readOnly = true)
    public Producto findByCodigoBarras(String codigo) {
        return repository.findByCodigoBarras(codigo)
                .orElseThrow(() -> new ResourceNotFoundException("Producto", "código de barras", codigo));
    }
}