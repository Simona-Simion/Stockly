package com.stockly.api.service.impl;

import com.stockly.api.exception.ResourceNotFoundException;
import com.stockly.api.exception.StockInsuficienteException;
import com.stockly.api.model.LineaReceta;
import com.stockly.api.model.MovimientoStock;
import com.stockly.api.model.Producto;
import com.stockly.api.model.Receta;
import com.stockly.api.model.UnidadMedida;
import com.stockly.api.repository.MovimientoStockRepository;
import com.stockly.api.repository.ProductoRepository;
import com.stockly.api.service.AlertaService;
import com.stockly.api.service.EscandalloService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Slf4j
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

            double cantidadNecesaria = convertirCantidad(linea.getCantidad() * cantidad, producto);

            log.info("[escandallo] {} | stock={} | necesario={}",
                    producto.getNombre(), producto.getStockActual(), cantidadNecesaria);

            if (producto.getStockActual() < cantidadNecesaria) {
                log.warn("[escandallo] STOCK INSUFICIENTE — {} | stock={} | necesario={}",
                        producto.getNombre(), producto.getStockActual(), cantidadNecesaria);
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
            double cantidadNecesaria = convertirCantidad(linea.getCantidad() * cantidad, producto);

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

    // Convierte la cantidad (en unidades base de la receta) a las unidades del producto.
    // Si la unidad del producto tiene capacidad_base definida, divide entre ella.
    // Ejemplo: 4 cl de J&B con botella de 70 cl → 4/70 = 0.057 botellas.
    private double convertirCantidad(double cantidadBaseReceta, Producto producto) {
        UnidadMedida unidad = producto.getUnidadMedida();
        if (unidad != null && unidad.getCapacidadBase() != null && unidad.getCapacidadBase() > 0) {
            return cantidadBaseReceta / unidad.getCapacidadBase();
        }
        return cantidadBaseReceta;
    }
}
