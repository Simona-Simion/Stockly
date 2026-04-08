package com.stockly.api.service.impl;

import com.stockly.api.dto.ProductoRequest;
import com.stockly.api.exception.ResourceNotFoundException;
import com.stockly.api.model.Categoria;
import com.stockly.api.model.Producto;
import com.stockly.api.model.UnidadMedida;
import com.stockly.api.repository.CategoriaRepository;
import com.stockly.api.repository.ProductoRepository;
import com.stockly.api.repository.UnidadMedidaRepository;
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
    private final CategoriaRepository categoriaRepository;
    private final UnidadMedidaRepository unidadMedidaRepository;

    @Override
    @Transactional(readOnly = true)
    public List<Producto> findAll() {
        return repository.findAllActivosConRelaciones();
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
    public Producto saveFromRequest(ProductoRequest req) {
        Categoria categoria = categoriaRepository.findById(req.getCategoriaId())
                .orElseThrow(() -> new ResourceNotFoundException("Categoria", "id", req.getCategoriaId()));
        UnidadMedida unidad = unidadMedidaRepository.findById(req.getUnidadMedidaId())
                .orElseThrow(() -> new ResourceNotFoundException("UnidadMedida", "id", req.getUnidadMedidaId()));

        Producto producto = new Producto();
        producto.setNombre(req.getNombre());
        producto.setCodigoBarras(req.getCodigoBarras());
        producto.setStockActual(req.getStockActual());
        producto.setStockMinimo(req.getStockMinimo());
        producto.setPrecioUnidad(req.getPrecioUnidad());
        producto.setCategoria(categoria);
        producto.setUnidadMedida(unidad);
        producto.setActivo(true);
        return save(producto);
    }

    @Override
    public Producto updateFromRequest(UUID id, ProductoRequest req) {
        Categoria categoria = categoriaRepository.findById(req.getCategoriaId())
                .orElseThrow(() -> new ResourceNotFoundException("Categoria", "id", req.getCategoriaId()));
        UnidadMedida unidad = unidadMedidaRepository.findById(req.getUnidadMedidaId())
                .orElseThrow(() -> new ResourceNotFoundException("UnidadMedida", "id", req.getUnidadMedidaId()));

        Producto p = new Producto();
        p.setNombre(req.getNombre());
        p.setCodigoBarras(req.getCodigoBarras());
        p.setStockActual(req.getStockActual());
        p.setStockMinimo(req.getStockMinimo());
        p.setPrecioUnidad(req.getPrecioUnidad());
        p.setCategoria(categoria);
        p.setUnidadMedida(unidad);
        return update(id, p);
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