package com.horecastock.api.repository;

import com.horecastock.api.model.PedidoDetalle;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface PedidoDetalleRepository extends JpaRepository<PedidoDetalle, UUID> {

}
