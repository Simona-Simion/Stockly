package com.stockly.api.service.impl;

import com.stockly.api.dto.EntradaStockRequest;
import com.stockly.api.dto.MovimientoDTO;
import com.stockly.api.exception.OperacionDuplicadaEnCursoException;
import com.stockly.api.exception.ResourceNotFoundException;
import com.stockly.api.model.MovimientoStock;
import com.stockly.api.model.OperacionProcesada;
import com.stockly.api.model.Producto;
import com.stockly.api.repository.MovimientoStockRepository;
import com.stockly.api.repository.OperacionProcesadaRepository;
import com.stockly.api.repository.ProductoRepository;
import com.stockly.api.service.EntradaStockService;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class EntradaStockServiceImpl implements EntradaStockService {

    private static final String TIPO_ENTRADA_PRODUCTO = "entrada_producto";
    private static final String TIPO_MOVIMIENTO_ENTRADA = "ENTRADA";
    private static final String ORIGEN_MANUAL = "MANUAL";

    private final ProductoRepository productoRepository;
    private final MovimientoStockRepository movimientoStockRepository;
    private final OperacionProcesadaRepository operacionProcesadaRepository;

    @Override
    @Transactional
    public MovimientoDTO registrarEntrada(EntradaStockRequest request) {
        Optional<OperacionProcesada> operacionExistente =
                operacionProcesadaRepository.findByUuidOperacion(request.getUuidOperacion());

        if (operacionExistente.isPresent()) {
            return obtenerMovimientoProcesado(operacionExistente.get());
        }

        if (!reservarOperacionSiNoExiste(request)) {
            return operacionProcesadaRepository.findByUuidOperacion(request.getUuidOperacion())
                    .map(this::obtenerMovimientoProcesado)
                    .orElseThrow(() -> new OperacionDuplicadaEnCursoException(
                            "La operacion '" + request.getUuidOperacion() +
                                    "' ya existe, pero aun no esta disponible. Reintenta."
                    ));
        }

        OperacionProcesada operacion = operacionProcesadaRepository.findByUuidOperacion(request.getUuidOperacion())
                .orElseThrow(() -> new IllegalStateException(
                        "No se encontro la reserva de la operacion '" + request.getUuidOperacion() + "'."
                ));

        Producto producto = productoRepository.findById(request.getProductoId())
                .orElseThrow(() -> new ResourceNotFoundException("Producto", "id", request.getProductoId()));

        if (producto.getActivo() != null && !producto.getActivo()) {
            throw new RuntimeException("El producto '" + producto.getNombre() + "' no esta activo");
        }

        double stockActual = producto.getStockActual() != null ? producto.getStockActual() : 0.0;
        producto.setStockActual(stockActual + request.getCantidad());
        productoRepository.save(producto);

        MovimientoStock movimiento = new MovimientoStock();
        movimiento.setProducto(producto);
        movimiento.setTipo(TIPO_MOVIMIENTO_ENTRADA);
        movimiento.setCantidad(request.getCantidad());
        movimiento.setOrigen(normalizarOrigen(request.getOrigen()));
        movimiento.setMotivo(normalizarMotivo(request.getMotivo(), producto));

        MovimientoStock movimientoGuardado = movimientoStockRepository.save(movimiento);

        operacion.setReferenciaId(
                movimientoGuardado.getId() != null ? movimientoGuardado.getId().toString() : null
        );
        operacion.setFechaProcesada(LocalDateTime.now());
        operacionProcesadaRepository.save(operacion);

        return toDTO(movimientoGuardado);
    }

    private boolean reservarOperacionSiNoExiste(EntradaStockRequest request) {
        OperacionProcesada operacion = new OperacionProcesada();
        operacion.setUuidOperacion(request.getUuidOperacion());
        operacion.setTipoOperacion(TIPO_ENTRADA_PRODUCTO);
        operacion.setFechaProcesada(LocalDateTime.now());

        try {
            operacionProcesadaRepository.saveAndFlush(operacion);
            return true;
        } catch (DataIntegrityViolationException ex) {
            return false;
        }
    }

    private MovimientoDTO obtenerMovimientoProcesado(OperacionProcesada operacion) {
        if (!TIPO_ENTRADA_PRODUCTO.equals(operacion.getTipoOperacion())) {
            throw new OperacionDuplicadaEnCursoException(
                    "La operacion '" + operacion.getUuidOperacion() +
                            "' ya existe con otro tipo de operacion."
            );
        }

        return buscarMovimientoPorReferenciaId(operacion.getReferenciaId())
                .map(this::toDTO)
                .orElseThrow(() -> new OperacionDuplicadaEnCursoException(
                        "La operacion '" + operacion.getUuidOperacion() +
                                "' ya existe, pero el movimiento original aun no esta disponible. Reintenta."
                ));
    }

    private Optional<MovimientoStock> buscarMovimientoPorReferenciaId(String referenciaId) {
        if (referenciaId == null || referenciaId.isBlank()) {
            return Optional.empty();
        }

        try {
            return movimientoStockRepository.findById(UUID.fromString(referenciaId));
        } catch (IllegalArgumentException ex) {
            return Optional.empty();
        }
    }

    private String normalizarOrigen(String origen) {
        if (origen == null || origen.isBlank()) {
            return ORIGEN_MANUAL;
        }
        return origen.trim();
    }

    private String normalizarMotivo(String motivo, Producto producto) {
        if (motivo == null || motivo.isBlank()) {
            return "Entrada manual: " + producto.getNombre();
        }
        return motivo.trim();
    }

    private MovimientoDTO toDTO(MovimientoStock movimiento) {
        return new MovimientoDTO(
                movimiento.getId(),
                movimiento.getTipo(),
                movimiento.getCantidad(),
                movimiento.getMotivo(),
                movimiento.getOrigen(),
                movimiento.getFecha(),
                movimiento.getProducto().getId(),
                movimiento.getProducto().getNombre()
        );
    }
}
