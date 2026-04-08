package com.stockly.api.repository;

import com.stockly.api.model.MovimientoStock;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.UUID;

public interface MovimientoStockRepository extends JpaRepository<MovimientoStock, UUID> {

    @Query("SELECT m FROM MovimientoStock m JOIN FETCH m.producto ORDER BY m.fecha DESC")
    List<MovimientoStock> findAllOrderByFechaDesc();

    @Query("SELECT m FROM MovimientoStock m JOIN FETCH m.producto WHERE m.producto.id = :productoId ORDER BY m.fecha DESC")
    List<MovimientoStock> findByProductoId(@Param("productoId") UUID productoId);
}
