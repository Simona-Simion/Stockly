package com.stockly.api.repository;

import com.stockly.api.model.UnidadMedida;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface UnidadMedidaRepository extends JpaRepository<UnidadMedida, UUID> {
}
