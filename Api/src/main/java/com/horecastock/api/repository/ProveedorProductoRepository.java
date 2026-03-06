package com.horecastock.api.repository;

import com.horecastock.api.model.ProveedorProducto;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface ProveedorProductoRepository extends JpaRepository<ProveedorProducto, UUID> {
}
