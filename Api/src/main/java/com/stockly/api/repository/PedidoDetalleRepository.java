package com.stockly.api.repository;

import com.stockly.api.model.PedidoDetalle;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface PedidoDetalleRepository extends JpaRepository<PedidoDetalle, UUID> {

}
