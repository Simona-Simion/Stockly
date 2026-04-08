package com.stockly.api.service;

import com.stockly.api.dto.MovimientoDTO;
import com.stockly.api.model.MovimientoStock;
import com.stockly.api.repository.MovimientoStockRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class MovimientoStockService {

    private final MovimientoStockRepository repository;

    public List<MovimientoDTO> listar() {
        return repository.findAllOrderByFechaDesc()
                .stream()
                .map(this::toDTO)
                .collect(Collectors.toList());
    }

    public List<MovimientoDTO> listarPorProducto(UUID productoId) {
        return repository.findByProductoId(productoId)
                .stream()
                .map(this::toDTO)
                .collect(Collectors.toList());
    }

    public MovimientoStock registrarMovimiento(MovimientoStock movimiento) {
        return repository.save(movimiento);
    }

    private MovimientoDTO toDTO(MovimientoStock m) {
        return new MovimientoDTO(
                m.getId(),
                m.getTipo(),
                m.getCantidad(),
                m.getMotivo(),
                m.getOrigen(),
                m.getFecha(),
                m.getProducto().getId(),
                m.getProducto().getNombre()
        );
    }
}
