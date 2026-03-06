package com.horecastock.api.repository;



import com.horecastock.api.model.Producto;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface ProductoRepository extends JpaRepository<Producto, UUID> {
    Optional<Producto> findByCodigoBarras(String codigoBarras);
}
