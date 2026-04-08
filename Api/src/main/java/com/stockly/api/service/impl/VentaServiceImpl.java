package com.stockly.api.service.impl;

import com.stockly.api.dto.VentaEscandalloRequest;
import com.stockly.api.dto.VentaProductoRequest;
import com.stockly.api.exception.ResourceNotFoundException;
import com.stockly.api.exception.StockInsuficienteException;
import com.stockly.api.model.MovimientoStock;
import com.stockly.api.model.Producto;
import com.stockly.api.model.Receta;
import com.stockly.api.model.UnidadMedida;
import com.stockly.api.model.Venta;
import com.stockly.api.repository.MovimientoStockRepository;
import com.stockly.api.repository.ProductoRepository;
import com.stockly.api.repository.RecetaRepository;
import com.stockly.api.repository.VentaRepository;
import com.stockly.api.service.AlertaService;
import com.stockly.api.service.EscandalloService;
import com.stockly.api.service.VentaService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class VentaServiceImpl implements VentaService {

    private final RecetaRepository recetaRepository;
    private final VentaRepository ventaRepository;
    private final EscandalloService escandalloService;
    private final ProductoRepository productoRepository;
    private final MovimientoStockRepository movimientoStockRepository;
    private final AlertaService alertaService;

    @Override
    @Transactional
    public Venta registrarVenta(VentaEscandalloRequest request) {

        // 1. Buscar la receta
        Receta receta = recetaRepository.findById(request.getRecetaId())
                .orElseThrow(() -> new ResourceNotFoundException("Receta", "id", request.getRecetaId()));

        // 2. Verificar que la receta está activa
        if (!receta.getActivo()) {
            throw new RuntimeException("La receta '" + receta.getNombre() + "' no está activa");
        }

        // 3. Determinar origen (por defecto MANUAL)
        String origen = (request.getOrigen() != null && !request.getOrigen().isBlank())
                ? request.getOrigen()
                : "MANUAL";

        // 4. Aplicar escandallo: valida stock de todos los ingredientes y descuenta.
        //    Si hay stock insuficiente lanza StockInsuficienteException → rollback completo.
        escandalloService.aplicarEscandallo(receta, request.getCantidad(), origen);

        // 5. Crear y persistir la venta
        Venta venta = new Venta();
        venta.setReceta(receta);
        venta.setCantidad(request.getCantidad());
        venta.setPrecioTotal(receta.getPrecioVenta() * request.getCantidad());
        venta.setOrigen(origen);

        return ventaRepository.save(venta);
    }

    @Override
    @Transactional
    public Venta registrarVentaProducto(VentaProductoRequest request) {

        // 1. Buscar el producto
        Producto producto = productoRepository.findById(request.getProductoId())
                .orElseThrow(() -> new ResourceNotFoundException("Producto", "id", request.getProductoId()));

        // 2. Convertir la cantidad solicitada a las unidades del producto
        double cantidadNecesaria = convertirCantidad(request.getCantidad(), producto);

        // 3. Verificar stock suficiente
        if (producto.getStockActual() < cantidadNecesaria) {
            throw new StockInsuficienteException(
                "Stock insuficiente para '" + producto.getNombre() + "'. " +
                "Disponible: " + producto.getStockActual() +
                ", necesario: " + cantidadNecesaria
            );
        }

        // 4. Descontar el stock
        producto.setStockActual(producto.getStockActual() - cantidadNecesaria);
        productoRepository.save(producto);

        // 5. Registrar movimiento de stock
        MovimientoStock movimiento = new MovimientoStock();
        movimiento.setProducto(producto);
        movimiento.setTipo("VENTA");
        movimiento.setCantidad(cantidadNecesaria);
        movimiento.setOrigen("MANUAL");
        movimiento.setMotivo("Venta directa: " + producto.getNombre());
        movimientoStockRepository.save(movimiento);

        // 6. Guardar la venta
        Venta venta = new Venta();
        venta.setProducto(producto);
        venta.setCantidad(request.getCantidad());
        venta.setPrecioTotal(producto.getPrecioUnidad() != null
                ? producto.getPrecioUnidad() * request.getCantidad()
                : 0.0);
        venta.setOrigen("MANUAL");

        Venta ventaGuardada = ventaRepository.save(venta);

        // 7. Comprobar si el stock bajó del mínimo
        alertaService.comprobarStockMinimo(producto);

        return ventaGuardada;
    }

    @Override
    @Transactional(readOnly = true)
    public List<Venta> listarVentas() {
        return ventaRepository.findAll();
    }

    // Convierte la cantidad solicitada a las unidades del producto.
    // Si la unidad tiene capacidad_base, divide entre ella (igual que EscandalloServiceImpl).
    private double convertirCantidad(double cantidad, Producto producto) {
        UnidadMedida unidad = producto.getUnidadMedida();
        if (unidad != null && unidad.getCapacidadBase() != null && unidad.getCapacidadBase() > 0) {
            return cantidad / unidad.getCapacidadBase();
        }
        return cantidad;
    }
}
