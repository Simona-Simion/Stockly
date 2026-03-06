package com.horecastock.api.repository;

import com.horecastock.api.model.MovimientoStock;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface MovimientoStockRepository extends JpaRepository<MovimientoStock, UUID> {

}
