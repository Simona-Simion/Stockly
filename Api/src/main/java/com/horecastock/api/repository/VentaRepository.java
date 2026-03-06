package com.horecastock.api.repository;

import com.horecastock.api.model.Venta;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface VentaRepository extends JpaRepository<Venta, UUID> {
}
