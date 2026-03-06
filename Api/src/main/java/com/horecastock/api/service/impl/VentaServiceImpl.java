package com.horecastock.api.service.impl;

import com.horecastock.api.dto.VentaRequest;
import com.horecastock.api.model.MovimientoStock;
import com.horecastock.api.model.Producto;
import com.horecastock.api.model.Venta;
import com.horecastock.api.repository.MovimientoStockRepository;
import com.horecastock.api.repository.ProductoRepository;
import com.horecastock.api.repository.VentaRepository;
import com.horecastock.api.service.VentaService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class VentaServiceImpl implements VentaService {

    private final ProductoRepository productoRepository;
    private final VentaRepository ventaRepository;
    private final MovimientoStockRepository movimientoStockRepository;

    public VentaServiceImpl(ProductoRepository productoRepository,
                            VentaRepository ventaRepository,
                            MovimientoStockRepository movimientoStockRepository) {
        this.productoRepository = productoRepository;
        this.ventaRepository = ventaRepository;
        this.movimientoStockRepository = movimientoStockRepository;
    }

    @Override
    @Transactional
    public void registrarVenta(VentaRequest request) {

        // 1. Buscar el producto
        Producto producto = productoRepository.findById(request.getIdProducto())
                .orElseThrow(() -> new RuntimeException("Producto no encontrado"));

        // 2. Calcular precio total
        double precioTotal = producto.getPrecioUnidad() * request.getCantidad();

        // 3. Crear la venta
        Venta venta = new Venta();
        venta.setProducto(producto);
        venta.setCantidad(request.getCantidad());
        venta.setPrecioTotal(precioTotal);

        ventaRepository.save(venta);

        // 4. Bajar el stock
        double nuevoStock = producto.getStockActual() - request.getCantidad();

        if (nuevoStock < 0) {
            throw new RuntimeException("No hay suficiente stock para realizar la venta");
        }

        producto.setStockActual(nuevoStock);
        productoRepository.save(producto);

        // 5. Registrar movimiento de stock
        MovimientoStock movimiento = new MovimientoStock();
        movimiento.setProducto(producto);
        movimiento.setTipo("VENTA");
        movimiento.setCantidad(request.getCantidad().doubleValue());
        movimiento.setOrigen("VENTA");

        movimientoStockRepository.save(movimiento);
    }
}
