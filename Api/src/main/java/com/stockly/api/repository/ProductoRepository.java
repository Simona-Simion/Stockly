package com.stockly.api.repository;



import com.stockly.api.model.Producto;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ProductoRepository extends JpaRepository<Producto, UUID> {

    Optional<Producto> findByCodigoBarras(String codigoBarras);

    List<Producto> findByActivoTrue();

    @Query("SELECT p FROM Producto p " +
           "WHERE p.activo = true " +
           "AND LOWER(TRIM(p.nombre)) = LOWER(TRIM(:nombre))")
    List<Producto> findActivosByNombreNormalizado(@Param("nombre") String nombre);

    // Carga productos activos con sus relaciones en una sola query (evita N+1)
    @Query("SELECT p FROM Producto p " +
           "JOIN FETCH p.categoria " +
           "JOIN FETCH p.unidadMedida " +
           "WHERE p.activo = true")
    List<Producto> findAllActivosConRelaciones();

    // Productos activos cuyo stock actual está por debajo del mínimo configurado
    @Query("SELECT p FROM Producto p WHERE p.activo = true AND p.stockActual < p.stockMinimo")
    List<Producto> findProductosBajoStockMinimo();
}
