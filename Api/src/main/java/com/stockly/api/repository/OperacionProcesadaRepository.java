package com.stockly.api.repository;

import com.stockly.api.model.OperacionProcesada;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface OperacionProcesadaRepository extends JpaRepository<OperacionProcesada, UUID> {

    boolean existsByUuidOperacion(String uuidOperacion);

    Optional<OperacionProcesada> findByUuidOperacion(String uuidOperacion);
}
