package com.horecastock.api.repository;



import com.horecastock.api.model.Producto;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ProductoRepository extends JpaRepository<Producto, UUID> {

    Optional<Producto> findByCodigoBarras(String codigoBarras);

    // Productos activos cuyo stock actual está por debajo del mínimo configurado
    @Query("SELECT p FROM Producto p WHERE p.activo = true AND p.stockActual < p.stockMinimo")
    List<Producto> findProductosBajoStockMinimo();
}
