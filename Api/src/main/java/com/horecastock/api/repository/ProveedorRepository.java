package com.horecastock.api.repository;

import com.horecastock.api.model.Proveedor;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface ProveedorRepository extends JpaRepository<Proveedor, UUID> {
}
