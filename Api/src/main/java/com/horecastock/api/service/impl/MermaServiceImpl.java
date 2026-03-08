package com.horecastock.api.service.impl;

import com.horecastock.api.dto.MermaRequest;
import com.horecastock.api.exception.ResourceNotFoundException;
import com.horecastock.api.exception.StockInsuficienteException;
import com.horecastock.api.model.MovimientoStock;
import com.horecastock.api.model.Producto;
import com.horecastock.api.repository.MovimientoStockRepository;
import com.horecastock.api.repository.ProductoRepository;
import com.horecastock.api.service.AlertaService;
import com.horecastock.api.service.MermaService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class MermaServiceImpl implements MermaService {

    private final ProductoRepository productoRepository;
    private final MovimientoStockRepository movimientoStockRepository;
    private final AlertaService alertaService;

    @Override
    @Transactional
    public void registrarMerma(MermaRequest request) {

        // 1. Buscar el producto y verificar que está activo
        Producto producto = productoRepository.findById(request.getProductoId())
                .orElseThrow(() -> new ResourceNotFoundException("Producto", "id", request.getProductoId()));

        if (!producto.getActivo()) {
            throw new RuntimeException("El producto '" + producto.getNombre() + "' no está activo");
        }

        // 2. Verificar que hay stock suficiente para absorber la merma
        if (producto.getStockActual() < request.getCantidad()) {
            throw new StockInsuficienteException(
                "Stock insuficiente para registrar la merma de '" + producto.getNombre() + "'. " +
                "Disponible: " + producto.getStockActual() + ", merma indicada: " + request.getCantidad()
            );
        }

        // 3. Descontar la cantidad mermada del stock
        producto.setStockActual(producto.getStockActual() - request.getCantidad());
        productoRepository.save(producto);

        // 4. Registrar el movimiento de stock tipo MERMA con el motivo
        MovimientoStock movimiento = new MovimientoStock();
        movimiento.setProducto(producto);
        movimiento.setTipo("MERMA");
        movimiento.setCantidad(request.getCantidad());
        movimiento.setOrigen("MANUAL");
        movimiento.setMotivo(request.getMotivo());
        movimientoStockRepository.save(movimiento);

        // 5. Comprobar si el stock bajó del mínimo y lanzar alerta si corresponde
        alertaService.comprobarStockMinimo(producto);
    }
}
