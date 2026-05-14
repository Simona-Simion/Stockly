package com.stockly.api.repository;

import com.stockly.api.model.Pedido;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface PedidoRepository extends JpaRepository<Pedido, UUID> {

    @Query("SELECT DISTINCT p FROM Pedido p " +
           "JOIN FETCH p.proveedor " +
           "LEFT JOIN FETCH p.detalles d " +
           "LEFT JOIN FETCH d.producto")
    List<Pedido> findAllConDetalles();

    @Query("SELECT DISTINCT p FROM Pedido p " +
           "JOIN FETCH p.proveedor " +
           "LEFT JOIN FETCH p.detalles d " +
           "LEFT JOIN FETCH d.producto " +
           "WHERE p.id = :id")
    Optional<Pedido> findByIdConDetalles(@Param("id") UUID id);
}
