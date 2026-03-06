package com.horecastock.api.repository;

import com.horecastock.api.model.UnidadMedida;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface UnidadMedidaRepository extends JpaRepository<UnidadMedida, UUID> {
}
