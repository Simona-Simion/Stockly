package com.stockly.api.service;

import com.stockly.api.dto.CrearPedidoLineaRequest;
import com.stockly.api.dto.CrearPedidoRequest;
import com.stockly.api.dto.PedidoLineaResponse;
import com.stockly.api.dto.PedidoResponse;
import com.stockly.api.dto.RecibirPedidoRequest;
import com.stockly.api.exception.OperacionDuplicadaEnCursoException;
import com.stockly.api.exception.ResourceNotFoundException;
import com.stockly.api.model.MovimientoStock;
import com.stockly.api.model.OperacionProcesada;
import com.stockly.api.model.Pedido;
import com.stockly.api.model.PedidoDetalle;
import com.stockly.api.model.Producto;
import com.stockly.api.model.Proveedor;
import com.stockly.api.repository.MovimientoStockRepository;
import com.stockly.api.repository.OperacionProcesadaRepository;
import com.stockly.api.repository.PedidoRepository;
import com.stockly.api.repository.ProductoRepository;
import com.stockly.api.repository.ProveedorRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class PedidoService {

    public static final String ESTADO_PENDIENTE = "PENDIENTE";
    public static final String ESTADO_RECIBIDO = "RECIBIDO";
    public static final String ESTADO_CANCELADO = "CANCELADO";
    private static final String TIPO_RECIBIR_PEDIDO_PROVEEDOR = "recibir_pedido_proveedor";
    private static final String TIPO_MOVIMIENTO_ENTRADA = "ENTRADA";
    private static final String ORIGEN_PEDIDO_PROVEEDOR = "PEDIDO_PROVEEDOR";

    private final PedidoRepository repository;
    private final ProveedorRepository proveedorRepository;
    private final ProductoRepository productoRepository;
    private final MovimientoStockRepository movimientoStockRepository;
    private final OperacionProcesadaRepository operacionProcesadaRepository;

    @Transactional
    public PedidoResponse crear(CrearPedidoRequest request) {
        if (request.getLineas() == null || request.getLineas().isEmpty()) {
            throw new IllegalArgumentException("El pedido debe tener al menos una linea");
        }

        Proveedor proveedor = proveedorRepository.findById(request.getProveedorId())
                .orElseThrow(() -> new ResourceNotFoundException("Proveedor", "id", request.getProveedorId()));

        Pedido pedido = new Pedido();
        pedido.setProveedor(proveedor);
        pedido.setFecha(LocalDateTime.now());
        pedido.setEstado(ESTADO_PENDIENTE);

        List<PedidoDetalle> detalles = new ArrayList<>();
        for (CrearPedidoLineaRequest lineaRequest : request.getLineas()) {
            detalles.add(crearDetalle(pedido, lineaRequest));
        }
        pedido.setDetalles(detalles);

        return toResponse(repository.save(pedido));
    }

    @Transactional(readOnly = true)
    public List<PedidoResponse> listar() {
        return repository.findAllConDetalles().stream()
                .sorted(Comparator.comparing(Pedido::getFecha).reversed())
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public PedidoResponse obtener(UUID id) {
        Pedido pedido = repository.findByIdConDetalles(id)
                .orElseThrow(() -> new ResourceNotFoundException("Pedido", "id", id));

        return toResponse(pedido);
    }

    @Transactional
    public PedidoResponse actualizarEstado(UUID id, String estado) {
        Pedido pedido = repository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Pedido", "id", id));

        validarEstado(estado);
        pedido.setEstado(estado);

        Pedido guardado = repository.save(pedido);
        return obtener(guardado.getId());
    }

    @Transactional
    public PedidoResponse recibir(UUID id, RecibirPedidoRequest request) {
        Optional<OperacionProcesada> operacionExistente =
                operacionProcesadaRepository.findByUuidOperacion(request.getUuidOperacion());

        if (operacionExistente.isPresent()) {
            return obtenerPedidoProcesado(id, operacionExistente.get());
        }

        if (!reservarOperacionRecepcion(request)) {
            return operacionProcesadaRepository.findByUuidOperacion(request.getUuidOperacion())
                    .map(operacion -> obtenerPedidoProcesado(id, operacion))
                    .orElseThrow(() -> new OperacionDuplicadaEnCursoException(
                            "La operacion '" + request.getUuidOperacion() +
                                    "' ya existe, pero aun no esta disponible. Reintenta."
                    ));
        }

        OperacionProcesada operacion = operacionProcesadaRepository.findByUuidOperacion(request.getUuidOperacion())
                .orElseThrow(() -> new IllegalStateException(
                        "No se encontro la reserva de la operacion '" + request.getUuidOperacion() + "'."
                ));

        Pedido pedido = repository.findByIdConDetalles(id)
                .orElseThrow(() -> new ResourceNotFoundException("Pedido", "id", id));

        validarPedidoRecibible(pedido);

        for (PedidoDetalle detalle : pedido.getDetalles()) {
            recibirLinea(pedido, detalle);
        }

        pedido.setEstado(ESTADO_RECIBIDO);
        Pedido pedidoGuardado = repository.save(pedido);

        operacion.setReferenciaId(pedidoGuardado.getId().toString());
        operacion.setFechaProcesada(LocalDateTime.now());
        operacionProcesadaRepository.save(operacion);

        return toResponse(pedidoGuardado);
    }

    private PedidoDetalle crearDetalle(Pedido pedido, CrearPedidoLineaRequest lineaRequest) {
        if (lineaRequest.getCantidad() == null || lineaRequest.getCantidad() <= 0) {
            throw new IllegalArgumentException("La cantidad de la linea debe ser mayor que 0");
        }

        Producto producto = productoRepository.findById(lineaRequest.getProductoId())
                .orElseThrow(() -> new ResourceNotFoundException("Producto", "id", lineaRequest.getProductoId()));

        if (producto.getActivo() != null && !producto.getActivo()) {
            throw new IllegalArgumentException("El producto '" + producto.getNombre() + "' no esta activo");
        }

        PedidoDetalle detalle = new PedidoDetalle();
        detalle.setPedido(pedido);
        detalle.setProducto(producto);
        detalle.setCantidad(lineaRequest.getCantidad());
        detalle.setPrecio(lineaRequest.getPrecioUnitario());
        return detalle;
    }

    private void validarEstado(String estado) {
        if (ESTADO_RECIBIDO.equals(estado)) {
            throw new IllegalArgumentException("Para recibir un pedido usa el endpoint de recepcion.");
        }

        if (!ESTADO_PENDIENTE.equals(estado)
                && !ESTADO_CANCELADO.equals(estado)) {
            throw new IllegalArgumentException("Estado de pedido invalido: " + estado);
        }
    }

    private boolean reservarOperacionRecepcion(RecibirPedidoRequest request) {
        OperacionProcesada operacion = new OperacionProcesada();
        operacion.setUuidOperacion(request.getUuidOperacion());
        operacion.setTipoOperacion(TIPO_RECIBIR_PEDIDO_PROVEEDOR);
        operacion.setFechaProcesada(LocalDateTime.now());

        try {
            operacionProcesadaRepository.saveAndFlush(operacion);
            return true;
        } catch (DataIntegrityViolationException ex) {
            return false;
        }
    }

    private PedidoResponse obtenerPedidoProcesado(UUID pedidoId, OperacionProcesada operacion) {
        if (!TIPO_RECIBIR_PEDIDO_PROVEEDOR.equals(operacion.getTipoOperacion())) {
            throw new OperacionDuplicadaEnCursoException(
                    "La operacion '" + operacion.getUuidOperacion() +
                            "' ya existe con otro tipo de operacion."
            );
        }

        if (operacion.getReferenciaId() == null || operacion.getReferenciaId().isBlank()) {
            throw new OperacionDuplicadaEnCursoException(
                    "La operacion '" + operacion.getUuidOperacion() +
                            "' ya existe, pero el pedido original aun no esta disponible. Reintenta."
            );
        }

        UUID pedidoProcesadoId;
        try {
            pedidoProcesadoId = UUID.fromString(operacion.getReferenciaId());
        } catch (IllegalArgumentException ex) {
            throw new OperacionDuplicadaEnCursoException(
                    "La operacion '" + operacion.getUuidOperacion() +
                            "' tiene una referencia invalida."
            );
        }

        if (!pedidoProcesadoId.equals(pedidoId)) {
            throw new OperacionDuplicadaEnCursoException(
                    "La operacion '" + operacion.getUuidOperacion() +
                            "' ya fue usada para otro pedido."
            );
        }

        return obtener(pedidoProcesadoId);
    }

    private void validarPedidoRecibible(Pedido pedido) {
        if (!ESTADO_PENDIENTE.equals(pedido.getEstado())) {
            throw new IllegalArgumentException("Solo se pueden recibir pedidos en estado PENDIENTE");
        }

        if (pedido.getDetalles() == null || pedido.getDetalles().isEmpty()) {
            throw new IllegalArgumentException("No se puede recibir un pedido sin lineas");
        }
    }

    private void recibirLinea(Pedido pedido, PedidoDetalle detalle) {
        Producto producto = detalle.getProducto();

        if (producto == null) {
            throw new IllegalArgumentException("El pedido contiene una linea sin producto");
        }

        if (producto.getActivo() != null && !producto.getActivo()) {
            throw new IllegalArgumentException("El producto '" + producto.getNombre() + "' no esta activo");
        }

        if (detalle.getCantidad() == null || detalle.getCantidad() <= 0) {
            throw new IllegalArgumentException("La cantidad de la linea debe ser mayor que 0");
        }

        double stockActual = producto.getStockActual() != null ? producto.getStockActual() : 0.0;
        producto.setStockActual(stockActual + detalle.getCantidad());
        productoRepository.save(producto);

        MovimientoStock movimiento = new MovimientoStock();
        movimiento.setProducto(producto);
        movimiento.setTipo(TIPO_MOVIMIENTO_ENTRADA);
        movimiento.setCantidad(detalle.getCantidad());
        movimiento.setOrigen(ORIGEN_PEDIDO_PROVEEDOR);
        movimiento.setMotivo("Recepcion pedido proveedor: " + pedido.getProveedor().getNombre());

        movimientoStockRepository.save(movimiento);
    }

    private PedidoResponse toResponse(Pedido pedido) {
        List<PedidoLineaResponse> lineas = pedido.getDetalles() == null
                ? List.of()
                : pedido.getDetalles().stream()
                        .sorted(Comparator.comparing(PedidoDetalle::getId))
                        .map(this::toLineaResponse)
                        .toList();

        return new PedidoResponse(
                pedido.getId(),
                pedido.getProveedor() != null ? pedido.getProveedor().getId() : null,
                pedido.getProveedor() != null ? pedido.getProveedor().getNombre() : null,
                pedido.getFecha(),
                pedido.getEstado(),
                lineas
        );
    }

    private PedidoLineaResponse toLineaResponse(PedidoDetalle detalle) {
        Producto producto = detalle.getProducto();

        return new PedidoLineaResponse(
                detalle.getId(),
                producto != null ? producto.getId() : null,
                producto != null ? producto.getNombre() : null,
                detalle.getCantidad(),
                detalle.getPrecio()
        );
    }
}
