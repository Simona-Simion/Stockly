package com.stockly.api.service.impl;

import com.stockly.api.dto.VentaEscandalloRequest;
import com.stockly.api.dto.VentaProductoRequest;
import com.stockly.api.exception.OperacionDuplicadaEnCursoException;
import com.stockly.api.exception.ResourceNotFoundException;
import com.stockly.api.exception.StockInsuficienteException;
import com.stockly.api.model.MovimientoStock;
import com.stockly.api.model.OperacionProcesada;
import com.stockly.api.model.Producto;
import com.stockly.api.model.Receta;
import com.stockly.api.model.UnidadMedida;
import com.stockly.api.model.Venta;
import com.stockly.api.repository.MovimientoStockRepository;
import com.stockly.api.repository.OperacionProcesadaRepository;
import com.stockly.api.repository.ProductoRepository;
import com.stockly.api.repository.RecetaRepository;
import com.stockly.api.repository.VentaRepository;
import com.stockly.api.service.AlertaService;
import com.stockly.api.service.EscandalloService;
import com.stockly.api.service.VentaService;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class VentaServiceImpl implements VentaService {

    private static final String TIPO_VENTA_RECETA = "venta_receta";
    private static final String TIPO_VENTA_PRODUCTO = "venta_producto";

    private final RecetaRepository recetaRepository;
    private final VentaRepository ventaRepository;
    private final EscandalloService escandalloService;
    private final ProductoRepository productoRepository;
    private final MovimientoStockRepository movimientoStockRepository;
    private final AlertaService alertaService;
    private final OperacionProcesadaRepository operacionProcesadaRepository;

    @Override
    @Transactional
    public Venta registrarVenta(VentaEscandalloRequest request) {
        if (!reservarOperacionSiNoExiste(request.getUuidOperacion(), TIPO_VENTA_RECETA)) {
            return obtenerVentaDuplicadaOExcepcion(request.getUuidOperacion());
        }

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
        //    Si hay stock insuficiente lanza StockInsuficienteException -> rollback completo.
        escandalloService.aplicarEscandallo(receta, request.getCantidad(), origen);

        // 5. Crear y persistir la venta
        Venta venta = new Venta();
        venta.setReceta(receta);
        venta.setCantidad(request.getCantidad());
        venta.setPrecioTotal(receta.getPrecioVenta() * request.getCantidad());
        venta.setOrigen(origen);

        Venta ventaGuardada = ventaRepository.save(venta);
        actualizarReferenciaOperacion(request.getUuidOperacion(), ventaGuardada.getId().toString());
        return ventaGuardada;
    }

    @Override
    @Transactional
    public Venta registrarVentaProducto(VentaProductoRequest request) {
        if (!reservarOperacionSiNoExiste(request.getUuidOperacion(), TIPO_VENTA_PRODUCTO)) {
            return obtenerVentaDuplicadaOExcepcion(request.getUuidOperacion());
        }

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
        actualizarReferenciaOperacion(request.getUuidOperacion(), ventaGuardada.getId().toString());

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

    private boolean reservarOperacionSiNoExiste(String uuidOperacion, String tipoOperacion) {
        if (!tieneUuidOperacion(uuidOperacion)) {
            return true;
        }

        if (operacionProcesadaRepository.existsByUuidOperacion(uuidOperacion)) {
            return false;
        }

        OperacionProcesada operacion = new OperacionProcesada();
        operacion.setUuidOperacion(uuidOperacion);
        operacion.setTipoOperacion(tipoOperacion);
        operacion.setFechaProcesada(LocalDateTime.now());

        try {
            operacionProcesadaRepository.saveAndFlush(operacion);
            return true;
        } catch (DataIntegrityViolationException ex) {
            return false;
        }
    }

    private void actualizarReferenciaOperacion(String uuidOperacion, String referenciaId) {
        if (!tieneUuidOperacion(uuidOperacion)) {
            return;
        }

        OperacionProcesada operacion = operacionProcesadaRepository.findByUuidOperacion(uuidOperacion)
                .orElseThrow(() -> new IllegalStateException(
                        "No se encontró la reserva de la operacion '" + uuidOperacion + "'."
                ));

        operacion.setReferenciaId(referenciaId);
        operacion.setFechaProcesada(LocalDateTime.now());
        operacionProcesadaRepository.save(operacion);
    }

    private Venta obtenerVentaDuplicadaOExcepcion(String uuidOperacion) {
        if (!tieneUuidOperacion(uuidOperacion)) {
            throw new OperacionDuplicadaEnCursoException(
                    "No se puede recuperar una venta duplicada sin uuidOperacion."
            );
        }

        return operacionProcesadaRepository.findByUuidOperacion(uuidOperacion)
                .map(OperacionProcesada::getReferenciaId)
                .flatMap(this::buscarVentaPorReferenciaId)
                .orElseThrow(() -> new OperacionDuplicadaEnCursoException(
                        "La operacion '" + uuidOperacion + "' ya existe, " +
                                "pero la venta original aun no está disponible. Reintenta."
                ));
    }

    private Optional<Venta> buscarVentaPorReferenciaId(String referenciaId) {
        if (referenciaId == null || referenciaId.isBlank()) {
            return Optional.empty();
        }

        try {
            return ventaRepository.findById(UUID.fromString(referenciaId));
        } catch (IllegalArgumentException ex) {
            return Optional.empty();
        }
    }

    private boolean tieneUuidOperacion(String uuidOperacion) {
        return uuidOperacion != null && !uuidOperacion.isBlank();
    }
}
