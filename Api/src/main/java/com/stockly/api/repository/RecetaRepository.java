package com.stockly.api.repository;

import com.stockly.api.model.Receta;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface RecetaRepository extends JpaRepository<Receta, UUID> {

    // Devuelve solo las recetas activas
    List<Receta> findByActivoTrue();
}
