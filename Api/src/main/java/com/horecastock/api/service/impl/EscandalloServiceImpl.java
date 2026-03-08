package com.horecastock.api.service.impl;

import com.horecastock.api.exception.ResourceNotFoundException;
import com.horecastock.api.exception.StockInsuficienteException;
import com.horecastock.api.model.LineaReceta;
import com.horecastock.api.model.MovimientoStock;
import com.horecastock.api.model.Producto;
import com.horecastock.api.model.Receta;
import com.horecastock.api.repository.MovimientoStockRepository;
import com.horecastock.api.repository.ProductoRepository;
import com.horecastock.api.service.AlertaService;
import com.horecastock.api.service.EscandalloService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class EscandalloServiceImpl implements EscandalloService {

    private final ProductoRepository productoRepository;
    private final MovimientoStockRepository movimientoStockRepository;
    private final AlertaService alertaService;

    @Override
    @Transactional
    public void aplicarEscandallo(Receta receta, Integer cantidad, String origen) {
        List<LineaReceta> lineas = receta.getLineas();

        // ─── FASE 1: VALIDACIÓN COMPLETA ─────────────────────────────────────────
        // Se validan TODOS los ingredientes antes de tocar ningún stock.
        // Si alguno falla, se lanza excepción y el @Transactional hace rollback total.
        for (LineaReceta linea : lineas) {
            Producto producto = linea.getProducto();

            // Guarda defensiva: un ingrediente con producto null indica datos corruptos
            if (producto == null) {
                throw new ResourceNotFoundException("Producto", "lineaReceta", linea.getId());
            }

            double cantidadNecesaria = linea.getCantidad() * cantidad;

            if (producto.getStockActual() < cantidadNecesaria) {
                throw new StockInsuficienteException(
                    "Stock insuficiente para '" + producto.getNombre() + "'. " +
                    "Disponible: " + producto.getStockActual() +
                    ", necesario: " + cantidadNecesaria
                );
            }
        }

        // ─── FASE 2: DESCUENTO Y REGISTRO ────────────────────────────────────────
        // Solo se llega aquí si TODOS los ingredientes tienen stock suficiente.
        for (LineaReceta linea : lineas) {
            Producto producto = linea.getProducto();
            double cantidadNecesaria = linea.getCantidad() * cantidad;

            // Descontar el stock del ingrediente
            producto.setStockActual(producto.getStockActual() - cantidadNecesaria);
            productoRepository.save(producto);

            // Registrar el movimiento de stock
            MovimientoStock movimiento = new MovimientoStock();
            movimiento.setProducto(producto);
            movimiento.setTipo("VENTA");
            movimiento.setCantidad(cantidadNecesaria);
            movimiento.setOrigen(origen);
            movimiento.setMotivo("Escandallo: " + receta.getNombre());
            movimientoStockRepository.save(movimiento);

            // Comprobar si el stock del ingrediente bajó del mínimo tras el descuento
            alertaService.comprobarStockMinimo(producto);
        }
    }
}
