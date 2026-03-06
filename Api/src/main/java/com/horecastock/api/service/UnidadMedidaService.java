package com.horecastock.api.service;

import com.horecastock.api.model.UnidadMedida;
import com.horecastock.api.repository.UnidadMedidaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class UnidadMedidaService {

    private final UnidadMedidaRepository repository;

    public UnidadMedida crear(UnidadMedida unidad) {
        return repository.save(unidad);
    }

    public List<UnidadMedida> listar() {
        return repository.findAll();
    }

    public void eliminar(UUID id) {
        repository.deleteById(id);
    }
}
