package com.stockly.api.service;

import com.stockly.api.dto.LineaRecetaRequest;
import com.stockly.api.dto.RecetaRequest;
import com.stockly.api.exception.ResourceNotFoundException;
import com.stockly.api.model.LineaReceta;
import com.stockly.api.model.Producto;
import com.stockly.api.model.Receta;
import com.stockly.api.model.UnidadMedida;
import com.stockly.api.repository.ProductoRepository;
import com.stockly.api.repository.RecetaRepository;
import com.stockly.api.repository.UnidadMedidaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional
public class RecetaService {

    private final RecetaRepository repository;
    private final ProductoRepository productoRepository;
    private final UnidadMedidaRepository unidadMedidaRepository;

    @Transactional(readOnly = true)
    public List<Receta> listar() {
        return repository.findByActivoTrue();
    }

    @Transactional(readOnly = true)
    public Receta obtener(UUID id) {
        return repository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Receta", "id", id));
    }

    public Receta crear(RecetaRequest req) {
        Receta receta = new Receta();
        receta.setNombre(req.getNombre());
        receta.setDescripcion(req.getDescripcion());
        receta.setPrecioVenta(req.getPrecioVenta());
        receta.setActivo(true);

        List<LineaReceta> lineas = req.getLineas().stream()
                .map(lineaReq -> buildLinea(lineaReq, receta))
                .toList();
        receta.setLineas(lineas);

        return repository.save(receta);
    }

    public Receta actualizar(UUID id, RecetaRequest req) {
        Receta existente = obtener(id);
        existente.setNombre(req.getNombre());
        existente.setDescripcion(req.getDescripcion());
        existente.setPrecioVenta(req.getPrecioVenta());

        existente.getLineas().clear();
        req.getLineas().stream()
                .map(lineaReq -> buildLinea(lineaReq, existente))
                .forEach(existente.getLineas()::add);

        return repository.save(existente);
    }

    public void desactivar(UUID id) {
        Receta receta = obtener(id);
        receta.setActivo(false);
        repository.save(receta);
    }

    private LineaReceta buildLinea(LineaRecetaRequest req, Receta receta) {
        Producto producto = productoRepository.findById(req.getProductoId())
                .orElseThrow(() -> new ResourceNotFoundException("Producto", "id", req.getProductoId()));

        LineaReceta linea = new LineaReceta();
        linea.setReceta(receta);
        linea.setProducto(producto);
        linea.setCantidad(req.getCantidad());

        if (req.getUnidadMedidaId() != null) {
            UnidadMedida unidad = unidadMedidaRepository.findById(req.getUnidadMedidaId())
                    .orElseThrow(() -> new ResourceNotFoundException("UnidadMedida", "id", req.getUnidadMedidaId()));
            linea.setUnidadMedida(unidad);
        }

        return linea;
    }
}
